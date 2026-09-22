// Source-contract guards only. These do not replace Flutter analysis or device tests.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
function section(start, end) {
  const first = main.indexOf(start);
  assert.ok(first >= 0, `Missing ${start}`);
  const last = main.indexOf(end, first + start.length);
  assert.ok(last > first, `Missing end of ${start}`);
  return main.slice(first, last);
}
test('legacy unblock sheet delegates to the callable path and guards account changes', () => {
  const body = section('Future<void> _unblock(_BlockedAccount account)', '\n  @override');
  assert.match(body, /await unblockAccount\(account\.id\)/);
  assert.doesNotMatch(body, /FirebaseFirestore|\.delete\(\)/);
  assert.match(body, /currentUser\?\.uid != uid/);
  assert.doesNotMatch(body, /blockedListRevision\.value\+\+/);
});
test('follow and block mutation helpers retain the server-owned callable', () => {
  const follow = section('Future<void> _manageFollow(', 'DocumentReference<Map<String, dynamic>> _blockedAccountRef(');
  assert.match(follow, /httpsCallable\('manageFollow'\)/);
  for (const action of ['cancel', 'accept', 'reject']) assert.ok(follow.includes(`_manageFollow('${action}'`));
  const blocks = section('Future<void> blockAccount(', 'class FollowRequestsScreen');
  assert.ok(blocks.includes("_manageFollow('block'"));
  assert.ok(blocks.includes("_manageFollow('unblock'"));
  assert.doesNotMatch(follow + blocks, /FirebaseFirestore|\.delete\(\)/);
});
test('public relationship lists retain their authorized callable route', () => {
  assert.match(main, /httpsCallable\('readFollowList'\)/);
});
test('messaging projection uses the privacy editor default and the client consumes it', () => {
  const editor = fs.readFileSync(path.join(root, 'lib/ui/settings/privacy/privacy_account_overview_tab.dart'), 'utf8');
  const chat = fs.readFileSync(path.join(root, 'lib/features/shell/chat_page.dart'), 'utf8');
  const { projectProfile } = require('../security/profile-projection');
  assert.match(editor, /this\.whoCanMessage = 'mutual'/);
  assert.ok(chat.includes("privacy['whoCanMessage']"));
  assert.equal(projectProfile({}, { self: false, following: false }).privacy.whoCanMessage, 'mutual');
});
