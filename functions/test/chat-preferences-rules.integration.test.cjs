// Actual Auth + Firestore emulator authorization; Admin only seeds/inspects.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const PROJECT = 'demo-unispace-security';
const fsHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const loopback = /^(localhost|127\.0\.0\.1):\d+$/;
if (!loopback.test(fsHost || '') || !loopback.test(authHost || '') ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    [process.env.GCLOUD_PROJECT, process.env.GOOGLE_CLOUD_PROJECT].some(p => p && p !== PROJECT)) {
  throw new Error('Credential-free fixed demo project and loopback emulators required.');
}
const app = initializeApp({ projectId: PROJECT }, `preferences-${randomUUID()}`);
const db = getFirestore(app);
const auth = getAuth(app);
const base = `http://${fsHost}/v1/projects/${PROJECT}/databases/(default)/documents`;
let author, peer, outsider;
async function signup(prefix) {
  const email = `preferences-${randomUUID()}@example.test`;
  const password = 'Only-local-fixture-password-37!';
  const uid = `${prefix}.${randomUUID()}`;
  await auth.createUser({ uid, email, password });
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(response.ok, true, `Emulator sign-in returned ${response.status}`);
  const data = await response.json();
  assert.equal(data.localId, uid);
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  return { uid, token: data.idToken, authTime: claims.auth_time };
}
before(async () => { [author, peer, outsider] = await Promise.all([
  signup('9preferences-author'), signup('8preferences`peer'), signup('7preferences-outsider'),
]); });
after(async () => { await db.terminate(); await deleteApp(app); });
function val(v) {
  if (v instanceof Timestamp) return { timestampValue: v.toDate().toISOString() };
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: fields(v) } };
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, val(v)])); }
function fp(...parts) { return parts.map(p => '`' + p.replaceAll('\\', '\\\\').replaceAll('`', '\\`') + '`').join('.'); }
function write(path, data, mask = Object.keys(data).map(k => fp(k))) {
  return { update: { name: `projects/${PROJECT}/databases/(default)/documents/${path}`, fields: fields(data) },
    updateMask: { fieldPaths: mask } };
}
async function commit(actor, writes) {
  const response = await fetch(`${base}:commit`, { method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    body: JSON.stringify({ writes }), signal: AbortSignal.timeout(15000) });
  return { status: response.status, data: await response.json() };
}
function patch(path, actor, data, mask) { return commit(actor, [write(path, data, mask)]); }
function nested(path, field, uid, value) { return write(path, { [field]: { [uid]: value } }, [fp(field, uid)]); }
function stamp(path, field, uid, extra = {}) {
  const w = write(path, extra);
  w.updateTransforms = [{ fieldPath: fp(field, uid), setToServerValue: 'REQUEST_TIME' }];
  return w;
}
function ok(r) { assert.ok(r.status >= 200 && r.status < 300, `Expected success, got ${r.status}: ${r.data.error?.status}`); }
function denied(r) { assert.equal(r.status, 403); assert.equal(r.data.error?.status, 'PERMISSION_DENIED'); }
async function fixture(data = {}) {
  const path = `chats/preferences-${randomUUID()}`;
  await db.doc(path).set({ memberIds: [author.uid, peer.uid], ...data });
  return path;
}
async function unchanged(path, action) {
  const before = (await db.doc(path).get()).data();
  denied(await action());
  assert.deepEqual((await db.doc(path).get()).data(), before);
}
const oldTime = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
const futureTime = Timestamp.fromDate(new Date('2100-01-01T00:00:00Z'));
const values = { muted: true, nicknames: 'Local name', theme: { bubbleColor: 4281579399 },
  autoTranslate: false, autoTranslateLang: 'ar', clearedAt: oldTime };
const prefixes = ['pinned_', 'muted_', 'deletedBy_'];
function valueWrite(path, key, uid) {
  return key === 'clearedAt' ? stamp(path, key, uid) : nested(path, key, uid, values[key]);
}

