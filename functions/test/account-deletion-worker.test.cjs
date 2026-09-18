const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  MODERATION_RETENTION_DAYS,
  scrubCommentsForDeletedUser,
  scrubChatMessage,
  scrubChatDocument,
  scrubNotification,
  scrubReport,
  storageObjectFromUrl,
} = require('../security/account-deletion-worker');

test('removes a deleted author comment while preserving and promoting other replies', () => {
  const input = [{
    id: 'gone',
    authorId: 'alice',
    text: 'private text',
    upvotedBy: ['bob', 'alice'],
    replies: [{
      id: 'reply',
      authorId: 'bob',
      text: 'keep me',
      replyToId: 'gone',
      replyToAuthorId: 'alice',
      replyToText: 'private text',
      replyToName: 'Alice',
      upvotedBy: ['alice', 'carol'],
      replies: [],
    }],
  }];

  const result = scrubCommentsForDeletedUser(input, 'alice');
  assert.equal(result.changed, true);
  assert.deepEqual(result.deletedCommentIds, ['gone']);
  assert.equal(result.comments.length, 1);
  assert.equal(result.comments[0].id, 'reply');
  assert.equal(result.comments[0].text, 'keep me');
  assert.deepEqual(result.comments[0].upvotedBy, ['carol']);
  assert.equal(Object.hasOwn(result.comments[0], 'replyToId'), false);
  assert.equal(Object.hasOwn(result.comments[0], 'replyToAuthorId'), false);
  assert.equal(Object.hasOwn(result.comments[0], 'replyToText'), false);
});

test('rewires a reply through a removed nested comment to the nearest surviving parent', () => {
  const input = [{
    id: 'root',
    authorId: 'bob',
    text: 'root',
    replies: [{
      id: 'gone',
      authorId: 'alice',
      replyToId: 'root',
      replyToAuthorId: 'bob',
      text: 'remove',
      replies: [{
        id: 'child',
        authorId: 'carol',
        replyToId: 'gone',
        replyToAuthorId: 'alice',
        replyToText: 'remove',
        replies: [],
      }],
    }],
  }];

  const result = scrubCommentsForDeletedUser(input, 'alice');
  const child = result.comments[0].replies[0];
  assert.equal(child.id, 'child');
  assert.equal(child.replyToId, 'root');
  assert.equal(child.replyToAuthorId, 'bob');
  assert.equal(Object.hasOwn(child, 'replyToText'), false);
});

test('scrubs an authored chat message and returns only its media for deletion', () => {
  const result = scrubChatMessage({
    authorId: 'alice',
    type: 'image',
    imageUrl: 'https://firebasestorage.googleapis.com/v0/b/demo/o/chats%2Fc1%2Fimages%2F1.jpg?alt=media',
    size: 99,
    reactions: { alice: ['❤️'], bob: ['👍'] },
    starredBy: { alice: true, bob: true },
  }, 'alice', 'deleted_x');

  assert.equal(result.changed, true);
  assert.equal(result.patch.authorId, 'deleted_x');
  assert.equal(result.patch.type, 'text');
  assert.equal(result.patch.deletedAccountMessage, true);
  assert.deepEqual(result.patch.reactions, { bob: ['👍'] });
  assert.deepEqual(result.patch.starredBy, { bob: true });
  assert.ok(result.deleteFields.includes('imageUrl'));
  assert.ok(result.deleteFields.includes('size'));
  assert.equal(result.storageUrls.length, 1);
});

test('anonymizes chat membership and removes per-user preferences', () => {
  const result = scrubChatDocument({
    memberIds: ['alice', 'bob'],
    members: {
      alice: { name: 'Alice', photoUrl: 'a.jpg' },
      bob: { name: 'Bob', photoUrl: 'b.jpg' },
    },
    unread: { alice: 1, bob: 2 },
    typing: { alice: 123, bob: 456 },
    lastSenderId: 'alice',
    lastMessage: 'secret',
    pinned_alice: true,
  }, 'alice', 'deleted_x');

  assert.deepEqual(result.patch.memberIds, ['deleted_x', 'bob']);
  assert.equal(result.patch.members.alice, undefined);
  assert.equal(result.patch.members.deleted_x.name, 'حساب محذوف');
  assert.deepEqual(result.patch.unread, { bob: 2 });
  assert.deepEqual(result.patch.typing, { bob: 456 });
  assert.equal(result.patch.lastSenderId, 'deleted_x');
  assert.equal(result.patch.lastMessage, 'رسالة من حساب محذوف');
  assert.deepEqual(result.deleteFields, ['pinned_alice']);
});

test('preserves an aggregate notification when other actors remain', () => {
  const result = scrubNotification({
    actorId: 'alice',
    actorIds: ['alice', 'bob'],
    actorNames: { alice: 'Alice', bob: 'Bob' },
    actorName: 'Alice',
    actorPhotoUrl: 'a.jpg',
  }, 'alice');

  assert.equal(result.deleteDocument, false);
  assert.equal(result.patch.actorId, 'bob');
  assert.deepEqual(result.patch.actorIds, ['bob']);
  assert.deepEqual(result.patch.actorNames, { bob: 'Bob' });
  assert.equal(result.patch.actorPhotoUrl, null);
});

test('pseudonymizes retained moderation evidence and attaches its retention deadline', () => {
  const now = 2_000_000_000_000;
  const Timestamp = { fromMillis: millis => ({ millis }) };
  const result = scrubReport({
    reporterId: 'alice',
    ownerId: 'alice',
    ownerName: 'Alice',
    reviewedBy: 'alice',
    snapshot: { displayName: 'Alice', username: 'alice', photoUrl: 'x', text: 'evidence' },
    history: [{ action: 'reported', by: 'alice' }],
  }, 'alice', 'deleted_x', Timestamp, now);

  assert.equal(result.changed, true);
  assert.equal(result.patch.reporterId, 'deleted_x');
  assert.equal(result.patch.ownerId, 'deleted_x');
  assert.equal(result.patch.ownerName, 'حساب محذوف');
  assert.equal(result.patch.snapshot.displayName, 'حساب محذوف');
  assert.equal(result.patch.snapshot.username, '');
  assert.equal(result.patch.snapshot.text, 'evidence');
  assert.equal(result.patch.reviewedBy, 'deleted_x');
  assert.equal(result.patch.history[0].by, 'deleted_x');
  assert.equal(
    result.patch.retentionDeleteAt.millis,
    now + MODERATION_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  );
});

test('accepts only Firebase Storage URLs for the configured bucket', () => {
  assert.equal(
    storageObjectFromUrl(
      'https://firebasestorage.googleapis.com/v0/b/demo/o/chats%2Fc1%2Fimages%2F1.jpg?alt=media',
      'demo',
    ),
    'chats/c1/images/1.jpg',
  );
  assert.equal(
    storageObjectFromUrl(
      'https://firebasestorage.googleapis.com/v0/b/other/o/chats%2Fc1%2Fimages%2F1.jpg',
      'demo',
    ),
    null,
  );
  assert.equal(storageObjectFromUrl('https://example.com/file', 'demo'), null);
});
