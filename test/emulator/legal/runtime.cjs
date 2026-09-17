'use strict';
// Test-only Functions entry point, copied into a disposable sandbox by prepare.cjs.
// Never export this entry point from the application's functions/index.js.
const {assertEmulatorOnly, PROJECT} = require('../safety.cjs');
assertEmulatorOnly();
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
initializeApp({projectId: PROJECT});
const dependencies = {auth: getAuth(), db: getFirestore(), FieldValue, HttpsError};
const {createConsentHandlers} = require('./legal/consent');
const consent = createConsentHandlers(dependencies);
exports.readLegalConsentStatus = onCall({region: 'europe-west1'}, consent.status);
exports.acceptLegalDocuments = onCall({region: 'europe-west1'}, consent.accept);
require('./legal/register-eligibility')(exports);

// Exercise the application's exact post handler, with text-only content in this suite.
// No Storage SDK, real media or notification/email triggers are initialized.
const {createPostHandler} = require('./security/create-post');
const postDependencies = {...dependencies, bucket: () => ({
  name: `${PROJECT}.test-only`,
  file() { throw new Error('Media access is outside this emulator suite.'); },
})};
exports.reserveOwnPost = onCall({region: 'europe-west1'}, createPostHandler(postDependencies));
exports.publishOwnPost = onCall({region: 'europe-west1'}, createPostHandler(postDependencies, true));
