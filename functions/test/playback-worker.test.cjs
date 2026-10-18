const {test} = require('node:test');
const assert = require('node:assert/strict');
const {preparePlaybackJob, finalizePlayback} = require('../security/playback-worker');
const {playbackObjectPath} = require('../security/playback-variant');

function fixture() {
  const path = 'community_posts/post/videos/original.mp4';
  const outputPath = playbackObjectPath('demo', path, '42');
  const original = {generation:'42', size:'25000000', contentType:'video/mp4',
    metadata:{firebaseStorageDownloadTokens:'original-token-must-not-propagate'}};
  const output = {generation:'87', metageneration:'1', size:'2500000', contentType:'video/mp4'};
  const records = new Map([[path, original]]), writes = [];
  let onRead = () => {}, beforeWrite = () => {};
  const bucket = {name:'demo', file:(name, options = {}) => ({
    name,
    getMetadata:async () => {
      onRead(name);
      if (!records.has(name)) throw Object.assign(new Error('missing'), {code:404});
      return [structuredClone(records.get(name))];
    },
    setMetadata:async (data, conditions) => {
      beforeWrite(name);
      const current = records.get(name);
      if (!current || options.generation !== current.generation ||
          conditions.ifMetagenerationMatch !== current.metageneration) {
        throw Object.assign(new Error('changed'), {code:412});
      }
      writes.push({name, options, data, conditions});
    },
  })};
  return {path, outputPath, original, output, records, writes, bucket,
    onRead:fn => {onRead = fn;}, beforeWrite:fn => {beforeWrite = fn;}};
}

test('preparation builds separate video job using optional dimensions and omits silent audio', async () => {
  const f = fixture(), before = structuredClone(f.original);
  const result = await preparePlaybackJob(f.bucket, f.path, async (file, metadata) => {
    assert.equal(file.name, f.path); assert.equal(metadata.generation, '42');
    return {width:1080, height:1920, hasAudio:false, durationSeconds:13};
  });
  assert.equal(result.status, 'pending'); assert.equal(result.generation, '42');
  assert.equal(result.outputPath, f.outputPath);
  assert.equal(result.job.inputUri, 'gs://demo/' + f.path);
  assert.equal(result.job.config.elementaryStreams.length, 1);
  assert.equal(result.job.config.elementaryStreams[0].videoStream.h264.heightPixels, 1280);
  assert.equal(JSON.stringify(result).includes('original-token'), false);
  assert.deepEqual(f.original, before); assert.deepEqual(f.writes, []);
});

test('preparation skips unknown, zero, invalid or excessive duration without changing original', async () => {
  for (const probe of [undefined, async () => ({}), async () => null,
    ...[0, -1, 601, Infinity, NaN, '13'].map(durationSeconds => async () => ({durationSeconds}))]) {
    const f = fixture(), before = structuredClone(f.original);
    assert.equal((await preparePlaybackJob(f.bucket, f.path, probe)).status, 'skipped');
    assert.deepEqual(f.original, before); assert.deepEqual(f.writes, []);
  }
});

test('preparation enforces byte budget before probing and accepts inclusive limits', async () => {
  const oversized = fixture(); oversized.original.size = String(500 * 1024 * 1024 + 1);
  assert.equal((await preparePlaybackJob(oversized.bucket, oversized.path,
    () => {throw Error('Oversized source must not be probed');})).status, 'skipped');
  const boundary = fixture(); boundary.original.size = String(500 * 1024 * 1024);
  assert.equal((await preparePlaybackJob(boundary.bucket, boundary.path,
    async () => ({durationSeconds:600}))).status, 'pending');
  const short = fixture();
  assert.equal((await preparePlaybackJob(short.bucket, short.path,
    async () => ({durationSeconds:0.1}))).status, 'pending');
});

test('preparation skips images, unrelated paths, missing sources, and verified existing output', async () => {
  const f = fixture();
  assert.equal((await preparePlaybackJob(f.bucket, 'other/file.mp4')).status, 'skipped');
  assert.equal((await preparePlaybackJob(f.bucket, 'community_posts/missing')).status, 'skipped');
  f.original.contentType = 'image/jpeg';
  assert.equal((await preparePlaybackJob(f.bucket, f.path)).status, 'skipped');
  f.original.contentType = 'video/mp4';
  f.output.metadata = {sourceGeneration:'42', sourceObject:f.path};
  f.records.set(f.outputPath, f.output);
  assert.equal((await preparePlaybackJob(f.bucket, f.path, () => {throw Error('must not probe');})).status, 'existing');
});

test('finalization stamps only derived output with source binding and private cache control', async () => {
  const f = fixture(), before = structuredClone(f.original);
  f.records.set(f.outputPath, f.output);
  assert.deepEqual(await finalizePlayback(f.bucket, f.path, '42'), {status:'ready', outputPath:f.outputPath});
  assert.deepEqual(f.writes, [{name:f.outputPath, options:{generation:'87'},
    data:{cacheControl:'private,max-age=300', metadata:{sourceGeneration:'42', sourceObject:f.path}},
    conditions:{ifMetagenerationMatch:'1'}}]);
  assert.deepEqual(f.original, before);
  assert.equal(JSON.stringify(f.writes).includes('firebaseStorageDownloadTokens'), false);
});

test('source replacement before or during output inspection never stamps', async () => {
  for (const during of [false, true]) {
    const f = fixture(); f.records.set(f.outputPath, f.output);
    if (during) f.onRead(name => {if (name === f.outputPath) f.original.generation = '43';});
    else f.original.generation = '43';
    assert.equal((await finalizePlayback(f.bucket, f.path, '42')).status, 'obsolete');
    assert.deepEqual(f.writes, []);
  }
});

test('invalid, oversized, empty, or token-bearing outputs are rejected', async () => {
  for (const change of [o => {o.size = '25000001';}, o => {o.size = '0';},
    o => {o.contentType = 'image/jpeg';}, o => {delete o.generation;},
    o => {o.metadata = {firebaseStorageDownloadTokens:'unexpected'};}]) {
    const f = fixture(); change(f.output); f.records.set(f.outputPath, f.output);
    assert.equal((await finalizePlayback(f.bucket, f.path, '42')).status, 'rejected');
    assert.deepEqual(f.writes, []);
  }
});

test('output replacement or metadata changes between validation and stamp cannot be marked', async () => {
  for (const key of ['generation', 'metageneration']) {
    const f = fixture(); f.records.set(f.outputPath, f.output);
    f.beforeWrite(() => {f.output[key] = '99';});
    assert.equal((await finalizePlayback(f.bucket, f.path, '42')).status, 'obsolete');
    assert.deepEqual(f.writes, []);
  }
});
