'use strict';

const {test, before, beforeEach, after} = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const {createRequire} = require('node:module');
const {randomUUID} = require('node:crypto');
const {PROJECT, HOSTS, assertEmulatorOnly, localJson} = require('./safety.cjs');
assertEmulatorOnly(); // MUST run before importing/initializing Firebase.
const runtimeRequire = createRequire(path.join(__dirname, 'functions/package.json'));
const {initializeApp, deleteApp} = runtimeRequire('firebase-admin/app');
const {getAuth} = runtimeRequire('firebase-admin/auth');
const {getFirestore, FieldValue, Timestamp} = runtimeRequire('firebase-admin/firestore');
const {HttpsError} = runtimeRequire('firebase-functions/v2/https');
const {createEligibilityConsentHandlers} = require('./functions/legal/eligibility-consent');
const app = initializeApp({projectId: PROJECT});
const auth = getAuth(app), db = getFirestore(app);
const handlers = createEligibilityConsentHandlers({auth, db, FieldValue, HttpsError});
const source = require('./source-manifest.json');
const publishedAt = new Date(Date.now() - 86400000).toISOString();
const year = Number(new Intl.DateTimeFormat('en', {timeZone: 'Africa/Algiers', year: 'numeric'}).format(new Date()));
const dateFor = years => `${year - years}-01-01`;
const policy = () => ({enabled: true, status: 'published', language: 'ar',
  operatorName: 'Synthetic emulator operator — not a legal publication', publishedAt,
  documents: ['terms', 'community', 'privacy'].map(id => ({id, version: 'emulator-1', title: `Test ${id}`,
    body: `بيانات اختبار محلية فقط: ${id}\nNot a real legal policy.`}))});
const jsonOptions = body => ({method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify(body)});
const endpoint = name => `http://${HOSTS.UNISPACE_LEGAL_FUNCTIONS_HOST}/${PROJECT}/europe-west1/${name}`;
async function callable(name, user, data = {}) {
  const options = jsonOptions({data});
  if (user) options.headers.authorization = `Bearer ${user.token}`;
  return localJson(endpoint(name), options);
}
function ok(response) {
  assert.equal(response.status, 200, JSON.stringify(response.body.error || {status: response.status}));
  assert.equal(response.body.error, undefined);
  assert.ok(response.body.result && typeof response.body.result === 'object');
  return response.body.result;
}
function denied(response, code) {
  assert.notEqual(response.status, 200);
  assert.equal(response.body.error?.status, code);
}
async function account() {
  const response = await localJson(`http://${HOSTS.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-emulator-key`,
    jsonOptions({email: `legal-${randomUUID()}@example.test`, password: 'Emulator-only-password-42!', returnSecureToken: true}));
  assert.equal(response.status, 200, response.body.error?.message);
  assert.equal(typeof response.body.idToken, 'string');
  return {uid: response.body.localId, token: response.body.idToken};
}
const status = async user => ok(await callable('readLegalEligibilityStatus', user));
async function declare(user, date) {
  const view = await status(user);
  return callable('declareLegalBirthDate', user, {birthDate: date, declarationContext: view.declarationContext, accuracyConfirmed: true});
}
const consentInput = state => ({fingerprint: state.policy.fingerprint, acceptanceContext: state.acceptanceContext,
  termsAccepted: true, communityAccepted: true, privacyAcknowledged: true});
const accept = (user, state) => callable('acceptEligibleLegalDocuments', user, consentInput(state));
async function adult() {
  const user = await account(); ok(await declare(user, dateFor(25))); return user;
}
async function requestFor(user) {
  // Real emulator token verification, not injected token claims.
  const decoded = await auth.verifyIdToken(user.token, true);
  return {auth: {uid: decoded.uid}, rawRequest: {headers: {authorization: `Bearer ${user.token}`}}, data: {}};
}
async function protectedWrite(user) {
  const request = await requestFor(user);
  const ref = db.doc(`legalIntegrationProbes/${user.uid}`);
  await db.runTransaction(async tx => {
    await handlers.assertInTransaction(tx, request);
    tx.set(ref, {checkedAt: FieldValue.serverTimestamp()});
  });
  return ref;
}
async function syntheticApproval(user, view) {
  // Synthetic fixture ONLY. This is not a real authority-verification procedure.
  const declaration = (await db.doc(`legalEligibilityDeclarations/${user.uid}`).get()).data();
  const now = Timestamp.now();
  return {schemaVersion: 1, status: 'verified', source: 'verified_legal_representative_review',
    subjectUid: user.uid, declarationId: declaration.declarationId, policyFingerprint: view.policy.fingerprint,
    rulesVersion: 'dz-18-19-v1', authorityVerified: true, termsAccepted: true, communityAccepted: true,
    privacyAcknowledged: true, revokedAt: null, representativeUid: 'synthetic-representative',
    reviewerUid: 'synthetic-reviewer', reviewReference: 'emulator-only', acceptedAt: now, verifiedAt: now,
    expiresAt: Timestamp.fromMillis(Date.now() + 3600000)};
}
async function direct(pathname, user, method = 'GET', payload) {
  const headers = {'content-type': 'application/json'};
  if (user) headers.authorization = `Bearer ${user.token}`;
  return localJson(`http://${HOSTS.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/${pathname}`,
    {method, headers, ...(payload ? {body: JSON.stringify(payload)} : {})});
}

