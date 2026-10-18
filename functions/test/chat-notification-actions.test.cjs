const test=require('node:test'),assert=require('node:assert/strict');
const {db,auth,FieldValue,fixture,callableRequest,close}=require('./helpers/notification-fixture.cjs');
const {createSignInSessionHandler}=require('../security/device-sessions');
const {createChatHandlers}=require('../security/chat-service');
const {createChatNotificationHandler,chatNotificationId}=require('../security/chat-push');
const {createChatNotificationActionHandler}=require('../security/chat-notification-actions');
const {createSyncPushDeviceHandler}=require('../security/push-preferences');
const {createPushNotificationHandler}=require('../security/push-notification');
const chat=createChatHandlers({db,auth,FieldValue}),action=createChatNotificationActionHandler({db,auth,chatHandlers:chat});
test.after(close);
async function setup(){const f=await fixture();for(const u of [f.owner,f.actor,f.outsider]){const issued=await createSignInSessionHandler({db,FieldValue})({data:{uid:u.uid},eventId:`notification-action-${u.uid}`});u.sid=issued.sessionClaims.sid;await auth.setCustomUserClaims(u.uid,{sid:u.sid});const response=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:await auth.createCustomToken(u.uid),returnSecureToken:true})});u.token=(await response.json()).idToken;await db.doc(`users/${u.uid}`).set({privacy:{whoCanMessage:'everyone'}},{merge:true});}
f.chatId=(await chat.open(callableRequest(f.actor,{peerId:f.owner.uid}))).chatId;f.messageId='source';
await chat.send(callableRequest(f.actor,{chatId:f.chatId,messageId:f.messageId,message:{type:'text',text:'Private source content'}}));
await createChatNotificationHandler({db,FieldValue})({params:{chatId:f.chatId,messageId:f.messageId},data:await db.doc(`chats/${f.chatId}/messages/${f.messageId}`).get()});
f.notificationId=chatNotificationId(f.chatId,f.messageId);f.input={chatId:f.chatId,messageId:f.messageId,notificationId:f.notificationId};return f;}
test('explicit reply is deduplicated across retries and uses authoritative reply source',async()=>{
 const f=await setup(),input={...f.input,action:'reply',text:' Thanks '};const first=await action(callableRequest(f.owner,input)),again=await action(callableRequest(f.owner,input));assert.equal(first.messageId,again.messageId);
 const sent=(await db.doc(`chats/${f.chatId}/messages/${first.messageId}`).get()).data();assert.equal(sent.authorId,f.owner.uid);assert.equal(sent.text,'Thanks');assert.equal(sent.replyToAuthorId,f.actor.uid);
 assert.equal((await db.doc(`chats/${f.chatId}`).get()).data().unread[f.actor.uid],1);
});
test('mark read is bounded to notification source and never clears newer arrivals',async()=>{
 const f=await setup();await chat.send(callableRequest(f.actor,{chatId:f.chatId,messageId:'newer',message:{type:'text',text:'Newer'}}));
 await action(callableRequest(f.owner,{...f.input,action:'markRead'}));const state=(await db.doc(`chats/${f.chatId}`).get()).data(),source=(await db.doc(`chats/${f.chatId}/messages/source`).get()).data();
 assert.equal(state.unread[f.owner.uid],1);assert.equal(state.lastReadAt[f.owner.uid].toMillis(),source.createdAt.toMillis());assert.equal((await db.doc(`users/${f.owner.uid}/notifications/${f.notificationId}`).get()).data().read,true);
 await action(callableRequest(f.owner,{...f.input,action:'markRead'}));assert.equal((await db.doc(`chats/${f.chatId}`).get()).data().unread[f.owner.uid],1);
});
test('mark read respects hidden receipts and a stale action cannot increase unread count',async()=>{
 const f=await setup();await db.doc(`users/${f.owner.uid}`).set({privacy:{readReceipts:false}},{merge:true});await chat.send(callableRequest(f.actor,{chatId:f.chatId,messageId:'newer',message:{type:'text',text:'New'}}));
 await db.doc(`chats/${f.chatId}`).set({unread:{[f.owner.uid]:0}},{merge:true});await action(callableRequest(f.owner,{...f.input,action:'markRead'}));const c=(await db.doc(`chats/${f.chatId}`).get()).data();assert.equal(c.unread[f.owner.uid],0);assert.equal(c.lastReadAt?.[f.owner.uid],undefined);
});
test('outsider, forged anchor, block and revoked session cannot mutate via a notification',async()=>{
 const f=await setup(),input={...f.input,action:'reply',text:'Unauthorized'};
 await assert.rejects(action(callableRequest(f.outsider,input)),{code:'permission-denied'});
 await assert.rejects(action(callableRequest(f.owner,{...input,messageId:'other'})),{code:'invalid-argument'});
 const block=db.doc(`users/${f.actor.uid}/blocked_accounts/${f.owner.uid}`);await block.set({});await assert.rejects(action(callableRequest(f.owner,input)),{code:'permission-denied'});await block.delete();
 await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({isRevoked:true});await assert.rejects(action(callableRequest(f.owner,{...f.input,action:'markRead'})),{code:'unauthenticated'});
});
test('deleted source and admin-only groups cannot be bypassed by quick reply',async()=>{
 const f=await setup();await db.doc(`chats/${f.chatId}`).update({type:'group',adminsOnlyMessaging:true,adminIds:[f.actor.uid]});
 await assert.rejects(action(callableRequest(f.owner,{...f.input,action:'reply',text:'Blocked'})),{code:'permission-denied'});
 await action(callableRequest(f.owner,{...f.input,action:'markRead'}));
 await db.doc(`chats/${f.chatId}/messages/source`).delete();await assert.rejects(action(callableRequest(f.owner,{...f.input,action:'reply',text:'Deleted'})),{code:'permission-denied'});
});
test('only capable Android devices receive data-only chat notifications; legacy previews stay private',async()=>{
 const f=await setup(),sync=createSyncPushDeviceHandler({db,auth,FieldValue}),preferences={enabled:true,community:true,announcements:true,exams:true};
 for(const [suffix,platform,version]of [['legacy','android',undefined],['modern','android',1],['ios','iOS',1]])await sync(callableRequest(f.owner,{token:f.owner.uid+'_'+suffix,sessionId:f.owner.sid,platform,preferences,locale:'fr',...(version===undefined?{}:{chatActionsVersion:version})}));
 await assert.rejects(sync(callableRequest(f.owner,{token:'invalid',sessionId:f.owner.sid,platform:'android',preferences,chatActionsVersion:2})),{code:'invalid-argument'});
 const calls=[],push=createPushNotificationHandler({db,auth,messaging:{sendEachForMulticast:async value=>{calls.push(value);return {responses:value.tokens.map(()=>({success:true}))};}}});
 await push({params:{userId:f.owner.uid,notifId:f.notificationId},data:await db.doc(`users/${f.owner.uid}/notifications/${f.notificationId}`).get()});
 const modern=calls.find(c=>c.tokens.some(t=>t.endsWith('_modern'))),legacy=calls.find(c=>c.tokens.some(t=>t.endsWith('_legacy'))),ios=calls.find(c=>c.tokens.some(t=>t.endsWith('_ios')));
 assert.equal(modern.notification,undefined);assert.equal(modern.data.chatActionsVersion,'1');assert.equal(legacy.notification.body,'Vous avez un nouveau message');assert.equal(ios.notification.title,'UniSpace');
 assert.equal(JSON.stringify(calls).includes('Private source content'),false);assert.equal(modern.data.actorName,'');
});
