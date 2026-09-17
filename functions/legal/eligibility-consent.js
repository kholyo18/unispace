'use strict';

const {createHash, randomBytes} = require('node:crypto');
const {parsePolicy} = require('./consent');
const {RULES_VERSION, TIME_ZONE, classifyBirthDate, timestampMillis, validUid,
  validateDeclaration, representativeIsVerified} = require('./eligibility');
const hash = value => createHash('sha256').update(JSON.stringify(value), 'utf8').digest('hex');
const isHash = value => typeof value === 'string' && /^[a-f0-9]{64}(?![\s\S])/.test(value);
const exactKeys = (value, keys) => value !== null && typeof value === 'object' && !Array.isArray(value) &&
  Object.keys(value).length === keys.length && keys.every(key => Object.hasOwn(value, key));
const documents = policy => policy.documents.map(({id, version, sha256}) => ({id, version, sha256}));
const sameDocuments = (a, b, keys) => Array.isArray(a) && a.length === b.length &&
  a.every((document, i) => document && keys.every(key => document[key] === b[i][key]));
const declarationContext = (uid, fingerprint) => hash(['unispace/birth-declaration/v1', uid, fingerprint, RULES_VERSION]);
const acceptanceContext = (uid, policy, declaration, phase) =>
  hash(['unispace/eligibility-consent/v1', uid, policy.fingerprint, declaration.declarationId, phase, RULES_VERSION]);

function archiveValid(archive, policy) {
  return archive && archive.schemaVersion === 1 && archive.fingerprint === policy.fingerprint &&
    archive.language === policy.language && archive.operatorName === policy.operatorName &&
    archive.publishedAt === policy.publishedAt &&
    sameDocuments(archive.documents, policy.documents, ['id', 'version', 'title', 'body', 'sha256']);
}

function receiptValid(receipt, state, now) {
  const {uid, policy, declaration, phase, context} = state;
  const acceptedAt = timestampMillis(receipt?.acceptedAt);
  if (!receipt || receipt.schemaVersion !== 2 || receipt.uid !== uid || receipt.context !== context ||
      receipt.fingerprint !== policy.fingerprint || receipt.declarationId !== declaration.declarationId ||
      receipt.phase !== phase || receipt.rulesVersion !== RULES_VERSION || receipt.language !== policy.language ||
      receipt.source !== 'explicit_in_app' || receipt.termsAccepted !== true || receipt.communityAccepted !== true ||
      receipt.privacyAcknowledged !== true || acceptedAt === null || acceptedAt > now ||
      acceptedAt < Math.max(timestampMillis(declaration.declaredAt), Date.parse(policy.publishedAt)) ||
      !sameDocuments(receipt.documents, documents(policy), ['id', 'version', 'sha256'])) return false;
  // A backdated or phase-mismatched administrative record never counts as new adult consent.
  return classifyBirthDate(declaration.birthDate, acceptedAt) === phase;
}

/**
 * V2 preview APIs. No existing API is replaced, and no live account is activated.
 * The entire transaction boundary must be used by future protected mutations;
 * a status response is informational, never a reusable authorization token.
 */
