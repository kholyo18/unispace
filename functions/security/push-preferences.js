const { HttpsError } = require('firebase-functions/v2/https');
const { createHash } = require('crypto');
const { validAuthTime, cutoffAllows } = require('./push-session-policy');
const validSessionId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.','..'].includes(v);
const preferenceKeys = ['enabled','community','announcements','exams'];
function createSyncPushDeviceHandler({auth,db,FieldValue}, detach = false) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated','Sign in first.');
    const i = request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== (detach ? 1 : 4) ||
        typeof i.token !== 'string' || !i.token.trim() || i.token.length > 4096 ||
        (!detach && (!validSessionId(i.sessionId) || !['android','iOS','macOS','windows','linux','fuchsia'].includes(i.platform) ||
        !i.preferences || Array.isArray(i.preferences) || Object.keys(i.preferences).length !== 4 ||
        !preferenceKeys.every(k => typeof i.preferences[k] === 'boolean')))) {
      throw new HttpsError('invalid-argument','Invalid push registration.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7),true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !validAuthTime(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    const deviceId = createHash('sha256').update(i.token).digest('hex');
    return db.runTransaction(async tx => {
      const [cutoff,profile] = await tx.getAll(db.doc(`authRevocations/${uid}`),db.doc(`users/${uid}`));
      if (!cutoffAllows(token.auth_time, cutoff.exists ? cutoff.data() : null)) throw new HttpsError('unauthenticated','Session revoked.');
      if (!profile.exists || ['disabled','deleted'].includes(profile.data().accountStatus) ||
          (!detach && profile.data().security?.frozen === true)) throw new HttpsError('permission-denied','Account unavailable.');
      let session;
      if (!detach) {
        session = await tx.get(db.doc('users/' + uid + '/sessions/' + i.sessionId));
        if (!session.exists || session.data().sessionId !== i.sessionId || session.data().isRevoked !== false ||
            typeof session.data().createdAt?.toMillis !== 'function') {
          throw new HttpsError('failed-precondition','Active device session required.');
        }
      }
      const bindingRef = db.doc('pushTokenOwners/' + deviceId);
      const revokedRef = bindingRef.collection('revocations').doc(uid);
      const [binding,revoked] = await tx.getAll(bindingRef,revokedRef);
      if (!detach && ((revoked.exists && (!validAuthTime(revoked.data().authTime) || token.auth_time <= revoked.data().authTime)) ||
          (binding.data()?.ownerId === uid && (!validAuthTime(binding.data().authTime) || token.auth_time < binding.data().authTime)))) {
        throw new HttpsError('unauthenticated','Sign in again to register this device.');
      }
      const collection = db.collection(`users/${uid}/fcm_tokens`);
      const duplicates = await tx.get(collection.where('token','==',i.token).limit(401));
      if (duplicates.size > 400) throw new HttpsError('resource-exhausted','Registration cleanup required.');
      if (detach) {
        tx.set(revokedRef,{authTime:Math.max(token.auth_time,validAuthTime(revoked.data()?.authTime) ? revoked.data().authTime : 0)});
        if (!binding.exists || (binding.data()?.ownerId === uid && binding.data().authTime <= token.auth_time)) {
          tx.set(bindingRef,{ownerId:null,authTime:token.auth_time,updatedAt:FieldValue.serverTimestamp()});
        }
        for (const doc of duplicates.docs) {
          if ((doc.data().authTime || 0) <= token.auth_time) tx.delete(doc.ref);
        }
        return {detached:true};
      }
      const previous = binding.data();
      if (previous?.ownerId && (!validSessionId(previous.ownerId) || !validAuthTime(previous.authTime))) {
        throw new HttpsError('failed-precondition','Device binding requires repair.');
      }
      if (previous?.ownerId && previous.ownerId !== uid) {
        const oldRef = bindingRef.collection('revocations').doc(previous.ownerId);
        const old = await tx.get(oldRef);
        if (old.exists && !validAuthTime(old.data().authTime)) {
          throw new HttpsError('failed-precondition','Device revocation requires repair.');
        }
        tx.set(oldRef,{authTime:Math.max(previous.authTime,old.data()?.authTime || 0)});
      }
      tx.set(bindingRef,{ownerId:uid,authTime:token.auth_time,sessionId:i.sessionId,sessionCreatedAt:session.data().createdAt,updatedAt:FieldValue.serverTimestamp()});
      tx.set(collection.doc(deviceId),{token:i.token,authTime:token.auth_time,sessionId:i.sessionId,platform:i.platform,preferences:i.preferences,updatedAt:FieldValue.serverTimestamp()});
      for (const doc of duplicates.docs) if (doc.id !== deviceId) tx.delete(doc.ref);
      return {synced:true};
    });
  };
}
function pushAllowed(preferences, type) {
  // Legacy registrations retain delivery until this client first synchronizes them.
  if (preferences == null) return true;
  if (preferences.enabled !== true) return false;
  if (['new_post','like','like_comment','reply','comment','repost','follow','follow_request','follow_accepted'].includes(type)) return preferences.community === true;
  if (type === 'announcement') return preferences.announcements === true;
  if (type === 'exam_reminder') return preferences.exams === true;
  return true;
}
module.exports = {createSyncPushDeviceHandler,pushAllowed};
