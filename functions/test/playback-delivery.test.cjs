const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createMediaDownloadHandler} = require('../security/media-download');
const {playbackObjectPath} = require('../security/playback-variant');

function fixture() {
  const sourcePath = 'community_posts/post/videos/original.mp4';
  const source = 'https://firebasestorage.googleapis.com/v0/b/demo/o/' + encodeURIComponent(sourcePath);
  const records = new Map([
    ['users/viewer', {displayName:'Viewer'}],
    ['users/author', {displayName:'Author'}],
    ['community_posts/post', {authorId:'author', status:'published', videoUrls:[source]}],
  ]);
  const snapshot = path => ({exists:records.has(path), data:() => records.get(path)});
  const db = {
    doc:path => ({path, get:async () => snapshot(path)}),
    runTransaction:async fn => fn({
      get:async ref => snapshot(ref.path),
      getAll:async (...refs) => refs.map(ref => snapshot(ref.path)),
      set:() => {},
    }),
  };
  const auth = {
    verifyIdToken:async (_, checkRevoked) => {
      assert.equal(checkRevoked, true);
      return {uid:'viewer', auth_time:100};
    },
    getUser:async () => ({disabled:false}),
  };
  const original = {generation:'42', size:'25000000', contentType:'video/mp4'};
  const metadata = new Map([[sourcePath, original]]), reads = [], signs = [];
  let afterSign = () => {};
  const bucket = () => ({name:'demo', file:path => ({
    getMetadata:async () => {
      reads.push(path);
      if (!metadata.has(path)) throw Object.assign(new Error('Missing'), {code:404});
      return [metadata.get(path)];
    },
    getSignedUrl:async options => {
      signs.push({path, options});
      await afterSign();
      return ['https://signed.invalid/' + encodeURIComponent(path)];
    },
  })});
  const request = data => ({auth:{uid:'viewer'}, rawRequest:{headers:{authorization:'Bearer fixture'}}, data});
  const call = (extra = {}, batch = false, comment = false, verifyOnly = false) =>
    createMediaDownloadHandler({auth, db, bucket}, batch, comment, {verifyOnly})(request({
      postId:'post', ...(batch ? {urls:[source]} : {url:source}), ...extra,
    }));
  return {sourcePath, source, original, metadata, reads, signs, records, call,
    mutateAfterSign:fn => {afterSign = fn;}};
}

test('omitted delivery preserves original download and does no variant lookup', async () => {
  const f = fixture();
  await f.call();
  assert.deepEqual(f.reads, [f.sourcePath]);
  assert.equal(f.signs[0].path, f.sourcePath);
  assert.deepEqual(f.signs[0].options.queryParams, {generation:'42'});
});

test('playback without a variant falls back to original generation', async () => {
  const f = fixture();
  const result = await f.call({delivery:'playback'}, true);
  assert.equal(result.items[0].source, f.source);
  assert.equal(f.signs[0].path, f.sourcePath);
  assert.deepEqual(f.signs[0].options.queryParams, {generation:'42'});
});

function addVariant(f) {
  const path = playbackObjectPath('demo', f.sourcePath, '42');
  f.metadata.set(path, {generation:'87', size:'2500000', contentType:'video/mp4',
    metadata:{sourceGeneration:'42', sourceObject:f.sourcePath}});
  return path;
}

test('playback selects verified derivative and pins its generation while preserving batch source', async () => {
  const f = fixture(), path = addVariant(f);
  const result = await f.call({delivery:'playback'}, true);
  assert.deepEqual(f.reads, [f.sourcePath, path]);
  assert.equal(result.items[0].source, f.source);
  assert.equal(result.items[0].url, 'https://signed.invalid/' + encodeURIComponent(path));
  assert.equal(f.signs[0].path, path);
  assert.deepEqual(f.signs[0].options.queryParams, {generation:'87'});
  f.reads.length = 0;
  await f.call();
  assert.deepEqual(f.reads, [f.sourcePath]);
  assert.equal(f.signs[1].path, f.sourcePath);
  assert.deepEqual(f.signs[1].options.queryParams, {generation:'42'});
});

test('unverified derivative falls back without signing candidate bytes', async () => {
  for (const key of ['sourceGeneration', 'sourceObject']) {
    const f = fixture(), path = addVariant(f);
    f.metadata.get(path).metadata[key] = 'other';
    await f.call({delivery:'playback'});
    assert.equal(f.signs[0].path, f.sourcePath);
  }
});

test('comment playback keeps original author-owned comment path validation', async () => {
  const f = fixture(), commentId = 'comment';
  const path = 'community_posts/post/comments/author/comment/video.mp4';
  const url = f.source.replace(encodeURIComponent(f.sourcePath), encodeURIComponent(path));
  f.metadata.set(path, f.original);
  f.records.get('community_posts/post').comments = [{id:commentId, authorId:'author', mediaType:'video', mediaUrl:url}];
  const derived = playbackObjectPath('demo', path, '42');
  f.metadata.set(derived, {generation:'88', size:'2500000', contentType:'video/mp4',
    metadata:{sourceGeneration:'42', sourceObject:path}});
  const result = await f.call({delivery:'playback', commentId, url}, false, true);
  assert.equal(result.mediaType, 'video');
  assert.equal(f.signs[0].path, derived);
  assert.deepEqual(f.signs[0].options.queryParams, {generation:'88'});
  f.records.get('community_posts/post').comments[0].mediaUrl = f.source;
  await assert.rejects(f.call({delivery:'playback', commentId}, false, true), {code:'invalid-argument'});
  assert.equal(f.signs.length, 1);
});

test('playback cannot bypass source membership, bucket, or viewer revocation', async () => {
  for (const mode of ['membership', 'bucket', 'revocation']) {
    const f = fixture();
    let url = f.source;
    if (mode === 'membership') url += '?different=true';
    if (mode === 'bucket') {
      url = f.source.replace('/b/demo/', '/b/foreign/');
      f.records.get('community_posts/post').videoUrls = [url];
    }
    if (mode === 'revocation') f.records.set('authRevocations/viewer', {revokedBefore:100});
    await assert.rejects(f.call({delivery:'playback', url}), {
      code:mode === 'membership' ? 'permission-denied' : mode === 'bucket' ? 'invalid-argument' : 'unauthenticated',
    });
    assert.equal(f.signs.length, 0);
    assert.equal(f.reads.length, 0);
  }
});

test('playback rechecks membership and revocation after signing', async () => {
  for (const mode of ['membership', 'revocation']) {
    const f = fixture();
    addVariant(f);
    f.mutateAfterSign(() => mode === 'membership'
      ? f.records.get('community_posts/post').videoUrls = []
      : f.records.set('authRevocations/viewer', {revokedBefore:100}));
    await assert.rejects(f.call({delivery:'playback'}), {
      code:mode === 'membership' ? 'permission-denied' : 'unauthenticated',
    });
    assert.equal(f.signs.length, 1);
  }
});

test('delivery is optional playback only and is forbidden in access-only mode', async () => {
  for (const delivery of ['original', 'download', null, true, {}]) {
    await assert.rejects(fixture().call({delivery}), {code:'invalid-argument'});
  }
  await assert.rejects(fixture().call({delivery:'playback', commentId:'comment'}, false, true, true),
    {code:'invalid-argument'});
  await assert.rejects(fixture().call({delivery:'playback', unexpected:true}), {code:'invalid-argument'});
});
