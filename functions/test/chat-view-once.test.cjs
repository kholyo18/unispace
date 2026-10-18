const test = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createChatViewOnceHandlers } = require('../security/chat-view-once');
const { createStorageUploadHandler } = require('../security/storage-upload');
const { createChatHandlers } = require('../security/chat-service');
const { createSignInSessionHandler } = require('../security/device-sessions');
const { db, auth, FieldValue, Timestamp, fixture, callableRequest, close, project } = require('./helpers/notification-fixture.cjs');
test.after(close);
async function setup() {
  const f = await fixture();
  for (const user of [f.actor, f.owner, f.outsider]) {
    const issued = await createSignInSessionHandler({ db, FieldValue })({ data: { uid: user.uid }, eventId: randomUUID() });
    user.sid = issued.sessionClaims.sid;
    await auth.setCustomUserClaims(user.uid, { sid: user.sid });
    const r = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: await auth.createCustomToken(user.uid), returnSecureToken: true }),
    });
    assert.equal(r.status, 200); user.token = (await r.json()).idToken;
    await db.doc(`users/${user.uid}`).set({ privacy: { whoCanMessage: 'everyone' } }, { merge: true });
  }
  const { chatId } = await createChatHandlers({ db, auth, FieldValue }).open(callableRequest(f.actor, { peerId: f.owner.uid }));
  const name = `${project}.appspot.com`, calls = [], metadata = { generation: '42', size: '4', contentType: 'image/jpeg' };
  let missing = false;
  const storage = { name, file: (path, options) => ({ path, options,
    getMetadata: async () => { if (missing) throw Object.assign(Error(), { code: 404 }); return [{ ...metadata }]; },
    getSignedUrl: async options => { calls.push({ path, options }); return [`https://storage.googleapis.com/${name}/${path}?signature=test`]; },
  }) };
  const prepareUpload = createStorageUploadHandler({ db, auth, FieldValue, Timestamp, bucketName: () => name });
  const h = createChatViewOnceHandlers({ db, auth, FieldValue, Timestamp, bucket: () => storage, prepareUpload });
  const mediaId = randomUUID(), messageId = randomUUID(), input = { chatId, mediaId, size: 4, contentType: 'image/jpeg' };
  const ref = db.doc(`chatViewOnceAssets/${mediaId}`);
  const request = user => ({ headers: { authorization: `Bearer ${user.token}` }, body: { chatId, messageId } });
  async function prepare() { return h.prepare(callableRequest(f.actor, input)); }
  async function bind(overrides = {}) {
    const generation = await h.prepareForSend({ uid: f.actor.uid, chatId, mediaId });
    await db.runTransaction(async tx => {
      const write = await h.bindForSend({ tx, uid: f.actor.uid, chatId, mediaId, messageId, generation, memberIds: [f.actor.uid, f.owner.uid], ...overrides });
      write();
      tx.create(db.doc(`chats/${chatId}/messages/${messageId}`), { authorId: f.actor.uid, type: 'viewOnce', mediaId });
    });
  }
  return { ...f, h, calls, metadata, input, mediaId, messageId, chatId, ref, request, prepare, bind, missing: () => { missing = true; } };
}
test('private exact upload signing and generation-bound consume returns no URL', async () => {
  const f = await setup(), result = await f.prepare();
  assert.equal(result.path, `chat_view_once/${f.chatId}/${f.mediaId}`);
  assert.equal(result.fileUrl, undefined);
  assert.equal(result.uploadHeaders['x-goog-if-generation-match'], '0');
  assert.ok(result.uploadExpiresAt <= Date.now() + 90000);
  assert.equal(f.calls[0].options.action, 'write');
  await f.bind();
  const opened = await f.h.consume(f.request(f.owner));
  assert.equal(opened.file.options.generation, '42'); assert.equal(opened.size, 4);
  assert.equal(opened.url, undefined); assert.equal(f.calls.length, 1);
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'already-exists' });
});
test('concurrent consumption grants exactly one response', async () => {
  const f = await setup(); await f.prepare(); await f.bind();
  const results = await Promise.allSettled([f.h.consume(f.request(f.owner)), f.h.consume(f.request(f.owner))]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.code, 'already-exists');
});
test('sender, outsider, mutual block, revoked session cannot consume', async () => {
  const f = await setup(); await f.prepare(); await f.bind();
  for (const u of [f.actor, f.outsider]) await assert.rejects(f.h.consume(f.request(u)), { code: 'permission-denied' });
  const block = db.doc(`users/${f.actor.uid}/blocked_accounts/${f.owner.uid}`); await block.set({});
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'permission-denied' }); await block.delete();
  await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({ isRevoked: true });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'unauthenticated' });
  assert.deepEqual((await f.ref.get()).data().consumedBy, {});
});
test('expired and missing object fail before consumption', async () => {
  const f = await setup(); await f.prepare(); await f.bind();
  await f.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() - 1) });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'failed-precondition' });
  await f.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() + 60000) }); f.missing();
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'not-found' });
  assert.deepEqual((await f.ref.get()).data().consumedBy, {});
});
test('asset owner/chat mismatch and cross-message reuse cannot bind', async () => {
  const f = await setup(); await f.prepare();
  for (const input of [{ uid: f.owner.uid, chatId: f.chatId }, { uid: f.actor.uid, chatId: 'other' }]) {
    await assert.rejects(f.h.prepareForSend({ ...input, mediaId: f.mediaId }), { code: 'failed-precondition' });
  }
  await f.bind(); await assert.rejects(f.bind({ messageId: 'another' }), { code: 'failed-precondition' });
});
test('rejects oversized/unsupported photos and wrong metadata', async () => {
  const f = await setup();
  for (const input of [{ ...f.input, size: 20 * 1024 * 1024 + 1 }, { ...f.input, contentType: 'image/gif' }, { ...f.input, mediaId: '../bad' }]) {
    await assert.rejects(f.h.prepare(callableRequest(f.actor, input)), { code: 'invalid-argument' });
  }
  await f.prepare(); f.metadata.size = '5';
  await assert.rejects(f.h.prepareForSend({ uid: f.actor.uid, chatId: f.chatId, mediaId: f.mediaId }), { code: 'failed-precondition' });
});
test('removed recipients, deleted message, canonical frozen account deny access', async () => {
  const f = await setup(); await f.prepare(); await f.bind();
  const message = db.doc(`chats/${f.chatId}/messages/${f.messageId}`);
  await message.update({ deleted: true });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'not-found' }); await message.update({ deleted: false });
  await db.doc(`accountStateControls/${f.owner.uid}`).set({ schemaVersion: 1, revision: 1, selfDisabled: false, selfFrozen: true, adminSuspended: false });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'permission-denied' });
  await db.doc(`chats/${f.chatId}`).update({ memberIds: [f.actor.uid] });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'permission-denied' });
});

