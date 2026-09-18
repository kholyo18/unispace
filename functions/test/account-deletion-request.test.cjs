const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createAccountDeletionRequestHandler } = require('../security/account-deletion-request');

class Snapshot {
  constructor(value) {
    this._value = value;
    this.exists = value != null;
  }
  data() {
    return this._value;
  }
}

class FakeDb {
  constructor(seed = {}) {
    this.docs = new Map(Object.entries(seed));
  }
  doc(path) {
    return { path };
  }
  async runTransaction(callback) {
    const tx = {
      getAll: async (...refs) => refs.map(ref => new Snapshot(this.docs.get(ref.path))),
      set: (ref, value) => this.docs.set(ref.path, value),
    };
    return callback(tx);
  }
}

const FieldValue = {
  serverTimestamp: () => ({ __serverTimestamp: true }),
};

function authFor(uid, { authTime = 100, invalid = false, tenant = false } = {}) {
  return {
    verifyIdToken: async (_token, checkRevoked) => {
      assert.equal(checkRevoked, true);
      if (invalid) throw new Error('invalid');
      return {
        uid,
        auth_time: authTime,
        ...(tenant ? { firebase: { tenant: 'tenant-a' } } : {}),
      };
    },
  };
}

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
    rawRequest: { headers: { authorization: 'Bearer test-token' } },
  };
}

test('anonymous and parameterized requests are rejected', async () => {
  const db = new FakeDb();
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice'),
    db,
    FieldValue,
  });

  await assert.rejects(handler(request(null)), error => error.code === 'unauthenticated');
  await assert.rejects(
    handler(request('alice', { uid: 'victim' })),
    error => error.code === 'invalid-argument',
  );
  assert.equal(db.docs.size, 0);
});

test('mismatched, invalid, tenant and revoked credentials are rejected', async () => {
  for (const options of [{}, { invalid: true }, { tenant: true }]) {
    const db = new FakeDb();
    const handler = createAccountDeletionRequestHandler({
      auth: authFor(options.invalid || options.tenant ? 'alice' : 'bob', options),
      db,
      FieldValue,
    });
    await assert.rejects(
      handler(request('alice')),
      error => error.code === 'unauthenticated',
    );
    assert.equal(db.docs.size, 0);
  }

  const db = new FakeDb({
    'authRevocations/alice': { revokedBefore: 100 },
  });
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice', { authTime: 100 }),
    db,
    FieldValue,
  });
  await assert.rejects(
    handler(request('alice')),
    error => error.code === 'unauthenticated',
  );
  assert.equal(db.docs.has('accountDeletionRequests/alice'), false);
});

test('authenticated user creates only their own deletion request', async () => {
  const db = new FakeDb();
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice'),
    db,
    FieldValue,
  });

  assert.deepEqual(await handler(request('alice')), {
    requested: true,
    alreadyRequested: false,
    status: 'requested',
    operationalTargetDays: 30,
  });

  assert.deepEqual(db.docs.get('accountDeletionRequests/alice'), {
    uid: 'alice',
    status: 'requested',
    source: 'app',
    policyVersion: '1.0',
    operationalTargetDays: 30,
    requestedAt: { __serverTimestamp: true },
    updatedAt: { __serverTimestamp: true },
  });
  assert.equal(db.docs.has('accountDeletionRequests/bob'), false);
});

test('repeating an active request is idempotent', async () => {
  const original = {
    uid: 'alice',
    status: 'requested',
    requestedAt: 'original-time',
  };
  const db = new FakeDb({
    'accountDeletionRequests/alice': original,
  });
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice'),
    db,
    FieldValue,
  });

  assert.deepEqual(await handler(request('alice')), {
    requested: true,
    alreadyRequested: true,
    status: 'requested',
    operationalTargetDays: 30,
  });
  assert.strictEqual(db.docs.get('accountDeletionRequests/alice'), original);
});

test('a cancelled request can be submitted again', async () => {
  const db = new FakeDb({
    'accountDeletionRequests/alice': {
      uid: 'alice',
      status: 'cancelled',
      requestedAt: 'old-time',
    },
  });
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice'),
    db,
    FieldValue,
  });

  const result = await handler(request('alice'));
  assert.equal(result.alreadyRequested, false);
  assert.equal(db.docs.get('accountDeletionRequests/alice').status, 'requested');
});

test('identity mismatch in an existing request fails closed', async () => {
  const db = new FakeDb({
    'accountDeletionRequests/alice': {
      uid: 'bob',
      status: 'requested',
    },
  });
  const handler = createAccountDeletionRequestHandler({
    auth: authFor('alice'),
    db,
    FieldValue,
  });

  await assert.rejects(
    handler(request('alice')),
    error => error.code === 'failed-precondition',
  );
});
