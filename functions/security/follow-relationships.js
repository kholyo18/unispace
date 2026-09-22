const { HttpsError } = require('firebase-functions/v2/https');

function createFollowHandler({ auth, db, FieldValue }) {
  return async request => {
    const uid = request.auth?.uid;
    const header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !['follow', 'unfollow', 'cancel', 'accept', 'reject', 'block', 'unblock'].includes(input.action) ||
        typeof input.userId !== 'string' || !input.userId.length || input.userId.length > 128 ||
        input.userId.includes('/') || ['.', '..', uid].includes(input.userId)) {
      throw new HttpsError('invalid-argument', 'Invalid follow operation.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); } catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const {action,userId} = input;
    const approving = action === 'accept' || action === 'reject';
    const owner = approving ? uid : userId;
    const from = approving ? userId : uid;
    const grants = action === 'follow' || action === 'accept';
    if (grants) {
      try {
        const other = await auth.getUser(userId);
        if (other.disabled) throw new Error('Unavailable');
      } catch (_) { throw new HttpsError('not-found', 'Account unavailable.'); }
    }
    const followerRef = db.doc(`users/${owner}/followers/${from}`);
    const followingRef = db.doc(`users/${from}/following/${owner}`);
    const pendingRef = db.doc(`users/${owner}/follow_requests/${from}`);
    const notificationRef = db.collection('users').doc(action === 'accept' ? from : owner).collection('notifications').doc();
    return db.runTransaction(async tx => {
      const paths = [`authRevocations/${uid}`, `users/${owner}`, `users/${from}`,
        followerRef.path, followingRef.path, pendingRef.path,
        `users/${owner}/blocked_accounts/${from}`, `users/${from}/blocked_accounts/${owner}`,
        `users/${owner}/blocked_users/${from}`, `users/${from}/blocked_users/${owner}`,
        `users/${owner}/blocked_by/${from}`, `users/${from}/blocked_by/${owner}`];
      const [cutoff, ownerDoc, fromDoc, follower, following, pending, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && (!Number.isFinite(cutoff.data().revokedBefore)
          || token.auth_time <= cutoff.data().revokedBefore)) {
        throw new HttpsError('unauthenticated', 'Session revoked.');
      }
      const unavailable = doc => !doc.exists || ['deleted','disabled'].includes(doc.data().accountStatus) || doc.data().security?.frozen === true;
      if (grants && (unavailable(ownerDoc) || unavailable(fromDoc) || blocks.some(b=>b.exists))) throw new HttpsError('permission-denied', 'Follow unavailable.');
      const person = (id, doc) => {
        const d=doc.data() || {};
        const names=[d.firstName,d.lastName].filter(v=>typeof v==='string'&&v.trim()).join(' ').trim();
        return {uid:id,name:names || (typeof d.displayName==='string' ? d.displayName : 'طالب UniSpace'),
          photoUrl:typeof d.profileImageUrl==='string' ? d.profileImageUrl : null,createdAt:FieldValue.serverTimestamp()};
      };
      const notify = type => {
        const actor=person(uid, approving ? ownerDoc : fromDoc);
        tx.set(notificationRef,{type,actorId:uid,actorName:actor.name,actorPhotoUrl:actor.photoUrl,
          message:type==='follow_request'?'طلب متابعتك':type==='follow_accepted'?'قبل طلب المتابعة':'بدأ بمتابعتك',
          createdAt:FieldValue.serverTimestamp(),read:false});
      };
      if (action === 'block') {
        const target=person(userId,ownerDoc);
        tx.set(db.doc(`users/${uid}/blocked_accounts/${userId}`),{
          targetId:userId,targetName:target.name,targetPhotoUrl:target.photoUrl,blockedAt:FieldValue.serverTimestamp()});
        tx.set(db.doc(`users/${userId}/blocked_by/${uid}`),{blockerId:uid,blockedAt:FieldValue.serverTimestamp()});
        tx.delete(followerRef);tx.delete(followingRef);tx.delete(pendingRef);
        tx.delete(db.doc(`users/${uid}/followers/${userId}`));
        tx.delete(db.doc(`users/${userId}/following/${uid}`));
        tx.delete(db.doc(`users/${uid}/follow_requests/${userId}`));
        return {state:'none'};
      }
      if (action === 'unblock') {
        tx.delete(db.doc(`users/${uid}/blocked_accounts/${userId}`));
        // Clear only the caller-owned legacy record. Never remove the peer's block.
        tx.delete(db.doc(`users/${uid}/blocked_users/${userId}`));
        tx.delete(db.doc(`users/${userId}/blocked_by/${uid}`));
        return {state:'none'};
      }
      if (action === 'unfollow') {
        tx.delete(followerRef);tx.delete(followingRef);tx.delete(pendingRef);
        return {state:'none'};
      }
      if (action === 'cancel' || action === 'reject') {
        tx.delete(pendingRef);
        return {state:follower.exists?'following':'none'};
      }
      if (follower.exists) {
        if (!following.exists) tx.set(followingRef,person(owner,ownerDoc));
        tx.delete(pendingRef);
        return {state:'following'};
      }
      if (action === 'accept') {
        if (!pending.exists || pending.data().uid !== from || pending.data().status !== 'pending') {
          throw new HttpsError('failed-precondition', 'No pending request.');
        }
      } else {
        const d=ownerDoc.data(), p=d.privacy || {};
        const isPrivate=typeof p.privateAccount==='boolean'?p.privateAccount:d.profileVisibility==='private';
        if (isPrivate) {
          // A mirror on the requester's account never grants private-account access.
          if (following.exists) tx.delete(followingRef);
          if (!pending.exists) {
            tx.set(pendingRef,{...person(from,fromDoc),status:'pending'});
            notify('follow_request');
          }
          return {state:'pending'};
        }
      }
      tx.set(followerRef,person(from,fromDoc));tx.set(followingRef,person(owner,ownerDoc));tx.delete(pendingRef);
      notify(action==='accept'?'follow_accepted':'follow');
      return {state:'following'};
    });
  };
}
module.exports={createFollowHandler};
