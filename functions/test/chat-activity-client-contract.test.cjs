// Source-integration checks complement the executable Dart client and Rules tests.
// They are not a Flutter runtime or mobile transport test.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const page = fs.readFileSync(path.join(root, 'lib/features/shell/chat_page.dart'), 'utf8');
const client = fs.readFileSync(path.join(root, 'lib/services/chat_activity_client.dart'), 'utf8');
test('chat screen uses the production activity writer and nested-merge adapter', () => {
  assert.match(page, /_chatActivity = ChatActivityClient\(/);
  assert.match(page, /sessionKey: \(\) => PublicProfileService\.viewerSession/);
  assert.match(page, /\.set\(data, SetOptions\(merge: true\)\)/);
  assert.match(page, /await _chatActivity\.markRead\(\)/);
  assert.match(page, /await _chatActivity\.setTyping\(active\)/);
});
test('legacy literal dotted activity set keys are absent from production screen', () => {
  assert.doesNotMatch(page, /['"](?:lastReadAt|typing)\.\$/);
  assert.match(client, /'lastReadAt': \{expectedUid: serverTimestamp\(\)\}/);
  assert.match(client, /'typing': \{expectedUid: active \? serverTimestamp\(\) : deleteField\(\)\}/);
});
test('peer typing has a finite deadline and writer closes with the screen', () => {
  assert.match(page, /_peerTypingExpiry = Timer\(remaining,/);
  assert.match(page, /_peerTypingExpiry\?\.cancel\(\);\s*_chatActivity\.dispose\(\);/);
  assert.match(page, /if \(text\.trim\(\)\.isEmpty\)/);
});
