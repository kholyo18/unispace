const { HttpsError } = require('firebase-functions/v2/https');
function createOwnProfileCountsHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length) throw new HttpsError('invalid-argument', 'No parameters allowed.');
    async function check(takeQuota) {
      return db.runTransaction(async tx => {
        const quotaRef = db.doc('profileCountsLimits/' + uid);
        const refs = [db.doc('authRevocations/' + uid), db.doc('users/' + uid)];
        if (takeQuota) refs.push(quotaRef);
        const [cutoff, account, quota] = await tx.getAll(...refs);
        if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
        const user = account.data();
        if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
        if (takeQuota) {
          const q = quota.data(), now = Date.now();
          const active = Number.isFinite(q?.windowStart) && now < q.windowStart + 60000;
          const count = active && Number.isSafeInteger(q.count) ? q.count : 0;
          if (count >= 60) throw new HttpsError('resource-exhausted', 'Try again later.');
          tx.set(quotaRef, {windowStart:active ? q.windowStart : now, count:count + 1});
        }
      });
    }
    await check(true);
    const owner = db.doc('users/' + uid);
    const [followers, following, posts] = await Promise.all([
      owner.collection('followers').count().get(), owner.collection('following').count().get(),
      db.collection('community_posts').where('authorId','==',uid).count().get(),
    ]);
    await check(false);
    return {followers:followers.data().count, following:following.data().count, posts:posts.data().count};
  };
}
module.exports = { createOwnProfileCountsHandler };
