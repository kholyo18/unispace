const test = require('node:test');
const assert = require('node:assert/strict');
const { createProtectedUploadCleanup } = require('../security/protected-upload-cleanup');
function fixture(count = 1, { failFirst = 0, delay = 0 } = {}) {
  let clock = 2000000000000, cursor = null;
  const entries = new Map(), calls = [], listings = [];
  for (let i = 0; i < count; i++) {
    const name = `private_upload_staging/alice/${String(i).padStart(20, '0')}`;
    entries.set(name, { name, metadata: { generation: String(i + 1), timeCreated: new Date(clock - 86400001).toISOString() } });
  }
  const db = { doc: name => { assert.equal(name, 'maintenanceCursors/protectedUploadStaging'); return { name }; },
    runTransaction: async fn => fn({ get: async () => ({ data: () => cursor }), set: (_, value) => { cursor = value; } }) };
  const bucket = { getFiles: async options => {
    listings.push(options);
    assert.equal(options.prefix, 'private_upload_staging/'); assert.equal(options.autoPaginate, false); assert.equal(options.maxResults, 100);
    const candidates = [...entries.values()].filter(f => !options.pageToken || f.name > options.pageToken).sort((a, b) => a.name.localeCompare(b.name));
    const files = candidates.slice(0, options.maxResults);
    return [files, candidates.length > files.length ? { pageToken: files.at(-1).name } : null];
  }, file: (name, options) => ({ delete: async args => {
    calls.push({ name, options, args }); clock += delay;
    const entry = entries.get(name);
    assert.equal(options.generation, entry.metadata.generation);
    assert.equal(args.ifGenerationMatch, entry.metadata.generation);
    if (Number(name.split('/').at(-1)) < failFirst) throw Object.assign(Error('denied'), { code: 403 });
    entries.delete(name);
  } }) };
  return { cleanup: createProtectedUploadCleanup({ db, bucket, now: () => clock }), entries, calls, listings,
    cursor: () => cursor, setCursor: value => { cursor = value; }, now: () => clock };
}
test('cleanup only deletes strict staging paths older than24hours with pinned generations', async () => {
  const f = fixture(1);
  for (const [name, meta] of [
    ['users/alice/avatar.jpg', { generation: '22', timeCreated: new Date(1).toISOString() }],
    ['private_upload_staging/alice/invalid', { generation: '23', timeCreated: new Date(1).toISOString() }],
    ['private_upload_staging/alice/11111111111111111111', { generation: '24', timeCreated: new Date(f.now() - 1000).toISOString() }],
    ['private_upload_staging/alice/22222222222222222222', { generation: '25', timeCreated: 'invalid' }],
  ]) f.entries.set(name, { name, metadata: meta });
  const result = await f.cleanup();
  assert.equal(result.removed, 1); assert.equal(result.skipped, 4);
  assert.equal(f.calls.length, 1); assert.equal(f.cursor().leaseUntilMs, 0);
});
test('failed first1000objects do not starve a later page on next scheduled run', async () => {
  const f = fixture(1001, { failFirst: 1000 });
  const first = await f.cleanup();
  assert.equal(first.pages, 10); assert.equal(first.failed, 1000); assert.ok(f.cursor().pageToken);
  const second = await f.cleanup();
  assert.equal(second.removed, 1); assert.equal(second.failed, 0); assert.equal(second.pages, 1);
  assert.equal(f.cursor().pageToken, null);
});
test('deadline checkpoint resumes within a page without redoing failed early objects', async () => {
  const f = fixture(4, { failFirst: 2, delay: 45000 });
  const first = await f.cleanup(); assert.equal(first.failed, 2); assert.equal(first.scanned, 2);
  assert.ok(f.cursor().lastName.endsWith('00000000000000000001'));
  const second = await f.cleanup(); assert.equal(second.removed, 2); assert.equal(second.failed, 0);
  assert.equal(f.calls.length, 4);
});
test('an active server lease prevents overlapping cleanup runs', async () => {
  const f = fixture(); f.setCursor({ leaseToken: 'other', leaseUntilMs: f.now() + 60000 });
  const result = await f.cleanup(); assert.equal(result.busy, true); assert.equal(f.listings.length, 0);
});
test('missing or invalid generation is skipped without unguarded deletion', async () => {
  const f = fixture(); [...f.entries.values()][0].metadata.generation = 'invalid';
  assert.equal((await f.cleanup()).skipped, 1); assert.equal(f.calls.length, 0);
});
test('partial page completion releases the lease and preserves retryable failures', async () => {
  const f = fixture(3, { failFirst: 1 });
  const result = await f.cleanup(); assert.equal(result.failed, 1); assert.equal(result.removed, 2);
  assert.equal(f.entries.size, 1); assert.equal(f.cursor().leaseToken, null);
});

test('installed GCS File.copy sends flat standard metadata and nested custom metadata to rewrite API', async () => {
  const { Storage } = require('@google-cloud/storage');
  const storage = new Storage({ projectId: 'demo-protected-upload-contract' });
  const bucket = storage.bucket('local-contract-bucket');
  const source = bucket.file('private_upload_staging/alice/12345678901234567890', { generation: '123' });
  let request;
  // Intercept the installed SDK's HTTP boundary, not a substitute copy API.
  source.request = (options, callback) => { request = options; callback(null, { done: true, resource: { generation: '456' } }); };
  await source.copy(bucket.file('users/alice/avatar.jpg'), { contentType: 'image/jpeg', cacheControl: 'private, no-store',
    metadata: { protectedUploadVersion: '1', uploadedBy: 'alice', uploadGrantId: '12345678901234567890' },
    preconditionOpts: { ifGenerationMatch: '0' } });
  assert.equal(request.qs.sourceGeneration, 123);
  assert.equal(request.qs.ifGenerationMatch, '0');
  assert.equal(request.json.contentType, 'image/jpeg');
  assert.equal(request.json.cacheControl, 'private, no-store');
  assert.deepEqual(request.json.metadata, { protectedUploadVersion: '1', uploadedBy: 'alice', uploadGrantId: '12345678901234567890' });
  assert.equal(request.json.metadata.firebaseStorageDownloadTokens, undefined);
});
