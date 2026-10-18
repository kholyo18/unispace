const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { createContentSearchPageHandler } = require('../security/content-search-page');
function fixture() {
  const records = new Map([['users/viewer', { displayName: 'Viewer' }]]);
  const docs = Array.from({ length: 8 }, (_, n) => {
    records.set('users/author' + n, { displayName: 'Author' });
    const data = { authorId: 'author' + n, body: 'body' + n, createdAt: new Timestamp(100 - n, 0),
      comments: [{ id: 'comment' + n, authorId: 'author' + ((n + 1) % 8), text: 'comment' }] };
    return { id: 'post' + n, data: () => data };
  });
  const snap = path => ({ exists: records.has(path), data: () => records.get(path) });
  const db = { doc: path => ({ path }), runTransaction: async fn => fn({
    get: async ref => snap(ref.path), getAll: async (...refs) => refs.map(ref => snap(ref.path)), set: () => {},
  }), collection: () => { const q = { orderBy: () => q, limit: () => q,
    get: async () => ({ docs, size: docs.length }) }; return q; } };
  const counts = new Map();
  let revoke = false;
  const auth = { verifyIdToken: async (token, checkRevoked) => {
    assert.equal(checkRevoked, true);
    counts.set(token, (counts.get(token) || 0) + 1);
    if (revoke) throw new Error('revoked');
    return { uid: 'viewer', auth_time: 100 };
  }, getUser: async uid => { if (uid === 'author7' && f.revokeOnLastAuthor) revoke = true; return { disabled: false }; } };
  const request = token => ({ auth: { uid: 'viewer' }, rawRequest: { headers: { authorization: 'Bearer ' + token } }, data: { cursor: null } });
  const f = { db, auth, counts, records, request, revokeOnLastAuthor: false };
  return f;
}
test('multiple feed and comment authors share entry verification with a fresh exit', async () => {
  const f = fixture();
  const result = await createContentSearchPageHandler(f, false, true)(f.request('first'));
  assert.equal(result.posts.length, 8);
  assert.equal(result.posts[0].data.comments.length, 1);
  assert.equal(f.counts.get('first'), 2, 'fresh entry shared with interior, fresh exit');
});
test('final fresh token check rejects revocation after interior authorization', async () => {
  const f = fixture(); f.revokeOnLastAuthor = true;
  await assert.rejects(createContentSearchPageHandler(f, false, true)(f.request('revoked')), { code: 'unauthenticated' });
  assert.equal(f.counts.get('revoked'), 2, 'revocation is caught by the fresh exit check');
});
test('parallel invocations and later requests do not share token verification', async () => {
  const f = fixture(), handler = createContentSearchPageHandler(f, false, true);
  await Promise.all([handler(f.request('one')), handler(f.request('two'))]);
  assert.equal(f.counts.get('one'), 2); assert.equal(f.counts.get('two'), 2);
  await handler(f.request('one'));
  assert.equal(f.counts.get('one'), 4);
});

test('rejected entry performs no Firestore work', async () => {
  const f = fixture();
  f.auth.verifyIdToken = async () => { throw Error('revoked'); };
  let reads = 0;
  f.db.runTransaction = async () => { reads++; throw Error('must not read'); };
  await assert.rejects(createContentSearchPageHandler(f, false, true)(f.request('rejected')), {code:'unauthenticated'});
  assert.equal(reads, 0);
});

test('revocation after entry before author reads and failed exit both deny response', async () => {
  for (const failure of ['revoked', 'backend unavailable']) {
    const f = fixture();
    let verifies = 0;
    f.auth.verifyIdToken = async (_, checkRevoked) => {
      assert.equal(checkRevoked, true);
      if (++verifies > 1) throw Error(failure);
      return {uid:'viewer', auth_time:100};
    };
    await assert.rejects(createContentSearchPageHandler(f, false, true)(f.request('token')), {code:'unauthenticated'});
    assert.equal(verifies, 2);
  }
});

test('same-bearer concurrent invocations retain independent entry and exit checks', async () => {
  const f = fixture(), handler = createContentSearchPageHandler(f, false, true);
  await Promise.all([handler(f.request('same')), handler(f.request('same'))]);
  assert.equal(f.counts.get('same'), 4);
});

test('interior revocation cutoff remains fresh despite shared token verification', async () => {
  const f = fixture();
  f.auth.getUser = async () => {
    f.records.set('authRevocations/viewer', {revokedBefore:100});
    return {disabled:false};
  };
  await assert.rejects(createContentSearchPageHandler(f, false, true)(f.request('cutoff')), {code:'unauthenticated'});
  assert.equal(f.counts.get('cutoff'), 1, 'fresh Firestore cutoff rejects before the exit');
});