async function cleanupFixture(behavior = {}) {
  // A separate emulator collection namespace is provided through a narrow db
  // adapter so prior test fixtures cannot affect the batch-limit assertions.
  const name = `viewOnceCleanup_${randomUUID()}`, collection = db.collection(name), calls = [];
  const cleanupDb = { collection: () => collection, runTransaction: callback => db.runTransaction(callback) };
  const storage = { file: (path, options) => ({
    getMetadata: async () => {
      if (behavior.missing) throw Object.assign(Error(), { code: 404 });
      return [{ generation: '99' }];
    },
    delete: async args => {
      calls.push({ path, options, args });
      if (behavior.deleteError) throw Object.assign(Error(), { code: behavior.deleteError });
    },
  }) };
  const h = createChatViewOnceHandlers({ db: cleanupDb, auth, FieldValue, Timestamp, bucket: () => storage });
  async function asset(state, expired = true) {
    const id = randomUUID(), ref = collection.doc(id), chatId = 'test_chat';
    await ref.set({ state, chatId, path: `chat_view_once/${chatId}/${id}`, ...(state === 'bound' ? { generation: '42' } : {}),
      expiresAt: Timestamp.fromMillis(Date.now() + (expired ? -60000 : 60000)) });
    return ref;
  }
  return { h, asset, calls };
}
test('cleanup deletes expired pinned/prepared generations and keeps unexpired tickets', async () => {
  const f = await cleanupFixture(), bound = await f.asset('bound'), prepared = await f.asset('prepared'), future = await f.asset('bound', false);
  assert.deepEqual(await f.h.cleanup(), { scanned: 2, removed: 2, failed: 0 });
  assert.equal((await bound.get()).exists, false); assert.equal((await prepared.get()).exists, false); assert.equal((await future.get()).exists, true);
  assert.deepEqual(f.calls.map(c => c.options.generation).sort(), ['42', '99']);
  for (const c of f.calls) assert.equal(c.args.ifGenerationMatch, c.options.generation);
});
test('cleanup retains ticket after failed delete and removes missing-object ticket', async () => {
  const f = await cleanupFixture({ deleteError: 403 }), ref = await f.asset('bound');
  assert.deepEqual(await f.h.cleanup(), { scanned: 1, removed: 0, failed: 1 }); assert.equal((await ref.get()).exists, true);
  const missing = await cleanupFixture({ missing: true }), abandoned = await missing.asset('prepared');
  assert.deepEqual(await missing.h.cleanup(), { scanned: 1, removed: 1, failed: 0 }); assert.equal((await abandoned.get()).exists, false);
  const missingBound = await cleanupFixture({ deleteError: 404 }); await missingBound.asset('bound');
  assert.deepEqual(await missingBound.h.cleanup(), { scanned: 1, removed: 1, failed: 0 });
});
test('cleanup processes at most100 expired assets per run', async () => {
  const f = await cleanupFixture({ missing: true });
  await Promise.all(Array.from({ length: 101 }, () => f.asset('prepared')));
  assert.deepEqual(await f.h.cleanup(), { scanned: 100, removed: 100, failed: 0 });
  assert.deepEqual(await f.h.cleanup(), { scanned: 1, removed: 1, failed: 0 });
});

