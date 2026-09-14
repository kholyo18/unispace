const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;

const { writeReport, contentReasons, text } = require('./report-writer');
const { Timestamp } = require('firebase-admin/firestore');
function createCommentReportHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 4 ||
        !validId(input.postId) || !validId(input.commentId) || !contentReasons.includes(input.reason) ||
        typeof input.details !== 'string' || input.details.length > 10000) {
      throw new HttpsError('invalid-argument', 'Invalid comment report.');
    }
    const uid = request.auth?.uid;
    const visible = await readPost({ ...request, data: { postId: input.postId } });
    let token;
    try { token = await auth.verifyIdToken((request.rawRequest?.headers?.authorization || '').slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    return db.runTransaction(async tx => {
      const ref = db.doc(`community_posts/${input.postId}`), snap = await tx.get(ref), data = snap.data();
      if (removed(data) || data.authorId !== visible.data.authorId) throw new HttpsError('not-found', 'Post unavailable.');
      const owner = data.authorId;
      const paths = [`authRevocations/${uid}`, `users/${uid}`, `users/${owner}`, `users/${owner}/followers/${uid}`,
        ...['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [`users/${uid}/${c}/${owner}`, `users/${owner}/${c}/${uid}`])];
      const [cutoff, actor, profile, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (unavailable(actor.data()) || unavailable(profile.data()) || (uid !== owner && blocks.some(b => b.exists))) {
        throw new HttpsError('permission-denied', 'Post unavailable.');
      }
      const privacy = profile.data().privacy || {};
      const privateAccount = typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : profile.data().profileVisibility === 'private';
      if (uid !== owner && privateAccount && !follower.exists) throw new HttpsError('permission-denied', 'Post is private.');
      const comments = Array.isArray(data.comments) ? data.comments : [];
      const nodes = [];
      function walk(rows, parentId = null, depth = 0) {
        if (depth > 30) throw new HttpsError('resource-exhausted', 'Comment nesting limit exceeded.');
        for (const node of rows) {
          if (!node || typeof node !== 'object' || Array.isArray(node)) continue;
          nodes.push({ node, parentId });
          if (Array.isArray(node.replies) && node.replies.length) walk(node.replies, node.id, depth + 1);
        }
      }
      walk(comments);
      const matches = nodes.filter(x => x.node.id === input.commentId);
      if (matches.length !== 1) throw new HttpsError('not-found', 'Comment unavailable.');
      const comment = matches[0].node;
        // The preflight projection excludes disabled/blocked/hidden comment authors.
        function visibleComment(rows) {
          for (const c of rows || []) {
            if (c.id === input.commentId) return true;
            if (visibleComment(c.replies)) return true;
          }
          return false;
        }
        if (!visibleComment(visible.data.comments)) throw new HttpsError('not-found', 'Comment unavailable.');
        const visited = new Set();
        const queue = [input.commentId];
        const hidden = new Set(Array.isArray(data.moderation?.hiddenCommentIds) ? data.moderation.hiddenCommentIds : []);
        while (queue.length) {
          const id = queue.pop();
          if (visited.has(id)) continue;
          if (visited.size >= 60) throw new HttpsError('resource-exhausted', 'Comment ancestry limit exceeded.');
          visited.add(id);
          const candidates = nodes.filter(x => x.node.id === id);
          if (candidates.length !== 1) throw new HttpsError('not-found', 'Comment unavailable.');
          const { node, parentId } = candidates[0];
          if (removed(node) || hidden.has(id) || !validId(node.authorId)) throw new HttpsError('not-found', 'Comment unavailable.');
          const paths = ['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [
            'users/' + uid + '/' + c + '/' + node.authorId,
            'users/' + node.authorId + '/' + c + '/' + uid,
          ]);
          const [author, ...blocked] = await tx.getAll(db.doc('users/' + node.authorId), ...paths.map(p => db.doc(p)));
          if (unavailable(author.data()) || (uid !== node.authorId && blocked.some(b => b.exists))) {
            throw new HttpsError('permission-denied', 'Comment unavailable.');
          }
          if (parentId) queue.push(parentId);
          if (node.replyToId) queue.push(node.replyToId);
        }
      const reportSnapshot = {text: text(comment.text, 100000), authorId: comment.authorId,
        authorName: text(comment.authorName ?? comment.author, 200),
        mediaUrl: text(comment.mediaUrl, 4096), mediaType: text(comment.mediaType, 100)};
      if (comment.createdAt instanceof Timestamp) reportSnapshot.createdAt = comment.createdAt;
      return writeReport({tx, db, FieldValue, uid, type: 'comment', targetId: input.commentId,
        postId: input.postId, ownerId: comment.authorId, ownerName: reportSnapshot.authorName,
        snapshot: reportSnapshot, reason: input.reason, details: input.details});
    });
  };
}
module.exports = { createCommentReportHandler };
