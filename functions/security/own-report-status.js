const { HttpsError } = require('firebase-functions/v2/https');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
function createOwnReportStatusHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 3 ||
        !['post','comment','user'].includes(input.type) || !validId(input.targetId) ||
        (input.type === 'comment' ? !validId(input.parentId) : input.parentId !== null)) {
      throw new HttpsError('invalid-argument', 'Invalid report target.');
    }
    const id = uid + '_' + (input.type === 'post' ? '' : input.type + '_') + input.targetId;
    return db.runTransaction(async tx => {
      const quotaRef = db.doc('communityReportStatusLimits/' + uid);
      const [cutoff, account, report, quota] = await tx.getAll(db.doc('authRevocations/' + uid),
        db.doc('users/' + uid), db.doc('community_reports/' + id), quotaRef);
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      const q = quota.data(), now = Date.now();
      const active = Number.isFinite(q?.windowStart) && now < q.windowStart + 60000;
      const count = active && Number.isSafeInteger(q.count) ? q.count : 0;
      if (count >= 120) throw new HttpsError('resource-exhausted', 'Try again later.');
      const d = report.data();
      if (d && (d.reporterId !== uid || d.type !== input.type ||
          (d.targetId ?? (input.type === 'post' ? d.postId : d.commentId)) !== input.targetId ||
          (input.type === 'comment' && (d.parentId ?? d.postId) !== input.parentId))) {
        throw new HttpsError('failed-precondition', 'Report identity mismatch.');
      }
      tx.set(quotaRef, {windowStart: active ? q.windowStart : now, count:count + 1});
      // Only existence of the caller's own report, never moderation details or another user's report.
      return {exists: report.exists};
    });
  };
}
module.exports = { createOwnReportStatusHandler };
