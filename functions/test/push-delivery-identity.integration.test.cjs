// Reject incomplete server/legacy records without changing real users or FCM.
// Auth/Firestore and production handlers are real loopback collaborators.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
if (process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    [process.env.GCLOUD_PROJECT, process.env.GOOGLE_CLOUD_PROJECT].some(p => p && p !== 'demo-unispace-security')) {
  throw Error('Credential-free fixed demo project required.');
}
const { db, auth, FieldValue, Timestamp, fixture, callableRequest, hash, close } = require('./helpers/notification-fixture.cjs');
const { createSyncPushDeviceHandler } = require('../security/push-preferences');
const { createPushNotificationHandler } = require('../security/push-notification');
const { createFollowHandler } = require('../security/follow-relationships');
after(close);
const preferences = { enabled: true, community: true, announcements: true, exams: true };
const sync = createSyncPushDeviceHandler({ db, auth, FieldValue });
const follow = createFollowHandler({ db, auth, FieldValue });
async function setup(extra = {}) {
  const f = await fixture();
  if (Object.keys(extra).length) await f.ref.update(extra);
  assert.equal((await f.ref.get()).data().type, extra.type || 'follow');
  const token = `identity-fixture-${f.owner.uid}`, sessionId = 'identity-session';
  await db.doc(`users/${f.owner.uid}/sessions/${sessionId}`).set({
    sessionId, isRevoked: false, createdAt: Timestamp.fromMillis(42000),
  });
  // A genuine fixture-token failure remains visible; no retry or bypass.
  assert.equal((await auth.verifyIdToken(f.owner.token, true)).uid, f.owner.uid);
  const registration = { token, sessionId, platform: 'android', preferences };
  assert.deepEqual(await sync(callableRequest(f.owner, registration)), { synced: true });
  const calls = [];
  const messaging = { sendEachForMulticast: async payload => {
    calls.push(payload); return { responses: payload.tokens.map(() => ({ success: true })) };
  } };
  const event = { params: { userId: f.owner.uid, notifId: f.ref.id }, data: await f.ref.get() };
  const handler = createPushNotificationHandler({ db, auth, messaging });
  return { ...f, token, registration, calls, messaging, handler, send: () => handler(event) };
}
async function suppressWithoutMutation(f) {
  const before = (await f.ref.get()).data();
  const tokenRef = db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(f.token)}`);
  const registration = (await tokenRef.get()).data();
  await f.send();
  assert.equal(f.calls.length, 0, 'An unverifiable required actor must not reach FCM');
  assert.deepEqual((await f.ref.get()).data(), before, 'A denial must not mutate the record');
  assert.deepEqual((await tokenRef.get()).data(), registration, 'A denial must not delete a healthy token');
}
for (const type of ['follow', 'follow_request', 'follow_accepted']) {
  for (const absent of ['missing', 'null', 'empty']) {
    test(`ACTORIDENTITY: ${type} rejects ${absent} actorId`, async () => {
      const f = await setup({ type });
      await f.ref.update({ actorId: absent === 'missing' ? FieldValue.delete() : absent === 'null' ? null : '' });
      await suppressWithoutMutation(f);
    });
  }
}
for (const alternative of ['actorName', 'actorIds']) {
  test(`ACTORIDENTITY: ${alternative} is not fallback identity authority`, async () => {
    const f = await setup();
    await f.ref.update({ actorId: FieldValue.delete(),
      actorName: alternative === 'actorName' ? 'Synthetic retained name' : '',
      actorIds: alternative === 'actorIds' ? [f.actor.uid] : [] });
    await suppressWithoutMutation(f);
  });
}
for (const state of ['disabled', 'deleted']) {
  test(`ACTORIDENTITY: removing actorId cannot bypass a ${state} Auth actor`, async () => {
    const f = await setup();
    if (state === 'disabled') await auth.updateUser(f.actor.uid, { disabled: true });
    else await auth.deleteUser(f.actor.uid);
    await f.send(); assert.equal(f.calls.length, 0, 'Existing Auth check must deny first');
    await f.ref.update({ actorId: FieldValue.delete() });
    await suppressWithoutMutation(f);
  });
}
for (const collection of ['blocked_accounts', 'blocked_users', 'blocked_by']) {
  for (const direction of ['recipient', 'actor']) {
    test(`ACTORIDENTITY: clearing actorId cannot bypass ${direction}/${collection}`, async () => {
      const f = await setup();
      const [owner, target] = direction === 'recipient' ? [f.owner.uid, f.actor.uid] : [f.actor.uid, f.owner.uid];
      await db.doc(`users/${owner}/${collection}/${target}`).set({ fixture: true });
      await f.send(); assert.equal(f.calls.length, 0, 'Existing block check must deny first');
      await f.ref.update({ actorId: '' }); await suppressWithoutMutation(f);
    });
  }
}
for (const type of ['announcement', 'exam_reminder']) {
  test(`${type} retains actorless delivery and its category opt-out`, async () => {
    const f = await setup({ type });
    for (const actorId of [FieldValue.delete(), null, '']) {
      await f.ref.update({ actorId }); await f.send();
    }
    assert.equal(f.calls.length, 3);
    assert.ok(f.calls.every(p => p.data.type === type && p.data.actorId === '' && p.data.recipientId === f.owner.uid));
    const category = type === 'announcement' ? 'announcements' : 'exams';
    await sync(callableRequest(f.owner, { ...f.registration, preferences: { ...preferences, [category]: false } }));
    await f.send(); assert.equal(f.calls.length, 3);
  });
}
test('malformed explicit IDs remain denied on social and actor-optional system records', async () => {
  const f = await setup();
  for (const type of ['follow', 'announcement', 'exam_reminder']) {
    for (const actorId of [false, 0, [], {}, '.', '..', 'invalid/path']) {
      await f.ref.update({ type, actorId }); await suppressWithoutMutation(f);
    }
  }
});
test('ACTORIDENTITY: a repaired valid actor can be retried with the same device registration', async () => {
  const f = await setup(); await f.ref.update({ actorId: FieldValue.delete() });
  await suppressWithoutMutation(f);
  await f.ref.update({ actorId: f.actor.uid }); await f.send();
  assert.equal(f.calls.length, 1);
  assert.deepEqual(f.calls[0].tokens, [f.token]);
  assert.equal(f.calls[0].data.actorId, f.actor.uid);
});
test('ACTORIDENTITY: clearing the required actor after batch one stops batch two', async () => {
  const f = await setup();
  const registration = (await db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(f.token)}`).get()).data();
  const binding = (await db.doc(`pushTokenOwners/${hash(f.token)}`).get()).data();
  for (let offset = 0; offset < 500; offset += 240) {
    const batch = db.batch();
    for (let i = offset; i < Math.min(500, offset + 240); i++) {
      const token = `${f.token}-${i}`, id = hash(token);
      batch.set(db.doc(`users/${f.owner.uid}/fcm_tokens/${id}`), { ...registration, token });
      batch.set(db.doc(`pushTokenOwners/${id}`), binding);
    }
    await batch.commit();
  }
  f.messaging.sendEachForMulticast = async payload => {
    f.calls.push(payload); await f.ref.update({ actorId: FieldValue.delete() });
    return { responses: payload.tokens.map(() => ({ success: true })) };
  };
  await f.send(); assert.deepEqual(f.calls.map(p => p.tokens.length), [500]);
});
for (const type of ['follow', 'follow_request', 'follow_accepted']) {
  test(`real follow producer retains a verifiable actor and delivery for ${type}`, async () => {
    const f = await setup();
    await f.ref.delete(); // The positive oracle must be the real producer output.
    if (type === 'follow_accepted') {
      await db.doc(`users/${f.actor.uid}`).set({ privacy: { privateAccount: true } }, { merge: true });
      assert.equal((await follow(callableRequest(f.owner, { action: 'follow', userId: f.actor.uid }))).state, 'pending');
      assert.equal((await follow(callableRequest(f.actor, { action: 'accept', userId: f.owner.uid }))).state, 'following');
    } else {
      if (type === 'follow_request') await db.doc(`users/${f.owner.uid}`).set({ privacy: { privateAccount: true } }, { merge: true });
      const result = await follow(callableRequest(f.actor, { action: 'follow', userId: f.owner.uid }));
      assert.equal(result.state, type === 'follow_request' ? 'pending' : 'following');
    }
    const notifications = await db.collection(`users/${f.owner.uid}/notifications`).get();
    assert.equal(notifications.size, 1, 'Inspect the actual producer output');
    const notification = notifications.docs[0];
    assert.equal(notification.data().type, type);
    assert.equal(notification.data().actorId, f.actor.uid);
    await f.handler({ params: { userId: f.owner.uid, notifId: notification.id }, data: notification });
    assert.equal(f.calls.length, 1);
    assert.deepEqual(f.calls[0].tokens, [f.token]);
    assert.equal(f.calls[0].data.actorId, f.actor.uid);
    assert.equal(f.calls[0].data.type, type);
  });
}
