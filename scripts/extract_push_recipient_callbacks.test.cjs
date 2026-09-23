const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), os = require('node:os'), path = require('node:path');
const {spawnSync} = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const script = path.join(__dirname, 'extract_push_recipient_callbacks.cjs');
const main = fs.readFileSync(path.join(root, 'lib/main.dart'), 'utf8');
function run(t, text, extra = []) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'push-callbacks-'));
  t.after(() => fs.rmSync(dir, {recursive:true, force:true}));
  const input = path.join(dir, 'main.dart'), output = path.join(dir, 'callbacks.dart');
  fs.writeFileSync(input, text);
  const result = spawnSync(process.execPath, [script, '--source', input, '--output', output, ...extra], {encoding:'utf8'});
  return {...result, output, generated:fs.existsSync(output) ? fs.readFileSync(output, 'utf8') : null};
}
test('extractor copies production callback body without rewriting its guard', t => {
  const result = run(t, main);
  assert.equal(result.status, 0, result.stderr);
  const start = main.indexOf('    FirebaseMessaging.onMessage.listen((msg) async {\n');
  const end = main.indexOf('\n    });\n\n    FirebaseMessaging.onMessageOpenedApp.listen', start);
  const body = main.slice(start + '    FirebaseMessaging.onMessage.listen((msg) async {\n'.length, end);
  assert.ok(result.generated.includes(body));
  const meta = JSON.parse(result.stdout);
  assert.equal(meta.sourceSha256, crypto.createHash('sha256').update(main).digest('hex'));
  assert.equal(meta.extractedSha256, crypto.createHash('sha256').update(result.generated).digest('hex'));
});
test('extractor rejects missing foreground callback instead of writing stale tests', t => {
  const result = run(t, main.replace('FirebaseMessaging.onMessage.listen((msg)', 'FirebaseMessaging.onMessage.listen((changed)'));
  assert.notEqual(result.status, 0);
  assert.equal(result.generated, null);
});
test('extractor rejects ambiguous foreground callback', t => {
  const result = run(t, main + '\n    FirebaseMessaging.onMessage.listen((msg) async {\n');
  assert.notEqual(result.status, 0);
  assert.equal(result.generated, null);
});
test('extractor rejects unknown command options', t => {
  const result = run(t, main, ['--ignored', 'value']);
  assert.notEqual(result.status, 0);
  assert.equal(result.generated, null);
});

test('checked-in callback fixture equals fresh production extraction', t => {
  const result = run(t, main);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.generated, fs.readFileSync(path.join(root,
    'test/support/generated_push_recipient_callbacks.dart'), 'utf8'));
});
