const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler } = require('./content-search-page');
function createMediaDownloadHandler({auth, db, bucket}, batch = false, comment = false, {verifyOnly = false} = {}) {
  if (verifyOnly && (!comment || batch)) throw new Error('Access-only mode requires a single comment.');
  const readPost = createContentSearchPageHandler({auth, db}, true);
  return async request => {
    const i = request.data;
    if (!i || typeof i !== 'object' || Array.isArray(i) || Object.keys(i).length !== (comment ? 3 : 2) ||
        !Object.hasOwn(i, 'postId') || !Object.hasOwn(i, batch ? 'urls' : 'url')) {
      throw new HttpsError('invalid-argument', 'Invalid media request.');
    }
    if (comment && (batch || typeof i.commentId !== 'string' || !i.commentId.length ||
        i.commentId.length > 256 || i.commentId.includes('/'))) {
      throw new HttpsError('invalid-argument', 'Invalid comment.');
    }
    function visibleComment(data) {
      const byId = new Map(), duplicate = new Set();
      function walk(rows, parent = null, depth = 0) {
        if (depth > 30) throw new HttpsError('permission-denied', 'Comment unavailable.');
        for (const row of Array.isArray(rows) ? rows : []) {
          if (!row || typeof row.id !== 'string') continue;
          if (byId.has(row.id)) duplicate.add(row.id);
          byId.set(row.id, {row, parent});
          walk(row.replies, row.id, depth + 1);
        }
      }
      walk(data?.comments);
      const target = byId.get(i.commentId), seen = new Set();
      let visits = 0;
      function available(id) {
        if (++visits > 60 || seen.has(id) || duplicate.has(id)) return false;
        const node = byId.get(id);
        if (!node) return false;
        seen.add(id);
        const parents = new Set([node.parent, node.row.replyToId].filter(Boolean));
        for (const parent of parents) {
          if (typeof parent !== 'string' || !available(parent)) return false;
        }
        seen.delete(id);
        return true;
      }
      return target && available(i.commentId) ? target.row : null;
    }
    const urls = batch ? i.urls : [i.url];
    if (!Array.isArray(urls) || urls.length < 1 || urls.length > 10 ||
        urls.some(url => typeof url !== 'string' || !url.length || url.length > 4096) ||
        new Set(urls).size !== urls.length) throw new HttpsError('invalid-argument', 'Invalid media URLs.');
    const visible = await readPost({...request, data:{postId:i.postId}});
    function ownsUrl(data, wanted, depth = 0) {
      if (comment) {
        const row = visibleComment(data);
        return !!row && ['image','video','gif'].includes(row.mediaType) && row.mediaUrl === wanted;
      }
      if (!data || depth > 8) return false;
      if ([...(data.imageUrls || []), ...(data.videoUrls || [])].includes(wanted)) return true;
      if ((data.pollSlides || []).some(s => ['image','video'].includes(s.type) && [s.url,s.path,s.mediaPath].includes(wanted))) return true;
      return ownsUrl(data.repostOf, wanted, depth + 1);
    }
    if (!urls.every(url => ownsUrl(visible.data, url))) throw new HttpsError('permission-denied', 'Media no longer belongs to this post.');
    const storage = bucket();
    const items = [];
    for (const source of urls) {
      let objectPath;
      try {
        const url = new URL(source), prefix = '/v0/b/' + storage.name + '/o/';
        if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' || url.port ||
            url.username || url.password || !url.pathname.startsWith(prefix)) throw Error();
        objectPath = decodeURIComponent(url.pathname.slice(prefix.length));
        if (!objectPath.startsWith('community_posts/')) throw Error();
        if (comment) {
          const author = visibleComment(visible.data)?.authorId;
          if (typeof author !== 'string' || !author || author.includes('/') ||
              !objectPath.startsWith('community_posts/' + i.postId + '/comments/' + author + '/' + i.commentId + '/')) throw Error();
        }
      } catch (_) { throw new HttpsError('invalid-argument', 'Unsupported media source.'); }
      // Access to already downloaded bytes: preserve membership/path validation,
      // but do not read Storage metadata or issue a new bearer URL.
      if (verifyOnly) return {authorized:true, postId:i.postId, commentId:i.commentId,
        source, mediaType:visibleComment(visible.data).mediaType};
      let metadata;
      try { [metadata] = await storage.file(objectPath).getMetadata(); }
      catch (e) { if (e.code === 404) throw new HttpsError('not-found', 'Media unavailable.'); throw new HttpsError('unavailable', 'Try again later.'); }
      if (!metadata.generation || Number(metadata.size) <= 0) throw new HttpsError('not-found', 'Media unavailable.');
      const expiresAt = Date.now() + 5 * 60 * 1000;
      // Bind delivery to the inspected immutable object generation.
      const [url] = await storage.file(objectPath).getSignedUrl({version:'v4', action:'read', expires:expiresAt,
        queryParams:{generation:String(metadata.generation)}});
      items.push({source, url, expiresAt});
    }
    // Recheck all memberships before exposing any signed URL.
    const fresh = await readPost({...request, data:{postId:i.postId}});
    if (!urls.every(url => ownsUrl(fresh.data, url))) throw new HttpsError('permission-denied', 'Media unavailable.');
    if (items.some(item => item.expiresAt <= Date.now())) throw new HttpsError('unavailable', 'Try again later.');
    if (comment) return {url:items[0].url, expiresAt:items[0].expiresAt, mediaType:visibleComment(fresh.data).mediaType};
    return batch ? {items} : {url:items[0].url, expiresAt:items[0].expiresAt};
  };
}
module.exports = { createMediaDownloadHandler };
