'use strict';

// Dependency-free tests against a serial, optimistic-retry transaction fake.
// This is NOT the Firebase Emulator and uses no production credentials or data.
const test = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const {parsePolicy, createConsentHandlers} = require('../legal/consent');
const {RULES_VERSION, TIME_ZONE, dateParts, localDate, anniversary, classifyBirthDate} = require('../legal/eligibility');
const {createEligibilityConsentHandlers} = require('../legal/eligibility-consent');
const NOW = Date.parse('2026-09-16T12:00:00.000Z');
const SERVER_TIME = Symbol('server timestamp');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
class Timestamp { constructor(value) { this.value = value; } toMillis() { return this.value; } }
const stamp = value => new Timestamp(value);
function clone(value) {
  if (value instanceof Timestamp) return stamp(value.value);
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, clone(v)]));
  return value;
}
function resolve(value, clock) {
  if (value === SERVER_TIME) return stamp(clock);
  if (value instanceof Timestamp) return stamp(value.value);
  if (Array.isArray(value)) return value.map(v => resolve(v, clock));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, resolve(v, clock)]));
  return value;
}
class FakeDb {
  constructor(clock) {
    this.clock = clock; this.docs = new Map(); this.versions = new Map(); this.writes = [];
    this.queue = Promise.resolve(); this.failCommit = false; this.beforeCommit = null; this.callbacks = 0;
  }
  doc(path) { assert.equal(path.split('/').length % 2, 0, `Document path ${path}`); return {path}; }
  seed(path, data) { this.docs.set(path, clone(data)); this.versions.set(path, (this.versions.get(path) || 0) + 1); }
  remove(path) { this.docs.delete(path); this.versions.set(path, (this.versions.get(path) || 0) + 1); }
  edit(path, mutate) { const value = clone(this.docs.get(path)); mutate(value); this.seed(path, value); }
  runTransaction(callback) {
    const execute = async () => {
      for (let attempt = 0; attempt < 5; attempt++) {
        this.callbacks++;
        const pending = [], reads = new Map();
        const get = async ref => {
          assert.equal(pending.length, 0, 'Firestore requires all reads before writes');
          reads.set(ref.path, this.versions.get(ref.path) || 0);
          const data = clone(this.docs.get(ref.path));
          return {exists: this.docs.has(ref.path), data: () => data};
        };
        const result = await callback({get, getAll: (...refs) => Promise.all(refs.map(get)),
          create: (ref, data) => pending.push({kind: 'create', path: ref.path, data}),
          set: (ref, data) => pending.push({kind: 'set', path: ref.path, data})});
        if (this.beforeCommit) await this.beforeCommit(this, attempt);
        if ([...reads].some(([path, version]) => version !== (this.versions.get(path) || 0))) continue;
        if (this.failCommit) throw new Error('simulated atomic commit failure');
        const next = new Map(this.docs);
        for (const write of pending) {
          if (write.kind === 'create') assert.equal(next.has(write.path), false, 'create cannot overwrite existing data');
          next.set(write.path, resolve(write.data, this.clock()));
        }
        this.docs = next;
        for (const write of pending) this.versions.set(write.path, (this.versions.get(write.path) || 0) + 1);
        this.writes.push(...pending.map(clone));
        return result;
      }
      throw new Error('simulated contention limit');
    };
    const result = this.queue.then(execute); this.queue = result.catch(() => {}); return result;
  }
}
function policy() {
  return {enabled: true, status: 'published', language: 'ar', operatorName: 'TEST ONLY — not a real operator',
    publishedAt: '2026-09-15T00:00:00.000Z', documents: ['terms', 'community', 'privacy'].map(id => ({
      id, version: 'test-1', title: `Test ${id}`, body: `نص اختبار فقط: ${id}\nلا يُنشر كوثيقة قانونية.`}))};
}
function setup(clock = NOW) {
  const h = {clock, checks: [], ids: 0};
  h.db = new FakeDb(() => h.clock); h.db.seed('legalPolicy/current', policy());
  h.auth = {verifyIdToken: async (token, checkRevoked) => {
    h.checks.push({token, checkRevoked});
    if (!['alice', 'bob'].includes(token)) throw new Error('invalid token');
    return {uid: token, auth_time: 1000};
  }};
  h.dependencies = {auth: h.auth, db: h.db, FieldValue: {serverTimestamp: () => SERVER_TIME}, HttpsError,
    now: () => h.clock, makeDeclarationId: () => (++h.ids).toString(16).padStart(32, '0')};
  Object.assign(h, createEligibilityConsentHandlers(h.dependencies));
  return h;
}
const request = (data = {}, uid = 'alice') => ({data, auth: {uid}, rawRequest: {headers: {authorization: `Bearer ${uid}`}}});
const declareInput = (state, birthDate) => ({birthDate, declarationContext: state.declarationContext, accuracyConfirmed: true});
const acceptInput = state => ({fingerprint: state.policy.fingerprint, acceptanceContext: state.acceptanceContext,
  termsAccepted: true, communityAccepted: true, privacyAcknowledged: true});
