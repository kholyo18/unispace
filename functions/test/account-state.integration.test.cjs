const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { db, auth, FieldValue, fixture, callableRequest, close } = require('./helpers/notification-fixture.cjs');
const { createAccountStateHandlers } = require('../security/account-state');
const { createPublicProfileHandler } = require('../security/public-profile');
const { createFollowHandler } = require('../security/follow-relationships');
after(close);
const handlers = createAccountStateHandlers({ auth, db, FieldValue });
const own = (u, action) => handlers.own(callableRequest(u, { action, expectedUid: u.uid }));
const profile = async u => (await db.doc(`users/${u.uid}`).get()).data();
const state = async u => (await db.doc(`accountStateControls/${u.uid}`).get()).data();
async function administrator(user) {
  await auth.setCustomUserClaims(user.uid, { accountAdministrator: true });
  const { email } = await auth.getUser(user.uid);
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Local-only-test-48!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(response.status, 200); const data = await response.json();
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  assert.equal(claims.accountAdministrator, true);
  return { uid: user.uid, token: data.idToken, authTime: claims.auth_time };
}
const administrative = (admin, target, suspended, expectedRevision) => handlers.administrative(
  callableRequest(admin, { userId: target.uid, suspended, expectedRevision, reasonCode: 'security' }));

