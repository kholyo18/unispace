const test=require('node:test'),assert=require('node:assert/strict');
const {validChatMembers,assertActiveChatRecipients,nextChatUnread}=require('../security/chat-service');
const ids=Array.from({length:601},(_,i)=>'user'+i);
test('groups above32 allowed; direct must remain exactly2; malformed members denied',()=>{
 assert.equal(validChatMembers({type:'group',memberIds:ids}),true);
 assert.equal(validChatMembers({type:'direct',memberIds:ids.slice(0,2)}),true);
 for(const value of [null,{type:'bogus',memberIds:ids.slice(0,2)},{type:'group',memberIds:[]},{type:'direct',memberIds:ids},{type:'group',memberIds:['u','u']},{type:'group',memberIds:['u','bad/path']},{type:'group',memberIds:['u',42]}])assert.equal(validChatMembers(value),false);
});
test('Auth lookups bounded100 and cover all601 recipients',async()=>{
 const batches=[];
 await assertActiveChatRecipients({getUsers:async batch=>{batches.push(batch);return {users:batch.map(x=>({uid:x.uid})),notFound:[]};}},ids);
 assert.deepEqual(batches.map(x=>x.length),[100,100,100,100,100,100,1]);
 assert.equal(batches.flat().map(x=>x.uid).join(','),ids.join(','));
});
test('disabled or missing member in late batch still denies; lookup failures fail closed',async()=>{
 for(const failure of ['disabled','missing','error']){
  let calls=0;
  await assert.rejects(assertActiveChatRecipients({getUsers:async batch=>{
   calls++;if(calls===2){if(failure==='error')throw Error('lookup');return {users:failure==='disabled'?[{disabled:true}]:[],notFound:failure==='missing'?['missing']:[]};}
   return {users:batch.map(x=>({uid:x.uid})),notFound:[]};
  }},ids),{code:'permission-denied'});
  assert.equal(calls,2);
 }
});
test('unread fanout above500 uses numbers preserving counts and excludes author',()=>{
 const unread=nextChatUnread({memberIds:ids,unread:{user0:8,user1:3,user2:'bad'}},'user0');
 assert.equal(Object.keys(unread).length,600);
 assert.equal(unread.user0,undefined);assert.equal(unread.user1,4);assert.equal(unread.user2,1);
 assert.equal(Object.values(unread).every(x=>typeof x==='number'),true);
});

test('legacy documents with omitted type retain direct two-member compatibility',()=>{
 assert.equal(validChatMembers({memberIds:['alice','bob']}),true);
 for(const memberIds of [[],['alice'],['alice','bob','third'],['alice','alice'],['alice','bad/path']]) {
  assert.equal(validChatMembers({memberIds}),false);
 }
});


