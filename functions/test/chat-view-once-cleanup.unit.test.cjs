const test = require('node:test');
const assert = require('node:assert/strict');
const { createChatViewOnceHandlers } = require('../security/chat-view-once');

function fixture(count, { failures = 0, onDelete = () => {}, changed = false } = {}) {
  const docs = new Map();
  const calls = [];
  const pages = [];
  for (let i = 0; i < count; i++) {
    const id = String(i).padStart(24, '0');
    const updateTime = { isEqual: other => other === updateTime };
    docs.set(id, { id, ref: { id }, exists: true, updateTime,
      data: () => ({ state: 'bound', chatId: 'test_chat', generation: '42', path: `chat_view_once/test_chat/${id}` }) });
  }
  function query(cursor = '', limit = 100) {
    return {
      where: (field, op) => { assert.equal(field, 'expiresAt'); assert.equal(op, '<='); return query(cursor, limit); },
      orderBy: field => { assert.equal(field, 'expiresAt'); return query(cursor, limit); },
      startAfter: doc => query(doc.id, limit),
      limit: value => query(cursor, value),
      get: async () => {
        const batch = [...docs.values()].filter(doc => doc.id > cursor).slice(0, limit);
        pages.push(batch.length);
        return { empty: batch.length === 0, size: batch.length, docs: batch };
      },
    };
  }
  const db = { collection: name => { assert.equal(name, 'chatViewOnceAssets'); return query(); },
    runTransaction: fn => fn({ get: async ref => changed ? { ...docs.get(ref.id), updateTime: { isEqual: () => false } } : docs.get(ref.id),
      delete: ref => docs.delete(ref.id) }) };
  const storage = { file: (path, options) => ({ delete: async args => {
    calls.push({ path, options, args });
    onDelete();
    if (Number(path.split('/').at(-1)) < failures) throw Object.assign(new Error('denied'), { code: 403 });
  } }) };
  const handlers = createChatViewOnceHandlers({ db, Timestamp: { now: () => 1000 }, bucket: () => storage });
  return { ...handlers, docs, calls, pages };
}

test('cleanup removes 201 expired photos through three cursor pages', async () => {
  const f = fixture(201);
  assert.deepEqual(await f.cleanup(), { scanned: 201, removed: 201, failed: 0 });
  assert.deepEqual(f.pages, [100, 100, 1]);
  assert.equal(f.docs.size, 0);
  for (const call of f.calls) {
    assert.deepEqual(call.options, { generation: '42' });
    assert.deepEqual(call.args, { ifGenerationMatch: '42' });
  }
});
test('a whole failed first page does not starve later expired assets', async () => {
  const f = fixture(201, { failures: 100 });
  assert.deepEqual(await f.cleanup(), { scanned: 201, removed: 101, failed: 100 });
  assert.equal(f.docs.size, 100);
  assert.deepEqual(f.pages, [100, 100, 1]);
});
test('cleanup is bounded to ten pages and continues remaining work next run', async () => {
  const f = fixture(1001);
  assert.deepEqual(await f.cleanup(), { scanned: 1000, removed: 1000, failed: 0 });
  assert.equal(f.pages.length, 10);
  assert.deepEqual(await f.cleanup(), { scanned: 1, removed: 1, failed: 0 });
});
test('cleanup stops starting new deletions when its time budget expires', async t => {
  let now = 1000;
  t.mock.method(Date, 'now', () => now);
  const f = fixture(201, { onDelete: () => { now += 45000; } });
  assert.deepEqual(await f.cleanup(), { scanned: 2, removed: 2, failed: 0 });
  assert.equal(f.calls.length, 2);
});
test('concurrent metadata changes preserve the ticket update-time guard', async () => {
  const f = fixture(1, { changed: true });
  assert.deepEqual(await f.cleanup(), { scanned: 1, removed: 0, failed: 0 });
  assert.equal(f.docs.size, 1);
});