test('owner disable and reactivate update the existing profile projection', async () => {
  const f = await fixture();
  assert.equal((await own(f.owner, 'deactivate')).accountStatus, 'disabled');
  assert.equal((await profile(f.owner)).accountStatus, 'disabled');
  assert.equal((await state(f.owner)).selfDisabled, true);
  assert.equal((await own(f.owner, 'reactivate')).accountStatus, 'active');
  assert.equal((await profile(f.owner)).security.frozen, false);
});
test('freeze and unfreeze preserve unrelated security identity and privacy fields', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).update({ security: { mfaEnabled: true, loginAlerts: false }, email: 'private@example.test' });
  await own(f.owner, 'freeze'); let p = await profile(f.owner);
  assert.equal(p.security.frozen, true); assert.equal(p.security.mfaEnabled, true); assert.equal(p.security.loginAlerts, false);
  assert.equal(p.email, 'private@example.test'); assert.equal(p.privacy.showEmailOnProfile, false);
  await own(f.owner, 'unfreeze'); p = await profile(f.owner); assert.equal(p.security.frozen, false); assert.equal(p.security.frozenAt, null);
});
test('concurrent duplicate requests are idempotent and do not advance state twice', async () => {
  const f = await fixture(); await Promise.all([own(f.owner, 'freeze'), own(f.owner, 'freeze')]);
  assert.equal((await state(f.owner)).revision, 1);
  assert.equal((await own(f.owner, 'freeze')).changed, false);
});
test('reactivation clears both voluntary flags while unfreeze alone preserves disable', async () => {
  const f = await fixture(); await own(f.owner, 'deactivate'); await own(f.owner, 'freeze');
  const result = await own(f.owner, 'unfreeze'); assert.equal(result.accountStatus, 'disabled');
  await own(f.owner, 'reactivate'); assert.equal((await profile(f.owner)).accountStatus, 'active');
});
test('anonymous identity and extra target fields cannot invoke self changes', async () => {
  const f = await fixture(); await assert.rejects(handlers.own(callableRequest(null, { action: 'freeze' })), { code: 'unauthenticated' });
  await assert.rejects(handlers.own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'freeze', userId: f.actor.uid })), { code: 'invalid-argument' });
  await assert.rejects(handlers.own({ ...callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'freeze' }), auth: { uid: f.actor.uid } }), { code: 'unauthenticated' });
  assert.equal(await state(f.actor), undefined);
});
test('arbitrary state and role payloads are rejected', async () => {
  const f = await fixture();
  for (const data of [{ action: 'suspend' }, { accountStatus: 'active' }, { action: 'reactivate', adminSuspended: false }, [], null]) {
    await assert.rejects(handlers.own(callableRequest(f.owner, data)), { code: 'invalid-argument' });
  }
});
test('missing profiles cannot be recreated through the state service', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).delete();
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'not-found' }); assert.equal(await profile(f.owner), undefined);
});
test('legacy inactive accounts are not classified as voluntary without review', async () => {
  const f = await fixture(); await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'disabled' });
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'failed-precondition' });
  assert.equal((await profile(f.owner)).accountStatus, 'disabled'); assert.equal(await state(f.owner), undefined);
});
test('deletion requests and terminal markers always prevent reactivation', async () => {
  const f = await fixture(); await db.doc(`account_deletion_requests/${f.owner.uid}`).set({ status: 'pending' });
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'failed-precondition' });
  await db.doc(`account_deletion_requests/${f.owner.uid}`).delete();
  await db.doc(`users/${f.owner.uid}`).update({ isDeleted: true });
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'failed-precondition' });
});
test('malformed and revoked cutoffs deny lifecycle changes before state writes', async () => {
  const f = await fixture();
  for (const revokedBefore of ['0', null, -1, f.owner.authTime, f.owner.authTime + 1]) {
    await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore });
    await assert.rejects(own(f.owner, 'freeze'), { code: 'unauthenticated' });
    assert.equal(await state(f.owner), undefined);
  }
});
test('Firebase Auth disabled accounts cannot use the self-service endpoint', async () => {
  const f = await fixture(); await auth.updateUser(f.owner.uid, { disabled: true });
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'unauthenticated' });
});
test('canonical state corruption and out-of-band projection changes fail closed', async () => {
  const f = await fixture(); await own(f.owner, 'freeze');
  await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'disabled' });
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'failed-precondition' });
  await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'active' });
  await db.doc(`accountStateControls/${f.owner.uid}`).update({ adminSuspended: 'false' });
  await assert.rejects(own(f.owner, 'unfreeze'), { code: 'failed-precondition' });
});
test('ordinary users and profile role labels do not grant account administration', async () => {
  const f = await fixture(); await db.doc(`users/${f.actor.uid}`).update({ isAdmin: true, roles: ['admin'], accountAdministrator: true });
  await assert.rejects(administrative(f.actor, f.owner, true, 0), { code: 'permission-denied' });
  assert.equal(await state(f.owner), undefined);
});
test('administration requires both signed and current Auth custom claims', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  await auth.setCustomUserClaims(admin.uid, {});
  await assert.rejects(administrative(admin, f.owner, true, 0), { code: 'permission-denied' });
});
test('administration requires recent authentication', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  const h = createAccountStateHandlers({ auth, db, FieldValue, now: () => (admin.authTime + 301) * 1000 });
  await assert.rejects(h.administrative(callableRequest(admin, { userId: f.owner.uid, suspended: true, expectedRevision: 0, reasonCode: 'security' })), { code: 'unauthenticated' });
});
test('administration rejects self targets stale versions and arbitrary reason text', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  await assert.rejects(administrative(admin, admin, true, 0), { code: 'invalid-argument' });
  await own(f.owner, 'freeze');
  await assert.rejects(administrative(admin, f.owner, true, 0), { code: 'failed-precondition' });
  await assert.rejects(handlers.administrative(callableRequest(admin, { userId: f.owner.uid, suspended: true, expectedRevision: 1, reasonCode: 'unbounded private text' })), { code: 'invalid-argument' });
});
test('administrator suspension atomically records controls projection and auth cutoff', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  const result = await administrative(admin, f.owner, true, 0);
  assert.equal(result.accountStatus, 'disabled');
  const c = await state(f.owner), p = await profile(f.owner);
  assert.equal(c.adminSuspended, true); assert.equal(c.administrativeChangedBy, admin.uid); assert.equal(p.accountStatus, 'disabled');
  const cutoff = (await db.doc(`authRevocations/${f.owner.uid}`).get()).data().revokedBefore;
  assert.ok(cutoff >= f.owner.authTime);
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'unauthenticated' });
});
test('even authentication newer than cutoff cannot self-lift administrative suspension', async () => {
  const f = await fixture(); const admin = await administrator(f.actor); await administrative(admin, f.owner, true, 0);
  // Model a valid post-cutoff session independently of Auth emulator clock ticks.
  // The real emulator-issued token is retained; only the server fixture cutoff changes.
  await db.doc(`authRevocations/${f.owner.uid}`).update({ revokedBefore: f.owner.authTime - 1 });
  for (const action of ['reactivate', 'unfreeze', 'deactivate', 'freeze']) {
    await assert.rejects(own(f.owner, action), { code: 'permission-denied' });
  }
  assert.equal((await state(f.owner)).adminSuspended, true);
});
test('admin reinstatement preserves voluntary disabled and frozen state and prior cutoff', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  await own(f.owner, 'deactivate'); await own(f.owner, 'freeze');
  const suspended = await administrative(admin, f.owner, true, 2);
  const cutoffBefore = (await db.doc(`authRevocations/${f.owner.uid}`).get()).data().revokedBefore;
  const result = await administrative(admin, f.owner, false, suspended.revision);
  assert.equal(result.accountStatus, 'disabled'); assert.equal(result.frozen, true);
  assert.equal((await state(f.owner)).adminSuspended, false);
  assert.equal((await db.doc(`authRevocations/${f.owner.uid}`).get()).data().revokedBefore, cutoffBefore);
});
test('admin cannot reinstate a deleted or pending-deletion target', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  await db.doc(`account_deletion_requests/${f.owner.uid}`).set({ status: 'processing' });
  await assert.rejects(administrative(admin, f.owner, false, 0), { code: 'failed-precondition' });
});
test('a suspended target is unavailable to projected-profile and follow services', async () => {
  const f = await fixture(); const admin = await administrator(f.actor); await administrative(admin, f.owner, true, 0);
  const publicProfile = createPublicProfileHandler({ auth, db });
  await assert.rejects(publicProfile(callableRequest(f.outsider, { userId: f.owner.uid })), { code: 'not-found' });
  const follow = createFollowHandler({ auth, db, FieldValue });
  await assert.rejects(follow(callableRequest(f.outsider, { action: 'follow', userId: f.owner.uid })), { code: 'permission-denied' });
});
test('reinstatement never changes a Firebase Auth console-level disable', async () => {
  const f = await fixture(); const admin = await administrator(f.actor);
  await administrative(admin, f.owner, true, 0); await auth.updateUser(f.owner.uid, { disabled: true });
  await administrative(admin, f.owner, false, 1);
  assert.equal((await auth.getUser(f.owner.uid)).disabled, true);
});
test('concurrent deletion cannot leave an account revived', async () => {
  const f = await fixture(); await own(f.owner, 'deactivate'); const ref = db.doc(`users/${f.owner.uid}`);
  await Promise.allSettled([own(f.owner, 'reactivate'), db.runTransaction(async tx => {
    await tx.get(ref); tx.update(ref, { accountStatus: 'deleted', isDeleted: true });
    tx.set(db.doc(`account_deletion_requests/${f.owner.uid}`), { status: 'pending' });
  })]);
  assert.equal((await profile(f.owner)).accountStatus, 'deleted');
  await assert.rejects(own(f.owner, 'reactivate'), { code: 'failed-precondition' });
});

