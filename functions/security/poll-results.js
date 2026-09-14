const { HttpsError } = require('firebase-functions/v2/https');
const { Timestamp, FieldPath } = require('firebase-admin/firestore');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
function createPollResultsHandler({ auth, db }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data, c = input?.cursor;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !validId(input.postId) || (c !== null && (!c || typeof c !== 'object' || Array.isArray(c) ||
          Object.keys(c).length !== 3 || !validId(c.id) || !Number.isInteger(c.seconds) ||
          c.seconds < -62135596800 || c.seconds > 253402300799 || !Number.isInteger(c.nanoseconds) ||
          c.nanoseconds < 0 || c.nanoseconds > 999999999))) throw new HttpsError('invalid-argument', 'Invalid results page.');
    const uid = request.auth?.uid;
    const visible = await readPost({ ...request, data: { postId: input.postId } });
    if (visible.data.authorId !== uid) throw new HttpsError('permission-denied', 'Only the post owner can read individual responses.');
    let token;
    try { token = await auth.verifyIdToken((request.rawRequest?.headers?.authorization || '').slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    return db.runTransaction(async tx => {
      const ref = db.doc('community_posts/' + input.postId);
      const [post, cutoff, account] = await tx.getAll(ref, db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled', 'deleted'].includes(user.accountStatus) || user.security?.frozen === true ||
          removed(post.data()) || post.data().authorId !== uid) throw new HttpsError('permission-denied', 'Results unavailable.');
      let query = ref.collection('poll_responses').orderBy('submittedAt', 'desc').orderBy(FieldPath.documentId(), 'desc');
      if (c) query = query.startAfter(new Timestamp(c.seconds, c.nanoseconds), c.id);
      const snapshot = await tx.get(query.limit(100));
      const responses = snapshot.docs.map(doc => {
        const d = doc.data();
        return { id: doc.id, respondentId: doc.id,
          respondentName: typeof d.respondentName === 'string' ? d.respondentName.slice(0, 200) : '',
          answers: d.answers && typeof d.answers === 'object' && !Array.isArray(d.answers) ? d.answers : {},
          submittedAt: d.submittedAt instanceof Timestamp ? d.submittedAt.toDate().toISOString() : null };
      });
      const last = snapshot.docs[snapshot.docs.length - 1], date = last?.data().submittedAt;
      if (last && !(date instanceof Timestamp)) throw new HttpsError('failed-precondition', 'Invalid response timestamp.');
      const result = { post: visible, responses, exhausted: snapshot.size < 100,
        cursor: last ? { id: last.id, seconds: date.seconds, nanoseconds: date.nanoseconds } : null };
      if (Buffer.byteLength(JSON.stringify(result)) > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Results page too large.');
      return result;
    });
  };
}
module.exports = { createPollResultsHandler };
