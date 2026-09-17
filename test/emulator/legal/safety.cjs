'use strict';

// Refuse to initialize an Admin SDK or make a request outside this disposable suite.
const PROJECT = 'demo-unispace-legal-integration';
const HOSTS = Object.freeze({
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9189',
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8189',
  UNISPACE_LEGAL_FUNCTIONS_HOST: '127.0.0.1:5189',
});
function assertEmulatorOnly(env = process.env) {
  if (env.UNISPACE_LEGAL_EMULATOR_TEST !== '1' || env.GCLOUD_PROJECT !== PROJECT) {
    throw new Error('Legal emulator tests require the dedicated demo project and explicit opt-in.');
  }
  for (const [key, value] of Object.entries(HOSTS)) {
    if (env[key] !== value) throw new Error(`Unsafe or missing emulator endpoint: ${key}`);
  }
  for (const name of ['GOOGLE_CLOUD_PROJECT', 'GCP_PROJECT']) {
    if (env[name] && env[name] !== PROJECT) throw new Error(`Mismatched demo project: ${name}`);
  }
  for (const name of ['GOOGLE_APPLICATION_CREDENTIALS', 'FIREBASE_TOKEN', 'CLOUDSDK_AUTH_ACCESS_TOKEN']) {
    if (env[name]) throw new Error(`Cloud credentials are forbidden in this suite: ${name}`);
  }
  if (env.FIREBASE_CONFIG) {
    let config;
    try { config = JSON.parse(env.FIREBASE_CONFIG); }
    catch (_) { throw new Error('Expected inline demo FIREBASE_CONFIG, not a credentials file.'); }
    if (config.projectId !== PROJECT) throw new Error('FIREBASE_CONFIG is not the demo project.');
  }
  return PROJECT;
}
async function localJson(url, options = {}) {
  assertEmulatorOnly();
  const target = new URL(url);
  if (target.protocol !== 'http:' || target.username || target.password ||
      !Object.values(HOSTS).includes(target.host)) throw new Error('Non-emulator URL refused.');
  const response = await fetch(target, {...options, redirect: 'error', signal: AbortSignal.timeout(45000)});
  const body = await response.json();
  return {status: response.status, body};
}
module.exports = {PROJECT, HOSTS, assertEmulatorOnly, localJson};
