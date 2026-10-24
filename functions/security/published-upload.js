// New uploads are finalized server-side without bearer tokens. Legacy token
// locators remain accepted until the staged cutover revokes their tokens.
function publishedUploadMatches(metadata, locator, uid) {
  if (!Number.isSafeInteger(Number(metadata.size)) || Number(metadata.size) <= 0) return false;
  const stored = String(metadata.metadata?.firebaseStorageDownloadTokens || '');
  const token = locator.searchParams.get('token');
  if (token) return stored.split(',').includes(token);
  return !stored && metadata.metadata?.protectedUploadVersion === '1' &&
    metadata.metadata?.uploadedBy === uid &&
    /^[A-Za-z0-9_-]{20}$/.test(metadata.metadata?.uploadGrantId || '') &&
    /^[0-9]+$/.test(String(metadata.generation || ''));
}
module.exports = { publishedUploadMatches };