// Static source guards only. These are not device or Flutter runtime tests.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path');
const root = path.resolve(__dirname, '../..');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
const service = fs.readFileSync(path.join(root, 'lib/ui/settings/push_preferences_service.dart'), 'utf8');
test('unused client-side cross-user notification senders stay removed', () => {
  assert.doesNotMatch(main, /Future<void>\s+pushNotification(?:FromMe)?\s*\(/);
  assert.doesNotMatch(main, /notif OK →|notif FAIL →/);
});
test('recipient actions keep the existing read and dismiss schema', () => {
  assert.match(main, /Future<void> _markNotificationRead\([\s\S]*?\.update\(\{'read': true\}\)/);
  assert.match(main, /Future<void> _dismissNotification\([\s\S]*?\.delete\(\)/);
  assert.match(main, /Future<void> _markAllNotificationsRead\([\s\S]*?batch\.update\(d\.reference, \{'read': true\}\)/);
});
test('device registration and detach retain callable-only paths', () => {
  assert.match(service, /httpsCallable\('syncPushDevice'/); assert.match(service, /httpsCallable\('detachPushDevice'/);
  function scan(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const file = path.join(dir, entry.name);
      if (entry.isDirectory()) scan(file);
      else if (file.endsWith('.dart')) assert.doesNotMatch(fs.readFileSync(file, 'utf8'), /collection\(['"]fcm_tokens['"]\)/, file);
    }
  }
  scan(path.join(root, 'lib'));
});
test('configured backend retains the real notification and device endpoints', () => {
  const index = fs.readFileSync(path.join(root, 'functions/index.js'), 'utf8');
  for (const name of ['pushOnNotification', 'syncPushDevice', 'detachPushDevice']) assert.ok(index.includes(`exports.${name}`));
  assert.equal(JSON.parse(fs.readFileSync(path.join(root, 'functions/package.json'))).main, 'index.js');
});
