const {requestAccepted,validChatMembers}=require('./chat-service');
const {createHash}=require('node:crypto');
const validId=v=>typeof v==='string'&&/^[A-Za-z0-9_-]{1,260}$/.test(v);
const chatNotificationId=(chatId,messageId)=>'chat_'+createHash('sha256').update(JSON.stringify([chatId,messageId])).digest('hex');
async function chatPushAllowed({db,userId,notification,notificationId}) {
  const {chatId,messageId,actorId}=notification;
  if(![chatId,messageId,actorId,userId].every(validId)||notificationId!==chatNotificationId(chatId,messageId)||actorId===userId)return false;
  const [chat,message]=await db.getAll(db.doc(`chats/${chatId}`),db.doc(`chats/${chatId}/messages/${messageId}`));
  const c=chat.data(),m=message.data();
  if(!validChatMembers(c)||!c.memberIds.includes(userId)||!c.memberIds.includes(actorId)||m?.authorId!==actorId||m.serverDelivery!==true)return false;
  const [recipient,actor,follower,reverse,request,...blocks]=await db.getAll(db.doc(`users/${userId}`),db.doc(`users/${actorId}`),db.doc(`users/${userId}/followers/${actorId}`),db.doc(`users/${actorId}/followers/${userId}`),db.doc(`messageRequests/${chatId}`),...['blocked_accounts','blocked_users','blocked_by'].flatMap(k=>[db.doc(`users/${userId}/${k}/${actorId}`),db.doc(`users/${actorId}/${k}/${userId}`)]));
  if([recipient,actor].some(p=>!p.exists||['deleted','disabled'].includes(p.data().accountStatus)||p.data().security?.frozen===true)||blocks.some(p=>p.exists))return false;
  const who=recipient.data().privacy?.whoCanMessage||'mutual';
  if(who==='none'||c.type!=='group'&&!(who==='everyone'||who==='followers'&&follower.exists||who==='mutual'&&follower.exists&&reverse.exists||requestAccepted(request.data(),actorId,userId,chatId)))return false;
  if(c.muted?.[userId]===true||c[`muted_${userId}`]===true)return false;
  if(c.lastReadAt?.[userId]?.toMillis()>=m.createdAt?.toMillis())return false;
  return true;
}
function createChatNotificationHandler({db,FieldValue}) {
  return async event=>{
    if(!event.data)return;
    const {chatId,messageId}=event.params,source=event.data.data();
    if(!validId(chatId)||!validId(messageId)||source.serverDelivery!==true)return;
    const chat=(await db.doc(`chats/${chatId}`).get()).data();
    if(!validChatMembers(chat)||!chat.memberIds.includes(source.authorId))return;
    for(const userId of chat.memberIds.filter(x=>x!==source.authorId)){
    if(!validId(userId))continue;
    const notificationId=chatNotificationId(chatId,messageId);
    const data={type:'message',chatId,messageId,actorId:source.authorId,actorIds:[source.authorId],actorName:chat.members?.[source.authorId]?.name||'UniSpace',read:false,createdAt:FieldValue.serverTimestamp(),message:''};
    if(!await chatPushAllowed({db,userId,notification:data,notificationId}))continue;
    try{await db.doc(`users/${userId}/notifications/${notificationId}`).create(data);}catch(error){if(error.code!==6)throw error;}
    }
  };
}
module.exports={createChatNotificationHandler,chatPushAllowed,chatNotificationId};
