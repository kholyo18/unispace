const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { createContentSearchPageHandler } = require('../security/content-search-page');

function fixture() {
  const records = new Map([['users/viewer', {}], ['users/owner', {}]]);
  const comments = Array.from({ length: 12 }, (_, n) => {
    records.set('users/commenter' + n, {});
    return { id: 'c' + n, authorId: 'commenter' + n, text: 'Comment ' + n };
  });
  const data = { authorId: 'owner', createdAt: new Timestamp(100, 0), comments };
  const snap = path => ({ exists: records.has(path), data: () => records.get(path) });
  const db = {
    doc: path => ({ path }),
    runTransaction: async fn => fn({ get: async ref => snap(ref.path),
      getAll: async (...refs) => refs.map(ref => snap(ref.path)), set: () => {} }),
    collection: () => { const q = { orderBy: () => q, limit: () => q,
      get: async () => ({ docs: [{ id: 'post', data: () => data }], size: 1 }) }; return q; },
  };
  const checked = [];
  let active = 0, maximum = 0;
  const auth = { verifyIdToken: async () => ({ uid: 'viewer', auth_time: 100 }),
    getUser: async uid => {
      checked.push(uid);
      if (uid.startsWith('commenter')) {
        active++; maximum = Math.max(maximum, active);
        await new Promise(resolve => setImmediate(resolve));
        active--;
      }
      return { disabled: false };
    } };
  const run = () => createContentSearchPageHandler({ auth, db }, false, true)({
    auth: { uid: 'viewer' }, rawRequest: { headers: { authorization: 'Bearer fixture' } }, data: { cursor: null },
  });
  return { records, data, checked, auth, run, maximum: () => maximum };
}

test('sibling comment author reads overlap within four and preserve order', async () => {
  const f = fixture(), result = await f.run();
  assert.ok(f.maximum() > 1, 'independent comment author reads must overlap');
  assert.ok(f.maximum() <= 4);
  assert.deepEqual(result.posts[0].data.comments.map(c => c.id), Array.from({ length: 12 }, (_, n) => 'c' + n));
});

test('hidden, removed and blocked comments stay absent; nested replies keep order', async () => {
  const f = fixture();
  f.data.moderation = { hiddenCommentIds: ['c0'] };
  f.data.comments[1].status = 'removed';
  f.records.set('users/viewer/blocked_accounts/commenter2', {});
  f.data.comments[3].replies = [{ id: 'r1', authorId: 'commenter4', text: 'First' },
    { id: 'r2', authorId: 'commenter5', text: 'Second' }];
  const result = await f.run(), comments = result.posts[0].data.comments;
  assert.deepEqual(comments.map(c => c.id), Array.from({ length: 9 }, (_, n) => 'c' + (n + 3)));
  assert.deepEqual(comments[0].replies.map(c => c.id), ['r1', 'r2']);
  assert.equal(f.checked.includes('commenter0'), false);
  assert.equal(f.checked.includes('commenter1'), false);
  assert.equal(f.checked.filter(uid => uid === 'commenter4').length, 1);
});

test('revocation during parallel comment reads denies the response', async () => {
  const f = fixture(), getUser = f.auth.getUser;
  f.auth.getUser = async uid => {
    const user = await getUser(uid);
    if (uid === 'commenter11') f.records.set('authRevocations/viewer', { revokedBefore: 100 });
    return user;
  };
  await assert.rejects(f.run(), { code: 'unauthenticated' });
});
