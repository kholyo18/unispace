const { HttpsError } = require('firebase-functions/v2/https');
const { actions, projection, readState, changeOwnState, validCutoff } = require('./account-state-policy');
const id = value => typeof value === 'string' && value.length > 0 && value.length <= 128 &&
  !value.includes('/') && !['.', '..'].includes(value);
const object = value => value && typeof value === 'object' && !Array.isArray(value);
const reasons = new Set(['policy', 'abuse', 'security', 'reviewed']);
function policy(call) {
  try { return call(); } catch (error) {
    if (['not-found', 'failed-precondition', 'permission-denied', 'invalid-argument'].includes(error.code)) {
      throw new HttpsError(error.code, error.message);
    }
    throw error;
  }
}
function createAccountStateHandlers({ auth, db, FieldValue, now = () => Date.now() }) {
  async function verify(request) {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization;
    if (!id(uid) || typeof header !== 'string' || !header.startsWith('Bearer ')) {
      throw new HttpsError('unauthenticated', 'Sign in first.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isSafeInteger(token.auth_time) || token.auth_time <= 0 ||
        token.auth_time > Math.floor(now() / 1000) + 60 || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    return { uid, token };
  }
  function write(tx, ref, controlRef, before, next, actor, action, administrative = null) {
    const changed = before.revision === 0 || ['selfDisabled', 'selfFrozen', 'adminSuspended'].some(k => before[k] !== next[k]);
    const view = projection(next);
    if (!changed) return { ...view, revision: before.revision, changed: false };
    const timestamp = FieldValue.serverTimestamp();
    const revision = before.revision + 1;
    const patch = { accountStatus: view.accountStatus, 'security.frozen': view.frozen, updatedAt: timestamp };
    const oldView = projection(before);
    if (oldView.accountStatus !== view.accountStatus) {
      patch[view.accountStatus === 'disabled' ? 'disabledAt' : 'reactivatedAt'] = timestamp;
    }
    if (oldView.frozen !== view.frozen || before.revision === 0) patch['security.frozenAt'] = view.frozen ? timestamp : null;
    tx.update(ref, patch);
    tx.set(controlRef, { schemaVersion: 1, revision, selfDisabled: next.selfDisabled,
      selfFrozen: next.selfFrozen, adminSuspended: next.adminSuspended,
      lastAction: action, updatedAt: timestamp,
      ...(administrative ? { administrativeChangedBy: actor, administrativeChangedAt: timestamp,
        administrativeReason: administrative } : {}) }, { merge: true });
    return { ...view, revision, changed: true };
  }
  async function own(request) {
    const { uid, token } = await verify(request), input = request.data;
    if (!object(input) || Object.keys(input).length !== 2 || !actions.has(input.action) || !id(input.expectedUid)) {
      throw new HttpsError('invalid-argument', 'An action and expected caller are required.');
    }
    // expectedUid is an intent binding, NOT an alternate target or authority.
    if (input.expectedUid !== uid) throw new HttpsError('unauthenticated', 'Account changed.');
    return db.runTransaction(async tx => {
      const ref = db.doc(`users/${uid}`), controlRef = db.doc(`accountStateControls/${uid}`);
      const [cutoff, profile, control, deletion] = await tx.getAll(db.doc(`authRevocations/${uid}`),
        ref, controlRef, db.doc(`account_deletion_requests/${uid}`));
      if (!validCutoff(cutoff, token.auth_time)) throw new HttpsError('unauthenticated', 'Session revoked.');
      const before = policy(() => readState(profile.data(), control.data(), deletion.exists));
      const next = policy(() => changeOwnState(before, input.action));
      return write(tx, ref, controlRef, before, next, uid, input.action);
    });
  }
  async function administrative(request) {
    const { uid, token } = await verify(request);
    // No profile role or hard-coded content-moderator ID confers this authority.
    // Both the signed claim and current Auth record must have the explicit role.
    if (token.accountAdministrator !== true) throw new HttpsError('permission-denied', 'Account administrator required.');
    const current = await auth.getUser(uid);
    if (current.disabled || current.customClaims?.accountAdministrator !== true) {
      throw new HttpsError('permission-denied', 'Account administrator required.');
    }
    if (Math.floor(now() / 1000) - token.auth_time > 300) {
      throw new HttpsError('unauthenticated', 'Reauthenticate before administration.');
    }
    const i = request.data;
    if (!object(i) || Object.keys(i).length !== 4 || !id(i.userId) || i.userId === uid ||
        typeof i.suspended !== 'boolean' || !Number.isSafeInteger(i.expectedRevision) || i.expectedRevision < 0 ||
        !reasons.has(i.reasonCode)) throw new HttpsError('invalid-argument', 'Invalid administrative transition.');
    try { await auth.getUser(i.userId); } catch (error) {
      if (error.code === 'auth/user-not-found') throw new HttpsError('not-found', 'Account unavailable.');
      throw error;
    }
    return db.runTransaction(async tx => {
      const ref = db.doc(`users/${i.userId}`), controlRef = db.doc(`accountStateControls/${i.userId}`);
      const targetCutoffRef = db.doc(`authRevocations/${i.userId}`);
      const [cutoff, actor, actorControl, profile, control, deletion, targetCutoff] = await tx.getAll(
        db.doc(`authRevocations/${uid}`), db.doc(`users/${uid}`), db.doc(`accountStateControls/${uid}`),
        ref, controlRef, db.doc(`account_deletion_requests/${i.userId}`), targetCutoffRef);
      if (!validCutoff(cutoff, token.auth_time)) throw new HttpsError('unauthenticated', 'Session revoked.');
      const actorState = policy(() => readState(actor.data(), actorControl.data()));
      if (actorState.adminSuspended || actorState.selfDisabled || actorState.selfFrozen) {
        throw new HttpsError('permission-denied', 'Administrator account unavailable.');
      }
      const before = policy(() => readState(profile.data(), control.data(), deletion.exists));
      if (before.revision !== i.expectedRevision) throw new HttpsError('failed-precondition', 'Account changed. Refresh first.');
      const previousCutoff = targetCutoff.exists ? targetCutoff.data()?.revokedBefore : 0;
      if (!Number.isSafeInteger(previousCutoff) || previousCutoff < 0) {
        throw new HttpsError('failed-precondition', 'Revocation state needs review.');
      }
      const next = { ...before, adminSuspended: i.suspended };
      const result = write(tx, ref, controlRef, before, next, uid, i.suspended ? 'suspend' : 'reinstate', i.reasonCode);
      if (i.suspended && result.changed) {
        // Atomic application-side cutoff, not a claim that Firebase Auth tokens
        // or a specific physical device were revoked at the Auth provider.
        tx.set(targetCutoffRef, { revokedBefore: Math.max(previousCutoff, Math.floor(now() / 1000)),
          updatedAt: FieldValue.serverTimestamp(), reason: 'administrative-suspension' }, { merge: true });
      }
      return result;
    });
  }
  return { own, administrative };
}
module.exports = { createAccountStateHandlers };
