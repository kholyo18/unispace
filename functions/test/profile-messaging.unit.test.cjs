const { test } = require('node:test');
const assert = require('node:assert/strict');
const { projectProfile } = require('../security/profile-projection');
const viewer = { self: false, following: false };
const profile = (extra = {}) => ({ email: 'private@example.test', phone: 'private',
  security: { internal: true }, coverImageUrl: 'cover', university: 'University', ...extra });
function absent(data, keys) {
  for (const key of keys) assert.equal(Object.hasOwn(data, key), false, key);
}

test('messaging audience defaults to mutual, matching the privacy editor', () => {
  assert.equal(projectProfile(profile(), viewer).privacy.whoCanMessage, 'mutual');
  assert.equal(projectProfile(profile({ privacy: { whoCanMessage: null } }), viewer)
    .privacy.whoCanMessage, 'mutual');
});
for (const audience of ['everyone', 'followers', 'mutual', 'none']) {
  test(`explicit messaging policy is projected: ${audience}`, () => {
    const result = projectProfile(profile({ privacy: { whoCanMessage: audience } }), viewer);
    assert.equal(result.privacy.whoCanMessage, audience);
    absent(result, ['security', 'email', 'phone']);
  });
}
test('malformed messaging policy is projected as none, never an arbitrary object', () => {
  for (const value of ['', 'unexpected', { secret: true }, ['everyone'], true, 1]) {
    assert.equal(projectProfile(profile({ privacy: { whoCanMessage: value } }), viewer)
      .privacy.whoCanMessage, 'none');
  }
});
test('private-account messaging metadata does not expose protected content', () => {
  const result = projectProfile(profile({ privacy: { privateAccount: true, whoCanMessage: 'everyone' } }), viewer);
  assert.equal(result.canViewContent, false);
  assert.equal(result.privacy.whoCanMessage, 'everyone');
  absent(result, ['email', 'coverImageUrl', 'security', 'university']);
});
