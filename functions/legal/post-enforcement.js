'use strict';

// Server-owned rollout control, read inside BOTH reservation/publication transactions.
// Absence preserves pre-rollout behavior; it never counts as legal acceptance.
// Clients must have no access to this namespace. Never cache the result per user.
const POST_ENFORCEMENT_PATH = 'legalEnforcement/postCreation';

function postCreationEnforced(snapshot, HttpsError) {
  if (!snapshot.exists) return false;
  const config = snapshot.data();
  if (!config || typeof config !== 'object' || Array.isArray(config) ||
      Object.keys(config).length !== 2 || config.schemaVersion !== 1 ||
      typeof config.enabled !== 'boolean') {
    throw new HttpsError('failed-precondition', 'Post eligibility configuration needs review.');
  }
  return config.enabled;
}

module.exports = {POST_ENFORCEMENT_PATH, postCreationEnforced};
