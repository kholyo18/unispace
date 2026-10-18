const {playbackObjectPath, buildPlaybackJob, pickPlaybackFile} = require('./playback-variant');

const missing = error => Number(error.code) === 404;
const MAX_SOURCE_BYTES = 500 * 1024 * 1024;
const MAX_DURATION_SECONDS = 600;
const validVideo = metadata => /^video\//i.test(metadata?.contentType || '') &&
  /^\d+$/.test(String(metadata?.generation)) &&
  Number.isFinite(Number(metadata?.size)) && Number(metadata.size) > 0;

async function preparePlaybackJob(bucket, objectPath, probe) {
  if (typeof objectPath !== 'string' || !objectPath.startsWith('community_posts/')) {
    return {status:'skipped'};
  }
  const original = bucket.file(objectPath);
  let metadata;
  try { [metadata] = await original.getMetadata(); }
  catch (error) { if (missing(error)) return {status:'skipped'}; throw error; }
  if (!validVideo(metadata) || Number(metadata.size) > MAX_SOURCE_BYTES) return {status:'skipped'};
  const generation = String(metadata.generation);
  const outputPath = playbackObjectPath(bucket.name, objectPath, generation);
  const selected = await pickPlaybackFile(bucket, objectPath, metadata);
  if (selected.metadata !== metadata) return {status:'existing', generation, outputPath};
  const dimensions = probe ? await probe(original, metadata) : undefined;
  // Job count alone does not bound paid work: unknown or excessive duration
  // stays on original delivery instead of entering the transcoding queue.
  if (!Number.isFinite(dimensions?.durationSeconds) || dimensions.durationSeconds <= 0 ||
      dimensions.durationSeconds > MAX_DURATION_SECONDS) return {status:'skipped'};
  const job = buildPlaybackJob(`gs://${bucket.name}/${objectPath}`,
    `gs://${bucket.name}/${outputPath.slice(0, outputPath.lastIndexOf('/') + 1)}`, dimensions);
  return {status:'pending', generation, outputPath, job};
}

// Call only after the corresponding Transcoder job reports SUCCEEDED.
// This function neither submits nor polls jobs, and never mutates the original.
async function finalizePlayback(bucket, objectPath, generation) {
  const outputPath = playbackObjectPath(bucket.name, objectPath, generation);
  const original = bucket.file(objectPath);
  let metadata, output;
  try {
    [metadata] = await original.getMetadata();
    if (String(metadata.generation) !== String(generation)) return {status:'obsolete'};
    [output] = await bucket.file(outputPath).getMetadata();
  } catch (error) {
    if (missing(error)) return {status:'obsolete'};
    throw error;
  }
  const size = Number(output.size);
  if (!validVideo(metadata) || output.contentType !== 'video/mp4' ||
      !/^\d+$/.test(String(output.generation)) || !/^\d+$/.test(String(output.metageneration)) ||
      !Number.isFinite(size) || size <= 0 || size > Number(metadata.size) ||
      Object.hasOwn(output.metadata || {}, 'firebaseStorageDownloadTokens')) {
    return {status:'rejected'};
  }
  // Probe/output reads may race replacement or deletion of the source.
  try { [metadata] = await original.getMetadata(); }
  catch (error) { if (missing(error)) return {status:'obsolete'}; throw error; }
  if (String(metadata.generation) !== String(generation)) return {status:'obsolete'};
  const custom = Object.fromEntries(Object.keys(output.metadata || {}).map(key => [key, null]));
  custom.sourceGeneration = String(generation);
  custom.sourceObject = objectPath;
  try {
    await bucket.file(outputPath, {generation:String(output.generation)}).setMetadata({
      cacheControl:'private,max-age=300', metadata:custom,
    }, {ifMetagenerationMatch:String(output.metageneration)});
  } catch (error) {
    if (missing(error) || Number(error.code) === 412) return {status:'obsolete'};
    throw error;
  }
  return {status:'ready', outputPath};
}

module.exports = {preparePlaybackJob, finalizePlayback};
