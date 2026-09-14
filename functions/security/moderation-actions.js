const { HttpsError } = require('firebase-functions/v2/https');
const { Timestamp } = require('firebase-admin/firestore');
// Preserves the existing authorized moderator roster. Changes require a server deployment.
const moderators = new Set(['QYZAB7X4JyXYgMGGwzgV8U4Mu6f2']);
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 512 && !v.includes('/') && !['.', '..'].includes(v);
const statuses = ['pending', 'dismissed', 'actioned', 'restored'];
function createModerationActionHandler({auth, db, FieldValue}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    if (!moderators.has(uid)) throw new HttpsError('permission-denied', 'Moderator access required.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 3 ||
        !validId(input.reportId) || !['reopen','dismiss','restore','hide'].includes(input.action) ||
        !statuses.includes(input.expectedStatus)) throw new HttpsError('invalid-argument', 'Invalid moderation action.');
    return db.runTransaction(async tx => {
      const reportRef = db.collection('community_reports').doc(input.reportId);
      const [report, cutoff, account] = await tx.getAll(reportRef, db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data(), d = report.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      if (!d) throw new HttpsError('not-found', 'Report unavailable.');
      if ((d.status ?? 'pending') !== input.expectedStatus) throw new HttpsError('failed-precondition', 'Report changed. Refresh first.');
      if (!['post','comment','user'].includes(d.type)) throw new HttpsError('failed-precondition', 'Invalid report target.');
      const {action} = input;
      let postRef, postData, commentId;
      if (action === 'hide' || action === 'restore') {
        if (d.type === 'user' && action === 'hide') throw new HttpsError('failed-precondition', 'Account hiding is unsupported.');
        if (d.type !== 'user') {
          const postId = d.type === 'post' ? (d.targetId ?? d.postId) : (d.parentId ?? d.postId);
          commentId = d.commentId ?? d.targetId;
          if (!validId(postId) || (d.type === 'comment' && !validId(commentId))) throw new HttpsError('failed-precondition', 'Invalid report target.');
          postRef = db.doc('community_posts/' + postId);
          const post = await tx.get(postRef); postData = post.data();
          // Never recreate a deleted document with moderation-only fields.
          if (!postData) throw new HttpsError('not-found', 'Post unavailable.');
          if (d.type === 'comment') {
            let matches = 0;
            function walk(rows, depth = 0) {
              if (depth > 30) throw new HttpsError('resource-exhausted', 'Comment nesting limit.');
              for (const c of Array.isArray(rows) ? rows : []) {
                if (c?.id === commentId) matches++;
                if (Array.isArray(c?.replies)) walk(c.replies, depth + 1);
              }
            }
            walk(postData.comments);
            if (matches !== 1) throw new HttpsError('not-found', 'Comment unavailable.');
          }
        }
      }
      const status = {reopen:'pending', dismiss:'dismissed', restore:'restored', hide:'actioned'}[action];
      if (postRef) {
        const changes = {updatedAt: FieldValue.serverTimestamp()};
        if (d.type === 'comment') {
          changes['moderation.hiddenCommentIds'] = action === 'hide' ? FieldValue.arrayUnion(commentId) : FieldValue.arrayRemove(commentId);
        } else {
          changes['moderation.status'] = action === 'hide' ? 'removed' : 'cleared';
          changes['moderation.reportId'] = input.reportId;
          changes['moderation.at'] = FieldValue.serverTimestamp();
          changes['moderation.by'] = uid;
          if (action === 'restore') Object.assign(changes, {reportCount: 0, reportScore: 0});
        }
        tx.update(postRef, changes);
      }
      tx.update(reportRef, {status, reviewedAt: FieldValue.serverTimestamp(), reviewedBy: uid,
        history: FieldValue.arrayUnion({action: {reopen:'reopened', dismiss:'dismissed', restore:'restored', hide:'hidden_by_mod'}[action], by: uid, at: Timestamp.now()})});
      return {status};
    });
  };
}
module.exports = { createModerationActionHandler, moderators };
