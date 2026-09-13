const { removed } = require('./content-search-page');
const id = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const rows = v => Array.isArray(v) ? v : [];
const unavailable = d => !d || ['disabled','deleted'].includes(d.accountStatus) || d.security?.frozen === true;
const contentMessages = {new_post:'نشر منشوراً جديداً',like:'أعجب بمنشورك',like_comment:'أعجب بتعليقك',
  comment:'علّق على منشورك',reply:'رد على تعليقك',repost:'أعاد نشر محتوى'};
function commentPath(raw, target, path = []) {
  if (path.length >= 30) return null;
  for (const c of rows(raw)) {
    if (!c || typeof c !== 'object') continue;
    const next = [...path,c];
    if (c.id === target) return next;
    const found = commentPath(c.replies,target,next);
    if (found) return found;
  }
  return null;
}

async function canReceiveContentPush({db,auth,userId,notification}) {
  const requiresPost = Object.hasOwn(contentMessages,notification.type);
  const postId = notification.postId;
  if (!requiresPost && (postId == null || postId === '')) return true;
  if (!id(postId)) return false;
  const commentId = notification.commentId;
  const requiresComment = ['like_comment','comment','reply'].includes(notification.type);
  if ((requiresComment || (commentId != null && commentId !== '')) && !id(commentId)) return false;
  const accounts = new Map();
  async function authAvailable(uid) {
    if (!accounts.has(uid)) accounts.set(uid,auth.getUser(uid).then(a => !a.disabled).catch(error => {
      if (error.code === 'auth/user-not-found') return false;
      throw error;
    }));
    return accounts.get(uid);
  }
  return db.runTransaction(async tx => {
    const people = new Map();
    async function visibleAuthor(uid, contentOwner = false) {
      if (!id(uid)) return false;
      if (!people.has(uid)) {
        const blockRefs = ['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [
          db.doc(`users/${userId}/${c}/${uid}`),db.doc(`users/${uid}/${c}/${userId}`)]);
        people.set(uid,await tx.getAll(db.doc(`users/${uid}`),db.doc(`users/${uid}/followers/${userId}`),...blockRefs));
      }
      const [profile,follower,...blocks] = people.get(uid), data = profile.data();
      if (unavailable(data) || !await authAvailable(uid) || (uid !== userId && blocks.some(s => s.exists))) return false;
      const p = data.privacy || {}, privateAccount = typeof p.privateAccount === 'boolean' ? p.privateAccount : data.profileVisibility === 'private';
      return !contentOwner || uid === userId || !privateAccount || follower.exists;
    }
    if (!await visibleAuthor(userId)) return false;
    if (notification.actorId && !await visibleAuthor(notification.actorId)) return false;
    async function visibleComment(data, target) {
      let path = commentPath(data.comments,target);
      if (!path) return false;
      const seen = new Set();
      while (path[0].replyToId) {
        const parent = path[0].replyToId;
        if (!id(parent) || seen.has(parent) || path.some(c => c.id === parent) || path.length >= 30) return false;
        seen.add(parent);
        const prefix = commentPath(data.comments,parent);
        if (!prefix) return false;
        path = [...prefix,...path];
        if (path.length > 30) return false;
      }
      for (const c of path) {
        if (removed(c) || rows(data.moderation?.hiddenCommentIds).includes(c.id) || !await visibleAuthor(c.authorId)) return false;
      }
      return true;
    }
    const seen = new Set();
    let current = postId, targetComment = commentId || null;
    while (current) {
      if (!id(current) || seen.has(current) || seen.size >= 8) return false;
      seen.add(current);
      const snapshot = await tx.get(db.doc(`community_posts/${current}`)), data = snapshot.data();
      if (removed(data) || !await visibleAuthor(data.authorId,true)) return false;
      if (targetComment && !await visibleComment(data,targetComment)) return false;
      if (data.isRepost === true || data.repostOf != null) {
        current = data.repostOf?.postId;
        if (!id(current)) return false;
        targetComment = data.repostOf.kind === 'comment' ? data.repostOf.commentId : null;
        if (data.repostOf.kind === 'comment' && !id(targetComment)) return false;
      } else current = null;
    }
    return true;
  });
}
module.exports = {canReceiveContentPush,contentMessages};
