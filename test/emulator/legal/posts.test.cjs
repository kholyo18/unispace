'use strict';

const {test, before, beforeEach, after} = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const {createRequire} = require('node:module');
const {randomUUID} = require('node:crypto');
const {PROJECT, HOSTS, assertEmulatorOnly, localJson} = require('./safety.cjs');
assertEmulatorOnly(); // No Firebase initialization before the existing isolation checks.
const runtimeRequire = createRequire(path.join(__dirname, 'functions/package.json'));
const {initializeApp, deleteApp} = runtimeRequire('firebase-admin/app');
const {getAuth} = runtimeRequire('firebase-admin/auth');
const {getFirestore, FieldValue, Timestamp} = runtimeRequire('firebase-admin/firestore');
const {createPostHandler} = require('./functions/security/create-post');
const {POST_ENFORCEMENT_PATH} = require('./functions/legal/post-enforcement');
const app = initializeApp({projectId: PROJECT}, 'post-guard-tests');
const auth = getAuth(app), db = getFirestore(app);
const source = require('./source-manifest.json');
const publicationDate = new Date(Date.now() - 86400000).toISOString();
const year = Number(new Intl.DateTimeFormat('en', {timeZone: 'Africa/Algiers', year: 'numeric'}).format(new Date()));
const dateFor = years => `${year - years}-01-01`;
const policy = () => ({enabled: true, status: 'published', language: 'ar',
  operatorName: 'Synthetic post-guard test operator', publishedAt: publicationDate,
  documents: ['terms', 'community', 'privacy'].map(id => ({id, version: 'posts-test-1', title: `Test ${id}`,
    body: `اختبار نشر فقط: ${id}. Not a real legal document.`}))});
const json = data => ({method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify(data)});
const content = () => ({title: 'Synthetic post', body: 'Text-only emulator test.', tags: ['test'],
  imageUrls: [], videoUrls: [], polls: [], pollSlides: []});
const nextPost = () => `legal-post-test-${randomUUID()}`;
async function call(name, user, data = {}) {
  const options = json({data});
  if (user) options.headers.authorization = `Bearer ${user.token}`;
  return localJson(`http://${HOSTS.UNISPACE_LEGAL_FUNCTIONS_HOST}/${PROJECT}/europe-west1/${name}`, options);
}
function ok(response) {
  assert.equal(response.status, 200, JSON.stringify(response.body.error || {status: response.status}));
  assert.equal(response.body.error, undefined);
  assert.ok(response.body.result && typeof response.body.result === 'object');
  return response.body.result;
}
function denied(response, code = 'FAILED_PRECONDITION') {
  assert.notEqual(response.status, 200);
  assert.equal(response.body.error?.status, code);
}
async function account() {
  const reply = await localJson(`http://${HOSTS.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-emulator-key`,
    json({email: `posts-${randomUUID()}@example.test`, password: 'Emulator-only-password-42!', returnSecureToken: true}));
  assert.equal(reply.status, 200, reply.body.error?.message);
  const user = {uid: reply.body.localId, token: reply.body.idToken};
  await db.doc(`users/${user.uid}`).set({accountStatus: 'active', firstName: 'Synthetic', lastName: 'Author', privacy: {}});
  return user;
}
const status = async user => ok(await call('readLegalEligibilityStatus', user));
async function declare(user, years = 25) {
  const view = await status(user);
  ok(await call('declareLegalBirthDate', user, {birthDate: dateFor(years),
    declarationContext: view.declarationContext, accuracyConfirmed: true}));
}
async function accept(user) {
  const view = await status(user);
  ok(await call('acceptEligibleLegalDocuments', user, {fingerprint: view.policy.fingerprint,
    acceptanceContext: view.acceptanceContext, termsAccepted: true, communityAccepted: true, privacyAcknowledged: true}));
  return view;
}
async function ready() {
  const user = await account(); await declare(user); await accept(user);
  assert.equal((await status(user)).canProceed, true);
  return user;
}
async function reviewedRepresentativeFixture(user) {
  // Emulator-only fixture, NOT an actual identity/authority or consent review.
  const declaration = (await db.doc(`legalEligibilityDeclarations/${user.uid}`).get()).data();
  const view = await status(user), now = Timestamp.now();
  await db.doc(`legalRepresentativeApprovals/${user.uid}`).set({schemaVersion: 1, status: 'verified',
    source: 'verified_legal_representative_review', subjectUid: user.uid,
    declarationId: declaration.declarationId, policyFingerprint: view.policy.fingerprint,
    rulesVersion: 'dz-18-19-v1', authorityVerified: true, termsAccepted: true, communityAccepted: true,
    privacyAcknowledged: true, revokedAt: null, representativeUid: 'synthetic-post-representative',
    reviewerUid: 'synthetic-post-reviewer', reviewReference: 'post-emulator-only',
    acceptedAt: now, verifiedAt: now, expiresAt: Timestamp.fromMillis(Date.now() + 3600000)});
}
const reserve = (user, postId) => call('reserveOwnPost', user, {postId});
const publish = (user, postId, body = content()) => call('publishOwnPost', user, {postId, content: body});
async function saved(postId) {
  const docs = await db.getAll(db.doc(`community_posts/${postId}`), db.doc(`postPublicationReceipts/${postId}`));
  return docs.map(doc => doc.data());
}
async function noPost(postId) { assert.deepEqual(await saved(postId), [undefined, undefined]); }
async function changedPolicy() {
  const next = policy(); next.documents[0].body += ' Changed publication.';
  await db.doc('legalPolicy/current').set(next);
}
async function direct(pathname, user, method = 'GET', payload) {
  const headers = {'content-type': 'application/json'};
  if (user) headers.authorization = `Bearer ${user.token}`;
  return localJson(`http://${HOSTS.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/${pathname}`,
    {method, headers, ...(payload ? {body: JSON.stringify(payload)} : {})});
}

