const {test,after}=require('node:test');const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getFirestore}=require('firebase-admin/firestore');
const {createPublicProfileHandler}=require('../security/public-profile');
const host=process.env.FIRESTORE_EMULATOR_HOST;
if(!host||!/^(127\.0\.0\.1|localhost):\d+$/.test(host))throw Error('Local Firestore emulator required');
const app=initializeApp({projectId:'demo-unispace-security'},'public-profile-tests');const db=getFirestore(app);
after(async()=>{await db.terminate();await deleteApp(app);});let index=0;
async function setup(){
 const target=`profile-${Date.now()}-${index++}`,viewer=target+'-viewer';
 const data={displayName:'Name',email:'private@example.com',phoneNumber:'secret-phone',security:{backupCodes:['secret']},
   academic:{internal:'secret'},twoFactorEnabled:true,unknownSecret:'secret',coverImageUrl:'cover',university:'College',github:'github',
   privacy:{privateAccount:false,showEmailOnProfile:false,showAcademicInfo:false,showSocialLinks:false,showOnline:false,showLastSeen:false},isOnline:true};
 await db.doc(`users/${target}`).set(data);
 let disabled=false;
 const token={uid:viewer,auth_time:100};
 const handler=createPublicProfileHandler({db,auth:{verifyIdToken:async()=>token,getUser:async()=>({disabled})}});
 const request={auth:{uid:viewer},rawRequest:{headers:{authorization:'Bearer signed'}},data:{userId:target}};
 return {target,viewer,handler,request,token,disable:()=>{disabled=true;}};
}
test('public response excludes hidden email and all unrelated sensitive fields',async()=>{
 const f=await setup();const p=await f.handler(f.request);
 assert.equal(p.displayName,'Name');assert.equal(p.canViewContent,true);
 for(const key of ['email','phoneNumber','security','academic','twoFactorEnabled','unknownSecret','university','github','isOnline','lastSeenAt'])assert.ok(!(key in p),key);
});
test('private visitor receives only basic identity; viewer-owned following cannot grant access',async()=>{
 const f=await setup();await db.doc(`users/${f.target}`).update({'privacy.privateAccount':true,'privacy.showEmailOnProfile':true});
 await db.doc(`users/${f.viewer}/following/${f.target}`).set({});
 const p=await f.handler(f.request);assert.equal(p.canViewContent,false);assert.ok(!('email'in p));assert.ok(!('coverImageUrl'in p));
});
test('accepted target follower receives allowed fields only and revocation takes effect on next read',async()=>{
 const f=await setup();await db.doc(`users/${f.target}`).update({'privacy.privateAccount':true,'privacy.showEmailOnProfile':true});
 const ref=db.doc(`users/${f.target}/followers/${f.viewer}`);await ref.set({});
 const p=await f.handler(f.request);assert.equal(p.canViewContent,true);assert.equal(p.email,'private@example.com');assert.ok(!('security'in p));
 await ref.delete();assert.equal((await f.handler(f.request)).canViewContent,false);
});
test('both blocking directions and legacy block collection deny access',async()=>{
 const f=await setup();for(const path of [`users/${f.target}/blocked_accounts/${f.viewer}`,`users/${f.viewer}/blocked_accounts/${f.target}`,`users/${f.target}/blocked_users/${f.viewer}`]){
  const ref=db.doc(path);await ref.set({});await assert.rejects(f.handler(f.request),{code:'not-found'});await ref.delete();
 }
});
test('frozen and Auth-disabled accounts are unavailable',async()=>{
 const f=await setup();await db.doc(`users/${f.target}`).update({'security.frozen':true});
 await assert.rejects(f.handler(f.request),{code:'not-found'});await db.doc(`users/${f.target}`).update({'security.frozen':false});
 f.disable();await assert.rejects(f.handler(f.request),{code:'not-found'});
});
test('anonymous, forged identity, extra parameters and revoked sessions are rejected',async()=>{
 const f=await setup();await assert.rejects(f.handler({...f.request,auth:null}),{code:'unauthenticated'});
 await assert.rejects(f.handler({...f.request,data:{userId:f.target,includeSecrets:true}}),{code:'invalid-argument'});
 await assert.rejects(f.handler({...f.request,auth:{uid:'foreign'}}),{code:'unauthenticated'});
 await db.doc(`authRevocations/${f.viewer}`).set({revokedBefore:100});await assert.rejects(f.handler(f.request),{code:'unauthenticated'});
});
test('legacy privacy flags are honored without leaking arbitrary privacy objects',async()=>{
 const f=await setup();await db.doc(`users/${f.target}`).set({displayName:'Legacy',profileVisibility:'private',showEmailInProfile:true,email:'private@example.com',privacy:{followersVisibility:{secret:'x'}}});
 const p=await f.handler(f.request);assert.equal(p.canViewContent,false);assert.equal(p.privacy.followersVisibility,'none');assert.ok(!('email'in p));
});
test('owner response remains sanitized and privacy changes are read fresh',async()=>{
 const f=await setup();f.token.uid=f.target;f.request.auth.uid=f.target;
 const owner=await f.handler(f.request);assert.equal(owner.email,'private@example.com');assert.ok(!('security'in owner));
 f.token.uid=f.viewer;f.request.auth.uid=f.viewer;
 await db.doc(`users/${f.target}`).update({'privacy.showEmailOnProfile':true});assert.equal((await f.handler(f.request)).email,'private@example.com');
 await db.doc(`users/${f.target}`).update({'privacy.showEmailOnProfile':false});assert.ok(!('email'in await f.handler(f.request)));
});
