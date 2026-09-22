const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readState, changeOwnState, projection, validCutoff } = require('../security/account-state-policy');
const active = () => readState({ accountStatus: 'active' });
test('legacy active profile initializes explicit voluntary defaults', () => {
  assert.deepEqual(active(), { schemaVersion: 1, revision: 0, selfDisabled: false, selfFrozen: false, adminSuspended: false });
});
test('missing legacy status is an active bootstrap, not missing profile', () => {
  assert.equal(readState({}).revision, 0);
  assert.throws(() => readState(undefined), { code: 'not-found' });
});
for (const accountStatus of ['disabled', 'suspended', null, 'unknown']) {
  test(`ambiguous historical account status ${accountStatus} is not silently reactivated`, () => {
    assert.throws(() => readState({ accountStatus }), { code: 'failed-precondition' });
  });
}
test('historical frozen profile requires a reviewed classification', () => {
  assert.throws(() => readState({ security: { frozen: true } }), { code: 'failed-precondition' });
});
for (const profile of [{ accountStatus: 'deleted' }, { isDeleted: true }, { deletionStatus: 'pending' },
  { deletedAt: 5 }, { security: { deletedAt: 5 } }]) {
  test(`terminal deletion marker ${Object.keys(profile)[0]} cannot be cleared by lifecycle`, () => {
    assert.throws(() => readState(profile), { code: 'failed-precondition' });
  });
}
test('even an apparently active profile with a durable deletion job cannot reactivate', () => {
  assert.throws(() => readState({}, undefined, true), { code: 'failed-precondition' });
});
test('self changes are immutable and do not mutate unrelated server metadata', () => {
  const state = { ...active(), note: 'retained' }; const next = changeOwnState(state, 'deactivate');
  assert.equal(state.selfDisabled, false); assert.equal(next.selfDisabled, true); assert.equal(next.note, 'retained');
});
test('reactivate clears voluntary disable and freeze but no administrative state', () => {
  const next = changeOwnState({ ...active(), selfDisabled: true, selfFrozen: true }, 'reactivate');
  assert.deepEqual(projection(next), { accountStatus: 'active', frozen: false });
});
for (const action of ['deactivate', 'reactivate', 'freeze', 'unfreeze']) {
  test(`administrative suspension cannot be changed through self action ${action}`, () => {
    assert.throws(() => changeOwnState({ ...active(), adminSuspended: true }, action), { code: 'permission-denied' });
  });
}
test('admin reinstatement preserves voluntary disabled and frozen flags', () => {
  assert.deepEqual(projection({ selfDisabled: true, selfFrozen: true, adminSuspended: false }), { accountStatus: 'disabled', frozen: true });
});
test('malformed canonical state and mismatched projections fail closed', () => {
  for (const control of [{}, { ...active(), revision: 1, adminSuspended: 'false' }, { ...active(), revision: 0 }]) {
    assert.throws(() => readState({}, control), { code: 'failed-precondition' });
  }
  assert.throws(() => readState({ accountStatus: 'disabled' }, { ...active(), revision: 1 }), { code: 'failed-precondition' });
});
test('cutoff comparison is strictly newer and rejects malformed values', () => {
  assert.equal(validCutoff({ exists: false }, 100), true);
  for (const value of [100, 101, -1, 99.5, '0', null, undefined]) {
    assert.equal(validCutoff({ exists: true, data: () => ({ revokedBefore: value }) }, 100), false);
  }
  assert.equal(validCutoff({ exists: true, data: () => ({ revokedBefore: 99 }) }, 100), true);
});
