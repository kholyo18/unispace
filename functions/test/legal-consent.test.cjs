'use strict';

// Dependency-free unit tests. This fake is NOT the Firestore emulator and does
// not prove deployed rules, real Firebase tokens or real database contention.
const test = require('node:test');
const assert = require('node:assert/strict');
const {createConsentHandlers, parsePolicy} = require('../legal/consent');
const NOW = Date.parse('2026-09-16T12:00:00.000Z');
class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
class Timestamp {
  constructor(value) { this.value = value; }
  toMillis() { return this.value; }
}
const pendingTimestamp = Symbol('serverTimestamp');
function copy(value) {
  if (value instanceof Timestamp) return new Timestamp(value.value);
  if (Array.isArray(value)) return value.map(copy);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, copy(v)]));
  return value;
}
function resolve(value, clock) {
  if (value === pendingTimestamp) return new Timestamp(clock);
  if (Array.isArray(value)) return value.map(v => resolve(v, clock));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, resolve(v, clock)]));
  return value;
}
class FakeDb {
  constructor() { this.docs = new Map(); this.writes = []; this.clock = NOW; this.queue = Promise.resolve(); this.failCommit = false; }
  doc(path) { return {path}; }
  seed(path, data) { this.docs.set(path, copy(data)); }
  runTransaction(callback) {
    const execute = async () => {
      const pending = [];
      const get = async ref => {
        assert.equal(pending.length, 0, 'No reads may follow writes');
        const data = copy(this.docs.get(ref.path));
        return {exists: this.docs.has(ref.path), data: () => data};
      };
      const result = await callback({get, getAll: (...refs) => Promise.all(refs.map(get)),
        create: (ref, data) => pending.push({kind: 'create', path: ref.path, data}),
        set: (ref, data) => pending.push({kind: 'set', path: ref.path, data})});
      if (this.failCommit) throw new Error('simulated database failure');
      const next = new Map(this.docs);
      for (const write of pending) {
        if (write.kind === 'create') assert.equal(next.has(write.path), false, 'create cannot overwrite');
        next.set(write.path, resolve(write.data, this.clock));
      }
      this.docs = next;
      this.writes.push(...pending.map(copy));
      this.clock++;
      return result;
    };
    const result = this.queue.then(execute);
    this.queue = result.catch(() => {});
    return result;
  }
}
function policy() {
  return {enabled: true, status: 'published', language: 'ar', operatorName: 'Test operator only',
    publishedAt: '2026-09-15T12:00:00.000Z', documents: ['terms', 'community', 'privacy'].map(id => ({
      id, version: 'test-1', title: `Test ${id}`, body: `نص اختبار فقط: ${id}\nالسطر الثاني.`}))};
}
function setup() {
  const db = new FakeDb();
  db.seed('legalPolicy/current', policy());
  const checks = [];
  const auth = {verifyIdToken: async (token, revoked) => {
    checks.push({token, revoked});
    if (!['alice', 'bob'].includes(token)) throw new Error('invalid or revoked token');
    return {uid: token, auth_time: 1000};
  }};
  const handlers = createConsentHandlers({db, auth, HttpsError, FieldValue: {serverTimestamp: () => pendingTimestamp}, now: () => NOW});
  return {db, auth, checks, ...handlers};
}
const request = (data = {}, uid = 'alice') => ({data, auth: {uid}, rawRequest: {headers: {authorization: `Bearer ${uid}`}}});
const input = state => ({fingerprint: state.policy.fingerprint, acceptanceContext: state.acceptanceContext,
  termsAccepted: true, communityAccepted: true, privacyAcknowledged: true});
const receiptPath = (state, uid = state.uid) => `legalConsentRecords/${uid}/receipts/${state.policy.fingerprint}`;
const archivePath = state => `legalPolicyVersions/${state.policy.fingerprint}`;
const rejects = (action, code) => assert.rejects(action, error => error instanceof HttpsError && error.code === code);

test('missing and explicitly disabled configurations are off, not acceptance', async () => {
  for (const value of [undefined, {enabled: false}]) {
    const h = setup();
    if (value) h.db.seed('legalPolicy/current', value); else h.db.docs.delete('legalPolicy/current');
    assert.deepEqual(await h.status(request()), {uid: 'alice', enabled: false, required: false});
    assert.equal(h.db.writes.length, 0);
  }
});

