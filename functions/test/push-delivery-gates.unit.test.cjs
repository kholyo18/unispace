const { test } = require('node:test');
const assert = require('node:assert/strict');
const { pushAllowed } = require('../security/push-preferences');
const all = { enabled: true, community: true, announcements: true, exams: true };
const categories = {
  community: ['new_post', 'like', 'like_comment', 'reply', 'comment', 'repost', 'follow', 'follow_request', 'follow_accepted'],
  announcements: ['announcement'], exams: ['exam_reminder'],
};
for (const [category, types] of Object.entries(categories)) {
  for (const type of types) {
    test(`supported ${type} respects its category and the global opt-out`, () => {
      assert.equal(pushAllowed(all, type), true);
      assert.equal(pushAllowed({ ...all, enabled: false }, type), false);
      assert.equal(pushAllowed({ ...all, [category]: false }, type), false);
      const only = { enabled: true, community: false, announcements: false, exams: false, [category]: true };
      assert.equal(pushAllowed(only, type), true);
      // Keep the existing helper's compatibility for known types; the dispatcher
      // still requires a valid canonical session-bound registration independently.
      assert.equal(pushAllowed(null, type), true);
      assert.equal(pushAllowed(undefined, type), true);
    });
  }
}
const unsupported = ['', 'chat', 'message', 'chat_message', 'dm_message', 'unknown',
  'FOLLOW', ' follow', 'follow ', '__proto__', 'constructor', 'toString', null, undefined, 3, {}, [], ['follow']];
unsupported.forEach((type, index) => {
  test(`TYPEGATE: unsupported type ${index} cannot bypass preferences`, () => {
    for (const preferences of [all, { ...all, community: false }, null, undefined]) {
      assert.equal(pushAllowed(preferences, type), false);
    }
  });
});
test('malformed preferences do not enable a recognized category', () => {
  for (const preferences of [{}, true, [], 'enabled', { enabled: 1 }, { enabled: true, community: 'true' }]) {
    assert.equal(pushAllowed(preferences, 'follow'), false);
  }
});
