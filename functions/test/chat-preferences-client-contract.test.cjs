// Static wiring checks complement Dart execution and exported-payload emulators.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const page = fs.readFileSync(process.env.CHAT_PREFERENCE_SOURCE || path.resolve(__dirname, '../../lib/features/shell/chat_page.dart'), 'utf8');
test('PREFERENCECLIENTREGRESSION: no literal dotted preference set keys remain', () => {
  assert.doesNotMatch(page, /['"](?:nicknames|theme|muted|clearedAt|autoTranslate|autoTranslateLang)\.\$/);
});
test('PREFERENCECLIENTREGRESSION: bubble selection has only one persistence decision', () => {
  const block = page.slice(page.indexOf('return _CompactBubbleOption('), page.indexOf('const SizedBox(height: 24)', page.indexOf('return _CompactBubbleOption(')));
  assert.equal((block.match(/setBubbleGradient\(/g) || []).length, 1);
  assert.equal((block.match(/setBubbleColor\(/g) || []).length, 1);
  assert.doesNotMatch(block, /_patch\(/);
});
test('screen-owned preference writer is passed to the details and disposed', () => {
  assert.match(page, /_chatPreferences = ChatPreferencesClient\(/);
  assert.match(page, /preferences: _chatPreferences/);
  assert.match(page, /_chatPreferences\.dispose\(\)/);
  assert.match(page, /sessionKey: \(\) => PublicProfileService\.viewerSession/);
  assert.match(page, /\.set\(data, SetOptions\(merge: true\)\)/);
  assert.match(page, /await _chatPreferences\.clearHistory\(\)/);
});
test('details use the bound owner and publish previews only after saved result', () => {
  assert.match(page, /String get _uid => widget\.preferences\.expectedUid/);
  assert.match(page, /if \(!saved\) return;/);
  assert.match(page, /return await action\(\) && _currentPreferences/);
  assert.doesNotMatch(page, /theme patch failed|تعذر حفظ المظهر: \$e/);
});
test('preference snapshot decoding is typed and earlier activity guards remain wired', () => {
  assert.match(page, /ChatPreferencesSnapshot\.fromData\(data, _me\.id\)/);
  assert.match(page, /await _chatActivity\.markRead\(\)/);
  assert.match(page, /await _chatActivity\.setTyping\(active\)/);
  assert.match(page, /_peerTypingExpiry = Timer\(remaining,/);
});

test('MUTECONSISTENCYREGRESSION: list shares the detail mute reader', () => {
  assert.match(page, /muted: ChatPreferencesSnapshot\.readMuted\(doc\.data\(\), uid\)/);
  assert.doesNotMatch(page, /muted: doc\.data\(\)\[['"]muted_\$uid['"]\]/);
});
test('MUTECONSISTENCYREGRESSION: list mute uses the bound preference writer', () => {
  const block = page.slice(page.indexOf("      case 'mute':"), page.indexOf("      case 'delete':"));
  assert.match(block, /await preferences\.setMuted\(!muted\)/);
  assert.match(block, /expectedUid: ownerUid/);
  assert.match(block, /currentUid: \(\) => mounted \? _auth\.currentUser\?\.uid : null/);
  assert.match(block, /preferences\.dispose\(\)/);
  assert.match(block, /context\.mounted && preferences\.isCurrent/);
  assert.doesNotMatch(block, /ref\.set\(\{['"]muted_/);
});
test('MUTECONSISTENCYREGRESSION: menu retains its owner and session across selection', () => {
  const start = page.indexOf('  Future<void> _showChatActions(');
  const block = page.slice(start, page.indexOf('class _ChatRow', start));
  assert.match(page, /ownerUid: uid/);
  assert.match(block, /required String ownerUid/);
  assert.match(block, /final menuSession = PublicProfileService\.viewerSession;/);
  assert.ok(block.indexOf('final menuSession = PublicProfileService.viewerSession;') < block.indexOf('await showMenu<String>'));
  const selected = block.slice(block.indexOf('if (selected == null'));
  assert.match(selected, /_auth\.currentUser\?\.uid != ownerUid/);
  assert.match(selected, /PublicProfileService\.viewerSession != menuSession/);
  assert.match(selected, /!context\.mounted/);
  assert.match(selected, /final uid = ownerUid;/);
  assert.doesNotMatch(selected, /_auth\.currentUser!\.uid/);
});
