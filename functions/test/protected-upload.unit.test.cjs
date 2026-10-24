const test = require('node:test');
const assert = require('node:assert/strict');
const { createProtectedUploadHandlers } = require('../security/protected-upload');
function fixture({ path = 'chats/chat/images/photo.jpg' } = {}) {
  const uid = 'sender', sid = 'a'.repeat(64), token = { uid, sid, auth_time: 100 };
  const records = new Map([
    [`users/${uid}/sessions/${sid}`, { sessionId: sid, authSessionVersion: 1, isRevoked: false }],
    [`authRevocations/${uid}`, { revokedBefore: 0 }],
  ]);
  let grantIndex = 0, acl = true, failReceipt = false;
  const objects = new Map(), signed = [], copies = [];
  const snapshot = key => ({ exists: records.has(key), data: () => records.get(key) });
  const db = {
    doc: key => ({ path: key, get: async () => snapshot(key) }),
    getAll: async (...refs) => refs.map(ref => snapshot(ref.path)),
    runTransaction: async fn => fn({
      getAll: async (...refs) => refs.map(ref => snapshot(ref.path)),
      get: async ref => snapshot(ref.path),
      create: (ref, value) => { assert.equal(records.has(ref.path), false); records.set(ref.path, value); },
      update: (ref, value) => {
        if (failReceipt && value.state === 'complete') { failReceipt = false; throw Error('receipt write unavailable'); }
        records.set(ref.path, { ...records.get(ref.path), ...value });
      },
    }),
  };
  const storage = { name: 'test-bucket', file: (name, options) => ({ name,
    getMetadata: async () => {
      const object = objects.get(name);
      if (!object || options?.generation && options.generation !== object.generation) throw Object.assign(Error('missing'), { code: 404 });
      return [object];
    },
    getSignedUrl: async options => { signed.push({ name, options }); return [`https://storage.googleapis.com/test-bucket/${name}?signature=test`]; },
    copy: async (destination, args) => {
      copies.push({ name, options, destination: destination.name, args });
      const source = objects.get(name), old = objects.get(destination.name);
      assert.equal(source.generation, options.generation);
      if ((old?.generation ?? '0') !== args.preconditionOpts.ifGenerationMatch) throw Object.assign(Error('conflict'), { code: 412 });
      objects.set(destination.name, { ...source, generation: '200', metadata: args.metadata, cacheControl: args.cacheControl });
    },
    delete: async args => {
      const source = objects.get(name);
      if (source) { assert.equal(args.ifGenerationMatch, source.generation); objects.delete(name); }
    },
  }) };
  const prepareUpload = async request => {
    if (!acl) throw Object.assign(Error('membership removed'), { code: 'permission-denied' });
    assert.equal(request.data.expectedUid, uid);
    return { grantId: String(++grantIndex).padStart(20, '0'), uid, path: request.data.path,
      size: request.data.size, contentType: request.data.contentType, bucket: storage.name, expiresAt: Date.now() + 1800000 };
  };
  prepareUpload.authorize = async request => {
    if (!acl) throw Object.assign(Error('membership removed'), { code: 'permission-denied' });
    assert.equal(request.data.expectedUid, uid);
  };
  const handler = createProtectedUploadHandlers({ auth: { verifyIdToken: async () => token }, db,
    FieldValue: { serverTimestamp: () => 1 }, Timestamp: { fromMillis: n => ({ toMillis: () => n }) }, bucket: () => storage, prepareUpload });
  const request = data => ({ auth: { uid }, rawRequest: { headers: { authorization: 'Bearer local-test' } }, data });
  const prepare = () => handler.prepare(request({ expectedUid: uid, path, size: 4, contentType: 'image/jpeg' }));
  const stage = grant => objects.set(grant.stagingPath, { generation: '100', size: '4', contentType: 'image/jpeg', metadata: { uploadedby: uid, uploadgrantid: grant.grantId } });
  const finalize = grant => handler.finalize(request({ grantId: grant.grantId }));
  return { prepare, stage, finalize, records, objects, signed, copies, path, uid, sid,
    deny: () => { acl = false; }, failReceipt: () => { failReceipt = true; } };
}
test('prepare signs private staging with exact content headers and create-only generation', async () => {
  const f = fixture(), grant = await f.prepare();
  assert.match(grant.stagingPath, /^private_upload_staging\/sender\/[0-9]{20}$/);
  assert.ok(grant.expiresAt <= Date.now() + 300000);
  assert.equal(grant.uploadHeaders['x-goog-if-generation-match'], '0');
  assert.equal(grant.uploadHeaders['Content-Length'], '4');
  assert.equal(f.signed[0].options.extensionHeaders['x-goog-meta-uploadedby'], 'sender');
  assert.equal(JSON.stringify(grant).includes('firebaseStorageDownloadTokens'), false);
});
test('finalize copies pinned source and returns tokenless locator; retries recover same receipt', async () => {
  const f = fixture(), grant = await f.prepare(); f.stage(grant);
  const receipt = await f.finalize(grant);
  assert.equal(receipt.url, 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/chats%2Fchat%2Fimages%2Fphoto.jpg?alt=media');
  assert.deepEqual(f.objects.get(f.path).metadata, { protectedUploadVersion: '1', uploadedBy: f.uid, uploadGrantId: grant.grantId });
  assert.equal(f.copies[0].options.generation, '100');
  assert.equal(f.copies[0].args.preconditionOpts.ifGenerationMatch, '0');
  assert.deepEqual(await f.finalize(grant), receipt);
  assert.equal(f.copies.length, 1);
});
test('current ACL is checked before copy and again on a completed receipt', async () => {
  for (const complete of [false, true]) {
    const f = fixture(), grant = await f.prepare(); f.stage(grant);
    if (complete) await f.finalize(grant);
    f.deny();
    await assert.rejects(f.finalize(grant), { code: 'permission-denied' });
    assert.equal(f.copies.length, complete ? 1 : 0);
  }
});
test('expired and revoked grants cannot finalize', async () => {
  for (const revoked of [false, true]) {
    const f = fixture(), grant = await f.prepare(); f.stage(grant);
    if (revoked) f.records.get(`users/${f.uid}/sessions/${f.sid}`).isRevoked = true;
    else f.records.get(`protectedUploadTickets/${grant.grantId}`).expiresAt = { toMillis: () => 1 };
    await assert.rejects(f.finalize(grant), { code: revoked ? 'unauthenticated' : 'deadline-exceeded' });
    assert.equal(f.copies.length, 0);
  }
});
test('staging rejects altered size, uploader, grant, or permanent download token', async () => {
  for (const corrupt of [o => { o.size = '5'; }, o => { o.metadata.uploadedby = 'other'; },
    o => { o.metadata.uploadgrantid = 'other'; }, o => { o.metadata.firebaseStorageDownloadTokens = 'secret'; }]) {
    const f = fixture(), grant = await f.prepare(); f.stage(grant); corrupt(f.objects.get(grant.stagingPath));
    await assert.rejects(f.finalize(grant), { code: 'failed-precondition' });
    assert.equal(f.copies.length, 0);
  }
});
test('profile overwrite pins destination at prepare and rejects a newer concurrent photo', async () => {
  const f = fixture({ path: 'users/sender/avatar.jpg' });
  f.objects.set(f.path, { generation: '55' });
  const grant = await f.prepare(); f.stage(grant);
  f.objects.set(f.path, { generation: '56' });
  await assert.rejects(f.finalize(grant), { code: 'already-exists' });
  assert.equal(f.copies.length, 0);
});
test('immutable chat attachments cannot overwrite even at prepare', async () => {
  const f = fixture(); f.objects.set(f.path, { generation: '55' });
  await assert.rejects(f.prepare(), { code: 'already-exists' });
  assert.equal(f.signed.length, 0);
});
test('copy committed before receipt failure is recovered without copying again', async () => {
  const f = fixture(), grant = await f.prepare(); f.stage(grant); f.failReceipt();
  await assert.rejects(f.finalize(grant), /receipt write unavailable/);
  assert.equal(f.copies.length, 1);
  assert.ok((await f.finalize(grant)).url.endsWith('?alt=media'));
  assert.equal(f.copies.length, 1);
});
test('a replacement staging generation cannot resume an earlier copy ticket', async () => {
  const f = fixture(), grant = await f.prepare(); f.stage(grant);
  Object.assign(f.records.get(`protectedUploadTickets/${grant.grantId}`), { state: 'copying', sourceGeneration: '99' });
  await assert.rejects(f.finalize(grant), { code: 'failed-precondition' });
  assert.equal(f.copies.length, 0);
});
