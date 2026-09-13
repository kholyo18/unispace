const { Timestamp, FieldPath } = require('firebase-admin/firestore');
const { HttpsError } = require('firebase-functions/v2/https');
const { createPublicProfileHandler } = require('./public-profile');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const list = v => Array.isArray(v) ? v : [];
const strings = v => list(v).filter(x => typeof x === 'string');
const pick = (data, keys) => Object.fromEntries(keys.filter(k => data[k] != null &&
  ['string', 'number', 'boolean'].includes(typeof data[k])).map(k => [k, data[k]]));
const date = v => typeof v?.toDate === 'function' ? v.toDate().toISOString() : typeof v === 'string' ? v : null;
function removed(data) {
  if (!data || ['removed', 'uploading', 'failed'].includes(String(data.status || '').toLowerCase()) || data.moderation?.status === 'removed') return true;
  if (data.moderation?.status === 'cleared') return false;
  const count = Number(data.reportCount) || 0, score = Number(data.reportScore) || 0;
  const views = Number(data.uniqueViewers ?? data.viewsCount) || 0;
  if (count < 3) return false;
  if (views <= 0) return score >= 8;
  const ratio = count / views;
  if (views > 5000 && ratio < 0.03) return score >= 8 && ratio >= 0.004;
  return ratio >= 0.03 || (score >= 8 && ratio >= 0.004);
}
function poll(p) {
  const result = pick(p, ['question', 'type', 'scaleStyle', 'scaleSize', 'isRequired', 'includeTime',
    'scaleMinLabel', 'scaleMaxLabel', 'multiSelect']);
  for (const k of ['options', 'gridRows', 'gridColumns']) result[k] = strings(p[k]);
  if (p.dateConfig && typeof p.dateConfig === 'object') result.dateConfig = {
    ...pick(p.dateConfig, ['year', 'includeTime', 'multiSelect', 'rangeStart', 'rangeEnd', 'rangesText']),
    months: list(p.dateConfig.months).filter(Number.isInteger), allowedDays: strings(p.dateConfig.allowedDays),
  };
  if (p.selectedTime && typeof p.selectedTime === 'object') result.selectedTime = pick(p.selectedTime, ['hour', 'minute']);
  return result;
}

