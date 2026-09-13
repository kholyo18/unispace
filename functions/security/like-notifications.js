const { createHash } = require('node:crypto');
const str = v => typeof v === 'string' ? v.trim() : '';

// Call only after the vote transaction has completed all other reads.
async function updateLikeNotification({ tx, db, FieldValue, uid, ownerId, postId, commentId,
  actor, wasLiked, liked, upvoters }) {
  if (uid === ownerId || wasLiked === liked) return;
  const isComment = !!commentId;
  const collection = db.collection(`users/${ownerId}/notifications`);
  let ref = collection.doc(isComment ? `like_c_${commentId}` : `like_post_${postId}`);
  let snap = await tx.get(ref);
  // Legacy comment IDs were not namespaced by post. Never overwrite an unrelated notification.
  if (snap.exists && snap.data().postId !== postId) {
    ref = collection.doc('like_v2_' + createHash('sha256').update(JSON.stringify([postId, commentId || null])).digest('hex'));
    snap = await tx.get(ref);
  }
  if (!snap.exists && !liked) return;
  const previous = snap.data() || {};
  const rawIds = Array.isArray(previous.actorIds) ? previous.actorIds : [previous.actorId];
  let ids = [...new Set(rawIds.filter(id => typeof id === 'string' && id !== uid && upvoters.has(id)))];
  if (liked) ids.unshift(uid);
  ids = ids.slice(0,30);
  if (!ids.length) { if (snap.exists) tx.delete(ref); return; }
  const actorName = [str(actor.firstName), str(actor.lastName)].filter(Boolean).join(' ') ||
    str(actor.displayName) || str(actor.username) || 'طالب UniSpace';
  const oldNames = previous.actorNames && typeof previous.actorNames === 'object' ? previous.actorNames : {};
  const names = Object.fromEntries(ids.map(id => [id, id === uid ? actorName :
    (str(oldNames[id]) || (id === previous.actorId ? str(previous.actorName) : '') || 'طالب UniSpace')]));
  const lead = ids[0];
  let message = isComment ? 'أعجب بتعليقك' : 'أعجب بمنشورك';
  if (ids.length === 2) message = `و${names[ids[1]]} أعجبا ب${isComment ? 'تعليقك' : 'منشورك'}`;
  if (ids.length > 2) message = `و${ids.length - 1} آخرين أعجبوا ب${isComment ? 'تعليقك' : 'منشورك'}`;
  const output = { type: isComment ? 'like_comment' : 'like', actorId: lead, actorName: names[lead],
    actorPhotoUrl: lead === uid ? str(actor.profileImageUrl) || null :
      (lead === previous.actorId ? str(previous.actorPhotoUrl) || null : null),
    actorIds: ids, actorNames: names, count: ids.length, message, postId,
    ...(isComment ? { commentId } : {}) };
  if (liked) {
    // A newly committed like resurfaces the aggregate; a repeated request never reaches here.
    tx.set(ref, { ...output, read: false, createdAt: FieldValue.serverTimestamp() });
  } else {
    // Retraction must not reset read state or reorder an old notification as new.
    tx.update(ref, output);
  }
}
module.exports = { updateLikeNotification };