before(async () => {
  console.log(`# source commit ${source.commit}; demo project ${PROJECT}`);
  console.log(`# production source/rule SHA256 manifest ${JSON.stringify(source.hashes)}`);
  // No database-wide clearing, real accounts, real emails, or cloud credentials.
  assert.equal((await db.collection('legalEligibilityDeclarations').limit(1).get()).empty, true,
    'Use a fresh disposable emulator, not an existing data directory.');
});
beforeEach(async () => { await db.doc('legalPolicy/current').set(policy()); });
after(async () => { await db.terminate(); await deleteApp(app); });

test('callable authentication rejects missing and invalid tokens', async () => {
  denied(await callable('readLegalEligibilityStatus', null), 'UNAUTHENTICATED');
  denied(await callable('readLegalEligibilityStatus', {token: 'not-a-token'}), 'UNAUTHENTICATED');
});
test('missing configuration denies V2 readiness without creating records', async () => {
  const user = await account(); await db.doc('legalPolicy/current').delete();
  const view = await status(user); assert.equal(view.state, 'not_configured'); assert.equal(view.canProceed, false);
  assert.equal((await db.doc(`legalEligibilityDeclarations/${user.uid}`).get()).exists, false);
});
test('malformed enabled policy fails closed through the HTTP callable', async () => {
  const user = await account(); await db.doc('legalPolicy/current').set({enabled: true, status: 'draft'});
  denied(await callable('readLegalEligibilityStatus', user), 'FAILED_PRECONDITION');
});
test('independent user: declare, accept, re-read, archive and guarded real transaction', async () => {
  const user = await account(); const initial = await status(user);
  assert.equal(initial.state, 'birth_date_required'); assert.equal(initial.canProceed, false);
  ok(await declare(user, dateFor(25)));
  const view = await status(user); assert.equal(view.state, 'independent_consent_required');
  assert.equal(view.canProceed, false); assert.equal(view.userAccepted, false);
  ok(await accept(user, view)); const ready = await status(user);
  assert.equal(ready.state, 'ready'); assert.equal(ready.canProceed, true);
  const receipt = await db.doc(`legalEligibilityReceipts/${user.uid}/receipts/${view.acceptanceContext}`).get();
  assert.ok(receipt.data().acceptedAt instanceof Timestamp);
  assert.equal(receipt.data().uid, user.uid);
  assert.equal(Object.hasOwn(receipt.data(), 'aiTrainingConsent'), false);
  assert.deepEqual((await db.doc(`legalPolicyVersions/${view.policy.fingerprint}`).get()).data().documents, view.policy.documents);
  assert.equal((await (await protectedWrite(user)).get()).exists, true);
});
test('V1 acceptance does not imply V2 age or personal acceptance', async () => {
  const user = await account(); const view = ok(await callable('readLegalConsentStatus', user));
  ok(await callable('acceptLegalDocuments', user, consentInput(view)));
  assert.equal(ok(await callable('readLegalConsentStatus', user)).required, false);
  assert.equal((await status(user)).state, 'birth_date_required');
  ok(await declare(user, dateFor(25)));
  assert.equal((await status(user)).state, 'independent_consent_required');
});
for (const field of ['termsAccepted', 'communityAccepted', 'privacyAcknowledged']) {
  test(`HTTP acceptance requires explicit ${field}`, async () => {
    const user = await adult(); const view = await status(user);
    denied(await callable('acceptEligibleLegalDocuments', user, {...consentInput(view), [field]: false}), 'INVALID_ARGUMENT');
    assert.equal((await status(user)).userAccepted, false);
  });
}
for (const field of ['uid', 'acceptedAt', 'guardianApproved', 'aiTrainingConsent']) {
  test(`HTTP acceptance rejects extra client-controlled ${field}`, async () => {
    const user = await adult(); const view = await status(user);
    denied(await callable('acceptEligibleLegalDocuments', user, {...consentInput(view), [field]: 'forged'}), 'INVALID_ARGUMENT');
    assert.equal((await status(user)).canProceed, false);
  });
}
test('declaration retry preserves revision/time and cannot change saved DOB', async () => {
  const user = await adult(); const ref = db.doc(`legalEligibilityDeclarations/${user.uid}`);
  const first = (await ref.get()).data(); ok(await declare(user, dateFor(25)));
  const second = (await ref.get()).data(); assert.deepEqual(second, first);
  denied(await declare(user, dateFor(26)), 'FAILED_PRECONDITION');
  assert.deepEqual((await ref.get()).data(), first);
});
test('invalid calendar date and missing accuracy are rejected by the server', async () => {
  const user = await account(); const view = await status(user);
  for (const input of [{birthDate: '2000-02-30', accuracyConfirmed: true},
    {birthDate: dateFor(25), accuracyConfirmed: false}]) {
    denied(await callable('declareLegalBirthDate', user, {...input, declarationContext: view.declarationContext}), 'INVALID_ARGUMENT');
  }
  assert.equal((await db.doc(`legalEligibilityDeclarations/${user.uid}`).get()).exists, false);
});
test('parallel HTTP acceptances produce one receipt without rewriting its timestamp', async () => {
  const user = await adult(); const view = await status(user);
  const results = (await Promise.all([accept(user, view), accept(user, view), accept(user, view)])).map(ok);
  assert.equal(results.filter(r => !r.alreadyAccepted).length, 1);
  const ref = db.collection(`legalEligibilityReceipts/${user.uid}/receipts`);
  const first = await ref.get(); assert.equal(first.size, 1);
  ok(await accept(user, view)); const second = await ref.get();
  assert.equal(second.size, 1); assert.ok(second.docs[0].data().acceptedAt.isEqual(first.docs[0].data().acceptedAt));
});
test('another account cannot reuse the displayed acceptance context', async () => {
  const alice = await adult(), bob = await adult(); const view = await status(alice);
  denied(await accept(bob, view), 'FAILED_PRECONDITION'); assert.equal((await status(bob)).userAccepted, false);
});
test('publication change rejects stale requests and requires fresh acceptance', async () => {
  const user = await adult(); const old = await status(user); ok(await accept(user, old));
  const changed = policy(); changed.documents[0].body += '\nChanged test body';
  await db.doc('legalPolicy/current').set(changed);
  denied(await accept(user, old), 'FAILED_PRECONDITION');
  const fresh = await status(user); assert.equal(fresh.canProceed, false);
  assert.notEqual(fresh.policy.fingerprint, old.policy.fingerprint);
  ok(await accept(user, fresh)); assert.equal((await status(user)).canProceed, true);
  assert.equal((await db.collection(`legalEligibilityReceipts/${user.uid}/receipts`).get()).size, 2);
});
test('under-minimum age cannot accept or execute the protected transaction', async () => {
  const user = await account(); ok(await declare(user, dateFor(17))); const view = await status(user);
  assert.equal(view.state, 'under_minimum_age'); assert.equal(view.canAccept, false); assert.equal(view.canProceed, false);
  await assert.rejects(() => protectedWrite(user), error => error.code === 'failed-precondition');
  assert.equal((await db.doc(`legalIntegrationProbes/${user.uid}`).get()).exists, false);
});
test('represented personal acceptance cannot substitute for reviewed approval', async () => {
  const user = await account(); ok(await declare(user, dateFor(18))); const view = await status(user);
  assert.equal(view.state, 'personal_consent_required'); ok(await accept(user, view));
  assert.equal((await status(user)).state, 'representative_required');
  assert.equal((await db.doc(`legalRepresentativeApprovals/${user.uid}`).get()).exists, false);
  await assert.rejects(() => protectedWrite(user), error => error.code === 'failed-precondition');
});
test('synthetic reviewed approval enables guard; subsequent revocation blocks a new write', async () => {
  const user = await account(); ok(await declare(user, dateFor(18))); const view = await status(user);
  ok(await accept(user, view)); const approval = await syntheticApproval(user, view);
  await db.doc(`legalRepresentativeApprovals/${user.uid}`).set(approval);
  assert.equal((await status(user)).canProceed, true); const probe = await protectedWrite(user);
  const previous = (await probe.get()).data();
  await db.doc(`legalRepresentativeApprovals/${user.uid}`).update({status: 'revoked', revokedAt: FieldValue.serverTimestamp()});
  assert.equal((await status(user)).canProceed, false);
  await assert.rejects(() => protectedWrite(user), error => error.code === 'failed-precondition');
  assert.deepEqual((await probe.get()).data(), previous);
});
test('expired or self-reviewed synthetic approvals do not grant readiness', async () => {
  const user = await account(); ok(await declare(user, dateFor(18))); const view = await status(user); ok(await accept(user, view));
  for (const patch of [{expiresAt: Timestamp.fromMillis(Date.now() - 1)}, {reviewerUid: user.uid}]) {
    await db.doc(`legalRepresentativeApprovals/${user.uid}`).set({...await syntheticApproval(user, view), ...patch});
    assert.equal((await status(user)).canProceed, false);
  }
});
for (const patch of [{accountStatus: 'disabled'}, {isDeleted: true}, {security: {frozen: true}}]) {
  test(`unavailable account state is enforced: ${JSON.stringify(patch)}`, async () => {
    const user = await adult(); await db.doc(`users/${user.uid}`).set(patch);
    denied(await callable('readLegalEligibilityStatus', user), 'PERMISSION_DENIED');
  });
}
test('server session-revocation cutoff is enforced through the callable', async () => {
  const user = await adult(); const token = await auth.verifyIdToken(user.token);
  await db.doc(`authRevocations/${user.uid}`).set({revokedBefore: token.auth_time});
  denied(await callable('readLegalEligibilityStatus', user), 'UNAUTHENTICATED');
});
test('Authentication emulator disabled users cannot call legal APIs', async () => {
  const user = await adult(); await auth.updateUser(user.uid, {disabled: true});
  denied(await callable('readLegalEligibilityStatus', user), 'UNAUTHENTICATED');
});
test('Admin SDK refresh-token revocation is checked against the real Auth emulator', async () => {
  const user = await adult(); const token = await auth.verifyIdToken(user.token);
  const wait = token.auth_time * 1000 + 1200 - Date.now();
  if (wait > 0) await new Promise(resolve => setTimeout(resolve, wait));
  await auth.revokeRefreshTokens(user.uid);
  denied(await callable('readLegalEligibilityStatus', user), 'UNAUTHENTICATED');
});
test('corrupt archive cannot silently grant readiness', async () => {
  const user = await adult(); const view = await status(user); ok(await accept(user, view));
  await db.doc(`legalPolicyVersions/${view.policy.fingerprint}`).update({operatorName: 'tampered test operator'});
  denied(await callable('readLegalEligibilityStatus', user), 'FAILED_PRECONDITION');
  // Remove only this synthetic archive; a new test gets a clean publication archive.
  await db.doc(`legalPolicyVersions/${view.policy.fingerprint}`).delete();
});

