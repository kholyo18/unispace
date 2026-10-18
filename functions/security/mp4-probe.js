const MAX_MOOV_BYTES = 2 * 1024 * 1024;
class InvalidMp4 extends Error {}
const invalid = () => { throw new InvalidMp4(); };

function box(buffer, offset, end) {
  if (end - offset < 8) invalid();
  let size = buffer.readUInt32BE(offset), header = 8;
  const type = buffer.toString('ascii', offset + 4, offset + 8);
  if (size === 1) {
    if (end - offset < 16) invalid();
    const extended = buffer.readBigUInt64BE(offset + 8);
    if (extended > BigInt(Number.MAX_SAFE_INTEGER)) invalid();
    size = Number(extended); header = 16;
  } else if (size === 0) size = end - offset;
  if (size < header || size > end - offset) invalid();
  return { type, start: offset + header, end: offset + size };
}

function parseMovie(buffer, fastStart) {
  let remaining = 4096;
  function children(start, end) {
    const rows = [];
    for (let offset = start; offset < end;) {
      if (--remaining < 0) invalid();
      const row = box(buffer, offset, end); rows.push(row); offset = row.end;
    }
    return rows;
  }
  const rows = children(0, buffer.length);
  const movie = rows.find(row => row.type === 'mvhd');
  if (!movie) invalid();
  const version = buffer[movie.start];
  const scaleOffset = version === 0 ? 12 : version === 1 ? 20 : invalid();
  const durationOffset = version === 0 ? 16 : 24;
  if (movie.end - movie.start < durationOffset + (version === 0 ? 4 : 8)) invalid();
  const scale = buffer.readUInt32BE(movie.start + scaleOffset);
  const duration = version === 0 ? buffer.readUInt32BE(movie.start + durationOffset) :
    buffer.readBigUInt64BE(movie.start + durationOffset);
  if (!scale || duration > Number.MAX_SAFE_INTEGER) invalid();
  let width, height, hasAudio = false;
  const tracks = rows.filter(row => row.type === 'trak');
  if (!tracks.length) invalid();
  for (const track of tracks) {
    const parts = children(track.start, track.end);
    const media = parts.find(row => row.type === 'mdia');
    if (!media) invalid();
    const handler = children(media.start, media.end).find(row => row.type === 'hdlr');
    if (!handler || handler.end - handler.start < 12) invalid();
    const kind = buffer.toString('ascii', handler.start + 8, handler.start + 12);
    if (kind === 'soun') hasAudio = true;
    if (kind !== 'vide') continue;
    const header = parts.find(row => row.type === 'tkhd');
    if (!header) invalid();
    const trackVersion = buffer[header.start];
    const widthOffset = trackVersion === 0 ? 76 : trackVersion === 1 ? 88 : invalid();
    if (header.end - header.start < widthOffset + 8) invalid();
    const w = buffer.readUInt32BE(header.start + widthOffset) / 65536;
    const h = buffer.readUInt32BE(header.start + widthOffset + 4) / 65536;
    if (!(w >= 2 && h >= 2)) invalid();
    // Keep encoded track dimensions: Transcoder handles the rotation matrix.
    if (width == null) { width = Math.floor(w); height = Math.floor(h); }
  }
  if (width == null) invalid();
  return { width, height, hasAudio, durationSeconds: Number(duration) / scale, fastStart };
}

async function probeMp4(readRange, size) {
  if (typeof readRange !== 'function' || !Number.isSafeInteger(size) || size < 8) return {};
  async function read(start, end) {
    if (start < 0 || end >= size || start > end) invalid();
    const buffer = await readRange(start, end);
    if (!Buffer.isBuffer(buffer) || buffer.length !== end - start + 1) invalid();
    return buffer;
  }
  try {
    let offset = 0, seenMedia = false;
    for (let count = 0; count < 64 && offset < size; count++) {
      const header = await read(offset, offset + 7);
      let length = header.readUInt32BE(0), headerSize = 8;
      const type = header.toString('ascii', 4, 8);
      if (count === 0 && !['ftyp', 'moov', 'mdat', 'free', 'wide', 'skip'].includes(type)) return {};
      if (length === 1) {
        const extended = (await read(offset + 8, offset + 15)).readBigUInt64BE(0);
        if (extended > BigInt(Number.MAX_SAFE_INTEGER)) return {};
        length = Number(extended); headerSize = 16;
      } else if (length === 0) length = size - offset;
      if (length < headerSize || length > size - offset) return {};
      if (type === 'moov') {
        if (length > MAX_MOOV_BYTES || length === headerSize) return {};
        return parseMovie(await read(offset + headerSize, offset + length - 1), !seenMedia);
      }
      if (type === 'mdat') seenMedia = true;
      offset += length;
    }
    return {};
  } catch (error) {
    if (error instanceof InvalidMp4) return {};
    throw error;
  }
}

module.exports = { probeMp4 };
