const { HttpsError } = require('firebase-functions/v2/https');

function createSessionBootstrapHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        typeof input.sessionId !== 'string' || !/^[a-zA-Z0-9_-]{1,200}$/.test(input.sessionId)) {
      throw new HttpsError('invalid-argument', 'Invalid session ID.');
    }
    return db.runTransaction(async tx => {
      const profileRef = db.doc('users/' + uid);
      const [cutoff, profile, session] = await tx.getAll(
        db.doc('authRevocations/' + uid), profileRef,
        profileRef.collection('sessions').doc(input.sessionId));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = profile.data();
      if (user?.accountStatus === 'deleted' || user?.isDeleted === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      if (!session.exists || session.data().isRevoked !== false || session.data().sessionId !== input.sessionId) {
        throw new HttpsError('failed-precondition', 'Session unavailable.');
      }
      // This is display metadata, not an authorization grant. Voluntarily disabled
      // or frozen accounts still need login to reach the existing reactivation UI.
      // Session creation remains client-owned pending the separate rules migration.
      if (user?.currentSessionId !== input.sessionId) tx.set(profileRef, {currentSessionId:input.sessionId}, {merge:true});
      return {uid, sessionId:input.sessionId};
    });
  };
}
module.exports = {createSessionBootstrapHandler};
