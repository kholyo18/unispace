'use strict';

const {createHash} = require('node:crypto');
const CONFIG_PATH = 'legalPolicy/current';
const RECEIPTS = 'legalConsentRecords';
const ARCHIVES = 'legalPolicyVersions';
const DOCUMENT_IDS = ['terms', 'community', 'privacy'];
const HASH_PATTERN = /^[a-f0-9]{64}$/;
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const digest = value => createHash('sha256').update(value, 'utf8').digest('hex');
const exactKeys = (value, keys) => object(value) && Object.keys(value).length === keys.length &&
  keys.every(key => Object.hasOwn(value, key));
const sameDocuments = (a, b, fields) => Array.isArray(a) && a.length === b.length &&
  a.every((item, i) => object(item) && fields.every(field => item[field] === b[i][field]));
const metadata = policy => policy.documents.map(({id, version, sha256}) => ({id, version, sha256}));
// This is a public identity binding, NOT a secret, authorization grant or proof of reading.
// It prevents an in-flight request for account A from recording acceptance for account B.
const acceptanceContext = (uid, fingerprint) => digest(JSON.stringify(['unispace/legal/v1', uid, fingerprint]));

function parsePolicy(raw, HttpsError, now = Date.now()) {
  const fail = () => { throw new HttpsError('failed-precondition', 'Legal policy is not ready.'); };
  if (raw == null) return null; // Absence explicitly means the staged feature is OFF.
  if (!object(raw)) return fail();
  if (raw.enabled === false) return null;
  if (raw.enabled !== true || raw.status !== 'published' || raw.language !== 'ar' ||
      typeof raw.operatorName !== 'string' || !raw.operatorName.trim() || raw.operatorName.length > 300 ||
      typeof raw.publishedAt !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/.test(raw.publishedAt) ||
      !Array.isArray(raw.documents) || raw.documents.length !== DOCUMENT_IDS.length) return fail();
  const published = Date.parse(raw.publishedAt);
  if (!Number.isFinite(published) || published < 0 || published > now ||
      new Date(published).toISOString() !== raw.publishedAt.replace(/(?<!\.[0-9]{3})Z$/, '.000Z')) return fail();
  const documents = DOCUMENT_IDS.map(id => {
    const matches = raw.documents.filter(item => object(item) && item.id === id);
    if (matches.length !== 1) return fail();
    const d = matches[0];
    if (typeof d.version !== 'string' || !/^[A-Za-z0-9._-]{1,80}$/.test(d.version) ||
        typeof d.title !== 'string' || !d.title.trim() || d.title.length > 300 ||
        typeof d.body !== 'string' || !d.body.trim()) return fail();
    return {id, version: d.version, title: d.title, body: d.body, sha256: digest(d.body)};
  });
  const identity = {schemaVersion: 1, language: 'ar', operatorName: raw.operatorName.trim(),
    publishedAt: new Date(published).toISOString(), documents};
  if (Buffer.byteLength(JSON.stringify(identity), 'utf8') > 128 * 1024) return fail();
  return {...identity, fingerprint: digest(JSON.stringify(identity))};
}

function archiveMatches(snapshot, policy) {
  const archive = snapshot.data();
  return snapshot.exists && archive?.schemaVersion === 1 &&
    archive.fingerprint === policy.fingerprint && archive.language === policy.language &&
    archive.operatorName === policy.operatorName && archive.publishedAt === policy.publishedAt &&
    sameDocuments(archive.documents, policy.documents, ['id', 'version', 'title', 'body', 'sha256']);
}

function receiptMatches(snapshot, uid, policy) {
  const receipt = snapshot.data();
  return snapshot.exists && receipt?.schemaVersion === 1 && receipt.uid === uid &&
    receipt.fingerprint === policy.fingerprint && receipt.language === policy.language &&
    receipt.termsAccepted === true && receipt.communityAccepted === true &&
    receipt.privacyAcknowledged === true && receipt.source === 'explicit_in_app' &&
    typeof receipt.acceptedAt?.toMillis === 'function' && Number.isFinite(receipt.acceptedAt.toMillis()) &&
    sameDocuments(receipt.documents, metadata(policy), ['id', 'version', 'sha256']);
}

