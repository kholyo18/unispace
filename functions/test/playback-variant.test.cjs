const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const { playbackObjectPath, buildPlaybackJob, pickPlaybackFile } = require('../security/playback-variant');

test('variant identity is deterministic and separates buckets, paths, and generations', () => {
  const digest = createHash('sha256').update('["bucket","community_posts/post/video.mp4","123"]').digest('hex');
  const path = playbackObjectPath('bucket', 'community_posts/post/video.mp4', '123');
  assert.equal(path, `community_playback/v1/${digest}/playback.mp4`);
  assert.equal(path, playbackObjectPath('bucket', 'community_posts/post/video.mp4', 123));
  for (const args of [['other', 'community_posts/post/video.mp4', '123'],
    ['bucket', 'community_posts/other/video.mp4', '123'], ['bucket', 'community_posts/post/video.mp4', '124']]) {
    assert.notEqual(path, playbackObjectPath(...args));
  }
  for (const args of [['', 'community_posts/a', '1'], ['bucket', 'other/a', '1'],
    ['bucket', 'community_posts/', '1'], ['bucket', 'community_posts/a', '1x'],
    ['bucket', 'community_posts/a', null], ['bucket', 'community_posts/a', '-1']]) {
    assert.throws(() => playbackObjectPath(...args), TypeError);
  }
});

test('job uses aspect-preserving 720-height AVC plus AAC MP4 and a separate output', () => {
  const job = buildPlaybackJob('gs://bucket/community_posts/a.mp4', 'gs://bucket/community_playback/v1/digest/');
  const [video, audio] = job.config.elementaryStreams;
  assert.deepEqual(video.videoStream.h264, { heightPixels: 720, bitrateBps: 2000000, frameRate: 30, pixelFormat: 'yuv420p' });
  assert.equal(Object.hasOwn(video.videoStream.h264, 'widthPixels'), false);
  assert.deepEqual(audio.audioStream, { codec: 'aac', bitrateBps: 96000 });
  assert.deepEqual(job.config.muxStreams, [{ key: 'playback', container: 'mp4', fileName: 'playback.mp4', elementaryStreams: ['video', 'audio'] }]);
  assert.equal(job.inputUri, 'gs://bucket/community_posts/a.mp4');
  assert.notEqual(job.inputUri, job.outputUri + 'playback.mp4');
  assert.throws(() => buildPlaybackJob('https://invalid/a', job.outputUri), TypeError);
  assert.throws(() => buildPlaybackJob(job.inputUri, 'gs://bucket/no-folder-slash'), TypeError);
  assert.throws(() => buildPlaybackJob('gs://bucket/x/playback.mp4', 'gs://bucket/x/'), TypeError);
});

test('known dimensions preserve portrait quality and avoid upscaling; silent input omits audio', () => {
  const make = options => buildPlaybackJob('gs://bucket/community_posts/a.mp4', 'gs://bucket/derived/', options);
  for (const [width, height, expected] of [[1080, 1920, 1280], [1920, 1080, 720],
    [1024, 1024, 720], [160, 90, 90], [1920, 1081, 720]]) {
    const h264 = make({ width, height }).config.elementaryStreams[0].videoStream.h264;
    assert.equal(h264.heightPixels, expected);
    assert.equal(Object.hasOwn(h264, 'widthPixels'), false);
  }
  assert.equal(make({ width: 0, height: 1080 }).config.elementaryStreams[0].videoStream.h264.heightPixels, 720);
  const silent = make({ width: 1080, height: 1920, hasAudio: false });
  assert.equal(silent.config.elementaryStreams.length, 1);
  assert.deepEqual(silent.config.muxStreams[0].elementaryStreams, ['video']);
  assert.equal(make({ hasAudio: true }).config.elementaryStreams.length, 2);
});

function fixture() {
  const originalPath = 'community_posts/post/source.mp4';
  const originalMetadata = { generation: '100', contentType: 'video/mp4', size: '1000000' };
  const derivedMetadata = { generation: '200', contentType: 'video/mp4', size: '100000',
    metadata: { sourceGeneration: '100', sourceObject: originalPath } };
  const files = new Map(), reads = [];
  let error;
  const storage = { name: 'bucket', file: path => {
    if (!files.has(path)) files.set(path, { name: path, getMetadata: async () => {
      reads.push(path); if (error) throw error; return [derivedMetadata];
    } }); return files.get(path);
  } };
  const run = () => pickPlaybackFile(storage, originalPath, originalMetadata);
  return { originalPath, originalMetadata, derivedMetadata, storage, run, reads, setError: value => { error = value; } };
}

test('verified smaller variant selected without modifying original metadata or file', async () => {
  const f = fixture(), before = structuredClone(f.originalMetadata);
  const result = await f.run();
  assert.equal(result.file.name, playbackObjectPath('bucket', f.originalPath, '100'));
  assert.equal(result.metadata, f.derivedMetadata);
  assert.deepEqual(f.originalMetadata, before);
  assert.deepEqual(f.reads, [result.file.name]);
});

test('images and missing variants preserve original; non-404 storage errors propagate', async () => {
  const image = fixture(); image.originalMetadata.contentType = 'image/jpeg';
  assert.equal((await image.run()).file.name, image.originalPath); assert.deepEqual(image.reads, []);
  const missing = fixture(); missing.setError(Object.assign(new Error('missing'), { code: 404 }));
  assert.equal((await missing.run()).metadata, missing.originalMetadata);
  for (const code of [403, 429, 500]) {
    const f = fixture(); f.setError(Object.assign(new Error('failure'), { code }));
    await assert.rejects(f.run(), { code });
  }
});

test('unverified, stale, wrong-source, invalid or oversized outputs cannot be selected', async () => {
  const mutations = [m => { delete m.metadata; }, m => { m.metadata.sourceGeneration = '99'; },
    m => { m.metadata.sourceObject = 'community_posts/other.mp4'; }, m => { m.contentType = 'image/jpeg'; },
    m => { m.size = '1000001'; }, m => { m.size = '0'; }, m => { m.size = 'invalid'; },
    m => { delete m.generation; }];
  for (const mutate of mutations) {
    const f = fixture(); mutate(f.derivedMetadata);
    const result = await f.run();
    assert.equal(result.file.name, f.originalPath); assert.equal(result.metadata, f.originalMetadata);
  }
});
