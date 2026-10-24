const { HttpsError } = require('firebase-functions/v2/https');
const { assertActiveSession } = require('./device-sessions');
const { assertChatAccount } = require('./chat-account');
const { assertGroupMessage } = require('./chat-groups');
const { validChatMembers } = require('./chat-service');
const { createPublicProfileHandler } = require('./public-profile');
const { createMediaDownloadHandler } = require('./media-download');
const { removed } = require('./content-search-page');
const fail = (code, message = 'Media unavailable.') => { throw new HttpsError(code, message); };

function parseProtectedMediaSource(source, bucketName) {
  try {
    if (typeof source !== 'string' || !source || source.length > 4096 || /[\x00-\x20\x7f\\]/.test(source)) throw Error();
    const url = new URL(source), prefix = `/v0/b/${bucketName}/o/`;
    if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' ||
        url.port || url.username || url.password || url.hash || !url.pathname.startsWith(prefix)) throw Error();
    const path = decodeURIComponent(url.pathname.slice(prefix.length));
    const parts = path.split('/');
    if (parts.some(p => !p || p === '.' || p === '..' || /[\\\x00-\x1f\x7f]/.test(p)) || path.length > 1024) throw Error();
    return { path, parts };
  } catch (_) { fail('invalid-argument', 'Invalid media source.'); }
}

function visibleMessage(message, chat, uid) {
  if (!message || message.viewOnce === true || message.type === 'viewOnce' ||
      message.deleted === true || message.isDeleted === true || message.deletedAt != null ||
      message.deletedForEveryone === true || chat[`deletedBy_${uid}`] === true ||
      message.hiddenBy?.[uid] === true || (Array.isArray(message.hiddenBy) && message.hiddenBy.includes(uid))) return false;
  const cleared = chat.clearedAt?.[uid];
  if (cleared != null && (typeof cleared.toMillis !== 'function' ||
      typeof message.createdAt?.toMillis !== 'function' || message.createdAt.toMillis() <= cleared.toMillis())) return false;
  return true;
}

