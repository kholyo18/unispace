const { createHash } = require('node:crypto');

function playbackObjectPath(bucket, objectPath, generation) {
  if (typeof bucket !== 'string' || !bucket.trim() || /[\/\s\x00-\x1f]/.test(bucket) ||
      typeof objectPath !== 'string' || !objectPath.startsWith('community_posts/') ||
      objectPath.length <= 'community_posts/'.length || /[\x00-\x1f]/.test(objectPath) ||
      !['string', 'number'].includes(typeof generation) || !/^\d+$/.test(String(generation))) {
    throw new TypeError('Invalid playback source identity.');
  }
  const digest = createHash('sha256').update(JSON.stringify([bucket, objectPath, String(generation)])).digest('hex');
  return `community_playback/v1/${digest}/playback.mp4`;
}

function buildPlaybackJob(inputGsUri, outputGsFolder, { width, height, hasAudio } = {}) {
  const valid = uri => typeof uri === 'string' && /^gs:\/\/[^/\s?#]+\/[^\r\n]+$/.test(uri);
  if (!valid(inputGsUri) || !valid(outputGsFolder) || !outputGsFolder.endsWith('/') ||
      inputGsUri === outputGsFolder + 'playback.mp4') {
    throw new TypeError('Invalid playback job locations.');
  }
  let heightPixels = 720;
  if (Number.isInteger(width) && width >= 2 && Number.isInteger(height) && height >= 2) {
    const scale = Math.min(1, 1280 / Math.max(width, height), 720 / Math.min(width, height));
    heightPixels = Math.max(2, Math.floor(height * scale / 2) * 2);
  }
  const elementaryStreams = [
    { key: 'video', videoStream: { h264: {
      heightPixels, bitrateBps: 2000000, frameRate: 30, pixelFormat: 'yuv420p',
    } } },
  ];
  if (hasAudio !== false) elementaryStreams.push({ key: 'audio', audioStream: { codec: 'aac', bitrateBps: 96000 } });
  return {
    inputUri: inputGsUri,
    outputUri: outputGsFolder,
    config: {
      elementaryStreams,
      muxStreams: [{ key: 'playback', container: 'mp4', fileName: 'playback.mp4',
        elementaryStreams: elementaryStreams.map(stream => stream.key) }],
    },
  };
}

async function pickPlaybackFile(storage, originalPath, originalMetadata) {
  const original = { file: storage.file(originalPath), metadata: originalMetadata };
  if (!String(originalMetadata?.contentType || '').toLowerCase().startsWith('video/')) return original;
  const originalSize = Number(originalMetadata.size);
  if (!Number.isFinite(originalSize) || originalSize <= 0) return original;
  const derivedPath = playbackObjectPath(storage.name, originalPath, originalMetadata.generation);
  const file = storage.file(derivedPath);
  let metadata;
  try { [metadata] = await file.getMetadata(); }
  catch (error) {
    if (error.code === 404 || error.code === '404') return original;
    // Do not disguise permission/service failures as an absent rendition.
    throw error;
  }
  const size = Number(metadata?.size);
  if (metadata?.metadata?.sourceGeneration !== String(originalMetadata.generation) ||
      metadata?.metadata?.sourceObject !== originalPath ||
      metadata?.contentType !== 'video/mp4' || !/^\d+$/.test(String(metadata?.generation)) ||
      !Number.isFinite(size) || size <= 0 || size > originalSize) return original;
  return { file, metadata };
}

module.exports = { playbackObjectPath, buildPlaybackJob, pickPlaybackFile };
