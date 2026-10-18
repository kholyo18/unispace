const { HttpsError } = require('firebase-functions/v2/https');
const { createHash } = require('node:crypto');
const validSid = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
const validUid = value => typeof value === 'string' && value.length > 0 && value.length <= 128 && !value.includes('/') && !['.', '..'].includes(value);

// Only authenticated beforeSignIn events may issue authorization-bearing rows.
// Event IDs make retries idempotent without sharing IDs between logins.
function createSignInSessionHandler({ db, FieldValue }) {
  return async event => {
    const uid = event.data?.uid;
    if (!validUid(uid) || event.data?.tenantId || typeof event.eventId !== 'string' || !event.eventId) {
      throw new HttpsError('permission-denied', 'Unsupported sign-in.');
    }
    const sid = createHash('sha256').update(JSON.stringify([uid, event.eventId])).digest('hex');
    const ref = db.doc(`users/${uid}/sessions/${sid}`);
    await db.runTransaction(async tx => {
      const cutoffRef = db.doc(`authRevocations/${uid}`);
      const [previous, cutoff] = await tx.getAll(ref, cutoffRef);
      if (cutoff.exists && (!Number.isSafeInteger(cutoff.data().revokedBefore) || cutoff.data().revokedBefore < 0)) {
        throw new HttpsError('permission-denied', 'Session state requires review.');
      }
      if (!cutoff.exists) tx.create(cutoffRef, { revokedBefore: 0 });
      if (previous.exists) {
        if (previous.data().authSessionVersion !== 1 || previous.data().isRevoked !== false) {
          throw new HttpsError('permission-denied', 'Session revoked. Sign in again.');
        }
        return;
      }
      tx.create(ref, {
        sessionId: sid, authSessionVersion: 1, isRevoked: false,
        revokedAt: null, revokeReason: null, isTrusted: false,
        createdAt: FieldValue.serverTimestamp(), lastSeenAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return { sessionClaims: { sid } };
  };
}
async function assertActiveSession({ db, token, reader = db }) {
  const uid = token?.uid || token?.sub;
  if (!validUid(uid) || !validSid(token?.sid) || token.firebase?.tenant ||
      !Number.isSafeInteger(token.auth_time) || token.auth_time <= 0) {
    throw new HttpsError('unauthenticated', 'Sign in again on this device.');
  }
  const [session, cutoff] = await reader.getAll(
    db.doc(`users/${uid}/sessions/${token.sid}`), db.doc(`authRevocations/${uid}`));
  if (!session.exists || session.data().authSessionVersion !== 1 ||
      session.data().sessionId !== token.sid || session.data().isRevoked !== false ||
      (cutoff.exists && (!Number.isSafeInteger(cutoff.data().revokedBefore) || token.auth_time <= cutoff.data().revokedBefore))) {
    throw new HttpsError('unauthenticated', 'Session revoked. Sign in again.');
  }
  return token.sid;
}
function createSessionGuard({ db }) {
  return handler => async request => {
    // Signed-out recovery is separately verified by its existing handler.
    if (request.auth) await assertActiveSession({ db, token: { ...request.auth.token, uid: request.auth.uid } });
    return handler(request);
  };
}
function createRevokeDeviceSessionsHandler({ auth, db, FieldValue }) {
  return async request => {
    const uid = request.auth?.uid;
    const header = request.rawRequest?.headers?.authorization;
    if (!validUid(uid) || typeof header !== 'string' || !header.startsWith('Bearer ')) {
      throw new HttpsError('unauthenticated', 'Sign in first.');
    }
    const input = request.data;
    if (!input || Array.isArray(input) || typeof input !== 'object' ||
        !((input.mode === 'single' && Object.keys(input).length === 2 && (typeof input.sessionId === 'string' && /^[a-zA-Z0-9_-]{1,200}$/.test(input.sessionId))) ||
          (input.mode === 'others' && Object.keys(input).length === 1))) {
      throw new HttpsError('invalid-argument', 'Choose a device or all other sessions.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid) throw new HttpsError('unauthenticated', 'Invalid session.');
    const collection = db.collection(`users/${uid}/sessions`);
    const changes = { isRevoked: true, revokedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(), revokeReason: input.mode === 'others' ? 'logout_all_other' : 'manual' };
    if (input.mode === 'single') {
      await db.runTransaction(async tx => {
        await assertActiveSession({ db, token, reader: tx });
        const target = collection.doc(input.sessionId);
        const snapshot = await tx.get(target);
        if (!snapshot.exists) throw new HttpsError('not-found', 'Device session not found.');
        if (snapshot.data().isRevoked !== true) tx.update(target, changes);
      });
    } else {
      let cursor;
      do {
        cursor = await db.runTransaction(async tx => {
          await assertActiveSession({ db, token, reader: tx });
          let query = collection.orderBy('__name__').limit(200);
          if (cursor) query = query.startAfter(cursor);
          const page = await tx.get(query);
          for (const doc of page.docs) {
            if (doc.id !== token.sid && doc.data().isRevoked !== true) tx.update(doc.ref, changes);
          }
          return page.size === 200 ? page.docs[page.docs.length - 1] : null;
        });
      } while (cursor);
    }
    return { revoked: true, currentSessionId: token.sid, mode: input.mode };
  };
}
module.exports = { validSid, createSignInSessionHandler, assertActiveSession, createSessionGuard, createRevokeDeviceSessionsHandler };

