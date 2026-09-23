// Real local Auth/Firestore and production registration/dispatch handlers.
// FCM sends are captured. One fault-injection case overrides actor Auth lookup.
// All other Auth/Firestore operations are real emulator calls; no real devices.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
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
  const token = `delivery-gate-local-${f.owner.uid}`;
  const sessionId = 'gate-session';
  await db.doc(`users/${f.owner.uid}/sessions/${sessionId}`).set({
    sessionId, isRevoked: false, createdAt: Timestamp.fromMillis(42000),
  });
  const registration = { token, sessionId, platform: 'android', preferences };
  // Expose fixture-token verification failures instead of hiding their code in
  // the callable's deliberately generic unauthenticated error. No retry/bypass.
  assert.equal((await auth.verifyIdToken(f.owner.token, true)).uid, f.owner.uid);
  assert.deepEqual(await sync(callableRequest(f.owner, registration)), { synced: true });
  const calls = [];
  const messaging = { sendEachForMulticast: async payload => {
    calls.push(payload);
    return { responses: payload.tokens.map(() => ({ success: true })) };
  } };
  const event = { params: { userId: f.owner.uid, notifId: f.ref.id }, data: await f.ref.get() };
  const send = (authClient = auth) => createPushNotificationHandler({ db, auth: authClient, messaging })(event);
  return { ...f, token, registration, calls, messaging, send };
}
async function extraTokens(f, count) {
  const record = (await db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(f.token)}`).get()).data();
  const binding = (await db.doc(`pushTokenOwners/${hash(f.token)}`).get()).data();
  for (let offset = 0; offset < count; offset += 240) {
    const batch = db.batch();
    for (let i = offset; i < Math.min(count, offset + 240); i++) {
      const token = `${f.token}-extra-${i}`, id = hash(token);
      batch.set(db.doc(`users/${f.owner.uid}/fcm_tokens/${id}`), { ...record, token });
      batch.set(db.doc(`pushTokenOwners/${id}`), binding);
    }
    await batch.commit();
  }
}
test('active actor and canonical device still dispatch the expected payload', async () => {
  const f = await setup(); await f.send();
  assert.equal(f.calls.length, 1);
  assert.deepEqual(f.calls[0].tokens, [f.token]);
  assert.equal(f.calls[0].data.recipientId, f.owner.uid);
  assert.equal(f.calls[0].data.type, 'follow');
});
test('AUTHGATE: disabled Auth actor cannot dispatch while its Firestore profile remains active', async () => {
  const f = await setup(); await auth.updateUser(f.actor.uid, { disabled: true });
  assert.equal((await db.doc(`users/${f.actor.uid}`).get()).data().accountStatus, 'active');
  await f.send(); assert.equal(f.calls.length, 0);
});
test('AUTHGATE: deleted Auth actor cannot dispatch from a surviving profile', async () => {
  const f = await setup(); await auth.deleteUser(f.actor.uid);
  assert.equal((await db.doc(`users/${f.actor.uid}`).get()).exists, true);
  await f.send(); assert.equal(f.calls.length, 0);
});
test('AUTHGATE: actor Auth lookup failure propagates without sending or deleting tokens', async () => {
  const f = await setup(), failure = Object.assign(new Error('synthetic Auth outage'), { code: 'auth/internal-error' });
  const failingAuth = { getUser: uid => uid === f.actor.uid ? Promise.reject(failure) : auth.getUser(uid) };
  await assert.rejects(f.send(failingAuth), error => error === failure);
  assert.equal(f.calls.length, 0);
  assert.equal((await db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(f.token)}`).get()).exists, true);
});
for (const type of ['chat', 'message', 'chat_message', 'dm_message', 'unknown', '', null]) {
  test(`TYPEGATE: generic dispatcher rejects unsupported ${String(type)}`, async () => {
    const f = await setup();
    await f.ref.update({ type, message: 'Synthetic text that must not be sent' });
    await f.send(); assert.equal(f.calls.length, 0);
    assert.equal((await f.ref.get()).exists, true);
  });
}
test('TYPEGATE: a missing notification type is not implicitly allowed', async () => {
  const f = await setup(); await f.ref.update({ type: FieldValue.delete() });
  await f.send(); assert.equal(f.calls.length, 0);
});
test('system announcement without an actor retains its existing category behavior', async () => {
  const f = await setup(); await f.ref.update({ type: 'announcement', actorId: FieldValue.delete(), message: 'Local system notice' });
  await f.send(); assert.equal(f.calls.length, 1);
  await sync(callableRequest(f.owner, { ...f.registration, preferences: { ...preferences, announcements: false } }));
  await f.send(); assert.equal(f.calls.length, 1);
});
test('self actor reuses the recipient Auth check without blocking a valid notification', async () => {
  const f = await setup(); await f.ref.update({ actorId: f.owner.uid });
  const lookedUp = [], trackingAuth = { getUser: uid => { lookedUp.push(uid); return auth.getUser(uid); } };
  await f.send(trackingAuth); assert.equal(f.calls.length, 1);
  assert.deepEqual(lookedUp, [f.owner.uid]);
});
test('re-enabled actor can receive normal processing on a later attempt', async () => {
  const f = await setup(); await auth.updateUser(f.actor.uid, { disabled: true });
  await f.send();
  await auth.updateUser(f.actor.uid, { disabled: false });
  await f.send(); assert.equal(f.calls.length, 1);
});
test('AUTHGATE: actor eligibility is rechecked before the second token batch', async () => {
  const f = await setup(); await extraTokens(f, 500);
  f.messaging.sendEachForMulticast = async payload => {
    f.calls.push(payload);
    await auth.updateUser(f.actor.uid, { disabled: true });
    return { responses: payload.tokens.map(() => ({ success: true })) };
  };
  await f.send(); assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0].tokens.length, 500);
});
test('TYPEGATE: a type changed after batch one cannot fall through on batch two', async () => {
  const f = await setup(); await extraTokens(f, 500);
  f.messaging.sendEachForMulticast = async payload => {
    f.calls.push(payload); await f.ref.update({ type: 'chat_message' });
    return { responses: payload.tokens.map(() => ({ success: true })) };
  };
  await f.send(); assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0].tokens.length, 500);
});
test('501 unchanged valid devices retain two bounded dispatch batches', async () => {
  const f = await setup(); await extraTokens(f, 500); await f.send();
  assert.deepEqual(f.calls.map(p => p.tokens.length), [500, 1]);
  assert.equal(new Set(f.calls.flatMap(p => p.tokens)).size, 501);
});
