const { HttpsError } = require('firebase-functions/v2/https');
const { validCutoff } = require('./account-state-policy');

const DELETE_WITHIN_DAYS = 30;
const DELETE_WINDOW_MS = DELETE_WITHIN_DAYS * 24 * 60 * 60 * 1000;

function createAccountDeletionRequestHandler({
  auth,
  db,
  FieldValue,
  Timestamp,
  revokeAllSessions,
  now = () => Date.now(),
}) {
  if (typeof revokeAllSessions !== 'function') {
    throw new TypeError('revokeAllSessions dependency is required');
  }

  return async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');

    const data = request.data;
    if (!data || typeof data !== 'object' || Array.isArray(data) ||
        data.confirm !== true || Object.keys(data).some((key) => !['confirm', 'expectedUid'].includes(key)) ||
        (Object.hasOwn(data, 'expectedUid') && (typeof data.expectedUid !== 'string' || !data.expectedUid.length))) {
      throw new HttpsError('invalid-argument', 'Explicit confirmation is required.');
    }

    const authorization = request.rawRequest?.headers?.authorization || '';
    if (!authorization.startsWith('Bearer ')) {
      throw new HttpsError('unauthenticated', 'Missing credential.');
    }

    let token;
    try {
      token = await auth.verifyIdToken(authorization.slice(7), true);
    } catch (_) {
      throw new HttpsError('unauthenticated', 'Sign in again.');
    }
    if (token.uid !== uid || !Number.isSafeInteger(token.auth_time) || token.auth_time <= 0 || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid credential.');
    }

    // Optional for older clients; current clients bind confirmation to the
    // expected account even if the SDK changes credentials during an await.
    if (Object.hasOwn(data, 'expectedUid') && data.expectedUid !== uid) {
      throw new HttpsError('unauthenticated', 'Account changed.');
    }
    const requestRef = db.collection('account_deletion_requests').doc(uid);
    const userRef = db.collection('users').doc(uid);
    const deleteBy = Timestamp.fromMillis(now() + DELETE_WINDOW_MS);
    let alreadyRequested = false;

    await db.runTransaction(async (tx) => {
      const cutoffRef = db.collection('authRevocations').doc(uid);
      const cutoff = await tx.get(cutoffRef);
      if (!validCutoff(cutoff, token.auth_time)) {
        throw new HttpsError('unauthenticated', 'Session revoked.');
      }
      const existing = await tx.get(requestRef);
      if (cutoff.data()?.storageAllowed !== false) {
        tx.set(cutoffRef, { revokedBefore: cutoff.data()?.revokedBefore ?? 0, storageAllowed: false }, { merge: true });
      }
      if (existing.exists && existing.data()?.status === 'pending') {
        alreadyRequested = true;
        return;
      }

      tx.set(requestRef, {
        uid,
        status: 'pending',
        requestedAt: FieldValue.serverTimestamp(),
        deleteBy,
        requestedFrom: 'app',
      }, { merge: true });

      tx.set(userRef, {
        deletionStatus: 'pending',
        deletionRequestedAt: FieldValue.serverTimestamp(),
        deletionDeleteBy: deleteBy,
        accountStatus: 'deleted',
        isDeleted: true,
        deletedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    await revokeAllSessions({
      ...request,
      data: {},
    });

    // Remove the Firebase Authentication account immediately after the durable
    // deletion request and revocation cutoff exist. The scheduled purge remains
    // idempotent and removes Firestore/Storage data even if it runs later.
    try {
      await auth.deleteUser(uid);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') throw error;
    }

    return {
      status: 'pending',
      deletionWithinDays: DELETE_WITHIN_DAYS,
      alreadyRequested,
    };
  };
}

module.exports = {
  DELETE_WITHIN_DAYS,
  createAccountDeletionRequestHandler,
};
