const { HttpsError } = require('firebase-functions/v2/https');
const { createContentSearchPageHandler, removed } = require('./content-search-page');
const validId = v => typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/') && !['.', '..'].includes(v);
const unavailable = d => !d || ['disabled', 'deleted'].includes(d.accountStatus) || d.security?.frozen === true;

const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const invalid = () => { throw new HttpsError('invalid-argument', 'Invalid or missing poll answer.'); };
const time = v => object(v) && Object.keys(v).length === 2 && Number.isInteger(v.hour) &&
  v.hour >= 0 && v.hour <= 23 && Number.isInteger(v.minute) && v.minute >= 0 && v.minute <= 59;
const indices = (v, size) => Array.isArray(v) && v.length <= size && new Set(v).size === v.length &&
  v.every(n => Number.isInteger(n) && n >= 0 && n < size);
function dateDay(v) {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}T00:00:00\.0{3,6}$/.test(v)) invalid();
  const day = v.slice(0, 10), parsed = new Date(day + 'T00:00:00Z');
  if (!Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== day) invalid();
  return day;
}
function validateAnswers(polls, answers) {
  if (!Array.isArray(polls) || !polls.length || polls.length > 100) {
    throw new HttpsError('failed-precondition', 'Poll unavailable.');
  }
  const allowed = new Set(), result = {};
  polls.forEach((p, i) => {
    const key = String(i), timeKey = String(i + 100000), value = answers[key];
    allowed.add(key);
    const includeTime = p.type === 'date' && (p.includeTime === true || p.dateConfig?.includeTime === true);
    if (includeTime) allowed.add(timeKey);
    let present = false;
    if (value != null) {
      switch (p.type) {
        case 'shortText': case 'longText':
          if (typeof value !== 'string' || value.length > 100000) invalid();
          present = value.trim().length > 0; break;
        case 'dropdown':
          if (typeof value !== 'string' || (value !== '' && !p.options?.includes(value))) invalid();
          present = value.length > 0; break;
        case 'singelOptin':
          if (!Number.isInteger(value) || value < 0 || value >= (p.options?.length || 0)) invalid();
          present = true; break;
        case 'checkbox':
          if (!indices(value, p.options?.length || 0)) invalid();
          present = value.length > 0; break;
        case 'linearScale': {
          const max = p.scaleStyle === 'slider' ? 100 : Math.min(10, Math.max(1, p.scaleSize ?? 5)) - 1;
          if (!Number.isInteger(value) || value < 0 || value > max) invalid();
          present = true; break;
        }
        case 'grid': case 'checkboxGrid':
          if (!object(value) || Object.keys(value).length > (p.gridRows?.length || 0)) invalid();
          for (const [row, columns] of Object.entries(value)) {
            if (!/^(0|[1-9]\d*)$/.test(row) || Number(row) >= (p.gridRows?.length || 0) ||
                !indices(columns, p.gridColumns?.length || 0) || (p.type === 'grid' && columns.length > 1)) invalid();
            present = present || columns.length > 0;
          }
          break;
        case 'time':
          if (!time(value)) invalid();
          present = true; break;
        case 'date': {
          const multi = p.multiSelect === true || p.dateConfig?.multiSelect === true;
          if (multi && !Array.isArray(value)) invalid();
          const values = multi ? value : [value];
          if (values.length > 3660) invalid();
          const days = values.map(dateDay), config = p.dateConfig;
          if (new Set(days).size !== days.length) invalid();
          for (const day of days) {
            if (config?.allowedDays?.length) {
              if (!config.allowedDays.some(d => typeof d === 'string' && d.slice(0, 10) === day)) invalid();
            } else if (config) {
              if (Number(day.slice(0, 4)) !== config.year ||
                  (config.months?.length && !config.months.includes(Number(day.slice(5, 7))))) invalid();
            } else if (day < '2000-01-01' || day > '2100-01-01') invalid();
          }
          present = days.length > 0; break;
        }
        default: invalid();
      }
    }
    if (p.isRequired === true && !present) invalid();
    if (includeTime && answers[timeKey] != null && !time(answers[timeKey])) invalid();
    if (includeTime && present && !time(answers[timeKey])) invalid();
    if (present) {
      result[key] = value;
      if (includeTime) result[timeKey] = answers[timeKey];
    }
  });
  if (Object.keys(answers).some(key => !allowed.has(key))) invalid();
  return result;
}

function createPollAnswerHandler({ auth, db, FieldValue }) {
  const readPost = createContentSearchPageHandler({ auth, db }, true);
  return async request => {
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 2 ||
        !validId(input.postId) || !object(input.answers) || Object.keys(input.answers).length > 200 ||
        Buffer.byteLength(JSON.stringify(input.answers), 'utf8') > 150000) invalid();
    const uid = request.auth?.uid;
    // Includes original-post/comment authorization for reposts and the shared request limit.
    const visible = await readPost({ ...request, data: { postId: input.postId } });
    const header = request.rawRequest?.headers?.authorization || '';
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    return db.runTransaction(async tx => {
      const ref = db.doc(`community_posts/${input.postId}`);
      const snapshot = await tx.get(ref), data = snapshot.data();
      if (removed(data) || data.authorId !== visible.data.authorId) throw new HttpsError('not-found', 'Post unavailable.');
      const owner = data.authorId;
      const paths = [`authRevocations/${uid}`, `users/${uid}`, `users/${owner}`, `users/${owner}/followers/${uid}`,
        ...['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [`users/${uid}/${c}/${owner}`, `users/${owner}/${c}/${uid}`])];
      const [cutoff, actor, profile, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (unavailable(actor.data()) || unavailable(profile.data()) || (uid !== owner && blocks.some(b => b.exists))) {
        throw new HttpsError('permission-denied', 'Post unavailable.');
      }
      const p = profile.data(), privacy = p.privacy || {};
      const privateAccount = typeof privacy.privateAccount === 'boolean' ? privacy.privateAccount : p.profileVisibility === 'private';
      if (uid !== owner && privateAccount && !follower.exists) throw new HttpsError('permission-denied', 'Post is private.');
      const answers = validateAnswers(data.polls, input.answers);
      const account = actor.data();
      const respondentName = [account.userName, account.name, account.displayName]
        .find(v => typeof v === 'string' && v.trim())?.trim().slice(0, 200) || 'طالب UniSpace';
      // Replace the answer map so cleared optional answers do not survive resubmission.
      tx.set(ref.collection('poll_responses').doc(uid), {
        answers, respondentId: uid, respondentName, submittedAt: FieldValue.serverTimestamp(),
      });
      return { submitted: true };
    });
  };
}
module.exports = { createPollAnswerHandler, validateAnswers };
