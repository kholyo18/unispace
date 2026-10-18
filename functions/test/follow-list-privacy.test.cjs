const {test,after}=require('node:test');
const assert=require('node:assert/strict');
const {randomUUID}=require('node:crypto');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {createFollowListHandler}=require('../security/follow-lists');
const host=process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local emulator required');
const project='demo-unispace-security';
const app=initializeApp({projectId:project},'follow-list-privacy');
const db=getFirestore(app);
after(async()=>{await db.terminate();await deleteApp(app);});
async function setup() {
 const owner='list-'+randomUUID(), viewer=owner+'-viewer', member=owner+'-member';
 for (const id of [owner,viewer,member]) await db.doc('users/'+id).set({displayName:id,privacy:{privateAccount:false}});
 await db.doc(`users/${owner}/followers/${member}`).set({});
 await db.doc(`users/${owner}/following/${member}`).set({});
 await db.doc(`users/${member}/followers/${owner}`).set({});
 const auth={verifyIdToken:async uid=>({uid,auth_time:100}),getUser:async()=>({disabled:false}),
  getUsers:async ids=>({users:ids.map(({uid})=>({uid,disabled:false}))})};
 const handler=createFollowListHandler({auth,db});
 const call=(uid,kind='followers')=>handler({auth:{uid},rawRequest:{headers:{authorization:'Bearer '+uid}},data:{userId:owner,kind,offset:0}});
 return {owner,viewer,member,call};
}
async function rest(uid,path) {
 const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url'),now=Math.floor(Date.now()/1000);
 const token=`${enc({alg:'none',typ:'JWT'})}.${enc({iss:`https://securetoken.google.com/${project}`,aud:project,sub:uid,iat:now,exp:now+3600,auth_time:100})}.`;
 return fetch(`http://${host}/v1/projects/${project}/databases/(default)/documents/${path}`,{headers:{Authorization:`Bearer ${token}`}});
}
test('direct list enumeration is owner-only; participants can inspect their own relationship',async()=>{
 const f=await setup();
 for (const kind of ['followers','following']) {
  const list=`users/${f.owner}/${kind}`;
  assert.equal((await rest(f.owner,list)).status,200);
  assert.equal((await rest(f.viewer,list)).status,403);
  assert.equal((await rest(f.member,list)).status,403);
  assert.equal((await rest(f.member,list+'/'+f.member)).status,200);
  assert.equal((await rest(f.viewer,list+'/'+f.member)).status,403);
 }
});
test('callable permits public lists and enforces none for both list kinds while preserving owner access',async()=>{
 const f=await setup();
 for (const kind of ['followers','following']) assert.ok((await f.call(f.viewer,kind)).items.some(x=>x.id===f.member));
 await db.doc('users/'+f.owner).update({'privacy.followersVisibility':'none','privacy.followingVisibility':'none'});
 for (const kind of ['followers','following']) {
  await assert.rejects(f.call(f.viewer,kind),{code:'permission-denied'});
  assert.ok((await f.call(f.owner,kind)).items.some(x=>x.id===f.member));
 }
});
test('private and mutual lists require authoritative relationships, not viewer mirrors',async()=>{
 const f=await setup();
 await db.doc('users/'+f.owner).update({'privacy.privateAccount':true,'privacy.followersVisibility':'mutual'});
 await db.doc(`users/${f.viewer}/following/${f.owner}`).set({});
 await assert.rejects(f.call(f.viewer),{code:'permission-denied'});
 await db.doc(`users/${f.owner}/followers/${f.viewer}`).set({});
 await assert.rejects(f.call(f.viewer),{code:'permission-denied'});
 await db.doc(`users/${f.viewer}/followers/${f.owner}`).set({});
 assert.ok((await f.call(f.viewer)).items.some(x=>x.id===f.member));
 await db.doc(`users/${f.owner}/followers/${f.viewer}`).delete();
 await assert.rejects(f.call(f.viewer),{code:'permission-denied'});
});
test('blocked list owner is unavailable and blocked members are filtered',async()=>{
 const f=await setup();
 await db.doc(`users/${f.member}/blocked_accounts/${f.viewer}`).set({});
 assert.equal((await f.call(f.viewer)).items.length,0);
 await db.doc(`users/${f.owner}/blocked_accounts/${f.viewer}`).set({});
 await assert.rejects(f.call(f.viewer),{code:'not-found'});
});
test('revoked authentication cannot use list callable or direct owner reads',async()=>{
 const f=await setup();
 await db.doc('authRevocations/'+f.owner).set({revokedBefore:100});
 await assert.rejects(f.call(f.owner),{code:'unauthenticated'});
 assert.equal((await rest(f.owner,`users/${f.owner}/followers`)).status,403);
});
test('malformed revocation cutoffs never permit relationship enumeration',async()=>{
 const f=await setup();
 for(const value of [null,false,'invalid',0.5,-1,Number.MAX_SAFE_INTEGER+1]){
  await db.doc('authRevocations/'+f.owner).set({revokedBefore:value});
  await assert.rejects(f.call(f.owner),{code:'unauthenticated'});
 }
 await db.doc('authRevocations/'+f.owner).set({revokedBefore:99});
 assert.ok((await f.call(f.owner)).items.length>0);
});
