const { test } = require('node:test');
const assert = require('node:assert/strict');
const { authCutoffAllows, cutoffAllows } = require('../security/push-session-policy');
const cutoff = 'Thu, 01 Jan 1970 00:01:40 GMT'; // 100 seconds, independently fixed.

test('Auth cutoff rejects authentication older than its timestamp', () => {
  assert.equal(authCutoffAllows(99, cutoff), false);
  assert.equal(authCutoffAllows(0, cutoff), false);
});
test('Auth cutoff equality follows the Admin SDK and preserves the distinct Firestore boundary', () => {
  assert.equal(authCutoffAllows(100, cutoff), true);
  assert.equal(cutoffAllows(100, { revokedBefore: 100 }), false);
});
test('authentication after the Auth cutoff is eligible', () => {
  assert.equal(authCutoffAllows(101, cutoff), true);
});
test('UTC and ISO metadata encode the same instant without dropping fractional milliseconds', () => {
  assert.equal(authCutoffAllows(100, '1970-01-01T00:01:40.000Z'), true);
  assert.equal(authCutoffAllows(100, '1970-01-01T00:01:40.001Z'), false);
  assert.equal(authCutoffAllows(101, '1970-01-01T00:01:40.001Z'), true);
});
test('absent optional Auth cutoff accepts only valid authentication times', () => {
  for (const value of [0, 100, Number.MAX_SAFE_INTEGER]) assert.equal(authCutoffAllows(value, undefined), true);
  for (const value of [undefined, null, '100', {}, [], NaN, Infinity, -1, 1.5, Number.MAX_SAFE_INTEGER + 1]) {
    assert.equal(authCutoffAllows(value, undefined), false);
  }
});
test('invalid authentication timestamps cannot pass a valid Auth cutoff', () => {
  for (const value of [undefined, null, '100', {}, [], NaN, Infinity, -1, 1.5, Number.MAX_SAFE_INTEGER + 1]) {
    assert.equal(authCutoffAllows(value, cutoff), false);
  }
});
test('explicit non-string cutoff values are not treated as absent or coerced', () => {
  for (const value of [null, false, true, 0, 100000, NaN, Infinity, [], {}, new Date(100000)]) {
    assert.equal(authCutoffAllows(101, value), false);
  }
});
test('invalid, blank, out-of-range and negative cutoff dates fail closed', () => {
  for (const value of ['', ' ', 'not-a-date', 'Infinity', '+999999-01-01T00:00:00Z', '1969-12-31T23:59:59Z']) {
    assert.equal(authCutoffAllows(101, value), false);
  }
});
test('the Unix epoch is a valid Auth cutoff rather than an absent value', () => {
  assert.equal(authCutoffAllows(0, 'Thu, 01 Jan 1970 00:00:00 GMT'), true);
  assert.equal(authCutoffAllows(-1, 'Thu, 01 Jan 1970 00:00:00 GMT'), false);
});
