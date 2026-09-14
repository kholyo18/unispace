const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath } = require('firebase-admin/firestore');
function createSyncAuthorPrivacyHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        !(input.cursor === null || (typeof input.cursor === 'string' && input.cursor.length > 0 && input.cursor.length <= 128 &&
        !input.cursor.includes('/') && !['.','..'].includes(input.cursor)))) throw new HttpsError('invalid-argument', 'Invalid sync page.');
    return db.runTransaction(async tx => {
      const [cutoff, account] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      const privacy = user.privacy || {};
      const patch = {
        authorPrivate: typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : user.profileVisibility === 'private',
        authorAppearInSearch: privacy.appearInSearch !== false,
        authorHideLikeCounts: privacy.hideLikeCounts === true,
      };
      let query = db.collection('community_posts').where('authorId','==',uid).orderBy(FieldPath.documentId());
      if (input.cursor) query = query.startAfter(input.cursor);
      const page = await tx.get(query.limit(200));
      for (const doc of page.docs) {
        if (Object.entries(patch).some(([k,v]) => doc.data()[k] !== v)) tx.update(doc.ref, patch);
      }
      return {cursor:page.docs.at(-1)?.id || null, exhausted:page.size < 200};
    });
  };
}
module.exports = { createSyncAuthorPrivacyHandler };