const declarationPath = (uid = 'alice') => `legalEligibilityDeclarations/${uid}`;
const approvalPath = (uid = 'alice') => `legalRepresentativeApprovals/${uid}`;
const receiptPath = state => `legalEligibilityReceipts/${state.uid}/receipts/${state.acceptanceContext}`;
const archivePath = state => `legalPolicyVersions/${state.policy.fingerprint}`;
const rejects = (action, code) => assert.rejects(action, error => error instanceof HttpsError && error.code === code);
async function declare(h, birthDate, uid = 'alice') {
  const state = await h.status(request({}, uid));
  await h.declareBirthDate(request(declareInput(state, birthDate), uid));
  return h.status(request({}, uid));
}
function verifiedApproval(h, state) {
  // In-memory test fixture ONLY. No real representative or review is being asserted.
  return {schemaVersion: 1, source: 'verified_legal_representative_review', status: 'verified',
    subjectUid: state.uid, declarationId: h.db.docs.get(declarationPath(state.uid)).declarationId,
    policyFingerprint: state.policy.fingerprint, rulesVersion: RULES_VERSION,
    representativeUid: 'test-representative', reviewerUid: 'test-reviewer', reviewReference: 'TEST-CASE-001',
    authorityVerified: true, termsAccepted: true, communityAccepted: true, privacyAcknowledged: true,
    acceptedAt: stamp(h.clock), verifiedAt: stamp(h.clock), expiresAt: stamp(h.clock + 86400000), revokedAt: null};
}
async function accept(h, state) { await h.accept(request(acceptInput(state), state.uid)); return h.status(request({}, state.uid)); }
async function guardedWrite(h, uid = 'alice') {
  return h.db.runTransaction(async tx => {
    const authorized = await h.assertInTransaction(tx, request({}, uid));
    tx.create(h.db.doc(`testProtectedWrites/${uid}`), {uid: authorized.uid});
    return authorized;
  });
}

// Exact date boundaries are specified independently of the production helpers.
for (const [birth, iso, expected] of [
  ['2008-09-16', '2026-09-15T22:59:59.999Z', 'under_minimum_age'],
  ['2008-09-16', '2026-09-15T23:00:00.000Z', 'represented'],
  ['2007-09-16', '2026-09-15T22:59:59.999Z', 'represented'],
  ['2007-09-16', '2026-09-15T23:00:00.000Z', 'independent'],
  ['2008-02-29', '2026-02-28T22:59:59.999Z', 'under_minimum_age'],
  ['2008-02-29', '2026-02-28T23:00:00.000Z', 'represented'],
  ['2008-02-29', '2027-02-28T22:59:59.999Z', 'represented'],
  ['2008-02-29', '2027-02-28T23:00:00.000Z', 'independent'],
  ['1900-01-01', '2026-09-16T12:00:00.000Z', 'independent'],
]) test(`calendar boundary ${birth} at ${iso}`, () => assert.equal(classifyBirthDate(birth, Date.parse(iso)), expected));

