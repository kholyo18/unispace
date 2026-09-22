const { HttpsError } = require('firebase-functions/v2/https');
const { readState, validCutoff } = require('./account-state-policy');
const { removed } = require('./content-search-page');
const { GRANT_TTL_MS, ACCESS_TTL_MS, MAX_GRANTS_PER_MINUTE, uploadPolicy, audienceAllows, validId } = require('./storage-upload-policy');
const blocks = (a, b) => ['blocked_accounts', 'blocked_users', 'blocked_by']
  .flatMap(c => [`users/${a}/${c}/${b}`, `users/${b}/${c}/${a}`]);
function usable(profile, controls, deleting) {
  let state;
  try { state = readState(profile, controls, deleting); }
  catch (error) { throw new HttpsError(error.code || 'failed-precondition', 'Account state requires review.'); }
  if (state.selfDisabled || state.selfFrozen || state.adminSuspended) throw new HttpsError('permission-denied', 'Account unavailable.');
}
function createStorageUploadHandler({ auth, db, FieldValue, Timestamp, bucketName, now = Date.now }) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization;
    if (!validId(uid) || typeof header !== 'string' || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    const nowMs = now();
    if (token.uid !== uid || !Number.isSafeInteger(token.auth_time) || token.auth_time <= 0 ||
        token.auth_time > Math.floor(nowMs / 1000) + 60 || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    const i = request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== 4 ||
        !Object.hasOwn(i, 'path') || !Object.hasOwn(i, 'contentType') || !Object.hasOwn(i, 'size') || i.expectedUid !== uid) {
      throw new HttpsError('invalid-argument', 'A matching caller and media description are required.');
    }
    let policy;
    try { policy = uploadPolicy(i.path, i.contentType, i.size, uid); }
    catch (_) { throw new HttpsError('invalid-argument', 'Unsupported media path, type or size.'); }
    const bucket = bucketName();
    if (typeof bucket !== 'string' || !/^[a-z0-9][a-z0-9._-]{2,221}$/.test(bucket)) throw new HttpsError('unavailable', 'Storage is not configured.');
    async function providerAvailable(id) {
      try { if ((await auth.getUser(id)).disabled) throw new HttpsError('permission-denied', 'Account unavailable.'); }
      catch (error) {
        if (error.code === 'permission-denied') throw error;
        if (error.code === 'auth/user-not-found') throw new HttpsError('not-found', 'Account unavailable.');
        throw new HttpsError('unavailable', 'Account status could not be checked.');
      }
    }
    const grantRef = db.collection('storageUploadGrants').doc();
    return db.runTransaction(async tx => {
      const cutoffRef = db.doc(`authRevocations/${uid}`);
      const [cutoff, profile, control, deletion] = await tx.getAll(cutoffRef, db.doc(`users/${uid}`),
        db.doc(`accountStateControls/${uid}`), db.doc(`account_deletion_requests/${uid}`));
      if (!validCutoff(cutoff, token.auth_time)) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (!profile.exists) {
        // Signup uploads precede completeSignupProfile. No social uploads are granted.
        if (policy.kind !== 'profile' || control.exists || deletion.exists) throw new HttpsError('permission-denied', 'Complete signup first.');
      } else usable(profile.data(), control.data(), deletion.exists);
      if (policy.postId) {
        const [post, receipt] = await tx.getAll(db.doc(`community_posts/${policy.postId}`), db.doc(`postDeletionReceipts/${policy.postId}`));
        const data = post.data();
        if (!data || receipt.exists || !validId(data.authorId)) throw new HttpsError('not-found', 'Post unavailable.');
        if (policy.kind === 'post') {
          if (data.authorId !== uid || (data.status !== 'uploading' && removed(data))) throw new HttpsError('permission-denied', 'Post upload unavailable.');
        } else {
          if (removed(data)) throw new HttpsError('not-found', 'Post unavailable.');
          const target = data.authorId;
          if (target !== uid) await providerAvailable(target);
          const [owner, state, pendingDelete, following, reverse, ...blocked] = await tx.getAll(
            db.doc(`users/${target}`), db.doc(`accountStateControls/${target}`), db.doc(`account_deletion_requests/${target}`),
            db.doc(`users/${target}/followers/${uid}`), db.doc(`users/${uid}/followers/${target}`), ...blocks(uid, target).map(p => db.doc(p)));
          usable(owner.data(), state.data(), pendingDelete.exists);
          const p = owner.data().privacy || {};
          const privateAccount = typeof p.privateAccount === 'boolean' ? p.privateAccount : owner.data().profileVisibility === 'private';
          if (uid !== target && (blocked.some(s => s.exists) || (privateAccount && !following.exists) ||
              !audienceAllows(p.whoCanComment, following.exists, reverse.exists, 'everyone'))) {
            throw new HttpsError('permission-denied', 'Comment upload unavailable.');
          }
        }
      }
      if (policy.chatId) {
        const chat = await tx.get(db.doc(`chats/${policy.chatId}`));
        const members = chat.data()?.memberIds;
        if (!Array.isArray(members) || members.length !== 2 || new Set(members).size !== 2 ||
            !members.every(validId) || !members.includes(uid)) throw new HttpsError('permission-denied', 'Chat unavailable.');
        if (policy.kind !== 'wallpaper') {
          const peer = members.find(id => id !== uid);
          await providerAvailable(peer);
          const [owner, state, pendingDelete, following, reverse, ...blocked] = await tx.getAll(
            db.doc(`users/${peer}`), db.doc(`accountStateControls/${peer}`), db.doc(`account_deletion_requests/${peer}`),
            db.doc(`users/${peer}/followers/${uid}`), db.doc(`users/${uid}/followers/${peer}`), ...blocks(uid, peer).map(p => db.doc(p)));
          usable(owner.data(), state.data(), pendingDelete.exists);
          if (blocked.some(s => s.exists) || !audienceAllows(owner.data().privacy?.whoCanMessage, following.exists, reverse.exists, 'mutual')) {
            throw new HttpsError('permission-denied', 'Media messaging is not allowed.');
          }
        }
      }
      const previous = cutoff.data() || {};
      const start = previous.storageGrantWindowStart, count = previous.storageGrantCount;
      const inWindow = Number.isSafeInteger(start) && start <= nowMs && nowMs < start + 60000;
      if (inWindow && (!Number.isSafeInteger(count) || count < 0 || count >= MAX_GRANTS_PER_MINUTE)) {
        throw new HttpsError('resource-exhausted', 'Wait before uploading again.');
      }
      const expiresAt = Timestamp.fromMillis(nowMs + GRANT_TTL_MS);
      tx.create(grantRef, { schemaVersion: 1, uid, path: policy.path, bucket, authTime: token.auth_time,
        contentType: policy.contentType, size: policy.size, overwrite: policy.overwrite,
        createdAt: FieldValue.serverTimestamp(), expiresAt });
      // One server-owned document combines revocation and temporary Storage access,
      // leaving the second cross-service read for an exact grant or chat/post record.
      tx.set(cutoffRef, { revokedBefore: previous.revokedBefore ?? 0, storageSchema: 1, storageAllowed: true,
        storageUntil: Timestamp.fromMillis(nowMs + ACCESS_TTL_MS), storageGrantWindowStart: inWindow ? start : nowMs,
        storageGrantCount: inWindow ? count + 1 : 1 }, { merge: true });
      return { grantId: grantRef.id, uid, path: policy.path, bucket, contentType: policy.contentType,
        size: policy.size, expiresAt: expiresAt.toMillis() };
    });
  };
}
module.exports = { createStorageUploadHandler };
