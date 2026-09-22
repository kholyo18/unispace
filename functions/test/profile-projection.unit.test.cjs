// Dependency-free tests of the real production projection, not mocked Rules.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { projectProfile } = require('../security/profile-projection');

function profile(overrides = {}) {
  return {
    firstName: 'Example', lastName: 'Student', displayName: 'Example Student',
    username: 'example', profileImageUrl: 'avatar', coverImageUrl: 'cover',
    email: 'private@example.test', phone: 'private-phone', phoneNumber: 'private-phone',
    birthDate: 'private-date', gender: 'private', security: { backupCodes: ['secret'] },
    academic: { internal: 'secret' }, twoFactorEnabled: true, unknownSecret: 'secret',
    fcmToken: 'secret-token', university: 'University', faculty: 'Faculty',
    major: 'Major', studyLevel: 'Level', github: 'github', linkedin: 'linkedin',
    portfolio: 'portfolio', isOnline: true, lastSeenAt: { toMillis: () => 123456 },
    followersCount: 8, followingCount: 3, privacy: {}, ...overrides,
  };
}
const viewer = { self: false, following: false };
function absent(result, keys) {
  for (const key of keys) assert.equal(Object.hasOwn(result, key), false, key);
}

test('public identity is available without exposing hidden email', () => {
  const result = projectProfile(profile(), viewer);
  assert.equal(result.displayName, 'Example Student');
  assert.equal(result.canViewContent, true);
  absent(result, ['email']);
});

test('email requires explicit opt-in for a visitor', () => {
  assert.equal(projectProfile(profile({ privacy: { showEmailOnProfile: true } }), viewer).email,
    'private@example.test');
});

test('explicit email opt-out overrides the legacy opt-in', () => {
  const result = projectProfile(profile({ showEmailInProfile: true,
    privacy: { showEmailOnProfile: false } }), viewer);
  absent(result, ['email']);
});

test('legacy email opt-in is preserved when no modern flag exists', () => {
  assert.equal(projectProfile(profile({ showEmailInProfile: true }), viewer).email,
    'private@example.test');
});

test('private visitor receives basic identity but no protected profile details', () => {
  const result = projectProfile(profile({ privacy: { privateAccount: true,
    showEmailOnProfile: true, showLastSeen: true } }), viewer);
  assert.equal(result.canViewContent, false);
  assert.equal(result.profileImageUrl, 'avatar');
  absent(result, ['email', 'coverImageUrl', 'university', 'github', 'isOnline',
    'lastSeenAt', 'followersCount', 'followingCount']);
});

test('accepted private-account follower receives only allowed details', () => {
  const result = projectProfile(profile({ privacy: { privateAccount: true,
    showEmailOnProfile: false, showAcademicInfo: false } }), { self: false, following: true });
  assert.equal(result.canViewContent, true);
  assert.equal(result.isFollowing, true);
  assert.equal(result.coverImageUrl, 'cover');
  absent(result, ['email', 'university']);
});

test('owner can see personal profile details without receiving internal security fields', () => {
  const result = projectProfile(profile({ privacy: { privateAccount: true,
    showEmailOnProfile: false, showAcademicInfo: false } }), { self: true, following: false });
  assert.equal(result.canViewContent, true);
  assert.equal(result.email, 'private@example.test');
  assert.equal(result.university, 'University');
  absent(result, ['security', 'phone', 'academic', 'fcmToken']);
});

for (const self of [false, true]) {
  for (const following of [false, true]) {
    test(`internal and unknown fields never escape (self=${self}, following=${following})`, () => {
      const result = projectProfile(profile(), { self, following });
      absent(result, ['phone', 'phoneNumber', 'birthDate', 'gender', 'security',
        'academic', 'twoFactorEnabled', 'unknownSecret', 'fcmToken']);
    });
  }
}

test('academic opt-out removes every public academic field', () => {
  absent(projectProfile(profile({ privacy: { showAcademicInfo: false } }), viewer),
    ['university', 'faculty', 'major', 'studyLevel']);
});

test('social-link opt-out removes all three public social fields', () => {
  absent(projectProfile(profile({ privacy: { showSocialLinks: false } }), viewer),
    ['github', 'linkedin', 'portfolio']);
});

test('online-status opt-out removes the field instead of leaking the stored value', () => {
  absent(projectProfile(profile({ privacy: { showOnline: false } }), viewer), ['isOnline']);
});

test('last-seen is hidden by default', () => {
  absent(projectProfile(profile(), viewer), ['lastSeenAt']);
});

test('last-seen opt-in returns milliseconds', () => {
  assert.equal(projectProfile(profile({ privacy: { showLastSeen: true } }), viewer).lastSeenAt, 123456);
});

test('non-Timestamp last-seen data is not copied', () => {
  absent(projectProfile(profile({ privacy: { showLastSeen: true }, lastSeenAt: 'secret' }), viewer),
    ['lastSeenAt']);
});

test('malformed audience values fail closed without copying arbitrary objects', () => {
  const result = projectProfile(profile({ privacy: { followersVisibility: { secret: 'x' },
    followingVisibility: 'unexpected', whoCanComment: 5, whoCanRepost: ['everyone'] } }), viewer);
  for (const key of ['followersVisibility', 'followingVisibility', 'whoCanComment', 'whoCanRepost']) {
    assert.equal(result.privacy[key], 'none');
  }
  absent(result, ['followersCount', 'followingCount']);
});

test('follower-only counts are withheld from a non-follower', () => {
  absent(projectProfile(profile({ privacy: { followersVisibility: 'followers',
    followingVisibility: 'followers' } }), viewer), ['followersCount', 'followingCount']);
});

test('follower-only counts are available to an accepted follower', () => {
  const result = projectProfile(profile({ privacy: { followersVisibility: 'followers',
    followingVisibility: 'followers' } }), { self: false, following: true });
  assert.equal(result.followersCount, 8);
  assert.equal(result.followingCount, 3);
});

test('none and unproven mutual audiences do not reveal counts to a visitor', () => {
  absent(projectProfile(profile({ privacy: { followersVisibility: 'none',
    followingVisibility: 'mutual' } }), { self: false, following: true }),
    ['followersCount', 'followingCount']);
});

test('non-finite or non-numeric counts are omitted', () => {
  absent(projectProfile(profile({ followersCount: Infinity, followingCount: '3' }), viewer),
    ['followersCount', 'followingCount']);
});

test('non-string identity values are not copied', () => {
  absent(projectProfile(profile({ displayName: { secret: 'x' }, profileImageUrl: ['x'] }), viewer),
    ['displayName', 'profileImageUrl']);
});

test('legacy private-account setting is honored', () => {
  assert.equal(projectProfile(profile({ profileVisibility: 'private' }), viewer).canViewContent, false);
});

test('explicit modern public setting overrides legacy private setting', () => {
  assert.equal(projectProfile(profile({ profileVisibility: 'private',
    privacy: { privateAccount: false } }), viewer).canViewContent, true);
});

test('projection does not mutate its input', () => {
  const data = profile({ privacy: { showEmailOnProfile: false } });
  const before = JSON.stringify(data);
  projectProfile(data, viewer);
  assert.equal(JSON.stringify(data), before);
});

test('privacy changes apply immediately, with no previous-result caching', () => {
  const data = profile({ privacy: { showEmailOnProfile: true } });
  assert.equal(projectProfile(data, viewer).email, 'private@example.test');
  data.privacy.showEmailOnProfile = false;
  absent(projectProfile(data, viewer), ['email']);
});
