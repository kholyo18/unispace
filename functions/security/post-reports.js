const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;

const { Timestamp } = require('firebase-admin/firestore');
const reasons = new Set(['abuse', 'sexual', 'academic/exam_leak', 'academic/cheating',
  'academic/misinfo', 'spam', 'impersonation', 'hate', 'other']);
const severityFor = reason => ['academic/exam_leak', 'academic/cheating', 'hate'].includes(reason)
  ? 'P1' : ['abuse', 'sexual', 'academic/misinfo', 'impersonation'].includes(reason) ? 'P2' : 'P3';
const text = (v, max) => typeof v === 'string' ? v.slice(0, max) : '';
function createPostReportHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 3 ||
        !validId(input.postId) || !reasons.has(input.reason) || typeof input.details !== 'string' ||
        input.details.length > 10000) throw new HttpsError('invalid-argument', 'Invalid report.');
    const uid = request.auth?.uid;
    // Includes original-post/comment authorization for reposts and the shared request limit.
    const visible = await readPost({ ...request, data: { postId: input.postId } });
    const header = request.rawRequest?.headers?.authorization || '';
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    return db.runTransaction(async tx => {
      const ref = db.doc(`community_posts/${input.postId}`);
      const snapshot = await tx.get(ref), data = snapshot.data();
      if (removed(data) || data.authorId !== visible.data.authorId) throw new HttpsError('not-found', 'Post unavailable.');
      const owner = data.authorId;
      const paths = [`authRevocations/${uid}`, `users/${uid}`, `users/${owner}`, `users/${owner}/followers/${uid}`,
        ...['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [`users/${uid}/${c}/${owner}`, `users/${owner}/${c}/${uid}`])];
      const [cutoff, actor, profile, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (unavailable(actor.data()) || unavailable(profile.data()) || (uid !== owner && blocks.some(b => b.exists))) {
        throw new HttpsError('permission-denied', 'Post unavailable.');
      }
      const p = profile.data(), privacy = p.privacy || {};
      const privateAccount = typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : p.profileVisibility === 'private';
      if (uid !== owner && privateAccount && !follower.exists) throw new HttpsError('permission-denied', 'Post is private.');
      if (uid === owner) throw new HttpsError('invalid-argument', 'Cannot report your own post.');
      // Keep legacy IDs so reports already submitted by this user are not counted again.
      const reportRef = db.collection('community_reports').doc(uid + '_' + input.postId);
      const existing = await tx.get(reportRef);
      if (existing.exists) {
        const prior = existing.data();
        if (prior.reporterId !== uid || prior.type !== 'post' ||
            (prior.targetId ?? prior.postId) !== input.postId) {
          throw new HttpsError('failed-precondition', 'Report identity mismatch.');
        }
        return { submitted: true, alreadyReported: true };
      }
      const severity = severityFor(input.reason);
      const ownerName = text(data.authorName ?? data.author ?? p.userName ?? p.displayName, 200);
      const reportSnapshot = {
        title: text(data.title, 10000), body: text(data.body, 100000),
        authorName: ownerName, authorId: owner,
        tags: Array.isArray(data.tags) ? data.tags.filter(v => typeof v === 'string').slice(0, 100).map(v => v.slice(0, 200)) : [],
        mediaUrls: [...(Array.isArray(data.imageUrls) ? data.imageUrls : []),
          ...(Array.isArray(data.videoUrls) ? data.videoUrls : [])]
          .filter(v => typeof v === 'string').slice(0, 100).map(v => v.slice(0, 4096)),
      };
      if (data.createdAt instanceof Timestamp) reportSnapshot.createdAt = data.createdAt;
      tx.create(reportRef, {
        type: 'post', targetId: input.postId, postId: input.postId, reporterId: uid,
        ownerId: owner, ownerName, reason: input.reason, details: input.details.trim(),
        severity, status: 'pending', snapshot: reportSnapshot,
        createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
        history: [{ action: 'reported', by: uid, at: Timestamp.now() }],
      });
      tx.update(ref, {
        reportCount: FieldValue.increment(1),
        reportScore: FieldValue.increment(severity === 'P1' ? 3 : severity === 'P2' ? 2 : 1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { submitted: true, alreadyReported: false };
    });
  };
}
module.exports = { createPostReportHandler };
