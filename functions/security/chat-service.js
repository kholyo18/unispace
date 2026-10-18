const {assertChatAccount}=require('./chat-account');
const {assertGroupMessage}=require('./chat-groups');
const {createHash}=require('node:crypto');
const { HttpsError } = require('firebase-functions/v2/https');
const { assertActiveSession } = require('./device-sessions');
const id = v => typeof v === 'string' && /^[A-Za-z0-9_-]{1,260}$/.test(v);
const fail = (code, text) => { throw new HttpsError(code, text); };
// Membership has no product-level total cap; platform document limits still apply.
const validChatMembers = chat => !!chat && (chat.type===undefined || ['direct','group'].includes(chat.type)) &&
  Array.isArray(chat.memberIds) && (chat.type==='group'?chat.memberIds.length>=1:chat.memberIds.length===2) &&
  chat.memberIds.every(id) && new Set(chat.memberIds).size===chat.memberIds.length;
async function assertActiveChatRecipients(auth, recipients) {
  // Firebase Auth accepts at most 100 identifiers per lookup.
  for(let offset=0;offset<recipients.length;offset+=100){
    let result;
    try{result=await auth.getUsers(recipients.slice(offset,offset+100).map(uid=>({uid})));}
    catch(_){fail('permission-denied','Recipient unavailable.');}
    if(result.notFound.length||result.users.some(user=>user.disabled))fail('permission-denied','Recipient unavailable.');
  }
}
function nextChatUnread(chat, senderId) {
  // Transaction-owned numeric writes avoid one field transform per recipient
  // (Firestore caps transforms per document), while retaining atomic retries.
  return Object.fromEntries(chat.memberIds.filter(uid=>uid!==senderId).map(uid=>{
    const old=chat.unread?.[uid];
    return [uid,typeof old==='number'&&Number.isFinite(old)?old+1:1];
  }));
}
const directId = (a,b) => [a,b].sort().join('_');
const requestMatches=(r,a,b,requestId)=>r && requestId===directId(a,b) && ((r.senderId===a&&r.receiverId===b)||(r.senderId===b&&r.receiverId===a));
const requestAccepted=(r,a,b,requestId)=>requestMatches(r,a,b,requestId)&&r.status==='accepted';
function cleanMessage(raw, chatId, projectId) {
  if (!raw || Array.isArray(raw) || typeof raw !== 'object') fail('invalid-argument','Message required.');
  if (['contact','poll','event'].includes(raw.type)) {
    const keys={contact:['type','contactName','contactPhone'],poll:['type','question','optionsJson'],event:['type','title','startsAtMs','place','description']}[raw.type];
    if(Object.keys(raw).some(k=>!keys.includes(k))) fail('invalid-argument','Unsupported message field.');
    const text=(value,max,optional=false)=>{
      if(optional&&value===undefined)return undefined;
      if(typeof value!=='string'||value.length>max||(!optional&&!value.trim())||/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(value))fail('invalid-argument','Invalid message content.');
      return value.trim();
    };
    if(raw.type==='contact') {
      const contactName=text(raw.contactName,120),phone=text(raw.contactPhone,40).replace(/[٠-٩۰-۹]/g,c=>String(c.charCodeAt(0)-(c<='٩'?0x660:0x6f0))).replace(/[ ()-]/g,'');
      if(!/^\+?[0-9]{6,15}$/.test(phone))fail('invalid-argument','Invalid phone number.');
      return {type:'contact',contactName,contactPhone:phone};
    }
    if(raw.type==='poll') {
      const question=text(raw.question,300);let options;
      if(typeof raw.optionsJson!=='string'||raw.optionsJson.length>2000)fail('invalid-argument','Invalid options.');
      try{options=JSON.parse(raw.optionsJson);}catch(_){fail('invalid-argument','Invalid options.');}
      if(!Array.isArray(options)||options.length<2||options.length>8)fail('invalid-argument','Invalid options.');
      options=options.map(v=>text(v,120));
      if(new Set(options.map(v=>v.normalize('NFKC').toLowerCase())).size!==options.length)fail('invalid-argument','Duplicate options.');
      return {type:'poll',question,optionsJson:JSON.stringify(options)};
    }
    if(!Number.isSafeInteger(raw.startsAtMs)||raw.startsAtMs<0||raw.startsAtMs>253402300799999)fail('invalid-argument','Invalid event date.');
    const result={type:'event',title:text(raw.title,120),startsAtMs:raw.startsAtMs};
    for(const [key,max] of [['place',200],['description',1000]]){const value=text(raw[key],max,true);if(value)result[key]=value;}
    return result;
  }
  if (raw.type === 'viewOnce') {
    if (Object.keys(raw).some(k=>!['type','mediaId'].includes(k)) || typeof raw.mediaId !== 'string' || !/^[A-Za-z0-9_-]{20,80}$/.test(raw.mediaId)) fail('invalid-argument','Invalid private photo.');
    return {type:'viewOnce',mediaId:raw.mediaId};
  }
  const allowed = ['caption','thumbnailUrl','type','text','imageUrl','gifUrl','videoUrl','audioUrl','fileUrl','fileName','size','durationMs','mimeType','replyToId','replyToText','replyToAuthorId','replyToName'];
  if (Object.keys(raw).some(k=>!allowed.includes(k))) fail('invalid-argument','Unsupported message field.');
  const fields = {text:'text',image:'imageUrl',gif:'gifUrl',video:'videoUrl',audio:'audioUrl',file:'fileUrl'};
  const field = fields[raw.type];
  if (!field || typeof raw[field] !== 'string' || !raw[field].trim() || raw[field].length > (field==='text'?10000:4096)) fail('invalid-argument','Invalid message content.');
  for(const [key,value] of Object.entries(raw)) {
    if (['size','durationMs'].includes(key)) { if(!Number.isSafeInteger(value)||value<0||value>1024*1024*1024) fail('invalid-argument','Invalid media metadata.'); }
    else if(typeof value!=='string'||value.length>10000) fail('invalid-argument','Invalid message metadata.');
  }
  if(field!=='text') {
    let url; try{url=new URL(raw[field]);}catch(_){fail('invalid-argument','Invalid attachment.');}
    let path;try{path=decodeURIComponent(url.pathname);}catch(_){fail('invalid-argument','Invalid attachment.');}
    if(projectId&&!['.appspot.com','.firebasestorage.app'].some(s=>path.startsWith('/v0/b/'+projectId+s+'/o/')))fail('invalid-argument','Attachment must belong to this application.');
    if(url.protocol!=='https:'||url.hostname!=='firebasestorage.googleapis.com'||!/^\/v0\/b\/[^/]+\/o\//.test(path)||!path.slice(path.indexOf('/o/')+3).startsWith(`chats/${chatId}/`)) fail('invalid-argument','Attachment must belong to this conversation.');
  }
  if (raw.caption !== undefined && (!['image','gif','video'].includes(raw.type) || typeof raw.caption !== 'string' || raw.caption.length>1000)) fail('invalid-argument','Invalid caption.');
  if (raw.thumbnailUrl !== undefined) {
    if(raw.type!=='video') fail('invalid-argument','Invalid thumbnail.');
    const thumbnail=cleanMessage({type:'image',imageUrl:raw.thumbnailUrl},chatId,projectId);
    if(!decodeURIComponent(new URL(thumbnail.imageUrl).pathname).includes('/o/chats/'+chatId+'/images/')) fail('invalid-argument','Invalid thumbnail path.');
  }
  // Quoted identity/text are derived from the original message, never trusted input.
  const result = {...raw,[field]:raw[field].trim()};
  for(const k of ['replyToText','replyToAuthorId','replyToName']) delete result[k];
  if(result.replyToId&&!id(result.replyToId)) fail('invalid-argument','Invalid reply.');
  return result;
}
const preview = m => m.type==='text'?m.text:({contact:'👤 جهة اتصال',poll:'📊 استطلاع',event:'📅 حدث',viewOnce:'① صورة',image:'📷 صورة',gif:'GIF',video:'🎬 فيديو',audio:'🎤 رسالة صوتية',file:`📎 ${m.fileName||'ملف'}`})[m.type];
function createChatHandlers({db,auth,FieldValue,viewOnce}) {
  async function identity(request) {
    const uid=request.auth?.uid, header=request.rawRequest?.headers?.authorization;
    if(!id(uid)||!header?.startsWith('Bearer ')) fail('unauthenticated','Sign in first.');
    let token;try{token=await auth.verifyIdToken(header.slice(7),true);}catch(_){fail('unauthenticated','Sign in again.');}
    if(token.uid!==uid) fail('unauthenticated','Invalid session.');
    return {uid,token};
  }
  async function pair(tx,token,peer) {
    const uid=token.uid;
    await assertActiveSession({db,token,reader:tx});
    if(!id(peer)||peer===uid) fail('invalid-argument','Invalid recipient.');
    const refs=[db.doc(`users/${uid}`),db.doc(`users/${peer}`),db.doc(`users/${peer}/followers/${uid}`),db.doc(`users/${uid}/followers/${peer}`)];
    for(const [a,b] of [[uid,peer],[peer,uid]]) for(const c of ['blocked_accounts','blocked_users','blocked_by']) refs.push(db.doc(`users/${a}/${c}/${b}`));
    const [own,other,follows,followed,...blocks]=await tx.getAll(...refs);
    if(!own.exists||!other.exists||[own,other].some(s=>['disabled','deleted'].includes(s.data().accountStatus)||s.data().security?.frozen===true)||blocks.some(s=>s.exists)) fail('permission-denied','Messaging unavailable.');
    await assertChatAccount({db,tx,uid,profile:own.data()});
    await assertChatAccount({db,tx,uid:peer,profile:other.data()});
    const privacy=other.data().privacy||{},who=privacy.whoCanMessage||'mutual';
    return {own:own.data(),other:other.data(),who,direct:who==='everyone'||who==='followers'&&follows.exists||who==='mutual'&&follows.exists&&followed.exists,requests:privacy.messageRequests!==false};
  }
  function chatData(uid,peer,p) {
    const brief=d=>({name:[d.firstName,d.lastName].filter(Boolean).join(' ')||d.displayName||d.userName||'',photoUrl:d.profileImageUrl||null});
    return {type:'direct',memberIds:[uid,peer],members:{[uid]:brief(p.own),[peer]:brief(p.other)},createdAt:FieldValue.serverTimestamp(),lastMessageAt:FieldValue.serverTimestamp(),unread:{[uid]:0,[peer]:0}};
  }
  async function getChat(tx,chatId,uid) {
    if(!id(chatId)) fail('invalid-argument','Invalid conversation.');
    const ref=db.doc(`chats/${chatId}`),snap=await tx.get(ref),data=snap.data();
    if(!snap.exists||!validChatMembers(data)||!data.memberIds.includes(uid)) fail('permission-denied','Conversation unavailable.');
    return {ref,data,peer:data.memberIds.find(x=>x!==uid)};
  }
  const open = async request => {
    const {uid,token}=await identity(request),peer=request.data?.peerId;
    if(!id(peer)||peer===uid) fail('invalid-argument','Invalid recipient.');
    let user;try{user=await auth.getUser(peer);}catch(_){fail('permission-denied','Recipient unavailable.');}
    if(user.disabled) fail('permission-denied','Recipient unavailable.');
    const chatId=directId(uid,peer);
    return db.runTransaction(async tx=>{
      const p=await pair(tx,token,peer),ref=db.doc(`chats/${chatId}`),rr=db.doc(`messageRequests/${chatId}`);
      const [chat,req]=await tx.getAll(ref,rr);
      if(req.exists&&!requestMatches(req.data(),uid,peer,chatId))fail('permission-denied','Invalid message request.');
      const accepted=requestAccepted(req.data(),uid,peer,chatId) && p.who!=='none';
      if(!p.direct&&!accepted){
        if(p.who==='none'||!p.requests) fail('permission-denied','Recipient does not accept messages.');
        if(req.exists&&req.data().status==='rejected') fail('permission-denied','Message request declined.');
        if(!req.exists){
          const limitRef=db.doc(`chatRequestLimits/${uid}`),limit=(await tx.get(limitRef)).data(),now=Date.now(),active=limit&&now-limit.windowStart<60000;
          if(active&&limit.count>=20)fail('resource-exhausted','Please wait before requesting more conversations.');
          tx.set(limitRef,{windowStart:active?limit.windowStart:now,count:active?limit.count+1:1});
          tx.create(rr,{senderId:uid,receiverId:peer,status:'pending',createdAt:FieldValue.serverTimestamp(),senderName:p.own.displayName||p.own.userName||'',senderPhotoUrl:p.own.profileImageUrl||null});
        }
        return {chatId,status:'pending'};
      }
      if(!chat.exists)tx.create(ref,chatData(uid,peer,p));
      else if(!chat.data().memberIds?.includes(uid)||!chat.data().memberIds?.includes(peer))fail('permission-denied','Invalid conversation.');
      return {chatId,status:'open'};
    });
  };
  const send=async request=>{
    const {uid,token}=await identity(request),{chatId,messageId,message}=request.data||{};
    if(!id(messageId))fail('invalid-argument','Message id required.');
    const clean=cleanMessage(message,chatId,db.projectId);
    const fingerprint=createHash('sha256').update(JSON.stringify(Object.fromEntries(Object.entries(clean).sort(([a],[b])=>a.localeCompare(b))))).digest('hex');
    if(!id(chatId))fail('invalid-argument','Invalid conversation.');
    const initial=(await db.doc(`chats/${chatId}`).get()).data();
    if(!validChatMembers(initial)||!initial.memberIds.includes(uid))fail('permission-denied','Conversation unavailable.');
    const checkedRecipients=initial.memberIds.filter(x=>x!==uid);
    let photoGeneration;
    if(clean.type==='viewOnce') {
      if(!viewOnce)fail('unavailable','Private photos unavailable.');
      // Idempotent confirmation is still authorized below, even after expiry.
      const sentReceipt=await db.doc(`chats/${chatId}/sendReceipts/${messageId}`).get();
      if(!sentReceipt.exists)photoGeneration=await viewOnce.prepareForSend({uid,chatId,mediaId:clean.mediaId});
    }
    await assertActiveChatRecipients(auth,checkedRecipients);
    return db.runTransaction(async tx=>{
      const chat=await getChat(tx,chatId,uid),group=chat.data.type==='group';
      if(chat.data.memberIds.some(x=>x!==uid&&!checkedRecipients.includes(x)))fail('aborted','Group membership changed. Retry sending.');
      const p=group?null:await pair(tx,token,chat.peer);
      if(group)await assertGroupMessage({db,tx,token,chat:chat.data});
      const ref=chat.ref.collection('messages').doc(messageId);
      const limitRef=db.doc(`chatMessageLimits/${uid}`);
      const receiptRef=chat.ref.collection('sendReceipts').doc(messageId);
      const [old,req,limit,receipt]=await tx.getAll(ref,db.doc(`messageRequests/${chatId}`),limitRef,receiptRef);
      if(!group&&!p.direct&&!(requestAccepted(req.data(),uid,chat.peer,chatId)&&p.who!=='none'))fail('permission-denied','Messaging not allowed.');
      if(receipt.exists){if(receipt.data().authorId!==uid||receipt.data().fingerprint!==fingerprint)fail('already-exists','Message id in use.');return {messageId};}
      if(old.exists)fail('already-exists','Message id in use.');
      if(clean.type==='event'&&(clean.startsAtMs<=Date.now()||clean.startsAtMs>Date.now()+366*86400000))fail('invalid-argument','Event must start within the next year.');
      const now=Date.now(),current=limit.data(),active=current&&now-current.windowStart<60000;
      if(active&&current.count>=60)fail('resource-exhausted','Please wait before sending more messages.');
      if(clean.replyToId){const quoted=await tx.get(chat.ref.collection('messages').doc(clean.replyToId));if(!quoted.exists)fail('invalid-argument','Reply unavailable.');clean.replyToText=quoted.data().text||preview(quoted.data())||'';clean.replyToAuthorId=quoted.data().authorId;clean.replyToName=chat.data.members?.[quoted.data().authorId]?.name||'';}
      const bindPhoto=clean.type==='viewOnce'?await viewOnce.bindForSend({tx,uid,chatId,messageId,mediaId:clean.mediaId,generation:photoGeneration,memberIds:chat.data.memberIds}):null;
      if(bindPhoto)bindPhoto();
      tx.create(receiptRef,{authorId:uid,fingerprint,createdAt:FieldValue.serverTimestamp()});
      tx.set(limitRef,{windowStart:active?current.windowStart:now,count:active?current.count+1:1});
      tx.create(ref,{...clean,...(clean.type==='poll'?{votes:{},text:clean.question}:clean.type==='event'?{attendees:{},text:clean.title}:clean.type==='contact'?{text:clean.contactName+' '+clean.contactPhone}:{}),authorId:uid,serverDelivery:true,createdAt:FieldValue.serverTimestamp()});
      tx.set(chat.ref,{lastMessage:preview(clean),lastMessageId:messageId,lastMessageAt:FieldValue.serverTimestamp(),lastSenderId:uid,unread:nextChatUnread(chat.data,uid),...Object.fromEntries(chat.data.memberIds.filter(x=>x!==uid).map(x=>[`deletedBy_${x}`,false]))},{merge:true});
      return {messageId};
    });
  };
  const respond=async request=>{
    const {uid,token}=await identity(request),{requestId,action}=request.data||{};
    if(!id(requestId)||!['accept','reject'].includes(action))fail('invalid-argument','Invalid response.');
    return db.runTransaction(async tx=>{
      await assertActiveSession({db,token,reader:tx});
      const ref=db.doc(`messageRequests/${requestId}`),snap=await tx.get(ref),r=snap.data();
      if(!r||r.receiverId!==uid||!id(r.senderId)||!requestMatches(r,uid,r.senderId,requestId))fail('permission-denied','Request unavailable.');
      if(r.status!=='pending'&&r.status!==(action==='accept'?'accepted':'rejected'))fail('failed-precondition','Request already answered.');
      const p=await pair(tx,token,r.senderId),chatId=directId(uid,r.senderId),chatRef=db.doc(`chats/${chatId}`),chat=await tx.get(chatRef);
      if(action==='accept'&&!chat.exists)tx.create(chatRef,chatData(uid,r.senderId,p));
      tx.update(ref,{status:action==='accept'?'accepted':'rejected',updatedAt:FieldValue.serverTimestamp()});
      return {chatId,status:action==='accept'?'open':'rejected'};
    });
  };
  const mutate=async request=>{
    const {uid,token}=await identity(request),{chatId,messageId,action,text}=request.data||{};
    if(!id(messageId)||!['edit','delete'].includes(action)||action==='edit'&&(typeof text!=='string'||!text.trim()||text.length>10000))fail('invalid-argument','Invalid message change.');
    return db.runTransaction(async tx=>{
      await assertActiveSession({db,token,reader:tx});
      const chat=await getChat(tx,chatId,uid),ref=chat.ref.collection('messages').doc(messageId),snap=await tx.get(ref);
      if(!snap.exists){if(action==='delete')return {messageId};fail('not-found','Message missing.');}
      if(snap.data().authorId!==uid)fail('permission-denied','Only your own messages may be changed.');
      if(action==='edit'){if(chat.data.type==='group')await assertGroupMessage({db,tx,token,chat:chat.data});else{const p=await pair(tx,token,chat.peer),req=await tx.get(db.doc(`messageRequests/${chatId}`));if(!p.direct&&!(requestAccepted(req.data(),uid,chat.peer,chatId)&&p.who!=='none'))fail('permission-denied','Messaging not allowed.');}}
      if(action==='edit'&&snap.data().type!=='text')fail('invalid-argument','Only text can be edited.');
      const latest=await tx.get(chat.ref.collection('messages').orderBy('createdAt','desc').limit(2));
      if(action==='edit')tx.update(ref,{text:text.trim(),editedAt:FieldValue.serverTimestamp()});else tx.delete(ref);
      if(chat.data.lastMessageId===messageId||latest.docs[0]?.id===messageId){
        const previous=latest.docs.find(d=>d.id!==messageId);
        tx.update(chat.ref,action==='edit'?{lastMessage:text.trim()}:{lastMessage:previous?preview(previous.data()):'',lastMessageId:previous?.id||null,lastSenderId:previous?.data().authorId||null,...(previous?{lastMessageAt:previous.data().createdAt}:{})});
      }
      return {messageId};
    });
  };
  // Responses share the edit authorization boundary and replace only this user's entry.
  // No client-provided counters are accepted, so retries never inflate totals.
  const respondToRichMessage=async(request,type)=>{
    const {uid,token}=await identity(request),data=request.data||{}, {chatId,messageId}=data;
    const keys=type==='poll'?['chatId','messageId','optionIndex']:['chatId','messageId','attending'];
    if(Object.keys(data).some(k=>!keys.includes(k))||!id(messageId))fail('invalid-argument','Invalid response.');
    if(type==='poll'&&(!Number.isInteger(data.optionIndex)||data.optionIndex<0||data.optionIndex>7)||type==='event'&&typeof data.attending!=='boolean')fail('invalid-argument','Invalid response.');
    return db.runTransaction(async tx=>{
      const chat=await getChat(tx,chatId,uid);
      if(chat.data.type==='group')await assertGroupMessage({db,tx,token,chat:chat.data,enforcePosting:false});
      else {
        const p=await pair(tx,token,chat.peer),req=await tx.get(db.doc(`messageRequests/${chatId}`));
        if(!p.direct&&!(requestAccepted(req.data(),uid,chat.peer,chatId)&&p.who!=='none'))fail('permission-denied','Messaging not allowed.');
      }
      const ref=chat.ref.collection('messages').doc(messageId),snap=await tx.get(ref),message=snap.data();
      if(!snap.exists)fail('not-found','Message missing.');
      if(message.deleted===true||message.deletedAt||message.hiddenBy?.[uid]===true||Array.isArray(message.hiddenBy)&&message.hiddenBy.includes(uid))fail('not-found','Message unavailable.');
      if(message.type!==type)fail('failed-precondition','Message type mismatch.');
      if(type==='poll') {
        let options;try{options=JSON.parse(message.optionsJson);}catch(_){fail('failed-precondition','Invalid poll.');}
        if(!Array.isArray(options)||data.optionIndex>=options.length)fail('invalid-argument','Invalid option.');
      }
      const field=type==='poll'?'votes':'attendees',value=type==='poll'?data.optionIndex:data.attending;
      tx.update(ref,{[field]:{...(message[field]||{}),[uid]:value}});
      return {messageId};
    });
  };
  const vote=request=>respondToRichMessage(request,'poll');
  const respondEvent=request=>respondToRichMessage(request,'event');
  return {open,send,respond,mutate,vote,respondEvent};
}
module.exports={createChatHandlers,cleanMessage,directId,requestAccepted,validChatMembers,assertActiveChatRecipients,nextChatUnread};

