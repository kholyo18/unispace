const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath } = require('firebase-admin/firestore');

const text = value => typeof value === 'string' ? value.trim() : '';
function normalize(value) {
  return value.toLowerCase().replace(/[\u064B-\u065F\u0670]/g, '')
    .replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي').replace(/ة/g, 'ه').replace(/[^\w\u0600-\u06FF]+/g, ' ')
    .replace(/\s+/g, ' ').trim();
}
const stop = new Set(['في', 'من', 'على', 'الى', 'الي', 'عن', 'مع', 'ما', 'لا',
  'ان', 'او', 'و', 'هذا', 'هذه', 'ذلك', 'the', 'and']);
function matchPerson(id, data, query) {
  const privacy = data.privacy || {};
  if (privacy.appearInSearch === false || data.security?.frozen === true ||
      ['disabled', 'deleted'].includes(data.accountStatus)) return null;
  const first = text(data.firstName), last = text(data.lastName);
  const display = text(data.displayName) || text(data.userName) || text(data.name);
  const username = text(data.username) || text(data.userName);
  const name = [first, last].filter(Boolean).join(' ') || display || username;
  if (!name) return null;
  const tokens = normalize(query).split(' ').filter(t => t.length >= 2 && !stop.has(t));
  const words = normalize(`${name} ${username} ${display}`).split(' ');
  const nameHit = tokens.length ? tokens.every(t => words.some(w => w === t ||
    (t.length >= 4 && w.startsWith(t)) || w === `${t}s` || w === `${t}es`)) :
    !!normalize(query) && normalize(`${name} ${username}`).includes(normalize(query));
  // Contact discovery is opt-in and exact: never allow partial address/number enumeration.
  const emailHit = query.includes('@') && privacy.findByEmail === true &&
    text(data.email).toLowerCase() === query.toLowerCase();
  const phoneHit = privacy.findByPhone === true && !!text(data.phone) && text(data.phone) === query;
  if (!nameHit && !emailHit && !phoneHit) return null;
  return { id, name, username: username || null, photoUrl: text(data.profileImageUrl) || null };
}

function createSearchPeopleHandler({ auth, db, now = Date.now }) {
  return async request => {
    const uid = request.auth?.uid;
    const header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 1 ||
        typeof input.query !== 'string' || !input.query.trim() || input.query.length > 160) {
      throw new HttpsError('invalid-argument', 'A search query of at most 160 characters is required.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    const cutoffRef = db.doc(`authRevocations/${uid}`);
    const checkCutoff = cutoff => {
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) {
        throw new HttpsError('unauthenticated', 'Session revoked.');
      }
    };
    // Bound the cost of the legacy scan until an indexed directory is introduced.
    await db.runTransaction(async tx => {
      const limitRef = db.doc(`peopleSearchLimits/${uid}`);
      const [cutoff, limit] = await tx.getAll(cutoffRef, limitRef);
      checkCutoff(cutoff);
      const timestamp = now();
      const previous = limit.data();
      const active = previous && timestamp < previous.windowStart + 60000;
      const count = active ? previous.count : 0;
      if (count >= 20) throw new HttpsError('resource-exhausted', 'Please wait before searching again.');
      tx.set(limitRef, { windowStart: active ? previous.windowStart : timestamp, count: count + 1 });
    });
    const people = [];
    const query = input.query.trim();
    let last;
    let truncated = false;
    for (let page = 0; page < 8 && people.length < 8; page++) {
      let scan = db.collection('users').orderBy(FieldPath.documentId()).limit(120);
      if (last) scan = scan.startAfter(last);
      const snapshot = await scan.get();
      if (snapshot.empty) break;
      const candidates = snapshot.docs.filter(doc => doc.id !== uid && matchPerson(doc.id, doc.data(), query));
      // Auth batch lookup excludes disabled/deleted accounts without one network request per user.
      const enabled = new Set();
      for (let offset = 0; offset < candidates.length; offset += 100) {
        const accounts = await auth.getUsers(candidates.slice(offset, offset + 100).map(doc => ({ uid: doc.id })));
        for (const account of accounts.users) if (!account.disabled) enabled.add(account.uid);
      }
      for (const candidate of candidates) {
        if (!enabled.has(candidate.id)) continue;
        const person = await db.runTransaction(async tx => {
          const target = candidate.id;
          const paths = ['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(collection => [
            `users/${uid}/${collection}/${target}`, `users/${target}/${collection}/${uid}`,
          ]);
          const [cutoff, profile, ...blocks] = await tx.getAll(cutoffRef, candidate.ref, ...paths.map(p => db.doc(p)));
          checkCutoff(cutoff);
          if (!profile.exists || blocks.some(doc => doc.exists)) return null;
          // Re-evaluate consent and the match with fresh data in the block-check transaction.
          return matchPerson(target, profile.data(), query);
        });
        if (person) people.push(person);
        if (people.length === 8) break;
      }
      last = snapshot.docs[snapshot.docs.length - 1];
      truncated = snapshot.size === 120 || people.length === 8;
      if (snapshot.size < 120) break;
    }
    checkCutoff(await cutoffRef.get());
    return { people, truncated };
  };
}

module.exports = { createSearchPeopleHandler, matchPerson };
