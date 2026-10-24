const test=require('node:test'),assert=require('node:assert/strict');
const {createGroupHandlers}=require('../security/chat-groups');
const {createChatHandlers}=require('../security/chat-service');
const {db,auth,FieldValue,fixture,callableRequest,close,read,denied}=require('./helpers/notification-fixture.cjs');
const {createSignInSessionHandler}=require('../security/device-sessions');
const groups=createGroupHandlers({db,auth,FieldValue}),chats=createChatHandlers({db,auth,FieldValue});
async function setup(){const f=await fixture();for(const u of [f.owner,f.actor,f.outsider]){const issued=await createSignInSessionHandler({db,FieldValue})({data:{uid:u.uid},eventId:`group-access-${u.uid}`});u.sid=issued.sessionClaims.sid;await auth.setCustomUserClaims(u.uid,{sid:u.sid});const response=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:await auth.createCustomToken(u.uid),returnSecureToken:true})});u.token=(await response.json()).idToken;await db.doc(`users/${u.uid}`).set({privacy:{whoCanMessage:'everyone'}},{merge:true});}f.chatId='group_access_'+f.actor.uid;await groups.create(callableRequest(f.actor,{groupId:f.chatId,name:'Private group',memberIds:[]}));return f;}
const link=f=>groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'rotateLink'}));
const join=(f,token,user=f.owner)=>groups.requestJoin(callableRequest(user,{chatId:f.chatId,token}));
const review=(f,approve=true,user=f.actor)=>groups.reviewJoinRequest(callableRequest(user,{chatId:f.chatId,requesterId:f.owner.uid,approve}));
test.after(close);
test('links contain random bearer tokens stored only as hashes and are administrator-only',async()=>{
 const f=await setup(),l=await link(f);assert.match(l.token,/^[a-f0-9]{64}$/);assert.equal(new URL(l.link).searchParams.get('token'),l.token);
 const data=(await db.doc('groupInviteLinks/'+f.chatId).get()).data();assert.notEqual(data.tokenHash,l.token);assert.equal(JSON.stringify(data).includes(l.token),false);
 await assert.rejects(groups.access(callableRequest(f.owner,{chatId:f.chatId,action:'rotateLink'})),{code:'permission-denied'});
 denied(await read('groupInviteLinks/'+f.chatId,f.actor));
 await assert.rejects(groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'setMessaging',adminsOnly:'true'})),{code:'invalid-argument'});
});
test('link requests grant no messages until current administrator approves; retries are idempotent',async()=>{
 const f=await setup(),l=await link(f);assert.equal((await join(f,l.token)).status,'pending');await join(f,l.token);
 denied(await read('chats/'+f.chatId,f.owner));denied(await read(`groupJoinRequests/${f.chatId}/requests/${f.owner.uid}`,f.owner));
 const rows=await groups.listJoinRequests(callableRequest(f.actor,{chatId:f.chatId}));assert.equal(rows.requests.length,1);assert.equal(rows.requests[0].uid,f.owner.uid);
 await assert.rejects(groups.listJoinRequests(callableRequest(f.outsider,{chatId:f.chatId})),{code:'permission-denied'});
 await assert.rejects(review(f,true,f.outsider),{code:'permission-denied'});
 await review(f);await review(f);assert.equal((await db.doc('chats/'+f.chatId).get()).data().memberIds.filter(x=>x===f.owner.uid).length,1);
 assert.equal((await groups.listJoinRequests(callableRequest(f.actor,{chatId:f.chatId}))).requests.length,0);
});
test('rotation, revocation and expiration deny old links and approval of stale pending requests',async()=>{
 const f=await setup(),old=await link(f);await join(f,old.token);const fresh=await link(f);
 await assert.rejects(join(f,old.token),{code:'failed-precondition'});await assert.rejects(review(f),{code:'failed-precondition'});
 await review(f,false);await join(f,fresh.token);
 await groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'revokeLink'}));await assert.rejects(review(f),{code:'failed-precondition'});
 const next=await link(f);await db.doc('groupInviteLinks/'+f.chatId).update({expiresAtMs:Date.now()-1});await assert.rejects(join(f,next.token),{code:'failed-precondition'});
});
test('demoting the link issuer invalidates access and revoked sessions cannot manage links',async()=>{
 const f=await setup();await groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'invite',memberId:f.outsider.uid}));await groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'promote',memberId:f.outsider.uid}));
 const l=await link(f);await groups.manage(callableRequest(f.outsider,{chatId:f.chatId,action:'demote',memberId:f.actor.uid}));
 await assert.rejects(join(f,l.token),{code:'failed-precondition'});await assert.rejects(link(f),{code:'permission-denied'});
 await groups.manage(callableRequest(f.outsider,{chatId:f.chatId,action:'promote',memberId:f.actor.uid}));
 await assert.rejects(join(f,l.token),{code:'failed-precondition'});
 await db.doc(`users/${f.outsider.uid}/sessions/${f.outsider.sid}`).update({isRevoked:true});
 await assert.rejects(groups.access(callableRequest(f.outsider,{chatId:f.chatId,action:'rotateLink'})),{code:'unauthenticated'});
});
test('blocks, privacy and disabled accounts remain authoritative at request and approval',async()=>{
 const f=await setup(),l=await link(f),block=db.doc(`users/${f.actor.uid}/blocked_accounts/${f.owner.uid}`);
 await block.set({});await assert.rejects(join(f,l.token),{code:'permission-denied'});await block.delete();
 await db.doc(`users/${f.owner.uid}`).set({privacy:{whoCanMessage:'none'}},{merge:true});await assert.rejects(join(f,l.token),{code:'permission-denied'});
 await db.doc(`users/${f.owner.uid}`).set({privacy:{whoCanMessage:'everyone'}},{merge:true});await join(f,l.token);await block.set({});await assert.rejects(review(f),{code:'permission-denied'});await block.delete();
 await auth.updateUser(f.owner.uid,{disabled:true});await assert.rejects(review(f),{code:'permission-denied'});
});
test('admin-only posting blocks regular members and can be reverted without altering membership',async()=>{
 const f=await setup();await groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'invite',memberId:f.owner.uid}));
 await groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'setMessaging',adminsOnly:true}));
 const send=(user,id)=>chats.send(callableRequest(user,{chatId:f.chatId,messageId:id,message:{type:'text',text:'Message'}}));
 await assert.rejects(send(f.owner,'denied'),{code:'permission-denied'});await send(f.actor,'allowed');
 await assert.rejects(groups.access(callableRequest(f.owner,{chatId:f.chatId,action:'setMessaging',adminsOnly:false})),{code:'permission-denied'});
 await groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'setMessaging',adminsOnly:false}));await send(f.owner,'restored');
});
test('join request spam budget survives idempotent retries and rejection requires a new link',async()=>{
 const f=await setup(),l=await link(f);await join(f,l.token);
 await db.doc('groupJoinRequestLimits/'+f.owner.uid).set({windowStart:Date.now(),count:20});await join(f,l.token);
 await review(f,false);await assert.rejects(join(f,l.token),{code:'permission-denied'});
 const next=await link(f);await assert.rejects(join(f,next.token),{code:'resource-exhausted'});
});
test('approval reconciles an existing direct invitation without duplicate membership',async()=>{
 const f=await setup(),l=await link(f);await db.doc(`groupInvites/${f.chatId}_${f.owner.uid}`).set({chatId:f.chatId,senderId:f.actor.uid,receiverId:f.owner.uid,status:'pending'});await db.doc('chats/'+f.chatId).update({pendingMemberIds:[f.owner.uid]});await join(f,l.token);await review(f);
 await groups.respond(callableRequest(f.owner,{chatId:f.chatId,action:'accept'}));
 const c=(await db.doc('chats/'+f.chatId).get()).data();assert.equal(c.memberIds.filter(x=>x===f.owner.uid).length,1);assert.equal(c.pendingMemberIds.includes(f.owner.uid),false);
});

