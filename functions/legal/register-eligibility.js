'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {createEligibilityConsentHandlers} = require('./eligibility-consent');

// Register only new preview names. Existing consent APIs/client remain unchanged.
module.exports = function registerEligibilityPreview(target) {
  const handlers = createEligibilityConsentHandlers({auth: getAuth(), db: getFirestore(), FieldValue, HttpsError});
  const options = {region: 'europe-west1', timeoutSeconds: 60};
  target.readLegalEligibilityStatus = onCall(options, handlers.status);
  target.declareLegalBirthDate = onCall(options, handlers.declareBirthDate);
  target.acceptEligibleLegalDocuments = onCall(options, handlers.accept);
};
