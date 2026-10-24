const {test,after}=require('node:test');
const assert=require('node:assert/strict');
const {randomUUID}=require('node:crypto');
const {db,auth,FieldValue,Timestamp,project,fixture,callableRequest,close}=require('../test/helpers/notification-fixture.cjs');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getStorage}=require('firebase-admin/storage');
const {createStorageUploadHandler}=require('../security/storage-upload');
const host=process.env.FIREBASE_STORAGE_EMULATOR_HOST;
if(!/^(127\.0\.0\.1|localhost):\d+$/.test(host||''))throw Error('Local Storage emulator required');
const app=initializeApp({projectId:project},'protected-rules-'+randomUUID());
const bucketName=project+'.firebasestorage.app',bucket=getStorage(app).bucket(bucketName);
const prepare=createStorageUploadHandler({db,auth,FieldValue,Timestamp,bucketName:()=>bucketName});
const base=`http://${host}/v0/b/${bucketName}/o`;
const headers=u=>u?{Authorization:`Firebase ${u.token}`}:{ };
const deny=async r=>assert.equal((await r).status,403);
after(async()=>{await close();await deleteApp(app);});
async function setup(){
 const f=await fixture(),path=`users/${f.owner.uid}/avatar.jpg`;
 const grant=await prepare(callableRequest(f.owner,{expectedUid:f.owner.uid,path,contentType:'image/jpeg',size:3}));
 return {...f,path,grant};
}
test('cutover denies client object metadata/bytes and listing including uploader and staging',async()=>{
 const f=await setup();
 for(const path of [f.path,`private_upload_staging/${f.owner.uid}/${f.grant.grantId}`]){
  await bucket.file(path).save(Buffer.from('abc'),{resumable:false,metadata:{contentType:'image/jpeg'}});
  for(const actor of [null,f.owner,f.outsider]){
   for(const suffix of ['', '?alt=media'])await deny(fetch(base+'/'+encodeURIComponent(path)+suffix,{headers:headers(actor)}));
  }
 }
 await deny(fetch(base+'?prefix=users/',{headers:headers(f.owner)}));
});
test('even valid legacy grants cannot mint new public-token SDK objects after cutover',async()=>{
 const f=await setup(),boundary='protected-'+randomUUID();
 const meta={name:f.path,contentType:'image/jpeg',metadata:{uploadGrantId:f.grant.grantId,uploadedBy:f.owner.uid}};
 const body=Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify(meta)}\r\n--${boundary}\r\nContent-Type: image/jpeg\r\n\r\nabc\r\n--${boundary}--\r\n`);
 await deny(fetch(base+'?name='+encodeURIComponent(f.path),{method:'POST',headers:{...headers(f.owner),'X-Goog-Upload-Protocol':'multipart','Content-Type':`multipart/related; boundary=${boundary}`},body}));
});
test('owner deletion remains available but peers cannot delete or add token metadata',async()=>{
 const f=await setup();await bucket.file(f.path).save(Buffer.from('abc'),{resumable:false,metadata:{contentType:'image/jpeg'}});
 const url=base+'/'+encodeURIComponent(f.path);
 await deny(fetch(url,{method:'PATCH',headers:{...headers(f.owner),'Content-Type':'application/json'},body:JSON.stringify({metadata:{firebaseStorageDownloadTokens:randomUUID()}})}));
 await deny(fetch(url,{method:'DELETE',headers:headers(f.outsider)}));
 assert.ok((await fetch(url,{method:'DELETE',headers:headers(f.owner)})).ok);
});
test('revoking a legacy token removes its bypass while the object remains for server delivery',async()=>{
 const f=await setup(),token=randomUUID(),file=bucket.file(f.path);
 await file.save(Buffer.from('abc'),{resumable:false,metadata:{contentType:'image/jpeg',metadata:{firebaseStorageDownloadTokens:token}}});
 const url=base+'/'+encodeURIComponent(f.path)+'?alt=media&token='+token;
 assert.equal((await fetch(url)).status,200);
 const [meta]=await file.getMetadata();
 await file.setMetadata({metadata:{firebaseStorageDownloadTokens:null}},{ifGenerationMatch:meta.generation,ifMetagenerationMatch:meta.metageneration});
 const denied=await fetch(url); assert.ok([401,403].includes(denied.status), 'Revoked token status: '+denied.status+' '+await denied.text());
 assert.equal((await file.exists())[0],true);
});