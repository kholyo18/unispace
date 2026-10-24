'use strict';
const { randomUUID } = require('node:crypto');
const PREFIX = 'private_upload_staging/';
const DAY = 24 * 60 * 60 * 1000;
const validPath = name => typeof name === 'string' && /^private_upload_staging\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{20}$/.test(name);

function createProtectedUploadCleanup({ db, bucket, now = Date.now }) {
  const cursorRef = db.doc('maintenanceCursors/protectedUploadStaging');
  return async () => {
    const started = now(), deadline = started + 90000, leaseToken = randomUUID();
    const state = await db.runTransaction(async tx => {
      const data = (await tx.get(cursorRef)).data() || {};
      if (Number.isFinite(data.leaseUntilMs) && data.leaseUntilMs > started) return null;
      const pageToken = typeof data.pageToken === 'string' && data.pageToken.length <= 16384 ? data.pageToken : null;
      const lastName = validPath(data.lastName) ? data.lastName : null;
      tx.set(cursorRef, { pageToken, lastName, leaseToken, leaseUntilMs: started + 120000, updatedAtMs: started });
      return { pageToken, lastName };
    });
    const result = { scanned: 0, removed: 0, failed: 0, skipped: 0, pages: 0, busy: state === null };
    if (!state) return result;
    const storage = typeof bucket === 'function' ? bucket() : bucket;
    let pageToken = state.pageToken, lastName = state.lastName;
    async function checkpoint(release = false) {
      await db.runTransaction(async tx => {
        const fresh = (await tx.get(cursorRef)).data();
        if (fresh?.leaseToken !== leaseToken) throw Error('Protected upload cleanup lease lost.');
        tx.set(cursorRef, { pageToken, lastName, leaseToken: release ? null : leaseToken,
          leaseUntilMs: release ? 0 : now() + 120000, updatedAtMs: now() });
      });
    }
    try {
      while (result.pages < 10 && now() < deadline) {
        let files, nextQuery;
        try {
          [files, nextQuery] = await storage.getFiles({ prefix: PREFIX, autoPaginate: false, maxResults: 100,
            ...(pageToken ? { pageToken } : {}) });
        } catch (error) {
          // An obsolete server-issued page token must not stall every future
          // run. Restart the next cycle; do not broaden the listing prefix.
          if (pageToken && Number(error.code) === 400) { pageToken = null; lastName = null; }
          throw error;
        }
        result.pages++;
        for (const listed of files) {
          if (lastName && listed.name <= lastName) continue;
          if (now() >= deadline) return result;
          result.scanned++;
          try {
            if (!validPath(listed.name)) { result.skipped++; continue; }
            const meta = listed.metadata || (await listed.getMetadata())[0];
            const created = Date.parse(meta.timeCreated);
            const generation = String(meta.generation || '');
            if (!Number.isFinite(created) || created > started - DAY || !/^[1-9]\d*$/.test(generation)) {
              result.skipped++; continue;
            }
            await storage.file(listed.name, { generation }).delete({ ifGenerationMatch: generation, ignoreNotFound: true });
            result.removed++;
          } catch (error) {
            if (Number(error.code) === 404) result.removed++;
            else result.failed++;
          } finally {
            // A failed early object is revisited next complete cycle, while
            // later objects and later pages continue across invocations.
            lastName = listed.name;
          }
        }
        pageToken = typeof nextQuery?.pageToken === 'string' ? nextQuery.pageToken : null;
        lastName = null;
        await checkpoint();
        if (!pageToken) break;
      }
      return result;
    } finally {
      await checkpoint(true);
    }
  };
}
module.exports = { createProtectedUploadCleanup };
