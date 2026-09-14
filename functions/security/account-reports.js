const { HttpsError } = require('firebase-functions/v2/https');
const { createPublicProfileHandler, projectProfile } = require('./public-profile');
const { writeReport, accountReasons, text } = require('./report-writer');
const unavailable = d => !d || ['disabled','deleted'].includes(d.accountStatus) || d.security?.frozen === true;
function createAccountReportHandler({auth, db, FieldValue}) {
  const readProfile = createPublicProfileHandler({auth, db});
  return async request => {
    const input = request.data, uid = request.auth?.uid;
    if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== 3 ||
        !accountReasons.includes(input.reason) || typeof input.details !== 'string' || input.details.length > 10000) {
      throw new HttpsError('invalid-argument', 'Invalid report.');
    }
    // Validates the target ID, current Firebase Auth state, blocks and session.
    await readProfile({...request, data: {userId: input.userId}});
    let token;
    try { token = await auth.verifyIdToken((request.rawRequest?.headers?.authorization || '').slice(7), true); }
    catch (_) { throw new HttpsError('unauthenticated', 'Sign in again.'); }
    if (token.uid !== uid || !Number.isFinite(token.auth_time) || token.firebase?.tenant) throw new HttpsError('unauthenticated', 'Invalid session.');
    return db.runTransaction(async tx => {
      const target = input.userId;
      const paths = ['authRevocations/' + uid, 'users/' + uid, 'users/' + target,
        'users/' + target + '/followers/' + uid,
        ...['blocked_accounts','blocked_users','blocked_by'].flatMap(c => [
          'users/' + uid + '/' + c + '/' + target, 'users/' + target + '/' + c + '/' + uid])];
      const [cutoff, actor, owner, follower, ...blocks] = await tx.getAll(...paths.map(p => db.doc(p)));
      if (cutoff.exists && token.auth_time <= cutoff.data().revokedBefore) throw new HttpsError('unauthenticated', 'Session revoked.');
      if (unavailable(actor.data()) || unavailable(owner.data()) || blocks.some(b => b.exists)) throw new HttpsError('permission-denied', 'Profile unavailable.');
      // A private profile can be reported using only its visible profile fields.
      const p = projectProfile(owner.data(), {self: uid === target, following: follower.exists});
      const name = text(p.displayName || [p.firstName, p.lastName].filter(Boolean).join(' '), 200);
      return writeReport({tx, db, FieldValue, uid, type: 'user', targetId: target, ownerId: target,
        ownerName: name, reason: input.reason, details: input.details,
        snapshot: {displayName: name, username: text(p.username, 200), photoUrl: text(p.profileImageUrl, 4096), mood: text(p.mood, 2000)} });
    });
  };
}
module.exports = { createAccountReportHandler };
