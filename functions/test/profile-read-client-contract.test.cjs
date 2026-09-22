// Source-contract checks; not a substitute for Flutter execution/device tests.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
function section(start, end) {
  const a = main.indexOf(start), b = main.indexOf(end, a + start.length);
  assert.ok(a >= 0 && b > a, start); return main.slice(a, b);
}
test('author identity cache never reads raw user documents and is viewer-scoped', () => {
  const s = section('class AuthorProfiles {', 'class LiveAuthorPhoto ');
  assert.match(s, /PublicProfileService\.load\(uid\)/);
  assert.doesNotMatch(s, /FirebaseFirestore|\.collection\(/);
  for (const contract of ['viewerSession', '_generation != generation', '_photos.clear()', '_names.clear()',
    'blockedListRevision.value', 'followRevision.value']) assert.ok(s.includes(contract), contract);
});
test('privacy and comment checks use projections and fail closed', () => {
  const privacy = section('Future<bool> isUserPrivate(', 'Future<Set<String>> loadFollowingIds(');
  const comments = section('Future<bool> canCommentOnAuthor(', 'Future<void> _manageFollow(');
  assert.match(privacy, /PublicProfileService\.load\(userId\)/);
  assert.match(comments, /PublicProfileService\.load\(authorId\)/);
  assert.match(comments, /profile\['canViewContent'\] != true/);
  assert.match(comments, /viewerSession == session/);
  assert.doesNotMatch(privacy + comments, /\.collection\('users'\)/);
  assert.match(comments, /catch[\s\S]*return false;/);
});
test('availability helpers no longer issue raw per-user or directory queries', () => {
  const s = section('Future<bool> isPeerUnavailable(', 'bool isUserDocUnavailable(');
  assert.match(s, /PublicProfileService\.isUnavailable/);
  assert.match(s, /PublicProfileService\.unavailableUserIds/);
  assert.doesNotMatch(s, /FirebaseFirestore|whereIn|\.collection\(/);
});
test('profile screen retains raw-owner versus projected-other read separation', () => {
  const presence = section('void _listenPresence() {', 'String? get _presenceText');
  assert.match(presence, /_isSelf[\s\S]*PublicProfileService\.watch\(widget\.userId\)/);
  const load = section('Future<void> _loadProfile() async {', 'Future<void> _loadCounts()');
  assert.match(load, /if \(_isSelf\)[\s\S]*else[\s\S]*PublicProfileService\.load\(widget\.userId\)/);
});
test('PublicProfileService binds all reads and watches to the tested session-aware reader', () => {
  const s = fs.readFileSync(path.join(root, 'lib/ui/settings/public_profile_service.dart'), 'utf8');
  assert.match(s, /PublicProfileReader\(/); assert.match(s, /authStateChanges\(\)/);
  assert.match(s, /httpsCallable\('readPublicProfile'\)/);
  assert.doesNotMatch(s, /FirebaseFirestore|\.collection\(/);
  assert.match(s, /watch\(String userId\) => _reader\.watch\(userId\)/);
});
