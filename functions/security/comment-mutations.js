const { updateLikeNotification } = require('./like-notifications');
const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;

function createCommentMutationHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) ||
        !['edit', 'delete', 'vote'].includes(input.action) || !validId(input.postId) || !validId(input.commentId) ||
        Object.keys(input).length !== (input.action === 'delete' ? 3 : 4) ||
        (input.action === 'vote' && ![-1, 0, 1].includes(input.vote)) ||
        (input.action === 'edit' && (typeof input.text !== 'string' || !input.text.trim() || input.text.length > 10000))) {
      throw new HttpsError('invalid-argument', 'Invalid comment operation.');
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
      if (input.action === 'vote') {
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
        const up = new Set(Array.isArray(comment.upvotedBy) ? comment.upvotedBy : []);
        const down = new Set(Array.isArray(comment.downvotedBy) ? comment.downvotedBy : []);
        const wasLiked = up.has(uid);
        const previousVote = (up.has(uid) ? 1 : 0) - (down.has(uid) ? 1 : 0);
        const votes = (Number.isSafeInteger(comment.votes) ? comment.votes : 0) - previousVote + input.vote;
        up.delete(uid); down.delete(uid);
        if (input.vote === 1) up.add(uid);
        if (input.vote === -1) down.add(uid);
        comment.upvotedBy = [...up]; comment.downvotedBy = [...down]; comment.votes = votes;
        await updateLikeNotification({ tx, db, FieldValue, uid, ownerId: comment.authorId,
          postId: input.postId, commentId: input.commentId, actor: actor.data(),
          wasLiked, liked: input.vote === 1, upvoters: up });
        tx.update(ref, { comments, updatedAt: FieldValue.serverTimestamp() });
        return { action: 'vote', commentId: input.commentId, vote: input.vote, votes, previousVote, ownerId: comment.authorId };
      }
      if (comment.authorId !== uid) throw new HttpsError('permission-denied', 'Only the comment author may change it.');
      const mirrorRef = db.doc(`users/${uid}/authored_comments/${input.commentId}`);
      const mirror = input.action === 'edit' ? await tx.get(mirrorRef) : null;
      if (input.action === 'edit') {
        comment.text = input.text.trim();
        comment.isEdited = true;
        if (mirror.exists && mirror.data().postId === input.postId) {
          tx.update(mirrorRef, { text: comment.text, isEdited: true });
        }
      } else {
        const removedIds = new Set([input.commentId]);
        // Cover both nested replies and legacy flat replyToId chains.
        let changed = true;
        while (changed) {
          changed = false;
          for (const { node, parentId } of nodes) {
            if (!removedIds.has(node.id) && (removedIds.has(parentId) || removedIds.has(node.replyToId))) {
              removedIds.add(node.id); changed = true;
            }
          }
        }
        const deleted = nodes.filter(x => removedIds.has(x.node.id));
        if (deleted.length > 450) throw new HttpsError('resource-exhausted', 'This thread requires a larger deletion job.');
        function prune(rows) {
          return rows.filter(n => !removedIds.has(n?.id)).map(n => {
            if (n && Array.isArray(n.replies)) n.replies = prune(n.replies);
            return n;
          });
        }
        data.comments = prune(comments);
        const refs = deleted.filter(({ node }) => validId(node.authorId) && validId(node.id))
          .map(({ node }) => db.doc(`users/${node.authorId}/authored_comments/${node.id}`));
        const mirrors = refs.length ? await tx.getAll(...refs) : [];
        for (const index of mirrors) {
          if (index.exists && index.data().postId === input.postId) tx.delete(index.ref);
        }
      }
      const next = input.action === 'edit' ? comments : data.comments;
      const count = next.filter(c => c && !c.replyToId).length;
      tx.update(ref, { comments: next, commentsCount: count, updatedAt: FieldValue.serverTimestamp() });
      return { action: input.action, commentId: input.commentId, commentsCount: count };
    });
  };
}
module.exports = { createCommentMutationHandler };
