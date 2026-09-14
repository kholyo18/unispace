const { HttpsError } = require('firebase-functions/v2/https');
const { Timestamp } = require('firebase-admin/firestore');
const profileStrings = ['firstName','lastName','displayName','userName','username','name','email','phone',
  'birthDate','gender','residence','university','faculty','department','major','studyLevel','section',
  'work','otherInfo','mood','github','linkedin','portfolio','profileImageUrl','coverImageUrl','profileVisibility'];
const privacyBooleans = ['privateAccount','appearInSearch','suggestAccount','findByEmail','findByPhone',
  'hideLikeCounts','messageRequests','readReceipts','typingIndicator','showOnline','showLastSeen',
  'showEmailOnProfile','showAcademicInfo','showSocialLinks'];
const privacyAudiences = ['followersVisibility','followingVisibility','whoCanComment','whoCanRepost','whoCanMention','whoCanMessage'];
function projectExport(user) {
  const profile = {}, privacy = {}, p = user.privacy || {};
  for (const key of profileStrings) if (typeof user[key] === 'string') profile[key] = user[key];
  for (const key of ['createdAt','updatedAt','lastSeenAt']) {
    if (user[key] instanceof Timestamp) profile[key] = user[key].toDate().toISOString();
  }
  for (const key of ['followersCount','followingCount','postsCount']) {
    if (Number.isSafeInteger(user[key]) && user[key] >= 0) profile[key] = user[key];
  }
  for (const key of ['showEmailInProfile','isOnline']) if (typeof user[key] === 'boolean') profile[key] = user[key];
  for (const key of privacyBooleans) if (typeof p[key] === 'boolean') privacy[key] = p[key];
  for (const key of privacyAudiences) if (typeof p[key] === 'string') privacy[key] = p[key];
  if (Array.isArray(p.hiddenWords)) privacy.hiddenWords = p.hiddenWords.filter(v => typeof v === 'string');
  profile.privacy = privacy;
  return {profile, privacy};
}
function createOwnProfileExportHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length) throw new HttpsError('invalid-argument', 'No parameters allowed.');
    return db.runTransaction(async tx => {
      const [cutoff, account] = await tx.getAll(db.doc('authRevocations/' + uid),db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      const result = projectExport(user);
      if (Buffer.byteLength(JSON.stringify(result)) > 2 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Profile export too large.');
      return result;
    });
  };
}
module.exports = { createOwnProfileExportHandler, projectExport };
