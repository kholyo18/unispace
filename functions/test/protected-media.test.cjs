const test = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createProtectedMediaHandler, parseProtectedMediaSource } = require('../security/protected-media');
const { db, auth, Timestamp, fixture, callableRequest, close, project } = require('./helpers/notification-fixture.cjs');
test.after(close);
async function setup() {
  const f = await fixture(), name = `${project}.appspot.com`, calls = [];
  const locator = path => `https://firebasestorage.googleapis.com/v0/b/${name}/o/${encodeURIComponent(path)}`;
  let onSign;
  const metadata = { generation: '42', size: '10' };
  const storage = { name, file: path => ({ getMetadata: async () => [metadata],
    getSignedUrl: async options => { calls.push({ path, options }); if (onSign) await onSign(); return ['https://storage.googleapis.com/signed']; } }) };
  const read = createProtectedMediaHandler({ db, auth, bucket: () => storage });
  const chatId = `protected_${randomUUID()}`;
  const chat = db.doc(`chats/${chatId}`), message = chat.collection('messages').doc('message');
  await chat.set({ type: 'direct', memberIds: [f.actor.uid, f.owner.uid] });
  const url = locator(`chats/${chatId}/images/photo.jpg`) + '?alt=media&token=legacy';
  await message.set({ type: 'image', imageUrl: url, createdAt: Timestamp.fromMillis(1000) });
  async function finalizedPreview(path, owner = f.owner.uid) {
    const id = db.collection('storageUploadGrants').doc().id;
    metadata.metadata = { protectedUploadVersion: '1', uploadedBy: owner, uploadGrantId: id };
    await db.doc(`storageUploadGrants/${id}`).set({ uid: owner, path, bucket: name });
    await db.doc(`protectedUploadTickets/${id}`).set({ uid: owner, path, bucket: name, state: 'complete', finalGeneration: '42' });
  }
  return { ...f, name, calls, metadata, finalizedPreview, locator, read, chat, chatId, message, url, setOnSign: fn => { onSign = fn; } };
}
test('source parser rejects foreign buckets, traversal, credentials, fragments and malformed encodings', () => {
  const valid = 'https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/users%2Fu%2Fprofile.jpg';
  assert.equal(parseProtectedMediaSource(valid + '?token=legacy&v=1', 'demo.appspot.com').path, 'users/u/profile.jpg');
  for (const source of [valid.replace('demo.appspot.com', 'other.appspot.com'), valid + '#x', valid.replace('/o/', '/o/..%2F'),
    valid.replace('https://', 'https://user@'), valid.replace('profile.jpg', '%ZZ'), valid.replace('profile.jpg', '%5Cbad')]) {
    assert.throws(() => parseProtectedMediaSource(source, 'demo.appspot.com'), { code: 'invalid-argument' });
  }
});
test('legacy chat locator is resolved to a two-minute generation-bound URL; outsiders and absent source fail', async () => {
  const f = await setup();
  const result = await f.read(callableRequest(f.owner, { url: f.url }));
  assert.equal(result.url, 'https://storage.googleapis.com/signed');
  assert.ok(result.expiresAt > Date.now() && result.expiresAt <= Date.now() + 120000);
  assert.deepEqual(f.calls[0].options.queryParams, { generation: '42' });
  await assert.rejects(f.read(callableRequest(f.outsider, { url: f.url })), { code: 'permission-denied' });
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url.replace('legacy', 'different') })), { code: 'not-found' });
});
test('all attachment types and thumbnail use persisted message ownership', async () => {
  const f = await setup();
  for (const [type, field, folder] of [['image','imageUrl','images'], ['gif','gifUrl','images'], ['video','videoUrl','videos'],
    ['audio','audioUrl','audio'], ['file','fileUrl','files'], ['video','thumbnailUrl','images']]) {
    const url = f.locator(`chats/${f.chatId}/${folder}/${field}.bin`);
    await f.message.set({ type, [field]: url });
    await f.read(callableRequest(f.owner, { url }));
  }
  assert.equal(f.calls.length, 6);
});
test('hidden, deleted, view-once and cleared messages cannot mint delivery URLs', async () => {
  const f = await setup();
  for (const extra of [{ hiddenBy: { [f.owner.uid]: true } }, { hiddenBy: [f.owner.uid] }, { deleted: true },
    { isDeleted: true }, { deletedAt: Timestamp.now() }, { deletedForEveryone: true }, { viewOnce: true }]) {
    await f.message.set({ type: 'image', imageUrl: f.url, createdAt: Timestamp.fromMillis(1000), ...extra });
    await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'not-found' });
  }
  await f.message.set({ type: 'image', imageUrl: f.url, createdAt: Timestamp.fromMillis(1000) });
  await f.chat.update({ clearedAt: { [f.owner.uid]: Timestamp.fromMillis(1000) } });
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'not-found' });
  assert.equal(f.calls.length, 0);
});
test('membership removal during signing and revoked sessions fail closed', async () => {
  const f = await setup();
  f.setOnSign(() => f.chat.update({ memberIds: [f.actor.uid] }));
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'permission-denied' });
  await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({ isRevoked: true });
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'unauthenticated' });
});
test('private-profile avatar remains visible, cover requires following, old path and blocked viewer fail', async () => {
  const f = await setup(), avatar = f.locator(`users/${f.owner.uid}/profile.jpg`), cover = f.locator(`users/${f.owner.uid}/cover.jpg`);
  await db.doc(`users/${f.owner.uid}`).set({ profileImageUrl: avatar + '?token=new&v=2', coverImageUrl: cover,
    privacy: { privateAccount: true } }, { merge: true });
  await f.read(callableRequest(f.actor, { url: avatar + '?token=old&v=1' }));
  await assert.rejects(f.read(callableRequest(f.actor, { url: cover })), { code: 'not-found' });
  await assert.rejects(f.read(callableRequest(f.actor, { url: avatar.replace('profile.jpg', 'old.jpg') })), { code: 'not-found' });
  await db.doc(`users/${f.owner.uid}/followers/${f.actor.uid}`).set({});
  await f.read(callableRequest(f.actor, { url: cover }));
  await db.doc(`users/${f.owner.uid}/blocked_accounts/${f.actor.uid}`).set({});
  await assert.rejects(f.read(callableRequest(f.actor, { url: avatar })), { code: 'not-found' });
});
test('signup owner previews require a finalized upload and canonical deletion denies access', async () => {
  const f = await setup(), url = f.locator(`users/${f.owner.uid}/profile.jpg`);
  await f.finalizedPreview(`users/${f.owner.uid}/profile.jpg`);
  await db.doc(`users/${f.owner.uid}`).delete();
  await f.read(callableRequest(f.owner, { url }));
  await db.doc(`account_deletion_requests/${f.owner.uid}`).set({ pending: true });
  await assert.rejects(f.read(callableRequest(f.owner, { url })), { code: 'permission-denied' });
});
test('visible forwarded copy remains readable beyond a page of hidden copies', async () => {
  const f = await setup();
  await f.message.delete();
  const batch = db.batch();
  for (let i = 0; i < 26; i++) batch.set(f.chat.collection('messages').doc(String(i).padStart(2, '0')), {
    type: 'image', imageUrl: f.url, hiddenBy: { [f.owner.uid]: i < 25 },
  });
  await batch.commit();
  await f.read(callableRequest(f.owner, { url: f.url }));
});
test('disabled Auth peer and canonical account freeze prevent new delivery', async () => {
  const f = await setup();
  await auth.updateUser(f.actor.uid, { disabled: true });
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'permission-denied' });
  await auth.updateUser(f.actor.uid, { disabled: false });
  await db.doc(`accountStateControls/${f.owner.uid}`).set({ schemaVersion: 1, revision: 1,
    selfDisabled: false, selfFrozen: true, adminSuspended: false });
  await db.doc(`users/${f.owner.uid}`).update({ 'security.frozen': true });
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'permission-denied' });
  assert.equal(f.calls.length, 0);
});
test('finalized owner post draft preview works before publication, rejects another viewer and deletion race', async () => {
  const f = await setup(), postId = randomUUID(), path = `community_posts/${postId}/images/new.jpg`, url = f.locator(path);
  await f.finalizedPreview(path);
  const post = db.doc(`community_posts/${postId}`);
  await post.set({ authorId: f.owner.uid, status: 'uploading', imageUrls: [] });
  await f.read(callableRequest(f.owner, { url }));
  await assert.rejects(f.read(callableRequest(f.actor, { url })), { code: 'not-found' });
  f.setOnSign(() => db.doc(`postDeletionReceipts/${postId}`).set({}));
  await assert.rejects(f.read(callableRequest(f.owner, { url })));
});
test('post and comment legacy locators preserve membership authorization', async () => {
  const f = await setup(), postId = randomUUID(), post = db.doc(`community_posts/${postId}`);
  const url = f.locator(`community_posts/${postId}/images/p.jpg`) + '?token=old';
  const comment = f.locator(`community_posts/${postId}/comments/${f.owner.uid}/comment/media.jpg`) + '?token=old';
  await post.set({ authorId: f.owner.uid, status: 'published', imageUrls: [url], comments: [
    { id: 'comment', authorId: f.owner.uid, mediaType: 'image', mediaUrl: comment } ] });
  for (const source of [url, comment]) {
    const previous = f.calls.length;
    const result = await f.read(callableRequest(f.actor, { url: source }));
    assert.ok(result.expiresAt <= Date.now() + 120000);
    assert.equal(f.calls.length, previous + 1);
  }
  await post.update({ status: 'removed' });
  await assert.rejects(f.read(callableRequest(f.actor, { url })), { code: 'not-found' });
});
test('wallpaper is restricted to current owner preference and blocks prevent chat delivery', async () => {
  const f = await setup(), wallpaper = f.locator(`chats/${f.chatId}/wallpaper/${f.owner.uid}.jpg`) + '?v=2';
  await f.chat.update({ theme: { [f.owner.uid]: { wallpaper: 'photo', wallpaperUrl: wallpaper } } });
  await f.read(callableRequest(f.owner, { url: wallpaper }));
  await assert.rejects(f.read(callableRequest(f.actor, { url: wallpaper })), { code: 'not-found' });
  await db.doc(`users/${f.actor.uid}/blocked_users/${f.owner.uid}`).set({});
  await assert.rejects(f.read(callableRequest(f.owner, { url: f.url })), { code: 'permission-denied' });
});

test('group photo needs no message, but remains private to active members',async()=>{
 const f=await setup();
 await f.message.delete();
 await f.chat.update({type:'group',photoUrl:f.url});
 await f.read(callableRequest(f.owner,{url:f.url}));
 await assert.rejects(f.read(callableRequest(f.outsider,{url:f.url})),{code:'permission-denied'});
 await f.chat.update({memberIds:[f.actor.uid]});
 await assert.rejects(f.read(callableRequest(f.owner,{url:f.url})),{code:'permission-denied'});
});
