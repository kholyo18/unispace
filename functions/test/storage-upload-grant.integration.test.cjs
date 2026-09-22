const {test,after}=require('node:test');const assert=require('node:assert/strict');const {randomUUID}=require('node:crypto');
const {db,auth,FieldValue,Timestamp,fixture,callableRequest,patch,read,denied,close}=require('./helpers/notification-fixture.cjs');
const {createStorageUploadHandler}=require('../security/storage-upload');
const {createAccountStateHandlers}=require('../security/account-state');
const {createRevokeAllSessionsHandler}=require('../security/revoke-all-sessions');
const {createAccountDeletionRequestHandler}=require('../security/account-deletion-request');
const {createPostHandler}=require('../security/create-post');
after(close);
const bucket='demo-unispace-security.firebasestorage.app';
const handler=createStorageUploadHandler({db,auth,FieldValue,Timestamp,bucketName:()=>bucket});
const lifecycle=createAccountStateHandlers({db,auth,FieldValue});
const grant=(u,path=`users/${u.uid}/avatar.jpg`,mime='image/jpeg',size=3)=>handler(callableRequest(u,{expectedUid:u.uid,path,contentType:mime,size}));
const own=(u,action)=>lifecycle.own(callableRequest(u,{expectedUid:u.uid,action}));
async function post(f,extra={}){const id=randomUUID();await db.doc(`community_posts/${id}`).set({authorId:f.owner.uid,status:'published',...extra});return id;}
async function chat(f){const id=randomUUID();await db.doc(`chats/${id}`).set({memberIds:[f.owner.uid,f.actor.uid]});await db.doc(`users/${f.actor.uid}`).update({'privacy.whoCanMessage':'everyone'});return id;}
const access=async u=>(await db.doc(`authRevocations/${u.uid}`).get()).data();

