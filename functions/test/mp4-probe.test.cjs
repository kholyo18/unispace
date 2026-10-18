const { test } = require('node:test');
const assert = require('node:assert/strict');
const { probeMp4 } = require('../security/mp4-probe');

function atom(type, payload = Buffer.alloc(0), extended = false) {
  const h = Buffer.alloc(extended ? 16 : 8);
  h.writeUInt32BE(extended ? 1 : h.length + payload.length); h.write(type, 4);
  if (extended) h.writeBigUInt64BE(BigInt(h.length + payload.length), 8);
  return Buffer.concat([h, payload]);
}
function movie(audio = true, version = 0) {
  const mvhd = Buffer.alloc(version ? 32 : 20); mvhd[0] = version;
  mvhd.writeUInt32BE(1000, version ? 20 : 12);
  if (version) mvhd.writeBigUInt64BE(20500n, 24); else mvhd.writeUInt32BE(20500, 16);
  function track(kind) {
    const tkhd = Buffer.alloc(version ? 96 : 84); tkhd[0] = version;
    tkhd.writeUInt32BE(1080 * 65536, version ? 88 : 76);
    tkhd.writeUInt32BE(1920 * 65536, version ? 92 : 80);
    const hdlr = Buffer.alloc(12); hdlr.write(kind, 8);
    return atom('trak', Buffer.concat([atom('tkhd', tkhd), atom('mdia', atom('hdlr', hdlr))]));
  }
  return atom('moov', Buffer.concat([atom('mvhd', mvhd), track('vide'), ...(audio ? [track('soun')] : [])]));
}
function source(buffer) {
  const reads = [];
  return { reads, read: async (start, end) => { reads.push([start, end]); return buffer.subarray(start, end + 1); } };
}

test('moov at end is sought directly without downloading media payload', async () => {
  const ftyp = atom('ftyp', Buffer.from('isom0000')), mdat = atom('mdat', Buffer.alloc(1000000));
  const moov = movie(), buffer = Buffer.concat([ftyp, mdat, moov]), f = source(buffer);
  assert.deepEqual(await probeMp4(f.read, buffer.length), {
    width: 1080, height: 1920, hasAudio: true, durationSeconds: 20.5, fastStart: false,
  });
  assert.equal(f.reads.some(([start, end]) => start < ftyp.length + mdat.length && end > ftyp.length + 7), false);
  assert.ok(f.reads.reduce((sum, [start, end]) => sum + end - start + 1, 0) < 1000);
});

test('front moov, version-one headers, silent video and extended top-level box', async () => {
  const buffer = Buffer.concat([atom('ftyp', Buffer.from('isom0000'), true), movie(false, 1), atom('mdat')]);
  const f = source(buffer);
  assert.deepEqual(await probeMp4(f.read, buffer.length), {
    width: 1080, height: 1920, hasAudio: false, durationSeconds: 20.5, fastStart: true,
  });
});

test('unknown, truncated and malformed formats return unknown safely', async () => {
  const malformed = [Buffer.from('not a video'), Buffer.alloc(7), atom('moov'),
    atom('moov', Buffer.from([0, 0, 0, 4, 116, 114, 97, 107])), atom('mdat', Buffer.alloc(8))];
  for (const buffer of malformed) assert.deepEqual(await probeMp4(source(buffer).read, buffer.length), {});
  const valid = movie();
  assert.deepEqual(await probeMp4(async () => Buffer.alloc(1), valid.length), {});
  const oversized = Buffer.alloc(16); oversized.writeUInt32BE(1); oversized.write('moov', 4);
  oversized.writeBigUInt64BE(BigInt(Number.MAX_SAFE_INTEGER) + 1n, 8);
  assert.deepEqual(await probeMp4(source(oversized).read, oversized.length), {});
  const overflow = atom('moov', Buffer.alloc(8)); overflow.writeUInt32BE(99999);
  assert.deepEqual(await probeMp4(source(overflow).read, overflow.length), {});
});

test('probe limits moov bytes and top-level header count', async () => {
  const large = atom('moov', Buffer.alloc(2 * 1024 * 1024)), largeSource = source(large);
  assert.deepEqual(await probeMp4(largeSource.read, large.length), {});
  assert.deepEqual(largeSource.reads, [[0, 7]]);
  const many = Buffer.concat([...Array.from({ length: 65 }, () => atom('free')), movie()]), f = source(many);
  assert.deepEqual(await probeMp4(f.read, many.length), {});
  assert.equal(f.reads.length, 64);
  assert.equal(f.reads.reduce((sum, [start, end]) => sum + end - start + 1, 0), 512);
  const crowded = atom('moov', Buffer.concat(Array.from({ length: 4097 }, () => atom('free'))));
  assert.deepEqual(await probeMp4(source(crowded).read, crowded.length), {});
});

test('zero-sized movie extends to EOF; truncated track cannot imply silent audio', async () => {
  const zeroSized = movie(false); zeroSized.writeUInt32BE(0);
  assert.equal((await probeMp4(source(zeroSized).read, zeroSized.length)).hasAudio, false);
  const valid = movie(false), payload = valid.subarray(8);
  const missingHandler = atom('moov', Buffer.concat([payload, atom('trak', atom('mdia'))]));
  assert.deepEqual(await probeMp4(source(missingHandler).read, missingHandler.length), {});
});

test('storage failures propagate instead of being misreported as malformed video', async () => {
  await assert.rejects(probeMp4(async () => { throw Object.assign(new Error('unavailable'), { code: 503 }); }, 100), { code: 503 });
});
