// Only loopback Auth/Firestore emulators are allowed. Admin SDK seeds fixtures;
// all Rules assertions use client REST with real Auth-emulator ID tokens.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const project = 'demo-unispace-security';
const host = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const local = /^(127\.0\.0\.1|localhost):\d+$/;
if (!local.test(host || '') || !local.test(authHost || '')) {
  throw new Error('Local Auth AND Firestore emulators required; production is forbidden.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { createFollowHandler } = require('../security/follow-relationships');
const { createPublicProfileHandler } = require('../security/public-profile');
const { createFollowListHandler } = require('../security/follow-lists');
const app = initializeApp({ projectId: project }, `follow-rules-${randomUUID()}`);
const db = getFirestore(app), auth = getAuth(app);
const manage = createFollowHandler({ auth, db, FieldValue });
const profile = createPublicProfileHandler({ auth, db });
const readList = createFollowListHandler({ auth, db });
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
after(async () => { await db.terminate(); await deleteApp(app); });

async function user() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `${randomUUID()}@example.test`,
      password: 'Emulator-only-password-47!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  assert.equal(response.status, 200, 'Auth emulator must be ready');
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url').toString());
  assert.ok(Number.isInteger(claims.auth_time));
  return { uid: data.localId, token: data.idToken, authTime: claims.auth_time };
}
const request = (actor, data) => ({ auth: { uid: actor.uid }, data,
  rawRequest: { headers: { authorization: `Bearer ${actor.token}` } } });
const call = (actor, action, userId) => manage(request(actor, { action, userId }));
async function fixture(privateAccount = true) {
  const [owner, from, stranger] = await Promise.all([user(), user(), user()]);
  for (const actor of [owner, from, stranger]) {
    await db.doc(`users/${actor.uid}`).set({ displayName: actor.uid, accountStatus: 'active',
      email: 'opted-in@example.test', security: { backupCodes: ['not-public'] },
      privacy: { privateAccount, showEmailOnProfile: true, whoCanMessage: 'mutual' } });
  }
  const relation = collection => `users/${owner.uid}/${collection}/${from.uid}`;
  return { owner, from, stranger, relation };
}
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  return { mapValue: { fields: fields(v) } };
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])); }
async function client(path, actor, method = 'GET', data) {
  const headers = { 'Content-Type': 'application/json' };
  if (actor) headers.Authorization = `Bearer ${actor.token}`;
  const response = await fetch(`${base}/${path.split('/').map(encodeURIComponent).join('/')}`, {
    method, headers, ...(data === undefined ? {} : { body: JSON.stringify({ fields: fields(data) }) }),
    signal: AbortSignal.timeout(15000),
  });
  const text = await response.text();
  return { status: response.status, data: text ? JSON.parse(text) : null };
}
function denied(result) {
  assert.equal(result.status, 403, JSON.stringify(result.data?.error || {}));
  assert.equal(result.data.error.status, 'PERMISSION_DENIED');
}
function allowed(result) { assert.equal(result.status, 200, JSON.stringify(result.data?.error || {})); }
const exists = async path => (await db.doc(path).get()).exists;
const collections = ['followers', 'following', 'follow_requests', 'blocked_accounts', 'blocked_by'];

// These seven cases also run against the immutable pre-fix Rules in CI.
// Every one must fail there for its specified authorization/compatibility reason.
test('REGRESSION: direct follower injection is denied', async () => {
  const f = await fixture();
  denied(await client(f.relation('followers'), f.from, 'PATCH', { uid: f.from.uid }));
});
test('REGRESSION: unrelated users cannot read relationship metadata', async () => {
  const f = await fixture(); await db.doc(f.relation('followers')).set({ uid: f.from.uid });
  denied(await client(f.relation('followers'), f.stranger));
});
test('REGRESSION: revoked sessions cannot inspect relationships', async () => {
  const f = await fixture(); await db.doc(f.relation('followers')).set({ uid: f.from.uid });
  await db.doc(`authRevocations/${f.from.uid}`).set({ revokedBefore: f.from.authTime });
  denied(await client(f.relation('followers'), f.from));
});
test('REGRESSION: direct block deletion is denied', async () => {
  const f = await fixture(); await db.doc(f.relation('blocked_accounts')).set({ targetId: f.from.uid });
  denied(await client(f.relation('blocked_accounts'), f.owner, 'DELETE'));
});
test('REGRESSION: owner can read legacy block records', async () => {
  const f = await fixture(); await db.doc(f.relation('blocked_users')).set({ identifier: f.from.uid });
  allowed(await client(f.relation('blocked_users'), f.owner));
});
test('REGRESSION: direct relationship deletion is denied', async () => {
  const f = await fixture(); await db.doc(f.relation('followers')).set({ uid: f.from.uid });
  denied(await client(f.relation('followers'), f.from, 'DELETE'));
});
test('REGRESSION: pending requests must use the callable', async () => {
  const f = await fixture();
  denied(await client(f.relation('follow_requests'), f.from, 'PATCH', { uid: f.from.uid, status: 'pending' }));
});

