const { HttpsError } = require('firebase-functions/v2/https');

// The callable SDK authenticates request.auth; each existing handler retains its
// own verified-token, revocation and operation-specific checks. This additional
// gate prevents an authenticated suspended caller from using a reader that only
// checks the TARGET profile. Do not apply it to deletion/sign-out cleanup paths.
function createAccountAccessGuard({ db }) {
  return handler => async request => {
    const uid = request.auth?.uid;
    if (uid != null) {
      if (typeof uid !== 'string' || !uid.length || uid.length > 128 || uid.includes('/') || ['.', '..'].includes(uid)) {
        throw new HttpsError('unauthenticated', 'Invalid account.');
      }
      const snapshot = await db.doc(`accountStateControls/${uid}`).get();
      if (snapshot.exists) {
        const c = snapshot.data();
        if (c.schemaVersion !== 1 || !Number.isSafeInteger(c.revision) || c.revision < 1 ||
            typeof c.selfDisabled !== 'boolean' || typeof c.selfFrozen !== 'boolean' || c.adminSuspended !== false) {
          throw new HttpsError('permission-denied', 'Account access requires review.');
        }
      }
    }
    return handler(request);
  };
}
module.exports = { createAccountAccessGuard };
