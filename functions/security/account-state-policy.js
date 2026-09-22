// Pure lifecycle policy. Canonical controls are server-owned; profile flags are
// compatibility projections, never a caller-supplied administrative decision.
const actions = new Set(['deactivate', 'reactivate', 'freeze', 'unfreeze']);
const object = value => value && typeof value === 'object' && !Array.isArray(value);
function fail(code, message) { const error = new Error(message); error.code = code; throw error; }
function projection(state) {
  return { accountStatus: state.adminSuspended || state.selfDisabled ? 'disabled' : 'active', frozen: state.selfFrozen };
}
function readState(profile, control, deletionExists = false) {
  if (!object(profile)) fail('not-found', 'Account unavailable.');
  if (deletionExists || profile.accountStatus === 'deleted' || profile.isDeleted === true ||
      profile.deletionStatus != null || profile.deletedAt != null || profile.security?.deletedAt != null) {
    fail('failed-precondition', 'Deletion cannot be reversed here.');
  }
  if (profile.security != null && !object(profile.security)) fail('failed-precondition', 'Account state needs review.');
  if (control == null) {
    // Old disabled/frozen flags have ambiguous provenance. Never silently turn a
    // historical administrative restriction into a self-service setting.
    if (![undefined, 'active'].includes(profile.accountStatus) ||
        ![undefined, false].includes(profile.security?.frozen)) {
      fail('failed-precondition', 'Legacy inactive state requires reviewed migration.');
    }
    return { schemaVersion: 1, revision: 0, selfDisabled: false, selfFrozen: false, adminSuspended: false };
  }
  if (!object(control) || control.schemaVersion !== 1 || !Number.isSafeInteger(control.revision) ||
      control.revision < 1 || control.revision >= Number.MAX_SAFE_INTEGER ||
      ['selfDisabled', 'selfFrozen', 'adminSuspended'].some(k => typeof control[k] !== 'boolean')) {
    fail('failed-precondition', 'Account controls need review.');
  }
  const view = projection(control);
  if ((profile.accountStatus ?? 'active') !== view.accountStatus || (profile.security?.frozen ?? false) !== view.frozen) {
    fail('failed-precondition', 'Account state changed outside the lifecycle service.');
  }
  return { ...control };
}
function changeOwnState(state, action) {
  if (!actions.has(action)) fail('invalid-argument', 'Invalid account action.');
  if (state.adminSuspended) fail('permission-denied', 'Administrative restriction requires support.');
  const next = { ...state };
  if (action === 'deactivate') next.selfDisabled = true;
  if (action === 'reactivate') { next.selfDisabled = false; next.selfFrozen = false; }
  if (action === 'freeze') next.selfFrozen = true;
  if (action === 'unfreeze') next.selfFrozen = false;
  return next;
}
function validCutoff(snapshot, authTime) {
  if (!snapshot.exists) return true;
  const value = snapshot.data()?.revokedBefore;
  return Number.isSafeInteger(value) && value >= 0 && authTime > value;
}
module.exports = { actions, projection, readState, changeOwnState, validCutoff };
