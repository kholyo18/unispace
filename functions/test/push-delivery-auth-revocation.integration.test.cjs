// Actual registration and delivery handlers; Auth/Firestore are loopback-only.
// Only FCM is captured. Explicit Auth metadata/error fault tests are named below.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { setTimeout: delay } = require('node:timers/promises');
if (process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    [process.env.GCLOUD_PROJECT, process.env.GOOGLE_CLOUD_PROJECT].some(p => p && p !== 'demo-unispace-security')) {
  throw Error('Credential-free fixed demo project required.');
}
const { db, auth, FieldValue, Timestamp, fixture, callableRequest, hash, close } = require('./helpers/notification-fixture.cjs');
const { createSyncPushDeviceHandler } = require('../security/push-preferences');
const { createPushNotificationHandler } = require('../security/push-notification');
after(close);
const preferences = { enabled: true, community: true, announcements: true, exams: true };
const sync = createSyncPushDeviceHandler({ db, auth, FieldValue });
async function setup() {
  const f = await fixture();
  const token = `auth-cutoff-fixture-${f.owner.uid}`, sessionId = 'auth-cutoff-session';
  const sessionRef = db.doc(`users/${f.owner.uid}/sessions/${sessionId}`);
  await sessionRef.set({ sessionId, isRevoked: false, createdAt: Timestamp.fromMillis(42000) });
  // No token-verification stub, retry, or suppressed fixture failure.
  assert.equal((await auth.verifyIdToken(f.owner.token, true)).uid, f.owner.uid);
  const registration = { token, sessionId, platform: 'android', preferences };
  assert.deepEqual(await sync(callableRequest(f.owner, registration)), { synced: true });
  const registrationRef = db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(token)}`);
  const bindingRef = db.doc(`pushTokenOwners/${hash(token)}`);
  const cutoffRef = db.doc(`authRevocations/${f.owner.uid}`);
  assert.equal((await cutoffRef.get()).exists, false);
  const calls = [];
  const messaging = { sendEachForMulticast: async payload => {
    calls.push(payload); return { responses: payload.tokens.map(() => ({ success: true })) };
  } };
  const event = { params: { userId: f.owner.uid, notifId: f.ref.id }, data: await f.ref.get() };
  const sender = (authClient = auth) => createPushNotificationHandler({ db, auth: authClient, messaging })(event);
  return { ...f, token, registration, registrationRef, bindingRef, sessionRef, cutoffRef, calls, messaging, sender };
}
async function snapshot(f) {
  return Promise.all([f.ref, f.registrationRef, f.bindingRef, f.sessionRef, f.cutoffRef]
    .map(async ref => { const s = await ref.get(); return { exists: s.exists, data: s.data() }; }));
}
async function deniedWithoutMutation(f, authClient) {
  const before = await snapshot(f), count = f.calls.length;
  await f.sender(authClient);
  assert.equal(f.calls.length, count, 'Revoked or unverifiable recipient registration must not reach FCM');
  assert.deepEqual(await snapshot(f), before, 'Denial must preserve notification, token, binding, and session');
}
async function revokeAndProve(user) {
  // Cross the token's authentication-second boundary once; this is not a retry.
  await delay(Math.max(0, (user.authTime + 1) * 1000 - Date.now() + 30));
  await auth.revokeRefreshTokens(user.uid);
  const account = await auth.getUser(user.uid);
  assert.ok(Date.parse(account.tokensValidAfterTime) > user.authTime * 1000,
    'The real Auth emulator must establish a strictly later cutoff');
  await assert.rejects(auth.verifyIdToken(user.token, true), { code: 'auth/id-token-revoked' });
  return account;
}
async function signInAgain(f) {
  const account = await auth.getUser(f.owner.uid);
  const result = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: account.email, password: 'Local-only-test-48!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(result.status, 200);
  const data = await result.json();
  const claims = await auth.verifyIdToken(data.idToken, true);
  assert.equal(claims.uid, f.owner.uid);
  assert.ok(claims.auth_time * 1000 >= Date.parse(account.tokensValidAfterTime));
  return { uid: claims.uid, token: data.idToken, authTime: claims.auth_time };
}
function recipientMetadata(f, value) {
  return { getUser: async uid => {
    const account = await auth.getUser(uid);
    return uid === f.owner.uid ? { ...account, tokensValidAfterTime: value } : account;
  } };
}

test('AUTHCUTOFF: Auth-only revocation denies an otherwise active registration without mutation', async () => {
  const f = await setup(); await f.sender(); assert.equal(f.calls.length, 1);
  await revokeAndProve(f.owner);
  assert.equal((await f.cutoffRef.get()).exists, false, 'No Firestore mirror may conceal the gap');
  assert.equal((await f.sessionRef.get()).data().isRevoked, false);
  await deniedWithoutMutation(f);
});
test('unrevoked recipient retains social and actorless system delivery and preferences', async () => {
  const f = await setup();
  await f.sender(); assert.deepEqual(f.calls[0].tokens, [f.token]);
  for (const type of ['announcement', 'exam_reminder']) {
    await f.ref.update({ type, actorId: FieldValue.delete() });
    await f.sender(); assert.equal(f.calls.at(-1).data.type, type);
    assert.equal(f.calls.at(-1).data.recipientId, f.owner.uid);
  }
  assert.equal(f.calls.length, 3);
  await sync(callableRequest(f.owner, { ...f.registration, preferences: { ...preferences, enabled: false } }));
  await deniedWithoutMutation(f);
});
test('AUTHCUTOFF: reauthentication and real resynchronization restore delivery on the same token', async () => {
  const f = await setup(); await revokeAndProve(f.owner);
  await deniedWithoutMutation(f);
  await assert.rejects(sync(callableRequest(f.owner, f.registration)), { code: 'unauthenticated' });
  const fresh = await signInAgain(f);
  assert.deepEqual(await sync(callableRequest(fresh, f.registration)), { synced: true });
  assert.equal((await f.bindingRef.get()).data().authTime, fresh.authTime);
  await f.sender(); assert.deepEqual(f.calls.map(p => p.tokens), [[f.token]]);
});
test('AUTHCUTOFF: a mixed batch sends only the freshly authenticated device', async () => {
  const f = await setup(); await revokeAndProve(f.owner);
  const fresh = await signInAgain(f), token = f.token + '-fresh', sessionId = 'fresh-session';
  await db.doc(`users/${f.owner.uid}/sessions/${sessionId}`).set({ sessionId, isRevoked: false, createdAt: Timestamp.now() });
  await sync(callableRequest(fresh, { ...f.registration, token, sessionId }));
  const before = await snapshot(f);
  await f.sender(); assert.deepEqual(f.calls.map(p => p.tokens), [[token]]);
  assert.deepEqual(await snapshot(f), before, 'Stale registration is not a dead FCM token');
});
test('AUTHCUTOFF: Auth-only revocation after 500 sends stops the next multicast batch', async () => {
  const f = await setup();
  const record = (await f.registrationRef.get()).data(), binding = (await f.bindingRef.get()).data();
  // Synthetic token fixtures only; no real devices and no FCM network transport.
  for (let offset = 0; offset < 500; offset += 240) {
    const batch = db.batch();
    for (let i = offset; i < Math.min(500, offset + 240); i++) {
      const token = `${f.token}-${i}`, id = hash(token);
      batch.set(db.doc(`users/${f.owner.uid}/fcm_tokens/${id}`), { ...record, token });
      batch.set(db.doc(`pushTokenOwners/${id}`), binding);
    }
    await batch.commit();
  }
  f.messaging.sendEachForMulticast = async payload => {
    f.calls.push(payload);
    if (f.calls.length === 1) await revokeAndProve(f.owner);
    return { responses: payload.tokens.map(() => ({ success: true })) };
  };
  await f.sender(); assert.deepEqual(f.calls.map(p => p.tokens.length), [500]);
  assert.equal((await f.cutoffRef.get()).exists, false);
});
test('AUTHCUTOFF: deleted and recreated Auth UID does not revive its old push binding', async () => {
  const f = await setup();
  await delay(Math.max(0, (f.owner.authTime + 1) * 1000 - Date.now() + 30));
  await auth.deleteUser(f.owner.uid);
  await auth.createUser({ uid: f.owner.uid, email: `recreated-${f.owner.uid}@example.test`, password: 'Local-only-test-48!' });
  const account = await auth.getUser(f.owner.uid);
  assert.ok(Date.parse(account.tokensValidAfterTime) > f.owner.authTime * 1000);
  await deniedWithoutMutation(f);
});
test('AUTHCUTOFF: explicit malformed Auth cutoff metadata fails closed (fault injection)', async () => {
  const f = await setup();
  for (const value of [null, '', 'not-a-date', 0, false, [], {}, '1969-12-31T23:59:59Z']) {
    await deniedWithoutMutation(f, recipientMetadata(f, value));
  }
});
test('absent optional Auth cutoff remains SDK-compatible (metadata fault injection)', async () => {
  const f = await setup(); await f.sender(recipientMetadata(f, undefined));
  assert.deepEqual(f.calls.map(p => p.tokens), [[f.token]]);
});
test('Auth lookup failure propagates without mutation and a later genuine lookup works', async () => {
  const f = await setup(), before = await snapshot(f);
  const error = Object.assign(Error('Synthetic Auth lookup outage'), { code: 'auth/internal-error' });
  await assert.rejects(f.sender({ getUser: async () => { throw error; } }), e => e === error);
  assert.equal(f.calls.length, 0); assert.deepEqual(await snapshot(f), before);
  await f.sender(); assert.deepEqual(f.calls.map(p => p.tokens), [[f.token]]);
});
test('a fresh Auth account does not override the stricter Firestore equality cutoff', async () => {
  const f = await setup();
  await f.cutoffRef.set({ revokedBefore: f.owner.authTime });
  await deniedWithoutMutation(f);
});
test('revoking only the actor authentication does not revoke the recipient device', async () => {
  const f = await setup(); await revokeAndProve(f.actor);
  await f.sender(); assert.deepEqual(f.calls.map(p => p.tokens), [[f.token]]);
});
