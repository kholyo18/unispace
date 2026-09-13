const { HttpsError } = require('firebase-functions/v2/https');
const invalid = () => { throw new HttpsError('invalid-argument', 'Invalid post content.'); };
const object = v => v && typeof v === 'object' && !Array.isArray(v);
const keys = (v, allowed) => object(v) && Object.keys(v).every(k => allowed.includes(k));
const string = (v, max) => typeof v === 'string' && v.length <= max;
const strings = (v, count, max) => Array.isArray(v) && v.length <= count && v.every(s => string(s, max));
const validId = v => string(v, 128) && v.length > 0 && !v.includes('/') && !['.', '..'].includes(v);
const pollKeys = ['question','type','options','gridRows','gridColumns','scaleStyle','scaleSize','isRequired',
  'includeTime','scaleMinLabel','scaleMaxLabel','multiSelect','dateConfig','selectedTime'];

function validateContent(c) {
  const fields = ['title','body','tags','imageUrls','videoUrls','polls','pollSlides'];
  if (!keys(c, fields) || Object.keys(c).length !== fields.length ||
      !string(c.title, 10000) || !string(c.body, 100000) || !strings(c.tags, 100, 200) ||
      !strings(c.imageUrls, 100, 4096) || !strings(c.videoUrls, 100, 4096) ||
      !Array.isArray(c.polls) || c.polls.length > 100 || !Array.isArray(c.pollSlides) || c.pollSlides.length > 300 ||
      Buffer.byteLength(JSON.stringify(c), 'utf8') > 500000) invalid();
  for (const p of c.polls) {
    if (!keys(p, pollKeys) || !string(p.question, 10000) ||
        !['shortText','longText','checkbox','linearScale','dropdown','singelOptin','grid','checkboxGrid','date','time'].includes(p.type) ||
        !strings(p.options, 500, 2000) || !strings(p.gridRows, 500, 2000) || !strings(p.gridColumns, 500, 2000) ||
        !['isRequired','includeTime','multiSelect'].every(k => typeof p[k] === 'boolean') ||
        !['scaleMinLabel','scaleMaxLabel'].every(k => p[k] == null || string(p[k], 2000)) ||
        !(p.scaleStyle == null || ['numbers','line','emoji','emoji1','stars','slider'].includes(p.scaleStyle)) ||
        !(p.scaleSize == null || (Number.isInteger(p.scaleSize) && p.scaleSize >= 0 && p.scaleSize <= 1000))) invalid();
    if (p.dateConfig != null) {
      const d = p.dateConfig;
      if (!keys(d, ['year','months','includeTime','allowedDays','rangeStart','rangeEnd','rangesText']) ||
          !Number.isInteger(d.year) || !Array.isArray(d.months) || d.months.length > 12 ||
          !d.months.every(m => Number.isInteger(m) && m >= 1 && m <= 12) ||
          typeof d.includeTime !== 'boolean' || !strings(d.allowedDays, 3660, 100) ||
          !['rangeStart','rangeEnd','rangesText'].every(k => d[k] == null || string(d[k], 10000))) invalid();
    }
    if (p.selectedTime != null && (!keys(p.selectedTime, ['hour','minute']) ||
        !Number.isInteger(p.selectedTime.hour) || p.selectedTime.hour < 0 || p.selectedTime.hour > 23 ||
        !Number.isInteger(p.selectedTime.minute) || p.selectedTime.minute < 0 || p.selectedTime.minute > 59)) invalid();
  }
  for (const s of c.pollSlides) {
    if (!object(s)) invalid();
    if (s.type === 'text') {
      if (!keys(s, ['type','text']) || !string(s.text, 100000)) invalid();
    } else if (s.type === 'poll') {
      if (!keys(s, ['type','pollIndex']) || !Number.isInteger(s.pollIndex) || s.pollIndex < 0 || s.pollIndex >= c.polls.length) invalid();
    } else if (['image','video'].includes(s.type)) {
      if (!keys(s, ['type','url']) || !string(s.url, 4096)) invalid();
    } else invalid();
  }
}

