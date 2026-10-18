const { HttpsError } = require('firebase-functions/v2/https');
const { assertActiveSession } = require('./device-sessions');
const { assertGroupMessage } = require('./chat-groups');
const { uploadPolicy } = require('./storage-upload-policy');
const MAX_SIZE = 20 * 1024 * 1024;
const validId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,260}$/.test(value);
const fail = (code, message) => { throw new HttpsError(code, message); };

// Signed URLs are short-lived capabilities: revocation prevents NEW issuance,
// while a URL already returned remains usable until its 90s/120s expiry.
function createChatDocumentHandlers({ db, auth, FieldValue, Timestamp, bucket, prepareUpload }) {
  async function identity(request) {
    const header = request.rawRequest?.headers?.authorization;
    if (!validId(request.auth?.uid) || !header?.startsWith('Bearer ')) fail('unauthenticated', 'Sign in first.');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { fail('unauthenticated', 'Sign in again.'); }
    if (token.uid !== request.auth.uid) fail('unauthenticated', 'Invalid session.');
    await assertActiveSession({ db, token });
    return token;
  }

  async function prepare(request) {
    const token = await identity(request), input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 4 ||
        input.expectedUid !== token.uid || input.contentType !== 'application/octet-stream') {
      fail('invalid-argument', 'Invalid document upload.');
    }
    let policy;
    try { policy = uploadPolicy(input.path, input.contentType, input.size, token.uid); }
    catch (_) { fail('invalid-argument', 'Invalid document upload.'); }
    if (policy.kind !== 'chat' || !input.path.startsWith(`chats/${policy.chatId}/files/`)) {
      fail('invalid-argument', 'Documents must use the conversation files folder.');
    }
    // Reuse the full server account, audience, membership, blocks and grant budget.
    const grant = await prepareUpload(request);
    const storage = bucket();
    if (grant.bucket !== storage.name || grant.path !== input.path || grant.uid !== token.uid ||
        grant.size !== input.size || grant.contentType !== input.contentType) fail('internal', 'Invalid upload authorization.');
    const uploadExpiresAt = Math.min(Date.now() + 90000, grant.expiresAt);
    if (!Number.isSafeInteger(uploadExpiresAt) || uploadExpiresAt <= Date.now()) fail('unavailable', 'Try again.');
    const uploadHeaders = {
      'Content-Type': input.contentType,
      'Content-Length': String(input.size),
      'x-goog-if-generation-match': '0',
    };
    const [uploadUrl] = await storage.file(input.path).getSignedUrl({
      version: 'v4', action: 'write', expires: uploadExpiresAt, contentType: input.contentType,
      extensionHeaders: { 'content-length': String(input.size), 'x-goog-if-generation-match': '0' },
    });
    await assertActiveSession({ db, token });
    return { ...grant, uploadUrl, uploadExpiresAt, uploadHeaders,
      fileUrl: `https://firebasestorage.googleapis.com/v0/b/${storage.name}/o/${encodeURIComponent(input.path)}` };
  }

  async function authorizedMessage(token, chatId, messageId) {
    const result = await db.runTransaction(async tx => {
      const chat = (await tx.get(db.doc(`chats/${chatId}`))).data();
      if (!chat || !Array.isArray(chat.memberIds) || !chat.memberIds.includes(token.uid) ||
          !['direct', 'group'].includes(chat.type) || chat.memberIds.some(uid => !validId(uid)) ||
          new Set(chat.memberIds).size !== chat.memberIds.length ||
          (chat.type === 'direct' && chat.memberIds.length !== 2)) fail('permission-denied', 'Conversation unavailable.');
      // Reading an existing direct message does not create a new direct request.
      // Group policy enforces current members, canonical accounts and mutual blocks.
      await assertGroupMessage({ db, tx, token, chat: { ...chat, type: 'group' }, enforcePosting: false });
      const message = (await tx.get(db.doc(`chats/${chatId}/messages/${messageId}`))).data();
      if (!message || message.type !== 'file' || typeof message.fileUrl !== 'string' ||
          message.deleted === true || message.isDeleted === true ||
          message.hiddenBy?.[token.uid] === true) fail('not-found', 'Document unavailable.');
      return { message, members: chat.memberIds };
    });
    let records;
    try { records = await auth.getUsers(result.members.map(uid => ({ uid }))); }
    catch (_) { fail('unavailable', 'Account status unavailable.'); }
    if (records.notFound.length || records.users.some(user => user.disabled)) fail('permission-denied', 'Account unavailable.');
    return result.message;
  }

  async function read(request) {
    const token = await identity(request), input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !validId(input.chatId) || !validId(input.messageId)) fail('invalid-argument', 'Invalid document request.');
    const message = await authorizedMessage(token, input.chatId, input.messageId), storage = bucket();
    let path;
    try {
      const locator = new URL(message.fileUrl), prefix = `/v0/b/${storage.name}/o/`;
      if (locator.protocol !== 'https:' || locator.hostname !== 'firebasestorage.googleapis.com' ||
          locator.port || locator.username || locator.password || !locator.pathname.startsWith(prefix)) throw Error();
      path = decodeURIComponent(locator.pathname.slice(prefix.length));
      const policy = uploadPolicy(path, 'application/octet-stream', message.size, token.uid);
      if (policy.kind !== 'chat' || policy.chatId !== input.chatId || !path.startsWith(`chats/${input.chatId}/files/`)) throw Error();
    } catch (_) { fail('invalid-argument', 'Invalid document source.'); }
    const file = storage.file(path);
    let metadata;
    try { [metadata] = await file.getMetadata(); }
    catch (error) { fail(error.code === 404 ? 'not-found' : 'unavailable', 'Document unavailable.'); }
    const size = Number(metadata.size);
    if (!metadata.generation || !Number.isSafeInteger(size) || size <= 0 || size > MAX_SIZE ||
        size !== message.size || metadata.contentType !== 'application/octet-stream') fail('failed-precondition', 'Invalid document metadata.');
    const expiresAt = Date.now() + 120000;
    const [url] = await file.getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt,
      queryParams: { generation: String(metadata.generation) } });
    const fresh = await authorizedMessage(token, input.chatId, input.messageId);
    if (fresh.fileUrl !== message.fileUrl || fresh.size !== message.size) fail('permission-denied', 'Document changed.');
    if (expiresAt <= Date.now()) fail('unavailable', 'Try again.');
    return { url, expiresAt, size, fileName: typeof fresh.fileName === 'string' ? fresh.fileName : path.split('/').at(-1) };
  }
  return { prepare, read };
}

module.exports = { createChatDocumentHandlers };