test('repository rules allow the expected authenticated profile read (positive control)', async () => {
  const user = await account(); await db.doc(`users/${user.uid}`).set({displayName: 'synthetic-test'});
  assert.equal((await direct(`users/${user.uid}`, user)).status, 200);
  assert.equal((await direct(`users/${user.uid}`, null)).status, 403);
});
for (const collection of ['legalPolicy', 'legalPolicyVersions', 'legalConsentRecords',
  'legalEligibilityDeclarations', 'legalRepresentativeApprovals', 'legalEligibilityReceipts']) {
  test(`actual repository rules deny direct access to ${collection}`, async () => {
    const owner = await account(), other = await account();
    const pathname = `${collection}/${owner.uid}`;
    await db.doc(pathname).set({synthetic: true});
    for (const user of [null, owner, other]) {
      for (const method of ['GET', 'PATCH', 'DELETE']) {
        const reply = await direct(pathname, user, method,
          method === 'PATCH' ? {fields: {synthetic: {booleanValue: false}}} : undefined);
        assert.equal(reply.status, 403, `${collection} ${method} must be denied`);
        assert.equal(reply.body.error?.status, 'PERMISSION_DENIED');
      }
      assert.equal((await direct(collection, user)).status, 403, 'collection listing must also be denied');
    }
    assert.equal((await db.doc(pathname).get()).data().synthetic, true);
  });
}
test('nested receipts cannot be read, forged or deleted by their owner', async () => {
  const user = await adult(); const view = await status(user); ok(await accept(user, view));
  for (const base of ['legalEligibilityReceipts', 'legalConsentRecords']) {
    const pathname = `${base}/${user.uid}/receipts/${view.acceptanceContext}`;
    if (base === 'legalConsentRecords') await db.doc(pathname).set({synthetic: true});
    for (const method of ['GET', 'PATCH', 'DELETE']) {
      assert.equal((await direct(pathname, user, method,
        method === 'PATCH' ? {fields: {termsAccepted: {booleanValue: true}}} : undefined)).status, 403);
    }
    assert.equal((await direct(`${base}/${user.uid}/receipts`, user)).status, 403);
  }
});
