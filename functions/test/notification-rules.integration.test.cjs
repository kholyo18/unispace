const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { db, Timestamp, project, fixture, read, erase, patch, denied, allowed, http, close } = require('./helpers/notification-fixture.cjs');
after(close);

test('anonymous and unrelated users cannot read notifications', async () => {
  const f = await fixture();
  for (const u of [null, f.actor, f.outsider]) denied(await read(f.path, u));
});
test('recipient reads the notification and its unread query', async () => {
  const f = await fixture(); allowed(await read(f.path, f.owner));
  const result = await http(`/users/${f.owner.uid}:runQuery`, f.owner, 'POST', { structuredQuery: {
    from: [{ collectionId: 'notifications' }], where: { fieldFilter: {
      field: { fieldPath: 'read' }, op: 'EQUAL', value: { booleanValue: false },
    } }, limit: 100,
  } });
  allowed(result); assert.equal(result.data.filter(r => r.document).length, 1);
});
test('recipient history ordering and unread aggregation remain available', async () => {
  const f = await fixture();
  const query = { from: [{ collectionId: 'notifications' }],
    orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' }], limit: 80 };
  allowed(await http(`/users/${f.owner.uid}:runQuery`, f.owner, 'POST', { structuredQuery: query }));
  allowed(await http(`/users/${f.owner.uid}:runAggregationQuery`, f.owner, 'POST', {
    structuredAggregationQuery: { structuredQuery: { from: [{ collectionId: 'notifications' }] },
      aggregations: [{ alias: 'total', count: {} }] },
  }));
});
test('cross-user history queries and collection-group queries are denied', async () => {
  const f = await fixture();
  denied(await http(`/users/${f.owner.uid}:runQuery`, f.actor, 'POST',
    { structuredQuery: { from: [{ collectionId: 'notifications' }], limit: 10 } }));
  denied(await http(':runQuery', f.owner, 'POST',
    { structuredQuery: { from: [{ collectionId: 'notifications', allDescendants: true }], limit: 10 } }));
});
test('NOTIFREGRESSION: sender cannot create a cross-user notification', async () => {
  const f = await fixture(); denied(await patch(`users/${f.owner.uid}/notifications/forged`, f.actor,
    { type: 'follow', actorId: f.actor.uid, message: 'not authorized', read: false }));
});
test('NOTIFREGRESSION: recipient cannot manufacture a self notification', async () => {
  const f = await fixture(); denied(await patch(`users/${f.owner.uid}/notifications/forged`, f.owner,
    { type: 'announcement', actorId: f.owner.uid, message: 'not authorized', read: false }));
});
test('NOTIFREGRESSION: a listed actor cannot rewrite a notification', async () => {
  const f = await fixture(); denied(await patch(f.path, f.actor, { message: 'forged event' }));
});
test('NOTIFREGRESSION: recipient cannot edit server-owned notification fields', async () => {
  const f = await fixture(); denied(await patch(f.path, f.owner, { actorName: 'Fake authority' }));
});
test('all identity and content fields are immutable even alongside a valid read update', async () => {
  const f = await fixture();
  for (const data of [{ actorId: f.outsider.uid }, { actorIds: [f.outsider.uid] }, { message: 'other' },
    { type: 'announcement' }, { postId: 'other' }, { commentId: 'other' }, { chatId: 'other' },
    { createdAt: Timestamp.fromMillis(0) }, { count: 999 }, { actorPhotoUrl: 'other' }, { extra: true }]) {
    denied(await patch(f.path, f.owner, { ...data, read: true }));
  }
  assert.equal((await f.ref.get()).data().read, false);
});
test('recipient can acknowledge idempotently without rewriting the envelope', async () => {
  const f = await fixture(), original = (await f.ref.get()).data();
  allowed(await patch(f.path, f.owner, { read: true }));
  allowed(await patch(f.path, f.owner, { read: true }));
  assert.deepEqual((await f.ref.get()).data(), { ...original, read: true });
});
test('acknowledging a legacy notification with no read field remains allowed', async () => {
  const f = await fixture(); await f.ref.set({ type: 'follow', actorId: f.actor.uid });
  allowed(await patch(f.path, f.owner, { read: true }));
});
test('NOTIFREGRESSION: recipient cannot reset an acknowledged notification', async () => {
  const f = await fixture(); await f.ref.update({ read: true });
  denied(await patch(f.path, f.owner, { read: false }));
});
test('read flag must be true and cannot be deleted', async () => {
  const f = await fixture();
  for (const read of [null, 1, 'true', {}, []]) denied(await patch(f.path, f.owner, { read }));
  denied(await patch(f.path, f.owner, {}, ['read']));
});
test('NOTIFREGRESSION: listed actors cannot dismiss someone else\'s notification', async () => {
  const f = await fixture(); denied(await erase(f.path, f.actor));
});
test('recipient can dismiss while an unrelated user cannot', async () => {
  const f = await fixture(); denied(await erase(f.path, f.outsider));
  allowed(await erase(f.path, f.owner)); assert.equal((await f.ref.get()).exists, false);
});
test('recipient mark-all and dismiss-all batches retain their permitted behavior', async () => {
  const f = await fixture(), second = f.path + '-second'; await db.doc(second).set((await f.ref.get()).data());
  const name = path => `projects/${project}/databases/(default)/documents/${path}`;
  allowed(await http(':commit', f.owner, 'POST', { writes: [f.path, second].map(path => ({
    update: { name: name(path), fields: { read: { booleanValue: true } } },
    updateMask: { fieldPaths: ['read'] }, currentDocument: { exists: true },
  })) }));
  assert.equal((await db.doc(second).get()).data().read, true);
  allowed(await http(':commit', f.owner, 'POST', { writes: [f.path, second].map(path => ({ delete: name(path) })) }));
});
test('a batch mixing acknowledgement with a forged create fails atomically', async () => {
  const f = await fixture(), prefix = `projects/${project}/databases/(default)/documents/`;
  denied(await http(':commit', f.owner, 'POST', { writes: [
    { update: { name: prefix + f.path, fields: { read: { booleanValue: true } } }, updateMask: { fieldPaths: ['read'] } },
    { update: { name: prefix + f.path + '-fake', fields: { actorId: { stringValue: f.owner.uid } } } },
  ] }));
  assert.equal((await f.ref.get()).data().read, false);
});
test('NOTIFREGRESSION: revoked recipient cannot read or acknowledge notifications', async () => {
  const f = await fixture(); await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore: f.owner.authTime });
  denied(await read(f.path, f.owner)); denied(await patch(f.path, f.owner, { read: true }));
  denied(await erase(f.path, f.owner));
});
test('a valid newer session remains usable and malformed cutoffs deny access', async () => {
  const f = await fixture(), cutoff = db.doc(`authRevocations/${f.owner.uid}`);
  await cutoff.set({ revokedBefore: f.owner.authTime - 1 }); allowed(await read(f.path, f.owner));
  for (const data of [{}, { revokedBefore: 'invalid' }]) { await cutoff.set(data); denied(await read(f.path, f.owner)); }
});
test('NOTIFREGRESSION: raw device token documents are server-only', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}/fcm_tokens/device`;
  await db.doc(path).set({ token: 'emulator-token' });
  denied(await read(path, f.owner)); denied(await patch(path, f.owner, { token: 'replacement' }));
  denied(await erase(path, f.owner));
});
test('new device registrations and token directory queries are denied for all clients', async () => {
  const f = await fixture();
  for (const u of [null, f.owner, f.actor]) {
    denied(await patch(`users/${f.owner.uid}/fcm_tokens/new`, u, { token: 'raw' }));
    denied(await http(`/users/${f.owner.uid}:runQuery`, u, 'POST', { structuredQuery: { from: [{ collectionId: 'fcm_tokens' }] } }));
  }
});
test('device ownership and revocation metadata have no client access', async () => {
  const f = await fixture();
  for (const path of ['pushTokenOwners/fixture', `pushTokenOwners/fixture/revocations/${f.owner.uid}`]) {
    await db.doc(path).set({ ownerId: f.owner.uid, authTime: 0 });
    denied(await read(path, f.owner)); denied(await patch(path, f.owner, { ownerId: f.actor.uid }));
  }
});
