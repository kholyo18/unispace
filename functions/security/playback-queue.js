const {createHash, randomUUID} = require('node:crypto');
const {removed} = require('./content-search-page');
const {preparePlaybackJob, finalizePlayback} = require('./playback-worker');

function videoPaths(bucketName, postId, data) {
  const paths = new Set();
  if (!data || removed(data) || data.isRepost || data.repostOf) return paths;
  const add = (value, comment) => {
    try {
      const u = new URL(value), prefix = `/v0/b/${bucketName}/o/`;
      if (u.protocol !== 'https:' || u.hostname !== 'firebasestorage.googleapis.com' ||
          u.port || u.username || u.password || !u.pathname.startsWith(prefix)) return;
      const path = decodeURIComponent(u.pathname.slice(prefix.length));
      if (!path.startsWith(`community_posts/${postId}/`) || /[\x00-\x1f]/.test(path)) return;
      if (comment && (typeof comment.authorId !== 'string' || comment.authorId.includes('/') ||
          typeof comment.id !== 'string' || comment.id.includes('/') ||
          !path.startsWith(`community_posts/${postId}/comments/${comment.authorId}/${comment.id}/`))) return;
      paths.add(path);
    } catch (_) {}
  };
  for (const url of Array.isArray(data.videoUrls) ? data.videoUrls.slice(0, 100) : []) add(url);
  for (const slide of Array.isArray(data.pollSlides) ? data.pollSlides.slice(0, 100) : []) {
    if (slide?.type === 'video') for (const field of ['url', 'path', 'mediaPath']) add(slide[field]);
  }
  let visited = 0;
  const hidden = new Set(Array.isArray(data.moderation?.hiddenCommentIds) ? data.moderation.hiddenCommentIds : []);
  function walk(rows, depth = 0) {
    if (!Array.isArray(rows) || depth > 30) return;
    for (const row of rows) {
      if (++visited > 1000) return;
      if (!row || removed(row) || hidden.has(row.id)) continue;
      if (row.mediaType === 'video') add(row.mediaUrl, row);
      walk(row.replies, depth + 1);
    }
  }
  walk(data.comments);
  return paths;
}

