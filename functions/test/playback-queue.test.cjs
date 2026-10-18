const {test, after} = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createPlaybackQueue, sourcePaths} = require('../security/playback-queue');
const {playbackObjectPath} = require('../security/playback-variant');
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) throw Error('Local emulator required');
for (const key of ['GCLOUD_PROJECT', 'GOOGLE_CLOUD_PROJECT']) {
  if (process.env[key] && process.env[key] !== 'demo-unispace-security') throw Error('Demo project only');
}
const app = initializeApp({projectId:'demo-unispace-security'}, 'playback-queue-' + randomUUID());
const firestore = getFirestore(app);
after(async () => {await firestore.terminate(); await deleteApp(app);});

async function fixture(count = 1) {
  const postId = 'queue-' + randomUUID(), collection = firestore.collection('testPlaybackQueue' + randomUUID());
  const db = {collection:() => collection, doc:path => firestore.doc(path), runTransaction:fn => firestore.runTransaction(fn)};
  const metadata = new Map(), writes = [], created = [], polled = [];
  const paths = Array.from({length:count}, (_, i) => `community_posts/${postId}/videos/${i}.mp4`);
  const url = path => 'https://firebasestorage.googleapis.com/v0/b/demo/o/' + encodeURIComponent(path) + '?token=secret-original-token';
  for (const path of paths) metadata.set(path, {generation:'42', size:'25000000', contentType:'video/mp4'});
  const post = {status:'published', videoUrls:paths.map(url)}, postRef = firestore.doc('community_posts/' + postId);
  await postRef.set(post);
  const bucket = {name:'demo', file:(path, options) => ({name:path,
    getMetadata:async () => {
      if (!metadata.has(path)) throw Object.assign(Error('missing'), {code:404});
      return [metadata.get(path)];
    },
    setMetadata:async data => {writes.push({path, options, data});},
  })};
  let create = async job => ({name:'projects/demo/locations/test/jobs/' + created.length});
  let get = async () => ({state:'RUNNING'});
  let clock = 1000000;
  const queue = createPlaybackQueue({db, bucket,
    probe:async () => ({durationSeconds:13, width:1080, height:1920, hasAudio:true}),
    createJob:async job => {created.push(job); return create(job);},
    getJob:async name => {polled.push(name); return get(name);}, now:() => clock});
  return {queue, postId, post, postRef, paths, url, metadata, writes, created, polled, collection,
    setCreate:fn => {create = fn;}, setGet:fn => {get = fn;}, advance:(ms = 120001) => {clock += ms;},
    rows:async () => (await collection.get()).docs.map(doc => ({ref:doc.ref, ...doc.data()}))};
}

test('enqueue is idempotent and stores paths instead of source URLs or tokens', async () => {
  const f = await fixture();
  await Promise.all([f.queue.enqueuePost(f.postId, f.post), f.queue.enqueuePost(f.postId, f.post)]);
  const rows = await f.rows(); assert.equal(rows.length, 1);
  assert.equal(rows[0].objectPath, f.paths[0]); assert.equal(rows[0].generation, '42');
  const {ref, ...data} = rows[0];
  assert.equal(JSON.stringify(data).includes('token'), false);
  assert.equal(JSON.stringify(data).includes('https:'), false);
});

test('source comparison ignores likes and URL token changes but detects newly eligible media', async () => {
  const f = await fixture();
  assert.deepEqual(sourcePaths(f.postId, f.post, 'demo'), sourcePaths(f.postId,
    {...f.post, likesCount:20, videoUrls:f.post.videoUrls.map(url => url.replace('secret-original-token', 'rotated'))}, 'demo'));
  assert.deepEqual(sourcePaths(f.postId, {...f.post, status:'uploading'}, 'demo'), []);
  assert.deepEqual(sourcePaths(f.postId, f.post, 'demo'), f.paths);
});

test('membership removed while polling prevents completed output from being finalized', async () => {
  const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post); await f.queue.reconcile();
  f.setGet(async () => {await f.postRef.update({videoUrls:[]}); return {state:'SUCCEEDED'};});
  await f.queue.reconcile();
  assert.equal((await f.rows())[0].status, 'obsolete'); assert.equal(f.writes.length, 0);
});

test('concurrent reconcilers submit one leased job using real Firestore transactions', async () => {
  const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post);
  await Promise.all([f.queue.reconcile(), f.queue.reconcile()]);
  assert.equal(f.created.length, 1);
  assert.equal((await f.rows())[0].status, 'pending');
});

test('missing post and removed membership never submit', async () => {
  for (const missing of [true, false]) {
    const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post);
    if (missing) await f.postRef.delete(); else await f.postRef.update({videoUrls:[]});
    await f.queue.reconcile();
    assert.equal(f.created.length, 0); assert.equal((await f.rows())[0].status, 'obsolete');
  }
});

