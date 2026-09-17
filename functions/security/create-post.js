const { HttpsError } = require('firebase-functions/v2/https');
const { createHash } = require('crypto');
const { createNewPostNotifications } = require('./new-post-notifications');
const { validateContent, mediaUrls, searchKeywords } = require('./edit-post');
const { createEligibilityConsentHandlers } = require('../legal/eligibility-consent');
const { POST_ENFORCEMENT_PATH, postCreationEnforced } = require('../legal/post-enforcement');
const id = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const text = v => typeof v === 'string' ? v.trim() : '';
const canonical = v => Array.isArray(v) ? v.map(canonical) : v && typeof v === 'object'
  ? Object.fromEntries(Object.keys(v).sort().map(k => [k,canonical(v[k])])) : v;

function createPostHandler({ auth, db, FieldValue, bucket }, publish = false) {
  const eligibility = createEligibilityConsentHandlers({auth, db, FieldValue, HttpsError});
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated','Sign in first.');
    const i = request.data, fields = publish ? ['postId','content'] : ['postId'];
    if (!i || typeof i !== 'object' || Array.isArray(i) || !id(i.postId) ||
        Object.keys(i).length !== fields.length || Object.keys(i).some(k => !fields.includes(k))) {
      throw new HttpsError('invalid-argument','Invalid post request.');
    }
    let hash;
    if (publish) {
      validateContent(i.content);
      const c = i.content;
      if (!c.title.trim() && !c.body.trim() && !c.imageUrls.length && !c.videoUrls.length && !c.polls.length && !c.pollSlides.length) {
        throw new HttpsError('invalid-argument','Post is empty.');
      }
      hash = createHash('sha256').update(JSON.stringify(canonical(c))).digest('hex');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    const authUser = publish ? await auth.getUser(uid) : null;
    if (authUser?.disabled) throw new HttpsError('permission-denied','Publishing unavailable.');
    const postRef = db.doc(`community_posts/${i.postId}`), receiptRef = db.doc(`postPublicationReceipts/${i.postId}`);
    const check = (post, receipt, deletion, cutoff, actor) => {
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated','Session revoked.');
      if (!actor.exists || ['disabled','deleted'].includes(actor.data().accountStatus) || actor.data().security?.frozen === true) {
        throw new HttpsError('permission-denied','Publishing unavailable.');
      }
      if (deletion.exists) throw new HttpsError('failed-precondition','Deleted post identifier cannot be reused.');
      if ((post.exists && post.data().authorId !== uid) || (receipt.exists && receipt.data().ownerId !== uid)) {
        throw new HttpsError('already-exists','Post identifier unavailable.');
      }
    };
    const refs = [postRef, receiptRef, db.doc(`postDeletionReceipts/${i.postId}`), db.doc(`authRevocations/${uid}`), db.doc(`users/${uid}`)];
    if (publish) {
      const snapshots = await db.getAll(...refs);
      check(...snapshots);
      const [post, receipt] = snapshots;
      if (!post.exists || !receipt.exists) throw new HttpsError('failed-precondition','Reserve the post first.');
      // An acknowledged retry does not depend on media that may have since been removed.
      if (receipt.data().status !== 'published') {
        const storage = bucket();
        for (const value of new Set(mediaUrls(i.content))) {
          let url, objectPath;
          try {
            url = new URL(value);
            const prefix = `/v0/b/${storage.name}/o/`, base = `community_posts/${i.postId}/`;
            if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' || url.port || url.username || url.password ||
                !url.pathname.startsWith(prefix) || url.searchParams.get('alt') !== 'media') throw Error();
            objectPath = decodeURIComponent(url.pathname.slice(prefix.length));
            if (!objectPath.startsWith(base) || !/^(images|videos)\/[^/]+$/.test(objectPath.slice(base.length))) throw Error();
          } catch (_) { throw new HttpsError('invalid-argument','Invalid post media.'); }
          let metadata;
          try { [metadata] = await storage.file(objectPath).getMetadata(); }
          catch (_) { throw new HttpsError('failed-precondition','Uploaded media is unavailable.'); }
          if (Number(metadata.size) <= 0 || !String(metadata.metadata?.firebaseStorageDownloadTokens || '').split(',').includes(url.searchParams.get('token'))) {
            throw new HttpsError('invalid-argument','Invalid media token.');
          }
        }
      }
    }
    return db.runTransaction(async tx => {
      // Recheck rollout and eligibility before ALL writes, notifications and retry acknowledgments.
      // A successful reservation or a client status response is not a publication authorization.
      const enforcement = await tx.get(db.doc(POST_ENFORCEMENT_PATH));
      if (postCreationEnforced(enforcement, HttpsError)) {
        await eligibility.assertInTransaction(tx, request);
      }
      const snapshots = await tx.getAll(...refs);
      check(...snapshots);
      const [post, receipt, , , actor] = snapshots;
      if (!publish) {
        if (post.exists || receipt.exists) {
          if (post.exists && receipt.exists && post.data().status === 'uploading' && receipt.data().status === 'uploading') {
            return {postId:i.postId,reserved:true};
          }
          throw new HttpsError('already-exists','Post identifier already used.');
        }
        tx.create(postRef,{authorId:uid,status:'uploading',createdAt:FieldValue.serverTimestamp()});
        tx.create(receiptRef,{ownerId:uid,status:'uploading',createdAt:FieldValue.serverTimestamp()});
        return {postId:i.postId,reserved:true};
      }
      if (!post.exists || !receipt.exists) throw new HttpsError('failed-precondition','Reservation unavailable.');
      if (receipt.data().status === 'published') {
        if (receipt.data().contentHash !== hash) throw new HttpsError('already-exists','Post already published with different content.');
        return {postId:i.postId,published:true};
      }
      if (receipt.data().status !== 'uploading' || post.data().status !== 'uploading') {
        throw new HttpsError('failed-precondition','Post cannot be published.');
      }
      const a = actor.data(), privacy = a.privacy || {};
      const name = [text(a.firstName),text(a.lastName)].filter(Boolean).join(' ') || text(a.displayName) || text(a.username) || text(authUser.displayName) || 'طالب UniSpace';
      const privateAccount = typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : a.profileVisibility === 'private';
      await createNewPostNotifications({tx,db,FieldValue,uid,postId:i.postId,
        actorName:name,actorPhotoUrl:text(a.profileImageUrl) || text(authUser.photoURL) || null});
      tx.update(postRef,{...i.content,authorName:name,authorPhotoUrl:text(a.profileImageUrl) || text(authUser.photoURL) || null,
        authorPrivate:privateAccount,authorAppearInSearch:privacy.appearInSearch !== false,authorHideLikeCounts:privacy.hideLikeCounts === true,
        status:'published',createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp(),
        votes:0,upvotedBy:[],downvotedBy:[],comments:[],commentsCount:0,version:1,isRepost:false,
        searchKeywords:searchKeywords(i.content,name)});
      tx.update(receiptRef,{status:'published',contentHash:hash,publishedAt:FieldValue.serverTimestamp()});
      return {postId:i.postId,published:true};
    });
  };
}
module.exports = { createPostHandler };