test('grants bind exact bucket path owner type size auth time and finite lifetime',async()=>{
 const f=await fixture();const result=await grant(f.owner);const stored=(await db.doc(`storageUploadGrants/${result.grantId}`).get()).data();
 assert.equal(stored.uid,f.owner.uid);assert.equal(stored.authTime,f.owner.authTime);assert.equal(stored.path,`users/${f.owner.uid}/avatar.jpg`);
 assert.equal(stored.bucket,bucket);assert.equal(stored.contentType,'image/jpeg');assert.equal(stored.size,3);assert.equal(stored.overwrite,true);
 assert.ok(result.expiresAt>Date.now());assert.ok(result.expiresAt<=Date.now()+30*60000);assert.equal((await access(f.owner)).storageAllowed,true);
});
test('anonymous requests and forged auth envelopes cannot create a grant',async()=>{
 const f=await fixture();await assert.rejects(handler(callableRequest(null,{})),{code:'unauthenticated'});
 await assert.rejects(handler({...callableRequest(f.owner,{expectedUid:f.owner.uid,path:`users/${f.owner.uid}/a.jpg`,contentType:'image/jpeg',size:3}),auth:{uid:f.actor.uid}}),{code:'unauthenticated'});
});
test('extra fields mismatched caller and bad sizes are rejected before writes',async()=>{
 const f=await fixture();const base={expectedUid:f.owner.uid,path:`users/${f.owner.uid}/a.jpg`,contentType:'image/jpeg',size:3};
 for(const bad of [{...base,expectedUid:f.actor.uid},{...base,overwrite:true},{...base,size:0},{...base,size:20971521}]) await assert.rejects(handler(callableRequest(f.owner,bad)),{code:'invalid-argument'});
 assert.equal(await access(f.owner),undefined);
});
test('signup may upload only its own profile before the profile document exists',async()=>{
 const f=await fixture();await db.doc(`users/${f.owner.uid}`).delete();await grant(f.owner);
 const id=await post(f);await assert.rejects(grant(f.owner,`community_posts/${id}/images/a.jpg`),{code:'permission-denied'});
});
test('missing profile with retained control or deletion state cannot reuse signup exception',async()=>{
 const f=await fixture();await db.doc(`users/${f.owner.uid}`).delete();await db.doc(`account_deletion_requests/${f.owner.uid}`).set({status:'pending'});
 await assert.rejects(grant(f.owner),{code:'permission-denied'});
});
test('post owner upload accepts a real server reservation and rejects another author',async()=>{
 const f=await fixture(),id=randomUUID();const reserve=createPostHandler({auth,db,FieldValue,bucket:()=>({name:bucket})});
 await reserve(callableRequest(f.owner,{postId:id}));await grant(f.owner,`community_posts/${id}/images/a.jpg`);
 await assert.rejects(grant(f.actor,`community_posts/${id}/images/a.jpg`),{code:'permission-denied'});
});
test('missing removed and deleted-post identifiers cannot receive upload grants',async()=>{
 const f=await fixture();await assert.rejects(grant(f.owner,'community_posts/missing/images/a.jpg'),{code:'not-found'});
 const id=await post(f,{status:'removed'});await assert.rejects(grant(f.owner,`community_posts/${id}/images/a.jpg`),{code:'permission-denied'});
 await db.doc(`postDeletionReceipts/${id}`).set({ownerId:f.owner.uid});await assert.rejects(grant(f.owner,`community_posts/${id}/images/a.jpg`),{code:'not-found'});
});
test('private comment upload requires accepted follow and not a requester-owned mirror',async()=>{
 const f=await fixture(),id=await post(f);await db.doc(`users/${f.owner.uid}`).update({'privacy.privateAccount':true});
 const path=`community_posts/${id}/comments/${f.actor.uid}/comment/media.jpg`;
 await db.doc(`users/${f.actor.uid}/following/${f.owner.uid}`).set({uid:f.owner.uid});
 await assert.rejects(grant(f.actor,path),{code:'permission-denied'});
 await db.doc(`users/${f.owner.uid}/followers/${f.actor.uid}`).set({uid:f.actor.uid});await grant(f.actor,path);
});
test('comment audience none rejects followers and mutual requires both directions',async()=>{
 const f=await fixture(),id=await post(f);const path=`community_posts/${id}/comments/${f.actor.uid}/comment/media.jpg`;
 await db.doc(`users/${f.owner.uid}`).update({'privacy.whoCanComment':'none'});await assert.rejects(grant(f.actor,path),{code:'permission-denied'});
 await db.doc(`users/${f.owner.uid}`).update({'privacy.whoCanComment':'mutual'});await db.doc(`users/${f.owner.uid}/followers/${f.actor.uid}`).set({});
 await assert.rejects(grant(f.actor,path),{code:'permission-denied'});await db.doc(`users/${f.actor.uid}/followers/${f.owner.uid}`).set({});await grant(f.actor,path);
});
test('block records in either direction and legacy collections deny comment uploads',async()=>{
 const f=await fixture(),id=await post(f);const target=`community_posts/${id}/comments/${f.actor.uid}/comment/media.jpg`;
 for(const c of ['blocked_accounts','blocked_by','blocked_users']) for(const [a,b] of [[f.owner,f.actor],[f.actor,f.owner]]) {
  const ref=db.doc(`users/${a.uid}/${c}/${b.uid}`);await ref.set({});await assert.rejects(grant(f.actor,target),{code:'permission-denied'});await ref.delete();
 }
});
test('chat media requires current distinct two-person membership',async()=>{
 const f=await fixture(),id=await chat(f);await grant(f.owner,`chats/${id}/images/a.jpg`);
 await assert.rejects(grant(f.outsider,`chats/${id}/images/a.jpg`),{code:'permission-denied'});
 await db.doc(`chats/${id}`).update({memberIds:[f.owner.uid,f.owner.uid]});await assert.rejects(grant(f.owner,`chats/${id}/images/a.jpg`),{code:'permission-denied'});
});
test('media upload enforces peer messaging preference but personal wallpaper is not a message',async()=>{
 const f=await fixture(),id=await chat(f);await db.doc(`users/${f.actor.uid}`).update({'privacy.whoCanMessage':'none'});
 await assert.rejects(grant(f.owner,`chats/${id}/images/a.jpg`),{code:'permission-denied'});
 await grant(f.owner,`chats/${id}/wallpaper/${f.owner.uid}.jpg`);
});
test('default mutual messaging requires both accepted relationship records',async()=>{
 const f=await fixture(),id=await chat(f);await db.doc(`users/${f.actor.uid}`).update({'privacy.whoCanMessage':FieldValue.delete()});
 await assert.rejects(grant(f.owner,`chats/${id}/images/a.jpg`),{code:'permission-denied'});
 await db.doc(`users/${f.actor.uid}/followers/${f.owner.uid}`).set({});await db.doc(`users/${f.owner.uid}/followers/${f.actor.uid}`).set({});
 await grant(f.owner,`chats/${id}/images/a.jpg`);
});
test('blocked and unavailable peers cannot receive new media grants',async()=>{
 const f=await fixture(),id=await chat(f);const path=`chats/${id}/audio/a.m4a`;
 const ref=db.doc(`users/${f.actor.uid}/blocked_by/${f.owner.uid}`);await ref.set({});await assert.rejects(grant(f.owner,path,'audio/mp4'),{code:'permission-denied'});await ref.delete();
 await db.doc(`users/${f.actor.uid}`).update({accountStatus:'deleted'});await assert.rejects(grant(f.owner,path,'audio/mp4'));
});
test('malformed and revoked global cutoffs fail closed',async()=>{
 const f=await fixture();for(const revokedBefore of [null,-1,'0',f.owner.authTime,f.owner.authTime+1]) {
  await db.doc(`authRevocations/${f.owner.uid}`).set({revokedBefore});await assert.rejects(grant(f.owner),{code:'unauthenticated'});
 }
});
test('provider-disabled callers cannot mint fresh grants',async()=>{
 const f=await fixture();await auth.updateUser(f.owner.uid,{disabled:true});await assert.rejects(grant(f.owner),{code:'unauthenticated'});
});
test('freeze deactivation and reactivation cannot silently preserve Storage authorization',async()=>{
 const f=await fixture();await grant(f.owner);await own(f.owner,'freeze');assert.equal((await access(f.owner)).storageAllowed,false);
 await assert.rejects(grant(f.owner),{code:'permission-denied'});await own(f.owner,'unfreeze');assert.equal((await access(f.owner)).storageAllowed,false);
 await grant(f.owner);assert.equal((await access(f.owner)).storageAllowed,true);await own(f.owner,'deactivate');assert.equal((await access(f.owner)).storageAllowed,false);
});
test('concurrent grant and freeze finish with Storage disabled',async()=>{
 const f=await fixture();await Promise.allSettled([grant(f.owner),own(f.owner,'freeze')]);assert.equal((await access(f.owner)).storageAllowed,false);
 await assert.rejects(grant(f.owner),{code:'permission-denied'});
});
test('revoking all sessions clears authorizations without decreasing existing cutoff',async()=>{
 const f=await fixture();await grant(f.owner);await createRevokeAllSessionsHandler({auth,db,FieldValue})(callableRequest(f.owner,{}));
 assert.notEqual((await access(f.owner)).storageAllowed,true);await assert.rejects(grant(f.owner),{code:'unauthenticated'});
});
test('durable deletion invalidates Storage before any external revocation failure',async()=>{
 const f=await fixture();await grant(f.owner);const h=createAccountDeletionRequestHandler({auth,db,FieldValue,Timestamp,
  revokeAllSessions:async()=>{throw Error('simulated external failure');}});
 await assert.rejects(h(callableRequest(f.owner,{confirm:true,expectedUid:f.owner.uid})));
 assert.equal((await access(f.owner)).storageAllowed,false);
 await assert.rejects(grant(f.owner));
});
test('grant count is bounded and concurrent issuance preserves the shared count',async()=>{
 const f=await fixture();const time=Date.now();await db.doc(`authRevocations/${f.owner.uid}`).set({revokedBefore:0,storageGrantWindowStart:time,storageGrantCount:59});
 const results=await Promise.allSettled([grant(f.owner),grant(f.owner)]);assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
 assert.equal(results.find(r=>r.status==='rejected').reason.code,'resource-exhausted');assert.equal((await access(f.owner)).storageGrantCount,60);
});
test('direct client access to grants and the authorization projection is denied',async()=>{
 const f=await fixture(),g=await grant(f.owner);
 for(const path of [`storageUploadGrants/${g.grantId}`,`authRevocations/${f.owner.uid}`]) {
  denied(await read(path,f.owner));denied(await patch(path,f.owner,{storageAllowed:true}));
 }
});
