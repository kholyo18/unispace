const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath, Timestamp } = require('firebase-admin/firestore');
const { moderators } = require('./moderation-actions');
const statuses = ['pending','actioned','dismissed','restored'];
function encode(value, depth = 0) {
  if (depth > 20) throw new HttpsError('resource-exhausted', 'Report nesting limit.');
  if (value instanceof Timestamp) return {__reportTime: value.toMillis()};
  if (Array.isArray(value)) return value.map(v => encode(v, depth + 1));
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k,v]) => [k, encode(v, depth + 1)]));
  return value;
}
function createModerationInboxHandler({auth, db}) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    if (!moderators.has(uid)) throw new HttpsError('permission-denied', 'Moderator access required.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !statuses.includes(input.status) || !(input.cursor === null || (typeof input.cursor === 'string' &&
        input.cursor.length > 0 && input.cursor.length <= 512 && !input.cursor.includes('/') && !['.','..'].includes(input.cursor)))) {
      throw new HttpsError('invalid-argument', 'Invalid inbox page.');
    }
    // Counts are aggregates, never a download of all report documents.
    const counts = Object.fromEntries(await Promise.all(statuses.map(async status => [status,
      (await db.collection('community_reports').where('status','==',status).count().get()).data().count])));
    return db.runTransaction(async tx => {
      const [cutoff, account] = await tx.getAll(db.doc('authRevocations/' + uid), db.doc('users/' + uid));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      const user = account.data();
      if (!user || ['disabled','deleted'].includes(user.accountStatus) || user.security?.frozen === true) throw new HttpsError('permission-denied', 'Account unavailable.');
      let query = db.collection('community_reports').where('status','==',input.status).orderBy(FieldPath.documentId());
      if (input.cursor) query = query.startAfter(input.cursor);
      const page = await tx.get(query.limit(50));
      const fields = ['type','targetId','postId','parentId','commentId','reporterId','ownerId','ownerName',
        'reason','details','severity','status','createdAt','updatedAt','reviewedAt','reviewedBy','snapshot','history'];
      const reports = page.docs.map(d => ({id:d.id, data:encode(Object.fromEntries(fields.filter(k => d.data()[k] !== undefined).map(k => [k,d.data()[k]])))}));
      const result = {reports, counts, cursor:page.docs.at(-1)?.id || null, exhausted:page.size < 50};
      if (Buffer.byteLength(JSON.stringify(result)) > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Inbox page too large.');
      return result;
    });
  };
}
module.exports = { createModerationInboxHandler, encode };
