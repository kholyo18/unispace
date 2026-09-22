const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  DELETE_WITHIN_DAYS,
  createAccountDeletionRequestHandler,
} = require('../security/account-deletion-request');

function fakeDb() {
  const docs = new Map();
  const writes = [];

  function ref(path) {
    return { path };
  }

  return {
    docs,
    writes,
    collection(name) {
      return {
        doc(id) {
          return ref(`${name}/${id}`);
        },
      };
    },
    async runTransaction(callback) {
      return callback({
        async get(documentRef) {
          const value = docs.get(documentRef.path);
          return {
            exists: value !== undefined,
            data: () => value,
          };
        },
        set(documentRef, data, options) {
          writes.push({ path: documentRef.path, data, options });
          const previous = docs.get(documentRef.path) || {};
          docs.set(
            documentRef.path,
            options?.merge ? { ...previous, ...data } : { ...data },
          );
        },
      });
    },
  };
}

function backend({ uid='alice', tokenUid='alice', authTime=100, now=1_800_000_000_000 }={}) {
  const db = fakeDb();
  const revoked = [];
  const deletedUsers = [];
  const auth = {
    async verifyIdToken(token, checkRevoked) {
      assert.equal(token, 'test-token');
      assert.equal(checkRevoked, true);
      return { uid: tokenUid, auth_time: authTime };
    },
    async deleteUser(deletedUid) {
      deletedUsers.push(deletedUid);
    },
  };
  const FieldValue = {
    serverTimestamp: () => ({ __serverTimestamp: true }),
  };
  const Timestamp = {
    fromMillis: (millis) => ({ millis }),
  };
  const revokeAllSessions = async (request) => {
    revoked.push(request);
    return { revoked: true };
  };
  const handler = createAccountDeletionRequestHandler({
    auth,
    db,
    FieldValue,
    Timestamp,
    revokeAllSessions,
    now: () => now,
  });
  const request = (data={confirm:true}) => ({
    auth: { uid },
    data,
    rawRequest: { headers: { authorization: 'Bearer test-token' } },
  });
  return { handler, request, db, revoked, deletedUsers, now };
}

test('requires authenticated user and explicit confirmation only', async () => {
  const { handler, request, db, revoked } = backend();
  await assert.rejects(
    handler({ data: { confirm: true }, rawRequest: { headers: {} } }),
    (error) => error.code === 'unauthenticated',
  );
  await assert.rejects(
    handler(request({})),
    (error) => error.code === 'invalid-argument',
  );
  await assert.rejects(
    handler(request({ confirm: true, uid: 'victim' })),
    (error) => error.code === 'invalid-argument',
  );
  assert.equal(db.writes.length, 0);
  assert.equal(revoked.length, 0);
});

test('rejects a credential that does not belong to the authenticated user', async () => {
  const { handler, request, db, revoked } = backend({ tokenUid: 'bob' });
  await assert.rejects(
    handler(request()),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(db.writes.length, 0);
  assert.equal(revoked.length, 0);
});

test('records one pending deletion request and revokes only that signed-in account', async () => {
  const { handler, request, db, revoked, deletedUsers, now } = backend();
  const result = await handler(request());

  assert.deepEqual(result, {
    status: 'pending',
    deletionWithinDays: DELETE_WITHIN_DAYS,
    alreadyRequested: false,
  });

  const requestDoc = db.docs.get('account_deletion_requests/alice');
  assert.equal(requestDoc.uid, 'alice');
  assert.equal(requestDoc.status, 'pending');
  assert.equal(requestDoc.requestedFrom, 'app');
  assert.equal(
    requestDoc.deleteBy.millis,
    now + DELETE_WITHIN_DAYS * 24 * 60 * 60 * 1000,
  );

  const userDoc = db.docs.get('users/alice');
  assert.equal(userDoc.deletionStatus, 'pending');
  assert.equal(userDoc.accountStatus, 'deleted');
  assert.equal(userDoc.isDeleted, true);
  assert.equal(userDoc.deletionDeleteBy.millis, requestDoc.deleteBy.millis);

  assert.equal(revoked.length, 1);
  assert.equal(revoked[0].auth.uid, 'alice');
  assert.deepEqual(revoked[0].data, {});
  assert.deepEqual(deletedUsers, ['alice']);
});

test('a repeated pending request is idempotent but revokes sessions again', async () => {
  const { handler, request, db, revoked, deletedUsers } = backend();
  await handler(request());
  const first = db.docs.get('account_deletion_requests/alice');
  const firstWriteCount = db.writes.length;

  const second = await handler(request());

  assert.equal(second.alreadyRequested, true);
  assert.equal(second.status, 'pending');
  assert.equal(db.writes.length, firstWriteCount);
  assert.strictEqual(db.docs.get('account_deletion_requests/alice'), first);
  assert.equal(revoked.length, 2);
  assert.deepEqual(deletedUsers, ['alice', 'alice']);
});

for (const revokedBefore of [100, 101, '100', null, -1, 99.5]) {
  test(`deletion rejects revoked or malformed cutoff ${JSON.stringify(revokedBefore)} before writes`, async () => {
    const f = backend();
    f.db.docs.set('authRevocations/alice', { revokedBefore });
    await assert.rejects(f.handler(f.request()), { code: 'unauthenticated' });
    assert.equal(f.db.writes.length, 0);
    assert.equal(f.deletedUsers.length, 0);
    assert.equal(f.revoked.length, 0);
  });
}
test('deletion permits authentication strictly newer than a valid cutoff', async () => {
  const f = backend(); f.db.docs.set('authRevocations/alice', { revokedBefore: 99 });
  assert.equal((await f.handler(f.request())).status, 'pending');
});

test('deletion confirmation bound to another account cannot delete the current identity', async () => {
  const f = backend();
  await assert.rejects(f.handler(f.request({ confirm: true, expectedUid: 'bob' })), { code: 'unauthenticated' });
  assert.equal(f.db.writes.length, 0); assert.equal(f.deletedUsers.length, 0);
});
test('current deletion client may assert its matching caller identity', async () => {
  const f = backend();
  assert.equal((await f.handler(f.request({ confirm: true, expectedUid: 'alice' }))).status, 'pending');
});
