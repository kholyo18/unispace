const { canReceiveContentPush, contentMessages } = require('./push-content-access');
const { createHash } = require('crypto');
const { logger } = require('firebase-functions');
const { pushAllowed } = require('./push-preferences');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const unavailable = d => !d || ['disabled','deleted'].includes(d.accountStatus) || d.security?.frozen === true;

function createPushNotificationHandler({ db, auth, messaging }) {
  return async event => {
    if (!event.data) return;
    const { userId, notifId } = event.params;
    if (!validId(userId)) return;
    const notificationRef = event.data.ref;
    const tokenSnapshot = await db.collection(`users/${userId}/fcm_tokens`).get();
    const byToken = new Map();
    for (const doc of tokenSnapshot.docs) {
      const token = doc.data().token;
      if (typeof token !== 'string' || !token.trim()) continue;
      if (!byToken.has(token)) byToken.set(token,[]);
      byToken.get(token).push(doc.ref);
    }
    const entries = [...byToken.entries()];
    for (let offset = 0; offset < entries.length; offset += 500) {
      const [notification,recipient] = await db.getAll(notificationRef,db.doc(`users/${userId}`));
      if (!notification.exists || notification.data().read === true || unavailable(recipient.data())) return;
      // A deleted and recreated notification must not receive the old event's push.
      if (!notification.createTime.isEqual(event.data.createTime)) return;
      let account;
      try { account = await auth.getUser(userId); }
      catch (error) { if (error.code === 'auth/user-not-found') return; throw error; }
      if (account.disabled) return;
      const data = notification.data(), actorId = data.actorId;
      if (actorId != null && actorId !== '') {
        if (!validId(actorId)) return;
        const paths = [db.doc(`users/${actorId}`),
          ...['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [db.doc(`users/${userId}/${c}/${actorId}`),db.doc(`users/${actorId}/${c}/${userId}`)])];
        const [actor,...blocks] = await db.getAll(...paths);
        if (unavailable(actor.data()) || (actorId !== userId && blocks.some(s => s.exists))) return;
      }
      const batch = entries.slice(offset,offset + 500);
      // Drop deleted/reassigned token records before dispatch; preserve token-to-ref mapping.
      const live = await db.getAll(...batch.flatMap(([,refs]) => refs));
      const present = new Set(live.filter(s => s.exists && typeof s.data().token === 'string').map(s => s.data().token));
      const denied = new Set(live.filter(s => s.exists && !pushAllowed(s.data().preferences, data.type)).map(s => s.data().token));
      const ownership = await db.getAll(...batch.map(([token]) => db.doc('pushTokenOwners/' + createHash('sha256').update(token).digest('hex'))));
      const cutoff = await db.doc('authRevocations/' + userId).get();
      const sessionRefs = new Map();
      for (const binding of ownership) {
        const data = binding.data();
        if (data?.ownerId === userId && data.sessionId != null && validId(data.sessionId)) {
          sessionRefs.set(data.sessionId,db.doc('users/' + userId + '/sessions/' + data.sessionId));
        }
      }
      const sessionSnapshots = sessionRefs.size ? await db.getAll(...sessionRefs.values()) : [];
      const sessions = new Map(sessionSnapshots.map(s => [s.id,s]));
      const active = batch.filter(([token],index) => {
        const binding = ownership[index];
        const owned = !binding.exists || (binding.data().ownerId === userId &&
          (!cutoff.exists || binding.data().authTime > cutoff.data().revokedBefore));
        const state = binding.data();
        const session = state?.sessionId != null ? sessions.get(state.sessionId) : null;
        // Legacy bindings migrate on the next successful device synchronization.
        const sessionActive = state?.sessionId == null || (session?.exists &&
          session.data().sessionId === state.sessionId && session.data().isRevoked === false &&
          typeof session.data().createdAt?.toMillis === 'function' &&
          typeof state.sessionCreatedAt?.isEqual === 'function' && state.sessionCreatedAt.isEqual(session.data().createdAt));
        return owned && sessionActive && present.has(token) && !denied.has(token);
      });
      if (!active.length) continue;
      if (!await canReceiveContentPush({db,auth,userId,notification:data})) return;
      const title = String(data.actorName || 'UniSpace');
      const body = Object.hasOwn(contentMessages,data.type) ? contentMessages[data.type] :
        (data.postId ? 'لديك تحديث على محتوى تتابعه' : String(data.message || 'لديك إشعار جديد'));
      const response = await messaging.sendEachForMulticast({
        tokens:active.map(([token]) => token),notification:{title,body},
        data:{recipientId:userId,type:String(data.type || ''),actorId:String(actorId || ''),actorName:String(data.actorName || ''),
          message:body,postId:String(data.postId || ''),commentId:String(data.commentId || ''),notificationId:String(notifId)},
        android:{priority:'high',notification:{channelId:'unispace_notifications'}},
      });
      const stale = [];
      let otherFailures = 0;
      response.responses.forEach((result,index) => {
        if (result.success) return;
        if (['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(result.error?.code)) {
          const [token,refs] = active[index];
          for (const ref of refs) stale.push({token,ref});
        } else otherFailures++;
      });
      // Compare inside a transaction so a refreshed token in the same document is never deleted.
      for (let start = 0; start < stale.length; start += 400) {
        const group = stale.slice(start,start + 400);
        await db.runTransaction(async tx => {
          const snapshots = await tx.getAll(...group.map(x => x.ref));
          snapshots.forEach((snap,index) => {
            if (snap.exists && snap.data().token === group[index].token) tx.delete(group[index].ref);
          });
        });
      }
      if (otherFailures) logger.warn('Notification push has non-token failures', {count:otherFailures});
    }
  };
}
module.exports = { createPushNotificationHandler };
