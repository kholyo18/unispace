const { HttpsError } = require('firebase-functions/v2/https');
function createUsernameCheckHandler({auth, db, now = Date.now}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const i = request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== 1 ||
        typeof i.username !== 'string' || !/^[a-zA-Z0-9_]{3,20}$/.test(i.username)) {
      throw new HttpsError('invalid-argument', 'Invalid username.');
    }
    return db.runTransaction(async tx => {
      const limit = db.doc('usernameCheckLimits/' + uid);
      const [cutoff, profile, quota] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid), limit);
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = profile.data();
      // Onboarding is allowed before a profile document exists.
      if (user && (['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true)) throw new HttpsError('permission-denied', 'Account unavailable.');
      const timestamp = now(), previous = quota.data();
      const active = previous && timestamp < previous.windowStart + 60000;
      const count = active ? previous.count : 0;
      if (count >= 30) throw new HttpsError('resource-exhausted', 'Try again later.');
      const matches = await tx.get(db.collection('users').where('username', '==', i.username).limit(2));
      const reservation = await tx.get(db.doc('usernameReservations/' + i.username));
      const available = (!reservation.exists || reservation.data().uid === uid) && !matches.docs.some(doc => doc.id !== uid);
      tx.set(limit, {windowStart:active ? previous.windowStart : timestamp, count:count + 1});
      return {username:i.username, available};
    });
  };
}
module.exports = {createUsernameCheckHandler};