// Dependencies are injected so validation and transaction behavior can be unit-tested
// without production credentials. Only these handlers write consent records.
function createConsentHandlers({auth, db, FieldValue, HttpsError, now = Date.now}) {
  async function authenticate(request) {
    const uid = request?.auth?.uid;
    const header = request?.rawRequest?.headers?.authorization;
    if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/') ||
        typeof header !== 'string' || !/^Bearer \S+$/.test(header)) {
      throw new HttpsError('unauthenticated', 'Sign in first.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (!token || token.uid !== uid || !Number.isSafeInteger(token.auth_time) || token.auth_time < 0 ||
        token.firebase?.tenant != null) throw new HttpsError('unauthenticated', 'Invalid session.');
    return {uid, token};
  }

  async function readPolicy(tx, uid, token) {
    const [config, cutoff, account] = await tx.getAll(
      db.doc(CONFIG_PATH), db.doc(`authRevocations/${uid}`), db.doc(`users/${uid}`));
    if (cutoff.exists) {
      const revokedBefore = cutoff.data()?.revokedBefore;
      if (!Number.isSafeInteger(revokedBefore) || revokedBefore < 0) {
        throw new HttpsError('failed-precondition', 'Session state unavailable.');
      }
      if (token.auth_time <= revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
    }
    const user = account.data();
    // A just-created Auth account is allowed before its profile exists.
    if (user && (['disabled', 'deleted'].includes(user.accountStatus) ||
        user.isDeleted === true || user.security?.frozen === true)) {
      throw new HttpsError('permission-denied', 'Account unavailable.');
    }
    return parsePolicy(config.data(), HttpsError, now());
  }

  async function status(request) {
    if (!exactKeys(request?.data, [])) throw new HttpsError('invalid-argument', 'No parameters allowed.');
    const {uid, token} = await authenticate(request);
    return db.runTransaction(async tx => {
      const policy = await readPolicy(tx, uid, token);
      if (!policy) return {uid, enabled: false, required: false};
      const receipt = await tx.get(db.doc(`${RECEIPTS}/${uid}/receipts/${policy.fingerprint}`));
      if (receipt.exists) {
        const archive = await tx.get(db.doc(`${ARCHIVES}/${policy.fingerprint}`));
        if (!receiptMatches(receipt, uid, policy) || !archiveMatches(archive, policy)) {
          throw new HttpsError('failed-precondition', 'Consent record needs review.');
        }
      }
      return {uid, enabled: true, required: !receipt.exists, policy,
        acceptanceContext: acceptanceContext(uid, policy.fingerprint)};
    });
  }

  async function accept(request) {
    const input = request?.data;
    if (!exactKeys(input, ['fingerprint', 'acceptanceContext', 'termsAccepted', 'communityAccepted', 'privacyAcknowledged']) ||
        typeof input.fingerprint !== 'string' || !HASH_PATTERN.test(input.fingerprint) ||
        typeof input.acceptanceContext !== 'string' || !HASH_PATTERN.test(input.acceptanceContext) ||
        input.termsAccepted !== true || input.communityAccepted !== true || input.privacyAcknowledged !== true) {
      throw new HttpsError('invalid-argument', 'Explicit acceptance of the displayed documents is required.');
    }
    const {uid, token} = await authenticate(request);
    if (input.acceptanceContext !== acceptanceContext(uid, input.fingerprint)) {
      throw new HttpsError('failed-precondition', 'Account changed. Reload the documents.');
    }
    return db.runTransaction(async tx => {
      const policy = await readPolicy(tx, uid, token);
      if (!policy || policy.fingerprint !== input.fingerprint) {
        throw new HttpsError('failed-precondition', 'Policy unavailable or changed. Reload the documents.');
      }
      const receiptRef = db.doc(`${RECEIPTS}/${uid}/receipts/${policy.fingerprint}`);
      const archiveRef = db.doc(`${ARCHIVES}/${policy.fingerprint}`);
      const [receipt, archive] = await tx.getAll(receiptRef, archiveRef);
      if (archive.exists && !archiveMatches(archive, policy)) {
        throw new HttpsError('failed-precondition', 'Policy archive needs review.');
      }
      if (receipt.exists) {
        if (!receiptMatches(receipt, uid, policy) || !archive.exists) {
          throw new HttpsError('failed-precondition', 'Consent record needs review.');
        }
        return {uid, accepted: true, fingerprint: policy.fingerprint, alreadyAccepted: true};
      }
      const acceptedAt = FieldValue.serverTimestamp();
      // All transaction reads precede writes. Preserve the exact accepted publication.
      if (!archive.exists) tx.create(archiveRef, {...policy, archivedAt: acceptedAt});
      tx.create(receiptRef, {schemaVersion: 1, uid, fingerprint: policy.fingerprint,
        language: policy.language, documents: metadata(policy),
        termsAccepted: true, communityAccepted: true, privacyAcknowledged: true,
        source: 'explicit_in_app', acceptedAt});
      tx.set(db.doc(`${RECEIPTS}/${uid}`), {schemaVersion: 1,
        latestFingerprint: policy.fingerprint, updatedAt: acceptedAt});
      return {uid, accepted: true, fingerprint: policy.fingerprint, alreadyAccepted: false};
    });
  }

  // These APIs record consent; they do NOT enforce it across other app APIs/rules.
  return {status, accept};
}

module.exports = {createConsentHandlers, parsePolicy};