before(async () => {
  console.log(`# post guard source ${source.commit}; isolated project ${PROJECT}; text-only posts`);
  assert.ok(source.hashes['functions/security/create-post.js']);
  assert.ok(source.hashes['functions/legal/post-enforcement.js']);
});
beforeEach(async () => {
  await db.doc('legalPolicy/current').set(policy());
  await db.doc(POST_ENFORCEMENT_PATH).set({schemaVersion: 1, enabled: true});
});
after(async () => { await db.terminate(); await deleteApp(app); });

for (const mode of ['absent', 'disabled']) {
  test(`pre-rollout ${mode} preserves existing post behavior without manufacturing consent`, async () => {
    const user = await account(), postId = nextPost();
    if (mode === 'absent') await db.doc(POST_ENFORCEMENT_PATH).delete();
    else await db.doc(POST_ENFORCEMENT_PATH).set({schemaVersion: 1, enabled: false});
    await db.doc('legalPolicy/current').delete();
    ok(await reserve(user, postId)); ok(await publish(user, postId));
    assert.equal((await saved(postId))[0].status, 'published');
    assert.equal((await db.doc(`legalEligibilityDeclarations/${user.uid}`).get()).exists, false);
    assert.equal((await db.collection(`legalEligibilityReceipts/${user.uid}/receipts`).get()).empty, true);
  });
}
for (const malformed of [{}, {schemaVersion: 1, enabled: 'false'}, {schemaVersion: 9, enabled: true}]) {
  test(`malformed rollout cannot silently disable enforcement: ${JSON.stringify(malformed)}`, async () => {
    const user = await ready(), postId = nextPost(); await db.doc(POST_ENFORCEMENT_PATH).set(malformed);
    denied(await reserve(user, postId)); await noPost(postId);
  });
}
for (const mode of ['absent', 'disabled', 'draft']) {
  test(`enabled enforcement with ${mode} legal publication denies reservation`, async () => {
    const user = await account(), postId = nextPost();
    if (mode === 'absent') await db.doc('legalPolicy/current').delete();
    else if (mode === 'disabled') await db.doc('legalPolicy/current').set({enabled: false});
    else await db.doc('legalPolicy/current').set({...policy(), status: 'draft'});
    denied(await reserve(user, postId)); await noPost(postId);
  });
}
test('direct reserve request without birth declaration is denied before either document is created', async () => {
  const user = await account(), postId = nextPost();
  denied(await reserve(user, postId)); await noPost(postId);
});
test('declared adult without current acceptance cannot reserve', async () => {
  const user = await account(), postId = nextPost(); await declare(user);
  denied(await reserve(user, postId)); await noPost(postId);
});
test('V1 acceptance and editable profile flags never replace V2 eligibility', async () => {
  const user = await account(), postId = nextPost();
  const view = ok(await call('readLegalConsentStatus', user));
  ok(await call('acceptLegalDocuments', user, {fingerprint: view.policy.fingerprint,
    acceptanceContext: view.acceptanceContext, termsAccepted: true, communityAccepted: true, privacyAcknowledged: true}));
  await db.doc(`users/${user.uid}`).update({birthDate: dateFor(25), guardianApproved: true, legalAccepted: true});
  denied(await reserve(user, postId)); await noPost(postId);
});
test('under-minimum declaration cannot reserve a post', async () => {
  const user = await account(), postId = nextPost(); await declare(user, 17);
  denied(await reserve(user, postId)); await noPost(postId);
});
test('represented personal acceptance alone cannot reserve a post', async () => {
  const user = await account(), postId = nextPost(); await declare(user, 18); await accept(user);
  assert.equal((await status(user)).state, 'representative_required');
  denied(await reserve(user, postId)); await noPost(postId);
});
test('qualified adult reserves and publishes with existing ownership, content and notification semantics', async () => {
  const user = await ready(), postId = nextPost();
  const follower = await account();
  await db.doc(`users/${user.uid}/followers/${follower.uid}`).set({accepted: true});
  const notification = db.doc(`users/${follower.uid}/notifications/post_${postId}`);
  assert.deepEqual(ok(await reserve(user, postId)), {postId, reserved: true});
  const initial = await saved(postId);
  assert.equal(initial[0].status, 'uploading'); assert.ok(initial[0].createdAt instanceof Timestamp);
  ok(await reserve(user, postId)); assert.deepEqual(await saved(postId), initial);
  assert.deepEqual(ok(await publish(user, postId)), {postId, published: true});
  const final = await saved(postId), notice = (await notification.get()).data();
  assert.equal(final[0].authorId, user.uid); assert.equal(final[1].ownerId, user.uid);
  assert.equal(final[0].body, content().body); assert.equal(final[0].status, 'published');
  assert.equal(final[0].authorName, 'Synthetic Author'); assert.equal(final[0].version, 1);
  assert.equal(final[1].status, 'published'); assert.ok(final[1].publishedAt instanceof Timestamp);
  assert.equal(notice.postId, postId); assert.equal(notice.actorId, user.uid);
  assert.equal(Object.hasOwn(final[0], 'birthDate'), false);
  assert.equal(Object.hasOwn(final[0], 'acceptanceContext'), false);
  ok(await publish(user, postId)); assert.deepEqual(await saved(postId), final);
  assert.deepEqual((await notification.get()).data(), notice);
});
test('represented user with personal consent and synthetic reviewed approval can publish', async () => {
  const user = await account(), postId = nextPost(); await declare(user, 18); await accept(user);
  await reviewedRepresentativeFixture(user); assert.equal((await status(user)).canProceed, true);
  ok(await reserve(user, postId)); ok(await publish(user, postId));
  assert.equal((await saved(postId))[0].status, 'published');
});
test('policy changed after reservation blocks publication and notifications until new acceptance', async () => {
  const user = await ready(), postId = nextPost(), follower = await account();
  await db.doc(`users/${user.uid}/followers/${follower.uid}`).set({accepted: true});
  const notification = db.doc(`users/${follower.uid}/notifications/post_${postId}`);
  ok(await reserve(user, postId)); const initial = await saved(postId); await changedPolicy();
  denied(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
  assert.equal((await notification.get()).exists, false);
  await accept(user); ok(await publish(user, postId)); assert.equal((await notification.get()).exists, true);
});
for (const change of ['revoked', 'expired']) {
  test(`representative ${change} after reservation blocks publication without partial writes`, async () => {
    const user = await account(), postId = nextPost(); await declare(user, 18); await accept(user);
    await reviewedRepresentativeFixture(user); ok(await reserve(user, postId)); const initial = await saved(postId);
    await db.doc(`legalRepresentativeApprovals/${user.uid}`).update(change === 'revoked'
      ? {status: 'revoked', revokedAt: FieldValue.serverTimestamp()}
      : {expiresAt: Timestamp.fromMillis(Date.now() - 1)});
    denied(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
  });
}
test('server cutoff revocation after reservation denies publication', async () => {
  const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); const initial = await saved(postId);
  const decoded = await auth.verifyIdToken(user.token);
  await db.doc(`authRevocations/${user.uid}`).set({revokedBefore: decoded.auth_time});
  denied(await publish(user, postId), 'UNAUTHENTICATED'); assert.deepEqual(await saved(postId), initial);
});
for (const patch of [{accountStatus: 'disabled'}, {security: {frozen: true}}, {isDeleted: true}]) {
  test(`unavailable profile cannot publish after reservation: ${JSON.stringify(patch)}`, async () => {
    const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); const initial = await saved(postId);
    await db.doc(`users/${user.uid}`).update(patch);
    denied(await publish(user, postId), 'PERMISSION_DENIED'); assert.deepEqual(await saved(postId), initial);
  });
}
test('Authentication-disabled account cannot publish', async () => {
  const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); const initial = await saved(postId);
  await auth.updateUser(user.uid, {disabled: true});
  denied(await publish(user, postId), 'UNAUTHENTICATED'); assert.deepEqual(await saved(postId), initial);
});
test('an old reservation made before rollout does not bypass newly enabled enforcement', async () => {
  const user = await account(), postId = nextPost(); await db.doc(POST_ENFORCEMENT_PATH).delete();
  ok(await reserve(user, postId)); const initial = await saved(postId);
  await db.doc(POST_ENFORCEMENT_PATH).set({schemaVersion: 1, enabled: true});
  denied(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
});
test('receipt corruption after ready status blocks the actual publisher', async () => {
  const user = await ready(), postId = nextPost(); const view = await status(user);
  ok(await reserve(user, postId)); const initial = await saved(postId);
  await db.doc(`legalEligibilityReceipts/${user.uid}/receipts/${view.acceptanceContext}`).update({privacyAcknowledged: false});
  denied(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
});
for (const field of ['guardianApproved', 'termsAccepted', 'skipEligibility']) {
  test(`post request cannot pass client-controlled ${field}`, async () => {
    const user = await ready(), postId = nextPost();
    denied(await call('reserveOwnPost', user, {postId, [field]: true}), 'INVALID_ARGUMENT'); await noPost(postId);
    ok(await reserve(user, postId)); const initial = await saved(postId);
    denied(await call('publishOwnPost', user, {postId, content: content(), [field]: true}), 'INVALID_ARGUMENT');
    assert.deepEqual(await saved(postId), initial);
  });
}
test('eligibility never authorizes another authors reservation or publication', async () => {
  const alice = await ready(), bob = await ready(), postId = nextPost(); ok(await reserve(alice, postId));
  const initial = await saved(postId);
  denied(await reserve(bob, postId), 'ALREADY_EXISTS'); denied(await publish(bob, postId), 'ALREADY_EXISTS');
  assert.deepEqual(await saved(postId), initial);
});
test('unchanged content validation still rejects empty posts for an eligible author', async () => {
  const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); const initial = await saved(postId);
  denied(await publish(user, postId, {...content(), title: '', body: ''}), 'INVALID_ARGUMENT');
  assert.deepEqual(await saved(postId), initial);
});
test('already-published retries also require current eligibility and never duplicate side effects', async () => {
  const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); ok(await publish(user, postId));
  const initial = await saved(postId); await changedPolicy();
  denied(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
  await accept(user); ok(await publish(user, postId)); assert.deepEqual(await saved(postId), initial);
});
test('concurrent qualified publications create one publication and one follower notification', async () => {
  const user = await ready(), postId = nextPost(), follower = await account();
  await db.doc(`users/${user.uid}/followers/${follower.uid}`).set({accepted: true});
  ok(await reserve(user, postId)); (await Promise.all([publish(user, postId), publish(user, postId)])).forEach(ok);
  const result = await saved(postId); assert.equal(result[0].version, 1); assert.equal(result[1].status, 'published');
  const notices = await db.collection(`users/${follower.uid}/notifications`).get(); assert.equal(notices.size, 1);
  assert.equal(notices.docs[0].id, `post_${postId}`);
});
test('client cannot read or switch off server-owned rollout configuration', async () => {
  const user = await ready();
  // Positive authentication control uses a permitted synthetic own-profile read.
  assert.equal((await direct(`users/${user.uid}`, user)).status, 200);
  for (const [url, method, payload] of [
    [POST_ENFORCEMENT_PATH, 'GET'], ['legalEnforcement', 'GET'],
    [POST_ENFORCEMENT_PATH, 'PATCH', {fields: {schemaVersion: {integerValue: '1'}, enabled: {booleanValue: false}}}],
    [POST_ENFORCEMENT_PATH, 'DELETE'],
  ]) {
    const reply = await direct(url, user, method, payload);
    assert.equal(reply.status, 403); assert.equal(reply.body.error?.status, 'PERMISSION_DENIED');
  }
  assert.deepEqual((await db.doc(POST_ENFORCEMENT_PATH).get()).data(), {schemaVersion: 1, enabled: true});
});
test('even an eligible client cannot create posts or publication receipts directly via Firestore', async () => {
  const user = await ready(), postId = nextPost();
  for (const namespace of ['community_posts', 'postPublicationReceipts']) {
    const reply = await direct(`${namespace}/${postId}`, user, 'PATCH', {fields: {
      authorId: {stringValue: user.uid}, ownerId: {stringValue: user.uid}, status: {stringValue: 'published'},
    }});
    assert.equal(reply.status, 403); assert.equal(reply.body.error?.status, 'PERMISSION_DENIED');
  }
  await noPost(postId);
});
test('a policy change after publisher preflight is rechecked in the real write transaction', async () => {
  const user = await ready(), postId = nextPost(); ok(await reserve(user, postId)); const initial = await saved(postId);
  let changed = false;
  // Controlled scheduling seam only; database reads, writes and transactions remain real SDK operations.
  const scheduledDb = new Proxy(db, {get(target, property) {
    if (property === 'getAll') return async (...refs) => {
      const snapshots = await target.getAll(...refs);
      if (!changed) { changed = true; await changedPolicy(); }
      return snapshots;
    };
    const value = Reflect.get(target, property, target);
    return typeof value === 'function' ? value.bind(target) : value;
  }});
  const handler = createPostHandler({auth, db: scheduledDb, FieldValue,
    bucket: () => ({name: `${PROJECT}.test-only`, file() {throw Error('No media permitted.');}})}, true);
  const decoded = await auth.verifyIdToken(user.token, true);
  await assert.rejects(() => handler({auth: {uid: decoded.uid},
    rawRequest: {headers: {authorization: `Bearer ${user.token}`}}, data: {postId, content: content()}}),
  error => error.code === 'failed-precondition');
  assert.equal(changed, true); assert.deepEqual(await saved(postId), initial);
});
