// Static source contracts only; production Dart behavior is tested separately.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
const drawer = fs.readFileSync(path.join(root, 'lib/ui/settings/drawer_screens.dart'), 'utf8');
const screen = fs.readFileSync(path.join(root, 'lib/features/settings/privacy/account_deletion_screen.dart'), 'utf8');
test('legacy status and freeze writers now use server lifecycle service', () => {
  assert.match(main, /AccountStateService\.change\(user.uid, 'deactivate'\)/);
  assert.equal((main.match(/AccountStateService\.change\(user.uid, 'reactivate'\)/g) || []).length, 2);
  assert.match(drawer, /AccountStateService\.change\(uid, next \? 'freeze' : 'unfreeze'\)/);
  assert.match(drawer, /AccountStateService\.change\(user.uid, 'unfreeze'\)/);
  assert.doesNotMatch(main + drawer, /'accountStatus'\s*:\s*'(active|disabled|deleted)'|'isDeleted'\s*:\s*true|'frozen'\s*:\s*(true|false|next)/);
});
test('all three deletion screens call the durable server deletion path', () => {
  for (const s of [main, drawer, screen]) {
    assert.match(s, /AccountStateService\.requestDeletion\(/);
    assert.doesNotMatch(s, /await (current|user)\.delete\(\)/);
  }
});
test('production service uses tested client logic without direct Firestore fallback', () => {
  const service = fs.readFileSync(path.join(root, 'lib/ui/settings/account_state_service.dart'), 'utf8');
  assert.match(service, /AccountStateClient\(/); assert.match(service, /PublicProfileService.viewerSession/);
  assert.doesNotMatch(service, /FirebaseFirestore|\.collection\(/);
});
test('lifecycle functions are exported from the configured production entrypoint', () => {
  const s = fs.readFileSync(path.join(root, 'functions/index.js'), 'utf8');
  assert.match(s, /exports.setOwnAccountState = onCall/);
  assert.match(s, /exports.setAdministrativeAccountRestriction = onCall/);
});

test('global callable access guard has only explicit lifecycle exemptions', () => {
  const s = fs.readFileSync(path.join(root, 'functions/index.js'), 'utf8');
  assert.match(s, /const onCall = .*accountAccessGuard\(handler\)/);
  const exemptions = [...s.matchAll(/exports\.(\w+) = lifecycleExemptOnCall\(/g)].map(m => m[1]).sort();
  assert.deepEqual(exemptions, ['detachPushDevice', 'markCurrentSession', 'requestAccountDeletion', 'revokeAllUserSessions']);
});
