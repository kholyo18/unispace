// Actual client authorization, confined to local Auth/Firestore emulators.
// Admin only seeds fixtures and inspects persisted state, never proves access.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const PROJECT = 'demo-unispace-security';
const fsHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const loopback = /^(localhost|127\.0\.0\.1):\d+$/;
if (!loopback.test(fsHost || '') || !loopback.test(authHost || '') ||
    (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== PROJECT)) {
  throw new Error('Demo project and local Auth/Firestore emulators required.');
}
const app = initializeApp({ projectId: PROJECT }, `metadata-${randomUUID()}`);
const db = getFirestore(app);
const base = `http://${fsHost}/v1/projects/${PROJECT}/databases/(default)/documents`;
let author, peer, outsider;
async function signup() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `metadata-${randomUUID()}@example.test`,
      password: 'Local-fixture-password-29!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(response.ok, true, `Local signup returned ${response.status}`);
  const data = await response.json();
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  return { uid: data.localId, token: data.idToken, authTime: claims.auth_time };
}
before(async () => { [author, peer, outsider] = await Promise.all([signup(), signup(), signup()]); });
after(async () => { await db.terminate(); await deleteApp(app); });
function val(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: fields(v) } };
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, val(v)])); }
async function request(url, actor, body) {
  const response = await fetch(url, { method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000) });
  return { status: response.status, data: await response.json() };
}
function write(path, data, mask = Object.keys(data)) {
  return { update: { name: `projects/${PROJECT}/databases/(default)/documents/${path}`, fields: fields(data) },
    updateMask: { fieldPaths: mask } };
}
function commit(actor, writes) { return request(`${base}:commit`, actor, { writes }); }
function patch(path, actor, data, mask) { return commit(actor, [write(path, data, mask)]); }
function nested(path, field, uid, v) { return write(path, { [field]: { [uid]: v } }, [`${field}.${uid}`]); }
function ok(r) { assert.ok(r.status >= 200 && r.status < 300, `Expected success, got ${r.status}: ${r.data.error?.status}`); }
function denied(r) { assert.equal(r.status, 403); assert.equal(r.data.error?.status, 'PERMISSION_DENIED'); }
async function fixture(data = {}) {
  const chat = `chats/metadata-${randomUUID()}`, message = `${chat}/messages/one`;
  await db.doc(chat).set({ memberIds: [author.uid, peer.uid] });
  await db.doc(message).set({ authorId: author.uid, text: 'original', ...data });
  return { chat, message };
}
async function rejectUnchanged(path, action) {
  const before = (await db.doc(path).get()).data();
  denied(await action());
  assert.deepEqual((await db.doc(path).get()).data(), before);
}

// Exact failure names are checked against immutable main Rules in CI.
test('REGRESSION: author cannot forge peer reaction', async () => {
  const f = await fixture();
  await rejectUnchanged(f.message, () => patch(f.message, author, { reactions: { [peer.uid]: ['👍'] } }));
});
test('REGRESSION: peer cannot rewrite author reaction', async () => {
  const f = await fixture({ reactions: { [author.uid]: ['❤️'] } });
  await rejectUnchanged(f.message, () => patch(f.message, peer, { reactions: { [author.uid]: ['😢'] } }));
});
test('REGRESSION: author cannot erase peer reactions with text edit', async () => {
  const f = await fixture({ reactions: { [peer.uid]: ['👍'] } });
  await rejectUnchanged(f.message, () => patch(f.message, author, { text: 'edited', reactions: {} }));
});
test('REGRESSION: author cannot forge peer read receipt', async () => {
  const f = await fixture();
  await rejectUnchanged(f.message, () => patch(f.message, author, { readBy: [peer.uid] }));
});
test('REGRESSION: peer cannot erase existing read receipt', async () => {
  const f = await fixture({ readBy: [author.uid, peer.uid] });
  await rejectUnchanged(f.message, () => patch(f.message, peer, { readBy: [] }));
});
test('REGRESSION: create cannot prepopulate another persons metadata', async () => {
  const f = await fixture(), path = `${f.chat}/messages/forged`;
  denied(await patch(path, author, { authorId: author.uid, reactions: { [peer.uid]: ['👍'] }, readBy: [peer.uid] }));
  assert.equal((await db.doc(path).get()).exists, false);
});
test('REGRESSION: author cannot forge peer star', async () => {
  const f = await fixture();
  await rejectUnchanged(f.message, () => patch(f.message, author, { starredBy: { [peer.uid]: true } }));
});
test('REGRESSION: recipient can star another authors message', async () => {
  const f = await fixture();
  ok(await commit(peer, [nested(f.message, 'starredBy', peer.uid, true)]));
  assert.equal((await db.doc(f.message).get()).data().starredBy[peer.uid], true);
});

