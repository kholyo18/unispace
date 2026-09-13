const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const unavailable = d => !d || ['disabled','deleted'].includes(d.accountStatus) || d.security?.frozen === true;

// Called once, inside the initial publication transaction, before its other writes.
async function createNewPostNotifications({ tx, db, FieldValue, uid, postId, actorName, actorPhotoUrl }) {
  const followers = await tx.get(db.collection(`users/${uid}/followers`).limit(40));
  const recipients = followers.docs.map(d => d.id).filter(id => validId(id) && id !== uid);
  const refs = recipients.flatMap(id => [db.doc(`users/${id}`),
    ...['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [db.doc(`users/${uid}/${c}/${id}`),db.doc(`users/${id}/${c}/${uid}`)])]);
  const snapshots = refs.length ? await tx.getAll(...refs) : [];
  const eligible = recipients.filter((id,index) => {
    const row = snapshots.slice(index * 7,index * 7 + 7);
    return !unavailable(row[0].data()) && !row.slice(1).some(s => s.exists);
  });
  // All reads precede writes. Accepted follower membership is protected by the query read.
  for (const id of eligible) {
    tx.set(db.doc(`users/${id}/notifications/post_${postId}`),{
      type:'new_post',actorId:uid,actorName,actorPhotoUrl:actorPhotoUrl || null,
      message:'نشر منشوراً جديداً',postId,read:false,createdAt:FieldValue.serverTimestamp(),
    });
  }
}
module.exports = { createNewPostNotifications };
