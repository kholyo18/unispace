const { HttpsError } = require('firebase-functions/v2/https');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
function createCompleteSignupHandler({auth, db, bucketName}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const i = request.data, required = ['firstName','lastName','username','birthDate','gender','college','department','major','level'];
    const allowed = [...required,'profileImageUrl','coverImageUrl'];
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).some(k => !allowed.includes(k)) ||
        required.some(k => !Object.hasOwn(i,k))) throw new HttpsError('invalid-argument', 'Invalid profile.');
    for (const k of ['firstName','lastName','college','department','major','level']) {
      if (typeof i[k] !== 'string' || i[k].length > 200 || i[k] !== i[k].trim()) throw new HttpsError('invalid-argument', 'Invalid profile text.');
    }
    if (!i.firstName || typeof i.username !== 'string' || !/^[a-zA-Z0-9_]{3,20}$/.test(i.username) ||
        (i.gender !== null && (typeof i.gender !== 'string' || i.gender.length > 40)) ||
        (i.birthDate !== null && (!Number.isSafeInteger(i.birthDate) || i.birthDate < -2208988800000 || i.birthDate > Date.now()))) {
      throw new HttpsError('invalid-argument', 'Invalid identity.');
    }
    for (const [key, file] of [['profileImageUrl','profile.jpg'],['coverImageUrl','cover.jpg']]) {
      if (!Object.hasOwn(i,key)) continue;
      try {
        if (typeof i[key] !== 'string' || i[key].length > 4096) throw Error();
        const url = new URL(i[key]);
        if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' || url.port || url.username || url.password ||
            decodeURIComponent(url.pathname) !== '/v0/b/' + bucketName() + '/o/users/' + uid + '/' + file) throw Error();
      } catch (_) { throw new HttpsError('invalid-argument', 'Invalid profile media.'); }
    }
    const account = await auth.getUser(uid);
    if (account.disabled) throw new HttpsError('permission-denied', 'Account unavailable.');
    return db.runTransaction(async tx => {
      const profileRef = db.doc('users/' + uid), nameRef = db.doc('usernameReservations/' + i.username);
      const [cutoff, profile, reservation] = await tx.getAll(db.doc('authRevocations/' + uid), profileRef, nameRef);
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const old = profile.data();
      if (old && (['disabled','deleted'].includes(old.accountStatus) || old.security?.frozen === true)) throw new HttpsError('permission-denied', 'Account unavailable.');
      if (old?.onboardingCompleted === true && old.username !== i.username) throw new HttpsError('failed-precondition', 'Profile already completed.');
      if (reservation.exists && reservation.data().uid !== uid) throw new HttpsError('already-exists', 'Username taken.');
      const existing = await tx.get(db.collection('users').where('username','==',i.username).limit(2));
      if (existing.docs.some(doc => doc.id !== uid)) throw new HttpsError('already-exists', 'Username taken.');
      // Both concurrent signups contend on this document, not just a preflight query.
      if (!reservation.exists) tx.create(nameRef, {uid, createdAt:FieldValue.serverTimestamp()});
      if (old?.onboardingCompleted !== true) {
        const name = [i.firstName,i.lastName].filter(Boolean).join(' ');
        const data = {firstName:i.firstName,lastName:i.lastName,name,displayName:name,username:i.username,
          email:account.email || null,birthDate:i.birthDate === null ? null : Timestamp.fromMillis(i.birthDate),
          gender:i.gender,college:i.college,department:i.department,major:i.major,level:i.level,
          onboardingCompleted:true,updatedAt:FieldValue.serverTimestamp()};
        for (const key of ['profileImageUrl','coverImageUrl']) if (Object.hasOwn(i,key)) data[key] = i[key];
        tx.set(profileRef, data, {merge:true});
      }
      return {completed:true,uid,username:i.username};
    });
  };
}
module.exports = {createCompleteSignupHandler};
