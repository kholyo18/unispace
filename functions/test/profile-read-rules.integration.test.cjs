// Admin SDK seeds fixtures and calls the production handler. All raw-access
// assertions use client REST with real tokens issued by the local Auth emulator.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const host = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const local = /^(127\.0\.0\.1|localhost):\d+$/;
if (!local.test(host || '') || !local.test(authHost || '')) {
  throw Error('Local Auth and Firestore emulators required. Production is forbidden.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { createPublicProfileHandler } = require('../security/public-profile');
const project = 'demo-unispace-security';
const app = initializeApp({ projectId: project }, `profile-read-${randomUUID()}`);
const db = getFirestore(app), auth = getAuth(app);
const handler = createPublicProfileHandler({ db, auth });
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
let owner, viewer;
async function makeUser() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `profile-${randomUUID()}@example.test`, password: 'Local-only-fixture-49!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(response.status, 200);
  const data = await response.json();
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  return { uid: data.localId, token: data.idToken, authTime: claims.auth_time };
}
before(async () => { [owner, viewer] = await Promise.all([makeUser(), makeUser()]); });
after(async () => { await db.terminate(); await deleteApp(app); });
async function request(path, actor, method = 'GET', body) {
  const response = await fetch(`${base}${path}`, {
    method, headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }), signal: AbortSignal.timeout(15000),
  });
  const text = await response.text();
  return { status: response.status, data: text ? JSON.parse(text) : null };
}
function denied(result) {
  assert.equal(result.status, 403, JSON.stringify(result.data));
  assert.equal(result.data?.error?.status, 'PERMISSION_DENIED');
}
async function fixture(privateAccount = false) {
  // Each test gets fresh documents and no residual relationship or cutoff.
  await db.recursiveDelete(db.doc(`users/${owner.uid}`));
  await db.recursiveDelete(db.doc(`users/${viewer.uid}`));
  for (const user of [owner, viewer]) await db.doc(`authRevocations/${user.uid}`).delete();
  await db.doc(`users/${owner.uid}`).set({ displayName: 'Profile owner', email: 'private@example.test',
    phone: 'private phone', birthDate: 'private date', security: { internal: 'private' },
    coverImageUrl: 'cover', profileImageUrl: 'avatar',
    privacy: { privateAccount, showEmailOnProfile: false } });
  await db.doc(`users/${viewer.uid}`).set({ displayName: 'Viewer' });
}
function call(actor = viewer) {
  return handler({ auth: { uid: actor.uid }, data: { userId: owner.uid },
    rawRequest: { headers: { authorization: `Bearer ${actor.token}` } } });
}
function userQuery(where) {
  return { structuredQuery: { from: [{ collectionId: 'users' }], ...(where ? { where } : {}), limit: 10 } };
}

