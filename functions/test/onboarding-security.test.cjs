const {test, after} = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createSessionBootstrapHandler} = require('../security/session-bootstrap');
const {createCompleteSignupHandler} = require('../security/complete-signup');
const {createUsernameCheckHandler} = require('../security/username-check');

const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local Firestore emulator required');
const project = 'demo-unispace-security';
for (const key of ['GCLOUD_PROJECT', 'GOOGLE_CLOUD_PROJECT']) {
  if (process.env[key] && process.env[key] !== project) throw Error('Only demo-unispace-security is allowed');
}
const app = initializeApp({projectId:project}, 'onboarding-security-tests');
const db = getFirestore(app);
after(async () => { await db.terminate(); await deleteApp(app); });
const unique = () => randomUUID().replaceAll('-', '').slice(0, 18);
function setup() {
  const uid = 'signup-' + unique();
  const auth = {
    verifyIdToken:async (token, checkRevoked) => {
      assert.equal(checkRevoked, true);
      if (token === 'revoked') throw Error('revoked ID token');
      return {uid:token, auth_time:100};
    },
    getUser:async id => ({uid:id, email:id + '@example.invalid', disabled:false}),
  };
  const request = (data, id = uid) => ({auth:{uid:id}, rawRequest:{headers:{authorization:'Bearer ' + id}}, data});
  const bootstrap = createSessionBootstrapHandler({auth, db});
  const complete = createCompleteSignupHandler({auth, db, bucketName:() => 'demo-bucket'});
  const check = createUsernameCheckHandler({auth, db, now:() => 100000});
  const input = (username = unique()) => ({firstName:'First', lastName:'Last', username, birthDate:null,
    gender:null, college:'College', department:'Department', major:'Major', level:'1'});
  const session = async (id = 'session-one', values = {}) => {
    await db.doc(`users/${uid}/sessions/${id}`).set({sessionId:id, isRevoked:false, ...values});
    return id;
  };
  const profile = async () => (await db.doc('users/' + uid).get()).data();
  return {uid, auth, request, bootstrap, complete, check, input, session, profile};
}

test('bootstrap creates only the pointer for an absent profile and preserves existing security', async () => {
  const f = setup(), sessionId = await f.session();
  assert.equal(await f.profile(), undefined);
  assert.deepEqual(await f.bootstrap(f.request({sessionId})), {uid:f.uid, sessionId});
  assert.deepEqual(await f.profile(), {currentSessionId:sessionId});
  const existing = {currentSessionId:sessionId, email:'keep@example.invalid', security:{mfaEnabled:true, backupCodes:['opaque']}};
  await db.doc('users/' + f.uid).set(existing);
  const next = await f.session('session-two');
  await f.bootstrap(f.request({sessionId:next}));
  assert.deepEqual(await f.profile(), {...existing, currentSessionId:next});
});

test('bootstrap rejects missing, foreign, revoked and mismatched session records', async () => {
  const f = setup();
  await db.doc('users/foreign-' + unique() + '/sessions/foreign').set({sessionId:'foreign', isRevoked:false});
  await f.session('revoked', {isRevoked:true});
  await f.session('mismatch', {sessionId:'another'});
  await f.session('ambiguous', {isRevoked:null});
  for (const sessionId of ['missing', 'foreign', 'revoked', 'mismatch', 'ambiguous']) {
    await assert.rejects(f.bootstrap(f.request({sessionId})), {code:'failed-precondition'});
  }
  assert.equal(await f.profile(), undefined);
});

test('voluntary disabled and frozen login can set metadata without reactivating the account', async () => {
  const f = setup(), sessionId = await f.session();
  const original = {accountStatus:'disabled', security:{frozen:true, mfaEnabled:true}, disabledAt:'preserved'};
  await db.doc('users/' + f.uid).set(original);
  await f.bootstrap(f.request({sessionId}));
  assert.deepEqual(await f.profile(), {...original, currentSessionId:sessionId});
  for (const deleted of [{accountStatus:'deleted'}, {isDeleted:true}]) {
    await db.doc('users/' + f.uid).set(deleted);
    await assert.rejects(f.bootstrap(f.request({sessionId})), {code:'permission-denied'});
    assert.deepEqual(await f.profile(), deleted);
  }
});

test('all onboarding endpoints reject forged identity, revoked tokens and the cutoff boundary', async () => {
  const f = setup();
  const pairs = [[f.bootstrap, {sessionId:await f.session()}], [f.complete, f.input()], [f.check, {username:unique()}]];
  for (const [handler, data] of pairs) {
    const forged = f.request(data);
    forged.auth.uid = 'someone-else';
    await assert.rejects(handler(forged), {code:'unauthenticated'});
    const revoked = f.request(data);
    revoked.rawRequest.headers.authorization = 'Bearer revoked';
    await assert.rejects(handler(revoked), {code:'unauthenticated'});
    await assert.rejects(handler({data}), {code:'unauthenticated'});
  }
  await db.doc('authRevocations/' + f.uid).set({revokedBefore:100});
  for (const [handler, data] of pairs) await assert.rejects(handler(f.request(data)), {code:'unauthenticated'});
  assert.equal(await f.profile(), undefined);
  assert.equal((await db.doc('usernameCheckLimits/' + f.uid).get()).exists, false);
});