for (const collection of collections) {
  test(`${collection}: neither participant can create, update or delete directly`, async () => {
    const f = await fixture(), path = f.relation(collection);
    for (const actor of [f.owner, f.from]) {
      denied(await client(path, actor, 'PATCH', { uid: f.from.uid }));
    }
    await db.doc(path).set({ uid: f.from.uid, status: 'pending' });
    for (const actor of [f.owner, f.from]) {
      denied(await client(path, actor, 'PATCH', { uid: f.from.uid, status: 'accepted' }));
      denied(await client(path, actor, 'DELETE'));
    }
    assert.equal((await db.doc(path).get()).data().status, 'pending');
  });
  test(`${collection}: participant get and owner list work without public enumeration`, async () => {
    const f = await fixture(), path = f.relation(collection);
    for (const actor of [f.owner, f.from]) assert.equal((await client(path, actor)).status, 404);
    await db.doc(path).set({ uid: f.from.uid });
    for (const actor of [f.owner, f.from]) allowed(await client(path, actor));
    denied(await client(path, f.stranger));
    denied(await client(path, null));
    const collectionPath = `users/${f.owner.uid}/${collection}`;
    allowed(await client(collectionPath, f.owner));
    denied(await client(collectionPath, f.from));
    denied(await client(collectionPath, f.stranger));
  });
}

test('legacy blocks are owner-readable but never client-writable', async () => {
  const f = await fixture(), path = f.relation('blocked_users');
  await db.doc(path).set({ identifier: f.from.uid });
  allowed(await client(`users/${f.owner.uid}/blocked_users`, f.owner));
  for (const actor of [f.from, f.stranger, null]) denied(await client(path, actor));
  for (const actor of [f.owner, f.from]) {
    denied(await client(path, actor, 'PATCH', { identifier: 'forged' }));
    denied(await client(path, actor, 'DELETE'));
  }
});

test('anonymous users cannot create accepted relationships', async () => {
  const f = await fixture();
  denied(await client(f.relation('followers'), null, 'PATCH', { uid: f.from.uid }));
});

test('private follow remains pending until the actual owner accepts it', async () => {
  const f = await fixture();
  assert.deepEqual(await call(f.from, 'follow', f.owner.uid), { state: 'pending' });
  assert.equal(await exists(f.relation('followers')), false);
  const before = await profile(request(f.from, { userId: f.owner.uid }));
  assert.equal(before.canViewContent, false); assert.ok(!('email' in before));
  await assert.rejects(call(f.from, 'accept', f.owner.uid), { code: 'failed-precondition' });
  await assert.rejects(call(f.stranger, 'accept', f.from.uid), { code: 'failed-precondition' });
  assert.deepEqual(await call(f.owner, 'accept', f.from.uid), { state: 'following' });
  const after = await profile(request(f.from, { userId: f.owner.uid }));
  assert.equal(after.canViewContent, true); assert.equal(after.email, 'opted-in@example.test');
  assert.ok(!('security' in after));
  assert.equal(await exists(`users/${f.from.uid}/following/${f.owner.uid}`), true);
});

test('forged follower proof cannot unlock the authorized public-profile endpoint', async () => {
  const f = await fixture();
  denied(await client(f.relation('followers'), f.from, 'PATCH', { uid: f.from.uid }));
  denied(await client(`users/${f.from.uid}/following/${f.owner.uid}`, f.from, 'PATCH', { uid: f.owner.uid }));
  assert.equal((await profile(request(f.from, { userId: f.owner.uid }))).canViewContent, false);
});

test('public follow and retry remain idempotent with real emulator authentication', async () => {
  const f = await fixture(false);
  assert.deepEqual(await call(f.from, 'follow', f.owner.uid), { state: 'following' });
  assert.deepEqual(await call(f.from, 'follow', f.owner.uid), { state: 'following' });
  assert.equal((await db.collection(`users/${f.owner.uid}/notifications`).get()).size, 1);
  await call(f.from, 'unfollow', f.owner.uid);
  assert.equal(await exists(f.relation('followers')), false);
  assert.equal(await exists(`users/${f.from.uid}/following/${f.owner.uid}`), false);
});

test('cancel and reject never leave an approvable private request', async () => {
  const f = await fixture();
  await call(f.from, 'follow', f.owner.uid); await call(f.from, 'cancel', f.owner.uid);
  await assert.rejects(call(f.owner, 'accept', f.from.uid), { code: 'failed-precondition' });
  await call(f.from, 'follow', f.owner.uid); await call(f.owner, 'reject', f.from.uid);
  await assert.rejects(call(f.owner, 'accept', f.from.uid), { code: 'failed-precondition' });
});

