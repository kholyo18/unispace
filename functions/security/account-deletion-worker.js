const { FieldPath } = require('firebase-admin/firestore');
const { randomUUID } = require('node:crypto');

const SECURITY_RETENTION_DAYS = 90;
const MODERATION_RETENTION_DAYS = 180;
const REQUEST_AUDIT_DAYS = 30;
const LEASE_MINUTES = 12;
const PAGE_SIZE = 120;

const DAY_MS = 24 * 60 * 60 * 1000;
const isObject = value => value && typeof value === 'object' && !Array.isArray(value);
const list = value => Array.isArray(value) ? value : [];
const map = value => isObject(value) ? value : {};
const validId = value => typeof value === 'string' && value.length > 0 && value.length <= 512 && !value.includes('/');

function without(listValue, uid) {
  return list(listValue).filter(value => value !== uid);
}

function removeMapKey(value, uid) {
  const result = { ...map(value) };
  if (!Object.hasOwn(result, uid)) return { value: result, changed: false };
  delete result[uid];
  return { value: result, changed: true };
}

function scrubCommentsForDeletedUser(rawComments, uid) {
  const comments = list(rawComments);
  const nodes = new Map();
  const deletedCommentIds = new Set();

  function index(rows, parentId = null, depth = 0) {
    if (depth > 40) throw new Error('comment-depth-limit');
    for (const row of list(rows)) {
      if (!isObject(row)) continue;
      const id = typeof row.id === 'string' ? row.id : null;
      if (id) nodes.set(id, { node: row, parentId });
      index(row.replies, id || parentId, depth + 1);
    }
  }
  index(comments);

  function replacementFor(id, seen = new Set()) {
    if (!id || seen.has(id)) return null;
    seen.add(id);
    const info = nodes.get(id);
    if (!info) return null;
    if (info.node.authorId !== uid) return id;
    const next = validId(info.node.replyToId) ? info.node.replyToId : info.parentId;
    return replacementFor(next, seen);
  }

  let changed = false;
  function transform(rows, parentId = null, depth = 0) {
    if (depth > 40) throw new Error('comment-depth-limit');
    const output = [];
    for (const original of list(rows)) {
      if (!isObject(original)) continue;
      const node = { ...original };
      const id = typeof node.id === 'string' ? node.id : null;
      const replies = transform(node.replies, id || parentId, depth + 1);
      node.replies = replies;

      const up = without(node.upvotedBy, uid);
      const down = without(node.downvotedBy, uid);
      if (up.length !== list(node.upvotedBy).length) {
        node.upvotedBy = up;
        changed = true;
      }
      if (down.length !== list(node.downvotedBy).length) {
        node.downvotedBy = down;
        changed = true;
      }

      const replyingToDeleted = node.replyToAuthorId === uid ||
        (typeof node.replyToId === 'string' && nodes.get(node.replyToId)?.node?.authorId === uid);
      if (replyingToDeleted) {
        const replacement = replacementFor(node.replyToId);
        if (replacement) {
          const target = nodes.get(replacement)?.node;
          node.replyToId = replacement;
          if (typeof target?.authorId === 'string') node.replyToAuthorId = target.authorId;
          else delete node.replyToAuthorId;
        } else {
          delete node.replyToId;
          delete node.replyToAuthorId;
        }
        delete node.replyToText;
        delete node.replyToName;
        delete node.replyToAuthor;
        changed = true;
      }

      if (node.authorId === uid) {
        if (id) deletedCommentIds.add(id);
        changed = true;
        output.push(...replies);
        continue;
      }
      output.push(node);
    }
    return output;
  }

  return {
    comments: transform(comments),
    changed,
    deletedCommentIds: [...deletedCommentIds],
  };
}

