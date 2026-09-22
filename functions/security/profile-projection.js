// Pure allowlisted profile projection. No Firebase calls or document writes.
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
    whoCanComment: audience(p.whoCanComment),
    whoCanRepost: audience(p.whoCanRepost),
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

module.exports = { projectProfile };
