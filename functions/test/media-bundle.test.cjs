const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createMediaDownloadHandler} = require('../security/media-download');

function fixture() {
  const sources = [0, 1].map(n => 'https://firebasestorage.googleapis.com/v0/b/demo/o/' +
    encodeURIComponent(`community_posts/post/images/${n}.jpg`));
  const records = new Map([
    ['users/viewer', {}], ['users/author', {}],
    ['community_posts/post', {authorId:'author', title:'Before', status:'published', imageUrls:sources}],
  ]);
  let afterSign = () => {};
  let verifications = 0;
  const signs = [], postReads = [], quotaWrites = [];
  const snapshot = path => {
    const value = records.get(path);
    return {id:path.split('/').at(-1), exists:records.has(path), data:() => value};
  };
  const db = {doc:path => ({path, get:async () => {
    if (path === 'community_posts/post') postReads.push(path);
    return snapshot(path);
  }}), runTransaction:async fn => fn({
    get:async ref => snapshot(ref.path),
    getAll:async (...refs) => refs.map(ref => snapshot(ref.path)),
    set:(ref, data) => {quotaWrites.push(ref.path); records.set(ref.path, data);},
  })};
  const auth = {verifyIdToken:async (_, revoked) => {
    verifications++;
    assert.equal(revoked, true); return {uid:'viewer', auth_time:100};
  }, getUser:async () => ({disabled:false})};
  const bucket = () => ({name:'demo', file:path => ({
    getMetadata:async () => [{generation:'42', size:'1000', contentType:'image/jpeg'}],
    getSignedUrl:async options => {
      signs.push({path, options}); await afterSign();
      return ['https://signed.invalid/' + encodeURIComponent(path)];
    },
  })});
  const call = (extra = {}, {batch = true, comment = false, verifyOnly = false} = {}) =>
    createMediaDownloadHandler({auth, db, bucket}, batch, comment, {verifyOnly})({
      auth:{uid:'viewer'}, rawRequest:{headers:{authorization:'Bearer fixture'}},
      data:{postId:'post', ...(batch ? {urls:sources} : {url:sources[0]}),
        ...(comment ? {commentId:'comment'} : {}), ...extra},
    });
  return {sources, records, signs, postReads, quotaWrites, call, verifications:() => verifications,
    mutateAfterSign:fn => {afterSign = fn;}};
}

test('opt-in batch includes final sanitized post with unchanged source order and signing boundary', async () => {
  const f = fixture();
  f.mutateAfterSign(() => f.records.set('community_posts/post', {
    ...f.records.get('community_posts/post'), title:'After', internalSecret:'not projected',
  }));
  const result = await f.call({includePost:true, delivery:'playback'});
  assert.deepEqual(Object.keys(result).sort(), ['items', 'post']);
  assert.equal(result.post.id, 'post'); assert.equal(result.post.data.title, 'After');
  assert.equal(Object.hasOwn(result.post.data, 'internalSecret'), false);
  assert.deepEqual(result.items.map(item => item.source), f.sources);
  assert.deepEqual(f.signs.map(sign => sign.options.queryParams), [{generation:'42'}, {generation:'42'}]);
  assert.equal(f.postReads.length, 2, 'Initial and final fresh post reads remain; bundle adds no third read');
  assert.equal(f.verifications(), 4, 'Each independent post pass verifies entry and exit afresh');
  assert.deepEqual(f.quotaWrites, ['contentSearchLimits/viewer', 'contentSearchLimits/viewer']);
});

test('legacy batch and single delivery responses remain unchanged', async () => {
  const f = fixture();
  assert.deepEqual(Object.keys(await f.call()), ['items']);
  assert.deepEqual(Object.keys(await f.call({}, {batch:false})).sort(), ['expiresAt', 'url']);
});

test('includePost is strictly true, batch-only, and rejects extra request keys', async () => {
  for (const includePost of [false, null, 1, 'true', {}, []]) {
    await assert.rejects(fixture().call({includePost}), {code:'invalid-argument'});
  }
  for (const options of [{batch:false}, {batch:false, comment:true}, {batch:false, comment:true, verifyOnly:true}]) {
    const f = fixture();
    await assert.rejects(f.call({includePost:true}, options), {code:'invalid-argument'});
    assert.equal(f.postReads.length, 0);
  }
  await assert.rejects(fixture().call({includePost:true, unexpected:true}), {code:'invalid-argument'});
});

test('bundle denies membership, blocking, private-account and revocation changes during signing', async () => {
  for (const mode of ['membership', 'block', 'private', 'revocation']) {
    const f = fixture();
    f.mutateAfterSign(() => {
      if (mode === 'membership') f.records.set('community_posts/post', {
        ...f.records.get('community_posts/post'), imageUrls:[],
      });
      if (mode === 'block') f.records.set('users/author/blocked_accounts/viewer', {});
      if (mode === 'private') f.records.set('users/author', {privacy:{privateAccount:true}});
      if (mode === 'revocation') f.records.set('authRevocations/viewer', {revokedBefore:100});
    });
    await assert.rejects(f.call({includePost:true}), {code:mode === 'membership' ? 'permission-denied'
      : mode === 'revocation' ? 'unauthenticated' : 'not-found'});
    assert.equal(f.signs.length, 2);
  }
});

test('bundle rejects removed or foreign source before signing', async () => {
  for (const source of ['https://firebasestorage.googleapis.com/v0/b/demo/o/unrelated',
    'https://firebasestorage.googleapis.com/v0/b/foreign/o/community_posts%2Fpost%2Fa.jpg']) {
    const f = fixture();
    if (source.includes('/b/foreign/')) f.records.get('community_posts/post').imageUrls = [source];
    await assert.rejects(f.call({includePost:true, urls:[source]}), {
      code:source.includes('/b/foreign/') ? 'invalid-argument' : 'permission-denied',
    });
    assert.equal(f.signs.length, 0);
  }
});