test('send integration binds private asset, consumes once and retries after opened/expiry without object fetch', async () => {
  const f = await setup(); await f.prepare();
  const chat = createChatHandlers({ db, auth, FieldValue, viewOnce: f.h });
  const input = { chatId: f.chatId, messageId: f.messageId, message: { type: 'viewOnce', mediaId: f.mediaId } };
  assert.deepEqual(await chat.send(callableRequest(f.actor, input)), { messageId: f.messageId });
  const message = db.doc(`chats/${f.chatId}/messages/${f.messageId}`);
  const saved = (await message.get()).data();
  assert.equal(saved.type, 'viewOnce'); assert.equal(saved.mediaId, f.mediaId);
  assert.equal(saved.imageUrl, undefined); assert.equal(saved.thumbnailUrl, undefined);
  await f.h.consume(f.request(f.owner));
  assert.equal((await message.get()).data().viewOnceOpenedBy[f.owner.uid], true);
  f.missing(); await f.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
  assert.deepEqual(await chat.send(callableRequest(f.actor, input)), { messageId: f.messageId });
  await assert.rejects(f.h.consume(f.request(f.owner)), { code: 'failed-precondition' });
  // Expiry cleanup can remove the asset; permanent send receipts still confirm
  // the original immutable message rather than attempting a second upload.
  await f.ref.delete();
  assert.deepEqual(await chat.send(callableRequest(f.actor, input)), { messageId: f.messageId });
});
test('send integration forbids reusing one asset in a different message or changing a receipt payload', async () => {
  const f = await setup(); await f.prepare();
  const chat = createChatHandlers({ db, auth, FieldValue, viewOnce: f.h });
  const input = { chatId: f.chatId, messageId: f.messageId, message: { type: 'viewOnce', mediaId: f.mediaId } };
  await chat.send(callableRequest(f.actor, input));
  await assert.rejects(chat.send(callableRequest(f.actor, { ...input, messageId: randomUUID() })), { code: 'failed-precondition' });
  await assert.rejects(chat.send(callableRequest(f.actor, { ...input, message: { type: 'viewOnce', mediaId: randomUUID() } })), { code: 'already-exists' });
});
test('send integration rejects view-once source URLs, thumbnails, captions, text and quoted payloads', async () => {
  const f = await setup();
  const chat = createChatHandlers({ db, auth, FieldValue, viewOnce: f.h });
  for (const extra of [{ imageUrl: 'https://example.test/photo' }, { thumbnailUrl: 'https://example.test/photo' }, { caption: 'private caption' }, { text: 'secret' }, { replyToId: 'old_message' }]) {
    await assert.rejects(chat.send(callableRequest(f.actor, { chatId: f.chatId, messageId: randomUUID(), message: { type: 'viewOnce', mediaId: f.mediaId, ...extra } })), { code: 'invalid-argument' });
  }
  assert.equal((await db.collection(`chats/${f.chatId}/messages`).get()).size, 0);
});
test('send integration preserves regular image/video captions and rejects invalid/cross-chat thumbnails', async () => {
  const f = await setup();
  const chat = createChatHandlers({ db, auth, FieldValue, viewOnce: f.h });
  const url = path => `https://firebasestorage.googleapis.com/v0/b/${project}.appspot.com/o/${encodeURIComponent(path)}`;
  const image = url(`chats/${f.chatId}/images/photo.jpg`), video = url(`chats/${f.chatId}/videos/clip.mp4`);
  const send = message => chat.send(callableRequest(f.actor, { chatId: f.chatId, messageId: randomUUID(), message }));
  for (const message of [{ type: 'image', imageUrl: image, caption: 'تعليق — photo 😊' }, { type: 'video', videoUrl: video, thumbnailUrl: image, caption: 'clip' }]) {
    const sent = await send(message), saved = (await db.doc(`chats/${f.chatId}/messages/${sent.messageId}`).get()).data();
    assert.equal(saved.caption, message.caption); assert.equal(saved.thumbnailUrl, message.thumbnailUrl);
  }
  for (const message of [
    { type: 'image', imageUrl: image, caption: 'x'.repeat(1001) },
    { type: 'image', imageUrl: image, caption: 42 },
    { type: 'text', text: 'hello', caption: 'invalid' },
    { type: 'image', imageUrl: image, thumbnailUrl: image },
    { type: 'video', videoUrl: video, thumbnailUrl: url('chats/another/images/photo.jpg') },
    { type: 'video', videoUrl: video, thumbnailUrl: url(`chats/${f.chatId}/videos/clip.mp4`) },
  ]) await assert.rejects(send(message), { code: 'invalid-argument' });
});

