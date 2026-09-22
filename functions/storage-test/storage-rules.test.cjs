// Real Storage/Auth/Firestore emulators. Admin SDK only seeds fixtures.
const {test,after}=require('node:test');const assert=require('node:assert/strict');const {randomUUID}=require('node:crypto');
const {db,auth,FieldValue,Timestamp,project,fixture,callableRequest,close}=require('../test/helpers/notification-fixture.cjs');
const host=process.env.FIREBASE_STORAGE_EMULATOR_HOST;
if(!/^(127\.0\.0\.1|localhost):\d+$/.test(host||'')) throw Error('Local Storage emulator is required; production forbidden.');
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getStorage}=require('firebase-admin/storage');
const app=initializeApp({projectId:project},'storage-fixtures-'+randomUUID());
const bucketName=project+'.firebasestorage.app',bucket=getStorage(app).bucket(bucketName);
const {createStorageUploadHandler}=require('../security/storage-upload');
const {createAccountStateHandlers}=require('../security/account-state');
const handler=createStorageUploadHandler({db,auth,FieldValue,Timestamp,bucketName:()=>bucketName});
const lifecycle=createAccountStateHandlers({db,auth,FieldValue});
after(async()=>{await close();await deleteApp(app);});
const base=`http://${host}/v0/b/${bucketName}/o`;
const headers=u=>u?{Authorization:`Firebase ${u.token}`}:{ };
async function response(r){const text=await r.text();let data;try{data=JSON.parse(text);}catch{data=text;}return {status:r.status,data,headers:r.headers};}
async function issue(u,path,mime='image/jpeg',size=3){return handler(callableRequest(u,{expectedUid:u.uid,path,contentType:mime,size}));}
async function upload(u,path,{grant=null,mime='image/jpeg',bytes=Buffer.from('abc'),metadata={}}={}){
 const boundary='audit-'+randomUUID();
 const meta={name:path,contentType:mime,metadata:{...(grant?{uploadGrantId:grant.grantId,uploadedBy:grant.uid}:{}),...metadata}};
 const body=Buffer.concat([Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify(meta)}\r\n--${boundary}\r\nContent-Type: ${mime}\r\n\r\n`),bytes,Buffer.from(`\r\n--${boundary}--\r\n`)]);
 return response(await fetch(base+'?name='+encodeURIComponent(path),{method:'POST',headers:{...headers(u),
  'X-Goog-Upload-Protocol':'multipart','Content-Type':`multipart/related; boundary=${boundary}`},body,signal:AbortSignal.timeout(15000)}));
}
const get=(u,path,suffix='')=>fetch(base+'/'+encodeURIComponent(path)+suffix,{headers:headers(u),signal:AbortSignal.timeout(15000)}).then(response);
const erase=(u,path)=>fetch(base+'/'+encodeURIComponent(path),{method:'DELETE',headers:headers(u),signal:AbortSignal.timeout(15000)}).then(response);
const denied=r=>assert.equal(r.status,403,JSON.stringify(r.data));
const allowed=r=>assert.ok(r.status>=200&&r.status<300,JSON.stringify(r.data));
async function setup(){
 const f=await fixture();for(const u of [f.owner,f.actor,f.outsider])await issue(u,`users/${u.uid}/avatar.jpg`);
 f.post=randomUUID();f.chat=randomUUID();
 await db.doc(`community_posts/${f.post}`).set({authorId:f.owner.uid,status:'published'});
 await db.doc(`chats/${f.chat}`).set({memberIds:[f.owner.uid,f.actor.uid]});
 await db.doc(`users/${f.actor.uid}`).update({'privacy.whoCanMessage':'everyone'});
 f.postPath=`community_posts/${f.post}/images/existing.jpg`;f.chatPath=`chats/${f.chat}/images/existing.jpg`;
 for(const path of [f.postPath,f.chatPath])await bucket.file(path).save(Buffer.from('abc'),{
  resumable:false,metadata:{contentType:'image/jpeg',metadata:{uploadedBy:f.owner.uid,firebaseStorageDownloadTokens:randomUUID()}}});
 return f;
}

test('STORAGEREGRESSION: nonowners cannot directly upload post media',async()=>{const f=await setup();denied(await upload(f.actor,`community_posts/${f.post}/images/forged.jpg`));});
test('STORAGEREGRESSION: strangers cannot overwrite post media',async()=>{const f=await setup();denied(await upload(f.actor,f.postPath));});
test('STORAGEREGRESSION: outsiders cannot read private chat object metadata',async()=>{const f=await setup();denied(await get(f.outsider,f.chatPath));});
test('STORAGEREGRESSION: visitors cannot retrieve raw post token metadata',async()=>{const f=await setup();denied(await get(f.actor,f.postPath));});
test('STORAGEREGRESSION: comment uploader path cannot be impersonated',async()=>{const f=await setup();denied(await upload(f.actor,`community_posts/${f.post}/comments/${f.owner.uid}/comment/media.jpg`));});
test('STORAGEREGRESSION: arbitrary post upload type is rejected',async()=>{const f=await setup();denied(await upload(f.owner,`community_posts/${f.post}/images/script.html`,{mime:'text/html'}));});
test('STORAGEREGRESSION: post prefix listing is denied',async()=>{const f=await setup();denied(await response(await fetch(base+'?prefix='+encodeURIComponent(`community_posts/${f.post}/`),{headers:headers(f.actor)})));});
test('STORAGEREGRESSION: revoked authentication cannot read post media',async()=>{const f=await setup();await db.doc(`authRevocations/${f.owner.uid}`).update({revokedBefore:f.owner.authTime});denied(await get(f.owner,f.postPath));});

test('owner profile creation replacement retrieval and deletion work',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/avatar.jpg`,grant=await issue(f.owner,path);
 allowed(await upload(f.owner,path,{grant}));allowed(await get(f.owner,path));
 allowed(await upload(f.owner,path,{grant:await issue(f.owner,path),bytes:Buffer.from('xyz')}));allowed(await erase(f.owner,path));
});
test('profile read without bearer token is owner-only',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/avatar.jpg`;allowed(await upload(f.owner,path,{grant:await issue(f.owner,path)}));
 denied(await get(f.actor,path));denied(await get(null,path));
});
test('post images and videos accept exact server grants and remain immutable',async()=>{
 const f=await setup();for(const [folder,mime]of [['images','image/jpeg'],['videos','video/mp4']]){
  const path=`community_posts/${f.post}/${folder}/new.bin`,grant=await issue(f.owner,path,mime);
  allowed(await upload(f.owner,path,{grant,mime}));allowed(await get(f.owner,path));denied(await upload(f.owner,path,{grant,mime}));
 }
});
test('approved comment upload works for the caller but not for another UID',async()=>{
 const f=await setup(),path=`community_posts/${f.post}/comments/${f.actor.uid}/comment/media.jpg`,grant=await issue(f.actor,path);
 allowed(await upload(f.actor,path,{grant}));allowed(await get(f.actor,path));denied(await get(f.outsider,path));denied(await upload(f.owner,path,{grant}));
});
test('chat images videos voice and ordinary file folders are compatible',async()=>{
 const f=await setup();for(const [folder,mime]of [['images','image/gif'],['videos','video/mp4'],['audio','audio/mp4'],['files','application/octet-stream']]){
  const path=`chats/${f.chat}/${folder}/new.bin`,grant=await issue(f.owner,path,mime);
  allowed(await upload(f.owner,path,{grant,mime}));allowed(await get(f.actor,path));
 }
});
test('wallpaper belongs to its member and may be replaced without allowing peer replacement',async()=>{
 const f=await setup(),path=`chats/${f.chat}/wallpaper/${f.owner.uid}.jpg`,grant=await issue(f.owner,path);
 allowed(await upload(f.owner,path,{grant}));allowed(await upload(f.owner,path,{grant}));denied(await upload(f.actor,path,{grant}));
});
test('grant path cannot be reused for a sibling object',async()=>{
 const f=await setup(),a=`community_posts/${f.post}/images/a.jpg`,b=`community_posts/${f.post}/images/b.jpg`;
 denied(await upload(f.owner,b,{grant:await issue(f.owner,a)}));
});
test('exact declared byte size and content type cannot be increased or changed',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/size.jpg`,grant=await issue(f.owner,path);
 denied(await upload(f.owner,path,{grant,bytes:Buffer.from('abcd')}));denied(await upload(f.owner,path,{grant,mime:'text/html'}));
});
test('missing forged and stolen grant IDs do not authorize an upload',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/grant.jpg`,grant=await issue(f.owner,path);
 denied(await upload(f.owner,path));denied(await upload(f.owner,path,{grant:{...grant,grantId:'abcdefghijklmnopqrst'}}));denied(await upload(f.actor,path,{grant}));
});
test('uploader metadata cannot override the verified grant owner',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/owner.jpg`;denied(await upload(f.owner,path,{grant:await issue(f.owner,path),metadata:{uploadedBy:f.actor.uid}}));
});
test('expired grants deny upload while a new grant restores legitimate access',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/expired.jpg`,grant=await issue(f.owner,path);
 await db.doc(`storageUploadGrants/${grant.grantId}`).update({expiresAt:Timestamp.fromMillis(Date.now()-1000)});
 denied(await upload(f.owner,path,{grant}));allowed(await upload(f.owner,path,{grant:await issue(f.owner,path)}));
});
test('deleted grant and mismatched grant authentication time fail closed',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/auth.jpg`,grant=await issue(f.owner,path),ref=db.doc(`storageUploadGrants/${grant.grantId}`);
 await ref.update({authTime:f.owner.authTime-1});denied(await upload(f.owner,path,{grant}));await ref.delete();denied(await upload(f.owner,path,{grant}));
});
test('missing expired or malformed storage authorization denies access',async()=>{
 const f=await setup(),ref=db.doc(`authRevocations/${f.owner.uid}`);const original=(await ref.get()).data();
 for(const change of [{storageAllowed:false},{storageUntil:Timestamp.fromMillis(0)},{storageSchema:2},{revokedBefore:'0'}]){
  await ref.set({...original,...change});denied(await get(f.owner,f.postPath));
 }
 await ref.delete();denied(await get(f.owner,f.postPath));
});
test('freeze revokes an already issued upload permission and direct reads atomically',async()=>{
 const f=await setup(),path=`users/${f.owner.uid}/freeze.jpg`,grant=await issue(f.owner,path);
 await lifecycle.own(callableRequest(f.owner,{expectedUid:f.owner.uid,action:'freeze'}));
 denied(await upload(f.owner,path,{grant}));denied(await get(f.owner,f.postPath));
});
test('a removed chat member cannot read or delete old objects',async()=>{
 const f=await setup();await db.doc(`chats/${f.chat}`).update({memberIds:[f.actor.uid,f.outsider.uid]});
 denied(await get(f.owner,f.chatPath));denied(await erase(f.owner,f.chatPath));
});
test('members cannot delete peer media but the uploader can delete their own',async()=>{
 const f=await setup();denied(await erase(f.actor,f.chatPath));allowed(await erase(f.owner,f.chatPath));
});
test('legacy objects with no uploader metadata cannot be client-deleted',async()=>{
 const f=await setup();await bucket.file(f.chatPath).setMetadata({metadata:{uploadedBy:null}});denied(await erase(f.owner,f.chatPath));
});
test('resumable creation finalization works under exact-grant create-only rules',async()=>{
 const f=await setup(),path=`community_posts/${f.post}/images/resumable.jpg`,grant=await issue(f.owner,path);
 const start=await fetch(base+'?name='+encodeURIComponent(path),{method:'POST',headers:{...headers(f.owner),'Content-Type':'application/json',
  'X-Goog-Upload-Protocol':'resumable','X-Goog-Upload-Command':'start','X-Goog-Upload-Header-Content-Length':'3',
  'X-Goog-Upload-Header-Content-Type':'image/jpeg'},body:JSON.stringify({name:path,contentType:'image/jpeg',metadata:{uploadGrantId:grant.grantId,uploadedBy:f.owner.uid}})});
 assert.ok(start.ok,await start.clone().text());const location=start.headers.get('x-goog-upload-url');assert.ok(location);
 assert.equal(new URL(location).host,host,'Resumable URL must stay on loopback');
 const done=await response(await fetch(location,{method:'POST',headers:{...headers(f.owner),'Content-Type':'application/octet-stream',
  'X-Goog-Upload-Command':'upload, finalize','X-Goog-Upload-Offset':'0'},body:Buffer.from('abc')}));allowed(done);allowed(await get(f.owner,path));
});
test('documented remaining boundary: a bearer download token is not revoked by SDK Rules',async()=>{
 const f=await setup();const [metadata]=await bucket.file(f.chatPath).getMetadata();const token=metadata.metadata.firebaseStorageDownloadTokens;
 const result=await get(null,f.chatPath,'?alt=media&token='+encodeURIComponent(token));allowed(result);
 // This test records a release blocker, not a private-media security claim.
});
