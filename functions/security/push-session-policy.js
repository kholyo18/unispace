// Server-owned push binding checks. This is not token-bound per-device login.
const validAuthTime = value => Number.isSafeInteger(value) && value >= 0;
const validSessionId = value => typeof value === 'string' && value.length > 0 &&
  value.length <= 128 && !value.includes('/') && !['.', '..'].includes(value);

function cutoffAllows(authTime, cutoff) {
  return validAuthTime(authTime) && (cutoff == null ||
    (validAuthTime(cutoff.revokedBefore) && authTime > cutoff.revokedBefore));
}

// Auth revocation can happen without updating our Firestore mirror (for
// example, an administrator revokes tokens or a password is reset). Match the
// Admin SDK boundary: equality is valid here; Firestore cutoffAllows stays >.
function authCutoffAllows(authTime, tokensValidAfterTime) {
  if (!validAuthTime(authTime)) return false;
  // UserRecord documents this field as optional. Explicit malformed values
  // are not an absent cutoff and must not authorize delivery.
  if (tokensValidAfterTime === undefined) return true;
  if (typeof tokensValidAfterTime !== 'string') return false;
  const cutoffMillis = Date.parse(tokensValidAfterTime);
  return Number.isFinite(cutoffMillis) && cutoffMillis >= 0 &&
    authTime >= cutoffMillis / 1000;
}

function bindingAllows({ binding, userId, cutoff, session }) {
  if (!binding || binding.ownerId !== userId || !validSessionId(binding.sessionId) ||
      !cutoffAllows(binding.authTime, cutoff)) return false;
  return !!session && session.sessionId === binding.sessionId && session.isRevoked === false &&
    typeof session.createdAt?.toMillis === 'function' &&
    typeof binding.sessionCreatedAt?.isEqual === 'function' &&
    binding.sessionCreatedAt.isEqual(session.createdAt);
}

function registrationMatches(record, binding) {
  return !!record && !!binding && validAuthTime(record.authTime) &&
    record.authTime === binding.authTime && record.sessionId === binding.sessionId &&
    !!record.preferences && !Array.isArray(record.preferences) &&
    ['enabled', 'community', 'announcements', 'exams']
      .every(key => typeof record.preferences[key] === 'boolean');
}

module.exports = { validAuthTime, cutoffAllows, authCutoffAllows, bindingAllows, registrationMatches };