const { createAccountAccessGuard } = require('../security/account-access-guard');
const guard = createAccountAccessGuard({ db });
test('global callable guard blocks a suspended caller even when the target is healthy', async () => {
  const f = await fixture(); const admin = await administrator(f.actor); await administrative(admin, f.owner, true, 0);
  await db.doc(`authRevocations/${f.owner.uid}`).update({ revokedBefore: f.owner.authTime - 1 });
  const readPublic = guard(createPublicProfileHandler({ auth, db }));
  await assert.rejects(readPublic(callableRequest(f.owner, { userId: f.outsider.uid })), { code: 'permission-denied' });
});
test('global guard never calls the business handler for malformed controls', async () => {
  const f = await fixture(); await db.doc(`accountStateControls/${f.owner.uid}`).set({ adminSuspended: false });
  let called = false; const handler = guard(async () => { called = true; });
  await assert.rejects(handler(callableRequest(f.owner, {})), { code: 'permission-denied' });
  assert.equal(called, false);
});
test('global guard preserves existing handler authorization for active and anonymous callers', async () => {
  const f = await fixture(); let calls = 0; const handler = guard(async request => { calls++; return request.auth?.uid ?? 'anonymous'; });
  assert.equal(await handler(callableRequest(f.owner, {})), f.owner.uid);
  assert.equal(await handler(callableRequest(null, {})), 'anonymous'); assert.equal(calls, 2);
});

test('self intent binding prevents an SDK-switched valid identity from changing the wrong account', async () => {
  const f = await fixture();
  await assert.rejects(handlers.own(callableRequest(f.actor, { action: 'deactivate', expectedUid: f.owner.uid })), { code: 'unauthenticated' });
  assert.equal((await profile(f.actor)).accountStatus, 'active'); assert.equal(await state(f.actor), undefined);
});