test('upload confirmation recovers a lost successful create-only PUT acknowledgement without granting read access', async () => {
  const f = await setup(); await f.prepare();
  const input = { chatId: f.chatId, mediaId: f.mediaId };
  assert.deepEqual(await f.h.confirmUpload(callableRequest(f.actor, input)), { uploaded: true });
  assert.equal(f.calls.length, 1); // Only the original write capability exists.
  assert.equal((await f.ref.get()).data().state, 'prepared');
  await assert.rejects(f.h.confirmUpload(callableRequest(f.owner, input)), { code: 'failed-precondition' });
  await assert.rejects(f.h.confirmUpload(callableRequest(f.actor, { ...input, chatId: 'other' })), { code: 'failed-precondition' });
  await assert.rejects(f.h.confirmUpload(callableRequest(f.actor, { ...input, extra: true })), { code: 'invalid-argument' });
});
test('upload confirmation rejects missing, mismatched, downloadable or expired objects and revoked sessions', async () => {
  const f = await setup(); await f.prepare();
  const req = callableRequest(f.actor, { chatId: f.chatId, mediaId: f.mediaId });
  f.metadata.size = '5'; await assert.rejects(f.h.confirmUpload(req), { code: 'failed-precondition' }); f.metadata.size = '4';
  f.metadata.metadata = { firebaseStorageDownloadTokens: 'must-never-be-issued' };
  await assert.rejects(f.h.confirmUpload(req), { code: 'failed-precondition' }); delete f.metadata.metadata;
  await f.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() - 1) });
  await assert.rejects(f.h.confirmUpload(req), { code: 'failed-precondition' });
  await f.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() + 60000) });
  f.missing(); await assert.rejects(f.h.confirmUpload(req), { code: 'not-found' });
  await db.doc(`users/${f.actor.uid}/sessions/${f.actor.sid}`).update({ isRevoked: true });
  await assert.rejects(f.h.confirmUpload(req), { code: 'unauthenticated' });
});

test('ordinary recipients may consume a private photo in administrator-only groups',async()=>{
 const f=await setup();await f.prepare();await f.bind();
 await db.doc('chats/'+f.chatId).update({type:'group',adminIds:[f.actor.uid],adminsOnlyMessaging:true});
 const opened=await f.h.consume(f.request(f.owner));assert.equal(opened.size,4);
});
