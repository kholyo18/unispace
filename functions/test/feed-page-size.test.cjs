const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { createContentSearchPageHandler } = require('../security/content-search-page');

function fixture() {
  const records = new Map([['users/viewer', {}], ['users/owner', {}]]);
  const docs = Array.from({ length: 40 }, (_, index) => ({
    id: 'post' + String(index).padStart(2, '0'),
    data: () => ({ authorId: 'owner', createdAt: new Timestamp(100 - index, 0),
      status: index < 8 && f.hideFirstPage ? 'removed' : 'published', comments: [] }),
  }));
  const limits = [];
  const snapshot = path => ({ exists: records.has(path), data: () => records.get(path) });
  const db = { doc: path => ({ path }), runTransaction: async fn => fn({
    get: async ref => snapshot(ref.path), getAll: async (...refs) => refs.map(ref => snapshot(ref.path)), set: () => {},
  }), collection: () => {
    let count = 25, start = 0;
    const query = { where: () => query, orderBy: () => query,
      startAfter: (timestamp, id) => {
        start = docs.findIndex(doc => doc.id === id && doc.data().createdAt.isEqual(timestamp)) + 1;
        assert.ok(start > 0, 'cursor must identify a raw document'); return query;
      },
      limit: value => { count = value; limits.push(value); return query; },
      get: async () => { const selected = docs.slice(start, start + count); return { docs: selected, size: selected.length }; },
    }; return query;
  } };
  const auth = { verifyIdToken: async () => ({ uid: 'viewer', auth_time: 100 }), getUser: async () => ({ disabled: false }) };
  const run = (data, mode = true) => createContentSearchPageHandler({ auth, db }, false, mode)({
    auth: { uid: 'viewer' }, rawRequest: { headers: { authorization: 'Bearer fixture' } }, data,
  });
  const f = { run, limits, hideFirstPage: false };
  return f;
}

test('default feed stays 25; initial eight and later 25 preserve cursor order', async () => {
  const f = fixture();
  assert.equal((await f.run({ cursor: null })).posts.length, 25);
  const first = await f.run({ cursor: null, pageSize: 8 });
  assert.equal(first.posts.length, 8); assert.equal(first.exhausted, false);
  assert.equal(first.authorAccessRechecked, true); assert.equal(first.cursor.id, 'post07');
  const next = await f.run({ cursor: first.cursor });
  assert.deepEqual(next.posts.map(post => post.id), Array.from({ length: 25 }, (_, n) => 'post' + String(n + 8).padStart(2, '0')));
  const last = await f.run({ cursor: next.cursor });
  assert.equal(last.posts.length, 7); assert.equal(last.exhausted, true);
  assert.deepEqual(f.limits, [25, 8, 25, 25]);
});

test('fully filtered initial page is not exhausted and advances from last raw document', async () => {
  const f = fixture(); f.hideFirstPage = true;
  const first = await f.run({ cursor: null, pageSize: 8 });
  assert.deepEqual(first.posts, []); assert.equal(first.exhausted, false);
  assert.equal(first.cursor.id, 'post07'); assert.equal(first.authorAccessRechecked, true);
  const next = await f.run({ cursor: first.cursor });
  assert.equal(next.posts[0].id, 'post08'); assert.equal(next.posts.length, 25);
});

test('page size accepts inclusive limits and rejects invalid values or extra fields', async () => {
  const f = fixture();
  for (const pageSize of [1, 25]) assert.equal((await f.run({ cursor: null, pageSize })).posts.length, pageSize);
  for (const pageSize of [0, -1, 26, 1.5, '8', null, true, {}, []]) {
    await assert.rejects(f.run({ cursor: null, pageSize }), { code: 'invalid-argument' });
  }
  for (const input of [{ cursor: null, unknown: 8 }, { cursor: null, pageSize: 8, extra: true }, { pageSize: 8 }]) {
    await assert.rejects(f.run(input), { code: 'invalid-argument' });
  }
});

test('profile and reaction request contracts reject pageSize', async () => {
  const f = fixture();
  await assert.rejects(f.run({ cursor: null, userId: 'owner', pageSize: 8 }, 'profile'), { code: 'invalid-argument' });
  await assert.rejects(f.run({ cursor: null, reaction: 'like', pageSize: 8 }, 'reactions'), { code: 'invalid-argument' });
});
