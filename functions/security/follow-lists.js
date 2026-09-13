const { HttpsError } = require('firebase-functions/v2/https');
const { FieldPath } = require('firebase-admin/firestore');

const validId = value => typeof value === 'string' && value.length > 0 && value.length <= 128 &&
  !value.includes('/') && !['.', '..'].includes(value);
const unavailable = data => !data || ['disabled', 'deleted'].includes(data.accountStatus) || data.security?.frozen === true;
const blockPaths = (a, b) => ['blocked_accounts', 'blocked_users', 'blocked_by'].flatMap(c => [
  `users/${a}/${c}/${b}`, `users/${b}/${c}/${a}`,
]);
const str = value => typeof value === 'string' ? value.trim() : '';

function canReadList(data, kind, self, following, followedBy) {
  if (self) return true;
  const p = data.privacy || {};
  const privateAccount = typeof p.privateAccount === 'boolean' ? p.privateAccount : data.profileVisibility === 'private';
  if (privateAccount && !following) return false;
  const audience = p[kind === 'followers' ? 'followersVisibility' : 'followingVisibility'] ?? 'everyone';
  return audience === 'everyone' || (audience === 'followers' && following) ||
    (audience === 'mutual' && following && followedBy);
}

function createFollowListHandler({ auth, db }) {
  return async request => {
    const uid = request.auth?.uid;
    const header = request.rawRequest?.headers?.authorization || '';
    if (!uid || !header.startsWith('Bearer ')) throw new HttpsError('unauthenticated', 'Sign in first.');
    const input = request.data;
    if (!input || typeof input !== 'object' || Array.isArray(input) ||
        Object.keys(input).some(k => !['userId', 'kind', 'offset'].includes(k)) ||
        !validId(input.userId) || !['followers', 'following'].includes(input.kind) ||
        !Number.isInteger(input.offset) || input.offset < 0 || input.offset > 10000 || input.offset % 50 !== 0) {
      throw new HttpsError('invalid-argument', 'Invalid list request.');
    }
    let token;
    try { token = await auth.verifyIdToken(header.slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) {
      throw new HttpsError('unauthenticated', 'Invalid session.');
    }
    let account;
    try { account = await auth.getUser(input.userId); }
    catch (error) {
      if (error.code === 'auth/user-not-found') throw new HttpsError('not-found', 'List unavailable.');
      throw new HttpsError('unavailable', 'Try again later.');
    }
    if (account.disabled) throw new HttpsError('not-found', 'List unavailable.');
    const result = await db.runTransaction(async tx => {
      const owner = input.userId;
      const refs = [`authRevocations/${uid}`, `users/${owner}`, `users/${owner}/followers/${uid}`,
        `users/${uid}/followers/${owner}`, ...blockPaths(uid, owner)];
      const [cutoff, profile, follower, reverse, ...blocks] = await tx.getAll(...refs.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) {
        throw new HttpsError('unauthenticated', 'Session revoked.');
      }
      if (unavailable(profile.data()) || (uid !== owner && blocks.some(b => b.exists))) {
        throw new HttpsError('not-found', 'List unavailable.');
      }
      if (!canReadList(profile.data(), input.kind, uid === owner, follower.exists, reverse.exists)) {
        throw new HttpsError('permission-denied', 'This list is private.');
      }
      const page = await tx.get(db.collection(`users/${owner}/${input.kind}`)
        .orderBy(FieldPath.documentId()).offset(input.offset).limit(50));
      const items = [];
      for (const relation of page.docs) {
        const id = relation.id;
        if (!validId(id)) continue;
        const paths = [`users/${id}`, `users/${id}/followers/${uid}`, `users/${uid}/followers/${id}`,
          `users/${id}/follow_requests/${uid}`, `users/${id}/followers/${owner}`, ...blockPaths(uid, id)];
        const [person, iFollow, followsMe, pending, authoritative, ...personBlocks] = await tx.getAll(...paths.map(p => db.doc(p)));
        const data = person.data();
        if (unavailable(data) || (id !== uid && personBlocks.some(b => b.exists))) continue;
        // A following mirror alone is not evidence of an accepted relationship.
        if (input.kind === 'following' && !authoritative.exists) continue;
        const name = [str(data.firstName), str(data.lastName)].filter(Boolean).join(' ') ||
          str(data.displayName) || str(data.userName) || str(data.name) || str(data.username) || 'طالب UniSpace';
        items.push({ id, name, photoUrl: str(data.profileImageUrl) || null,
          createdAtMs: typeof relation.data().createdAt?.toMillis === 'function' ? relation.data().createdAt.toMillis() : 0,
          iFollow: iFollow.exists, followsMe: followsMe.exists,
          pending: !iFollow.exists && pending.exists && pending.data().status === 'pending' });
      }
      // Numeric offsets do not expose IDs of filtered-out members in a cursor.
      return { items, nextOffset: page.size === 50 && input.offset < 10000 ? input.offset + 50 : null,
        truncated: page.size === 50 && input.offset === 10000 };
    });
    if (result.items.length) {
      const accounts = await auth.getUsers(result.items.map(p => ({ uid: p.id })));
      const enabled = new Set(accounts.users.filter(a => !a.disabled).map(a => a.uid));
      result.items = result.items.filter(p => enabled.has(p.id));
    }
    return result;
  };
}

module.exports = { createFollowListHandler, canReadList };
