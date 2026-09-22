const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { db, auth, FieldValue, Timestamp, fixture, callableRequest, hash, close } = require('./helpers/notification-fixture.cjs');
const { createSyncPushDeviceHandler } = require('../security/push-preferences');
const { createPushNotificationHandler } = require('../security/push-notification');
after(close);
const sync = createSyncPushDeviceHandler({ auth, db, FieldValue });
const detach = createSyncPushDeviceHandler({ auth, db, FieldValue }, true);
const preferences = { enabled: true, community: true, announcements: true, exams: true };
async function setup({ register = true } = {}) {
  const f = await fixture();
  const token = `emulator-only-${f.owner.uid}`;
  const sessionId = 'session-1';
  const sessionRef = db.doc(`users/${f.owner.uid}/sessions/${sessionId}`);
  await sessionRef.set({ sessionId, isRevoked: false, createdAt: Timestamp.fromMillis(42000) });
  const data = { token, sessionId, platform: 'android', preferences };
  const request = callableRequest(f.owner, data);
  const registrationRef = db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(token)}`);
  const bindingRef = db.doc(`pushTokenOwners/${hash(token)}`);
  if (register) assert.deepEqual(await sync(request), { synced: true });
  const calls = [];
  const messaging = { sendEachForMulticast: async payload => {
    calls.push(payload); return { responses: payload.tokens.map(() => ({ success: true })) };
  } };
  const event = { params: { userId: f.owner.uid, notifId: f.ref.id }, data: await f.ref.get() };
  const handler = createPushNotificationHandler({ db, auth, messaging });
  return { ...f, token, data, request, sessionRef, registrationRef, bindingRef, event,
    calls, messaging, send: () => handler(event) };
}

test('registered active device receives one mock multicast with the correct recipient', async () => {
  const f = await setup(); await f.send(); assert.equal(f.calls.length, 1);
  assert.deepEqual(f.calls[0].tokens, [f.token]);
  assert.equal(f.calls[0].data.recipientId, f.owner.uid);
  assert.equal(f.calls[0].notification.body, 'بدأ بمتابعتك');
});
test('PUSHREGRESSION: an unbound legacy token cannot receive a notification', async () => {
  const f = await setup(); await f.bindingRef.delete(); await f.send(); assert.equal(f.calls.length, 0);
});
test('PUSHREGRESSION: a binding without a session cannot receive a notification', async () => {
  const f = await setup(); await f.bindingRef.set({ ownerId: f.owner.uid, authTime: f.owner.authTime });
  await f.send(); assert.equal(f.calls.length, 0);
});
test('PUSHREGRESSION: a noncanonical legacy token record is not delivery authority', async () => {
  const f = await setup(); await db.doc(`users/${f.owner.uid}/fcm_tokens/legacy`).set((await f.registrationRef.get()).data());
  await f.registrationRef.delete(); await f.send(); assert.equal(f.calls.length, 0);
});
test('PUSHREGRESSION: malformed cutoff cannot authorize device registration', async () => {
  const f = await setup({ register: false }); await db.doc(`authRevocations/${f.owner.uid}`).set({});
  await assert.rejects(sync(f.request), { code: 'unauthenticated' });
});
test('PUSHREGRESSION: frozen accounts cannot register push devices', async () => {
  const f = await setup({ register: false }); await db.doc(`users/${f.owner.uid}`).update({ 'security.frozen': true });
  await assert.rejects(sync(f.request), { code: 'permission-denied' });
});
test('PUSHREGRESSION: malformed device revocation cannot be bypassed during registration', async () => {
  const f = await setup({ register: false }); await f.bindingRef.collection('revocations').doc(f.owner.uid).set({});
  await assert.rejects(sync(f.request), { code: 'unauthenticated' });
});
test('canonical registration metadata and preferences must match the binding', async () => {
  const f = await setup(), original = (await f.registrationRef.get()).data();
  for (const change of [{ authTime: f.owner.authTime - 1 }, { sessionId: 'other' }, { preferences: {} }]) {
    await f.registrationRef.set({ ...original, ...change }); await f.send();
  }
  assert.equal(f.calls.length, 0);
});
test('a registration moved to another account is not delivered to the old account', async () => {
  const f = await setup(); await f.bindingRef.update({ ownerId: f.actor.uid });
  await f.send(); assert.equal(f.calls.length, 0);
});
test('missing revoked or recreated device sessions deny delivery', async () => {
  const f = await setup(), original = (await f.sessionRef.get()).data();
  await f.sessionRef.delete(); await f.send();
  await f.sessionRef.set({ ...original, isRevoked: true }); await f.send();
  await f.sessionRef.set({ ...original, createdAt: Timestamp.fromMillis(43000) }); await f.send();
  assert.equal(f.calls.length, 0);
});
test('recipient cutoff is checked again at delivery time', async () => {
  const f = await setup(), cutoff = db.doc(`authRevocations/${f.owner.uid}`);
  for (const data of [{ revokedBefore: f.owner.authTime }, {}, { revokedBefore: 'bad' }]) {
    await cutoff.set(data); await f.send();
  }
  assert.equal(f.calls.length, 0);
});
test('read or dismissed notifications are not pushed', async () => {
  const f = await setup(); await f.ref.update({ read: true }); await f.send();
  await f.ref.delete(); await f.send(); assert.equal(f.calls.length, 0);
});
test('recreated notifications do not receive an old event push', async () => {
  const f = await setup(), original = (await f.ref.get()).data();
  await f.ref.delete(); await f.ref.set(original); await f.send(); assert.equal(f.calls.length, 0);
});
test('global and community preference opt-outs prevent dispatch', async () => {
  const f = await setup();
  for (const p of [{ ...preferences, enabled: false }, { ...preferences, community: false }]) {
    await sync({ ...f.request, data: { ...f.data, preferences: p } }); await f.send();
  }
  assert.equal(f.calls.length, 0);
});
test('blocked actors and unavailable recipients suppress dispatch', async () => {
  const f = await setup(), block = db.doc(`users/${f.owner.uid}/blocked_accounts/${f.actor.uid}`);
  await block.set({}); await f.send(); await block.delete();
  await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'disabled' }); await f.send();
  await db.doc(`users/${f.owner.uid}`).update({ accountStatus: 'active', 'security.frozen': true }); await f.send();
  assert.equal(f.calls.length, 0);
});
test('registration rejects anonymous forged and malformed requests without writes', async () => {
  const f = await setup({ register: false });
  await assert.rejects(sync(callableRequest(null, f.data)), { code: 'unauthenticated' });
  await assert.rejects(sync({ ...f.request, auth: { uid: f.actor.uid } }), { code: 'unauthenticated' });
  for (const data of [{ ...f.data, extra: true }, { ...f.data, token: '' },
    { ...f.data, sessionId: 'a/b' }, { ...f.data, preferences: {} }]) {
    await assert.rejects(sync({ ...f.request, data }), { code: 'invalid-argument' });
  }
  assert.equal((await f.bindingRef.get()).exists, false);
});
test('registration requires an active matching session record', async () => {
  const f = await setup({ register: false }), original = (await f.sessionRef.get()).data();
  await f.sessionRef.delete(); await assert.rejects(sync(f.request), { code: 'failed-precondition' });
  await f.sessionRef.set({ ...original, isRevoked: true }); await assert.rejects(sync(f.request), { code: 'failed-precondition' });
});
test('registration rejects equal or later authentication cutoffs and accepts a newer session', async () => {
  const f = await setup({ register: false }), cutoff = db.doc(`authRevocations/${f.owner.uid}`);
  for (const revokedBefore of [f.owner.authTime, f.owner.authTime + 1]) {
    await cutoff.set({ revokedBefore }); await assert.rejects(sync(f.request), { code: 'unauthenticated' });
  }
  await cutoff.set({ revokedBefore: f.owner.authTime - 1 }); assert.deepEqual(await sync(f.request), { synced: true });
});
test('registration deduplicates old records into the canonical document', async () => {
  const f = await setup({ register: false }), collection = db.collection(`users/${f.owner.uid}/fcm_tokens`);
  await collection.doc('old').set({ token: f.token }); await collection.doc('old-2').set({ token: f.token });
  await sync(f.request); const docs = await collection.get();
  assert.equal(docs.size, 1); assert.equal(docs.docs[0].id, hash(f.token));
});
test('repeated detach remains safe and prevents stale re-registration', async () => {
  const f = await setup(), request = callableRequest(f.owner, { token: f.token });
  assert.deepEqual(await detach(request), { detached: true });
  assert.deepEqual(await detach(request), { detached: true });
  assert.equal((await f.registrationRef.get()).exists, false);
  await assert.rejects(sync(f.request), { code: 'unauthenticated' });
  await f.send(); assert.equal(f.calls.length, 0);
});
test('frozen user can still detach their device to reduce data exposure', async () => {
  const f = await setup(); await db.doc(`users/${f.owner.uid}`).update({ 'security.frozen': true });
  assert.deepEqual(await detach(callableRequest(f.owner, { token: f.token })), { detached: true });
  assert.equal((await f.registrationRef.get()).exists, false);
});
test('switching device ownership revokes the previous account registration', async () => {
  const f = await setup();
  await db.doc(`users/${f.actor.uid}/sessions/session-2`).set({ sessionId: 'session-2', isRevoked: false, createdAt: Timestamp.now() });
  await sync(callableRequest(f.actor, { ...f.data, sessionId: 'session-2' }));
  assert.equal((await f.bindingRef.get()).data().ownerId, f.actor.uid);
  await assert.rejects(sync(f.request), { code: 'unauthenticated' });
  await detach(callableRequest(f.owner, { token: f.token }));
  assert.equal((await f.bindingRef.get()).data().ownerId, f.actor.uid);
  await f.send(); assert.equal(f.calls.length, 0);
});
test('malformed existing binding metadata is not laundered into valid authority', async () => {
  const f = await setup({ register: false });
  await f.bindingRef.set({ ownerId: f.owner.uid, authTime: 'bad' });
  await assert.rejects(sync(f.request), { code: 'unauthenticated' });
  await f.bindingRef.set({ ownerId: f.actor.uid, authTime: 'bad' });
  await assert.rejects(sync(f.request), { code: 'failed-precondition' });
});
test('transient FCM failures do not delete a valid registration', async () => {
  const f = await setup(); f.messaging.sendEachForMulticast = async () => ({ responses: [
    { success: false, error: { code: 'messaging/server-unavailable' } },
  ] });
  await f.send(); assert.equal((await f.registrationRef.get()).exists, true);
});
test('invalid tokens are removed without touching unrelated or refreshed records', async () => {
  const f = await setup(); f.messaging.sendEachForMulticast = async () => {
    await f.registrationRef.update({ token: f.token + '-refreshed' });
    return { responses: [{ success: false, error: { code: 'messaging/registration-token-not-registered' } }] };
  };
  await f.send(); assert.equal((await f.registrationRef.get()).data().token, f.token + '-refreshed');
  await f.registrationRef.update({ token: f.token });
  f.messaging.sendEachForMulticast = async () => ({ responses: [
    { success: false, error: { code: 'messaging/registration-token-not-registered' } },
  ] });
  await f.send(); assert.equal((await f.registrationRef.get()).exists, false);
});
