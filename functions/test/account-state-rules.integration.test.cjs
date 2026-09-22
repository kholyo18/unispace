const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { db, auth, FieldValue, fixture, callableRequest, patch, read, erase, allowed, denied, close } = require('./helpers/notification-fixture.cjs');
const { createAccountStateHandlers } = require('../security/account-state');
after(close);
const handlers = createAccountStateHandlers({ auth, db, FieldValue });
const control = () => ({ schemaVersion: 1, revision: 1, selfDisabled: false, selfFrozen: false, adminSuspended: false });
test('STATEREGRESSION: clients cannot directly disable their account', async () => {
  const f = await fixture(); denied(await patch(`users/${f.owner.uid}`, f.owner, { accountStatus: 'disabled' }));
});
test('STATEREGRESSION: clients cannot manufacture a deleted flag', async () => {
  const f = await fixture(); denied(await patch(`users/${f.owner.uid}`, f.owner, { isDeleted: true }));
});
test('STATEREGRESSION: clients cannot directly clear a frozen state', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).update({ security: { frozen: true, frozenAt: null } });
  denied(await patch(`users/${f.owner.uid}`, f.owner, { security: { frozen: false, frozenAt: null } }));
});
test('STATEREGRESSION: lifecycle timestamps are not client editable', async () => {
  const f = await fixture(); denied(await patch(`users/${f.owner.uid}`, f.owner, { deletedAt: null }));
});
test('STATEREGRESSION: an administrative restriction blocks direct chat reads', async () => {
  const f = await fixture(); const path = `chats/state-${f.owner.uid}`;
  await db.doc(path).set({ memberIds: [f.owner.uid, f.actor.uid] });
  await db.doc(`accountStateControls/${f.owner.uid}`).set({ ...control(), adminSuspended: true });
  denied(await read(path, f.owner));
});
test('STATEREGRESSION: clients cannot revive a pending deletion', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'deleted', isDeleted: true });
  denied(await patch(`users/${f.owner.uid}`, f.owner, { accountStatus: 'active', isDeleted: false }));
});
test('STATEREGRESSION: removing the entire security map cannot clear frozen state', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).update({ security: { frozen: true } });
  denied(await patch(`users/${f.owner.uid}`, f.owner, {}, ['security']));
});
test('canonical controls cannot be read written or deleted by owner or outsider', async () => {
  const f = await fixture(); const path = `accountStateControls/${f.owner.uid}`; await db.doc(path).set(control());
  for (const actor of [f.owner, f.actor]) {
    denied(await read(path, actor)); denied(await patch(path, actor, { adminSuspended: false })); denied(await erase(path, actor));
  }
});
test('active profile edits preserve server lifecycle fields and canonical controls', async () => {
  const f = await fixture(); await handlers.own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'freeze' }));
  allowed(await patch(`users/${f.owner.uid}`, f.owner, { displayName: 'Allowed name' }));
  assert.equal((await db.doc(`users/${f.owner.uid}`).get()).data().security.frozen, true);
});
test('a suspended owner with valid authentication can read status but not edit it', async () => {
  const f = await fixture(); await db.doc(`accountStateControls/${f.owner.uid}`).set({ ...control(), adminSuspended: true });
  await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'disabled' });
  allowed(await read(`users/${f.owner.uid}`, f.owner));
  denied(await patch(`users/${f.owner.uid}`, f.owner, { displayName: 'Not allowed' }));
});
test('a revoked suspended owner cannot even read the private status', async () => {
  const f = await fixture(); await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore: f.owner.authTime });
  denied(await read(`users/${f.owner.uid}`, f.owner));
});
test('personal saved records do not bypass administrative suspension', async () => {
  const f = await fixture(); await db.doc(`accountStateControls/${f.owner.uid}`).set({ ...control(), adminSuspended: true });
  for (const collection of ['saved_posts', 'saved_comments', 'hidden_posts', 'hidden_comments']) {
    denied(await patch(`users/${f.owner.uid}/${collection}/example`, f.owner, { id: 'example' }));
  }
});
test('malformed administrative control cannot authorize social access', async () => {
  const f = await fixture(); const path = `chats/malformed-${f.owner.uid}`;
  await db.doc(path).set({ memberIds: [f.owner.uid, f.actor.uid] });
  for (const data of [{}, { schemaVersion: 1, adminSuspended: 'false' }, { schemaVersion: 0, adminSuspended: false }]) {
    await db.doc(`accountStateControls/${f.owner.uid}`).set(data); denied(await read(path, f.owner));
  }
});
test('an ordinary owner can still read voluntary disabled status and reactivate via server', async () => {
  const f = await fixture(); await handlers.own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'deactivate' }));
  allowed(await read(`users/${f.owner.uid}`, f.owner));
  assert.equal((await handlers.own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'reactivate' }))).accountStatus, 'active');
});
