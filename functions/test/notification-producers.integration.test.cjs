const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { db, auth, FieldValue, Timestamp, fixture, callableRequest, patch, allowed, close } = require('./helpers/notification-fixture.cjs');
const { createFollowHandler } = require('../security/follow-relationships');
const { createPostVoteHandler } = require('../security/post-votes');
const { createCommentHandler } = require('../security/create-comment');
const { createPostHandler } = require('../security/create-post');
const { createRepostHandler } = require('../security/repost');
after(close);
const deps = { db, auth, FieldValue, Timestamp, bucket: () => ({ name: 'demo-bucket' }) };
const follow = createFollowHandler(deps), vote = createPostVoteHandler(deps), comment = createCommentHandler(deps);
const reserve = createPostHandler(deps), publish = createPostHandler(deps, true), repost = createRepostHandler(deps);
const notifications = uid => db.collection(`users/${uid}/notifications`);
async function setup() {
  const f = await fixture(); await f.ref.delete();
  const postId = `post-${randomUUID()}`, post = db.doc(`community_posts/${postId}`);
  await post.set({ authorId: f.owner.uid, title: 'Test post', body: 'Original content', status: 'published',
    createdAt: Timestamp.now(), upvotedBy: [], downvotedBy: [], votes: 0, comments: [], commentsCount: 0 });
  return { ...f, postId, post };
}

test('authorized public follow creates a server-derived notification without duplicates', async () => {
  const f = await setup(), request = callableRequest(f.actor, { action: 'follow', userId: f.owner.uid });
  await follow(request); await follow(request);
  const docs = await notifications(f.owner.uid).get(); assert.equal(docs.size, 1);
  const n = docs.docs[0].data(); assert.equal(n.type, 'follow'); assert.equal(n.actorId, f.actor.uid);
  assert.equal(n.actorName, 'Verified actor'); assert.equal(n.read, false);
});
test('private request and owner acceptance retain their correct recipients', async () => {
  const f = await setup(); await db.doc(`users/${f.owner.uid}`).update({ 'privacy.privateAccount': true });
  assert.deepEqual(await follow(callableRequest(f.actor, { action: 'follow', userId: f.owner.uid })), { state: 'pending' });
  assert.equal((await notifications(f.owner.uid).get()).docs[0].data().type, 'follow_request');
  await follow(callableRequest(f.owner, { action: 'accept', userId: f.actor.uid }));
  const n = (await notifications(f.actor.uid).get()).docs[0].data();
  assert.equal(n.type, 'follow_accepted'); assert.equal(n.actorId, f.owner.uid);
});
test('blocked and actor-spoofing follow requests cannot create notifications', async () => {
  const f = await setup();
  await assert.rejects(follow(callableRequest(f.actor, { action: 'follow', userId: f.owner.uid, actorName: 'Spoof' })), { code: 'invalid-argument' });
  await db.doc(`users/${f.owner.uid}/blocked_accounts/${f.actor.uid}`).set({});
  await assert.rejects(follow(callableRequest(f.actor, { action: 'follow', userId: f.owner.uid })), { code: 'permission-denied' });
  assert.equal((await notifications(f.owner.uid).get()).size, 0);
});
test('post like retry preserves read state and unlike retracts the aggregate', async () => {
  const f = await setup(), request = callableRequest(f.actor, { postId: f.postId, vote: 1 });
  await vote(request);
  const ref = notifications(f.owner.uid).doc(`like_post_${f.postId}`);
  allowed(await patch(ref.path, f.owner, { read: true }));
  const before = (await ref.get()).data(); await vote(request); assert.deepEqual((await ref.get()).data(), before);
  await vote(callableRequest(f.actor, { postId: f.postId, vote: 0 })); assert.equal((await ref.get()).exists, false);
});
test('concurrent same-state likes make one aggregate with one actor', async () => {
  const f = await setup(), request = callableRequest(f.actor, { postId: f.postId, vote: 1 });
  await Promise.all([vote(request), vote(request)]);
  const docs = await notifications(f.owner.uid).get(); assert.equal(docs.size, 1);
  assert.deepEqual(docs.docs[0].data().actorIds, [f.actor.uid]);
});
test('comment notifications contain references and generic text but no comment excerpt', async () => {
  const f = await setup(), text = 'Private comment excerpt must never enter notification data';
  const request = callableRequest(f.actor, { postId: f.postId, commentId: 'comment-1', replyToId: null, text, media: null });
  const result = await comment(request); assert.equal(result.created, true);
  assert.equal((await comment(request)).created, false);
  const docs = await notifications(f.owner.uid).get(); assert.equal(docs.size, 1);
  const n = docs.docs[0].data(); assert.equal(n.type, 'comment'); assert.equal(n.message, 'علّق على منشورك');
  assert.equal(n.commentId, 'comment-1'); assert.equal(n.actorId, f.actor.uid);
  assert.equal(JSON.stringify(n).includes(text), false);
  assert.equal((await f.post.get()).data().comments[0].text, text);
});
test('reply notifications use a generic envelope without altering the real reply', async () => {
  const f = await setup();
  await comment(callableRequest(f.owner, { postId: f.postId, commentId: 'parent', replyToId: null, text: 'Parent', media: null }));
  await comment(callableRequest(f.actor, { postId: f.postId, commentId: 'reply', replyToId: 'parent', text: 'Sensitive reply detail', media: null }));
  const docs = await notifications(f.owner.uid).get(); assert.equal(docs.size, 1);
  assert.equal(docs.docs[0].data().message, 'رد على تعليقك');
  assert.equal(JSON.stringify(docs.docs[0].data()).includes('Sensitive reply detail'), false);
});
test('self comments and likes do not create self notifications', async () => {
  const f = await setup(); await vote(callableRequest(f.owner, { postId: f.postId, vote: 1 }));
  await comment(callableRequest(f.owner, { postId: f.postId, commentId: 'self', replyToId: null, text: 'Own comment', media: null }));
  assert.equal((await notifications(f.owner.uid).get()).size, 0);
});
test('post publication notifies accepted followers once and omits content excerpts', async () => {
  const f = await setup(); await follow(callableRequest(f.actor, { action: 'follow', userId: f.owner.uid }));
  const postId = `publish-${randomUUID()}`;
  await reserve(callableRequest(f.owner, { postId }));
  const request = callableRequest(f.owner, { postId, content: { title: 'Sensitive post title', body: 'Sensitive post body',
    tags: [], imageUrls: [], videoUrls: [], polls: [], pollSlides: [] } });
  await publish(request); await publish(request);
  const docs = await notifications(f.actor.uid).get(); assert.equal(docs.size, 1);
  const n = docs.docs[0].data(); assert.equal(n.type, 'new_post'); assert.equal(n.postId, postId);
  assert.equal(JSON.stringify(n).includes('Sensitive post'), false);
});
test('repost producer keeps the source recipient and deterministic retry behavior', async () => {
  const f = await setup(), request = callableRequest(f.actor, { postId: `repost-${randomUUID()}`,
    sourcePostId: f.postId, commentId: null, title: 'Repost title', body: '' });
  await repost(request); await repost(request);
  const docs = await notifications(f.owner.uid).get(); assert.equal(docs.size, 1);
  assert.equal(docs.docs[0].data().type, 'repost'); assert.equal(docs.docs[0].data().actorId, f.actor.uid);
});