function createContentSearchPageHandler({ auth, db, now = Date.now }, singlePost = false, feed = false) {
  const readProfile = createPublicProfileHandler({ auth, db });
  return async request => {
    const input = request.data;
    const reactions = feed === 'reactions';
    const profilePosts = feed === 'profile';
    const authorComments = feed === 'comments';
    if (authorComments && (!input || typeof input !== 'object' || Array.isArray(input) ||
        Object.keys(input).length !== 1 || !validId(input.userId))) {
      throw new HttpsError('invalid-argument', 'A userId is required.');
    }
    if (singlePost && (!input || typeof input !== 'object' || Array.isArray(input) ||
        Object.keys(input).length !== 1 || !validId(input.postId))) {
      throw new HttpsError('invalid-argument', 'A postId is required.');
    }
    if (!singlePost && !feed && (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !Number.isInteger(input.page) || input.page < 0 || input.page > 5 ||
        !(input.token === null || (typeof input.token === 'string' && input.token.length > 0 && input.token.length <= 160)) ||
        (input.page === 0 && input.token === null))) throw new HttpsError('invalid-argument', 'Invalid search page.');
    if (feed && !authorComments) {
      const c = input?.cursor;
      if (!input || typeof input !== 'object' || Array.isArray(input) ||
          Object.keys(input).length !== ((reactions || profilePosts) ? 2 : 1) || !Object.hasOwn(input, 'cursor') ||
          (reactions && !['like', 'dislike'].includes(input.reaction)) ||
          (profilePosts && !validId(input.userId)) ||
          (c !== null && (!c || typeof c !== 'object' || Array.isArray(c) ||
            Object.keys(c).length !== 3 || !validId(c.id) ||
            !Number.isInteger(c.seconds) || c.seconds < -62135596800 || c.seconds > 253402300799 ||
            !Number.isInteger(c.nanoseconds) || c.nanoseconds < 0 || c.nanoseconds > 999999999))) {
        throw new HttpsError('invalid-argument', 'Invalid feed cursor.');
      }
    }
    const uid = request.auth?.uid;
    // Reuse the existing verified bearer / revocation / availability boundary.
    await readProfile({ ...request, data: { userId: uid } });
    await db.runTransaction(async tx => {
      const ref = db.doc(`${profilePosts ? 'profilePostLimits' : authorComments ? 'profileCommentLimits' : reactions ? 'contentReactionLimits' : feed ? 'contentFeedLimits' : 'contentSearchLimits'}/${uid}`), snap = await tx.get(ref);
      const previous = snap.data(), timestamp = now();
      const active = previous && timestamp < previous.windowStart + 60000;
      const count = active ? previous.count : 0;
      if (count >= 60) throw new HttpsError('resource-exhausted', 'Wait before searching again.');
      tx.set(ref, { windowStart: active ? previous.windowStart : timestamp, count: count + 1 });
    });
    const profiles = new Map();
    function profile(id) {
      if (!validId(id)) return Promise.resolve(null);
      if (!profiles.has(id)) profiles.set(id, readProfile({ ...request, data: { userId: id } }).catch(error => {
        if (error.code === 'not-found' || error.code === 'permission-denied') return null;
        throw error;
      }));
      return profiles.get(id);
    }
    const voteState = data => ({ upvotedBy: list(data.upvotedBy).includes(uid) ? [uid] : [],
      downvotedBy: list(data.downvotedBy).includes(uid) ? [uid] : [] });
    async function comments(raw, depth = 0, hidden = new Set()) {
      if (depth > 30) throw new HttpsError('resource-exhausted', 'Comment nesting limit exceeded.');
      const result = [];
      for (const c of list(raw)) {
        if (!c || typeof c !== 'object' || hidden.has(c.id) || removed(c) || !await profile(c.authorId)) continue;
        result.push({ ...pick(c, ['id', 'author', 'authorId', 'authorPhotoUrl', 'text', 'replyToId',
          'replyToAuthor', 'votes', 'mediaUrl', 'mediaType', 'isEdited']), ...voteState(c),
          createdAt: date(c.createdAt), replies: await comments(c.replies, depth + 1, hidden) });
      }
      return result;
    }
    const originals = new Map();
    async function project(id, data, chain = new Set()) {
      if (removed(data) || chain.has(id) || chain.size >= 8) return null;
      const owner = await profile(data.authorId);
      if (owner?.canViewContent !== true) return null;
      const next = new Set(chain); next.add(id);
      const who = owner.privacy.whoCanComment;
      const mutual = who === 'mutual' && owner.isFollowing &&
        (await db.doc('users/' + uid + '/followers/' + data.authorId).get()).exists;
      const canComment = uid === data.authorId || who === 'everyone' ||
        (who === 'followers' && owner.isFollowing) || mutual;
      const result = { ...pick(data, ['authorName', 'author', 'authorId', 'authorPhotoUrl', 'isEdited',
        'title', 'body', 'mediaUrl', 'votes', 'commentsCount', 'isRepost']),
        ...voteState(data), createdAt: date(data.createdAt), canComment: !!canComment,
        authorPrivate: owner.privacy.privateAccount === true,
        authorHideLikeCounts: data.authorHideLikeCounts === true,
        imageUrls: strings(data.imageUrls ?? data.imagePaths), videoUrls: strings(data.videoUrls ?? data.videoPaths),
        tags: strings(data.tags), polls: list(data.polls).filter(p => p && typeof p === 'object').map(poll),
        pollSlides: list(data.pollSlides).filter(p => p && typeof p === 'object')
          .map(p => pick(p, ['type', 'text', 'pollIndex', 'url', 'mediaPath', 'path'])),
        comments: await comments(data.comments, 0, new Set(strings(data.moderation?.hiddenCommentIds))) };
      if (data.isRepost === true || data.repostOf != null) {
        const quote = data.repostOf, originalId = quote?.postId;
        if (!validId(originalId)) return null;
        if (!originals.has(originalId)) originals.set(originalId, db.doc(`community_posts/${originalId}`).get());
        const snapshot = await originals.get(originalId);
        if (!snapshot.exists) return null;
        const original = await project(originalId, snapshot.data(), next);
        if (!original) return null;
        result.repostOf = { ...original, postId: originalId, imageUrl: original.imageUrls[0] || '' };
        delete result.repostOf.comments;
        if (quote.kind === 'comment') {
          if (!validId(quote.commentId)) return null;
          function find(rows) {
            for (const c of rows) { if (c.id === quote.commentId) return c; const hit = find(c.replies); if (hit) return hit; }
            return null;
          }
          const c = find(original.comments);
          if (!c) return null;
          Object.assign(result.repostOf, { kind: 'comment', commentId: c.id, commentAuthor: c.author || '',
            commentAuthorId: c.authorId, commentAuthorPhotoUrl: c.authorPhotoUrl || '', commentText: c.text || '',
            commentMediaUrl: c.mediaUrl || '', commentMediaType: c.mediaType || '' });
        }
      }
      return result;
    }
    if (authorComments) {
      const target = await profile(input.userId);
      if (target?.canViewContent !== true) throw new HttpsError('not-found', 'Comments unavailable.');
      const index = await db.collection('users').doc(input.userId).collection('authored_comments')
        .orderBy('createdAt', 'desc').limit(80).get();
      const posts = [];
      let count = 0, bytes = 0;
      async function collect(doc, selected = null) {
        if (!doc.exists || count >= 80) return;
        const data = await project(doc.id, doc.data());
        if (!data) return;
        const commentIds = [];
        function walk(rows) {
          for (const c of rows) {
            if (count >= 80) return;
            if (c.authorId === input.userId && (!selected || selected.has(c.id))) {
              commentIds.push(c.id); count++;
            }
            walk(c.replies);
          }
        }
        walk(data.comments);
        if (!commentIds.length) return;
        const row = { id: doc.id, data, commentIds };
        bytes += Buffer.byteLength(JSON.stringify(row));
        if (bytes > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Comments page is too large.');
        posts.push(row);
      }
      if (!index.empty) {
        const byPost = new Map();
        for (const row of index.docs) {
          const data = row.data(), id = data.postId, cid = data.commentId || row.id;
          if (!validId(id) || !validId(cid)) continue;
          if (!byPost.has(id)) byPost.set(id, new Set());
          byPost.get(id).add(cid);
        }
        for (const [id, selected] of byPost) {
          await collect(await db.doc('community_posts/' + id).get(), selected);
        }
      } else {
        // Preserve the bounded legacy lookup only when the index is empty.
        let last;
        for (let page = 0; page < 8 && count < 80; page++) {
          let query = db.collection('community_posts').orderBy('createdAt', 'desc').limit(80);
          if (last) query = query.startAfter(last);
          const snapshot = await query.get();
          for (const doc of snapshot.docs) await collect(doc);
          if (snapshot.size < 80) break;
          last = snapshot.docs[snapshot.docs.length - 1];
        }
      }
      await readProfile({ ...request, data: { userId: uid } });
      const freshTarget = await readProfile({ ...request, data: { userId: input.userId } });
      if (freshTarget.canViewContent !== true) throw new HttpsError('not-found', 'Comments unavailable.');
      return { posts };
    }
    if (singlePost) {
      const snapshot = await db.doc('community_posts/' + input.postId).get();
      const data = snapshot.exists ? await project(snapshot.id, snapshot.data()) : null;
      if (!data) throw new HttpsError('not-found', 'Post unavailable.');
      if (Buffer.byteLength(JSON.stringify(data)) > 6 * 1024 * 1024) {
        throw new HttpsError('resource-exhausted', 'Post is too large.');
      }
      await readProfile({ ...request, data: { userId: uid } });
      return { id: snapshot.id, data };
    }
    if (feed) {
      if (profilePosts) {
        const target = await profile(input.userId);
        if (target?.canViewContent !== true) throw new HttpsError('not-found', 'Profile posts unavailable.');
      }
      let query = db.collection('community_posts');
      if (profilePosts) query = query.where('authorId', '==', input.userId);
      if (reactions) query = query.where(input.reaction === 'like' ? 'upvotedBy' : 'downvotedBy', 'array-contains', uid);
      query = query.orderBy('createdAt', 'desc')
        .orderBy(FieldPath.documentId(), 'desc');
      if (input.cursor) query = query.startAfter(
        new Timestamp(input.cursor.seconds, input.cursor.nanoseconds), input.cursor.id);
      const snapshot = await query.limit(25).get();
      const posts = [];
      let bytes = 0;
      for (const doc of snapshot.docs) {
        const data = await project(doc.id, doc.data());
        if (!data) continue;
        bytes += Buffer.byteLength(JSON.stringify(data));
        if (bytes > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Feed page is too large.');
        posts.push({ id: doc.id, data });
      }
      if (profilePosts && input.cursor === null) {
        const target = await db.doc('users/' + input.userId).get();
        const pinnedId = target.data()?.pinnedPostId;
        if (validId(pinnedId) && !posts.some(p => p.id === pinnedId)) {
          const pinned = await db.doc('community_posts/' + pinnedId).get();
          if (pinned.exists && pinned.data().authorId === input.userId) {
            const data = await project(pinned.id, pinned.data());
            if (data) {
              bytes += Buffer.byteLength(JSON.stringify(data));
              if (bytes > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Profile page is too large.');
              posts.push({ id: pinned.id, data });
            }
          }
        }
      }
      const last = snapshot.docs[snapshot.docs.length - 1];
      const createdAt = last?.data().createdAt;
      if (last && !(createdAt instanceof Timestamp)) {
        throw new HttpsError('failed-precondition', 'Invalid post timestamp.');
      }
      await readProfile({ ...request, data: { userId: uid } });
      return { posts, exhausted: snapshot.size < 25, cursor: last ? {
        id: last.id, seconds: createdAt.seconds, nanoseconds: createdAt.nanoseconds,
      } : null };
    }
    let query = db.collection('community_posts');
    query = input.page === 0 ? query.where('searchKeywords', 'array-contains', input.token).limit(60) :
      query.orderBy('createdAt', 'desc').offset((input.page - 1) * 80).limit(80);
    const snapshot = await query.get();
    const posts = [];
    let bytes = 0;
    for (const doc of snapshot.docs) {
      const data = await project(doc.id, doc.data());
      if (data) {
        bytes += Buffer.byteLength(JSON.stringify(data));
        if (bytes > 6 * 1024 * 1024) throw new HttpsError('resource-exhausted', 'Search page is too large.');
        posts.push({ id: doc.id, data });
      }
    }
    await readProfile({ ...request, data: { userId: uid } });
    return { posts, exhausted: snapshot.size < (input.page === 0 ? 60 : 80) };
  };
}
module.exports = { createContentSearchPageHandler, removed };
