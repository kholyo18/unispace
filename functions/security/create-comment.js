const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;
const blockPaths = (a,b) => ['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [`users/${a}/${c}/${b}`,`users/${b}/${c}/${a}`]);
const str = v => typeof v === 'string' ? v.trim() : '';
const nodesIn = rows => Array.isArray(rows) ? rows.filter(n => n && typeof n === 'object' && !Array.isArray(n)) : [];
function findPath(rows, id, path = []) {
  if (path.length > 30) throw new HttpsError('resource-exhausted', 'Reply nesting limit exceeded.');
  for (const n of nodesIn(rows)) {
    const next = [...path,n];
    if (n.id === id) return next;
    const found = findPath(n.replies,id,next); if (found) return found;
  }
  return null;
}

function createCommentHandler({ auth, db, FieldValue, Timestamp, bucket }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const i = request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== 5 ||
        !validId(i.postId) || !validId(i.commentId) || !(i.replyToId === null || validId(i.replyToId)) ||
        typeof i.text !== 'string' || i.text.length > 10000 || (!i.text.trim() && i.media === null) ||
        !(i.media === null || (typeof i.media === 'object' && !Array.isArray(i.media) && Object.keys(i.media).length === 2 &&
          ['image','gif','video'].includes(i.media.type) && typeof i.media.url === 'string' && i.media.url.length <= 4096))) {
      throw new HttpsError('invalid-argument', 'Invalid comment.');
    }
    const uid = request.auth?.uid;
    const visible = await readPost({...request,data:{postId:i.postId}});
    if (i.replyToId && !findPath(visible.data.comments,i.replyToId)) throw new HttpsError('not-found','Reply target unavailable.');
    let token;
    try { token = await auth.verifyIdToken((request.rawRequest?.headers?.authorization || '').slice(7),true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    if (i.media) {
      const storage = bucket();
      let url, objectPath;
      try {
        url = new URL(i.media.url);
        const prefix = `/v0/b/${storage.name}/o/`;
        if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' || url.port ||
            url.username || url.password || !url.pathname.startsWith(prefix) || url.searchParams.get('alt') !== 'media') throw Error();
        objectPath = decodeURIComponent(url.pathname.slice(prefix.length));
        const expected = `community_posts/${i.postId}/comments/${uid}/${i.commentId}/media.`;
        if (!objectPath.startsWith(expected) || !/^[a-zA-Z0-9]{1,8}$/.test(objectPath.slice(expected.length))) throw Error();
      } catch (_) { throw new HttpsError('invalid-argument','Invalid comment media.'); }
      const [metadata] = await storage.file(objectPath).getMetadata();
      const tokens = String(metadata.metadata?.firebaseStorageDownloadTokens || '').split(',');
      if (!tokens.includes(url.searchParams.get('token')) || Number(metadata.size) <= 0) {
        throw new HttpsError('invalid-argument','Media is unavailable.');
      }
    }
    return db.runTransaction(async tx => {
      const postRef=db.doc(`community_posts/${i.postId}`), snapshot=await tx.get(postRef), data=snapshot.data();
      if (removed(data) || data.authorId !== visible.data.authorId) throw new HttpsError('not-found','Post unavailable.');
      const owner=data.authorId;
      const paths=[`authRevocations/${uid}`,`users/${uid}`,`users/${owner}`,`users/${owner}/followers/${uid}`,
        `users/${uid}/followers/${owner}`,`users/${uid}/authored_comments/${i.commentId}`,...blockPaths(uid,owner)];
      const [cutoff,actor,profile,follower,reverse,index,...blocks]=await tx.getAll(...paths.map(p=>db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated','Session revoked.');
      if (unavailable(actor.data()) || unavailable(profile.data()) || (uid !== owner && blocks.some(b=>b.exists))) throw new HttpsError('permission-denied','Commenting unavailable.');
      const privacy=profile.data().privacy || {};
      const privateAccount=typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : profile.data().profileVisibility === 'private';
      const audience=privacy.whoCanComment ?? 'everyone';
      const allowed=uid === owner || ((!privateAccount || follower.exists) && (audience === 'everyone' ||
        (audience === 'followers' && follower.exists) || (audience === 'mutual' && follower.exists && reverse.exists)));
      if (!allowed) throw new HttpsError('permission-denied','Commenting is not allowed.');
      const comments=nodesIn(data.comments), previous=findPath(comments,i.commentId)?.at(-1);
      const toWire=c=>({id:c.id,author:str(c.author),authorId:uid,authorPhotoUrl:c.authorPhotoUrl ?? null,
        text:c.text,createdAt:typeof c.createdAt?.toDate === 'function' ? c.createdAt.toDate().toISOString() : c.createdAt,
        replyToId:c.replyToId ?? null,replyToAuthor:c.replyToAuthor ?? null,mediaUrl:c.mediaUrl ?? null,
        mediaType:c.mediaType ?? null,replies:[],votes:Number(c.votes)||0,
        upvotedBy:Array.isArray(c.upvotedBy)&&c.upvotedBy.includes(uid)?[uid]:[],
        downvotedBy:Array.isArray(c.downvotedBy)&&c.downvotedBy.includes(uid)?[uid]:[]});
      if (previous || index.exists) {
        if (previous?.authorId === uid && previous.text === i.text.trim() && (previous.replyToId ?? null) === i.replyToId &&
            (previous.mediaUrl ?? null) === (i.media?.url ?? null) && (previous.mediaType ?? null) === (i.media?.type ?? null)) {
          return {comment:toWire(previous),created:false};
        }
        throw new HttpsError('already-exists','Comment identifier already used.');
      }
      let ancestors=i.replyToId ? findPath(comments,i.replyToId) : [];
      // Legacy flat replies still inherit availability of every referenced parent.
      const seenParents=new Set();
      while (ancestors?.[0]?.replyToId) {
        const parentId=ancestors[0].replyToId;
        if (seenParents.has(parentId) || ancestors.some(n=>n.id===parentId) || ancestors.length>=30) {
          throw new HttpsError('not-found','Reply target unavailable.');
        }
        seenParents.add(parentId);
        const prefix=findPath(comments,parentId);
        if (!prefix) throw new HttpsError('not-found','Reply target unavailable.');
        ancestors=[...prefix,...ancestors];
      }
      if (!ancestors || ancestors.length >= 30) throw new HttpsError('not-found','Reply target unavailable.');
      const hidden=new Set(Array.isArray(data.moderation?.hiddenCommentIds)?data.moderation.hiddenCommentIds:[]);
      for (const ancestor of ancestors) {
        if (!validId(ancestor.authorId) || removed(ancestor) || hidden.has(ancestor.id)) throw new HttpsError('not-found','Reply target unavailable.');
        const [person,...blocked]=await tx.getAll(db.doc(`users/${ancestor.authorId}`),...blockPaths(uid,ancestor.authorId).map(p=>db.doc(p)));
        if (unavailable(person.data()) || (uid !== ancestor.authorId && blocked.some(b=>b.exists))) throw new HttpsError('permission-denied','Reply target unavailable.');
      }
      const parent=ancestors.at(-1), a=actor.data();
      const name=[str(a.firstName),str(a.lastName)].filter(Boolean).join(' ') || str(a.displayName) || str(a.username) || 'طالب UniSpace';
      const comment={id:i.commentId,author:name,authorId:uid,authorPhotoUrl:str(a.profileImageUrl)||null,text:i.text.trim(),
        createdAt:Timestamp.now(),replyToId:i.replyToId,replyToAuthor:parent?str(parent.author):null,
        votes:0,upvotedBy:[],downvotedBy:[],mediaUrl:i.media?.url ?? null,mediaType:i.media?.type ?? null,replies:[]};
      if (parent) { parent.replies=nodesIn(parent.replies); parent.replies.unshift(comment); } else comments.unshift(comment);
      tx.update(postRef,{comments,commentsCount:comments.filter(c=>!c.replyToId).length,updatedAt:FieldValue.serverTimestamp()});
      tx.create(index.ref,{commentId:i.commentId,postId:i.postId,text:comment.text,createdAt:comment.createdAt,
        mediaUrl:comment.mediaUrl,mediaType:comment.mediaType,replyToId:i.replyToId});
      const recipients=new Map();
      if (parent && parent.authorId !== uid) recipients.set(parent.authorId,'reply');
      if (owner !== uid && !recipients.has(owner)) recipients.set(owner,'comment');
      for (const [recipient,type] of recipients) tx.create(db.collection(`users/${recipient}/notifications`).doc(),{
        type,actorId:uid,actorName:name,actorPhotoUrl:comment.authorPhotoUrl,postId:i.postId,commentId:i.commentId,
        message:`${type === 'reply' ? 'رد على تعليقك' : 'علّق على منشورك'}: ${(comment.text || 'أرفق وسائط').slice(0,60)}`,
        createdAt:comment.createdAt,read:false,
      });
      return {comment:toWire(comment),created:true};
    });
  };
}
module.exports={createCommentHandler};
