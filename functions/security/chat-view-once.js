const {validChatMembers,assertActiveChatRecipients}=require('./chat-service');
const { HttpsError } = require('firebase-functions/v2/https');
const { assertActiveSession } = require('./device-sessions');
const { assertGroupMessage } = require('./chat-groups');
const validId = v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,260}$/.test(v);
const validMedia = v => typeof v === 'string' && /^[A-Za-z0-9_-]{20,80}$/.test(v);
const TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX = 20 * 1024 * 1024, TTL = 14 * 86400000;
const fail = (code, message) => { throw new HttpsError(code, message); };
const keys = (v, expected) => v && typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === expected.length && expected.every(k => Object.hasOwn(v, k));

function createChatViewOnceHandlers({ db, auth, FieldValue, Timestamp, bucket, prepareUpload }) {
  const assetRef = id => db.doc(`chatViewOnceAssets/${id}`);
  async function identity(request, callable = false) {
    const header = (callable ? request.rawRequest : request)?.headers?.authorization;
    if (typeof header !== 'string' || !header.startsWith('Bearer ')) fail('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { fail('unauthenticated', 'Sign in again.'); }
    if (!validId(token.uid) || callable && token.uid !== request.auth?.uid) fail('unauthenticated', 'Invalid session.');
    await assertActiveSession({ db, token });
    return token;
  }
  function usable(asset, uid, chatId) {
    if (!asset || asset.ownerId !== uid || asset.chatId !== chatId || !['prepared', 'bound'].includes(asset.state) ||
        typeof asset.path !== 'string' || !asset.path.startsWith(`chat_view_once/${chatId}/`) ||
        !validMedia(asset.path.slice(`chat_view_once/${chatId}/`.length)) || !TYPES.has(asset.contentType) ||
        !Number.isSafeInteger(asset.size) || asset.size <= 0 || asset.size > MAX ||
        asset.state === 'bound' && !/^\d+$/.test(String(asset.generation)) ||
        !Number.isFinite(asset.expiresAt?.toMillis?.()) || asset.expiresAt.toMillis() <= Date.now()) fail('failed-precondition', 'Photo unavailable.');
  }
  async function object(asset, generation) {
    const file = bucket().file(asset.path, generation ? { generation: String(generation) } : undefined);
    let metadata;
    try { [metadata] = await file.getMetadata(); }
    catch (error) { fail(error.code === 404 ? 'not-found' : 'unavailable', 'Photo unavailable.'); }
    if (!metadata.generation || generation && String(metadata.generation) !== String(generation) ||
        Number(metadata.size) !== asset.size || metadata.contentType !== asset.contentType ||
        metadata.metadata?.firebaseStorageDownloadTokens) fail('failed-precondition', 'Invalid photo metadata.');
    return { file, generation: String(metadata.generation) };
  }
  async function prepare(request) {
    const token = await identity(request, true), input = request.data;
    if (!keys(input, ['chatId', 'mediaId', 'size', 'contentType']) || !validId(input.chatId) || !validMedia(input.mediaId) ||
        !TYPES.has(input.contentType) || !Number.isSafeInteger(input.size) || input.size <= 0 || input.size > MAX) fail('invalid-argument', 'Invalid photo upload.');
    const path = `chat_view_once/${input.chatId}/${input.mediaId}`;
    // Reuse full account, privacy, membership and upload-budget checks. The
    // virtual public path is never uploaded; only this private path is signed.
    const grant = await prepareUpload({ ...request, data: { expectedUid: token.uid, path: `chats/${input.chatId}/images/${input.mediaId}`, size: input.size, contentType: input.contentType } });
    const storage = bucket();
    if (grant.bucket !== storage.name || grant.uid !== token.uid) fail('internal', 'Invalid upload grant.');
    await db.runTransaction(async tx => {
      await assertActiveSession({ db, token, reader: tx });
      const old = await tx.get(assetRef(input.mediaId));
      if (old.exists) {
        const a = old.data();
        usable(a, token.uid, input.chatId);
        if (a.state !== 'prepared' || a.size !== input.size || a.contentType !== input.contentType) fail('already-exists', 'Photo id already used.');
      } else tx.create(assetRef(input.mediaId), { ownerId: token.uid, chatId: input.chatId, path, size: input.size, contentType: input.contentType,
        state: 'prepared', createdAt: FieldValue.serverTimestamp(), expiresAt: Timestamp.fromMillis(Date.now() + TTL) });
    });
    const uploadExpiresAt = Math.min(Date.now() + 90000, grant.expiresAt);
    if (!Number.isFinite(uploadExpiresAt) || uploadExpiresAt <= Date.now()) fail('unavailable', 'Try again.');
    const uploadHeaders = { 'Content-Type': input.contentType, 'Content-Length': String(input.size), 'x-goog-if-generation-match': '0' };
    const [uploadUrl] = await storage.file(path).getSignedUrl({ version: 'v4', action: 'write', expires: uploadExpiresAt, contentType: input.contentType,
      extensionHeaders: { 'content-length': String(input.size), 'x-goog-if-generation-match': '0' } });
    await assertActiveSession({ db, token });
    return { mediaId: input.mediaId, path, size: input.size, contentType: input.contentType, uploadUrl, uploadHeaders, uploadExpiresAt };
  }
  async function prepareForSend({ uid, chatId, mediaId }) {
    if (!validMedia(mediaId) || !validId(chatId) || !validId(uid)) fail('invalid-argument', 'Invalid photo.');
    const asset = (await assetRef(mediaId).get()).data();
    usable(asset, uid, chatId);
    return (await object(asset, asset.generation)).generation;
  }
  async function confirmUpload(request) {
    const token = await identity(request, true), input = request.data;
    if (!keys(input, ['chatId', 'mediaId']) || !validId(input.chatId) || !validMedia(input.mediaId)) fail('invalid-argument', 'Invalid photo confirmation.');
    const ref = assetRef(input.mediaId), snapshot = await ref.get(), asset = snapshot.data();
    usable(asset, token.uid, input.chatId);
    await object(asset, asset.generation);
    // Recheck after the object lookup. Only the owner learns whether the
    // original immutable upload succeeded; no URL, bytes or metadata escapes.
    await db.runTransaction(async tx => {
      await assertActiveSession({ db, token, reader: tx });
      const fresh = await tx.get(ref);
      usable(fresh.data(), token.uid, input.chatId);
      if (!fresh.updateTime.isEqual(snapshot.updateTime)) fail('aborted', 'Photo changed. Retry confirmation.');
    });
    return { uploaded: true };
  }
  async function bindForSend({ tx, uid, chatId, messageId, mediaId, generation, memberIds }) {
    if (!validMedia(mediaId) || !validId(messageId) || !Array.isArray(memberIds) || !memberIds.includes(uid) || memberIds.some(v => !validId(v)) || new Set(memberIds).size !== memberIds.length) fail('invalid-argument', 'Invalid photo recipients.');
    const ref = assetRef(mediaId), asset = (await tx.get(ref)).data();
    usable(asset, uid, chatId);
    if (asset.state !== 'prepared' || !/^\d+$/.test(String(generation))) fail('failed-precondition', 'Photo already sent.');
    const recipients = [...new Set(memberIds.filter(id => id !== uid))];
    if (!recipients.length) fail('failed-precondition', 'Photo needs a recipient.');
    // Caller must invoke only after ALL reads in the send transaction.
    return () => tx.update(ref, { state: 'bound', messageId, generation: String(generation), recipients, consumedBy: {}, boundAt: FieldValue.serverTimestamp() });
  }
  async function consume(request) {
    const token = await identity(request), input = request.body;
    if (!keys(input, ['chatId', 'messageId']) || !validId(input.chatId) || !validId(input.messageId)) fail('invalid-argument', 'Invalid photo request.');
    const messageRef = db.doc(`chats/${input.chatId}/messages/${input.messageId}`);
    const initial = (await messageRef.get()).data();
    if (initial?.type !== 'viewOnce' || !validMedia(initial.mediaId)) fail('not-found', 'Photo unavailable.');
    const ref = assetRef(initial.mediaId), initialAsset = (await ref.get()).data();
    if (!initialAsset || initialAsset.state !== 'bound' || !initialAsset.recipients?.includes(token.uid) || initialAsset.ownerId === token.uid) fail('permission-denied', 'Photo unavailable.');
    usable(initialAsset, initial.authorId, input.chatId);
    const currentChat = (await db.doc(`chats/${input.chatId}`).get()).data();
    if (!validChatMembers(currentChat) || !currentChat.memberIds.includes(token.uid)) fail('permission-denied', 'Conversation unavailable.');
    await assertActiveChatRecipients(auth, currentChat.memberIds);
    const resolved = await object(initialAsset, initialAsset.generation);
    await db.runTransaction(async tx => {
      const [chatDoc, messageDoc, assetDoc] = await tx.getAll(db.doc(`chats/${input.chatId}`), messageRef, ref);
      const chat = chatDoc.data(), message = messageDoc.data(), asset = assetDoc.data();
      if (!validChatMembers(chat) ||
          chat.type === 'direct' && chat.memberIds.length !== 2 || JSON.stringify(chat.memberIds) !== JSON.stringify(currentChat.memberIds)) fail('permission-denied', 'Conversation changed.');
      await assertGroupMessage({ db, tx, token, chat: { ...chat, type: 'group' }, enforcePosting: false });
      if (!message || message.type !== 'viewOnce' || message.mediaId !== initial.mediaId || message.deleted === true || message.isDeleted === true || message.hiddenBy?.[token.uid] === true) fail('not-found', 'Photo unavailable.');
      usable(asset, message.authorId, input.chatId);
      if (asset.state !== 'bound' || asset.messageId !== input.messageId || asset.ownerId === token.uid || !asset.recipients.includes(token.uid) ||
          asset.path !== initialAsset.path || asset.generation !== resolved.generation || asset.size !== initialAsset.size || asset.contentType !== initialAsset.contentType) fail('permission-denied', 'Photo unavailable.');
      if (Object.hasOwn(asset.consumedBy || {}, token.uid)) fail('already-exists', 'Photo already opened.');
      tx.update(ref, { consumedBy: { ...asset.consumedBy, [token.uid]: Timestamp.now() } });
      // Public metadata only: clients can render an opened indicator, never bytes.
      tx.update(messageRef, { viewOnceOpenedBy: { ...(message.viewOnceOpenedBy || {}), [token.uid]: true } });
    });
    // Consumption commits BEFORE streaming. Disconnects consume the photo too.
    return { file: resolved.file, contentType: initialAsset.contentType, size: initialAsset.size };
  }
  async function cleanup() {
    const cutoff = Timestamp.now();
    const expired = await db.collection('chatViewOnceAssets').where('expiresAt', '<=', cutoff).limit(100).get();
    const result = { scanned: expired.size, removed: 0, failed: 0 };
    for (const doc of expired.docs) {
      const asset = doc.data();
      try {
        if (!validMedia(doc.id) || !validId(asset.chatId) || asset.path !== `chat_view_once/${asset.chatId}/${doc.id}` ||
            !['prepared', 'bound'].includes(asset.state)) throw Error('Invalid expired asset.');
        let generation = asset.generation;
        if (asset.state === 'bound' && !/^\d+$/.test(String(generation))) throw Error('Invalid pinned generation.');
        try {
          // Abandoned uploads have no pinned generation. Resolve it once, then
          // delete only that generation; never delete a replacement object.
          if (asset.state === 'prepared') {
            const [metadata] = await bucket().file(asset.path).getMetadata();
            generation = metadata.generation;
            if (!/^\d+$/.test(String(generation))) throw Error('Invalid generation.');
          }
          await bucket().file(asset.path, { generation: String(generation) }).delete({ ifGenerationMatch: String(generation) });
        } catch (error) { if (Number(error.code) !== 404) throw error; }
        const removed = await db.runTransaction(async tx => {
          const fresh = await tx.get(doc.ref);
          // Expiry never renews in application code. This extra guard prevents
          // deleting metadata changed by a concurrent maintenance operation.
          if (!fresh.exists || !fresh.updateTime.isEqual(doc.updateTime)) return false;
          tx.delete(doc.ref); return true;
        });
        if (removed) result.removed++;
      } catch (_) {
        // Preserve the ticket for retry on storage/IAM/database failure.
        result.failed++;
      }
    }
    return result;
  }
  return { prepare, prepareForSend, bindForSend, consume, cleanup, confirmUpload };
}
module.exports = { createChatViewOnceHandlers };
