const { HttpsError } = require('firebase-functions/v2/https');
const STORE_URL = 'https://play.google.com/store/apps/details?id=dz.fachub.fachub';
async function readPolicy(db) {
  const row = await db.doc('releasePolicy/android').get();
  if (!row.exists) return { enabled: false, minimumBuild: 1, storeUrl: STORE_URL };
  const data = row.data();
  if (typeof data?.enabled !== 'boolean' || !Number.isSafeInteger(data.minimumBuild) || data.minimumBuild < 1) {
    throw new HttpsError('failed-precondition', 'Release policy is unavailable.');
  }
  return { enabled: data.enabled, minimumBuild: data.minimumBuild, storeUrl: STORE_URL };
}
function createReleasePolicyReader({ db }) {
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 0) {
      throw new HttpsError('invalid-argument', 'An empty request is required.');
    }
    return readPolicy(db);
  };
}
// Compatibility gate only: session buildNumber is client-maintained metadata,
// not an attestation of a trustworthy binary. Media ACLs remain independent.
function createReleaseVersionGuard({ db }) {
  return handler => async request => {
    const policy = await readPolicy(db);
    if (policy.enabled && request.auth) {
      const uid = request.auth.uid, sid = request.auth.token?.sid;
      let build;
      if (typeof uid === 'string' && uid.length > 0 && !uid.includes('/') &&
          typeof sid === 'string' && /^[a-f0-9]{64}$/.test(sid)) {
        build = (await db.doc(`users/${uid}/sessions/${sid}`).get()).data()?.buildNumber;
      }
      if (typeof build !== 'string' || !/^[0-9]+$/.test(build) ||
          !Number.isSafeInteger(Number(build)) || Number(build) < policy.minimumBuild) {
        throw new HttpsError('failed-precondition', 'Update UniSpace to continue.',
          { reason: 'app-update-required', minimumBuild: policy.minimumBuild });
      }
    }
    return handler(request);
  };
}
module.exports = { createReleasePolicyReader, createReleaseVersionGuard };
