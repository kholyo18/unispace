const { updateLikeNotification } = require('./like-notifications');
const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;

function createPostVoteHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !validId(input.postId) || ![-1, 0, 1].includes(input.vote)) throw new HttpsError('invalid-argument', 'Invalid vote.');
    const uid = request.auth?.uid;
    // Includes original-post/comment authorization for reposts and the shared request limit.
    const visible = await readPost({ ...request, data: { postId: input.postId } });
    const header = request.rawRequest?.headers?.authorization || '';
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    return db.runTransaction(async tx => {
      const ref = db.doc(`community_posts/${input.postId}`);
      const snapshot = await tx.get(ref), data = snapshot.data();
      if (removed(data) || data.authorId !== visible.data.authorId) throw new HttpsError('not-found', 'Post unavailable.');
      const owner = data.authorId;
      const paths = [`authRevocations/${uid}`, `users/${uid}`, `users/${owner}`, `users/${owner}/followers/${uid}`,
        ...['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [`users/${uid}/${c}/${owner}`, `users/${owner}/${c}/${uid}`])];
      const [cutoff, actor, profile, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (unavailable(actor.data()) || unavailable(profile.data()) || (uid !== owner && blocks.some(b => b.exists))) {
        throw new HttpsError('permission-denied', 'Post unavailable.');
      }
      const p = profile.data(), privacy = p.privacy || {};
      const privateAccount = typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : p.profileVisibility === 'private';
      if (uid !== owner && privateAccount && !follower.exists) throw new HttpsError('permission-denied', 'Post is private.');
      const up = new Set(Array.isArray(data.upvotedBy) ? data.upvotedBy : []);
      const down = new Set(Array.isArray(data.downvotedBy) ? data.downvotedBy : []);
      const wasLiked = up.has(uid);
      const previousVote = (up.has(uid) ? 1 : 0) - (down.has(uid) ? 1 : 0);
      const votes = (Number.isSafeInteger(data.votes) ? data.votes : 0) - previousVote + input.vote;
      // Desired-state writes make repeating the same request idempotent.
      up.delete(uid); down.delete(uid);
      if (input.vote === 1) up.add(uid);
      if (input.vote === -1) down.add(uid);
      await updateLikeNotification({ tx, db, FieldValue, uid, ownerId: owner, postId: input.postId,
        actor: actor.data(), wasLiked, liked: input.vote === 1, upvoters: up });
      tx.update(ref, { upvotedBy: [...up], downvotedBy: [...down], votes, updatedAt: FieldValue.serverTimestamp() });
      return { votes, vote: input.vote, previousVote, ownerId: owner };
    });
  };
}
module.exports = { createPostVoteHandler };
