const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { createContentSearchPageHandler } = require('../security/content-search-page');

function fixture({ repost = false, mode = true, empty = false } = {}) {
  const records = new Map([['users/viewer', {}], ['users/owner', {}],
    ['users/originalOwner', {}], ['users/ancestorOwner', {}]]);
  const data = { authorId: 'owner', createdAt: new Timestamp(100, 0), comments: [] };
  if (repost) {
    data.repostOf = { postId: 'original' };
    records.set('community_posts/original', { authorId: 'originalOwner',
      repostOf: { postId: 'ancestor' }, createdAt: new Timestamp(90, 0), comments: [] });
    records.set('community_posts/ancestor', { authorId: 'ancestorOwner',
      createdAt: new Timestamp(80, 0), comments: [] });
  }
  const snapshot = path => {
    const value = records.get(path);
    return { id: path.split('/').at(-1), exists: records.has(path), data: () => value };
  };
  const reads = new Map(), checks = [];
  let afterRead = () => {}, getUserHook = () => {};
  const db = { doc: path => ({ path, get: async () => snapshot(path) }),
    runTransaction: async fn => fn({ get: async ref => snapshot(ref.path), set: () => {},
      getAll: async (...refs) => {
        const result = refs.map(ref => snapshot(ref.path));
        const target = refs[1].path;
        reads.set(target, (reads.get(target) || 0) + 1);
        afterRead(target, reads.get(target));
        return result;
      } }),
    collection: () => { const q = { where: () => q, orderBy: () => q, limit: () => q,
      get: async () => ({ docs: empty ? [] : [{ id: 'post', data: () => data }], size: empty ? 0 : 1 }) }; return q; },
  };
  const auth = {
    verifyIdToken: async () => { checks.push('token'); return { uid: 'viewer', auth_time: 100 }; },
    getUser: async uid => { await getUserHook(uid); return { disabled: false }; },
  };
  const run = () => createContentSearchPageHandler({ auth, db }, false, mode)({ auth: { uid: 'viewer' },
    rawRequest: { headers: { authorization: 'Bearer fixture' } },
    data: { cursor: null, ...(mode === 'profile' ? { userId: 'owner' } : {}) } });
  return { records, reads, checks, run, afterRead: fn => { afterRead = fn; },
    getUserHook: fn => { getUserHook = fn; } };
}

test('feed omits an author that becomes private after projection and retains cursor', async () => {
  const f = fixture();
  f.afterRead((path, count) => {
    if (path === 'users/owner' && count === 1) f.records.set(path, { privacy: { privateAccount: true } });
  });
  const result = await f.run();
  assert.deepEqual(result.posts, []);
  assert.equal(result.cursor.id, 'post');
  assert.equal(result.exhausted, true);
  assert.equal(result.authorAccessRechecked, true);
  assert.equal(f.reads.get('users/owner'), 2);
  assert.equal(f.checks.length, 2, 'fresh entry shared with interior, fresh exit');
});

test('feed omits newly blocked author and nested repost ancestor', async () => {
  for (const target of ['owner', 'originalOwner', 'ancestorOwner']) {
    const f = fixture({ repost: true });
    f.afterRead((path, count) => {
      if (path === 'users/' + target && count === 1) f.records.set('users/' + target + '/blocked_accounts/viewer', {});
    });
    assert.deepEqual((await f.run()).posts, [], target + ' must hide entire repost');
    assert.equal(f.reads.get('users/' + target), 2);
  }
});

test('approved private author remains visible after final refresh', async () => {
  const f = fixture();
  f.records.set('users/owner', { privacy: { privateAccount: true } });
  f.records.set('users/owner/followers/viewer', {});
  const result = await f.run();
  assert.equal(result.posts.length, 1);
  assert.equal(result.posts[0].data.authorPrivate, true);
  assert.equal(result.authorAccessRechecked, true);
  assert.equal(f.reads.get('users/owner'), 2);
});

test('empty fresh feed advertises boundary; profile feed does not', async () => {
  assert.equal((await fixture({ empty: true }).run()).authorAccessRechecked, true);
  const legacy = await fixture({ mode: 'profile' }).run();
  assert.equal(Object.hasOwn(legacy, 'authorAccessRechecked'), false);
  assert.equal(legacy.posts.length, 1);
});

test('availability failures during fresh author read propagate and final viewer revocation remains enforced', async () => {
  const unavailable = fixture();
  let ownerChecks = 0;
  unavailable.getUserHook(uid => {
    if (uid === 'owner' && ++ownerChecks === 2) throw new Error('backend unavailable');
  });
  await assert.rejects(unavailable.run(), { code: 'unavailable' });
  const revoked = fixture();
  revoked.afterRead((path, count) => {
    if (path === 'users/owner' && count === 2) revoked.records.set('authRevocations/viewer', { revokedBefore: 100 });
  });
  await assert.rejects(revoked.run(), { code: 'unauthenticated' });
  assert.equal(revoked.checks.length, 2);
});
