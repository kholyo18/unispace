'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {PROJECT, HOSTS, assertEmulatorOnly} = require('./safety.cjs');
const safe = () => ({UNISPACE_LEGAL_EMULATOR_TEST: '1', GCLOUD_PROJECT: PROJECT, ...HOSTS});
test('explicit loopback-only demo configuration is accepted', () => assert.equal(assertEmulatorOnly(safe()), PROJECT));
for (const key of ['UNISPACE_LEGAL_EMULATOR_TEST', 'GCLOUD_PROJECT', ...Object.keys(HOSTS)]) {
  test(`missing ${key} is refused before SDK initialization`, () => {
    const env = safe(); delete env[key]; assert.throws(() => assertEmulatorOnly(env));
  });
}
for (const key of Object.keys(HOSTS)) {
  test(`external host in ${key} is refused`, () => assert.throws(() => assertEmulatorOnly({...safe(), [key]: 'example.com:443'})));
}
for (const key of ['GOOGLE_APPLICATION_CREDENTIALS', 'FIREBASE_TOKEN', 'CLOUDSDK_AUTH_ACCESS_TOKEN']) {
  test(`credential setting ${key} is refused`, () => assert.throws(() => assertEmulatorOnly({...safe(), [key]: 'not-a-real-secret'})));
}
test('non-demo project is refused', () => assert.throws(() => assertEmulatorOnly({...safe(), GCLOUD_PROJECT: 'production-project'})));
test('conflicting project aliases are refused', () => {
  for (const key of ['GOOGLE_CLOUD_PROJECT', 'GCP_PROJECT']) assert.throws(() => assertEmulatorOnly({...safe(), [key]: 'other'}));
});
test('inline Firebase configuration must also use the demo project', () => {
  for (const value of ['/private/file.json', '{}', '{"projectId":"other"}']) {
    assert.throws(() => assertEmulatorOnly({...safe(), FIREBASE_CONFIG: value}));
  }
  assert.equal(assertEmulatorOnly({...safe(), FIREBASE_CONFIG: JSON.stringify({projectId: PROJECT})}), PROJECT);
});
