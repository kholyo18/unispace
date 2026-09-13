const { HttpsError } = require('firebase-functions/v2/https');

function createRevokeAllSessionsHandler({ auth, db, FieldValue }) {
  return async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    // Never accept a target uid from the caller.
    if (request.data != null &&
        (typeof request.data !== 'object' || Array.isArray(request.data) || Object.keys(request.data).length)) {
      throw new HttpsError('invalid-argument', 'This operation takes no parameters.');
    }
    const authorization = request.rawRequest?.headers?.authorization || '';
    if (!authorization.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Missing credential.');
    let token;
    try {
      token = await auth.verifyIdToken(authorization.slice(7), true);
    } catch (_) {
      throw new HttpsError('unauthenticated', 'Sign in again.');
    }
    if (token.uid !== uid || !Number.isFinite(token.auth_time)) {
      throw new HttpsError('unauthenticated', 'Invalid credential.');
    }
    const cutoffRef = db.collection('authRevocations').doc(uid);
    const previous = await cutoffRef.get();
    if (previous.exists && token.auth_time <= previous.data().revokedBefore) {
      throw new HttpsError('unauthenticated', 'This sign-in has been revoked.');
    }

    await auth.revokeRefreshTokens(uid);
    const user = await auth.getUser(uid);
    const cutoff = Math.floor(Date.parse(user.tokensValidAfterTime) / 1000);
    if (!Number.isFinite(cutoff)) throw new HttpsError('internal', 'Could not verify revocation.');
    // Concurrent requests must never move the cutoff backwards.
    await db.runTransaction(async (tx) => {
      const current = await tx.get(cutoffRef);
      tx.set(cutoffRef, {
        revokedBefore: Math.max(cutoff, current.data()?.revokedBefore || 0),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    const sessions = await db.collection('users').doc(uid).collection('sessions').get();
    let batch = db.batch();
    let pending = 0;
    for (const session of sessions.docs) {
      if (session.data().isRevoked === true) continue;
      batch.update(session.ref, {
        isRevoked: true,
        revokedAt: FieldValue.serverTimestamp(),
        revokeReason: 'logout_all_server',
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (++pending === 400) { await batch.commit(); batch = db.batch(); pending = 0; }
    }
    if (pending) await batch.commit();
    return { revoked: true };
  };
}

module.exports = { createRevokeAllSessionsHandler };
