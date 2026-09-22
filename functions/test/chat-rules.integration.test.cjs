// Integration tests: Admin SDK is used ONLY to seed local fixtures.
// Every access-control assertion uses client REST requests and Auth emulator ID tokens.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');

const PROJECT = 'demo-unispace-security';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const localHost = /^(127\.0\.0\.1|localhost):\d+$/;
if (!localHost.test(firestoreHost || '') || !localHost.test(authHost || '')) {
  throw new Error('Local Firestore AND Auth emulators are required; production access is forbidden.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const app = initializeApp({ projectId: PROJECT }, `chat-rules-${randomUUID()}`);
const db = getFirestore(app);
const documentBase = `http://${firestoreHost}/v1/projects/${PROJECT}/databases/(default)/documents`;
let owner, peer, outsider;

async function makeUser() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `audit-${randomUUID()}@example.test`,
      password: 'Emulator-only-password-47!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  const value = await response.json();
  assert.equal(response.ok, true, `Auth emulator signup failed: ${value.error?.message || response.status}`);
  assert.equal(typeof value.localId, 'string');
  assert.equal(typeof value.idToken, 'string');
  const claims = JSON.parse(Buffer.from(value.idToken.split('.')[1], 'base64url').toString('utf8'));
  assert.ok(Number.isInteger(claims.auth_time));
  return { uid: value.localId, token: value.idToken, authTime: claims.auth_time };
}

before(async () => { [owner, peer, outsider] = await Promise.all([makeUser(), makeUser(), makeUser()]); });
after(async () => { await db.terminate(); await deleteApp(app); });

function restValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (Array.isArray(value)) return { arrayValue: { values: value.map(restValue) } };
  if (value && typeof value === 'object') return { mapValue: { fields: restFields(value) } };
  throw new TypeError('Unsupported test fixture value.');
}
function restFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, restValue(value)]));
}
async function http(url, actor, method = 'GET', body) {
  const headers = { 'Content-Type': 'application/json' };
  if (actor) headers.Authorization = `Bearer ${actor.token}`;
  const response = await fetch(url, { method, headers,
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    signal: AbortSignal.timeout(15000) });
  const text = await response.text();
  return { status: response.status, data: text ? JSON.parse(text) : null };
}
async function client(path, actor, method = 'GET', data, deleteFields = []) {
  const suffix = path.split('/').map(encodeURIComponent).join('/');
  let url = `${documentBase}/${suffix}`;
  let body;
  if (method === 'PATCH') {
    const mask = [...Object.keys(data || {}), ...deleteFields];
    if (mask.length) url += '?' + mask.map(key => `updateMask.fieldPaths=${encodeURIComponent(key)}`).join('&');
    body = { fields: restFields(data || {}) };
  }
  return http(url, actor, method, body);
}
function allowed(result) {
  assert.ok(result.status >= 200 && result.status < 300,
    `Expected success, got ${result.status}: ${JSON.stringify(result.data?.error || {})}`);
}
function denied(result) {
  assert.equal(result.status, 403, `Expected permission denial, got ${result.status}`);
  assert.equal(result.data?.error?.status, 'PERMISSION_DENIED');
}
async function fixture() {
  const chat = `chats/audit-${randomUUID()}`;
  const message = `${chat}/messages/original`;
  await db.doc(chat).set({ memberIds: [owner.uid, peer.uid] });
  await db.doc(message).set({ authorId: owner.uid, text: 'original', readBy: [], reactions: {} });
  return { chat, message };
}
async function withCutoff(value, callback) {
  const ref = db.doc(`authRevocations/${owner.uid}`);
  await ref.set({ revokedBefore: value });
  try { await callback(); } finally { await ref.delete(); }
}

test('anonymous clients cannot read a chat or its messages', async () => {
  const f = await fixture();
  denied(await client(f.chat, null));
  denied(await client(f.message, null));
});

test('both current members can read their chat and message', async () => {
  const f = await fixture();
  for (const actor of [owner, peer]) {
    allowed(await client(f.chat, actor));
    allowed(await client(f.message, actor));
  }
});

test('outsiders cannot read chat documents or messages', async () => {
  const f = await fixture();
  denied(await client(f.chat, outsider));
  denied(await client(f.message, outsider));
});

test('a current member can create a message with their own author ID', async () => {
  const f = await fixture();
  allowed(await client(`${f.chat}/messages/peer-message`, peer, 'PATCH',
    { authorId: peer.uid, text: 'hello', readBy: [], reactions: {} }));
});

test('an outsider cannot create a message in another chat', async () => {
  const f = await fixture();
  denied(await client(`${f.chat}/messages/outsider`, outsider, 'PATCH',
    { authorId: outsider.uid, text: 'not allowed' }));
});

test('a member cannot forge another sender when creating a message', async () => {
  const f = await fixture();
  denied(await client(`${f.chat}/messages/forged`, peer, 'PATCH',
    { authorId: owner.uid, text: 'not allowed' }));
});