test('blocking removes both relationships and pending requests atomically', async () => {
  const f = await fixture(false);
  await call(f.from, 'follow', f.owner.uid); await call(f.owner, 'follow', f.from.uid);
  await db.doc(f.relation('follow_requests')).set({ uid: f.from.uid, status: 'pending' });
  await db.doc(`users/${f.from.uid}/follow_requests/${f.owner.uid}`).set({ uid: f.owner.uid, status: 'pending' });
  await call(f.owner, 'block', f.from.uid);
  for (const kind of ['followers', 'following', 'follow_requests']) {
    assert.equal(await exists(f.relation(kind)), false);
    assert.equal(await exists(`users/${f.from.uid}/${kind}/${f.owner.uid}`), false);
  }
  await assert.rejects(call(f.from, 'follow', f.owner.uid), { code: 'permission-denied' });
  await assert.rejects(profile(request(f.from, { userId: f.owner.uid })), { code: 'not-found' });
});

test('unblock clears the caller-owned modern, mirror and legacy records, without refollowing', async () => {
  const f = await fixture();
  await call(f.owner, 'block', f.from.uid);
  await db.doc(f.relation('blocked_users')).set({ identifier: f.from.uid });
  await call(f.owner, 'unblock', f.from.uid);
  assert.equal(await exists(f.relation('blocked_accounts')), false);
  assert.equal(await exists(f.relation('blocked_users')), false);
  assert.equal(await exists(`users/${f.from.uid}/blocked_by/${f.owner.uid}`), false);
  assert.equal(await exists(f.relation('followers')), false);
  assert.equal((await profile(request(f.from, { userId: f.owner.uid }))).canViewContent, false);
});

test('unilateral unblock cannot remove the other person\'s modern or legacy block', async () => {
  const f = await fixture(false);
  await call(f.owner, 'block', f.from.uid); await call(f.from, 'block', f.owner.uid);
  await db.doc(`users/${f.from.uid}/blocked_users/${f.owner.uid}`).set({ identifier: f.owner.uid });
  await call(f.owner, 'unblock', f.from.uid);
  assert.equal(await exists(`users/${f.from.uid}/blocked_accounts/${f.owner.uid}`), true);
  assert.equal(await exists(`users/${f.from.uid}/blocked_users/${f.owner.uid}`), true);
  assert.equal(await exists(f.relation('blocked_by')), true);
  await assert.rejects(call(f.owner, 'follow', f.from.uid), { code: 'permission-denied' });
});

test('revocation covers all relationship reads, lists and callable changes', async () => {
  const f = await fixture();
  await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore: f.owner.authTime });
  for (const kind of [...collections, 'blocked_users']) {
    await db.doc(f.relation(kind)).set({ uid: f.from.uid });
    denied(await client(f.relation(kind), f.owner));
    denied(await client(`users/${f.owner.uid}/${kind}`, f.owner));
  }
  for (const action of ['follow', 'unfollow', 'cancel', 'accept', 'reject', 'block', 'unblock']) {
    await assert.rejects(call(f.owner, action, f.from.uid), { code: 'unauthenticated' });
  }
});

test('a malformed cutoff fails closed in Rules and in the callable', async () => {
  const f = await fixture();
  await db.doc(`authRevocations/${f.owner.uid}`).set({ revokedBefore: 'invalid' });
  denied(await client(`users/${f.owner.uid}/followers`, f.owner));
  await assert.rejects(call(f.owner, 'block', f.from.uid), { code: 'unauthenticated' });
  assert.equal(await exists(f.relation('blocked_accounts')), false);
});

test('a session newer than its cutoff can still follow', async () => {
  const f = await fixture(false);
  await db.doc(`authRevocations/${f.from.uid}`).set({ revokedBefore: f.from.authTime - 1 });
  assert.deepEqual(await call(f.from, 'follow', f.owner.uid), { state: 'following' });
  allowed(await client(f.relation('followers'), f.from));
});

test('forged request identity, self-follow and approval parameters are rejected', async () => {
  const f = await fixture(false);
  const forged = request(f.from, { action: 'follow', userId: f.owner.uid });
  forged.auth.uid = f.stranger.uid;
  await assert.rejects(manage(forged), { code: 'unauthenticated' });
  await assert.rejects(call(f.from, 'follow', f.from.uid), { code: 'invalid-argument' });
  await assert.rejects(manage(request(f.from, { action: 'follow', userId: f.owner.uid, approved: true })),
    { code: 'invalid-argument' });
});

test('authorized list browsing works through the callable while raw lists stay private', async () => {
  const f = await fixture(false);
  await call(f.from, 'follow', f.owner.uid);
  denied(await client(`users/${f.owner.uid}/followers`, f.stranger));
  const data = await readList(request(f.stranger, { userId: f.owner.uid, kind: 'followers', offset: 0 }));
  assert.equal(data.items.length, 1); assert.equal(data.items[0].id, f.from.uid);
  await db.doc(`users/${f.owner.uid}`).update({ 'privacy.followersVisibility': 'none' });
  await assert.rejects(readList(request(f.stranger, { userId: f.owner.uid, kind: 'followers', offset: 0 })),
    { code: 'permission-denied' });
});

test('the authorized profile response carries messaging policy without internal data', async () => {
  const f = await fixture(false);
  const data = await profile(request(f.from, { userId: f.owner.uid }));
  assert.equal(data.privacy.whoCanMessage, 'mutual'); assert.ok(!('security' in data));
});
