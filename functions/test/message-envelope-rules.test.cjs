// Client Rules regression tests. Admin SDK only seeds and inspects demo fixtures.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const local = /^(127\.0\.0\.1|localhost):\d+$/;
const project = 'demo-unispace-security';
if (!local.test(process.env.FIRESTORE_EMULATOR_HOST || '') ||
    !local.test(process.env.FIREBASE_AUTH_EMULATOR_HOST || '') ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    [process.env.GCLOUD_PROJECT, process.env.GOOGLE_CLOUD_PROJECT].some(v => v && v !== project)) {
  throw Error('Credential-free loopback Auth/Firestore demo emulators required.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const app = initializeApp({ projectId: project }, `message-envelope-${randomUUID()}`);
const db = getFirestore(app);
const base = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${project}/databases/(default)/documents`;
let author, peer, outsider;
async function signup() {
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `envelope-${randomUUID()}@example.test`, password: 'Demo-fixture-only-482!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  assert.equal(response.status, 200);
  assert.equal(typeof data.localId, 'string');
  assert.equal(typeof data.idToken, 'string');
  return { uid: data.localId, token: data.idToken };
}
before(async () => { [author, peer, outsider] = await Promise.all([signup(), signup(), signup()]); });
after(async () => { await db.terminate(); await deleteApp(app); });
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number' && Number.isFinite(v)) return { integerValue: String(v) };
  if (v instanceof Timestamp) return { timestampValue: v.toDate().toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  if (v && typeof v === 'object') return { mapValue: { fields: fields(v) } };
  throw TypeError('Unsupported fixture value');
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])); }
async function request(url, actor, method, body) {
  const response = await fetch(url, {
    method, headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }), signal: AbortSignal.timeout(15000),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}
function allowed(result) { assert.ok(result.status >= 200 && result.status < 300, JSON.stringify(result)); }
function denied(result) {
  assert.equal(result.status, 403);
  assert.equal(result.body?.error?.status, 'PERMISSION_DENIED');
}
async function fixture(extra = {}) {
  const chat = `chats/envelope-${randomUUID()}`, path = `${chat}/messages/original`;
  await db.doc(chat).set({ memberIds: [author.uid, peer.uid] });
  await db.doc(path).set({
    authorId: author.uid, type: 'text', text: 'Original',
    createdAt: Timestamp.fromMillis(42000), editedAt: Timestamp.fromMillis(43000),
    url: 'https://example.test/original', name: 'original.txt', size: 15, duration: 2,
    replyToId: 'original-reply-id', replyToText: 'Original reply',
    replyToAuthorId: peer.uid, reactions: { [peer.uid]: 'like' },
    starredBy: { [peer.uid]: true }, readBy: [peer.uid], ...extra,
  });
  return { chat, path };
}
async function patch(f, actor, data = {}, remove = [], serverEditedAt = false) {
  const paths = [...Object.keys(data), ...remove];
  const write = {
    update: { name: `projects/${project}/databases/(default)/documents/${f.path}`, fields: fields(data) },
    updateMask: { fieldPaths: paths }, currentDocument: { exists: true },
  };
  if (serverEditedAt) write.updateTransforms = [{ fieldPath: 'editedAt', setToServerValue: 'REQUEST_TIME' }];
  return request(base + ':commit', actor, 'POST', { writes: [write] });
}
async function unchangedAfterDenied(f, actor, data, remove = []) {
  const before = (await db.doc(f.path).get()).data();
  denied(await patch(f, actor, data, remove));
  assert.deepEqual((await db.doc(f.path).get()).data(), before);
}
test('production text edit with server editedAt preserves the message envelope and peer metadata', async () => {
  const f = await fixture(), before = (await db.doc(f.path).get()).data();
  allowed(await patch(f, author, { text: 'Edited' }, [], true));
  const next = (await db.doc(f.path).get()).data();
  assert.equal(next.text, 'Edited');
  assert.ok(next.editedAt.toMillis() > before.editedAt.toMillis());
  delete next.text; delete next.editedAt; delete before.text; delete before.editedAt;
  assert.deepEqual(next, before);
});
test('legacy text-only update remains compatible', async () => {
  const f = await fixture(); allowed(await patch(f, author, { text: 'Legacy edit' }));
});
for (const [key, replacement] of Object.entries({
  type: 'image', createdAt: Timestamp.fromMillis(999999999),
  url: 'https://example.test/replacement', name: 'replacement.txt', size: 999,
  duration: 30, replyToId: 'other-message', replyToText: 'Changed attribution',
  replyToAuthorId: 'another-author',
})) {
  test(`ENVELOPE: author cannot replace ${key}, even alongside a valid text edit`, async () => {
    const f = await fixture(); await unchangedAfterDenied(f, author, { text: 'Edited', [key]: replacement });
  });
}
for (const key of ['type', 'createdAt', 'url', 'replyToId']) {
  test(`ENVELOPE: author cannot delete immutable ${key}`, async () => {
    const f = await fixture(); await unchangedAfterDenied(f, author, {}, [key]);
  });
}
test('ENVELOPE: unknown metadata cannot be added by the author', async () => {
  const f = await fixture(); await unchangedAfterDenied(f, author, { system: true, privateMediaId: 'forged' });
});
for (const v of [null, 42, true, ['text'], { content: 'text' }]) {
  test(`ENVELOPE: edited text rejects non-string ${JSON.stringify(v)}`, async () => {
    const f = await fixture(); await unchangedAfterDenied(f, author, { text: v });
  });
}
test('ENVELOPE: editedAt cannot be backdated, future-dated, removed or retyped', async () => {
  const f = await fixture();
  for (const v of [Timestamp.fromMillis(0), Timestamp.fromMillis(4102444800000), 'yesterday', null]) {
    await unchangedAfterDenied(f, author, { editedAt: v });
  }
  await unchangedAfterDenied(f, author, {}, ['editedAt']);
});
test('unchanged legacy malformed immutable fields do not prevent a legitimate edit', async () => {
  const f = await fixture({ createdAt: 'legacy', size: 'legacy', url: { legacy: true } });
  allowed(await patch(f, author, { text: 'Still editable' }, [], true));
  assert.equal((await db.doc(f.path).get()).data().createdAt, 'legacy');
});
test('participants retain only their own reactions stars and receipt additions', async () => {
  const f = await fixture();
  allowed(await patch(f, author, {
    reactions: { [peer.uid]: 'like', [author.uid]: 'love' },
    starredBy: { [peer.uid]: true, [author.uid]: true }, readBy: [peer.uid, author.uid],
  }));
  allowed(await patch(f, peer, { reactions: { [author.uid]: 'love', [peer.uid]: 'laugh' } }));
  await unchangedAfterDenied(f, author, { reactions: { [author.uid]: 'love', [peer.uid]: 'forged' } });
});
test('peer author impersonation and peer text changes remain denied', async () => {
  const f = await fixture();
  await unchangedAfterDenied(f, peer, { authorId: peer.uid, text: 'Forged' });
  await unchangedAfterDenied(f, peer, { text: 'Forged' });
});
test('anonymous and unrelated users cannot update a message', async () => {
  const f = await fixture();
  await unchangedAfterDenied(f, null, { text: 'Forged' });
  await unchangedAfterDenied(f, outsider, { text: 'Forged' });
});
test('author delete remains allowed while peer delete is denied', async () => {
  const f = await fixture();
  denied(await request(`${base}/${f.path}`, peer, 'DELETE'));
  allowed(await request(`${base}/${f.path}`, author, 'DELETE'));
  assert.equal((await db.doc(f.path).get()).exists, false);
});
test('removed member and revoked sessions cannot use the author edit branch', async () => {
  const f = await fixture();
  await db.doc(f.chat).update({ memberIds: [peer.uid, outsider.uid] });
  await unchangedAfterDenied(f, author, { text: 'Not allowed' });
  await db.doc(f.chat).update({ memberIds: [author.uid, peer.uid] });
  const claims = JSON.parse(Buffer.from(author.token.split('.')[1], 'base64url').toString('utf8'));
  const ref = db.doc(`authRevocations/${author.uid}`);
  await ref.set({ revokedBefore: claims.auth_time });
  try { await unchangedAfterDenied(f, author, { text: 'Not allowed' }); }
  finally { await ref.delete(); }
});
test('a forbidden envelope edit aborts other writes in the same batch', async () => {
  const a = await fixture(), b = await fixture();
  const before = (await db.doc(a.path).get()).data();
  const writes = [
    { update: { name: `projects/${project}/databases/(default)/documents/${a.path}`, fields: fields({ text: 'valid' }) },
      updateMask: { fieldPaths: ['text'] }, currentDocument: { exists: true } },
    { update: { name: `projects/${project}/databases/(default)/documents/${b.path}`, fields: fields({ type: 'image' }) },
      updateMask: { fieldPaths: ['type'] }, currentDocument: { exists: true } },
  ];
  denied(await request(base + ':commit', author, 'POST', { writes }));
  assert.deepEqual((await db.doc(a.path).get()).data(), before);
});
