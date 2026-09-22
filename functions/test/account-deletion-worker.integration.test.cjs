const { test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require('firebase-admin/firestore');
const { createAccountDeletionWorker } = require('../security/account-deletion-worker');

const host = process.env.FIRESTORE_EMULATOR_HOST || '';
if (!/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
  throw new Error('Local Firestore emulator required; production access forbidden.');
}

test('scheduled worker purges one account while preserving shared data', async () => {
  const app = initializeApp({ projectId: 'demo-unispace-deletion' }, 'account-deletion-worker-integration');
  const db = getFirestore(app);
  const now = 2_000_000_000_000;
  const deletedAuthUsers = [];
  const deletedPrefixes = [];
  const deletedObjects = [];

  const bucket = {
    name: 'test-bucket',
    async deleteFiles({ prefix }) {
      deletedPrefixes.push(prefix);
    },
    file(path) {
      return {
        async delete() {
          deletedObjects.push(path);
        },
      };
    },
  };

  const auth = {
    async deleteUser(uid) {
      deletedAuthUsers.push(uid);
    },
  };

  let randomCall = 0;
  const randomId = () => {
    randomCall++;
    return randomCall === 1
      ? 'worker_token_1234567890'
      : 'tombstone_abcdef0123456789';
  };

  try {
    await db.recursiveDelete(db.collection('account_deletion_requests'));
    await db.recursiveDelete(db.collection('users'));
    await db.recursiveDelete(db.collection('community_posts'));
    await db.recursiveDelete(db.collection('community_reports'));
    await db.recursiveDelete(db.collection('chats'));
    await db.recursiveDelete(db.collection('messageRequests'));
    await db.recursiveDelete(db.collection('usernameReservations'));
    await db.recursiveDelete(db.collection('pushTokenOwners'));
    await db.recursiveDelete(db.collection('authRevocations'));

    const seed = db.batch();
    seed.set(db.doc('account_deletion_requests/alice'), {
      uid: 'alice',
      status: 'pending',
      requestedAt: Timestamp.fromMillis(now - 10_000),
      deleteBy: Timestamp.fromMillis(now + 30 * 24 * 60 * 60 * 1000),
    });
    seed.set(db.doc('users/alice'), {
      displayName: 'Alice',
      username: 'alice',
      accountStatus: 'deleted',
    });
    seed.set(db.doc('users/bob'), { displayName: 'Bob', username: 'bob' });
    seed.set(db.doc('accountStateControls/alice'), { schemaVersion: 1, adminSuspended: true });
    seed.set(db.doc('accountStateControls/bob'), { schemaVersion: 1, adminSuspended: false });
    seed.set(db.doc('users/alice/following/bob'), { uid: 'bob' });
    seed.set(db.doc('users/bob/followers/alice'), { uid: 'alice' });
    seed.set(db.doc('users/alice/fcm_tokens/device1'), { token: 'secret-token' });
    seed.set(db.doc('pushTokenOwners/device1'), { ownerId: 'alice', sessionId: 's1' });
    seed.set(db.doc('usernameReservations/alice_name'), { uid: 'alice' });
    seed.set(db.doc('messageRequests/request1'), {
      senderId: 'alice',
      receiverId: 'bob',
      status: 'pending',
    });
    seed.set(db.doc('community_posts/p-owned'), {
      authorId: 'alice',
      title: 'delete',
      comments: [],
      commentsCount: 0,
      upvotedBy: [],
      downvotedBy: [],
    });
    seed.set(db.doc('community_posts/p-other'), {
      authorId: 'bob',
      title: 'keep',
      upvotedBy: ['alice', 'carol'],
      downvotedBy: [],
      commentsCount: 1,
      comments: [{
        id: 'root',
        authorId: 'bob',
        text: 'root',
        upvotedBy: ['alice'],
        downvotedBy: [],
        replies: [{
          id: 'alice-comment',
          authorId: 'alice',
          text: 'private',
          replyToId: 'root',
          replyToAuthorId: 'bob',
          upvotedBy: [],
          downvotedBy: [],
          mediaUrl: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/community_posts%2Fp-other%2Fcomments%2Falice%2Falice-comment%2Fmedia.jpg?alt=media',
          replies: [{
            id: 'carol-reply',
            authorId: 'carol',
            text: 'preserve',
            replyToId: 'alice-comment',
            replyToAuthorId: 'alice',
            replyToText: 'private',
            upvotedBy: [],
            downvotedBy: [],
            replies: [],
          }],
        }],
      }],
    });
    seed.set(db.doc('community_posts/p-other/poll_responses/alice'), {
      respondentId: 'alice',
      answerIds: ['a'],
    });
    seed.set(db.doc('chats/c1'), {
      type: 'direct',
      memberIds: ['alice', 'bob'],
      members: {
        alice: { name: 'Alice', photoUrl: 'a.jpg' },
        bob: { name: 'Bob', photoUrl: 'b.jpg' },
      },
      unread: { alice: 1, bob: 2 },
      lastSenderId: 'alice',
      lastMessage: 'private',
      lastMessageAt: Timestamp.fromMillis(now - 1_000),
    });
    seed.set(db.doc('chats/c1/messages/m1'), {
      authorId: 'alice',
      type: 'image',
      imageUrl: 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/chats%2Fc1%2Fimages%2F1.jpg?alt=media',
      size: 10,
      reactions: { alice: ['❤️'], bob: ['👍'] },
      createdAt: Timestamp.fromMillis(now - 2_000),
    });
    seed.set(db.doc('chats/c1/messages/m2'), {
      authorId: 'bob',
      type: 'text',
      text: 'keep',
      replyToId: 'm1',
      replyToAuthorId: 'alice',
      replyToText: 'private',
      replyToName: 'Alice',
      reactions: { alice: ['👍'], carol: ['❤️'] },
      createdAt: Timestamp.fromMillis(now - 1_000),
    });
    seed.set(db.doc('users/bob/notifications/n1'), {
      type: 'like',
      actorId: 'alice',
      actorName: 'Alice',
      actorPhotoUrl: 'a.jpg',
      actorIds: ['alice', 'carol'],
      actorNames: { alice: 'Alice', carol: 'Carol' },
      count: 2,
      postId: 'p-other',
    });
    seed.set(db.doc('community_reports/r1'), {
      type: 'post',
      targetId: 'p-other',
      reporterId: 'alice',
      ownerId: 'bob',
      ownerName: 'Bob',
      snapshot: { text: 'evidence' },
      reason: 'spam',
      details: 'evidence',
      status: 'pending',
      history: [{ action: 'reported', by: 'alice', at: Timestamp.fromMillis(now - 5_000) }],
    });
    await seed.commit();

    const worker = createAccountDeletionWorker({
      auth,
      db,
      bucket,
      FieldValue,
      Timestamp,
      now: () => now,
      randomId,
    });

    const result = await worker();
    assert.deepEqual(result, { processed: true, status: 'completed' });

    const request = (await db.doc('account_deletion_requests/alice').get()).data();
    assert.equal(request.status, 'completed');
    assert.equal(typeof request.tombstoneId, 'string');
    const tombstoneId = request.tombstoneId;
    assert.ok(tombstoneId.startsWith('deleted_'));

    assert.equal((await db.doc('users/alice').get()).exists, false);
    assert.equal((await db.doc('accountStateControls/alice').get()).exists, false);
    assert.equal((await db.doc('accountStateControls/bob').get()).exists, true);
    assert.deepEqual(deletedAuthUsers, ['alice']);
    assert.equal((await db.doc('users/bob/followers/alice').get()).exists, false);
    assert.equal((await db.doc('messageRequests/request1').get()).exists, false);
    assert.equal((await db.doc('usernameReservations/alice_name').get()).exists, false);
    assert.equal((await db.doc('community_posts/p-owned').get()).exists, false);

    const remainingPost = (await db.doc('community_posts/p-other').get()).data();
    assert.deepEqual(remainingPost.upvotedBy, ['carol']);
    assert.equal(remainingPost.comments.length, 1);
    assert.equal(remainingPost.comments[0].id, 'root');
    assert.equal(remainingPost.comments[0].replies.length, 1);
    assert.equal(remainingPost.comments[0].replies[0].id, 'carol-reply');
    assert.equal(remainingPost.comments[0].replies[0].replyToId, 'root');
    assert.equal(remainingPost.comments[0].replies[0].replyToAuthorId, 'bob');
    assert.equal((await db.doc('community_posts/p-other/poll_responses/alice').get()).exists, false);

    const chat = (await db.doc('chats/c1').get()).data();
    assert.deepEqual(chat.memberIds, [tombstoneId, 'bob']);
    assert.equal(chat.members.alice, undefined);
    assert.equal(chat.members[tombstoneId].name, 'حساب محذوف');
    assert.equal(chat.lastSenderId, tombstoneId);
    assert.equal(chat.lastMessage, 'رسالة من حساب محذوف');

    const m1 = (await db.doc('chats/c1/messages/m1').get()).data();
    assert.equal(m1.authorId, tombstoneId);
    assert.equal(m1.type, 'text');
    assert.equal(m1.deletedAccountMessage, true);
    assert.equal(m1.imageUrl, undefined);
    assert.deepEqual(m1.reactions, { bob: ['👍'] });

    const m2 = (await db.doc('chats/c1/messages/m2').get()).data();
    assert.equal(m2.authorId, 'bob');
    assert.equal(m2.replyToAuthorId, tombstoneId);
    assert.equal(m2.replyToText, 'رسالة من حساب محذوف');
    assert.deepEqual(m2.reactions, { carol: ['❤️'] });

    const notification = (await db.doc('users/bob/notifications/n1').get()).data();
    assert.equal(notification.actorId, 'carol');
    assert.deepEqual(notification.actorIds, ['carol']);
    assert.deepEqual(notification.actorNames, { carol: 'Carol' });

    const report = (await db.doc('community_reports/r1').get()).data();
    assert.equal(report.reporterId, tombstoneId);
    assert.equal(report.containsDeletedAccount, true);
    assert.equal(report.history[0].by, tombstoneId);
    assert.equal(typeof report.retentionDeleteAt.toMillis, 'function');

    const binding = (await db.doc('pushTokenOwners/device1').get()).data();
    assert.equal(binding.ownerId, null);
    assert.equal(binding.sessionId, undefined);
    assert.equal((await db.doc('pushTokenOwners/device1/revocations/alice').get()).exists, true);
    assert.equal((await db.doc('authRevocations/alice').get()).exists, true);

    assert.ok(deletedPrefixes.includes('community_posts/p-owned/'));
    assert.ok(deletedPrefixes.includes('community_posts/p-other/comments/alice/alice-comment/'));
    assert.ok(deletedPrefixes.includes('users/alice/'));
    assert.ok(deletedObjects.includes('chats/c1/images/1.jpg'));
    assert.ok(deletedObjects.includes('chats/c1/wallpaper/alice.jpg'));
  } finally {
    await db.terminate();
    await deleteApp(app);
  }
});