test('date utility uses the server date in Africa/Algiers, not the process time zone', () => {
  assert.equal(TIME_ZONE, 'Africa/Algiers'); assert.equal(localDate(Date.parse('2026-12-31T23:01:00Z')), '2027-01-01');
  assert.equal(anniversary('2008-02-29', 18), '2026-03-01');
  assert.deepEqual(dateParts('2000-02-29'), {year: 2000, month: 2, day: 29});
  assert.equal(dateParts('1900-02-29'), null);
});
for (const date of ['2008-02-30', '2008-13-01', '2008-00-01', '2008-01-00', '2008-1-01',
  '2008-01-01\n', ' 2008-01-01', '2008-01-01 ', '٢٠٠٨-٠١-٠١', '2008-01-01T00:00:00Z',
  '1899-12-31', '2026-09-17', '', null, 20080916]) {
  test(`birth date input rejects ${JSON.stringify(date)}`, async () => {
    const h = setup(), state = await h.status(request());
    await rejects(() => h.declareBirthDate(request(declareInput(state, date))), 'invalid-argument');
    assert.equal(h.db.writes.length, 0);
  });
}
for (const clock of [NaN, Infinity, -1, 1.1, '1000']) test(`invalid server clock ${String(clock)}`, () => {
  assert.throws(() => classifyBirthDate('2000-01-01', clock), RangeError);
});

for (const value of [undefined, {enabled: false}]) test(`unconfigured policy never authorizes V2: ${JSON.stringify(value)}`, async () => {
  const h = setup(); value ? h.db.seed('legalPolicy/current', value) : h.db.remove('legalPolicy/current');
  const state = await h.status(request());
  assert.equal(state.enabled, false); assert.equal(state.canProceed, false); assert.equal(state.state, 'not_configured');
  await rejects(() => guardedWrite(h), 'failed-precondition'); assert.equal(h.db.writes.length, 0);
});
for (const [name, mutate] of [
  ['draft', p => {p.status = 'draft';}], ['operator missing', p => {p.operatorName = '';}],
  ['duplicate document', p => {p.documents[2] = p.documents[0];}], ['future publication', p => {p.publishedAt = '2030-01-01T00:00:00.000Z';}],
]) test(`shared publication validation rejects ${name}`, async () => {
  const h = setup(), p = policy(); mutate(p); h.db.seed('legalPolicy/current', p);
  await rejects(() => h.status(request()), 'failed-precondition');
});