function createPlaybackQueue({db, bucket, createJob, getJob, probe, now = Date.now}) {
  const jobs = db.collection('mediaPlaybackJobs');
  async function enqueuePost(postId, data) {
    if (typeof postId !== 'string' || !postId || postId.includes('/')) return;
    for (const objectPath of videoPaths(bucket.name, postId, data)) {
      let metadata;
      try { [metadata] = await bucket.file(objectPath).getMetadata(); }
      catch (error) { if (Number(error.code) === 404) continue; throw error; }
      if (!/^video\//i.test(metadata.contentType || '') || !/^\d+$/.test(String(metadata.generation)) ||
          !Number.isFinite(Number(metadata.size)) || Number(metadata.size) <= 0) continue;
      const generation = String(metadata.generation);
      const id = createHash('sha256').update(JSON.stringify([bucket.name, objectPath, generation])).digest('hex');
      try {
        await jobs.doc(id).create({postId, objectPath, generation, status:'queued', attempts:0, leaseUntilMS:0});
      } catch (error) { if (Number(error.code) !== 6 && error.code !== 'already-exists') throw error; }
    }
  }
  async function claim(ref, submitting) {
    return db.runTransaction(async tx => {
      const snap = await tx.get(ref), data = snap.data();
      if (!data || !['queued', 'submitting', 'pending'].includes(data.status) || data.leaseUntilMS > now()) return null;
      if ((data.status === 'pending') === submitting) return null;
      if (submitting && data.attempts >= 3) {
        tx.update(ref, {status:'failed', leaseUntilMS:0}); return null;
      }
      if (!submitting && ((data.pollAttempts || 0) >= 36 ||
          (data.pendingSinceMS != null && now() >= data.pendingSinceMS + 3 * 60 * 60 * 1000))) {
        tx.update(ref, {status:'failed', leaseUntilMS:0}); return null;
      }
      const leaseId = randomUUID();
      const next = {...data, leaseId, leaseUntilMS:now() + 120000,
        status:submitting ? 'submitting' : 'pending', attempts:data.attempts + (submitting ? 1 : 0)};
      if (!submitting) {
        next.pollAttempts = (data.pollAttempts || 0) + 1;
        next.pendingSinceMS = data.pendingSinceMS ?? now();
      }
      tx.update(ref, next);
      return next;
    });
  }
  async function finish(ref, leaseId, patch) {
    await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (snap.data()?.leaseId === leaseId) tx.update(ref, {...patch, leaseUntilMS:0, leaseId:''});
    });
  }
  async function referenced(data) {
    const snap = await db.doc(`community_posts/${data.postId}`).get();
    return videoPaths(bucket.name, data.postId, snap.data()).has(data.objectPath);
  }
  async function reconcile() {
    const snapshot = await jobs.where('status', 'in', ['queued', 'submitting', 'pending']).limit(30).get();
    let submissions = 0;
    // Poll existing jobs first. Each job has a transaction lease across invocations.
    const docs = [...snapshot.docs].sort((a, b) => Number(b.data().status === 'pending') - Number(a.data().status === 'pending'));
    for (const doc of docs) {
      const submitting = doc.data().status !== 'pending';
      if (submitting && submissions >= 4) continue;
      const data = await claim(doc.ref, submitting);
      if (!data) continue;
      if (submitting) submissions++;
      try {
        if (!await referenced(data)) {
          await finish(doc.ref, data.leaseId, {status:'obsolete'}); continue;
        }
        if (submitting) {
          const prepared = await preparePlaybackJob(bucket, data.objectPath, probe);
          if (prepared.generation !== data.generation || prepared.status === 'skipped') {
            await finish(doc.ref, data.leaseId, {status:'obsolete'}); continue;
          }
          if (prepared.status === 'existing') {
            await finish(doc.ref, data.leaseId, {status:'ready'}); continue;
          }
          if (!await referenced(data)) {
            await finish(doc.ref, data.leaseId, {status:'obsolete'}); continue;
          }
          // A crash after submission but before persistence can duplicate a job;
          // the persisted attempt budget bounds these submissions to three.
          const job = await createJob(prepared.job);
          if (typeof job?.name !== 'string' || !job.name) throw new Error('Missing job name');
          await finish(doc.ref, data.leaseId, {status:'pending', name:job.name,
            pollAttempts:0, pendingSinceMS:now()});
        } else {
          let job;
          try { job = await getJob(data.name); }
          catch (error) {
            const code = Number(error.code ?? error.status ?? error.response?.status);
            const permanent = code >= 400 && code < 500 && code !== 429;
            const expired = data.pollAttempts >= 36 || now() >= data.pendingSinceMS + 3 * 60 * 60 * 1000;
            await finish(doc.ref, data.leaseId, {status:permanent || expired ? 'failed' : 'pending'});
            continue;
          }
          if (job.state === 'SUCCEEDED') {
            if (!await referenced(data)) {
              await finish(doc.ref, data.leaseId, {status:'obsolete'}); continue;
            }
            const result = await finalizePlayback(bucket, data.objectPath, data.generation);
            await finish(doc.ref, data.leaseId, {status:result.status});
          } else {
            const expired = data.pollAttempts >= 36 || now() >= data.pendingSinceMS + 3 * 60 * 60 * 1000;
            await finish(doc.ref, data.leaseId, {status:job.state === 'FAILED' || expired ? 'failed' : 'pending'});
          }
        }
      } catch (_) {
        await finish(doc.ref, data.leaseId, {status:submitting ? (data.attempts >= 3 ? 'failed' : 'queued') :
          (data.pollAttempts >= 36 || now() >= data.pendingSinceMS + 3 * 60 * 60 * 1000 ? 'failed' : 'pending')});
      }
    }
  }
  return {enqueuePost, reconcile};
}

// Stable comparison lets the trigger ignore likes and other non-media edits.
const sourcePaths = (postId, data, bucketName) => [...videoPaths(bucketName, postId, data)].sort();
module.exports = {createPlaybackQueue, sourcePaths};