test('pending successful job finalizes derivative; failed job never stamps', async () => {
  for (const state of ['SUCCEEDED', 'FAILED']) {
    const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post); await f.queue.reconcile();
    f.setGet(async () => ({state}));
    const output = playbackObjectPath('demo', f.paths[0], '42');
    f.metadata.set(output, {generation:'87', metageneration:'1', size:'2500000', contentType:'video/mp4'});
    await f.queue.reconcile();
    assert.equal((await f.rows())[0].status, state === 'SUCCEEDED' ? 'ready' : 'failed');
    assert.equal(f.writes.length, state === 'SUCCEEDED' ? 1 : 0);
  }
});

test('submit errors release leases and stop after three attempts', async () => {
  const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post);
  f.setCreate(async () => {throw Error('transient');});
  for (let i = 0; i < 5; i++) await f.queue.reconcile();
  assert.equal(f.created.length, 3);
  const row = (await f.rows())[0]; assert.equal(row.status, 'failed'); assert.equal(row.leaseUntilMS, 0);
});

test('missing and permanently rejected jobs fail after one poll without resubmission', async () => {
  for (const code of [404, 403, 400]) {
    const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post); await f.queue.reconcile();
    f.setGet(async () => {throw Object.assign(Error('permanent'), {code});});
    await f.queue.reconcile(); await f.queue.reconcile();
    assert.equal((await f.rows())[0].status, 'failed');
    assert.equal(f.polled.length, 1); assert.equal(f.created.length, 1);
  }
});

test('transient and throttled polling failures stop at persisted attempt 36', async () => {
  for (const code of [500, 429]) {
    const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post); await f.queue.reconcile();
    await (await f.rows())[0].ref.update({pollAttempts:34});
    f.setGet(async () => {throw Object.assign(Error('transient'), {code});});
    await f.queue.reconcile();
    assert.equal((await f.rows())[0].status, 'pending');
    await f.queue.reconcile(); await f.queue.reconcile();
    const row = (await f.rows())[0];
    assert.equal(row.status, 'failed'); assert.equal(row.pollAttempts, 36);
    assert.equal(f.polled.length, 2); assert.equal(f.created.length, 1);
  }
});

test('nonterminal jobs expire at the poll budget or three-hour deadline', async () => {
  for (const deadline of [true, false]) {
    const f = await fixture(); await f.queue.enqueuePost(f.postId, f.post); await f.queue.reconcile();
    if (deadline) f.advance(3 * 60 * 60 * 1000);
    else await (await f.rows())[0].ref.update({pollAttempts:35});
    await f.queue.reconcile(); await f.queue.reconcile();
    assert.equal((await f.rows())[0].status, 'failed');
    assert.equal(f.polled.length, deadline ? 0 : 1); assert.equal(f.created.length, 1);
  }
});

test('expired submitting lease retries within persisted budget and each run submits at most four', async () => {
  const f = await fixture(6); await f.queue.enqueuePost(f.postId, f.post);
  const rows = await f.rows();
  await rows[0].ref.update({status:'submitting', attempts:2, leaseUntilMS:999999, leaseId:'crashed'});
  await f.queue.reconcile(); assert.equal(f.created.length, 4);
  await f.queue.reconcile(); assert.equal(f.created.length, 6);
  assert.ok((await f.rows()).every(row => row.status === 'pending' && row.attempts <= 3));
});

test('enqueue excludes removed content, foreign buckets, cross-post and repost media', async () => {
  const f = await fixture();
  for (const patch of [{status:'removed'}, {status:'uploading'}, {status:'failed'},
    {moderation:{status:'removed'}}, {isRepost:true}, {videoUrls:[f.url(f.paths[0]).replace('/b/demo/', '/b/foreign/')]},
    {videoUrls:[f.url('community_posts/other/videos/a.mp4')]}]) {
    await f.queue.enqueuePost(f.postId, {...f.post, ...patch});
  }
  assert.equal((await f.rows()).length, 0);
});

test('poll and nested comment videos are collected only from author-owned comment paths', async () => {
  const f = await fixture(3);
  const commentPath = `community_posts/${f.postId}/comments/author/reply/video.mp4`;
  f.metadata.set(commentPath, f.metadata.get(f.paths[0]));
  await f.queue.enqueuePost(f.postId, {status:'published',
    pollSlides:[{type:'video', url:f.url(f.paths[1])}],
    comments:[{id:'parent', authorId:'author', replies:[{id:'reply', authorId:'author', mediaType:'video', mediaUrl:f.url(commentPath)}]},
      {id:'wrong', authorId:'someone', mediaType:'video', mediaUrl:f.url(f.paths[2])}],
  });
  assert.deepEqual((await f.rows()).map(row => row.objectPath).sort(), [f.paths[1], commentPath].sort());
});