test('missing declaration fails closed without copying the editable profile date', async () => {
  const h = setup(); h.db.seed('users/alice', {birthDate: stamp(Date.parse('1980-01-01')), age: 46, guardianApproved: true});
  const state = await h.status(request());
  assert.equal(state.state, 'birth_date_required'); assert.equal(state.canProceed, false); assert.equal(state.canAccept, false);
  assert.equal(state.policy.fingerprint, parsePolicy(policy(), HttpsError, NOW).fingerprint);
  assert.deepEqual(h.checks[0], {token: 'alice', checkRevoked: true}); assert.equal(h.db.writes.length, 0);
});
for (const [name, mutate] of [
  ['missing auth', r => {delete r.auth;}], ['missing header', r => {delete r.rawRequest;}],
  ['array header', r => {r.rawRequest.headers.authorization = ['Bearer alice'];}],
  ['header newline', r => {r.rawRequest.headers.authorization += '\n';}],
  ['invalid token', r => {r.rawRequest.headers.authorization = 'Bearer invalid';}],
  ['mismatched caller', r => {r.auth.uid = 'bob';}], ['slash UID', r => {r.auth.uid = 'a/b';}],
  ['dot UID', r => {r.auth.uid = '..';}], ['blank UID', r => {r.auth.uid = ' ';}],
]) test(`authentication rejects ${name}`, async () => {
  const h = setup(), r = request(); mutate(r);
  await rejects(() => h.status(r), 'unauthenticated'); assert.equal(h.db.writes.length, 0);
});
for (const token of [{uid: 'alice', auth_time: 0.5}, {uid: 'alice', auth_time: -1},
  {uid: 'alice', auth_time: Math.floor(NOW / 1000) + 60}, {uid: 'alice', auth_time: 1000, firebase: {tenant: 'test'}}]) {
  test(`token claim validation ${JSON.stringify(token)}`, async () => {
    const h = setup(); h.auth.verifyIdToken = async () => token;
    await rejects(() => h.status(request()), 'unauthenticated');
  });
}
for (const [boundary, code] of [[1000, 'unauthenticated'], [1001, 'unauthenticated'], ['1000', 'failed-precondition'], [-1, 'failed-precondition']]) {
  test(`revocation boundary ${JSON.stringify(boundary)}`, async () => {
    const h = setup(); h.db.seed('authRevocations/alice', {revokedBefore: boundary});
    await rejects(() => h.status(request()), code);
  });
}
for (const profile of [{accountStatus: 'disabled'}, {accountStatus: 'deleted'}, {isDeleted: true}, {security: {frozen: true}}]) {
  test(`blocked account cannot declare ${JSON.stringify(profile)}`, async () => {
    const h = setup(), state = await h.status(request()); h.db.seed('users/alice', profile);
    await rejects(() => h.declareBirthDate(request(declareInput(state, '2000-01-01'))), 'permission-denied');
    assert.equal(h.db.writes.length, 0);
  });
}
for (const input of [null, [], {uid: 'alice'}, {now: NOW}]) test(`status accepts only an empty object: ${JSON.stringify(input)}`, async () => {
  await rejects(() => setup().status(request(input)), 'invalid-argument');
});
for (const value of [false, 'true', 1, null]) test(`date accuracy must be literal true: ${JSON.stringify(value)}`, async () => {
  const h = setup(), state = await h.status(request());
  await rejects(() => h.declareBirthDate(request({...declareInput(state, '2000-01-01'), accuracyConfirmed: value})), 'invalid-argument');
});
for (const field of ['uid', 'declaredAt', 'declarationId', 'guardianApproved', 'age', 'eligibility']) {
  test(`declaration rejects client-controlled ${field}`, async () => {
    const h = setup(), state = await h.status(request());
    await rejects(() => h.declareBirthDate(request({...declareInput(state, '2000-01-01'), [field]: 'forged'})), 'invalid-argument');
    assert.equal(h.db.writes.length, 0);
  });
}

test('declaration context is account-bound and rejects trailing newline', async () => {
  const h = setup(), state = await h.status(request()), data = declareInput(state, '2000-01-01');
  await rejects(() => h.declareBirthDate(request(data, 'bob')), 'failed-precondition');
  await rejects(() => h.declareBirthDate(request({...data, declarationContext: data.declarationContext + '\n'})), 'invalid-argument');
  assert.equal(h.db.writes.length, 0);
});

test('declaration is immutable through the client API and idempotent for a lost response', async () => {
  const h = setup(), original = await h.status(request()), data = declareInput(original, '2008-09-17');
  await h.declareBirthDate(request(data));
  const stored = clone(h.db.docs.get(declarationPath()));
  assert.equal((await h.declareBirthDate(request(data))).alreadyRecorded, true);
  await rejects(() => h.declareBirthDate(request({...data, birthDate: '2000-01-01'})), 'failed-precondition');
  assert.deepEqual(h.db.docs.get(declarationPath()), stored); assert.equal(h.db.writes.length, 1);
  assert.equal(stored.declaredAt.toMillis(), NOW); assert.equal(stored.source, 'self_declared');
});

test('under-18 declaration cannot accept even with a representative record', async () => {
  const h = setup(), state = await declare(h, '2008-09-17');
  h.db.seed(approvalPath(), verifiedApproval(h, state));
  const checked = await h.status(request()); assert.equal(checked.canProceed, false); assert.equal(checked.canAccept, false);
  await rejects(() => h.accept(request({...acceptInput(state), acceptanceContext: 'a'.repeat(64)})), 'failed-precondition');
  await rejects(() => guardedWrite(h), 'failed-precondition'); assert.equal(h.db.writes.length, 1);
});

