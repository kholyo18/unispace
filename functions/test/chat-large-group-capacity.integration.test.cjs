// Only local emulators are permitted by notification-fixture.cjs.
const test = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {createChatHandlers} = require('../security/chat-service');
const {createSignInSessionHandler} = require('../security/device-sessions');
const {createChatViewOnceHandlers} = require('../security/chat-view-once');
const {createStorageUploadHandler} = require('../security/storage-upload');
const {createChatNotificationHandler,chatNotificationId,chatPushAllowed} = require('../security/chat-push');
const {db,auth,FieldValue,Timestamp,project,fixture,callableRequest,close} = require('./helpers/notification-fixture.cjs');
const handlers = createChatHandlers({db,auth,FieldValue});
test.after(close);
async function setup() {
  const result = await fixture();
  for (const user of [result.actor,result.owner,result.outsider]) {
    const issued = await createSignInSessionHandler({db,FieldValue})({data:{uid:user.uid},eventId:randomUUID()});
    user.sid = issued.sessionClaims.sid;
    await auth.setCustomUserClaims(user.uid,{sid:user.sid});
    const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`,{
      method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:await auth.createCustomToken(user.uid),returnSecureToken:true}),
    });
    assert.equal(response.status,200);
    user.token=(await response.json()).idToken;
    await db.doc(`users/${user.uid}`).set({privacy:{whoCanMessage:'everyone'}},{merge:true});
  }
  return result;
}

test('35-member accepted group can send, grant media, and fan out; outsider and blocks still denied',async()=>{
  const {actor,owner,outsider}=await setup();
  const extra=[];
  for(let i=0;i<33;i++) {
    const user=await auth.createUser({uid:'capacity_'+randomUUID().replaceAll('-','')});
    extra.push(user.uid);
    await db.doc(`users/${user.uid}`).set({displayName:'Capacity recipient',accountStatus:'active',privacy:{whoCanMessage:'everyone'}});
  }
  const memberIds=[actor.uid,owner.uid,...extra],chatId='capacity_'+randomUUID().replaceAll('-','');
  assert.equal(memberIds.length,35);
  const ref=db.doc(`chats/${chatId}`);
  await ref.set({type:'group',name:'Local capacity fixture',memberIds,adminIds:[actor.uid],
    members:Object.fromEntries(memberIds.map(uid=>[uid,{name:'Local member'}])),
    unread:Object.fromEntries(memberIds.map(uid=>[uid,0]))});
  const input={chatId,messageId:'large_send',message:{type:'text',text:'Capacity regression'}};
  await handlers.send(callableRequest(actor,input));
  await handlers.send(callableRequest(actor,input));
  const chat=(await ref.get()).data();
  for(const uid of memberIds)assert.equal(chat.unread[uid],uid===actor.uid?0:1);
  assert.equal((await ref.collection('messages').doc(input.messageId).get()).data().serverDelivery,true);
  const grant=createStorageUploadHandler({db,auth,FieldValue,Timestamp,bucketName:()=>`${project}.appspot.com`});
  const upload={path:`chats/${chatId}/images/capacity.jpg`,contentType:'image/jpeg',size:128,expectedUid:actor.uid};
  assert.equal((await grant(callableRequest(actor,upload))).path,upload.path);
  await createChatNotificationHandler({db,FieldValue})({params:{chatId,messageId:input.messageId},data:await ref.collection('messages').doc(input.messageId).get()});
  const notificationId=chatNotificationId(chatId,input.messageId);
  assert.equal((await db.doc(`users/${extra.at(-1)}/notifications/${notificationId}`).get()).exists,true);
  assert.equal((await db.doc(`users/${outsider.uid}/notifications/${notificationId}`).get()).exists,false);
  await assert.rejects(handlers.send(callableRequest(outsider,{...input,messageId:'outsider'})),{code:'permission-denied'});
  await assert.rejects(grant(callableRequest(outsider,{...upload,expectedUid:outsider.uid})),{code:'permission-denied'});
  // Storage itself is mocked; actual auth, session, group authorization,
  // recipient binding and exactly-once consumption use local emulators.
  const storage={name:`${project}.appspot.com`,file:(path,options)=>({path,options,
    getMetadata:async()=>[{generation:'42',size:'4',contentType:'image/jpeg'}],
    getSignedUrl:async()=>['https://example.invalid/local-only-signed-upload'],
  })};
  const viewOnce=createChatViewOnceHandlers({db,auth,FieldValue,Timestamp,bucket:()=>storage,prepareUpload:grant});
  const mediaId=randomUUID(),photoId='large_photo';
  await viewOnce.prepare(callableRequest(actor,{chatId,mediaId,size:4,contentType:'image/jpeg'}));
  await createChatHandlers({db,auth,FieldValue,viewOnce}).send(callableRequest(actor,{
    chatId,messageId:photoId,message:{type:'viewOnce',mediaId},
  }));
  const asset=(await db.doc(`chatViewOnceAssets/${mediaId}`).get()).data();
  assert.equal(asset.recipients.length,34);
  const consume={headers:{authorization:`Bearer ${owner.token}`},body:{chatId,messageId:photoId}};
  assert.equal((await viewOnce.consume(consume)).size,4);
  await assert.rejects(viewOnce.consume(consume),{code:'already-exists'});
  await db.doc(`users/${owner.uid}/blocked_accounts/${actor.uid}`).set({});
  await assert.rejects(handlers.send(callableRequest(actor,{...input,messageId:'blocked'})),{code:'permission-denied'});
  await assert.rejects(grant(callableRequest(actor,upload)),{code:'permission-denied'});
  const notification=(await db.doc(`users/${owner.uid}/notifications/${notificationId}`).get()).data();
  assert.equal(await chatPushAllowed({db,userId:owner.uid,notification,notificationId}),false);
});

test('legacy direct chat without type can send, while duplicate membership is rejected',async()=>{
  const {actor,owner}=await setup();
  const {chatId}=await handlers.open(callableRequest(actor,{peerId:owner.uid}));
  const ref=db.doc(`chats/${chatId}`);
  await ref.update({type:FieldValue.delete()});
  await handlers.send(callableRequest(actor,{chatId,messageId:'legacy_send',message:{type:'text',text:'Legacy direct'}}));
  assert.equal((await ref.get()).data().unread[owner.uid],1);
  await ref.update({memberIds:[actor.uid,actor.uid]});
  await assert.rejects(handlers.send(callableRequest(actor,{chatId,messageId:'invalid',message:{type:'text',text:'deny'}})),{code:'permission-denied'});
});