function createEligibilityConsentHandlers({auth, db, FieldValue, HttpsError, now = Date.now,
  makeDeclarationId = () => randomBytes(16).toString('hex')}) {
  async function authenticate(request) {
    const uid = request?.auth?.uid;
    const header = request?.rawRequest?.headers?.authorization;
    if (!validUid(uid) || typeof header !== 'string' || !/^Bearer \S+(?![\s\S])/.test(header)) {
      throw new HttpsError('unauthenticated', 'Sign in first.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (!token || token.uid !== uid || !Number.isSafeInteger(token.auth_time) || token.auth_time < 0 ||
        token.firebase?.tenant != null) throw new HttpsError('unauthenticated', 'Invalid session.');
    return {uid, token};
  }

  async function readRoot(tx, identity, clock) {
    const {uid, token} = identity;
    const [config, cutoff, account] = await tx.getAll(
      db.doc('legalPolicy/current'), db.doc(`authRevocations/${uid}`), db.doc(`users/${uid}`));
    if (token.auth_time > Math.floor(clock / 1000)) throw new HttpsError('unauthenticated', 'Invalid authentication time.');
    if (cutoff.exists) {
      const boundary = cutoff.data()?.revokedBefore;
      if (!Number.isSafeInteger(boundary) || boundary < 0) throw new HttpsError('failed-precondition', 'Session state unavailable.');
      if (token.auth_time <= boundary) throw new HttpsError('unauthenticated', 'Session revoked.');
    }
    const user = account.data();
    if (user && (['disabled', 'deleted'].includes(user.accountStatus) || user.isDeleted === true || user.security?.frozen === true)) {
      throw new HttpsError('permission-denied', 'Account unavailable.');
    }
    // Never import birthDate, guardian flags or eligibility from the editable profile.
    return parsePolicy(config.data(), HttpsError, clock);
  }

  async function readState(tx, identity, clock) {
    const {uid} = identity;
    const policy = await readRoot(tx, identity, clock);
    if (!policy) return {uid, policy: null};
    const declared = await tx.get(db.doc(`legalEligibilityDeclarations/${uid}`));
    if (!declared.exists) return {uid, policy, phase: 'birth_date_required'};
    const {record: declaration, phase} = validateDeclaration(declared.data(), uid, clock, HttpsError);
    const state = {uid, policy, declaration, phase};
    if (phase === 'under_minimum_age') return state;
    state.context = acceptanceContext(uid, policy, declaration, phase);
    state.receiptRef = db.doc(`legalEligibilityReceipts/${uid}/receipts/${state.context}`);
    state.archiveRef = db.doc(`legalPolicyVersions/${policy.fingerprint}`);
    const refs = [state.receiptRef, state.archiveRef];
    if (phase === 'represented') refs.push(db.doc(`legalRepresentativeApprovals/${uid}`));
    const [receipt, archive, approval] = await tx.getAll(...refs);
    state.receiptExists = receipt.exists;
    state.archiveExists = archive.exists;
    if (archive.exists && !archiveValid(archive.data(), policy)) {
      throw new HttpsError('failed-precondition', 'Policy archive needs review.');
    }
    if (receipt.exists && (!archive.exists || !receiptValid(receipt.data(), state, clock))) {
      throw new HttpsError('failed-precondition', 'Eligibility receipt needs review.');
    }
    state.representativeVerified = phase === 'represented' &&
      representativeIsVerified(approval?.data(), declaration, policy, clock);
    return state;
  }

  function publicStatus(state) {
    const {uid, policy, phase} = state;
    const common = {schemaVersion: 2, uid, rulesVersion: RULES_VERSION, timeZone: TIME_ZONE};
    if (!policy) return {...common, enabled: false, state: 'not_configured', canAccept: false,
      canProceed: false, userAccepted: false};
    const publication = {policy, declarationContext: declarationContext(uid, policy.fingerprint)};
    if (phase === 'birth_date_required' || phase === 'under_minimum_age') {
      return {...common, ...publication, enabled: true, state: phase, canAccept: false,
        canProceed: false, userAccepted: false};
    }
    const userAccepted = state.receiptExists;
    const canProceed = userAccepted && (phase === 'independent' || state.representativeVerified);
    const result = canProceed ? 'ready' : userAccepted ? 'representative_required' :
      phase === 'independent' ? 'independent_consent_required' : 'personal_consent_required';
    return {...common, ...publication, enabled: true, state: result, phase,
      canAccept: true, canProceed, userAccepted, representativeVerified: state.representativeVerified,
      acceptanceContext: state.context};
  }

  async function status(request) {
    if (!exactKeys(request?.data, [])) throw new HttpsError('invalid-argument', 'No parameters allowed.');
    const identity = await authenticate(request);
    return db.runTransaction(async tx => publicStatus(await readState(tx, identity, now())));
  }

  async function declareBirthDate(request) {
    const input = request?.data;
    if (!exactKeys(input, ['birthDate', 'declarationContext', 'accuracyConfirmed']) ||
        input.accuracyConfirmed !== true || !isHash(input.declarationContext) || typeof input.birthDate !== 'string') {
      throw new HttpsError('invalid-argument', 'Confirm the birth date explicitly.');
    }
    const identity = await authenticate(request);
    // Stable on automatic Firestore transaction retries; no external side effects in the callback.
    const declarationId = makeDeclarationId();
    if (typeof declarationId !== 'string' || !/^[a-f0-9]{32}(?![\s\S])/.test(declarationId)) {
      throw new HttpsError('internal', 'Unable to create declaration.');
    }
    return db.runTransaction(async tx => {
      const clock = now();
      try { classifyBirthDate(input.birthDate, clock); }
      catch (_) { throw new HttpsError('invalid-argument', 'Use a valid Gregorian date in YYYY-MM-DD form.'); }
      const policy = await readRoot(tx, identity, clock);
      if (!policy || input.declarationContext !== declarationContext(identity.uid, policy.fingerprint)) {
        throw new HttpsError('failed-precondition', 'Account or documents changed. Reload.');
      }
      const ref = db.doc(`legalEligibilityDeclarations/${identity.uid}`);
      const existing = await tx.get(ref);
      if (existing.exists) {
        const {record} = validateDeclaration(existing.data(), identity.uid, clock, HttpsError);
        if (record.birthDate !== input.birthDate) {
          throw new HttpsError('failed-precondition', 'Use the reviewed correction process.');
        }
        return {uid: identity.uid, recorded: true, alreadyRecorded: true};
      }
      tx.create(ref, {schemaVersion: 1, uid: identity.uid, declarationId, rulesVersion: RULES_VERSION,
        birthDate: input.birthDate, source: 'self_declared', accuracyConfirmed: true,
        declaredAt: FieldValue.serverTimestamp()});
      return {uid: identity.uid, recorded: true, alreadyRecorded: false};
    });
  }

  async function accept(request) {
    const input = request?.data;
    if (!exactKeys(input, ['fingerprint', 'acceptanceContext', 'termsAccepted', 'communityAccepted', 'privacyAcknowledged']) ||
        !isHash(input.fingerprint) || !isHash(input.acceptanceContext) || input.termsAccepted !== true ||
        input.communityAccepted !== true || input.privacyAcknowledged !== true) {
      throw new HttpsError('invalid-argument', 'Explicit acceptance is required.');
    }
    const identity = await authenticate(request);
    return db.runTransaction(async tx => {
      const state = await readState(tx, identity, now());
      if (!state.policy || !state.context || input.fingerprint !== state.policy.fingerprint || input.acceptanceContext !== state.context) {
        throw new HttpsError('failed-precondition', 'Eligibility, account or documents changed. Reload.');
      }
      if (state.receiptExists) return {uid: identity.uid, accepted: true, alreadyAccepted: true};
      const acceptedAt = FieldValue.serverTimestamp();
      // All policy, eligibility, revocation, receipt and archive reads occur before writes.
      if (!state.archiveExists) tx.create(state.archiveRef, {...state.policy, archivedAt: acceptedAt});
      tx.create(state.receiptRef, {schemaVersion: 2, uid: identity.uid, context: state.context,
        fingerprint: state.policy.fingerprint, declarationId: state.declaration.declarationId,
        phase: state.phase, rulesVersion: RULES_VERSION, language: state.policy.language,
        documents: documents(state.policy), source: 'explicit_in_app', acceptedAt,
        termsAccepted: true, communityAccepted: true, privacyAcknowledged: true});
      // Recording personal consent is not evidence of a representative's authority or account activation.
      return {uid: identity.uid, accepted: true, alreadyAccepted: false};
    });
  }

  async function assertInTransaction(tx, request) {
    const identity = await authenticate(request);
    const state = await readState(tx, identity, now());
    if (!publicStatus(state).canProceed) throw new HttpsError('failed-precondition', 'Current eligibility and consent are required.');
    return {uid: identity.uid, fingerprint: state.policy.fingerprint, phase: state.phase};
  }

  // No callable for granting representative approval is exposed.
  return {status, declareBirthDate, accept, assertInTransaction};
}

module.exports = {createEligibilityConsentHandlers};