test('ordinary members can vote and RSVP in administrator-only groups',async()=>{
 const f=await setup();await groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'invite',memberId:f.owner.uid}));
 await groups.access(callableRequest(f.actor,{chatId:f.chatId,action:'setMessaging',adminsOnly:true}));
 await chats.send(callableRequest(f.actor,{chatId:f.chatId,messageId:'poll',message:{type:'poll',question:'When?',optionsJson:'["Today","Tomorrow"]'}}));
 await chats.send(callableRequest(f.actor,{chatId:f.chatId,messageId:'event',message:{type:'event',title:'Study',startsAtMs:Date.now()+86400000}}));
 await chats.vote(callableRequest(f.owner,{chatId:f.chatId,messageId:'poll',optionIndex:1}));
 await chats.respondEvent(callableRequest(f.owner,{chatId:f.chatId,messageId:'event',attending:true}));
 assert.equal((await db.doc('chats/'+f.chatId+'/messages/poll').get()).data().votes[f.owner.uid],1);
 assert.equal((await db.doc('chats/'+f.chatId+'/messages/event').get()).data().attendees[f.owner.uid],true);
});

test('only a current administrator can assign their finalized group image',async()=>{
 const f=await setup();
 const name='demo-unispace-security.appspot.com';
 const url=`https://firebasestorage.googleapis.com/v0/b/${name}/o/${encodeURIComponent(`chats/${f.chatId}/images/group.jpg`)}`;
 const metadata={size:'100',generation:'42',contentType:'image/jpeg',metadata:{protectedUploadVersion:'1',uploadedBy:f.actor.uid,uploadGrantId:'abcdefghijklmnopqrst'}};
 const handler=createGroupHandlers({db,auth,FieldValue,bucket:()=>({name,file:()=>({getMetadata:async()=>[metadata]})})});
 await handler.manage(callableRequest(f.actor,{chatId:f.chatId,action:'photo',photoUrl:url}));
 assert.equal((await db.doc('chats/'+f.chatId).get()).data().photoUrl,url);
 await assert.rejects(handler.manage(callableRequest(f.owner,{chatId:f.chatId,action:'photo',photoUrl:url})),{code:'permission-denied'});
 await assert.rejects(handler.manage(callableRequest(f.actor,{chatId:f.chatId,action:'photo',photoUrl:url.replace('group.jpg','other.jpg').replace(encodeURIComponent(f.chatId),'foreign')})),{code:'invalid-argument'});
 metadata.metadata.uploadedBy=f.owner.uid;
 await assert.rejects(handler.manage(callableRequest(f.actor,{chatId:f.chatId,action:'photo',photoUrl:url})),{code:'permission-denied'});
});
test('adding a person checks blocks with existing members, not only the administrator',async()=>{
 const f=await setup();
 await groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'invite',memberId:f.owner.uid}));
 await db.doc(`users/${f.owner.uid}/blocked_accounts/${f.outsider.uid}`).set({});
 await assert.rejects(groups.manage(callableRequest(f.actor,{chatId:f.chatId,action:'invite',memberId:f.outsider.uid})),{code:'permission-denied'});
 assert.equal((await db.doc('chats/'+f.chatId).get()).data().memberIds.includes(f.outsider.uid),false);
});