test('under-18 declaration becomes represented on the server birthday, not by editing the date', async () => {
  const h = setup(Date.parse('2026-09-15T22:59:59Z'));
  assert.equal((await declare(h, '2008-09-16')).state, 'under_minimum_age');
  h.clock = Date.parse('2026-09-15T23:00:00Z');
  const state = await h.status(request()); assert.equal(state.phase, 'represented');
  assert.equal(state.canAccept, true); assert.equal(state.canProceed, false);
});

test('18-year-old personal consent is recorded but never substitutes for representative verification', async () => {
  const h = setup(), state = await declare(h, '2008-09-16');
  const next = await accept(h, state);
  assert.equal(next.userAccepted, true); assert.equal(next.state, 'representative_required'); assert.equal(next.canProceed, false);
  await rejects(() => guardedWrite(h), 'failed-precondition');
});

test('verified representative alone cannot substitute for personal consent', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state));
  const next = await h.status(request()); assert.equal(next.representativeVerified, true);
  assert.equal(next.userAccepted, false); assert.equal(next.canProceed, false);
});

test('both decisions allow the transaction guard only in the represented phase', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state));
  const next = await accept(h, state); assert.equal(next.canProceed, true);
  assert.equal((await guardedWrite(h)).phase, 'represented'); assert.equal(h.db.docs.has('testProtectedWrites/alice'), true);
});
for (const [name, mutate] of [
  ['pending', a => {a.status = 'pending';}], ['revoked status', a => {a.status = 'revoked';}],
  ['revocation timestamp', a => {a.revokedAt = stamp(NOW);}], ['missing explicit non-revocation', a => {delete a.revokedAt;}],
  ['same-account representative', a => {a.representativeUid = 'alice';}], ['self-review', a => {a.reviewerUid = 'alice';}],
  ['representative reviews own proof', a => {a.reviewerUid = a.representativeUid;}],
  ['wrong subject', a => {a.subjectUid = 'bob';}], ['wrong declaration', a => {a.declarationId = 'f'.repeat(32);}],
  ['wrong publication', a => {a.policyFingerprint = 'f'.repeat(64);}], ['wrong rules', a => {a.rulesVersion = 'other';}],
  ['unchecked authority', a => {a.authorityVerified = false;}], ['missing terms', a => {a.termsAccepted = false;}],
  ['missing community', a => {a.communityAccepted = false;}], ['missing privacy acknowledgment', a => {a.privacyAcknowledged = false;}],
  ['string boolean', a => {a.authorityVerified = 'true';}], ['unreviewed source', a => {a.source = 'email_only';}],
  ['expired at equality', a => {a.expiresAt = stamp(NOW);}], ['future verification', a => {a.verifiedAt = stamp(NOW + 1);}],
  ['acceptance after verification', a => {a.acceptedAt = stamp(NOW + 1);}],
  ['approval before declaration', a => {a.acceptedAt = stamp(NOW - 1);}],
  ['string timestamp', a => {a.verifiedAt = String(NOW);}], ['missing review reference', a => {delete a.reviewReference;}],
]) test(`representative approval never grants access with ${name}`, async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); await accept(h, state);
  const approval = verifiedApproval(h, state); mutate(approval); h.db.seed(approvalPath(), approval);
  assert.equal((await h.status(request())).canProceed, false);
  await rejects(() => guardedWrite(h), 'failed-precondition');
});

test('representative revocation after a ready status is rechecked by the protected transaction', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state));
  assert.equal((await accept(h, state)).canProceed, true);
  h.db.edit(approvalPath(), a => {a.status = 'revoked';});
  await rejects(() => guardedWrite(h), 'failed-precondition'); assert.equal(h.db.docs.has('testProtectedWrites/alice'), false);
});

