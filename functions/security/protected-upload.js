'use strict';
const { HttpsError } = require('firebase-functions/v2/https');
const { assertActiveSession } = require('./device-sessions');
const { uploadPolicy, validId } = require('./storage-upload-policy');
const fail = (code, message) => { throw new HttpsError(code, message); };
const generation = value => typeof value === 'string' && /^\d+$/.test(value);
const exact = (value, keys) => value && typeof value === 'object' && !Array.isArray(value) &&
  Object.keys(value).length === keys.length && keys.every(key => Object.hasOwn(value, key));
const locator = (bucket, path) => `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucket)}/o/${encodeURIComponent(path)}?alt=media`;

function createProtectedUploadHandlers({ auth, db, FieldValue, Timestamp, bucket, prepareUpload }) {
  const ticket = id => db.doc(`protectedUploadTickets/${id}`);
  async function identity(request) {
    const header = request.rawRequest?.headers?.authorization;
    if (!request.auth?.uid || typeof header !== 'string' || !header.startsWith('Bearer ')) fail('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { fail('unauthenticated', 'Sign in again.'); }
    if (token.uid !== request.auth.uid) fail('unauthenticated', 'Invalid session.');
    await assertActiveSession({ db, token });
    return token;
  }
  async function metadata(file) {
    try { return (await file.getMetadata())[0]; }
    catch (error) { if (Number(error.code) === 404) return null; throw error; }
  }
  function validTicket(value, token, id) {
    if (!value || value.uid !== token.uid || value.sessionId !== token.sid || value.grantId !== id) fail('permission-denied', 'Upload unavailable.');
    if (!Number.isFinite(value.expiresAt?.toMillis?.()) || value.expiresAt.toMillis() <= Date.now()) fail('deadline-exceeded', 'Upload expired.');
    if (value.stagingPath !== `private_upload_staging/${token.uid}/${id}` || !['prepared', 'copying', 'complete'].includes(value.state)) fail('failed-precondition', 'Invalid upload.');
    const policy = uploadPolicy(value.path, value.contentType, value.size, token.uid);
    if (!generation(value.targetGeneration) || !policy.overwrite && value.targetGeneration !== '0') fail('failed-precondition', 'Invalid upload destination.');
    return policy;
  }
  function ownedFinal(meta, value) {
    return meta && generation(String(meta.generation)) && Number(meta.size) === value.size &&
      meta.contentType === value.contentType && meta.metadata?.uploadedBy === value.uid &&
      meta.metadata?.uploadGrantId === value.grantId && meta.metadata?.protectedUploadVersion === '1' &&
      !meta.metadata?.firebaseStorageDownloadTokens;
  }
  async function prepare(request) {
    const token = await identity(request);
    // The existing handler performs all account, membership, block, audience,
    // quota and path/type/size checks. Clients cannot choose staging paths.
    const grant = await prepareUpload(request);
    const storage = bucket();
    if (!validId(grant.grantId) || grant.uid !== token.uid || grant.bucket !== storage.name) fail('internal', 'Invalid upload grant.');
    const policy = uploadPolicy(grant.path, grant.contentType, grant.size, token.uid);
    const current = await metadata(storage.file(grant.path));
    if (current && !policy.overwrite) fail('already-exists', 'Media already exists.');
    const targetGeneration = current ? String(current.generation) : '0';
    if (!generation(targetGeneration)) fail('failed-precondition', 'Invalid destination generation.');
    const expiresAt = Math.min(Date.now() + 300000, grant.expiresAt);
    if (!Number.isFinite(expiresAt) || expiresAt <= Date.now()) fail('deadline-exceeded', 'Upload expired.');
    const stagingPath = `private_upload_staging/${token.uid}/${grant.grantId}`;
    const value = { schemaVersion: 1, grantId: grant.grantId, uid: token.uid, sessionId: token.sid,
      path: grant.path, bucket: storage.name, size: grant.size, contentType: grant.contentType,
      stagingPath, targetGeneration, state: 'prepared', createdAt: FieldValue.serverTimestamp(), expiresAt: Timestamp.fromMillis(expiresAt) };
    await db.runTransaction(async tx => {
      await assertActiveSession({ db, token, reader: tx });
      tx.create(ticket(grant.grantId), value);
    });
    const uploadHeaders = { 'Content-Type': grant.contentType, 'Content-Length': String(grant.size),
      'x-goog-if-generation-match': '0', 'x-goog-meta-uploadedby': token.uid, 'x-goog-meta-uploadgrantid': grant.grantId };
    const [uploadUrl] = await storage.file(stagingPath).getSignedUrl({ version: 'v4', action: 'write', expires: expiresAt,
      contentType: grant.contentType, extensionHeaders: Object.fromEntries(Object.entries(uploadHeaders).map(([k, v]) => [k.toLowerCase(), v])) });
    await assertActiveSession({ db, token });
    return { ...grant, expiresAt, stagingPath, uploadUrl, uploadHeaders };
  }
  async function finalize(request) {
    const token = await identity(request);
    if (!exact(request.data, ['grantId']) || !validId(request.data.grantId)) fail('invalid-argument', 'Invalid upload receipt.');
    const ref = ticket(request.data.grantId);
    const value = (await ref.get()).data();
    validTicket(value, token, request.data.grantId);
    const storage = bucket();
    if (storage.name !== value.bucket) fail('failed-precondition', 'Storage changed.');
    // Recheck current ACL even when recovering a completed copy/receipt. A
    // removed member or revoked session must not finalize an earlier grant.
    await prepareUpload.authorize({ ...request, data: { expectedUid: token.uid, path: value.path, contentType: value.contentType, size: value.size } });
    const destination = storage.file(value.path);
    let finalMetadata = await metadata(destination);
    if (!ownedFinal(finalMetadata, value)) {
      if (value.state === 'complete') fail('failed-precondition', 'Uploaded media was replaced.');
      const actualTarget = finalMetadata ? String(finalMetadata.generation) : '0';
      if (actualTarget !== value.targetGeneration) fail('already-exists', 'Destination changed. Select the image again.');
      const staged = await metadata(storage.file(value.stagingPath));
      if (!staged || !generation(String(staged.generation)) || Number(staged.size) !== value.size || staged.contentType !== value.contentType ||
          staged.metadata?.uploadedby !== value.uid || staged.metadata?.uploadgrantid !== value.grantId ||
          staged.metadata?.firebaseStorageDownloadTokens || staged.metadata?.firebasestoragedownloadtokens) fail('failed-precondition', 'Invalid staged media.');
      const sourceGeneration = String(staged.generation);
      await db.runTransaction(async tx => {
        await assertActiveSession({ db, token, reader: tx });
        const fresh = (await tx.get(ref)).data();
        validTicket(fresh, token, value.grantId);
        if (fresh.sourceGeneration && fresh.sourceGeneration !== sourceGeneration) fail('failed-precondition', 'Staged media changed.');
        if (fresh.state !== 'complete') tx.update(ref, { state: 'copying', sourceGeneration });
      });
      try {
        await storage.file(value.stagingPath, { generation: sourceGeneration }).copy(destination, {
          preconditionOpts: { ifGenerationMatch: value.targetGeneration },
          contentType: value.contentType, cacheControl: 'private, no-store',
          metadata: { protectedUploadVersion: '1', uploadedBy: value.uid, uploadGrantId: value.grantId },
        });
      } catch (error) {
        if (Number(error.code) !== 412) throw error;
        // A concurrent finalize may have committed this exact grant. Never
        // retry an unconditional overwrite after a generation conflict.
      }
      finalMetadata = await metadata(destination);
      if (!ownedFinal(finalMetadata, value)) fail('aborted', 'Destination changed. Retry or upload again.');
    }
    const finalGeneration = String(finalMetadata.generation);
    await db.runTransaction(async tx => {
      await assertActiveSession({ db, token, reader: tx });
      const fresh = (await tx.get(ref)).data();
      validTicket(fresh, token, value.grantId);
      if (fresh.finalGeneration && fresh.finalGeneration !== finalGeneration) fail('failed-precondition', 'Uploaded media changed.');
      tx.update(ref, { state: 'complete', finalGeneration, completedAt: FieldValue.serverTimestamp() });
    });
    // Staging is private and may be cleaned by bucket lifecycle if deletion
    // fails. A cleanup failure must not turn a committed upload into failure.
    try {
      const fresh = (await ref.get()).data();
      if (fresh.sourceGeneration) await storage.file(value.stagingPath, { generation: fresh.sourceGeneration }).delete({ ifGenerationMatch: fresh.sourceGeneration });
    } catch (_) { /* Receipt remains usable for idempotent recovery. */ }
    return { url: locator(value.bucket, value.path), path: value.path, bucket: value.bucket, uid: value.uid };
  }
  return { prepare, finalize };
}
module.exports = { createProtectedUploadHandlers };
