const { HttpsError } = require('firebase-functions/v2/https');
const { moderators } = require('./moderation-actions');
const { encode } = require('./moderation-inbox');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 512 && !v.includes('/') && !['.','..'].includes(v);
const pick = (d, keys) => Object.fromEntries(keys.filter(k => d[k] !== undefined).map(k => [k,d[k]]));
function createModerationPreviewHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    if (!moderators.has(uid)) throw new HttpsError('permission-denied', 'Moderator access required.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 || !validId(input.reportId)) throw new HttpsError('invalid-argument', 'Invalid report.');
    return db.runTransaction(async tx => {
      const [cutoff, account, report] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid), db.doc('community_reports/' + input.reportId));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data(), r = report.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      if (!r) throw new HttpsError('not-found', 'Report unavailable.');
      if (r.type === 'user') return {post:null, unavailable:true};
      if (!['post','comment'].includes(r.type)) throw new HttpsError('failed-precondition', 'Invalid report type.');
      const id = r.type === 'post' ? (r.targetId ?? r.postId) : (r.parentId ?? r.postId);
      if (!validId(id)) throw new HttpsError('failed-precondition', 'Invalid target.');
      const doc = await tx.get(db.doc('community_posts/' + id)), data = doc.data();
      if (!data) return {post:null, unavailable:true};
      // Moderator inspection may include hidden/private content, but only the target of a stored report.
      const result = pick(data,['title','body','authorName','author','authorId','authorPhotoUrl','createdAt','imageUrls','videoUrls','tags']);
      result.comments = [];
      if (r.type === 'comment') {
        const cid = r.commentId ?? r.targetId, matches = [];
        if (!validId(cid)) throw new HttpsError('failed-precondition', 'Invalid comment.');
        function walk(rows, depth = 0) {
          if (depth > 30) throw new HttpsError('resource-exhausted', 'Comment nesting limit.');
          for (const c of Array.isArray(rows) ? rows : []) {
            if (c?.id === cid) matches.push(c);
            if (Array.isArray(c?.replies)) walk(c.replies,depth + 1);
          }
        }
        walk(data.comments);
        if (matches.length !== 1) return {post:null, unavailable:true};
        result.comments = [pick(matches[0],['id','text','author','authorName','authorId','authorPhotoUrl','createdAt','mediaUrl','mediaType','isEdited'])];
      }
      const response = {post:{id, data:encode(result)}, unavailable:false};
      if (Buffer.byteLength(JSON.stringify(response)) > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Preview too large.');
      return response;
    });
  };
}
module.exports = { createModerationPreviewHandler };
