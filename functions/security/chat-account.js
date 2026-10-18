const {HttpsError}=require('firebase-functions/v2/https');
const {readState}=require('./account-state-policy');
// Read canonical controls in the same transaction as the message/group mutation.
async function assertChatAccount({db,tx,uid,profile}) {
  const [control,deletion]=await tx.getAll(db.doc(`accountStateControls/${uid}`),db.doc(`account_deletion_requests/${uid}`));
  let state;
  try { state=readState(profile,control.data(),deletion.exists); }
  catch (_) { throw new HttpsError('permission-denied','Account unavailable.'); }
  if(state.selfDisabled||state.selfFrozen||state.adminSuspended) throw new HttpsError('permission-denied','Account unavailable.');
}
module.exports={assertChatAccount};
