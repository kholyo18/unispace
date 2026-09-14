const {test, after} = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createMediaDownloadHandler} = require('../security/media-download');

const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local Firestore emulator required');
const project = 'demo-unispace-security';
for (const key of ['GCLOUD_PROJECT', 'GOOGLE_CLOUD_PROJECT']) {
  if (process.env[key] && process.env[key] !== project) throw Error('Only demo-unispace-security is allowed');
}
const app = initializeApp({projectId:project}, 'media-authorization-tests'), db = getFirestore(app);
after(async () => { await db.terminate(); await deleteApp(app); });
const unique = () => randomUUID().replaceAll('-', '');
const mediaUrl = (path, bucket = 'demo-media') => 'https://firebasestorage.googleapis.com/v0/b/' + bucket + '/o/' + encodeURIComponent(path) + '?alt=media&token=legacy';
async function setup() {
  const uid = 'media-viewer-' + unique(), author = 'media-author-' + unique(), postId = unique();
  await db.doc('users/' + uid).set({displayName:'Viewer'});
  await db.doc('users/' + author).set({displayName:'Author'});
  const path = 'community_posts/' + postId + '/images/photo.jpg', url = mediaUrl(path);
  const ref = db.doc('community_posts/' + postId);
  await ref.set({authorId:author, status:'published', imageUrls:[url]});
  const auth = {verifyIdToken:async (token, checkRevoked) => {
    assert.equal(checkRevoked, true); return {uid:token, auth_time:100};
  }, getUser:async () => ({disabled:false})};
  const calls = [];
  let afterSign;
  const bucket = () => ({name:'demo-media', file:objectPath => ({
    getMetadata:async () => { calls.push({kind:'metadata', objectPath}); return [{generation:'42', size:'1024'}]; },
    getSignedUrl:async options => {
      calls.push({kind:'sign', objectPath, options});
      if (afterSign) await afterSign();
      return ['https://signed.example.invalid/' + encodeURIComponent(objectPath)];
    },
  })});
  const request = data => ({auth:{uid}, rawRequest:{headers:{authorization:'Bearer ' + uid}}, data});
  const handler = createMediaDownloadHandler({auth, db, bucket});
  const comment = createMediaDownloadHandler({auth, db, bucket}, false, true);
  const verify = createMediaDownloadHandler({auth, db, bucket}, false, true, {verifyOnly:true});
  return {uid, author, postId, path, url, ref, auth, bucket, calls, request, handler, comment, verify,
    mutateAfterSign:fn => { afterSign = fn; }, call:() => handler(request({postId, url}))};
}

