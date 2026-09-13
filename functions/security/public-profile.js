const { HttpsError } = require('firebase-functions/v2/https');

function projectProfile(data, { self, following }) {
  const p = data.privacy && typeof data.privacy === 'object' ? data.privacy : {};
  const privateAccount = typeof p.privateAccount === 'boolean' ? p.privateAccount : data.profileVisibility === 'private';
  const canViewContent = self || !privateAccount || following;
  const showEmail = typeof p.showEmailOnProfile === 'boolean' ? p.showEmailOnProfile : data.showEmailInProfile === true;
  const audience = value => value == null ? 'everyone' :
    (['everyone', 'followers', 'mutual', 'none'].includes(value) ? value : 'none');
  const result = { canViewContent, isFollowing: following, privacy: {
    privateAccount, showEmailOnProfile: canViewContent && (self || showEmail),
    showAcademicInfo: canViewContent && (self || p.showAcademicInfo !== false),
    showSocialLinks: canViewContent && (self || p.showSocialLinks !== false),
    showOnline: canViewContent && (self || p.showOnline !== false),
    showLastSeen: canViewContent && (self || p.showLastSeen === true),
    followersVisibility: audience(p.followersVisibility),
    followingVisibility: audience(p.followingVisibility),
  } };
  const copy = keys => { for (const key of keys) if (typeof data[key] === 'string') result[key] = data[key]; };
  copy(['firstName', 'lastName', 'displayName', 'username', 'profileImageUrl']);
  if (!canViewContent) return result;
  copy(['coverImageUrl', 'mood', 'otherInfo', 'work', 'residence']);
  if (result.privacy.showEmailOnProfile) copy(['email']);
  if (result.privacy.showAcademicInfo) copy(['university', 'faculty', 'major', 'studyLevel']);
  if (result.privacy.showSocialLinks) copy(['github', 'linkedin', 'portfolio']);
  if (result.privacy.showOnline) result.isOnline = data.isOnline === true;
  if (result.privacy.showLastSeen && typeof data.lastSeenAt?.toMillis === 'function') result.lastSeenAt = data.lastSeenAt.toMillis();
  const visible = audience => self || audience === 'everyone' || (audience === 'followers' && following);
  if (visible(result.privacy.followersVisibility) && Number.isFinite(data.followersCount)) result.followersCount = data.followersCount;
  if (visible(result.privacy.followingVisibility) && Number.isFinite(data.followingCount)) result.followingCount = data.followingCount;
  return result;
}

function createPublicProfileHandler({ auth, db }) {
  return async request => {
    const uid = request.auth?.uid;
    const header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        typeof input.userId !== 'string' || !input.userId.length || input.userId.length > 128 || input.userId.includes('/') || ['.', '..'].includes(input.userId)) {
      throw new HttpsError('invalid-argument', 'A userId is required.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); } catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const target = input.userId;
    let account;
    try { account = await auth.getUser(target); } catch (error) {
      if (error.code === 'auth/user-not-found') throw new HttpsError('not-found', 'Profile unavailable.');
      throw new HttpsError('unavailable', 'Try again later.');
    }
    if (account.disabled) throw new HttpsError('not-found', 'Profile unavailable.');
    return db.runTransaction(async tx => {
      const paths = [`authRevocations/${uid}`, `users/${target}`, `users/${target}/followers/${uid}`,
        `users/${uid}/blocked_accounts/${target}`, `users/${target}/blocked_accounts/${uid}`,
        `users/${uid}/blocked_users/${target}`, `users/${target}/blocked_users/${uid}`,
        `users/${uid}/blocked_by/${target}`, `users/${target}/blocked_by/${uid}`];
      const [cutoff, profile, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const data = profile.data();
      if (!data || ['disabled', 'deleted'].includes(data.accountStatus) || data.security?.frozen === true ||
          (uid !== target && blocks.some(b => b.exists))) throw new HttpsError('not-found', 'Profile unavailable.');
      // Only the target's accepted followers count; a viewer-owned following record is not proof.
      return projectProfile(data, { self: uid === target, following: follower.exists });
    });
  };
}

module.exports = { projectProfile, createPublicProfileHandler };