// Exactly these nine negative controls must fail under immutable pre-fix main.
for (const key of Object.keys(values)) {
  test(`PREFREGRESSION: cannot replace peer ${key}`, async () => {
    const c = await fixture();
    await unchanged(c, () => commit(author, [valueWrite(c, key, peer.uid)]));
  });
}
for (const prefix of prefixes) {
  test(`PREFREGRESSION: cannot set peer ${prefix}flag`, async () => {
    const c = await fixture();
    await unchanged(c, () => patch(c, author, { [prefix + peer.uid]: true }));
  });
}
for (const key of Object.keys(values)) {
  test(`own ${key} edit and removal preserve peer values`, async () => {
    const c = await fixture({ [key]: { [peer.uid]: values[key] } });
    const r = await commit(author, [valueWrite(c, key, author.uid)]); ok(r);
    const d = (await db.doc(c).get()).data()[key];
    assert.deepEqual(d[peer.uid], values[key]);
    if (key === 'clearedAt') {
      assert.equal(d[author.uid].toDate().toISOString(),
        new Date(r.data.writeResults[0].transformResults[0].timestampValue).toISOString());
    } else assert.deepEqual(d[author.uid], values[key]);
    ok(await patch(c, author, {}, [fp(key, author.uid)]));
    assert.deepEqual((await db.doc(c).get()).data()[key], { [peer.uid]: values[key] });
  });
  test(`peer ${key} cannot be removed through a parent replacement or deletion`, async () => {
    const c = await fixture({ [key]: { [author.uid]: values[key], [peer.uid]: values[key] } });
    await unchanged(c, () => patch(c, author, { [key]: {} }));
    await unchanged(c, () => patch(c, author, {}, [fp(key)]));
    await unchanged(c, () => patch(c, author, {}, [fp(key, peer.uid)]));
  });
  test(`new chat cannot prepopulate peer or outsider ${key}`, async () => {
    for (const target of [peer, outsider]) {
      const c = `chats/preferences-create-${randomUUID()}`;
      const w = valueWrite(c, key, target.uid);
      w.update.fields.memberIds = val([author.uid, peer.uid]);
      w.updateMask.fieldPaths.push(fp('memberIds'));
      denied(await commit(author, [w]));
      assert.equal((await db.doc(c).get()).exists, false);
    }
  });
  test(`valid initial own ${key} and subsequent peer own edit are allowed`, async () => {
    const c = `chats/preferences-create-${randomUUID()}`;
    const w = valueWrite(c, key, author.uid);
    w.update.fields.memberIds = val([author.uid, peer.uid]);
    w.updateMask.fieldPaths.push(fp('memberIds'));
    ok(await commit(author, [w]));
    ok(await commit(peer, [valueWrite(c, key, peer.uid)]));
    assert.deepEqual(Object.keys((await db.doc(c).get()).data()[key]).sort(), [author.uid, peer.uid].sort());
  });
  test(`malformed ${key} container or value is denied when changed`, async () => {
    const c = await fixture({ [key]: { [peer.uid]: values[key] } });
    for (const bad of [null, [], 'invalid', 42]) await unchanged(c, () => patch(c, author, { [key]: bad }));
    for (const bad of [null, [], 42]) await unchanged(c, () => commit(author, [nested(c, key, author.uid, bad)]));
  });
  test(`outsider ${key} and mixed own plus peer changes are rejected atomically`, async () => {
    const c = await fixture({ lastMessage: 'before' });
    await unchanged(c, () => commit(peer, [valueWrite(c, key, outsider.uid)]));
    await unchanged(c, () => commit(author, [valueWrite(c, key, author.uid), valueWrite(c, key, peer.uid)]));
    const w = valueWrite(c, key, peer.uid);
    w.update.fields.lastMessage = val('after'); w.updateMask.fieldPaths.push(fp('lastMessage'));
    await unchanged(c, () => commit(author, [w]));
  });
}
for (const prefix of prefixes) {
  test(`both members may toggle or delete only their own ${prefix}flag`, async () => {
    const c = await fixture();
    for (const [actor, other] of [[author, peer], [peer, author]]) {
      for (const value of [true, false]) ok(await patch(c, actor, { [prefix + actor.uid]: value }));
      await unchanged(c, () => patch(c, other, {}, [fp(prefix + actor.uid)]));
      ok(await patch(c, actor, {}, [fp(prefix + actor.uid)]));
    }
  });
  test(`${prefix}flag create accepts own booleans but not peer initialization`, async () => {
    for (const actor of [author, peer]) {
      const c = `chats/preferences-create-${randomUUID()}`;
      ok(await patch(c, actor, { memberIds: [author.uid, peer.uid], [prefix + actor.uid]: false }));
      const bad = `chats/preferences-create-${randomUUID()}`;
      const other = actor === author ? peer : author;
      denied(await patch(bad, actor, { memberIds: [author.uid, peer.uid], [prefix + other.uid]: false }));
      assert.equal((await db.doc(bad).get()).exists, false);
    }
  });
  test(`changed ${prefix}flag requires boolean while legacy unrelated values survive`, async () => {
    const c = await fixture({ [prefix + author.uid]: 'old', [prefix + peer.uid]: null });
    ok(await patch(c, author, { lastMessage: 'unchanged legacy flags' }));
    for (const bad of [null, 42, 'false', [], {}]) await unchanged(c, () => patch(c, author, { [prefix + author.uid]: bad }));
    ok(await patch(c, author, { [prefix + author.uid]: true }));
    assert.equal((await db.doc(c).get()).data()[prefix + peer.uid], null);
  });
}
test('clear-history cutoff cannot be backdated or future-dated', async () => {
  const c = await fixture();
  for (const time of [oldTime, futureTime]) await unchanged(c, () => commit(author, [nested(c, 'clearedAt', author.uid, time)]));
});
test('concurrent nested preferences preserve both users and existing theme settings', async () => {
  const c = await fixture({ theme: { [author.uid]: { wallpaper: 'default' }, [peer.uid]: { bubbleColor: 1 } } });
  const writes = [author, peer].map(a => write(c, { theme: { [a.uid]: { wallpaper: 'sky' } } }, [fp('theme', a.uid, 'wallpaper')]));
  (await Promise.all(writes.map((w, i) => commit([author, peer][i], [w])))).forEach(ok);
  assert.deepEqual((await db.doc(c).get()).data().theme[peer.uid], { bubbleColor: 1, wallpaper: 'sky' });
});
test('normal direct bootstrap, empty settings, summary and unread changes remain permitted', async () => {
  const c = `chats/preferences-create-${randomUUID()}`;
  ok(await patch(c, author, { memberIds: [author.uid, peer.uid], type: 'direct', muted: {}, theme: {} }));
  ok(await patch(c, author, { lastMessage: 'hello', lastSenderId: author.uid, unread: { [peer.uid]: 1 } }));
});
test('member IDs must be two distinct nonempty strings on create and cannot be substituted', async () => {
  for (const ids of [[author.uid, author.uid], [author.uid, ''], [author.uid, 42],
    [author.uid], [author.uid, peer.uid, outsider.uid], { [author.uid]: true, [peer.uid]: true }]) {
    const c = `chats/preferences-create-${randomUUID()}`;
    denied(await patch(c, author, { memberIds: ids }));
    assert.equal((await db.doc(c).get()).exists, false);
  }
  const c = await fixture();
  await unchanged(c, () => patch(c, author, { memberIds: [author.uid, outsider.uid], ['pinned_' + author.uid]: true }));
});
test('malformed legacy membership fails closed; valid deletion tombstone stays compatible', async () => {
  const bad = await fixture({ memberIds: [author.uid, peer.uid, outsider.uid] });
  await unchanged(bad, () => patch(bad, author, { ['pinned_' + peer.uid]: true }));
  const good = await fixture({ memberIds: [author.uid, 'deleted_account_tombstone'] });
  ok(await patch(good, author, { ['pinned_' + author.uid]: true }));
});
test('unchanged malformed legacy maps survive unrelated writes but cannot be replaced by clients', async () => {
  const c = await fixture({ theme: 'old', muted: null, nicknames: { [peer.uid]: 42 } });
  ok(await patch(c, author, { lastMessage: 'safe update' }));
  ok(await commit(author, [nested(c, 'nicknames', author.uid, '')]));
  assert.equal((await db.doc(c).get()).data().nicknames[peer.uid], 42);
  await unchanged(c, () => patch(c, author, { theme: { [author.uid]: {} } }));
});
test('deleting an exclusively own preferences map is allowed and idempotent', async () => {
  const c = await fixture({ nicknames: { [author.uid]: 'Only me' } });
  for (let i = 0; i < 2; i++) ok(await patch(c, author, {}, [fp('nicknames')]));
});
test('literal dotted legacy keys do not grant canonical peer preference authority', async () => {
  const legacy = `nicknames.${peer.uid}`;
  const c = await fixture({ [legacy]: 'legacy inert value' });
  ok(await commit(author, [nested(c, 'nicknames', author.uid, 'Mine')]));
  await unchanged(c, () => commit(author, [nested(c, 'nicknames', peer.uid, 'Forged')]));
  assert.equal((await db.doc(c).get()).data()[legacy], 'legacy inert value');
});
test('anonymous, outsider, removed, revoked and suspended identities cannot alter preferences', async () => {
  const c = await fixture();
  for (const actor of [null, outsider]) await unchanged(c, () => commit(actor, [nested(c, 'muted', peer.uid, true)]));
  await db.doc(c).update({ memberIds: [author.uid, outsider.uid] });
  await unchanged(c, () => patch(c, peer, { ['muted_' + peer.uid]: true }));
  await db.doc(c).update({ memberIds: [author.uid, peer.uid] });
  const cutoff = db.doc(`authRevocations/${peer.uid}`);
  await cutoff.set({ revokedBefore: peer.authTime });
  try { await unchanged(c, () => patch(c, peer, { ['pinned_' + peer.uid]: true })); } finally { await cutoff.delete(); }
  const controls = db.doc(`accountStateControls/${peer.uid}`);
  await controls.set({ schemaVersion: 1, adminSuspended: true });
  try { await unchanged(c, () => commit(peer, [nested(c, 'theme', peer.uid, {})])); } finally { await controls.delete(); }
});
test('a forged preference aborts other writes in the same batch', async () => {
  const a = await fixture({ lastMessage: 'before' }); const b = await fixture();
  await unchanged(b, () => commit(author, [write(a, { lastMessage: 'after' }), nested(b, 'muted', peer.uid, true)]));
  assert.equal((await db.doc(a).get()).data().lastMessage, 'before');
});
test('combined initial and update preferences with activity stay within real rule evaluation limits', async () => {
  const c = `chats/preferences-combined-${randomUUID()}`;
  for (const actor of [author, peer]) {
    const data = {}; const masks = [];
    for (const key of Object.keys(values).filter(k => k !== 'clearedAt')) {
      data[key] = { [actor.uid]: values[key] }; masks.push(fp(key, actor.uid));
    }
    for (const prefix of prefixes) { data[prefix + actor.uid] = true; masks.push(fp(prefix + actor.uid)); }
    if (actor === author) { data.memberIds = [author.uid, peer.uid]; masks.push(fp('memberIds')); }
    const w = write(c, data, masks);
    w.updateTransforms = ['clearedAt', 'lastReadAt', 'typing'].map(key => ({
      fieldPath: fp(key, actor.uid), setToServerValue: 'REQUEST_TIME',
    }));
    ok(await commit(actor, [w]));
  }
  const d = (await db.doc(c).get()).data();
  for (const key of [...Object.keys(values), 'lastReadAt', 'typing']) {
    assert.deepEqual(Object.keys(d[key]).sort(), [author.uid, peer.uid].sort());
  }
});
test('preference scalar types are enforced without rejecting legitimate empty strings', async () => {
  const c = await fixture();
  for (const [key, bad] of [['muted', 'true'], ['autoTranslate', 'false'], ['nicknames', false],
    ['autoTranslateLang', false], ['theme', 'default']]) {
    await unchanged(c, () => commit(author, [nested(c, key, author.uid, bad)]));
  }
  for (const key of ['nicknames', 'autoTranslateLang']) ok(await commit(author, [nested(c, key, author.uid, '')]));
});
