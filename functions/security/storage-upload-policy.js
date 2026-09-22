// A grant authorizes one exact upload, never a prefix or a download URL.
const MIB = 1024 * 1024;
const GRANT_TTL_MS = 30 * 60 * 1000;
const ACCESS_TTL_MS = 60 * 60 * 1000;
const MAX_GRANTS_PER_MINUTE = 60;
const validId = v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(v);
const image = /^image\/(jpeg|png|gif|webp|bmp|heic|heif|avif)$/;
const video = /^video\/(mp4|quicktime|x-m4v|webm|x-matroska|3gpp)$/;
const audio = /^audio\/(mp4|mpeg|aac|ogg|wav|x-wav|webm)$/;
function invalid() { const e = new Error('Unsupported media path, type or size.'); e.code = 'invalid-argument'; throw e; }
function uploadPolicy(path, contentType, size, uid) {
  if (!validId(uid) || typeof path !== 'string' || path.length > 1024 ||
      typeof contentType !== 'string' || !Number.isSafeInteger(size) || size <= 0) invalid();
  const p = path.split('/');
  if (p.some(x => !x || x === '.' || x === '..' || /[\\\x00-\x1f\x7f]/.test(x))) invalid();
  const fileName = p.at(-1);
  if (!/^[A-Za-z0-9_.-]{1,800}$/.test(fileName)) invalid();
  let rule;
  if (p.length === 3 && p[0] === 'users' && p[1] === uid && image.test(contentType)) {
    rule = { kind: 'profile', overwrite: true, maxBytes: 20 * MIB };
  } else if (p.length === 4 && p[0] === 'community_posts' && validId(p[1])) {
    if (p[2] === 'images' && image.test(contentType)) rule = { kind: 'post', postId: p[1], overwrite: false, maxBytes: 20 * MIB };
    if (p[2] === 'videos' && video.test(contentType)) rule = { kind: 'post', postId: p[1], overwrite: false, maxBytes: 200 * MIB };
  } else if (p.length === 6 && p[0] === 'community_posts' && validId(p[1]) && p[2] === 'comments' &&
      p[3] === uid && validId(p[4]) && /^media\.[A-Za-z0-9]{1,8}$/.test(fileName) &&
      (image.test(contentType) || video.test(contentType))) {
    rule = { kind: 'comment', postId: p[1], commentId: p[4], overwrite: false, maxBytes: 40 * MIB };
  } else if (p.length === 4 && p[0] === 'chats' && /^[A-Za-z0-9_-]{1,300}$/.test(p[1])) {
    const folder = p[2];
    if ((folder === 'images' && image.test(contentType)) || (folder === 'videos' && video.test(contentType)) ||
        (folder === 'audio' && audio.test(contentType))) rule = { kind: 'chat', chatId: p[1], overwrite: false, maxBytes: 40 * MIB };
    if (folder === 'files' && contentType === 'application/octet-stream') rule = { kind: 'chat', chatId: p[1], overwrite: false, maxBytes: 20 * MIB };
    if (folder === 'wallpaper' && fileName === uid + '.jpg' && image.test(contentType)) {
      rule = { kind: 'wallpaper', chatId: p[1], overwrite: true, maxBytes: 20 * MIB };
    }
  }
  if (!rule || size > rule.maxBytes) invalid();
  return { ...rule, path, contentType, size };
}
function audienceAllows(value, following, reverse, fallback) {
  const who = value ?? fallback;
  return who === 'everyone' || (who === 'followers' && following) || (who === 'mutual' && following && reverse);
}
module.exports = { MIB, GRANT_TTL_MS, ACCESS_TTL_MS, MAX_GRANTS_PER_MINUTE, uploadPolicy, audienceAllows, validId };
