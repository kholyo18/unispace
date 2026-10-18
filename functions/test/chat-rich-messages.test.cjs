const test=require('node:test'),assert=require('node:assert/strict');
const {createChatHandlers,cleanMessage}=require('../security/chat-service');
const {db,auth,FieldValue,fixture,callableRequest,close,patch,denied}=require('./helpers/notification-fixture.cjs');
const {createSignInSessionHandler}=require('../security/device-sessions');
const handlers=createChatHandlers({db,auth,FieldValue});
const poll={type:'poll',question:'When?',optionsJson:'["Today","Tomorrow"]'};
const event={type:'event',title:'Study',startsAtMs:Date.now()+86400000,place:'Library'};
async function setup(){const f=await fixture();for(const u of [f.owner,f.actor,f.outsider]){const issued=await createSignInSessionHandler({db,FieldValue})({data:{uid:u.uid},eventId:`rich-${u.uid}`});u.sid=issued.sessionClaims.sid;await auth.setCustomUserClaims(u.uid,{sid:u.sid});const response=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:await auth.createCustomToken(u.uid),returnSecureToken:true})});u.token=(await response.json()).idToken;await db.doc(`users/${u.uid}`).set({privacy:{whoCanMessage:'everyone'}},{merge:true});}f.chatId=(await handlers.open(callableRequest(f.actor,{peerId:f.owner.uid}))).chatId;return f;}
const send=(f,messageId,message)=>handlers.send(callableRequest(f.actor,{chatId:f.chatId,messageId,message}));
test.after(close);
test('strict bounded rich payloads normalize phone digits, spaces and poll options',()=>{
 assert.deepEqual(cleanMessage({type:'contact',contactName:' A ',contactPhone:'+٢١٣ (٧٧٠) ۱۲۳-۴۵۶'},'x'),{type:'contact',contactName:'A',contactPhone:'+213770123456'});
 assert.equal(cleanMessage({...poll,optionsJson:'[" A ","B"]'},'x').optionsJson,'["A","B"]');
 for(const message of [{...poll,votes:{}},{...event,attendees:{}},{...poll,optionsJson:'["A","a"]'},{...poll,optionsJson:'["Ａ","A"]'},{...poll,optionsJson:'["A"]'},{...poll,optionsJson:'bad'},{...poll,optionsJson:JSON.stringify(Array(9).fill('A'))},{...poll,question:'x'.repeat(301)},{...poll,optionsJson:'["",4]'},{type:'contact',contactName:'A',contactPhone:'12345'},{type:'contact',contactName:'A',contactPhone:'https://phone'},{...event,startsAtMs:1.5},{...event,startsAtMs:Infinity},{...event,title:''},{...event,description:'x'.repeat(1001)}])assert.throws(()=>cleanMessage(message,'x'),{code:'invalid-argument'});
});
test('send creates server state; retry has one unread and does not erase votes',async()=>{
 const f=await setup();await send(f,'poll',poll);await handlers.vote(callableRequest(f.owner,{chatId:f.chatId,messageId:'poll',optionIndex:0}));await send(f,'poll',poll);
 const p=(await db.doc(`chats/${f.chatId}/messages/poll`).get()).data();assert.deepEqual(p.votes,{[f.owner.uid]:0});assert.equal((await db.doc(`chats/${f.chatId}`).get()).data().unread[f.owner.uid],1);
 await send(f,'event',event);assert.deepEqual((await db.doc(`chats/${f.chatId}/messages/event`).get()).data().attendees,{});
 await send(f,'contact',{type:'contact',contactName:'Friend',contactPhone:'+213770123456'});
 denied(await patch(`chats/${f.chatId}/messages/poll`,f.owner,{votes:{[f.owner.uid]:1}}));
 denied(await patch(`chats/${f.chatId}/messages/event`,f.owner,{attendees:{[f.owner.uid]:true}}));
});
test('concurrent single choice votes preserve both voters and replacement never adds totals',async()=>{
 const f=await setup();await send(f,'poll',poll);const vote=(user,index)=>handlers.vote(callableRequest(user,{chatId:f.chatId,messageId:'poll',optionIndex:index}));
 await Promise.all([vote(f.owner,0),vote(f.actor,1)]);await vote(f.owner,1);await vote(f.owner,1);
 assert.deepEqual((await db.doc(`chats/${f.chatId}/messages/poll`).get()).data().votes,{[f.owner.uid]:1,[f.actor.uid]:1});
 await assert.rejects(vote(f.owner,2),{code:'invalid-argument'});await assert.rejects(vote(f.outsider,0),{code:'permission-denied'});
});
test('concurrent event RSVP preserves attendees and permits changing to decline',async()=>{
 const f=await setup();await send(f,'event',event);const respond=(user,attending)=>handlers.respondEvent(callableRequest(user,{chatId:f.chatId,messageId:'event',attending}));
 await Promise.all([respond(f.owner,true),respond(f.actor,true)]);await respond(f.owner,false);await respond(f.owner,false);
 assert.deepEqual((await db.doc(`chats/${f.chatId}/messages/event`).get()).data().attendees,{[f.owner.uid]:false,[f.actor.uid]:true});
 await assert.rejects(respond(f.outsider,true),{code:'permission-denied'});await assert.rejects(respond(f.owner,'true'),{code:'invalid-argument'});
});
test('blocked, frozen, revoked and disabled sessions cannot respond',async()=>{
 const f=await setup();await send(f,'poll',poll);await send(f,'event',event);
 const actions=()=>[()=>handlers.vote(callableRequest(f.owner,{chatId:f.chatId,messageId:'poll',optionIndex:0})),()=>handlers.respondEvent(callableRequest(f.owner,{chatId:f.chatId,messageId:'event',attending:true}))];
 const deniedBoth=async code=>{for(const action of actions())await assert.rejects(action(),{code});};
 const block=db.doc(`users/${f.actor.uid}/blocked_accounts/${f.owner.uid}`);await block.set({});await deniedBoth('permission-denied');await block.delete();
 const control=db.doc(`accountStateControls/${f.owner.uid}`);await control.set({schemaVersion:1,revision:1,selfFrozen:true,selfDisabled:false,adminSuspended:false});await deniedBoth('permission-denied');await control.delete();
 await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({isRevoked:true});await deniedBoth('unauthenticated');await db.doc(`users/${f.owner.uid}/sessions/${f.owner.sid}`).update({isRevoked:false});
 await auth.updateUser(f.owner.uid,{disabled:true});await deniedBoth('unauthenticated');
});
test('deleted, hidden and wrong-type responses fail without recreating messages',async()=>{
 const f=await setup();await send(f,'event',event);const input={chatId:f.chatId,messageId:'event'};
 await assert.rejects(handlers.vote(callableRequest(f.owner,{...input,optionIndex:0})),{code:'failed-precondition'});
 await db.doc(`chats/${f.chatId}/messages/event`).update({hiddenBy:{[f.owner.uid]:true}});
 await assert.rejects(handlers.respondEvent(callableRequest(f.owner,{...input,attending:true})),{code:'not-found'});
 await handlers.mutate(callableRequest(f.actor,{...input,action:'delete'}));
 await assert.rejects(handlers.respondEvent(callableRequest(f.owner,{...input,attending:true})),{code:'not-found'});assert.equal((await db.doc(`chats/${f.chatId}/messages/event`).get()).exists,false);
});
test('group responses require accepted current membership and current privacy',async()=>{
 const f=await setup(),chatId=`group_rich_${f.actor.uid}`;
 await db.doc(`chats/${chatId}`).set({type:'group',memberIds:[f.actor.uid,f.owner.uid],members:{},unread:{}});
 await handlers.send(callableRequest(f.actor,{chatId,messageId:'poll',message:poll}));
 await handlers.vote(callableRequest(f.owner,{chatId,messageId:'poll',optionIndex:0}));
 await db.doc(`users/${f.actor.uid}`).set({privacy:{whoCanMessage:'none'}},{merge:true});
 await assert.rejects(handlers.vote(callableRequest(f.owner,{chatId,messageId:'poll',optionIndex:1})),{code:'permission-denied'});
 await db.doc(`chats/${chatId}`).update({memberIds:[f.actor.uid]});
 await assert.rejects(handlers.vote(callableRequest(f.owner,{chatId,messageId:'poll',optionIndex:1})),{code:'permission-denied'});
});