test('caller cannot smuggle identity, security or a foreign profile image into signup', async () => {
  const f = setup();
  for (const extra of [{uid:'victim'}, {email:'forged@example.invalid'}, {security:{mfaEnabled:false}}, {onboardingCompleted:true}]) {
    await assert.rejects(f.complete(f.request({...f.input(), ...extra})), {code:'invalid-argument'});
  }
  await assert.rejects(f.complete(f.request({...f.input(), profileImageUrl:'https://firebasestorage.googleapis.com/v0/b/demo-bucket/o/users%2Fvictim%2Fprofile.jpg?alt=media'})), {code:'invalid-argument'});
  await assert.rejects(f.bootstrap(f.request({sessionId:'a', uid:f.uid})), {code:'invalid-argument'});
  await assert.rejects(f.bootstrap(f.request({sessionId:'../a'})), {code:'invalid-argument'});
  await assert.rejects(f.check(f.request({username:'valid_name', available:true})), {code:'invalid-argument'});
  assert.equal(await f.profile(), undefined);
});

test('completion derives email and preserves bootstrap/security fields; retries do not overwrite identity', async () => {
  const f = setup(), sessionId = await f.session();
  await f.bootstrap(f.request({sessionId}));
  await db.doc('users/' + f.uid).set({security:{mfaEnabled:true}, privacy:{privateAccount:true}}, {merge:true});
  const data = f.input();
  const result = await f.complete(f.request(data));
  assert.deepEqual(result, {completed:true, uid:f.uid, username:data.username});
  const first = await f.profile();
  assert.equal(first.email, f.uid + '@example.invalid');
  assert.equal(first.name, 'First Last');
  assert.equal(first.currentSessionId, sessionId);
  assert.deepEqual(first.security, {mfaEnabled:true});
  assert.deepEqual(first.privacy, {privateAccount:true});
  await f.complete(f.request({...data, firstName:'Altered'}));
  assert.deepEqual(await f.profile(), first);
  await assert.rejects(f.complete(f.request(f.input())), {code:'failed-precondition'});
});

test('concurrent completion reserves a username once and loser remains incomplete', async () => {
  const a = setup(), b = setup(), username = unique();
  const outcomes = await Promise.allSettled([a.complete(a.request(a.input(username))), b.complete(b.request(b.input(username)))]);
  assert.equal(outcomes.filter(x => x.status === 'fulfilled').length, 1);
  assert.equal(outcomes.find(x => x.status === 'rejected').reason.code, 'already-exists');
  const winner = outcomes[0].status === 'fulfilled' ? a : b, loser = winner === a ? b : a;
  assert.equal((await db.doc('usernameReservations/' + username).get()).data().uid, winner.uid);
  assert.equal(await loser.profile(), undefined);
  assert.deepEqual(await loser.check(loser.request({username})), {username, available:false});
  await winner.complete(winner.request(winner.input(username)));
  assert.equal((await winner.profile()).username, username);
});

test('existing legacy username blocks completion even without a reservation', async () => {
  const f = setup(), username = unique();
  await db.doc('users/legacy-' + unique()).set({username});
  assert.deepEqual(await f.check(f.request({username})), {username, available:false});
  await assert.rejects(f.complete(f.request(f.input(username))), {code:'already-exists'});
  assert.equal((await db.doc('usernameReservations/' + username).get()).exists, false);
  assert.equal(await f.profile(), undefined);
});

test('availability check supports absent profile and applies the 30 request quota', async () => {
  const f = setup(), username = unique();
  for (let i = 0; i < 30; i++) assert.deepEqual(await f.check(f.request({username})), {username, available:true});
  await assert.rejects(f.check(f.request({username})), {code:'resource-exhausted'});
  assert.equal(await f.profile(), undefined);
  assert.equal((await db.doc('usernameCheckLimits/' + f.uid).get()).data().count, 30);
});

test('disabled and frozen accounts cannot use profile completion or availability checks', async () => {
  const f = setup();
  for (const state of [{accountStatus:'disabled'}, {accountStatus:'deleted'}, {security:{frozen:true}}]) {
    await db.doc('users/' + f.uid).set(state);
    await assert.rejects(f.check(f.request({username:unique()})), {code:'permission-denied'});
    await assert.rejects(f.complete(f.request(f.input())), {code:'permission-denied'});
    assert.deepEqual(await f.profile(), state);
  }
});
