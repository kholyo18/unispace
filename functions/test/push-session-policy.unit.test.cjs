const { test } = require('node:test');
const assert = require('node:assert/strict');
const { validAuthTime, cutoffAllows, bindingAllows, registrationMatches } = require('../security/push-session-policy');
const timestamp = n => ({ toMillis: () => n, isEqual: other => other?.toMillis?.() === n });
function data() {
  return { binding: { ownerId: 'owner', authTime: 101, sessionId: 'device', sessionCreatedAt: timestamp(42) },
    userId: 'owner', cutoff: { revokedBefore: 100 },
    session: { sessionId: 'device', createdAt: timestamp(42), isRevoked: false } };
}
test('authentication timestamps must be nonnegative safe integers', () => {
  for (const v of [0, 100, Number.MAX_SAFE_INTEGER]) assert.equal(validAuthTime(v), true);
  for (const v of [null, undefined, '100', {}, NaN, Infinity, -1, 1.5, Number.MAX_SAFE_INTEGER + 1]) assert.equal(validAuthTime(v), false);
});
test('absent cutoff accepts valid authentication but equality is revoked', () => {
  assert.equal(cutoffAllows(100, null), true);
  assert.equal(cutoffAllows(100, { revokedBefore: 99 }), true);
  assert.equal(cutoffAllows(100, { revokedBefore: 100 }), false);
  assert.equal(cutoffAllows(100, { revokedBefore: 101 }), false);
});
test('malformed cutoff documents fail closed', () => {
  for (const c of [{}, { revokedBefore: null }, { revokedBefore: '99' }, { revokedBefore: -1 }, { revokedBefore: 0.5 }]) {
    assert.equal(cutoffAllows(100, c), false);
  }
});
test('valid current server binding and session allow delivery', () => {
  assert.equal(bindingAllows(data()), true);
});
test('missing binding cannot authorize a legacy raw token', () => {
  assert.equal(bindingAllows({ ...data(), binding: null }), false);
});
test('binding owner must equal the recipient', () => {
  assert.equal(bindingAllows({ ...data(), userId: 'other' }), false);
});
test('legacy binding without a device session requires synchronization', () => {
  const d = data(); delete d.binding.sessionId; assert.equal(bindingAllows(d), false);
});
test('malformed device identifiers fail closed', () => {
  for (const id of ['', '.', '..', 'a/b', 'x'.repeat(129)]) {
    const d = data(); d.binding.sessionId = id; assert.equal(bindingAllows(d), false);
  }
});
test('missing, revoked and wrong-ID sessions deny delivery', () => {
  for (const session of [null, { ...data().session, isRevoked: true }, { ...data().session, sessionId: 'other' }]) {
    assert.equal(bindingAllows({ ...data(), session }), false);
  }
});
test('recreated sessions cannot reuse the earlier binding', () => {
  const d = data(); d.session.createdAt = timestamp(43); assert.equal(bindingAllows(d), false);
});
test('missing or malformed session creation timestamps deny delivery', () => {
  const d = data(); delete d.binding.sessionCreatedAt; assert.equal(bindingAllows(d), false);
  const e = data(); e.session.createdAt = '42'; assert.equal(bindingAllows(e), false);
});
test('valid global revocation cutoffs apply to bindings', () => {
  const d = data(); d.cutoff.revokedBefore = d.binding.authTime; assert.equal(bindingAllows(d), false);
});
test('canonical registration must match binding session and auth time', () => {
  const binding = data().binding;
  const record = { authTime: 101, sessionId: 'device', preferences: { enabled: true, community: true, announcements: false, exams: false } };
  assert.equal(registrationMatches(record, binding), true);
  assert.equal(registrationMatches({ ...record, authTime: 100 }, binding), false);
  assert.equal(registrationMatches({ ...record, sessionId: 'other' }, binding), false);
});
test('missing or malformed registration preferences are not assumed enabled', () => {
  const binding = data().binding;
  for (const preferences of [null, {}, [], { enabled: true }, { enabled: 'true', community: true, announcements: true, exams: true }]) {
    assert.equal(registrationMatches({ authTime: 101, sessionId: 'device', preferences }, binding), false);
  }
});