test('authorized media is signed for the inspected object generation with a bounded expiry', async () => {
  const f = await setup(), before = Date.now(), result = await f.call();
  assert.match(result.url, /^https:\/\/signed\.example\.invalid\//);
  assert.ok(result.expiresAt >= before + 299000 && result.expiresAt <= Date.now() + 300000);
  assert.deepEqual(f.calls.map(x => x.kind), ['metadata', 'sign']);
  assert.equal(f.calls[1].objectPath, f.path);
  assert.deepEqual(f.calls[1].options.queryParams, {generation:'42'});
  assert.equal(f.calls[1].options.version, 'v4');
  assert.equal(f.calls[1].options.action, 'read');
});

test('private content needs owner-side acceptance; forged following mirror grants nothing', async () => {
  const f = await setup();
  await db.doc('users/' + f.author).set({privacy:{privateAccount:true}}, {merge:true});
  await db.doc(`users/${f.uid}/following/${f.author}`).set({uid:f.author});
  await assert.rejects(f.call(), {code:'not-found'});
  assert.equal(f.calls.length, 0);
  await db.doc(`users/${f.author}/followers/${f.uid}`).set({uid:f.uid});
  await f.call();
  assert.equal(f.calls.filter(x => x.kind === 'sign').length, 1);
});

test('both directions of blocking deny media before Storage is contacted', async () => {
  for (const reverse of [false, true]) {
    const f = await setup(), owner = reverse ? f.author : f.uid, target = reverse ? f.uid : f.author;
    await db.doc(`users/${owner}/blocked_accounts/${target}`).set({uid:target});
    await assert.rejects(f.call(), {code:'not-found'});
    assert.equal(f.calls.length, 0);
  }
});

test('removed posts, deleted authors and deleted source documents cannot issue URLs', async () => {
  for (const mode of ['removed', 'deleted-author', 'missing-post']) {
    const f = await setup();
    if (mode === 'removed') await f.ref.update({moderation:{status:'removed'}});
    if (mode === 'deleted-author') await db.doc('users/' + f.author).update({accountStatus:'deleted'});
    if (mode === 'missing-post') await f.ref.delete();
    await assert.rejects(f.call(), {code:'not-found'});
    assert.equal(f.calls.length, 0);
  }
});

test('exact membership and configured bucket are both required', async () => {
  const f = await setup();
  await assert.rejects(f.handler(f.request({postId:f.postId, url:f.url.replace('legacy', 'different')})), {code:'permission-denied'});
  const foreign = mediaUrl(f.path, 'foreign-bucket');
  await f.ref.update({imageUrls:[foreign]});
  await assert.rejects(f.handler(f.request({postId:f.postId, url:foreign})), {code:'invalid-argument'});
  assert.equal(f.calls.length, 0);
});

test('membership removal and a new block during signing prevent URL disclosure', async () => {
  for (const mode of ['membership', 'block']) {
    const f = await setup();
    f.mutateAfterSign(() => mode === 'membership'
      ? f.ref.update({imageUrls:[]})
      : db.doc(`users/${f.author}/blocked_accounts/${f.uid}`).set({uid:f.uid}));
    await assert.rejects(f.call(), {code:mode === 'membership' ? 'permission-denied' : 'not-found'});
    assert.equal(f.calls.filter(x => x.kind === 'sign').length, 1);
  }
});

test('comment access-only mode validates membership and ownership path without signing', async () => {
  const f = await setup(), commentId = 'comment-one';
  const url = mediaUrl(`community_posts/${f.postId}/comments/${f.author}/${commentId}/video.mp4`);
  await f.ref.update({comments:[{id:commentId, authorId:f.author, mediaType:'video', mediaUrl:url}]});
  assert.deepEqual(await f.verify(f.request({postId:f.postId, commentId, url})),
    {authorized:true, postId:f.postId, commentId, source:url, mediaType:'video'});
  assert.equal(f.calls.length, 0);
  const wrong = mediaUrl(`community_posts/${f.postId}/comments/another/${commentId}/video.mp4`);
  await f.ref.update({comments:[{id:commentId, authorId:f.author, mediaType:'video', mediaUrl:wrong}]});
  await assert.rejects(f.verify(f.request({postId:f.postId, commentId, url:wrong})), {code:'invalid-argument'});
  assert.equal(f.calls.length, 0);
});

test('flat replies beneath a hidden or missing ancestor cannot expose comment media', async () => {
  for (const hidden of [true, false]) {
    const f = await setup(), commentId = 'reply';
    const url = mediaUrl(`community_posts/${f.postId}/comments/${f.author}/${commentId}/photo.jpg`);
    const child = {id:commentId, authorId:f.author, replyToId:'parent', mediaType:'image', mediaUrl:url};
    await f.ref.update({comments:hidden ? [{id:'parent', authorId:f.author}, child] : [child],
      moderation:{hiddenCommentIds:hidden ? ['parent'] : []}});
    await assert.rejects(f.comment(f.request({postId:f.postId, commentId, url})), {code:'permission-denied'});
    assert.equal(f.calls.length, 0);
  }
});

test('repost media authorization follows current original privacy', async () => {
  const f = await setup(), repostId = unique();
  await db.doc('community_posts/' + repostId).set({authorId:f.uid, isRepost:true, repostOf:{postId:f.postId}});
  const data = {postId:repostId, url:f.url};
  await f.handler(f.request(data));
  await db.doc('users/' + f.author).update({privacy:{privateAccount:true}});
  await assert.rejects(f.handler(f.request(data)), {code:'not-found'});
  assert.equal(f.calls.filter(x => x.kind === 'sign').length, 1);
});