test('the current author can edit text while preserving authorship', async () => {
  const f = await fixture();
  allowed(await client(f.message, owner, 'PATCH', { text: 'edited' }));
  const stored = (await db.doc(f.message).get()).data();
  assert.equal(stored.text, 'edited');
  assert.equal(stored.authorId, owner.uid);
});

test('REGRESSION: even the original author cannot reassign authorship', async () => {
  const f = await fixture();
  denied(await client(f.message, owner, 'PATCH', { authorId: peer.uid }));
  assert.equal((await db.doc(f.message).get()).data().authorId, owner.uid);
});

test('REGRESSION: the author cannot delete the authorId field', async () => {
  const f = await fixture();
  denied(await client(f.message, owner, 'PATCH', {}, ['authorId']));
});

test('the peer cannot edit another author\'s message text', async () => {
  const f = await fixture();
  denied(await client(f.message, peer, 'PATCH', { text: 'not allowed' }));
});

test('the peer cannot reassign authorship', async () => {
  const f = await fixture();
  denied(await client(f.message, peer, 'PATCH', { authorId: peer.uid }));
});

test('legitimate read receipt updates remain allowed for a member', async () => {
  const f = await fixture();
  allowed(await client(f.message, peer, 'PATCH', { readBy: [peer.uid] }));
});

test('legitimate reaction updates remain allowed for a member', async () => {
  const f = await fixture();
  allowed(await client(f.message, peer, 'PATCH', { reactions: { [peer.uid]: 'like' } }));
});

test('an outsider cannot mutate read receipts', async () => {
  const f = await fixture();
  denied(await client(f.message, outsider, 'PATCH', { readBy: [outsider.uid] }));
});

test('the current author can delete their own message', async () => {
  const f = await fixture();
  allowed(await client(f.message, owner, 'DELETE'));
  assert.equal((await db.doc(f.message).get()).exists, false);
});

test('the peer cannot delete another author\'s message', async () => {
  const f = await fixture();
  denied(await client(f.message, peer, 'DELETE'));
});

test('REGRESSION: an author removed from the chat cannot read, edit or delete', async () => {
  const f = await fixture();
  await db.doc(f.chat).update({ memberIds: [peer.uid, outsider.uid] });
  denied(await client(f.message, owner));
  denied(await client(f.message, owner, 'PATCH', { text: 'not allowed' }));
  denied(await client(f.message, owner, 'DELETE'));
});

test('a member cannot replace chat membership through the client', async () => {
  const f = await fixture();
  denied(await client(f.chat, owner, 'PATCH', { memberIds: [owner.uid, outsider.uid] }));
});

test('a message without an existing member-owned parent chat is denied', async () => {
  denied(await client(`chats/missing-${randomUUID()}/messages/new`, owner, 'PATCH',
    { authorId: owner.uid, text: 'not allowed' }));
});

test('REGRESSION: equal auth_time cutoff blocks chat access and message mutations', async () => {
  const f = await fixture();
  await withCutoff(owner.authTime, async () => {
    denied(await client(f.chat, owner));
    denied(await client(f.message, owner));
    denied(await client(f.chat, owner, 'PATCH', { lastMessage: 'not allowed' }));
    denied(await client(f.message, owner, 'PATCH', { text: 'not allowed' }));
    denied(await client(f.message, owner, 'DELETE'));
    denied(await client(`${f.chat}/messages/revoked`, owner, 'PATCH',
      { authorId: owner.uid, text: 'not allowed' }));
    denied(await client(`chats/revoked-${randomUUID()}`, owner, 'PATCH',
      { memberIds: [owner.uid, peer.uid] }));
  });
});

test('a session newer than the cutoff remains usable', async () => {
  const f = await fixture();
  await withCutoff(owner.authTime - 1, async () => {
    allowed(await client(f.chat, owner));
    allowed(await client(f.message, owner, 'PATCH', { text: 'allowed' }));
  });
});

test('a cutoff later than auth_time denies access', async () => {
  const f = await fixture();
  await withCutoff(owner.authTime + 1, async () => { denied(await client(f.message, owner)); });
});

test('a malformed server cutoff fails closed', async () => {
  const f = await fixture();
  await withCutoff('invalid', async () => { denied(await client(f.message, owner)); });
});

test('member-filtered chat queries remain allowed', async () => {
  await fixture();
  const result = await http(`${documentBase}:runQuery`, owner, 'POST', { structuredQuery: {
    from: [{ collectionId: 'chats' }], where: { fieldFilter: {
      field: { fieldPath: 'memberIds' }, op: 'ARRAY_CONTAINS', value: { stringValue: owner.uid },
    } }, limit: 10,
  } });
  allowed(result);
  assert.ok(result.data.some(row => row.document), 'Expected at least one member-owned chat');
});

test('unfiltered chat collection queries are denied', async () => {
  denied(await http(`${documentBase}:runQuery`, owner, 'POST',
    { structuredQuery: { from: [{ collectionId: 'chats' }], limit: 10 } }));
});
