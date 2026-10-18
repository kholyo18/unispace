const {HttpsError}=require('firebase-functions/v2/https');
const {createHash}=require('node:crypto');
const {assertActiveSession}=require('./device-sessions');
const {assertGroupMessage}=require('./chat-groups');
const {validChatMembers}=require('./chat-service');
const {chatNotificationId}=require('./chat-push');
const validId=v=>typeof v==='string'&&/^[A-Za-z0-9_-]{1,260}$/.test(v);
const fail=(code,message)=>{throw new HttpsError(code,message);};
function createChatNotificationActionHandler({db,auth,chatHandlers}){
 return async request=>{
  const uid=request.auth?.uid,header=request.rawRequest?.headers?.authorization,input=request.data;
  if(!validId(uid)||!header?.startsWith('Bearer '))fail('unauthenticated','Sign in first.');
  let token;try{token=await auth.verifyIdToken(header.slice(7),true);}catch(_){fail('unauthenticated','Sign in again.');}
  if(token.uid!==uid)fail('unauthenticated','Invalid session.');
  if(!input||Array.isArray(input)||Object.keys(input).some(k=>!['notificationId','chatId','messageId','action','text'].includes(k))||
   ![input.notificationId,input.chatId,input.messageId].every(validId)||!['reply','markRead'].includes(input.action)||
   input.notificationId!==chatNotificationId(input.chatId,input.messageId))fail('invalid-argument','Invalid notification action.');
  if(input.action==='reply'&&(typeof input.text!=='string'||!input.text.trim()||input.text.length>10000)||input.action==='markRead'&&input.text!==undefined)fail('invalid-argument','Invalid reply.');
  const notificationRef=db.doc(`users/${uid}/notifications/${input.notificationId}`),chatRef=db.doc(`chats/${input.chatId}`),messageRef=chatRef.collection('messages').doc(input.messageId);
  await db.runTransaction(async tx=>{
   await assertActiveSession({db,token,reader:tx});
   const [notification,chat,message]=await tx.getAll(notificationRef,chatRef,messageRef),n=notification.data(),c=chat.data(),m=message.data();
   if(n?.type!=='message'||n.chatId!==input.chatId||n.messageId!==input.messageId||!m||m.authorId!==n.actorId||m.authorId===uid||m.serverDelivery!==true||m.deleted===true||m.isDeleted===true||m.hiddenBy?.[uid]===true)fail('permission-denied','Notification unavailable.');
   if(!validChatMembers(c)||!c.memberIds.includes(uid))fail('permission-denied','Conversation unavailable.');
   await assertGroupMessage({db,tx,token,chat:{...c,type:'group'},enforcePosting:input.action==='reply'});
   if(input.action!=='markRead')return;
   const stamp=m.createdAt;
   if(!stamp||typeof stamp.toMillis!=='function')fail('failed-precondition','Message is not ready.');
   const own=(await tx.get(db.doc(`users/${uid}`))).data();
   const previous=c.lastReadAt?.[uid],alreadyRead=typeof previous?.toMillis==='function'&&previous.toMillis()>=stamp.toMillis();
   // A stale notification must not clear arrivals newer than its source message.
   // For exceptionally old notifications keep a conservative unread count.
   const newer=await tx.get(chatRef.collection('messages').where('createdAt','>',stamp).limit(500));
   if(!alreadyRead){
    const change={};
    if(newer.size<500)change[`unread.${uid}`]=Math.min(Number.isSafeInteger(c.unread?.[uid])&&c.unread[uid]>=0?c.unread[uid]:Number.MAX_SAFE_INTEGER,newer.docs.filter(d=>d.data().authorId!==uid).length);
    if(own?.privacy?.readReceipts!==false)change[`lastReadAt.${uid}`]=stamp;
    if(Object.keys(change).length)tx.update(chatRef,change);
   }
   tx.update(notificationRef,{read:true});
  });
  if(input.action==='reply'){
   const text=input.text.trim();
   const messageId='notification_reply_'+createHash('sha256').update(JSON.stringify([uid,input.notificationId,text])).digest('hex');
   await chatHandlers.send({...request,data:{chatId:input.chatId,messageId,message:{type:'text',text,replyToId:input.messageId}}});
   return {action:'reply',messageId};
  }
  return {action:'markRead',notificationId:input.notificationId};
 };
}
module.exports={createChatNotificationActionHandler};