test('anonymous raw-profile access is denied', async () => {
  await fixture(); denied(await request(`/users/${owner.uid}`, null));
});
test('owner reads their whole profile for settings and account bootstrap', async () => {
  await fixture(); const result = await request(`/users/${owner.uid}`, owner);
  assert.equal(result.status, 200); assert.equal(result.data.fields.email.stringValue, 'private@example.test');
  assert.ok(result.data.fields.security);
});
test('RAWREGRESSION: a stranger cannot read a public raw profile', async () => {
  await fixture(); denied(await request(`/users/${owner.uid}`, viewer));
});
test('RAWREGRESSION: accepted followers cannot read private raw profiles', async () => {
  await fixture(true); await db.doc(`users/${owner.uid}/followers/${viewer.uid}`).set({ uid: viewer.uid });
  denied(await request(`/users/${owner.uid}`, viewer));
});
test('RAWREGRESSION: a blocked user cannot read the raw profile', async () => {
  await fixture(); await db.doc(`users/${owner.uid}/blocked_accounts/${viewer.uid}`).set({ targetId: viewer.uid });
  denied(await request(`/users/${owner.uid}`, viewer));
});
test('RAWREGRESSION: foreign missing documents do not allow existence probes', async () => {
  await fixture(); denied(await request(`/users/missing-${randomUUID()}`, viewer));
});
test('RAWREGRESSION: unfiltered user directory enumeration is denied', async () => {
  await fixture(); denied(await request(':runQuery', viewer, 'POST', userQuery()));
});
test('RAWREGRESSION: email name and document-ID queries cannot expose raw profiles', async () => {
  await fixture();
  const filters = [
    { field: { fieldPath: 'email' }, op: 'EQUAL', value: { stringValue: 'private@example.test' } },
    { field: { fieldPath: 'displayName' }, op: 'EQUAL', value: { stringValue: 'Profile owner' } },
    { field: { fieldPath: '__name__' }, op: 'IN', value: { arrayValue: { values: [
      { referenceValue: `projects/${project}/databases/(default)/documents/users/${owner.uid}` },
    ] } } },
  ];
  for (const fieldFilter of filters) denied(await request(':runQuery', viewer, 'POST', userQuery({ fieldFilter })));
});
test('RAWREGRESSION: user aggregation cannot bypass directory restrictions', async () => {
  await fixture();
  denied(await request(':runAggregationQuery', viewer, 'POST', { structuredAggregationQuery: {
    structuredQuery: { from: [{ collectionId: 'users' }] }, aggregations: [{ alias: 'total', count: {} }],
  } }));
});
test('an owner can detect their missing profile for legitimate bootstrap', async () => {
  await fixture(); await db.doc(`users/${owner.uid}`).delete();
  assert.equal((await request(`/users/${owner.uid}`, owner)).status, 404);
});
test('revoked owners cannot read their own raw profile or the public handler', async () => {
  await fixture(); await db.doc(`authRevocations/${owner.uid}`).set({ revokedBefore: owner.authTime });
  denied(await request(`/users/${owner.uid}`, owner));
  await assert.rejects(call(owner), { code: 'unauthenticated' });
});
test('newer owner authentication remains valid', async () => {
  await fixture(); await db.doc(`authRevocations/${owner.uid}`).set({ revokedBefore: owner.authTime - 1 });
  assert.equal((await request(`/users/${owner.uid}`, owner)).status, 200);
});
test('owner profile edits remain allowed and preserve protected data', async () => {
  await fixture();
  assert.equal((await request(`/users/${owner.uid}?updateMask.fieldPaths=displayName`, owner, 'PATCH',
    { fields: { displayName: { stringValue: 'Updated owner' } } })).status, 200);
  const data = (await db.doc(`users/${owner.uid}`).get()).data();
  assert.equal(data.displayName, 'Updated owner'); assert.equal(data.email, 'private@example.test');
});
test('foreign profile mutation and client profile deletion remain denied', async () => {
  await fixture(); denied(await request(`/users/${owner.uid}`, viewer, 'PATCH',
    { fields: { displayName: { stringValue: 'Forged' } } }));
  denied(await request(`/users/${owner.uid}`, viewer, 'DELETE'));
  denied(await request(`/users/${owner.uid}`, owner, 'DELETE'));
});
test('authorized handler still returns public identity while direct reads are denied', async () => {
  await fixture(); denied(await request(`/users/${owner.uid}`, viewer));
  const profile = await call();
  assert.equal(profile.displayName, 'Profile owner'); assert.equal(profile.canViewContent, true);
  for (const key of ['email', 'phone', 'birthDate', 'security']) assert.equal(Object.hasOwn(profile, key), false);
});
test('private visitors get only basic identity, not the private cover or email', async () => {
  await fixture(true); const profile = await call();
  assert.equal(profile.canViewContent, false); assert.equal(profile.profileImageUrl, 'avatar');
  for (const key of ['coverImageUrl', 'email', 'security']) assert.equal(Object.hasOwn(profile, key), false);
});
test('accepted followers receive only owner-approved projected fields', async () => {
  await fixture(true); await db.doc(`users/${owner.uid}/followers/${viewer.uid}`).set({ uid: viewer.uid });
  await db.doc(`users/${owner.uid}`).update({ 'privacy.showEmailOnProfile': true });
  const profile = await call(); assert.equal(profile.canViewContent, true);
  assert.equal(profile.email, 'private@example.test'); assert.equal(Object.hasOwn(profile, 'security'), false);
  denied(await request(`/users/${owner.uid}`, viewer));
});
test('blocking in either direction denies the projected read', async () => {
  await fixture();
  for (const [a, b] of [[owner.uid, viewer.uid], [viewer.uid, owner.uid]]) {
    const ref = db.doc(`users/${a}/blocked_accounts/${b}`); await ref.set({});
    await assert.rejects(call(), { code: 'not-found' }); await ref.delete();
  }
});
test('malformed server cutoffs fail closed in direct and projected reads', async () => {
  await fixture();
  for (const revokedBefore of ['invalid', null, true]) {
    await db.doc(`authRevocations/${viewer.uid}`).set({ revokedBefore });
    denied(await request(`/users/${viewer.uid}`, viewer));
    await assert.rejects(call(), { code: 'unauthenticated' });
  }
});
test('disabling the target Auth account makes the projected profile unavailable', async () => {
  await fixture(); await auth.updateUser(owner.uid, { disabled: true });
  try { await assert.rejects(call(), { code: 'not-found' }); }
  finally { await auth.updateUser(owner.uid, { disabled: false }); }
});
