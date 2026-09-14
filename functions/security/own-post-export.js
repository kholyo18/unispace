const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath, Timestamp } = require('firebase-admin/firestore');
function jsonValue(value, depth = 0) {
  if (depth > 30) throw new HttpsError('resource-exhausted', 'Export nesting limit.');
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(v => jsonValue(v,depth + 1));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k,v]) => [k,jsonValue(v,depth + 1)]));
  return value;
}
function createOwnPostExportHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        !(input.cursor === null || (typeof input.cursor === 'string' && input.cursor.length > 0 && input.cursor.length <= 128 &&
        !input.cursor.includes('/') && !['.','..'].includes(input.cursor)))) throw new HttpsError('invalid-argument', 'Invalid sync page.');
    return db.runTransaction(async tx => {
      const [cutoff, account] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      let query = db.collection('community_posts').where('authorId','==',uid).orderBy(FieldPath.documentId());
      if (input.cursor) query = query.startAfter(input.cursor);
      const page = await tx.get(query.limit(50));
      const fields = ['title','body','authorId','authorName','authorPhotoUrl','createdAt','updatedAt',
        'imageUrls','videoUrls','tags','polls','pollSlides','isRepost','isEdited','votes','commentsCount'];
      const posts = []; let bytes = 0, cursor = input.cursor;
      for (const doc of page.docs) {
        const data = doc.data();
        const post = {id:doc.id};
        for (const key of fields) if (data[key] !== undefined) post[key] = jsonValue(data[key]);
        // Repost snapshots can contain other people's content; export references only.
        if (data.repostOf && typeof data.repostOf === 'object') {
          post.repostOf = Object.fromEntries(['postId','commentId','type'].filter(k => typeof data.repostOf[k] === 'string').map(k => [k,data.repostOf[k]]));
        }
        post.comments = [];
        function collect(rows, depth = 0) {
          if (depth > 30) throw new HttpsError('resource-exhausted', 'Comment nesting limit.');
          for (const comment of Array.isArray(rows) ? rows : []) {
            if (comment?.authorId === uid) post.comments.push(Object.fromEntries(
              ['id','authorId','text','createdAt','replyToId','mediaUrl','mediaType','isEdited']
                .filter(k => comment[k] !== undefined).map(k => [k,jsonValue(comment[k])])));
            if (Array.isArray(comment?.replies)) collect(comment.replies,depth + 1);
          }
        }
        collect(data.comments);
        const size = Buffer.byteLength(JSON.stringify(post));
        if (size > 4 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Post export too large.');
        if (posts.length && bytes + size > 4 * 1024 * 1024) break;
        posts.push(post); bytes += size; cursor = doc.id;
      }
      return {posts, cursor, exhausted:posts.length === page.size && page.size < 50};
    });
  };
}
module.exports = { createOwnPostExportHandler };
