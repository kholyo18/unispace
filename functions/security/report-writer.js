const { HttpsError } = require('firebase-functions/v2/https');
const { Timestamp } = require('firebase-admin/firestore');
const contentReasons = ['abuse','sexual','academic/exam_leak','academic/cheating','academic/misinfo','spam','impersonation','hate','other'];
const accountReasons = ['impersonation','fake','harassment','inappropriate_profile','spam','hate','other'];
const text = (v, max) => typeof v === 'string' ? v.slice(0, max) : '';
async function writeReport({tx, db, FieldValue, uid, type, targetId, postId, ownerId, ownerName, snapshot, reason, details}) {
  if (ownerId === uid) throw new HttpsError('invalid-argument', 'Cannot report yourself.');
  const ref = db.collection('community_reports').doc(uid + '_' + type + '_' + targetId);
  const quotaRef = db.collection('communityReportLimits').doc(uid);
  const [existing, quota] = await tx.getAll(ref, quotaRef);
  if (existing.exists) {
    const old = existing.data();
    if (old.reporterId !== uid || old.type !== type || old.targetId !== targetId ||
        (type === 'comment' && (old.parentId ?? old.postId) !== postId)) {
      throw new HttpsError('failed-precondition', 'Report identity mismatch.');
    }
    return { submitted: true, alreadyReported: true };
  }
  const now = Date.now(), q = quota.data();
  const active = Number.isFinite(q?.windowStart) && now < q.windowStart + 60000;
  const count = active && Number.isSafeInteger(q.count) ? q.count : 0;
  if (count >= 60) throw new HttpsError('resource-exhausted', 'Wait before reporting again.');
  const severity = ['academic/exam_leak','academic/cheating','hate','harassment'].includes(reason) ? 'P1'
    : ['abuse','sexual','academic/misinfo','impersonation','inappropriate_profile'].includes(reason) ? 'P2' : 'P3';
  const payload = { type, targetId, reporterId: uid, ownerId, ownerName, snapshot, reason,
    details: details.trim(), severity, status: 'pending', createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(), history: [{action: 'reported', by: uid, at: Timestamp.now()}] };
  if (type === 'comment') Object.assign(payload, { postId, parentId: postId, commentId: targetId });
  tx.create(ref, payload);
  tx.set(quotaRef, { windowStart: active ? q.windowStart : now, count: count + 1 });
  return { submitted: true, alreadyReported: false };
}
module.exports = { writeReport, contentReasons, accountReasons, text };