test('at 19 the same publication requires new independent acceptance and rejects the old in-flight context', async () => {
  const h = setup(Date.parse('2026-09-15T22:59:59Z')), state = await declare(h, '2007-09-16');
  h.db.seed(approvalPath(), verifiedApproval(h, state)); assert.equal((await accept(h, state)).canProceed, true);
  const representedPath = receiptPath(state), originalTime = h.db.docs.get(representedPath).acceptedAt.toMillis();
  h.clock = Date.parse('2026-09-15T23:00:00Z'); const adult = await h.status(request());
  assert.equal(adult.phase, 'independent'); assert.equal(adult.canProceed, false); assert.equal(adult.userAccepted, false);
  assert.equal(adult.policy.fingerprint, state.policy.fingerprint); assert.notEqual(adult.acceptanceContext, state.acceptanceContext);
  await rejects(() => h.accept(request(acceptInput(state))), 'failed-precondition');
  assert.equal((await accept(h, adult)).canProceed, true); assert.equal((await guardedWrite(h)).phase, 'independent');
  assert.equal(h.db.docs.get(representedPath).acceptedAt.toMillis(), originalTime);
  assert.notEqual(receiptPath(adult), representedPath);
});

test('independent adult requires no representative, but still needs personal consent', async () => {
  const h = setup(), state = await declare(h, '2000-01-01');
  await rejects(() => guardedWrite(h), 'failed-precondition');
  assert.equal((await accept(h, state)).canProceed, true); assert.equal((await guardedWrite(h)).phase, 'independent');
});

for (const field of ['termsAccepted', 'communityAccepted', 'privacyAcknowledged']) test(`acceptance requires literal true for ${field}`, async () => {
  const h = setup(), state = await declare(h, '2000-01-01');
  for (const value of [false, 'true', 1, null]) {
    await rejects(() => h.accept(request({...acceptInput(state), [field]: value})), 'invalid-argument');
  }
  assert.equal(h.db.writes.length, 1);
});
for (const field of ['uid', 'acceptedAt', 'guardianApproved', 'representativeUid', 'phase', 'aiTrainingConsent']) {
  test(`personal acceptance rejects untrusted ${field}`, async () => {
    const h = setup(), state = await declare(h, '2000-01-01');
    await rejects(() => h.accept(request({...acceptInput(state), [field]: 'forged'})), 'invalid-argument');
  });
}

test('V1 consent receipts do not imply V2 eligibility or independent acceptance', async () => {
  const h = setup(); const legacy = createConsentHandlers(h.dependencies);
  const old = await legacy.status(request()); await legacy.accept(request(acceptInput(old)));
  assert.equal((await legacy.status(request())).required, false);
  const undeclared = await h.status(request()); assert.equal(undeclared.canProceed, false);
  const adult = await declare(h, '2000-01-01'); assert.equal(adult.userAccepted, false);
  await rejects(() => h.accept(request(acceptInput(old))), 'failed-precondition');
  assert.equal((await accept(h, adult)).canProceed, true);
});

test('acceptance rejects a context from another account', async () => {
  const h = setup(), alice = await declare(h, '2000-01-01'); const bob = await declare(h, '2000-01-01', 'bob');
  await rejects(() => h.accept(request(acceptInput(alice), 'bob')), 'failed-precondition');
  assert.notEqual(alice.acceptanceContext, bob.acceptanceContext);
  assert.equal((await h.status(request({}, 'bob'))).userAccepted, false);
});

test('publication changes require new user and represented-person approvals', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state));
  assert.equal((await accept(h, state)).canProceed, true);
  h.db.edit('legalPolicy/current', p => {p.documents[0].body += '\nتغيير اختباري.';});
  const changed = await h.status(request()); assert.equal(changed.userAccepted, false); assert.equal(changed.representativeVerified, false);
  await rejects(() => h.accept(request(acceptInput(state))), 'failed-precondition');
  await h.accept(request(acceptInput(changed))); assert.equal((await h.status(request())).canProceed, false);
});

test('declaration correction with a new server revision invalidates both approvals', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state)); await accept(h, state);
  // Simulate a future reviewed correction boundary; no correction API exists in this slice.
  h.db.edit(declarationPath(), d => {d.declarationId = 'e'.repeat(32);});
  const changed = await h.status(request()); assert.equal(changed.userAccepted, false); assert.equal(changed.representativeVerified, false);
  await rejects(() => h.accept(request(acceptInput(state))), 'failed-precondition');
});