function mediaUrls(c) {
  const rows = v => Array.isArray(v) ? v : [];
  return [...rows(c.imageUrls), ...rows(c.videoUrls),
    ...rows(c.pollSlides).filter(s => ['image','video'].includes(s?.type)).map(s => s.url)]
    .filter(v => typeof v === 'string');
}

function searchKeywords(c, author) {
  const words = [...c.title.split(/\s+/), ...c.body.split(/\s+/), ...c.tags, ...String(author || '').split(/\s+/)];
  const out = new Set();
  for (const word of words) {
    const normalized = word.toLowerCase().replace(/[\u064B-\u065F\u0670]/g, '')
      .replace(/[أإآٱ]/g,'ا').replace(/[ىئ]/g,'ي').replace(/ؤ/g,'و').replace(/ة/g,'ه')
      .replace(/[^\w\u0600-\u06FF]+/g,' ').replace(/\s+/g,' ').trim();
    if (normalized.length >= 2) out.add(normalized);
    if (out.size >= 40) break;
  }
  return [...out];
}

function createEditPostHandler({ auth, db, FieldValue, bucket }) {
  return async request => {
    const uid = request.auth?.uid, header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated','Sign in first.');
    const i = request.data;
    if (!keys(i, ['postId','content']) || Object.keys(i).length !== 2 || !validId(i.postId)) invalid();
    validateContent(i.content);
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated','Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated','Invalid session.');
    const ref = db.doc(`community_posts/${i.postId}`);
    const initial = await ref.get();
    if (!initial.exists || initial.data().authorId !== uid) throw new HttpsError('not-found','Post unavailable.');
    const retained = new Set(mediaUrls(initial.data())), verified = new Set();
    // Existing URLs remain usable. Newly attached objects must belong to this post's media prefix.
    for (const value of new Set(mediaUrls(i.content))) {
      if (retained.has(value)) continue;
      const storage = bucket();
      let url, objectPath;
      try {
        url = new URL(value);
        const prefix = `/v0/b/${storage.name}/o/`;
        if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com' || url.port ||
            url.username || url.password || !url.pathname.startsWith(prefix) || url.searchParams.get('alt') !== 'media') invalid();
        objectPath = decodeURIComponent(url.pathname.slice(prefix.length));
        const base = `community_posts/${i.postId}/`;
        if (!objectPath.startsWith(base) || !/^(images|videos)\/[^/]+$/.test(objectPath.slice(base.length))) invalid();
      } catch (_) { invalid(); }
      let metadata;
      try { [metadata] = await storage.file(objectPath).getMetadata(); }
      catch (_) { throw new HttpsError('failed-precondition','Uploaded media is unavailable.'); }
      if (Number(metadata.size) <= 0 || !String(metadata.metadata?.firebaseStorageDownloadTokens || '').split(',').includes(url.searchParams.get('token'))) invalid();
      verified.add(value);
    }
    return db.runTransaction(async tx => {
      const [post, receipt, cutoff, actor] = await tx.getAll(ref, db.doc(`postDeletionReceipts/${i.postId}`),
        db.doc(`authRevocations/${uid}`), db.doc(`users/${uid}`));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated','Session revoked.');
      if (!post.exists || post.data().authorId !== uid || receipt.exists) throw new HttpsError('not-found','Post unavailable.');
      if (!actor.exists || ['disabled','deleted'].includes(actor.data().accountStatus) || actor.data().security?.frozen === true) {
        throw new HttpsError('permission-denied','Editing unavailable.');
      }
      const currentMedia = new Set(mediaUrls(post.data()));
      if (mediaUrls(i.content).some(url => !currentMedia.has(url) && !verified.has(url))) {
        throw new HttpsError('aborted','Post media changed. Reopen the editor.');
      }
      // Field-level update deliberately preserves ownership, quotes, votes, comments and moderation.
      tx.update(ref, {...i.content, searchKeywords: searchKeywords(i.content, post.data().author),
        isEdited: true, editedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp()});
      return {postId: i.postId, edited: true};
    });
  };
}
module.exports = { createEditPostHandler, validateContent, mediaUrls, searchKeywords };