function scrubChatMessage(data, uid, tombstoneId) {
  const original = map(data);
  const patch = {};
  const deleteFields = new Set();
  const storageUrls = [];
  let changed = false;

  const reactions = removeMapKey(original.reactions, uid);
  if (reactions.changed) {
    patch.reactions = reactions.value;
    changed = true;
  }
  const starred = removeMapKey(original.starredBy, uid);
  if (starred.changed) {
    patch.starredBy = starred.value;
    changed = true;
  }

  if (original.replyToAuthorId === uid) {
    patch.replyToAuthorId = tombstoneId;
    patch.replyToText = 'رسالة من حساب محذوف';
    patch.replyToName = 'حساب محذوف';
    changed = true;
  }

  if (original.authorId === uid) {
    for (const key of ['imageUrl', 'gifUrl', 'videoUrl', 'audioUrl', 'fileUrl']) {
      if (typeof original[key] === 'string' && original[key]) storageUrls.push(original[key]);
      if (Object.hasOwn(original, key)) deleteFields.add(key);
    }
    for (const key of ['fileName', 'size', 'durationMs', 'editedAt',
      'replyToId', 'replyToText', 'replyToAuthorId', 'replyToName']) {
      if (Object.hasOwn(original, key)) deleteFields.add(key);
    }
    patch.authorId = tombstoneId;
    patch.type = 'text';
    patch.text = 'تم حذف محتوى هذه الرسالة بعد حذف الحساب.';
    patch.deletedAccountMessage = true;
    changed = true;
  }

  return { patch, deleteFields: [...deleteFields], storageUrls, changed };
}

function scrubChatDocument(data, uid, tombstoneId) {
  const original = map(data);
  const patch = {};
  const deleteFields = [];
  let changed = false;

  if (list(original.memberIds).includes(uid)) {
    patch.memberIds = [...new Set(list(original.memberIds).map(id => id === uid ? tombstoneId : id))];
    changed = true;
  }

  if (isObject(original.members) && Object.hasOwn(original.members, uid)) {
    const members = { ...original.members };
    delete members[uid];
    members[tombstoneId] = { name: 'حساب محذوف', photoUrl: null, deleted: true };
    patch.members = members;
    changed = true;
  }

  for (const field of ['unread', 'lastReadAt', 'muted', 'clearedAt', 'nicknames',
    'theme', 'autoTranslate', 'autoTranslateLang', 'typing']) {
    const cleaned = removeMapKey(original[field], uid);
    if (cleaned.changed) {
      patch[field] = cleaned.value;
      changed = true;
    }
  }

  if (original.lastSenderId === uid) {
    patch.lastSenderId = tombstoneId;
    patch.lastMessage = 'رسالة من حساب محذوف';
    changed = true;
  }

  for (const prefix of ['pinned_', 'muted_', 'deletedBy_']) {
    const field = prefix + uid;
    if (Object.hasOwn(original, field)) {
      deleteFields.push(field);
      changed = true;
    }
  }

  return { patch, deleteFields, changed };
}

function scrubNotification(data, uid) {
  const original = map(data);
  const ids = list(original.actorIds).filter(id => typeof id === 'string' && id !== uid);
  const names = { ...map(original.actorNames) };
  delete names[uid];

  if (original.actorId !== uid && !list(original.actorIds).includes(uid) && !Object.hasOwn(map(original.actorNames), uid)) {
    return { changed: false, deleteDocument: false, patch: {} };
  }

  if (original.actorId === uid && ids.length === 0) {
    return { changed: true, deleteDocument: true, patch: {} };
  }

  const lead = original.actorId === uid ? ids[0] : original.actorId;
  const patch = {
    actorIds: ids,
    actorNames: names,
    count: ids.length || (lead ? 1 : 0),
  };
  if (original.actorId === uid) {
    patch.actorId = lead;
    patch.actorName = names[lead] || 'طالب UniSpace';
    patch.actorPhotoUrl = null;
  }
  return { changed: true, deleteDocument: false, patch };
}

function scrubReport(data, uid, tombstoneId, Timestamp, nowMs) {
  const original = map(data);
  const patch = {
    containsDeletedAccount: true,
    deletedAccountAnonymizedAt: Timestamp.fromMillis(nowMs),
    retentionDeleteAt: Timestamp.fromMillis(nowMs + MODERATION_RETENTION_DAYS * DAY_MS),
  };
  let changed = false;

  if (original.reporterId === uid) {
    patch.reporterId = tombstoneId;
    changed = true;
  }
  if (original.ownerId === uid) {
    patch.ownerId = tombstoneId;
    patch.ownerName = 'حساب محذوف';
    if (isObject(original.snapshot)) {
      const snapshot = { ...original.snapshot };
      for (const key of ['displayName', 'authorName']) {
        if (Object.hasOwn(snapshot, key)) snapshot[key] = 'حساب محذوف';
      }
      for (const key of ['username', 'photoUrl', 'authorPhotoUrl']) {
        if (Object.hasOwn(snapshot, key)) snapshot[key] = '';
      }
      patch.snapshot = snapshot;
    }
    changed = true;
  }
  if (original.reviewedBy === uid) {
    patch.reviewedBy = tombstoneId;
    changed = true;
  }
  if (Array.isArray(original.history)) {
    const history = original.history.map(item => {
      if (!isObject(item) || item.by !== uid) return item;
      changed = true;
      return { ...item, by: tombstoneId };
    });
    if (changed) patch.history = history;
  }
  return { changed, patch };
}

