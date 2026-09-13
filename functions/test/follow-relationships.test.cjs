const {test,after}=require('node:test');const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getFirestore,FieldValue}=require('firebase-admin/firestore');
const {createFollowHandler}=require('../security/follow-relationships');
const {createPublicProfileHandler}=require('../security/public-profile');
const host=process.env.FIRESTORE_EMULATOR_HOST;
if(!host||!/^(127\.0\.0\.1|localhost):\d+$/.test(host))throw Error('Local emulator required');
const project='demo-unispace-security',app=initializeApp({projectId:project},'follow-tests'),db=getFirestore(app);
after(async()=>{await db.terminate();await deleteApp(app);});let index=0;
async function setup(privateAccount=true){
 const owner=`follow-${Date.now()}-${index++}`,from=owner+'-from',stranger=owner+'-stranger';
 for(const uid of [owner,from,stranger])await db.doc(`users/${uid}`).set({displayName:uid,privacy:{privateAccount}});
 const auth={verifyIdToken:async token=>({uid:token,auth_time:100}),getUser:async()=>({disabled:false})};
 const handler=createFollowHandler({db,auth,FieldValue});
 const request=(uid,action,userId)=>({auth:{uid},rawRequest:{headers:{authorization:'Bearer '+uid}},data:{action,userId}});
 const call=(uid,action,userId)=>handler(request(uid,action,userId));
 const exists=async path=>(await db.doc(path).get()).exists;
 const profile=()=>createPublicProfileHandler({db,auth})({...request(from,'follow',owner),data:{userId:owner}});
 return {owner,from,stranger,call,exists,handler,request,profile};
}
test('private follow requires real pending request and owner approval to unlock profile',async()=>{
 const f=await setup();assert.deepEqual(await f.call(f.from,'follow',f.owner),{state:'pending'});
 assert.equal(await f.exists(`users/${f.owner}/followers/${f.from}`),false);
 assert.equal((await f.profile()).canViewContent,false);
 await assert.rejects(f.call(f.stranger,'accept',f.from),{code:'failed-precondition'});
 await assert.rejects(f.call(f.from,'accept',f.owner),{code:'failed-precondition'});
 assert.deepEqual(await f.call(f.owner,'accept',f.from),{state:'following'});
 assert.equal(await f.exists(`users/${f.from}/following/${f.owner}`),true);
 assert.equal((await f.profile()).canViewContent,true);
});
test('repeated requests and approvals do not duplicate notifications',async()=>{
 const f=await setup();await f.call(f.from,'follow',f.owner);await f.call(f.from,'follow',f.owner);
 const notices=await db.collection(`users/${f.owner}/notifications`).get();
 assert.equal(notices.size,1);assert.equal(notices.docs[0].data().read,false);assert.equal(notices.docs[0].data().actorId,f.from);
 await f.call(f.owner,'accept',f.from);await f.call(f.owner,'accept',f.from);
 assert.equal((await db.collection(`users/${f.from}/notifications`).get()).size,1);
});
test('public follow is immediate; concurrent duplicates create one notification',async()=>{
 const f=await setup(false);await Promise.all([f.call(f.from,'follow',f.owner),f.call(f.from,'follow',f.owner)]);
 assert.equal(await f.exists(`users/${f.owner}/followers/${f.from}`),true);
 assert.equal((await db.collection(`users/${f.owner}/notifications`).get()).size,1);
 await f.call(f.from,'unfollow',f.owner);
 assert.equal(await f.exists(`users/${f.owner}/followers/${f.from}`),false);
 assert.equal(await f.exists(`users/${f.from}/following/${f.owner}`),false);
});
test('cancelled and rejected requests cannot subsequently be approved',async()=>{
 const f=await setup();await f.call(f.from,'follow',f.owner);await f.call(f.from,'cancel',f.owner);
 await assert.rejects(f.call(f.owner,'accept',f.from),{code:'failed-precondition'});
 await f.call(f.from,'follow',f.owner);await f.call(f.owner,'reject',f.from);
 await assert.rejects(f.call(f.owner,'accept',f.from),{code:'failed-precondition'});
});
test('block atomically removes both directions and pending requests; unblocking grants nothing',async()=>{
 const f=await setup(false);await f.call(f.from,'follow',f.owner);await f.call(f.owner,'follow',f.from);
 await db.doc(`users/${f.owner}/follow_requests/${f.from}`).set({uid:f.from,status:'pending'});
 await f.call(f.owner,'block',f.from);
 for(const path of [`users/${f.owner}/followers/${f.from}`,`users/${f.from}/followers/${f.owner}`,`users/${f.owner}/following/${f.from}`,`users/${f.from}/following/${f.owner}`,`users/${f.owner}/follow_requests/${f.from}`])assert.equal(await f.exists(path),false);
 await assert.rejects(f.call(f.from,'follow',f.owner),{code:'permission-denied'});
 await assert.rejects(f.profile(),{code:'not-found'});
 await f.call(f.from,'unblock',f.owner);await assert.rejects(f.call(f.from,'follow',f.owner),{code:'permission-denied'});
 await f.call(f.owner,'unblock',f.from);assert.equal(await f.exists(`users/${f.owner}/followers/${f.from}`),false);
});
test('concurrent cancel and accept leave a consistent committed state',async()=>{
 const f=await setup();await f.call(f.from,'follow',f.owner);
 await Promise.allSettled([f.call(f.from,'cancel',f.owner),f.call(f.owner,'accept',f.from)]);
 assert.equal(await f.exists(`users/${f.owner}/followers/${f.from}`),await f.exists(`users/${f.from}/following/${f.owner}`));
 assert.equal(await f.exists(`users/${f.owner}/follow_requests/${f.from}`),false);
});
test('forged identity, extra parameters, self-follow and revoked sessions are rejected',async()=>{
 const f=await setup();await assert.rejects(f.handler({...f.request(f.from,'follow',f.owner),auth:{uid:f.stranger}}),{code:'unauthenticated'});
 await assert.rejects(f.handler({...f.request(f.from,'follow',f.owner),data:{action:'follow',userId:f.owner,approved:true}}),{code:'invalid-argument'});
 await assert.rejects(f.call(f.from,'follow',f.from),{code:'invalid-argument'});
 await db.doc(`authRevocations/${f.from}`).set({revokedBefore:100});await assert.rejects(f.call(f.from,'follow',f.owner),{code:'unauthenticated'});
});
test('rules allow participants to inspect status but forbid direct grants and deletes',async()=>{
 const f=await setup();await f.call(f.from,'follow',f.owner);
 const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
 async function rest(uid,path,method='GET'){
  const now=Math.floor(Date.now()/1000),token=`${enc({alg:'none',typ:'JWT'})}.${enc({iss:`https://securetoken.google.com/${project}`,aud:project,sub:uid,iat:now,exp:now+3600,auth_time:100})}.`;
  return fetch(`http://${host}/v1/projects/${project}/databases/(default)/documents/${path}`,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},...(method==='PATCH'?{body:JSON.stringify({fields:{uid:{stringValue:f.from}}})}:{})});
 }
 for(const uid of [f.from,f.owner])assert.equal((await rest(uid,`users/${f.owner}/follow_requests/${f.from}`)).status,200);
 assert.equal((await rest(f.stranger,`users/${f.owner}/follow_requests/${f.from}`)).status,403);
 for(const uid of [f.from,f.owner])for(const path of [`users/${f.owner}/followers/${f.from}`,`users/${f.from}/following/${f.owner}`,`users/${f.owner}/follow_requests/${f.from}`])for(const method of ['PATCH','DELETE'])assert.equal((await rest(uid,path,method)).status,403);
});

test('a requester-owned mirror does not bypass private approval',async()=>{
 const f=await setup();await db.doc('users/'+f.from+'/following/'+f.owner).set({uid:f.owner});
 assert.deepEqual(await f.call(f.from,'follow',f.owner),{state:'pending'});
 assert.equal(await f.exists('users/'+f.from+'/following/'+f.owner),false);
 assert.equal((await f.profile()).canViewContent,false);
});
test('concurrent block and acceptance cannot leave a blocked follower authorized',async()=>{
 const f=await setup();await f.call(f.from,'follow',f.owner);
 await Promise.allSettled([f.call(f.owner,'block',f.from),f.call(f.owner,'accept',f.from)]);
 assert.equal(await f.exists('users/'+f.owner+'/blocked_accounts/'+f.from),true);
 assert.equal(await f.exists('users/'+f.owner+'/followers/'+f.from),false);
 await assert.rejects(f.profile(),{code:'not-found'});
});
