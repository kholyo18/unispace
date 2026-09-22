// All network/database access in these tests is restricted to local emulators.
const assert = require('node:assert/strict');
const { randomUUID, createHash } = require('node:crypto');
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const local = /^(127\.0\.0\.1|localhost):\d+$/;
if (!local.test(firestoreHost || '') || !local.test(authHost || '')) {
  throw Error('Local Auth and Firestore emulators are required; production is forbidden.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const project = 'demo-unispace-security';
const app = initializeApp({ projectId: project }, `notification-tests-${randomUUID()}`);
const db = getFirestore(app), auth = getAuth(app);
const base = `http://${firestoreHost}/v1/projects/${project}/databases/(default)/documents`;

async function user() {
  const result = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `notify-${randomUUID()}@example.test`, password: 'Local-only-test-48!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(result.status, 200);
  const data = await result.json();
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  return { uid: data.localId, token: data.idToken, authTime: claims.auth_time };
}
async function fixture() {
  const [owner, actor, outsider] = await Promise.all([user(), user(), user()]);
  await Promise.all([owner, actor, outsider].map((u, i) => db.doc(`users/${u.uid}`).set({
    displayName: ['Recipient', 'Verified actor', 'Outsider'][i], accountStatus: 'active',
    privacy: { privateAccount: false, showEmailOnProfile: false },
  })));
  const path = `users/${owner.uid}/notifications/event-${randomUUID()}`;
  const ref = db.doc(path);
  await ref.set({ type: 'follow', actorId: actor.uid, actorIds: [actor.uid],
    actorName: 'Verified actor', actorPhotoUrl: null, message: 'بدأ بمتابعتك',
    read: false, createdAt: Timestamp.now() });
  return { owner, actor, outsider, path, ref };
}
function callableRequest(actor, data) {
  return { auth: actor ? { uid: actor.uid } : null, data,
    rawRequest: { headers: actor ? { authorization: `Bearer ${actor.token}` } : {} } };
}
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (v instanceof Timestamp) return { timestampValue: v.toDate().toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  if (v && typeof v === 'object') return { mapValue: { fields: fields(v) } };
  throw Error('Unsupported fixture value');
}
const fields = data => Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)]));
async function http(suffix, actor, method = 'GET', body) {
  const response = await fetch(base + suffix, { method,
    headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }), signal: AbortSignal.timeout(15000) });
  const text = await response.text();
  return { status: response.status, data: text ? JSON.parse(text) : null };
}
const read = (path, actor) => http('/' + path, actor);
const erase = (path, actor) => http('/' + path, actor, 'DELETE');
function patch(path, actor, data, deletes = []) {
  const mask = [...Object.keys(data), ...deletes].map(k => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  return http('/' + path + (mask ? '?' + mask : ''), actor, 'PATCH', { fields: fields(data) });
}
function denied(result) {
  assert.equal(result.status, 403, JSON.stringify(result.data));
  assert.equal(result.data?.error?.status, 'PERMISSION_DENIED');
}
function allowed(result) { assert.ok(result.status >= 200 && result.status < 300, JSON.stringify(result)); }
const hash = token => createHash('sha256').update(token).digest('hex');
async function close() { await db.terminate(); await deleteApp(app); }
module.exports = { db, auth, FieldValue, Timestamp, project, fixture, callableRequest, value, fields,
  http, read, erase, patch, denied, allowed, hash, close };