test('canonical ordering and equivalent UTC times yield the same fingerprint', () => {
  const a = policy(), b = policy(); b.documents.reverse(); b.publishedAt = '2026-09-15T12:00:00Z';
  assert.deepEqual(parsePolicy(a, HttpsError, NOW), parsePolicy(b, HttpsError, NOW));
});
for (const field of ['body', 'title', 'version']) test(`changing ${field} changes the fingerprint`, () => {
  const a = policy(), b = policy(); b.documents[0][field] += 'x';
  assert.notEqual(parsePolicy(a, HttpsError, NOW).fingerprint, parsePolicy(b, HttpsError, NOW).fingerprint);
});
for (const [name, mutate] of [
  ['enabled type', p => {p.enabled = 'true';}], ['unpublished draft', p => {p.status = 'draft';}],
  ['unsupported language', p => {p.language = 'fr';}], ['blank operator', p => {p.operatorName = ' ';}],
  ['future publication', p => {p.publishedAt = '2030-01-01T00:00:00.000Z';}],
  ['invalid calendar date', p => {p.publishedAt = '2026-02-30T00:00:00.000Z';}],
  ['date without UTC', p => {p.publishedAt = '2026-09-15T12:00:00';}],
  ['duplicate document', p => {p.documents[1] = {...p.documents[0]};}],
  ['missing document', p => {p.documents.pop();}], ['empty document', p => {p.documents[0].body = ' ';}],
  ['version with trailing newline', p => {p.documents[0].version += '\n';}],
  ['body exceeds byte budget', p => {p.documents[0].body = 'س'.repeat(70000);}],
]) test(`rejects malformed policy: ${name}`, () => {
  const p = policy(); mutate(p);
  assert.throws(() => parsePolicy(p, HttpsError, NOW), error => error.code === 'failed-precondition');
});

test('status requires a valid revoked-token check and makes no writes', async () => {
  const h = setup(); const state = await h.status(request());
  assert.equal(state.required, true); assert.equal(state.policy.documents.length, 3);
  assert.deepEqual(h.checks, [{token: 'alice', revoked: true}]); assert.equal(h.db.writes.length, 0);
});
for (const [name, mutate] of [
  ['no auth', r => {delete r.auth;}], ['no header', r => {delete r.rawRequest;}],
  ['array header', r => {r.rawRequest.headers.authorization = ['Bearer alice'];}],
  ['header newline', r => {r.rawRequest.headers.authorization = 'Bearer alice\n';}],
  ['invalid token', r => {r.rawRequest.headers.authorization = 'Bearer revoked';}],
  ['mismatched caller', r => {r.auth.uid = 'bob';}], ['path injection', r => {r.auth.uid = 'a/b';}],
]) test(`denies authentication: ${name}`, async () => {
  const h = setup(), r = request(); mutate(r);
  await rejects(() => h.status(r), 'unauthenticated'); assert.equal(h.db.writes.length, 0);
});
for (const token of [{uid: 'alice', auth_time: 0.5}, {uid: 'alice', auth_time: -1},
  {uid: 'alice', auth_time: 1000, firebase: {tenant: 'other'}}]) {
  test(`denies invalid token claims ${JSON.stringify(token)}`, async () => {
    const h = setup(); h.auth.verifyIdToken = async () => token;
    await rejects(() => h.status(request()), 'unauthenticated');
  });
}
for (const [cutoff, code] of [[1000, 'unauthenticated'], [1001, 'unauthenticated'], ['1000', 'failed-precondition']]) {
  test(`revocation cutoff ${JSON.stringify(cutoff)} fails closed`, async () => {
    const h = setup(); h.db.seed('authRevocations/alice', {revokedBefore: cutoff});
    await rejects(() => h.status(request()), code);
  });
}
for (const user of [{accountStatus: 'disabled'}, {accountStatus: 'deleted'}, {isDeleted: true}, {security: {frozen: true}}]) {
  test(`unavailable account ${JSON.stringify(user)} cannot accept`, async () => {
    const h = setup(), state = await h.status(request()); h.db.seed('users/alice', user);
    await rejects(() => h.accept(request(input(state))), 'permission-denied');
    assert.equal(h.db.writes.length, 0);
  });
}

test('status rejects client parameters', async () => {
  await rejects(() => setup().status(request({uid: 'alice'})), 'invalid-argument');
});
for (const field of ['termsAccepted', 'communityAccepted', 'privacyAcknowledged']) {
  test(`acceptance requires literal true for ${field}`, async () => {
    const h = setup(), data = input(await h.status(request()));
    for (const value of [false, 'true', 1, null]) {
      await rejects(() => h.accept(request({...data, [field]: value})), 'invalid-argument');
    }
    assert.equal(h.db.writes.length, 0);
  });
}
for (const key of ['uid', 'acceptedAt', 'policy', 'aiTrainingConsent']) {
  test(`rejects untrusted extra field ${key}`, async () => {
    const h = setup(), data = input(await h.status(request()));
    await rejects(() => h.accept(request({...data, [key]: 'forged'})), 'invalid-argument');
    assert.equal(h.db.writes.length, 0);
  });
}

