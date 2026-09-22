// Profile edits stay compatible; voluntary lifecycle writes now use the server.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { db, auth, FieldValue, callableRequest, fixture, patch, denied, allowed, close } = require('./helpers/notification-fixture.cjs');
after(close);
test('client cannot add server identity roles counts or onboarding fields', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  for (const data of [{ uid: 'other' }, { email: 'other@example.test' }, { username: 'other' },
    { roles: ['admin'] }, { isAdmin: true }, { followersCount: 999 }, { onboardingCompleted: true }, { fcmToken: 'raw-token' }]) {
    denied(await patch(path, f.owner, data));
  }
});
test('protected fields cannot be deleted or overwritten through a full profile replacement', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  await db.doc(path).update({ email: 'owner@example.test', uid: f.owner.uid });
  denied(await patch(path, f.owner, {}, ['email']));
  denied(await patch(path, f.owner, { uid: 'other' }));
});
test('unknown nested security fields cannot be added changed or removed', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  await db.doc(path).update({ security: { serverOwned: true, loginAlerts: true } });
  for (const security of [{ serverOwned: false, loginAlerts: true }, { loginAlerts: true },
    { serverOwned: true, loginAlerts: true, admin: true }]) denied(await patch(path, f.owner, { security }));
});
test('legitimate display and academic settings remain editable', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  allowed(await patch(path, f.owner, { displayName: 'Updated name', academic: { college: 'College', major: 'Major', level: 'Level' } }));
  assert.equal((await db.doc(path).get()).data().displayName, 'Updated name');
});
test('academic map rejects hidden fields and invalid value types', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  denied(await patch(path, f.owner, { academic: { college: 'College', admin: true } }));
  denied(await patch(path, f.owner, { academic: { college: 7 } }));
});
test('legacy backup codes can only be cleared not replaced with credentials', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  await db.doc(path).update({ security: { backupCodes: ['obsolete'], loginAlerts: true } });
  denied(await patch(path, f.owner, { security: { backupCodes: ['new-credential'], loginAlerts: true } }));
  allowed(await patch(path, f.owner, { security: { backupCodes: [], loginAlerts: true } }));
});
test('revoked owners cannot change otherwise editable profile fields', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore: f.owner.authTime });
  denied(await patch(path, f.owner, { displayName: 'Not allowed' }));
});
test('voluntary deactivate and reactivate remain compatible through the lifecycle service', async () => {
  const f = await fixture(), path = `users/${f.owner.uid}`;
  const { own } = require('../security/account-state').createAccountStateHandlers({ auth, db, FieldValue });
  await own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'deactivate' }));
  assert.equal((await db.doc(path).get()).data().accountStatus, 'disabled');
  await own(callableRequest(f.owner, { expectedUid: f.owner.uid, action: 'reactivate' }));
  assert.equal((await db.doc(path).get()).data().accountStatus, 'active');
});