function createProtectedMediaHandler({ auth, db, bucket }) {
  const profileReader = createPublicProfileHandler({ auth, db });
  const postReader = createMediaDownloadHandler({ auth, db, bucket }, false, false, { verifyOnly: true });
  const commentReader = createMediaDownloadHandler({ auth, db, bucket }, false, true, { verifyOnly: true });
  return async request => {
    const input = request.data, uid = request.auth?.uid;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        !Object.hasOwn(input, 'url')) fail('invalid-argument', 'A media URL is required.');
    const header = request.rawRequest?.headers?.authorization;
    if (!uid || typeof header !== 'string' || !header.startsWith('Bearer ')) fail('unauthenticated');
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); } catch (_) { fail('unauthenticated'); }
    if (token.uid !== uid) fail('unauthenticated');
    const storage = bucket(), { path, parts } = parseProtectedMediaSource(input.url, storage.name);
    async function ownedPreview() {
      let meta;
      try { [meta] = await storage.file(path).getMetadata(); } catch (_) { return false; }
      const custom = meta.metadata || {}, id = custom.uploadGrantId;
      if (custom.protectedUploadVersion !== '1' || custom.uploadedBy !== uid ||
          typeof id !== 'string' || !/^[A-Za-z0-9_-]{20}$/.test(id) || custom.firebaseStorageDownloadTokens) return false;
      const [grant, ticket] = await db.getAll(db.doc(`storageUploadGrants/${id}`), db.doc(`protectedUploadTickets/${id}`));
      const g = grant.data(), t = ticket.data();
      return g?.uid === uid && g.path === path && g.bucket === storage.name &&
        t?.uid === uid && t.path === path && t.bucket === storage.name && t.state === 'complete' &&
        t.finalGeneration === String(meta.generation);
    }
    async function account(id, allowSignup = false) {
      return db.runTransaction(async tx => {
        const profile = await tx.get(db.doc(`users/${id}`));
        if (!profile.exists && allowSignup) {
          const rows = await tx.getAll(db.doc(`accountStateControls/${id}`), db.doc(`account_deletion_requests/${id}`));
          if (rows.some(row => row.exists)) fail('permission-denied');
          return false;
        }
        await assertChatAccount({ db, tx, uid: id, profile: profile.data() });
        return true;
      });
    }
    async function authorize() {
      await assertActiveSession({ db, token });
      const ownPreview = parts[0] === 'users' && parts.length === 3 && parts[1] === uid;
      const hasProfile = await account(uid, ownPreview);
      if (parts[0] === 'users' && parts.length === 3) {
        const owner = parts[1];
        if (!hasProfile && ownPreview) { if (!await ownedPreview()) fail('not-found'); return; }
        await account(owner);
        const visible = await profileReader({ ...request, data: { userId: owner } });
        const matches = ['profileImageUrl', 'coverImageUrl'].some(field => {
          try { return parseProtectedMediaSource(visible[field], storage.name).path === path; } catch (_) { return false; }
        });
        if (!matches && !(ownPreview && await ownedPreview())) fail('not-found');
        // Owners may preview a just-uploaded object before saving its profile field.
        return;
      }
      if (parts[0] === 'community_posts') {
        const comment = parts.length === 6 && parts[2] === 'comments';
        if (!comment && !(parts.length === 4 && ['images', 'videos'].includes(parts[2]))) fail('invalid-argument');
        if (!comment && await ownedPreview()) {
          const [post, receipt] = await db.getAll(db.doc(`community_posts/${parts[1]}`), db.doc(`postDeletionReceipts/${parts[1]}`));
          const data = post.data();
          if (data?.authorId === uid && !receipt.exists &&
              !removed(data.status === 'uploading' ? { ...data, status: 'published' } : data)) return;
        }
        await (comment ? commentReader : postReader)({ ...request, data: {
          postId: parts[1], url: input.url, ...(comment ? { commentId: parts[4] } : {}),
        } });
        return;
      }
      if (parts[0] !== 'chats' || parts.length !== 4 ||
          !['images', 'videos', 'audio', 'files', 'wallpaper'].includes(parts[2])) fail('invalid-argument');
      const chatId = parts[1];
      const members = await db.runTransaction(async tx => {
        const chat = (await tx.get(db.doc(`chats/${chatId}`))).data();
        if (!validChatMembers(chat) || !chat.memberIds.includes(uid) || chat[`deletedBy_${uid}`] === true) fail('permission-denied');
        await assertGroupMessage({ db, tx, token, chat: { ...chat, type: 'group' }, enforcePosting: false });
        if (parts[2] === 'wallpaper') {
          if (parts[3] !== `${uid}.jpg` || (chat.theme?.[uid]?.wallpaperUrl !== input.url && !await ownedPreview())) fail('not-found');
        } else if (!(chat.type === 'group' && parts[2] === 'images' && chat.photoUrl === input.url)) {
          const fields = { imageUrl: 'image', gifUrl: 'gif', videoUrl: 'video', audioUrl: 'audio', fileUrl: 'file', thumbnailUrl: 'video' };
          let found = false;
          for (const [field, type] of Object.entries(fields)) {
            const query = db.collection(`chats/${chatId}/messages`).where(field, '==', input.url).limit(25);
            let cursor;
            do {
              const rows = await tx.get(cursor ? query.startAfter(cursor) : query);
              if (rows.docs.some(row => row.data().type === type && visibleMessage(row.data(), chat, uid))) { found = true; break; }
              cursor = rows.size === 25 ? rows.docs.at(-1) : null;
            } while (cursor);
            if (found) break;
          }
          if (!found) fail('not-found');
        }
        return chat.memberIds;
      });
      for (let start = 0; start < members.length; start += 100) {
        let users;
        try { users = await auth.getUsers(members.slice(start, start + 100).map(id => ({ uid: id }))); }
        catch (_) { fail('unavailable'); }
        if (users.notFound.length || users.users.some(user => user.disabled)) fail('permission-denied');
      }
    }
    await authorize();
    const file = storage.file(path);
    let metadata;
    try { [metadata] = await file.getMetadata(); }
    catch (error) { fail(error.code === 404 ? 'not-found' : 'unavailable'); }
    if (!metadata.generation || !Number.isSafeInteger(Number(metadata.size)) || Number(metadata.size) <= 0) fail('not-found');
    const expiresAt = Date.now() + 120000;
    const [url] = await file.getSignedUrl({ version: 'v4', action: 'read', expires: expiresAt,
      queryParams: { generation: String(metadata.generation) } });
    await authorize();
    if (expiresAt <= Date.now()) fail('unavailable');
    return { url, expiresAt };
  };
}
module.exports = { createProtectedMediaHandler, parseProtectedMediaSource };