for (const [name, mutate] of [
  ['wrong UID', d => {d.uid = 'bob';}], ['invalid date', d => {d.birthDate = '2000-02-30';}],
  ['client timestamp', d => {d.declaredAt = 'now';}], ['future declaration', d => {d.declaredAt = stamp(NOW + 1);}],
  ['unconfirmed declaration', d => {d.accuracyConfirmed = false;}], ['wrong rules', d => {d.rulesVersion = 'other';}],
  ['empty revision', d => {d.declarationId = '';}], ['claimed verification', d => {d.source = 'verified';}],
]) test(`corrupt declaration fails closed: ${name}`, async () => {
  const h = setup(); await declare(h, '2000-01-01'); h.db.edit(declarationPath(), mutate);
  await rejects(() => h.status(request()), 'failed-precondition');
});
for (const [name, mutate] of [
  ['UID', r => {r.uid = 'bob';}], ['phase', r => {r.phase = 'represented';}],
  ['schema version', r => {r.schemaVersion = 1;}], ['timestamp', r => {r.acceptedAt = 'now';}],
  ['future time', r => {r.acceptedAt = stamp(NOW + 1);}], ['backdate', r => {r.acceptedAt = stamp(NOW - 1);}],
  ['consent flag', r => {r.communityAccepted = false;}], ['document hash', r => {r.documents[0].sha256 = 'f'.repeat(64);}],
]) test(`corrupt receipt fails closed without overwriting ${name}`, async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); await accept(h, state);
  h.db.edit(receiptPath(state), mutate); const writes = h.db.writes.length;
  await rejects(() => h.status(request()), 'failed-precondition');
  await rejects(() => h.accept(request(acceptInput(state))), 'failed-precondition'); assert.equal(h.db.writes.length, writes);
});
for (const corrupt of ['missing', 'body', 'title']) test(`archive integrity: ${corrupt}`, async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); await accept(h, state);
  if (corrupt === 'missing') h.db.remove(archivePath(state));
  else h.db.edit(archivePath(state), a => {a.documents[0][corrupt] += 'tampered';});
  await rejects(() => h.status(request()), 'failed-precondition');
});

test('lost acceptance response is idempotent and preserves the original server time', async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); await accept(h, state);
  const original = h.db.docs.get(receiptPath(state)).acceptedAt.toMillis(), writes = h.db.writes.length;
  h.clock += 10000;
  assert.equal((await h.accept(request(acceptInput(state)))).alreadyAccepted, true);
  assert.equal(h.db.docs.get(receiptPath(state)).acceptedAt.toMillis(), original); assert.equal(h.db.writes.length, writes);
});

test('two serialized simultaneous acceptance calls create one receipt', async () => {
  const h = setup(), state = await declare(h, '2000-01-01');
  const results = await Promise.all([h.accept(request(acceptInput(state))), h.accept(request(acceptInput(state)))]);
  assert.deepEqual(results.map(r => r.alreadyAccepted).sort(), [false, true]); assert.equal(h.db.writes.length, 3);
});

test('transaction retry uses the same generated declaration identity', async () => {
  const h = setup(), state = await h.status(request());
  h.db.beforeCommit = (db, attempt) => {if (attempt === 0) db.seed('users/alice', {displayName: 'changed'});};
  await h.declareBirthDate(request(declareInput(state, '2000-01-01')));
  assert.equal(h.ids, 1); assert.equal(h.db.docs.get(declarationPath()).declarationId, '0'.repeat(31) + '1');
  assert.equal(h.db.writes.length, 1);
});

test('policy update during the fake transaction causes a retry and refuses stale acceptance atomically', async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); const writes = h.db.writes.length;
  h.db.beforeCommit = (db, attempt) => {if (attempt === 0) db.edit('legalPolicy/current', p => {p.documents[0].version = 'test-2';});};
  await rejects(() => h.accept(request(acceptInput(state))), 'failed-precondition');
  assert.equal(h.db.docs.has(receiptPath(state)), false); assert.equal(h.db.docs.has(archivePath(state)), false);
  assert.equal(h.db.writes.length, writes);
});