function storageObjectFromUrl(value, bucketName) {
  if (typeof value !== 'string' || !value || typeof bucketName !== 'string' || !bucketName) return null;
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com') return null;
    const marker = '/v0/b/' + bucketName + '/o/';
    if (!url.pathname.startsWith(marker)) return null;
    const objectPath = decodeURIComponent(url.pathname.slice(marker.length));
    return objectPath && !objectPath.startsWith('/') ? objectPath : null;
  } catch (_) {
    return null;
  }
}

async function deleteFilesWithPrefix(bucket, prefix) {
  try {
    await bucket.deleteFiles({ prefix });
  } catch (error) {
    if (error?.code !== 404) throw error;
  }
}

async function deleteExactStorageObject(bucket, objectPath) {
  if (!objectPath) return;
  try {
    await bucket.file(objectPath).delete({ ignoreNotFound: true });
  } catch (error) {
    if (error?.code !== 404) throw error;
  }
}

async function deleteQueryDocuments(query, db) {
  while (true) {
    const snapshot = await query.limit(PAGE_SIZE).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
    if (snapshot.size < PAGE_SIZE) return;
  }
}

async function deleteReceiptRows(db, uid) {
  for (const name of ['postPublicationReceipts', 'repostPublicationReceipts', 'postDeletionReceipts']) {
    await deleteQueryDocuments(db.collection(name).where('ownerId', '==', uid), db);
  }
}

async function deleteUsernameReservations(db, uid) {
  await deleteQueryDocuments(db.collection('usernameReservations').where('uid', '==', uid), db);
}

async function deleteMessageRequests(db, uid) {
  await deleteQueryDocuments(db.collection('messageRequests').where('senderId', '==', uid), db);
  await deleteQueryDocuments(db.collection('messageRequests').where('receiverId', '==', uid), db);
}

async function collectRelationshipIds(userRef) {
  const result = new Set();
  for (const name of ['following', 'followers', 'follow_requests', 'blocked_accounts', 'blocked_by', 'blocked_users']) {
    const snapshot = await userRef.collection(name).get();
    for (const doc of snapshot.docs) {
      result.add(doc.id);
      const data = doc.data();
      for (const key of ['uid', 'targetId', 'blockerId']) {
        if (validId(data?.[key])) result.add(data[key]);
      }
    }
  }
  return result;
}

async function deleteRelationshipMirrors(db, uid, relatedIds) {
  const paths = new Set();
  for (const other of relatedIds) {
    if (!validId(other) || other === uid) continue;
    for (const name of ['following', 'followers', 'follow_requests', 'blocked_accounts', 'blocked_by', 'blocked_users']) {
      paths.add('users/' + other + '/' + name + '/' + uid);
    }
  }
  let batch = db.batch();
  let count = 0;
  for (const path of paths) {
    batch.delete(db.doc(path));
    count++;
    if (count === 400) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }
  if (count) await batch.commit();
}

