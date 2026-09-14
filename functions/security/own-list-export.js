const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath, Timestamp } = require('firebase-admin/firestore');
const fields = {
  blocked_accounts: ['targetId','blockedAt','createdAt'],
  hidden_posts: ['postId','hiddenAt','createdAt','source'],
  hidden_comments: ['commentId','postId','hiddenAt','createdAt','source'],
  following: ['uid','createdAt'], followers: ['uid','createdAt'],
  saved_posts: ['postId','savedAt','createdAt'],
};
function createOwnListExportHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 || typeof input.collection !== 'string' || !Object.hasOwn(fields, input.collection) ||
        !(input.cursor === null || (typeof input.cursor === 'string' && input.cursor.length > 0 && input.cursor.length <= 1500 &&
        !input.cursor.includes('/') && !['.','..'].includes(input.cursor)))) throw new HttpsError('invalid-argument', 'Invalid sync page.');
    return db.runTransaction(async tx => {
      const [cutoff, account] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      let query = db.collection('users').doc(uid).collection(input.collection).orderBy(FieldPath.documentId());
      if (input.cursor) query = query.startAfter(input.cursor);
      const page = await tx.get(query.limit(200));
      const items = page.docs.map(doc => {
        const data = doc.data(), item = {id:doc.id};
        for (const key of fields[input.collection]) {
          const value = data[key];
          if (value instanceof Timestamp) item[key] = value.toDate().toISOString();
          else if (typeof value === 'string') {
            if (value.length > 4096) throw new HttpsError('resource-exhausted', 'Export field too large.');
            item[key] = value;
          }
        }
        return item;
      });
      const result = {items, cursor:page.docs.at(-1)?.id || null, exhausted:page.size < 200};
      if (Buffer.byteLength(JSON.stringify(result)) > 4 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Export page too large.');
      return result;
    });
  };
}
module.exports = { createOwnListExportHandler };
