// Static wiring guards, not device/UI interaction tests.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), path = require('node:path');
const root = path.resolve(__dirname, '../..');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
test('foreground notification rendering still passes through the tested preference service', () => {
  const start = main.indexOf('FirebaseMessaging.onMessage.listen((msg) async {');
  const end = main.indexOf('FirebaseMessaging.onMessageOpenedApp.listen', start);
  assert.ok(start >= 0 && end > start);
  const listener = main.slice(start, end);
  const gate = listener.indexOf('!PushPreferencesService.instance.allows(');
  const render = listener.indexOf('await _localNotifs.show(');
  assert.ok(gate >= 0 && render > gate);
  assert.match(listener.slice(gate, render), /return;/);
});
test('foreground system presentation remains disabled before the local display gate', () => {
  const setup = main.indexOf('await messaging.setForegroundNotificationPresentationOptions(');
  const listen = main.indexOf('FirebaseMessaging.onMessage.listen((msg) async {');
  assert.ok(setup >= 0 && setup < listen);
  for (const flag of ['alert', 'badge', 'sound']) {
    assert.match(main.slice(setup, listen), new RegExp(`${flag}: false`));
  }
});