test('own dotted reaction add and delete preserve the other participant', async () => {
  const f = await fixture({ reactions: { [author.uid]: ['❤️'] } });
  ok(await commit(peer, [nested(f.message, 'reactions', peer.uid, ['👍', '🔥'])]));
  assert.deepEqual((await db.doc(f.message).get()).data().reactions,
    { [author.uid]: ['❤️'], [peer.uid]: ['👍', '🔥'] });
  ok(await patch(f.message, peer, { reactions: {} }, [`reactions.${peer.uid}`]));
  assert.deepEqual((await db.doc(f.message).get()).data().reactions, { [author.uid]: ['❤️'] });
});
test('legacy string and all six quick reactions remain accepted', async () => {
  const f = await fixture({ reactions: { [peer.uid]: 'like' } });
  ok(await commit(peer, [nested(f.message, 'reactions', peer.uid, ['❤️', '😂', '😮', '😢', '🔥', '👍'])]));
  ok(await commit(peer, [nested(f.message, 'reactions', peer.uid, 'like')]));
});
test('full map update may change only caller while preserving other entries', async () => {
  const f = await fixture({ reactions: { [author.uid]: ['❤️'], [peer.uid]: ['👍'] } });
  ok(await patch(f.message, peer, { reactions: { [author.uid]: ['❤️'], [peer.uid]: ['🔥'] } }));
});
test('concurrent dotted writes preserve both participants', async () => {
  const f = await fixture();
  (await Promise.all([
    commit(author, [nested(f.message, 'reactions', author.uid, ['❤️'])]),
    commit(peer, [nested(f.message, 'reactions', peer.uid, ['👍'])]),
  ])).forEach(ok);
  assert.deepEqual((await db.doc(f.message).get()).data().reactions, { [author.uid]: ['❤️'], [peer.uid]: ['👍'] });
});
test('whole map deletion requires caller to own every existing entry', async () => {
  const f = await fixture({ reactions: { [author.uid]: ['❤️'], [peer.uid]: ['👍'] } });
  await rejectUnchanged(f.message, () => patch(f.message, author, {}, ['reactions']));
  const own = await fixture({ reactions: { [peer.uid]: ['👍'] } });
  ok(await patch(own.message, peer, {}, ['reactions']));
});
for (const [label, invalid] of Object.entries({ null: null, number: 3, object: { emoji: '👍' },
  mixed: ['👍', 3], empty: [], oversized: Array(7).fill('👍'), long: 'x'.repeat(33), nested: [{ emoji: '👍' }], duplicates: ['👍', '👍'] })) {
  test(`malformed own reaction denied: ${label}`, async () => {
    const f = await fixture();
    await rejectUnchanged(f.message, () => patch(f.message, peer, { reactions: { [peer.uid]: invalid } }));
  });
}
test('reaction container cannot be an array', async () => {
  const f = await fixture();
  await rejectUnchanged(f.message, () => patch(f.message, author, { reactions: [] }));
});
test('own star acknowledgement is idempotent and deletion preserves others', async () => {
  const f = await fixture({ starredBy: { [author.uid]: true } });
  ok(await commit(peer, [nested(f.message, 'starredBy', peer.uid, true)]));
  ok(await commit(peer, [nested(f.message, 'starredBy', peer.uid, true)]));
  ok(await patch(f.message, peer, { starredBy: {} }, [`starredBy.${peer.uid}`]));
  assert.deepEqual((await db.doc(f.message).get()).data().starredBy, { [author.uid]: true });
});
test('peer cannot erase author star or store false or non-boolean stars', async () => {
  const f = await fixture({ starredBy: { [author.uid]: true, [peer.uid]: true } });
  await rejectUnchanged(f.message, () => patch(f.message, peer, { starredBy: { [peer.uid]: true } }));
  for (const v of [false, 'true', 1, null]) {
    await rejectUnchanged(f.message, () => commit(author, [nested(f.message, 'starredBy', author.uid, v)]));
  }
});
test('own read receipt append and repeated arrayUnion remain valid', async () => {
  const f = await fixture({ readBy: [author.uid] });
  const w = { transform: { document: `projects/${PROJECT}/databases/(default)/documents/${f.message}`,
    fieldTransforms: [{ fieldPath: 'readBy', appendMissingElements: { values: [val(peer.uid)] } }] } };
  ok(await commit(peer, [w])); ok(await commit(peer, [w]));
  assert.deepEqual((await db.doc(f.message).get()).data().readBy, [author.uid, peer.uid]);
});
test('a read receipt cannot be removed even by its own reader', async () => {
  const f = await fixture({ readBy: [peer.uid] });
  await rejectUnchanged(f.message, () => patch(f.message, peer, {}, ['readBy']));
});
test('readBy rejects duplicates unrelated identities and non-list values', async () => {
  const f = await fixture({ readBy: [author.uid] });
  for (const readBy of [[author.uid, peer.uid, peer.uid], [author.uid, outsider.uid], [author.uid, 3],
    'reader', { [peer.uid]: true }, null]) {
    await rejectUnchanged(f.message, () => patch(f.message, peer, { readBy }));
  }
});
test('creation permits omitted metadata or own well-typed metadata', async () => {
  const f = await fixture();
  ok(await patch(`${f.chat}/messages/plain`, author, { authorId: author.uid, type: 'text', text: 'hello' }));
  ok(await patch(`${f.chat}/messages/self`, author, { authorId: author.uid, text: 'hello',
    reactions: { [author.uid]: ['❤️'] }, starredBy: { [author.uid]: true }, readBy: [author.uid] }));
});
test('creation separately rejects forged star and read receipt', async () => {
  const f = await fixture();
  for (const field of ['readBy', 'starredBy']) {
    const v = field === 'readBy' ? [peer.uid] : { [peer.uid]: true };
    denied(await patch(`${f.chat}/messages/${field}`, author, { authorId: author.uid, [field]: v }));
  }
});
test('unchanged malformed legacy metadata does not prevent author text edits', async () => {
  const f = await fixture({ reactions: null, starredBy: false, readBy: 'legacy-invalid' });
  ok(await patch(f.message, author, { text: 'edited' }));
  assert.equal((await db.doc(f.message).get()).data().reactions, null);
  await rejectUnchanged(f.message, () => patch(f.message, author, { reactions: { [author.uid]: ['❤️'] } }));
});
test('personal reaction or star does not authorize editing peer text', async () => {
  const f = await fixture();
  await rejectUnchanged(f.message, () => patch(f.message, peer, { text: 'forged', reactions: { [peer.uid]: ['👍'] } }));
  await rejectUnchanged(f.message, () => patch(f.message, peer, { text: 'forged', starredBy: { [peer.uid]: true } }));
});
test('anonymous outsider and removed member cannot mutate metadata', async () => {
  const f = await fixture();
  for (const actor of [null, outsider]) denied(await patch(f.message, actor, { reactions: { [peer.uid]: ['👍'] } }));
  await db.doc(f.chat).update({ memberIds: [author.uid, outsider.uid] });
  await rejectUnchanged(f.message, () => patch(f.message, peer, { starredBy: { [peer.uid]: true } }));
});
test('revoked or suspended member cannot change personal metadata', async () => {
  const f = await fixture(), cutoff = db.doc(`authRevocations/${peer.uid}`);
  await cutoff.set({ revokedBefore: peer.authTime });
  try { denied(await patch(f.message, peer, { reactions: { [peer.uid]: ['👍'] } })); }
  finally { await cutoff.delete(); }
  const control = db.doc(`accountStateControls/${peer.uid}`);
  await control.set({ schemaVersion: 1, adminSuspended: true });
  try { denied(await patch(f.message, peer, { starredBy: { [peer.uid]: true } })); }
  finally { await control.delete(); }
});
test('mixed batch with one forged entry is rejected atomically', async () => {
  const f = await fixture();
  denied(await commit(peer, [nested(f.message, 'reactions', peer.uid, ['👍']),
    nested(f.message, 'reactions', author.uid, ['😢'])]));
  assert.equal((await db.doc(f.message).get()).data().reactions, undefined);
});
