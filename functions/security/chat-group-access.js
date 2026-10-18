const {randomBytes,createHash}=require('node:crypto');
const {HttpsError}=require('firebase-functions/v2/https');
const {assertActiveSession}=require('./device-sessions');
const bad=(code,message)=>{throw new HttpsError(code,message);};
const validId=v=>typeof v==='string'&&/^[A-Za-z0-9_-]{1,260}$/.test(v);
const digest=value=>createHash('sha256').update(value).digest('hex');
const strict=(data,keys)=>{if(!data||Array.isArray(data)||typeof data!=='object'||Object.keys(data).some(k=>!keys.includes(k)))bad('invalid-argument','Invalid group request.');};

function createGroupAccessHandlers({db,FieldValue,identity,groupId,available,groupPair,assertChatAccount}) {
  async function current(tx,token,chatId,admin=false){
    await assertActiveSession({db,token,reader:tx});
    const ref=db.doc(`chats/${chatId}`),snap=await tx.get(ref),chat=snap.data();
    if(chat?.type!=='group'||!Array.isArray(chat.memberIds)||!chat.memberIds.length)bad('permission-denied','Group unavailable.');
    if(admin&&(!chat.memberIds.includes(token.uid)||!chat.adminIds?.includes(token.uid)))bad('permission-denied','Group administrator required.');
    const own=await tx.get(db.doc(`users/${token.uid}`));
    await assertChatAccount({db,tx,uid:token.uid,profile:own.data()});
    return {ref,chat,own:own.data()};
  }
  const linkRef=chatId=>db.doc(`groupInviteLinks/${chatId}`);
  const requestRef=(chatId,uid)=>db.doc(`groupJoinRequests/${chatId}/requests/${uid}`);
  function activeLink(link,chat,hash){
    if(!link?.active||link.tokenHash!==hash||link.expiresAtMs<=Date.now()||!chat.memberIds.includes(link.issuerUid)||!chat.adminIds?.includes(link.issuerUid))bad('failed-precondition','Invitation link is unavailable.');
  }
  async function joinBudget(tx,uid){
    const ref=db.doc(`groupJoinRequestLimits/${uid}`),old=(await tx.get(ref)).data(),now=Date.now(),active=old&&now-old.windowStart<60000;
    if(active&&old.count>=20)bad('resource-exhausted','Wait before requesting more groups.');
    return ()=>tx.set(ref,{windowStart:active?old.windowStart:now,count:active?old.count+1:1});
  }
  const access=async request=>{
    const {uid,token}=await identity(request),data=request.data||{};
    strict(data,['chatId','action','adminsOnly']);const chatId=groupId(data.chatId),action=data.action;
    if(!['rotateLink','revokeLink','setMessaging'].includes(action)||action==='setMessaging'&&typeof data.adminsOnly!=='boolean'||action!=='setMessaging'&&data.adminsOnly!==undefined)bad('invalid-argument','Invalid group setting.');
    const secret=action==='rotateLink'?randomBytes(32).toString('hex'):null;
    return db.runTransaction(async tx=>{
      const {ref}=await current(tx,token,chatId,true);
      if(action==='setMessaging') {tx.update(ref,{adminsOnlyMessaging:data.adminsOnly});return {chatId,adminsOnly:data.adminsOnly};}
      if(action==='revokeLink'){tx.set(linkRef(chatId),{active:false,updatedAt:FieldValue.serverTimestamp()},{merge:true});return {chatId,active:false};}
      const expiresAtMs=Date.now()+7*86400000;
      tx.set(linkRef(chatId),{tokenHash:digest(secret),issuerUid:uid,active:true,expiresAtMs,createdAt:FieldValue.serverTimestamp()});
      return {chatId,token:secret,expiresAtMs,link:`unispace://group/join?groupId=${encodeURIComponent(chatId)}&token=${secret}`};
    });
  };
  const requestJoin=async request=>{
    const {uid,token}=await identity(request),data=request.data||{};strict(data,['chatId','token']);
    const chatId=groupId(data.chatId);
    if(typeof data.token!=='string'||! /^[a-f0-9]{64}$/.test(data.token))bad('invalid-argument','Invalid invitation link.');
    const hash=digest(data.token);
    return db.runTransaction(async tx=>{
      const {chat,own}=await current(tx,token,chatId),ref=requestRef(chatId,uid);
      const [link,snap]=await tx.getAll(linkRef(chatId),ref);activeLink(link.data(),chat,hash);
      if(chat.memberIds.includes(uid))return {chatId,status:'open'};
      for(const peer of chat.memberIds)await groupPair({db,tx,sender:uid,receiver:peer});
      await groupPair({db,tx,sender:link.data().issuerUid,receiver:uid,invitation:true});
      if(snap.data()?.linkHash===hash){if(snap.data().status==='rejected')bad('permission-denied','Join request declined.');if(snap.data().status==='pending')return {chatId,status:'pending'};}
      const commitBudget=await joinBudget(tx,uid);commitBudget();
      tx.set(ref,{uid,name:[own.firstName,own.lastName].filter(Boolean).join(' ')||own.displayName||own.userName||'',status:'pending',linkHash:hash,createdAt:FieldValue.serverTimestamp()});
      return {chatId,status:'pending'};
    });
  };
  const listJoinRequests=async request=>{
    const {token}=await identity(request),data=request.data||{};strict(data,['chatId']);const chatId=groupId(data.chatId);
    return db.runTransaction(async tx=>{
      await current(tx,token,chatId,true);
      const snap=await tx.get(db.collection(`groupJoinRequests/${chatId}/requests`).where('status','==','pending').limit(50));
      return {chatId,requests:snap.docs.map(d=>({uid:d.id,name:d.data().name||''})),hasMore:snap.size===50};
    });
  };
  const reviewJoinRequest=async request=>{
    const {uid,token}=await identity(request),data=request.data||{};strict(data,['chatId','requesterId','approve']);
    const chatId=groupId(data.chatId),target=data.requesterId;
    if(!validId(target)||typeof data.approve!=='boolean')bad('invalid-argument','Invalid join response.');
    if(data.approve)await available(target);
    return db.runTransaction(async tx=>{
      const {ref,chat}=await current(tx,token,chatId,true),joinRef=requestRef(chatId,target);
      const directInviteRef=db.doc(`groupInvites/${chatId}_${target}`);
      const [snapshot,link,directInvite]=await tx.getAll(joinRef,linkRef(chatId),directInviteRef),join=snapshot.data();
      if(!join||join.uid!==target)bad('not-found','Join request unavailable.');
      const status=data.approve?'approved':'rejected';
      if(join.status===status)return {chatId,status};
      if(join.status!=='pending')bad('failed-precondition','Join request already reviewed.');
      if(data.approve){
        activeLink(link.data(),chat,join.linkHash);
        await groupPair({db,tx,sender:uid,receiver:target,invitation:true});
        for(const peer of chat.memberIds.filter(x=>x!==target))await groupPair({db,tx,sender:target,receiver:peer});
        const profile=(await tx.get(db.doc(`users/${target}`))).data();
        if(!chat.memberIds.includes(target))tx.update(ref,{memberIds:[...chat.memberIds,target],pendingMemberIds:(chat.pendingMemberIds||[]).filter(x=>x!==target),[`pendingMembers.${target}`]:FieldValue.delete(),[`members.${target}`]:{name:[profile.firstName,profile.lastName].filter(Boolean).join(' ')||profile.displayName||profile.userName||'',photoUrl:profile.profileImageUrl||null},[`unread.${target}`]:0});
      }
      if(data.approve&&directInvite.data()?.receiverId===target&&directInvite.data()?.status==='pending')tx.update(directInviteRef,{status:'accepted',updatedAt:FieldValue.serverTimestamp()});
      tx.update(joinRef,{status,reviewedBy:uid,reviewedAt:FieldValue.serverTimestamp()});
      return {chatId,status};
    });
  };
  return {access,requestJoin,listJoinRequests,reviewJoinRequest};
}
module.exports={createGroupAccessHandlers};
