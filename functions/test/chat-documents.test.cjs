const test = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createChatDocumentHandlers } = require('../security/chat-documents');
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
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: await auth.createCustomToken(user.uid), returnSecureToken: true }),
    });
    assert.equal(response.status, 200);
    user.token = (await response.json()).idToken;
    await db.doc(`users/${user.uid}`).set({ privacy: { whoCanMessage: 'everyone' } }, { merge: true });
  }
  const { chatId } = await createChatHandlers({ db, auth, FieldValue }).open(callableRequest(f.actor, { peerId: f.owner.uid }));
  const calls = [], name = `${project}.appspot.com`;
  const metadata = { generation: '42', size: '4', contentType: 'application/octet-stream' };
  let onSign;
  const storage = { name, file: path => ({
    getMetadata: async () => [{ ...metadata }],
    getSignedUrl: async options => {
      calls.push({ path, options });
      if (onSign) await onSign();
      return [`https://storage.googleapis.com/${name}/${encodeURIComponent(path)}?test-signed=1`];
    },
  }) };
  const prepareUpload = createStorageUploadHandler({ db, auth, FieldValue, Timestamp, bucketName: () => name });
  const handlers = createChatDocumentHandlers({ db, auth, FieldValue, Timestamp, bucket: () => storage, prepareUpload });
  const input = { expectedUid: f.actor.uid, path: `chats/${chatId}/files/document.bin`, contentType: 'application/octet-stream', size: 4 };
  const messageId = 'document';
  const fileUrl = `https://firebasestorage.googleapis.com/v0/b/${name}/o/${encodeURIComponent(input.path)}`;
  await db.doc(`chats/${chatId}/messages/${messageId}`).set({ authorId: f.actor.uid, type: 'file', fileName: 'notes.pdf', fileUrl, size: 4 });
  return { ...f, chatId, messageId, handlers, calls, input, metadata, setOnSign: fn => { onSign = fn; } };
}

test('prepare issues an exact 90-second create-only signed PUT and token-free locator', async () => {
  const f = await setup(), start = Date.now();
  const result = await f.handlers.prepare(callableRequest(f.actor, f.input));
  assert.equal(result.path, f.input.path);
  assert.equal(result.size, 4);
  assert.equal(new URL(result.fileUrl).search, '');
  assert.ok(result.uploadExpiresAt > start && result.uploadExpiresAt <= Date.now() + 90000);
  assert.deepEqual(result.uploadHeaders, { 'Content-Type': 'application/octet-stream', 'Content-Length': '4', 'x-goog-if-generation-match': '0' });
  const signed = f.calls.at(-1);
  assert.equal(signed.path, f.input.path);
  assert.equal(signed.options.version, 'v4');
  assert.equal(signed.options.action, 'write');
  assert.equal(signed.options.contentType, 'application/octet-stream');
  assert.deepEqual(signed.options.extensionHeaders, { 'content-length': '4', 'x-goog-if-generation-match': '0' });
});

test('prepare rejects wrong folder, oversized file, outsider, block and revoked session before signing', async () => {
  const f = await setup();
  for (const input of [{ ...f.input, path: f.input.path.replace('/files/', '/audio/') }, { ...f.input, size: 20 * 1024 * 1024 + 1 }]) {
    await assert.rejects(f.handlers.prepare(callableRequest(f.actor, input)), { code: 'invalid-argument' });
  }
  await assert.rejects(f.handlers.prepare(callableRequest(f.outsider, { ...f.input, expectedUid: f.outsider.uid })), { code: 'permission-denied' });
  await db.doc(`users/${f.owner.uid}/blocked_accounts/${f.actor.uid}`).set({});
  await assert.rejects(f.handlers.prepare(callableRequest(f.actor, f.input)), { code: 'permission-denied' });
  await db.doc(`users/${f.actor.uid}/sessions/${f.actor.sid}`).update({ isRevoked: true });
  await assert.rejects(f.handlers.prepare(callableRequest(f.actor, f.input)), { code: 'unauthenticated' });
  assert.equal(f.calls.length, 0);
});

test('read issues only a generation-bound two-minute URL for a current member', async () => {
  const f = await setup(), input = { chatId: f.chatId, messageId: f.messageId };
  const result = await f.handlers.read(callableRequest(f.owner, input));
  assert.equal(result.fileName, 'notes.pdf');
  assert.equal(result.size, 4);
  assert.ok(result.expiresAt > Date.now() && result.expiresAt <= Date.now() + 120000);
  assert.equal(f.calls.at(-1).options.action, 'read');
  assert.deepEqual(f.calls.at(-1).options.queryParams, { generation: '42' });
  await assert.rejects(f.handlers.read(callableRequest(f.outsider, input)), { code: 'permission-denied' });
  await db.doc(`users/${f.actor.uid}/blocked_accounts/${f.owner.uid}`).set({});
  await assert.rejects(f.handlers.read(callableRequest(f.owner, input)), { code: 'permission-denied' });
  await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({ isRevoked: true });
  await assert.rejects(f.handlers.read(callableRequest(f.owner, input)), { code: 'unauthenticated' });
  assert.equal(f.calls.length, 1);
});

test('read rejects unrelated source, invalid object size and canonical freeze', async () => {
  const f = await setup(), input = { chatId: f.chatId, messageId: f.messageId };
  f.metadata.size = String(20 * 1024 * 1024 + 1);
  await assert.rejects(f.handlers.read(callableRequest(f.owner, input)), { code: 'failed-precondition' });
  f.metadata.size = '4';
  await db.doc(`chats/${f.chatId}/messages/${f.messageId}`).update({ fileUrl: 'https://example.com/file.pdf' });
  await assert.rejects(f.handlers.read(callableRequest(f.owner, input)), { code: 'invalid-argument' });
  await db.doc(`accountStateControls/${f.owner.uid}`).set({ schemaVersion: 1, revision: 1, selfDisabled: false, selfFrozen: true, adminSuspended: false });
  await assert.rejects(f.handlers.read(callableRequest(f.owner, input)), { code: 'permission-denied' });
  assert.equal(f.calls.length, 0);
});

test('read rechecks membership after signing and withholds stale capability', async () => {
  const f = await setup();
  f.setOnSign(() => db.doc(`chats/${f.chatId}`).update({ memberIds: [f.actor.uid] }));
  await assert.rejects(f.handlers.read(callableRequest(f.owner, { chatId: f.chatId, messageId: f.messageId })), { code: 'permission-denied' });
});

test('prepare rechecks signed session after signing before returning upload capability', async () => {
  const f = await setup();
  f.setOnSign(() => db.doc(`users/${f.actor.uid}/sessions/${f.actor.sid}`).update({ isRevoked: true }));
  await assert.rejects(f.handlers.prepare(callableRequest(f.actor, f.input)), { code: 'unauthenticated' });
});

test('ordinary members may read existing documents in administrator-only groups but cannot upload',async()=>{
 const f=await setup();await db.doc('chats/'+f.chatId).update({type:'group',adminIds:[f.actor.uid],adminsOnlyMessaging:true});
 const result=await f.handlers.read(callableRequest(f.owner,{chatId:f.chatId,messageId:f.messageId}));assert.equal(result.size,4);
 await assert.rejects(f.handlers.prepare(callableRequest(f.owner,{...f.input,expectedUid:f.owner.uid})),{code:'permission-denied'});
});