async function detachPushDevices({ db, FieldValue, Timestamp, uid, userRef, nowMs }) {
  const tokens = await userRef.collection('fcm_tokens').get();
  for (const tokenDoc of tokens.docs) {
    const bindingRef = db.doc('pushTokenOwners/' + tokenDoc.id);
    await db.runTransaction(async tx => {
      const binding = await tx.get(bindingRef);
      if (binding.data()?.ownerId === uid) {
        tx.set(bindingRef, {
          ownerId: null,
          sessionId: FieldValue.delete(),
          sessionCreatedAt: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      tx.set(bindingRef.collection('revocations').doc(uid), {
        retainedFor: 'account-deletion-security',
        expiresAt: Timestamp.fromMillis(nowMs + SECURITY_RETENTION_DAYS * DAY_MS),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  }
}

async function scrubNotifications({ db, FieldValue, uid }) {
  for (const base of [
    db.collectionGroup('notifications').where('actorIds', 'array-contains', uid),
    db.collectionGroup('notifications').where('actorId', '==', uid),
  ]) {
    while (true) {
      const snapshot = await base.limit(PAGE_SIZE).get();
      if (snapshot.empty) break;
      const batch = db.batch();
      let mutations = 0;
      for (const doc of snapshot.docs) {
        const result = scrubNotification(doc.data(), uid);
        if (!result.changed) continue;
        if (result.deleteDocument) batch.delete(doc.ref);
        else batch.update(doc.ref, result.patch, { lastUpdateTime: doc.updateTime });
        mutations++;
      }
      if (!mutations) break;
      await batch.commit();
      if (snapshot.size < PAGE_SIZE) break;
    }
  }
}

async function scrubReports({ db, Timestamp, uid, tombstoneId, nowMs }) {
  for (const base of [
    db.collection('community_reports').where('reporterId', '==', uid),
    db.collection('community_reports').where('ownerId', '==', uid),
    db.collection('community_reports').where('reviewedBy', '==', uid),
  ]) {
    while (true) {
      const snapshot = await base.limit(PAGE_SIZE).get();
      if (snapshot.empty) break;
      let changed = 0;
      for (const doc of snapshot.docs) {
        const didChange = await db.runTransaction(async tx => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return false;
          const result = scrubReport(fresh.data(), uid, tombstoneId, Timestamp, nowMs);
          if (!result.changed) return false;
          tx.update(doc.ref, result.patch);
          return true;
        });
        if (didChange) changed++;
      }
      if (!changed || snapshot.size < PAGE_SIZE) break;
    }
  }
}

async function scrubChatMessages({ db, bucket, FieldValue, chatRef, uid, tombstoneId }) {
  let cursor = null;
  while (true) {
    let query = chatRef.collection('messages').orderBy(FieldPath.documentId()).limit(PAGE_SIZE);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) return;

    const batch = db.batch();
    const objects = [];
    let mutations = 0;
    for (const doc of snapshot.docs) {
      const result = scrubChatMessage(doc.data(), uid, tombstoneId);
      if (!result.changed) continue;
      const update = { ...result.patch };
      for (const field of result.deleteFields) update[field] = FieldValue.delete();
      batch.update(doc.ref, update, { lastUpdateTime: doc.updateTime });
      for (const url of result.storageUrls) {
        const objectPath = storageObjectFromUrl(url, bucket.name);
        if (objectPath && objectPath.startsWith('chats/' + chatRef.id + '/')) objects.push(objectPath);
      }
      mutations++;
    }
    if (mutations) await batch.commit();
    for (const objectPath of objects) await deleteExactStorageObject(bucket, objectPath);

    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < PAGE_SIZE) return;
  }
}

async function scrubChats({ db, bucket, FieldValue, uid, tombstoneId }) {
  while (true) {
    const snapshot = await db.collection('chats').where('memberIds', 'array-contains', uid).limit(25).get();
    if (snapshot.empty) return;
    for (const chat of snapshot.docs) {
      await scrubChatMessages({ db, bucket, FieldValue, chatRef: chat.ref, uid, tombstoneId });
      await deleteExactStorageObject(bucket, 'chats/' + chat.id + '/wallpaper/' + uid + '.jpg');
      await db.runTransaction(async tx => {
        const fresh = await tx.get(chat.ref);
        if (!fresh.exists) return;
        const result = scrubChatDocument(fresh.data(), uid, tombstoneId);
        if (!result.changed) return;
        const patch = { ...result.patch };
        for (const field of result.deleteFields) patch[field] = FieldValue.delete();
        tx.set(chat.ref, patch, { merge: true });
      });
    }
  }
}

async function deleteOwnedPosts({ db, bucket, uid }) {
  while (true) {
    const snapshot = await db.collection('community_posts').where('authorId', '==', uid).limit(40).get();
    if (snapshot.empty) return;
    for (const doc of snapshot.docs) {
      await deleteFilesWithPrefix(bucket, 'community_posts/' + doc.id + '/');
      await db.recursiveDelete(doc.ref);
      const batch = db.batch();
      for (const name of ['postPublicationReceipts', 'repostPublicationReceipts', 'postDeletionReceipts']) {
        batch.delete(db.doc(name + '/' + doc.id));
      }
      await batch.commit();
    }
  }
}

async function scrubRemainingPosts({ db, bucket, uid }) {
  let cursor = null;
  while (true) {
    let query = db.collection('community_posts').orderBy(FieldPath.documentId()).limit(60);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) return;

    const batch = db.batch();
    const prefixes = [];
    let mutations = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const transformed = scrubCommentsForDeletedUser(data.comments, uid);
      const up = without(data.upvotedBy, uid);
      const down = without(data.downvotedBy, uid);
      const patch = {};
      if (transformed.changed) patch.comments = transformed.comments;
      if (up.length !== list(data.upvotedBy).length) patch.upvotedBy = up;
      if (down.length !== list(data.downvotedBy).length) patch.downvotedBy = down;
      if (Object.keys(patch).length) {
        patch.commentsCount = transformed.comments.filter(comment => isObject(comment) && !comment.replyToId).length;
        batch.update(doc.ref, patch, { lastUpdateTime: doc.updateTime });
        mutations++;
      }
      batch.delete(doc.ref.collection('poll_responses').doc(uid));
      mutations++;
      for (const commentId of transformed.deletedCommentIds) {
        prefixes.push('community_posts/' + doc.id + '/comments/' + uid + '/' + commentId + '/');
      }
    }
    if (mutations) await batch.commit();
    for (const prefix of prefixes) await deleteFilesWithPrefix(bucket, prefix);

    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < 60) return;
  }
}

async function deleteKnownEphemeralDocs(db, uid) {
  const names = [
    'communityReportLimits',
    'communityReportStatusLimits',
    'usernameCheckLimits',
    'contentSearchLimits',
    'contentFeedLimits',
    'contentReactionLimits',
    'profilePostLimits',
    'profileCommentLimits',
  ];
  const batch = db.batch();
  for (const name of names) batch.delete(db.doc(name + '/' + uid));
  await batch.commit();
}

async function purgeAccount({ auth, db, bucket, FieldValue, Timestamp, uid, tombstoneId, nowMs }) {
  const userRef = db.doc('users/' + uid);
  const relatedIds = await collectRelationshipIds(userRef);

  await deleteMessageRequests(db, uid);
  await scrubChats({ db, bucket, FieldValue, uid, tombstoneId });
  await deleteOwnedPosts({ db, bucket, uid });
  await scrubRemainingPosts({ db, bucket, uid });
  await scrubNotifications({ db, FieldValue, uid });
  await scrubReports({ db, Timestamp, uid, tombstoneId, nowMs });
  await deleteRelationshipMirrors(db, uid, relatedIds);
  await detachPushDevices({ db, FieldValue, Timestamp, uid, userRef, nowMs });
  await deleteUsernameReservations(db, uid);
  await deleteReceiptRows(db, uid);
  await deleteKnownEphemeralDocs(db, uid);
  await deleteFilesWithPrefix(bucket, 'users/' + uid + '/');

  await db.recursiveDelete(userRef);
  await db.doc('authRevocations/' + uid).set({
    expiresAt: Timestamp.fromMillis(nowMs + SECURITY_RETENTION_DAYS * DAY_MS),
    retainedFor: 'account-deletion-security',
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') throw error;
  }
}

async function deleteExpired(query, db) {
  while (true) {
    const snapshot = await query.limit(PAGE_SIZE).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
    if (snapshot.size < PAGE_SIZE) return;
  }
}

async function cleanupExpiredReports({ db, Timestamp, nowMs }) {
  const cutoff = Timestamp.fromMillis(nowMs);
  let cursor = null;
  while (true) {
    let query = db.collection('community_reports')
      .where('retentionDeleteAt', '<=', cutoff)
      .orderBy('retentionDeleteAt')
      .limit(PAGE_SIZE);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) return;

    const batch = db.batch();
    let deletions = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const holdUntil = typeof data.legalHoldUntil?.toMillis === 'function'
        ? data.legalHoldUntil.toMillis() : 0;
      if (data.legalHold === true || holdUntil > nowMs) continue;
      batch.delete(doc.ref);
      deletions++;
    }
    if (deletions) await batch.commit();
    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < PAGE_SIZE) return;
  }
}

