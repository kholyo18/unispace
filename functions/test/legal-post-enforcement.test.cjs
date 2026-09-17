'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {POST_ENFORCEMENT_PATH, postCreationEnforced} = require('../legal/post-enforcement');
class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const snapshot = config => ({exists: true, data: () => config});

test('rollout path is separate from editable profiles and legal receipts', () => {
  assert.equal(POST_ENFORCEMENT_PATH, 'legalEnforcement/postCreation');
});
test('absent rollout is off without reading or creating a consent record', () => {
  assert.equal(postCreationEnforced({exists: false, data: () => {throw Error('unexpected');}}, HttpsError), false);
});
for (const enabled of [false, true]) {
  test(`only a valid versioned boolean configuration returns ${enabled}`, () => {
    assert.equal(postCreationEnforced(snapshot({schemaVersion: 1, enabled}), HttpsError), enabled);
  });
}
for (const config of [null, undefined, [], '', true, {}, {enabled: true}, {schemaVersion: 1},
  {schemaVersion: 2, enabled: true}, {schemaVersion: '1', enabled: true},
  {schemaVersion: 1, enabled: 'false'}, {schemaVersion: 1, enabled: 0},
  {schemaVersion: 1, enabled: null}, {schemaVersion: 1, enabled: true, bypass: true},
  {schemaVersion: 1, enabled: false, extra: 'unknown'}]) {
  test(`malformed existing rollout fails closed: ${JSON.stringify(config)}`, () => {
    assert.throws(() => postCreationEnforced(snapshot(config), HttpsError), error => error.code === 'failed-precondition');
  });
}
test('a read/decoding failure is not converted to off', () => {
  assert.throws(() => postCreationEnforced({exists: true, data: () => {throw Error('read failed');}}, HttpsError), /read failed/);
});
