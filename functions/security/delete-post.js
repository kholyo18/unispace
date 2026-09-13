const { HttpsError } = require('firebase-functions/v2/https');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);

function createDeletePostHandler({ auth, db, FieldValue }) {
  return async request => {
    const uid=request.auth?.uid, header=request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated','Sign in first.');
    const i=request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== 1 || !validId(i.postId)) {
      throw new HttpsError('invalid-argument','A postId is required.');
    }
    let token;
    try { token=await auth.verifyIdToken(header.slice(7),true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    return db.runTransaction(async tx=>{
      const ref=db.doc(`community_posts/${i.postId}`), receiptRef=db.doc(`postDeletionReceipts/${i.postId}`);
      const userRef=db.doc(`users/${uid}`);
      const [post,receipt,cutoff,user]=await tx.getAll(ref,receiptRef,db.doc(`authRevocations/${uid}`),userRef);
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated','Session revoked.');
      if (receipt.exists) {
        if (receipt.data().ownerId !== uid) throw new HttpsError('not-found','Post unavailable.');
        if (post.exists) throw new HttpsError('failed-precondition','Deleted post identifier was reused.');
        return {postId:i.postId,deleted:true};
      }
      if (!post.exists || post.data().authorId !== uid) throw new HttpsError('not-found','Post unavailable.');
      // Deleting one's own content does not depend on discoverability or voluntary account freeze.
      tx.create(receiptRef,{ownerId:uid,deletedAt:FieldValue.serverTimestamp()});
      tx.delete(ref);
      if (user.exists && user.data().pinnedPostId === i.postId) tx.update(userRef,{pinnedPostId:FieldValue.delete()});
      return {postId:i.postId,deleted:true};
    });
  };
}
module.exports={createDeletePostHandler};