async function cleanupRetention({ db, Timestamp, nowMs }) {
  const cutoff = Timestamp.fromMillis(nowMs);
  await cleanupExpiredReports({ db, Timestamp, nowMs });
  await deleteExpired(db.collection('authRevocations').where('expiresAt', '<=', cutoff), db);
  await deleteExpired(db.collection('account_deletion_requests').where('auditDeleteAt', '<=', cutoff), db);
  await deleteExpired(db.collectionGroup('revocations').where('expiresAt', '<=', cutoff), db);
}

function errorCode(error) {
  if (typeof error?.code === 'string' && error.code.length <= 120) return error.code;
  if (typeof error?.name === 'string' && error.name.length <= 120) return error.name;
  return 'account-deletion-worker-failed';
}

function createAccountDeletionWorker({
  auth,
  db,
  bucket,
  FieldValue,
  Timestamp,
  now = () => Date.now(),
  randomId = () => randomUUID().replace(/-/g, ''),
}) {
  async function claim() {
    const nowMs = now();
    const pending = await db.collection('account_deletion_requests').where('status', '==', 'pending').limit(8).get();
    let candidates = pending.docs;
    if (!candidates.length) {
      const processing = await db.collection('account_deletion_requests').where('status', '==', 'processing').limit(20).get();
      candidates = processing.docs.filter(doc => {
        const lease = doc.data().leaseUntil;
        return typeof lease?.toMillis !== 'function' || lease.toMillis() <= nowMs;
      });
    }

    for (const candidate of candidates) {
      const workerToken = randomId();
      const tombstoneId = 'deleted_' + randomId().slice(0, 40);
      const claimed = await db.runTransaction(async tx => {
        const fresh = await tx.get(candidate.ref);
        if (!fresh.exists) return null;
        const data = fresh.data();
        const leaseMs = typeof data.leaseUntil?.toMillis === 'function' ? data.leaseUntil.toMillis() : 0;
        const eligible = data.status === 'pending' || (data.status === 'processing' && leaseMs <= nowMs);
        if (!eligible) return null;
        const existingTombstone = typeof data.tombstoneId === 'string' && data.tombstoneId.startsWith('deleted_')
          ? data.tombstoneId : tombstoneId;
        tx.set(candidate.ref, {
          status: 'processing',
          workerToken,
          tombstoneId: existingTombstone,
          leaseUntil: Timestamp.fromMillis(nowMs + LEASE_MINUTES * 60 * 1000),
          processingStartedAt: data.processingStartedAt || FieldValue.serverTimestamp(),
          lastAttemptAt: FieldValue.serverTimestamp(),
          attempts: FieldValue.increment(1),
          lastError: FieldValue.delete(),
        }, { merge: true });
        return { ref: candidate.ref, uid: candidate.id, workerToken, tombstoneId: existingTombstone };
      });
      if (claimed) return claimed;
    }
    return null;
  }

  async function finish(claimed, nowMs) {
    await db.runTransaction(async tx => {
      const fresh = await tx.get(claimed.ref);
      if (!fresh.exists || fresh.data().workerToken !== claimed.workerToken) return;
      tx.set(claimed.ref, {
        status: 'completed',
        completedAt: FieldValue.serverTimestamp(),
        ordinaryDataDeletedAt: FieldValue.serverTimestamp(),
        auditDeleteAt: Timestamp.fromMillis(nowMs + REQUEST_AUDIT_DAYS * DAY_MS),
        leaseUntil: FieldValue.delete(),
        workerToken: FieldValue.delete(),
        lastError: FieldValue.delete(),
      }, { merge: true });
    });
  }

  async function fail(claimed, error) {
    await db.runTransaction(async tx => {
      const fresh = await tx.get(claimed.ref);
      if (!fresh.exists || fresh.data().workerToken !== claimed.workerToken) return;
      tx.set(claimed.ref, {
        status: 'pending',
        leaseUntil: FieldValue.delete(),
        workerToken: FieldValue.delete(),
        lastError: errorCode(error),
        lastAttemptAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  }

  return async () => {
    const nowMs = now();
    await cleanupRetention({ db, Timestamp, nowMs });
    const claimed = await claim();
    if (!claimed) return { processed: false };

    try {
      await purgeAccount({
        auth,
        db,
        bucket: typeof bucket === 'function' ? bucket() : bucket,
        FieldValue,
        Timestamp,
        uid: claimed.uid,
        tombstoneId: claimed.tombstoneId,
        nowMs,
      });
      await finish(claimed, nowMs);
      return { processed: true, status: 'completed' };
    } catch (error) {
      await fail(claimed, error);
      throw error;
    }
  };
}

module.exports = {
  SECURITY_RETENTION_DAYS,
  MODERATION_RETENTION_DAYS,
  REQUEST_AUDIT_DAYS,
  scrubCommentsForDeletedUser,
  scrubChatMessage,
  scrubChatDocument,
  scrubNotification,
  scrubReport,
  storageObjectFromUrl,
  createAccountDeletionWorker,
};
