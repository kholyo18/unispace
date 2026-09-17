'use strict';

// Product rules selected for the preview; not a statement of legal compliance.
const RULES_VERSION = 'dz-18-19-v1';
const TIME_ZONE = 'Africa/Algiers';
const DATE = /^\d{4}-\d{2}-\d{2}(?![\s\S])/;
const ID = /^[a-f0-9]{32}(?![\s\S])/;
const formatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit',
});

function dateParts(value) {
  if (typeof value !== 'string' || !DATE.test(value)) return null;
  const [year, month, day] = value.split('-').map(Number);
  if (year < 1900 || year > 9999) return null;
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() + 1 !== month || date.getUTCDate() !== day) return null;
  return {year, month, day};
}

function localDate(milliseconds) {
  if (!Number.isSafeInteger(milliseconds) || milliseconds < 0 || milliseconds > 253402214399999) {
    throw new RangeError('Invalid server clock.');
  }
  const parts = Object.fromEntries(formatter.formatToParts(milliseconds).map(({type, value}) => [type, value]));
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function anniversary(birthDate, age) {
  const birth = dateParts(birthDate);
  if (!birth || ![18, 19].includes(age) || birth.year + age > 9999) throw new RangeError('Invalid anniversary.');
  // Conservative preview convention: Feb 29 matures on March 1 in non-leap years.
  // Confirm the final legal/operational convention before production activation.
  return new Date(Date.UTC(birth.year + age, birth.month - 1, birth.day)).toISOString().slice(0, 10);
}

function classifyBirthDate(birthDate, now) {
  const today = localDate(now);
  if (!dateParts(birthDate) || birthDate > today) throw new RangeError('Invalid birth date.');
  if (today < anniversary(birthDate, 18)) return 'under_minimum_age';
  if (today < anniversary(birthDate, 19)) return 'represented';
  return 'independent';
}

function timestampMillis(value) {
  try {
    const milliseconds = value?.toMillis?.();
    return Number.isSafeInteger(milliseconds) && milliseconds >= 0 ? milliseconds : null;
  } catch (_) { return null; }
}

function validUid(value) {
  return typeof value === 'string' && value.length > 0 && value.length <= 128 &&
    !value.includes('/') && value !== '.' && value !== '..' && value.trim() === value;
}

function validateDeclaration(record, uid, now, HttpsError) {
  const fail = () => { throw new HttpsError('failed-precondition', 'Eligibility declaration needs review.'); };
  if (!record || record.schemaVersion !== 1 || record.uid !== uid || record.rulesVersion !== RULES_VERSION ||
      record.source !== 'self_declared' || typeof record.declarationId !== 'string' || !ID.test(record.declarationId) ||
      record.accuracyConfirmed !== true || timestampMillis(record.declaredAt) === null ||
      timestampMillis(record.declaredAt) > now || !dateParts(record.birthDate)) return fail();
  try {
    // A declaration cannot predate its own stated birth date, either.
    if (record.birthDate > localDate(timestampMillis(record.declaredAt))) return fail();
    return {record, phase: classifyBirthDate(record.birthDate, now)};
  } catch (_) { return fail(); }
}

function representativeIsVerified(approval, declaration, policy, now) {
  if (!approval || approval.schemaVersion !== 1 || approval.status !== 'verified' ||
      approval.source !== 'verified_legal_representative_review' || approval.subjectUid !== declaration.uid ||
      approval.declarationId !== declaration.declarationId || approval.policyFingerprint !== policy.fingerprint ||
      approval.rulesVersion !== RULES_VERSION || approval.authorityVerified !== true ||
      approval.termsAccepted !== true || approval.communityAccepted !== true || approval.privacyAcknowledged !== true ||
      approval.revokedAt !== null || !validUid(approval.representativeUid) || !validUid(approval.reviewerUid) ||
      approval.representativeUid === declaration.uid || approval.reviewerUid === declaration.uid ||
      approval.reviewerUid === approval.representativeUid ||
      typeof approval.reviewReference !== 'string' || !/^[A-Za-z0-9_-]{1,120}(?![\s\S])/.test(approval.reviewReference)) return false;
  const accepted = timestampMillis(approval.acceptedAt);
  const verified = timestampMillis(approval.verifiedAt);
  const expires = timestampMillis(approval.expiresAt);
  const declared = timestampMillis(declaration.declaredAt);
  return accepted !== null && verified !== null && expires !== null && declared !== null &&
    accepted >= Math.max(declared, Date.parse(policy.publishedAt)) && accepted <= verified &&
    verified <= now && expires > now &&
    classifyBirthDate(declaration.birthDate, accepted) === 'represented';
}

module.exports = {RULES_VERSION, TIME_ZONE, dateParts, localDate, anniversary,
  classifyBirthDate, timestampMillis, validUid, validateDeclaration, representativeIsVerified};