test('revocation during the fake protected transaction prevents the pending write on retry', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state)); await accept(h, state);
  h.db.beforeCommit = (db, attempt) => {if (attempt === 0) db.edit(approvalPath(), a => {a.status = 'revoked';});};
  await rejects(() => guardedWrite(h), 'failed-precondition'); assert.equal(h.db.docs.has('testProtectedWrites/alice'), false);
});

test('authentication cutoff published during a fake transaction prevents the pending write', async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); await accept(h, state);
  h.db.beforeCommit = (db, attempt) => {if (attempt === 0) db.seed('authRevocations/alice', {revokedBefore: 1000});};
  await rejects(() => guardedWrite(h), 'unauthenticated'); assert.equal(h.db.docs.has('testProtectedWrites/alice'), false);
});

test('commit failure leaves no partial archive or acceptance', async () => {
  const h = setup(), state = await declare(h, '2000-01-01'); h.db.failCommit = true;
  await assert.rejects(() => h.accept(request(acceptInput(state))), /simulated atomic commit failure/);
  assert.equal(h.db.docs.has(receiptPath(state)), false); assert.equal(h.db.docs.has(archivePath(state)), false);
});

test('status and receipts omit birth date, representative identity and optional-processing permission', async () => {
  const h = setup(), state = await declare(h, '2008-09-16'); h.db.seed(approvalPath(), verifiedApproval(h, state));
  const ready = await accept(h, state), receipt = h.db.docs.get(receiptPath(state));
  for (const value of [ready, receipt]) {
    const json = JSON.stringify(value);
    for (const sensitive of ['2008-09-16', 'test-representative', 'test-reviewer', 'TEST-CASE-001']) assert.equal(json.includes(sensitive), false);
    assert.equal(Object.hasOwn(value, 'aiTrainingConsent'), false);
  }
  assert.deepEqual(Object.keys(receipt).sort(), ['schemaVersion', 'uid', 'context', 'fingerprint', 'declarationId', 'phase',
    'rulesVersion', 'language', 'documents', 'source', 'acceptedAt', 'termsAccepted', 'communityAccepted', 'privacyAcknowledged'].sort());
});

test('registration adds exactly three preview endpoints without replacing existing exports', () => {
  const source = readFileSync(require.resolve('../legal/register-eligibility'), 'utf8');
  const exports = {existingCallable: 'preserved'}, module = {exports: {}};
  const dependencies = {
    'firebase-functions/v2/https': {onCall: (options, handler) => ({options, handler}), HttpsError},
    'firebase-admin/auth': {getAuth: () => ({})},
    'firebase-admin/firestore': {getFirestore: () => ({}), FieldValue: {}},
    './eligibility-consent': {createEligibilityConsentHandlers: () => ({status: 'status', declareBirthDate: 'declare', accept: 'accept'})},
  };
  vm.runInNewContext(source, {module, require: name => {assert.ok(Object.hasOwn(dependencies, name)); return dependencies[name];}});
  module.exports(exports);
  assert.deepEqual(Object.keys(exports).sort(), ['acceptEligibleLegalDocuments', 'declareLegalBirthDate', 'existingCallable', 'readLegalEligibilityStatus']);
  assert.equal(exports.existingCallable, 'preserved'); assert.equal(exports.declareLegalBirthDate.handler, 'declare');
  assert.equal(exports.readLegalEligibilityStatus.options.region, 'europe-west1');
});


test('representative acceptance recorded before 18 cannot become valid merely when the birthday arrives', async () => {
  const h = setup(Date.parse('2026-09-15T22:59:59Z')), underAge = await declare(h, '2008-09-16');
  h.db.seed(approvalPath(), verifiedApproval(h, underAge));
  h.clock = Date.parse('2026-09-15T23:00:00Z');
  const now18 = await h.status(request());
  await h.accept(request(acceptInput(now18)));
  assert.equal((await h.status(request())).canProceed, false);
});
