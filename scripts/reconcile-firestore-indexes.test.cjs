const { test } = require('node:test');
const assert = require('node:assert/strict');
const { reconcile } = require('./reconcile-firestore-indexes.cjs');

test('preserves existing production indexes while adding required indexes', () => {
  const current = {
    indexes: [
      {
        collectionGroup: 'legacy',
        queryScope: 'COLLECTION',
        fields: [
          { fieldPath: 'a', order: 'ASCENDING' },
          { fieldPath: 'b', order: 'DESCENDING' },
        ],
      },
    ],
    fieldOverrides: [
      {
        collectionGroup: 'notifications',
        fieldPath: 'actorId',
        ttl: true,
        indexes: [
          { order: 'DESCENDING', queryScope: 'COLLECTION_GROUP' },
        ],
      },
      {
        collectionGroup: 'legacy',
        fieldPath: 'largeMap',
        indexes: [],
      },
    ],
  };

  const required = {
    indexes: [
      {
        collectionGroup: 'community_posts',
        queryScope: 'COLLECTION',
        fields: [
          { fieldPath: 'authorId', order: 'ASCENDING' },
          { fieldPath: 'createdAt', order: 'DESCENDING' },
        ],
      },
    ],
    fieldOverrides: [
      {
        collectionGroup: 'notifications',
        fieldPath: 'actorId',
        indexes: [
          { order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' },
        ],
      },
      {
        collectionGroup: 'revocations',
        fieldPath: 'expiresAt',
        indexes: [
          { order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' },
        ],
      },
    ],
  };

  const merged = reconcile(current, required);

  assert.equal(merged.indexes.length, 2);
  assert.ok(merged.indexes.some(x => x.collectionGroup === 'legacy'));
  assert.ok(merged.indexes.some(x => x.collectionGroup === 'community_posts'));

  const actor = merged.fieldOverrides.find(
    x => x.collectionGroup === 'notifications' && x.fieldPath === 'actorId',
  );
  assert.equal(actor.ttl, true);
  assert.deepEqual(actor.indexes, [
    { order: 'DESCENDING', queryScope: 'COLLECTION_GROUP' },
    { order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' },
  ]);

  const legacy = merged.fieldOverrides.find(
    x => x.collectionGroup === 'legacy' && x.fieldPath === 'largeMap',
  );
  assert.deepEqual(legacy.indexes, []);

  const revocations = merged.fieldOverrides.find(
    x => x.collectionGroup === 'revocations' && x.fieldPath === 'expiresAt',
  );
  assert.deepEqual(revocations.indexes, [
    { order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' },
  ]);
});

test('deduplicates indexes and override modes', () => {
  const index = {
    collectionGroup: 'community_posts',
    queryScope: 'COLLECTION',
    fields: [{ fieldPath: 'authorId', order: 'ASCENDING' }],
  };
  const mode = { order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' };

  const merged = reconcile(
    {
      indexes: [index],
      fieldOverrides: [{
        collectionGroup: 'notifications',
        fieldPath: 'actorId',
        indexes: [mode],
      }],
    },
    {
      indexes: [index],
      fieldOverrides: [{
        collectionGroup: 'notifications',
        fieldPath: 'actorId',
        indexes: [mode],
      }],
    },
  );

  assert.equal(merged.indexes.length, 1);
  assert.equal(merged.fieldOverrides.length, 1);
  assert.equal(merged.fieldOverrides[0].indexes.length, 1);
});


test('keeps live Firebase index when only exported density differs', () => {
  const live = {
    collectionGroup: 'community_posts',
    queryScope: 'COLLECTION',
    fields: [
      { fieldPath: 'authorId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' },
      { fieldPath: '__name__', order: 'DESCENDING' },
    ],
    density: 'SPARSE_ALL',
  };

  const required = {
    collectionGroup: 'community_posts',
    queryScope: 'COLLECTION',
    fields: [
      { fieldPath: 'authorId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' },
      { fieldPath: '__name__', order: 'DESCENDING' },
    ],
  };

  const merged = reconcile(
    { indexes: [live], fieldOverrides: [] },
    { indexes: [required], fieldOverrides: [] },
  );

  assert.equal(merged.indexes.length, 1);
  assert.deepEqual(merged.indexes[0], live);
});

test('does not collapse explicitly different density requirements', () => {
  const live = {
    collectionGroup: 'community_posts',
    queryScope: 'COLLECTION',
    fields: [
      { fieldPath: 'authorId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' },
    ],
    density: 'SPARSE_ALL',
  };

  const required = {
    collectionGroup: 'community_posts',
    queryScope: 'COLLECTION',
    fields: [
      { fieldPath: 'authorId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' },
    ],
    density: 'DENSE',
  };

  const merged = reconcile(
    { indexes: [live], fieldOverrides: [] },
    { indexes: [required], fieldOverrides: [] },
  );

  assert.equal(merged.indexes.length, 2);
});
