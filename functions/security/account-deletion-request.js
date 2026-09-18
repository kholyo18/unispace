const { HttpsError } = require('firebase-functions/v2/https');

function createAccountDeletionRequestHandler({ auth, db, FieldValue }) {
  return async request => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');

    const input = request.data;
    if (input != null &&
        (typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length)) {
      throw new HttpsError('invalid-argument', 'This operation takes no parameters.');
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
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }

    const cutoffRef = db.doc(`authRevocations/${uid}`);
    const deletionRef = db.doc(`accountDeletionRequests/${uid}`);

    return db.runTransaction(async tx => {
      const [cutoff, existing] = await tx.getAll(cutoffRef, deletionRef);
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) {
        throw new HttpsError('unauthenticated', 'Session revoked.');
      }

      if (existing.exists) {
        const prior = existing.data() || {};
        if (prior.uid !== uid) {
          throw new HttpsError('failed-precondition', 'Deletion request identity mismatch.');
        }
        if (prior.status === 'requested' || prior.status === 'processing') {
          return {
            requested: true,
            alreadyRequested: true,
            status: prior.status,
            operationalTargetDays: 30,
          };
        }
      }

      tx.set(deletionRef, {
        uid,
        status: 'requested',
        source: 'app',
        policyVersion: '1.0',
        operationalTargetDays: 30,
        requestedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        requested: true,
        alreadyRequested: false,
        status: 'requested',
        operationalTargetDays: 30,
      };
    });
  };
}

module.exports = { createAccountDeletionRequestHandler };