test('hashes reject trailing newlines', async () => {
  const h = setup(), data = input(await h.status(request()));
  for (const key of ['fingerprint', 'acceptanceContext']) {
    await rejects(() => h.accept(request({...data, [key]: data[key] + '\n'})), 'invalid-argument');
  }
});

test('first acceptance creates server-time receipt and exact publication archive atomically', async () => {
  const h = setup(), state = await h.status(request());
  const result = await h.accept(request(input(state)));
  assert.equal(result.alreadyAccepted, false); assert.equal(h.db.writes.length, 3);
  const receipt = h.db.docs.get(receiptPath(state)), archive = h.db.docs.get(archivePath(state));
  assert.equal(receipt.uid, 'alice'); assert.equal(receipt.acceptedAt.toMillis(), NOW + 1);
  assert.deepEqual(archive.documents, state.policy.documents);
  assert.deepEqual(Object.keys(receipt).sort(), ['schemaVersion', 'uid', 'fingerprint', 'language', 'documents',
    'termsAccepted', 'communityAccepted', 'privacyAcknowledged', 'source', 'acceptedAt'].sort());
  assert.equal((await h.status(request())).required, false);
});

test('lost-response retry does not duplicate or rewrite acceptedAt', async () => {
  const h = setup(), state = await h.status(request()), data = input(state);
  await h.accept(request(data));
  const original = h.db.docs.get(receiptPath(state)).acceptedAt.toMillis();
  assert.equal((await h.accept(request(data))).alreadyAccepted, true);
  assert.equal(h.db.writes.length, 3);
  assert.equal(h.db.docs.get(receiptPath(state)).acceptedAt.toMillis(), original);
});

test('two simultaneous callers in the serialized fake create only one receipt', async () => {
  const h = setup(), data = input(await h.status(request()));
  const result = await Promise.all([h.accept(request(data)), h.accept(request(data))]);
  assert.deepEqual(result.map(r => r.alreadyAccepted).sort(), [false, true]);
  assert.equal(h.db.writes.length, 3);
});

test('account switch cannot apply an old displayed context to another account', async () => {
  const h = setup(), state = await h.status(request());
  await rejects(() => h.accept(request(input(state), 'bob')), 'failed-precondition');
  assert.equal(h.db.writes.length, 0);
  const bob = await h.status(request({}, 'bob'));
  assert.notEqual(state.acceptanceContext, bob.acceptanceContext);
  await h.accept(request(input(bob), 'bob'));
  assert.equal((await h.status(request())).required, true);
});

test('policy changed after display invalidates acceptance and existing consent', async () => {
  const h = setup(), state = await h.status(request()); await h.accept(request(input(state)));
  const changed = policy(); changed.documents[0].body += '\nتغيير'; h.db.seed('legalPolicy/current', changed);
  await rejects(() => h.accept(request(input(state))), 'failed-precondition');
  const next = await h.status(request()); assert.equal(next.required, true);
  await h.accept(request(input(next))); assert.equal(h.db.docs.has(receiptPath(state)), true);
});

test('disabled policy cannot receive acceptance', async () => {
  const h = setup(), data = input(await h.status(request())); h.db.seed('legalPolicy/current', {enabled: false});
  await rejects(() => h.accept(request(data)), 'failed-precondition'); assert.equal(h.db.writes.length, 0);
});

for (const corrupt of ['receipt', 'timestamp', 'archive', 'missingArchive']) {
  test(`corrupt ${corrupt} cannot silently grant access or be overwritten`, async () => {
    const h = setup(), state = await h.status(request()); await h.accept(request(input(state)));
    if (corrupt === 'receipt') h.db.docs.get(receiptPath(state)).communityAccepted = false;
    if (corrupt === 'timestamp') h.db.docs.get(receiptPath(state)).acceptedAt = 'client-time';
    if (corrupt === 'archive') h.db.docs.get(archivePath(state)).documents[0].body = 'tampered';
    if (corrupt === 'missingArchive') h.db.docs.delete(archivePath(state));
    await rejects(() => h.status(request()), 'failed-precondition');
    await rejects(() => h.accept(request(input(state))), 'failed-precondition');
    assert.equal(h.db.writes.length, 3);
  });
}

test('database commit failure grants nothing and leaves no partial receipt', async () => {
  const h = setup(), state = await h.status(request()); h.db.failCommit = true;
  await assert.rejects(() => h.accept(request(input(state))), /simulated database failure/);
  assert.equal(h.db.docs.has(receiptPath(state)), false); assert.equal(h.db.docs.has(archivePath(state)), false);
  assert.equal(h.db.writes.length, 0);
});
