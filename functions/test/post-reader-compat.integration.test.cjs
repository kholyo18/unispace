const {test,after}=require('node:test');
const assert=require('node:assert/strict');
const {randomUUID}=require('node:crypto');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore,Timestamp}=require('firebase-admin/firestore');
const {createContentSearchPageHandler}=require('../security/content-search-page');
const {createAccountAccessGuard}=require('../security/account-access-guard');
if(!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST||''))throw Error('Local emulator required');
const app=initializeApp({projectId:'demo-unispace-security'},'post-reader-compat'),db=getFirestore(app);
after(async()=>{await db.terminate();await deleteApp(app);});
async function fixture(){
 const viewer=randomUUID(),owner=randomUUID(),id=randomUUID(),word=randomUUID();
 await db.doc('users/'+viewer).set({displayName:'Viewer'});
 await db.doc('users/'+owner).set({displayName:'Owner',privacy:{privateAccount:false}});
 await db.doc('community_posts/'+id).set({authorId:owner,title:'عنوان',body:'مضمون المنشور',status:'published',createdAt:Timestamp.now(),searchKeywords:[word],upvotedBy:[viewer,'another'],imageUrls:['https://example.invalid/image.jpg'],comments:[{id:'c1',authorId:owner,text:'تعليق'}]});
 const auth={verifyIdToken:async()=>({uid:viewer,auth_time:100}),getUser:async()=>({disabled:false})};
 const run=(data,single=false,mode=false)=>createAccountAccessGuard({db})(createContentSearchPageHandler({auth,db},single,mode))({auth:{uid:viewer},rawRequest:{headers:{authorization:'Bearer fixture'}},data});
 return {viewer,owner,id,word,run};
}
test('feed and single reader preserve Arabic title body and media with caller-only votes',async()=>{
 const f=await fixture();
 const single=await f.run({postId:f.id},true);
 const feed=await f.run({cursor:null},false,true);
 for(const row of [single,feed.posts.find(p=>p.id===f.id)]){
  assert.ok(row);assert.equal(row.data.title,'عنوان');assert.equal(row.data.body,'مضمون المنشور');
  assert.equal(row.data.imageUrls.length,1);assert.deepEqual(row.data.upvotedBy,[f.viewer]);
 }
});
test('profile reader accepts legacy signed sessions and rejects private unaccepted viewers',async()=>{
 const f=await fixture();
 assert.ok((await f.run({userId:f.owner,cursor:null},false,'profile')).posts.some(p=>p.id===f.id));
 await db.doc('users/'+f.owner).update({privacy:{privateAccount:true}});
 await assert.rejects(f.run({userId:f.owner,cursor:null},false,'profile'),{code:'not-found'});
 await db.doc('users/'+f.viewer+'/following/'+f.owner).set({});
 await assert.rejects(f.run({postId:f.id},true),{code:'not-found'});
 await db.doc('users/'+f.owner+'/followers/'+f.viewer).set({});
 assert.equal((await f.run({postId:f.id},true)).id,f.id);
});
test('both block directions and removed posts remain hidden',async()=>{
 for(const reverse of [false,true]){
  const f=await fixture();
  await db.doc('users/'+(reverse?f.owner:f.viewer)+'/blocked_accounts/'+(reverse?f.viewer:f.owner)).set({});
  await assert.rejects(f.run({postId:f.id},true),{code:'not-found'});
 }
 const f=await fixture();await db.doc('community_posts/'+f.id).update({status:'removed'});
 await assert.rejects(f.run({postId:f.id},true),{code:'not-found'});
});
test('profile comments use authorized content',async()=>{
 const f=await fixture();
 await db.doc('users/'+f.owner+'/authored_comments/c1').set({postId:f.id,commentId:'c1',createdAt:Timestamp.now()});
 const r=await f.run({userId:f.owner},false,'comments');
 assert.deepEqual(r.posts[0].commentIds,['c1']);assert.equal(r.posts[0].data.comments[0].text,'تعليق');
});
test('search and own reactions preserve body content',async()=>{
 const f=await fixture();
 for(const r of [await f.run({page:0,token:f.word}),await f.run({reaction:'like',cursor:null},false,'reactions')]){
  assert.equal(r.posts.find(p=>p.id===f.id).data.body,'مضمون المنشور');
 }
});
test('revoked credentials and administrative restrictions fail closed',async()=>{
 const f=await fixture();
 await db.doc('authRevocations/'+f.viewer).set({revokedBefore:100});
 await assert.rejects(f.run({postId:f.id},true),{code:'unauthenticated'});
 const g=await fixture();
 await db.doc('accountStateControls/'+g.viewer).set({schemaVersion:1,revision:1,selfDisabled:false,selfFrozen:false,adminSuspended:true});
 await assert.rejects(g.run({postId:g.id},true),{code:'permission-denied'});
});