test('rich fallback text supports replies; nontext edits and changed retries cannot corrupt state',async()=>{
 const f=await setup();await send(f,'poll',poll);await handlers.vote(callableRequest(f.owner,{chatId:f.chatId,messageId:'poll',optionIndex:1}));
 await send(f,'reply',{type:'text',text:'Reply',replyToId:'poll'});
 assert.equal((await db.doc(`chats/${f.chatId}/messages/reply`).get()).data().replyToText,poll.question);
 await assert.rejects(handlers.mutate(callableRequest(f.actor,{chatId:f.chatId,messageId:'poll',action:'edit',text:'overwrite'})),{code:'invalid-argument'});
 await assert.rejects(send(f,'poll',{...poll,question:'Changed?'}),{code:'already-exists'});
 assert.deepEqual((await db.doc(`chats/${f.chatId}/messages/poll`).get()).data().votes,{[f.owner.uid]:1});
 await db.doc(`users/${f.actor.uid}`).set({privacy:{whoCanMessage:'none'}},{merge:true});
 await assert.rejects(handlers.vote(callableRequest(f.owner,{chatId:f.chatId,messageId:'poll',optionIndex:0})),{code:'permission-denied'});
});

test('new events require future within one year; receipts survive event start',async()=>{
 const f=await setup(),now=Date.now();
 await assert.rejects(send(f,'past',{...event,startsAtMs:now-1}),{code:'invalid-argument'});
 await assert.rejects(send(f,'distant',{...event,startsAtMs:now+367*86400000}),{code:'invalid-argument'});
 const soon={...event,startsAtMs:now+60000};await send(f,'soon',soon);
 const realNow=Date.now;Date.now=()=>now+120000;
 try{await send(f,'soon',soon);}finally{Date.now=realNow;}
 assert.equal((await db.doc(`chats/${f.chatId}`).get()).data().unread[f.owner.uid],1);
});
