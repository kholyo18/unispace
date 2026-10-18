const {getApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');
const {onDocumentWritten} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {createPlaybackQueue, sourcePaths} = require('./playback-queue');
const {probeMp4} = require('./mp4-probe');

const bucketName = 'fachub-c631c.firebasestorage.app';
// Transcoder returns canonical resource names containing the project number.
const parent = 'projects/696673984351/locations/europe-west1';
async function transcoder(path, method = 'GET', body) {
  const token = await getApp().options.credential.getAccessToken();
  const response = await fetch('https://transcoder.googleapis.com/v1/' + path, {
    method, headers: {Authorization: 'Bearer ' + token.access_token, 'Content-Type': 'application/json'},
    body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(30000),
  });
  if (!response.ok) throw Object.assign(new Error('Playback service unavailable'), {code: response.status});
  return response.json();
}
function queue() {
  return createPlaybackQueue({db: getFirestore(), bucket: getStorage().bucket(bucketName),
    createJob: job => transcoder(parent + '/jobs', 'POST', job),
    getJob: name => {
      if (typeof name !== 'string' || !name.startsWith(parent + '/jobs/') || !/^[\w-]+$/.test(name.slice((parent + '/jobs/').length))) {
        throw new Error('Invalid playback job identity');
      }
      return transcoder(name);
    },
    probe: (file, metadata) => probeMp4(async (start, end) => {
      const [bytes] = await file.bucket.file(file.name, {generation: metadata.generation})
        .download({start, end, validation: false});
      return bytes;
    }, Number(metadata.size)),
  });
}
exports.queuePostPlayback = onDocumentWritten({document: 'community_posts/{postId}',
  region: 'europe-west1', retry: true, maxInstances: 2, concurrency: 1, timeoutSeconds: 120},
async event => {
  if (!event.data?.after.exists) return;
  const before = sourcePaths(event.params.postId, event.data.before.data(), bucketName);
  const after = sourcePaths(event.params.postId, event.data.after.data(), bucketName);
  if (JSON.stringify(before) !== JSON.stringify(after)) {
    await queue().enqueuePost(event.params.postId, event.data.after.data());
  }
});
exports.processPlaybackQueue = onSchedule({schedule: 'every 1 minutes', region: 'europe-west1',
  maxInstances: 1, concurrency: 1, timeoutSeconds: 300}, async () => {
  await queue().reconcile();
});
