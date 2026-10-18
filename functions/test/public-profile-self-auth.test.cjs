const {test} = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const {BaseAuth} = require(path.join(path.dirname(require.resolve('firebase-admin/app')), '../auth/base-auth.js'));
const {createPublicProfileHandler} = require('../security/public-profile');

function fixture(mode = 'valid') {
  const lookups = [], checks = [], transactionReads = [];
  const records = new Map([['users/viewer', {displayName:'Viewer'}], ['users/other', {displayName:'Other'}]]);
  // Stub only JWT decoding and the remote Auth boundary. The actual installed
  // SDK performs the checkRevoked=true disabled/revocation/user lookup logic.
  const auth = {
    idTokenVerifier:{verifyJWT:async () => ({uid:'viewer', sub:'viewer', auth_time:100})},
    getUser:async uid => {
      lookups.push(uid);
      if (mode === 'missing' && uid === 'viewer') throw Object.assign(Error('missing'), {code:'auth/user-not-found'});
      return {disabled:(mode === 'disabled' && uid === 'viewer') || (mode === 'target-disabled' && uid === 'other'),
        tokensValidAfterTime:mode === 'revoked' && uid === 'viewer' ? new Date(101000).toISOString() : undefined};
    },
    verifyDecodedJWTNotRevokedOrDisabled:BaseAuth.prototype.verifyDecodedJWTNotRevokedOrDisabled,
    verifyIdToken(token, checkRevoked) {
      checks.push(checkRevoked);
      return BaseAuth.prototype.verifyIdToken.call(this, token, checkRevoked);
    },
  };
  const db = {
    doc:documentPath => ({path:documentPath}),
    runTransaction:async fn => fn({getAll:async (...refs) => {
      transactionReads.push(refs.map(ref => ref.path));
      return refs.map(ref => ({exists:records.has(ref.path), data:() => records.get(ref.path)}));
    }}),
  };
  const handler = createPublicProfileHandler({auth, db});
  const run = (userId = 'viewer') => handler({auth:{uid:'viewer'},
    rawRequest:{headers:{authorization:'Bearer test-jwt'}}, data:{userId}});
  return {run, lookups, checks, transactionReads, records};
}

test('self profile uses actual SDK Auth check exactly once and retains Firestore authorization', async () => {
  const f = fixture();
  assert.equal((await f.run()).displayName, 'Viewer');
  assert.deepEqual(f.lookups, ['viewer']);
  assert.deepEqual(f.checks, [true]);
  assert.equal(f.transactionReads.length, 1);
  assert.ok(f.transactionReads[0].includes('authRevocations/viewer'));
  assert.ok(f.transactionReads[0].includes('users/viewer'));
});

test('actual SDK rejects disabled, token-revoked and missing viewers before profile reads', async () => {
  for (const mode of ['disabled', 'revoked', 'missing']) {
    const f = fixture(mode);
    await assert.rejects(f.run(), {code:'unauthenticated'});
    assert.deepEqual(f.lookups, ['viewer']); assert.deepEqual(f.checks, [true]);
    assert.equal(f.transactionReads.length, 0);
  }
});

test('other-user profile still fetches target and rejects Auth-disabled target', async () => {
  for (const mode of ['valid', 'target-disabled']) {
    const f = fixture(mode);
    if (mode === 'valid') assert.equal((await f.run('other')).displayName, 'Other');
    else await assert.rejects(f.run('other'), {code:'not-found'});
    assert.deepEqual(f.lookups, ['viewer', 'other']); assert.deepEqual(f.checks, [true]);
  }
});

test('each self read freshly verifies and server revocation still denies the next read', async () => {
  const f = fixture();
  await f.run();
  f.records.set('authRevocations/viewer', {revokedBefore:100});
  await assert.rejects(f.run(), {code:'unauthenticated'});
  assert.deepEqual(f.lookups, ['viewer', 'viewer']); assert.deepEqual(f.checks, [true, true]);
  assert.equal(f.transactionReads.length, 2);
});
