const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const { searchKeywords } = require('./edit-post');
const { createHash } = require('crypto');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const str = v => typeof v === 'string' ? v.trim() : '';
const rows = v => Array.isArray(v) ? v : [];
const unavailable = d => !d || ['disabled','deleted'].includes(d.accountStatus) || d.security?.frozen === true;
function pathTo(raw, id, path = []) {
  if (path.length >= 30) throw new HttpsError('resource-exhausted','Reply nesting limit exceeded.');
  for (const c of rows(raw)) {
    if (!c || typeof c !== 'object') continue;
    const next = [...path,c];
    if (c.id === id) return next;
    if (rows(c.replies).length) { const found = pathTo(c.replies,id,next); if (found) return found; }
  }
  return null;
}
function createRepostHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({auth,db},true);
  return async request => {
    const i = request.data, fields = ['postId','sourcePostId','commentId','title','body'];
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== 5 || Object.keys(i).some(k => !fields.includes(k)) ||
        !validId(i.postId) || !validId(i.sourcePostId) || i.postId === i.sourcePostId || !(i.commentId === null || validId(i.commentId)) ||
        typeof i.title !== 'string' || i.title.length > 10000 || typeof i.body !== 'string' || i.body.length > 100000) {
      throw new HttpsError('invalid-argument','Invalid repost.');
    }
    const visible = await readPost({...request,data:{postId:i.sourcePostId}});
    if (i.commentId && !pathTo(visible.data.comments,i.commentId)) throw new HttpsError('not-found','Comment unavailable.');
    const uid = request.auth.uid;
    let token;
    try { token = await auth.verifyIdToken((request.rawRequest?.headers?.authorization || '').slice(7),true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    const hash = createHash('sha256').update(JSON.stringify([i.sourcePostId,i.commentId,i.title,i.body])).digest('hex');
    return db.runTransaction(async tx => {
      const target = db.doc(`community_posts/${i.postId}`), receiptRef = db.doc(`repostPublicationReceipts/${i.postId}`);
      const [existing,receipt,deletion,cutoff,actor] = await tx.getAll(target,receiptRef,db.doc(`postDeletionReceipts/${i.postId}`),
        db.doc(`authRevocations/${uid}`),db.doc(`users/${uid}`));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated','Session revoked.');
      if (unavailable(actor.data())) throw new HttpsError('permission-denied','Reposting unavailable.');
      if (deletion.exists) throw new HttpsError('failed-precondition','Deleted identifier cannot be reused.');
      if (receipt.exists) {
        if (receipt.data().ownerId === uid && receipt.data().contentHash === hash && existing.exists && existing.data().authorId === uid) {
          return {postId:i.postId,published:true};
        }
        throw new HttpsError('already-exists','Repost identifier already used.');
      }
      if (existing.exists) throw new HttpsError('already-exists','Post identifier already used.');
      const people = new Map();
      async function person(id, requireContent, requireRepost) {
        if (!validId(id)) throw new HttpsError('not-found','Author unavailable.');
        if (!people.has(id)) {
          const blocks = ['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [`users/${uid}/${c}/${id}`,`users/${id}/${c}/${uid}`]);
          people.set(id,await tx.getAll(db.doc(`users/${id}`),db.doc(`users/${id}/followers/${uid}`),
            db.doc(`users/${uid}/followers/${id}`),...blocks.map(p => db.doc(p))));
        }
        const [profile,follower,reverse,...blocks] = people.get(id), data = profile.data();
        if (unavailable(data) || (id !== uid && blocks.some(b => b.exists))) throw new HttpsError('permission-denied','Author unavailable.');
        const p = data.privacy || {}, privateAccount = typeof p.privateAccount === 'boolean' ? p.privateAccount : data.profileVisibility === 'private';
        const audience = p.whoCanRepost ?? 'everyone';
        if (id !== uid && ((requireContent && privateAccount && !follower.exists) || (requireRepost &&
            !(audience === 'everyone' || (audience === 'followers' && follower.exists) || (audience === 'mutual' && follower.exists && reverse.exists))))) {
          throw new HttpsError('permission-denied','Reposting is not allowed.');
        }
      }
      async function comment(data, commentId) {
        let path = pathTo(data.comments,commentId);
        if (!path) throw new HttpsError('not-found','Comment unavailable.');
        const seen = new Set();
        while (path[0].replyToId) {
          const parentId = path[0].replyToId;
          if (seen.has(parentId) || path.some(c => c.id === parentId) || path.length >= 30) throw new HttpsError('not-found','Comment unavailable.');
          seen.add(parentId);
          const prefix = pathTo(data.comments,parentId);
          if (!prefix) throw new HttpsError('not-found','Comment unavailable.');
          path = [...prefix,...path];
        }
        for (const c of path) {
          if (removed(c) || rows(data.moderation?.hiddenCommentIds).includes(c.id)) throw new HttpsError('not-found','Comment unavailable.');
          await person(c.authorId,false,c.id === commentId);
        }
        return path.at(-1);
      }
      const seen = new Set();
      let sourceId = i.sourcePostId, quoteComment = i.commentId, recipient, sourceOwner;
      while (sourceId) {
        if (!validId(sourceId) || sourceId === i.postId || seen.has(sourceId) || seen.size >= 8) throw new HttpsError('not-found','Repost source unavailable.');
        seen.add(sourceId);
        const source = (await tx.get(db.doc(`community_posts/${sourceId}`))).data();
        if (removed(source)) throw new HttpsError('not-found','Repost source unavailable.');
        await person(source.authorId,true,true);
        const c = quoteComment ? await comment(source,quoteComment) : null;
        if (sourceId === i.sourcePostId) { sourceOwner = source.authorId; recipient = c?.authorId || source.authorId; }
        if (source.isRepost === true || source.repostOf != null) {
          sourceId = source.repostOf?.postId;
          if (!validId(sourceId)) throw new HttpsError('not-found','Repost source unavailable.');
          quoteComment = source.repostOf.kind === 'comment' ? source.repostOf.commentId : null;
          if (source.repostOf.kind === 'comment' && !validId(quoteComment)) throw new HttpsError('not-found','Comment unavailable.');
        } else sourceId = null;
      }
      const a = actor.data(), p = a.privacy || {};
      const name = [str(a.firstName),str(a.lastName)].filter(Boolean).join(' ') || str(a.displayName) || str(a.username) || 'طالب UniSpace';
      const quote = {postId:i.sourcePostId,authorId:sourceOwner,...(i.commentId ? {kind:'comment',commentId:i.commentId} : {})};
      tx.create(target,{authorId:uid,authorName:name,authorPhotoUrl:str(a.profileImageUrl) || null,title:i.title,body:i.body,
        status:'published',createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp(),isRepost:true,repostOf:quote,
        imageUrls:[],videoUrls:[],polls:[],pollSlides:[],tags:[],votes:0,upvotedBy:[],downvotedBy:[],comments:[],commentsCount:0,version:1,
        authorPrivate:typeof p.privateAccount === 'boolean' ? p.privateAccount : a.profileVisibility === 'private',
        authorAppearInSearch:p.appearInSearch !== false,authorHideLikeCounts:p.hideLikeCounts === true,
        searchKeywords:searchKeywords({title:i.title,body:i.body,tags:[]},name)});
      tx.create(receiptRef,{ownerId:uid,contentHash:hash,createdAt:FieldValue.serverTimestamp()});
      if (recipient !== uid) tx.set(db.doc(`users/${recipient}/notifications/repost_${i.postId}`),{
        type:'repost',actorId:uid,actorName:name,actorPhotoUrl:str(a.profileImageUrl) || null,
        message:i.commentId ? 'أعاد نشر تعليقك' : 'أعاد نشر منشورك',postId:i.sourcePostId,
        ...(i.commentId ? {commentId:i.commentId} : {}),read:false,createdAt:FieldValue.serverTimestamp()});
      return {postId:i.postId,published:true};
    });
  };
}
module.exports = { createRepostHandler };
