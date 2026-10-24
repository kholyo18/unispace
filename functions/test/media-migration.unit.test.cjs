const {test}=require('node:test');const assert=require('node:assert/strict');
const {createLegacyMediaTokenMigration}=require('../security/legacy-media-token-migration');
const {publishedUploadMatches}=require('../security/published-upload');
function setup(policy={}){
 let writes=0;const changed=[];let cursor;
 const meta={generation:'12',metageneration:'3',metadata:{firebaseStorageDownloadTokens:'legacy'}};
 const file={name:'users/owner/avatar.jpg',getMetadata:async()=>[meta],setMetadata:async(value,options)=>{
  changed.push({value,options});meta.metadata.firebaseStorageDownloadTokens=value.metadata.firebaseStorageDownloadTokens;
 }};
 const db={doc:path=>({get:async()=>({data:()=>path==='releasePolicy/android'?policy:cursor}),set:async value=>{writes++;cursor=value;}})};
 const bucket=()=>({getFiles:async({prefix})=>[file.name.startsWith(prefix)?[file]:[],null]});
 return {run:createLegacyMediaTokenMigration({db,bucket}),changed,get writes(){return writes;}};
}
const ready={enabled:true,minimumBuild:2,protectedMediaVerifiedBuild:2,storageCutoverVerified:true};
test('legacy token migration defaults to dry-run with no object or cursor writes',async()=>{
 const f=setup();const result=await f.run();assert.equal(result.found,1);assert.equal(result.revoked,0);assert.equal(f.writes,0);assert.equal(f.changed.length,0);
});
test('token mutation requires the tested enforced version and verified rule cutover',async()=>{
 for(const policy of [{},{...ready,enabled:false},{...ready,storageCutoverVerified:false},{...ready,minimumBuild:3}]){
  const f=setup(policy);await assert.rejects(f.run({apply:true,verifiedBuild:2}));assert.equal(f.changed.length,0);
 }
});
test('migration removes only capability metadata with both version preconditions and verifies removal',async()=>{
 const f=setup(ready),result=await f.run({apply:true,verifiedBuild:2});assert.equal(result.revoked,1);assert.equal(result.complete,true);
 assert.deepEqual(f.changed,[{value:{metadata:{firebaseStorageDownloadTokens:null}},options:{ifGenerationMatch:'12',ifMetagenerationMatch:'3'}}]);
});
test('publication accepts legacy valid tokens and server-finalized tokenless ownership only',()=>{
 const old={size:'3',metadata:{firebaseStorageDownloadTokens:'old'}};
 assert.equal(publishedUploadMatches(old,new URL('https://example.test/?token=old'),'owner'),true);
 assert.equal(publishedUploadMatches(old,new URL('https://example.test/?token=wrong'),'owner'),false);
 const fresh={size:'3',generation:'2',metadata:{protectedUploadVersion:'1',uploadedBy:'owner',uploadGrantId:'abcdefghijklmnopqrst'}};
 assert.equal(publishedUploadMatches(fresh,new URL('https://example.test/?alt=media'),'owner'),true);
 assert.equal(publishedUploadMatches(fresh,new URL('https://example.test/?alt=media'),'other'),false);
 assert.equal(publishedUploadMatches({...fresh,metadata:{}},new URL('https://example.test/?alt=media'),'owner'),false);
 assert.equal(publishedUploadMatches({...fresh,metadata:{...fresh.metadata,firebaseStorageDownloadTokens:'unexpected'}},new URL('https://example.test/?alt=media'),'owner'),false);
});
test('installed Storage SDK sends flat generation preconditions on metadata PATCH',async()=>{
 const {Storage}=require('@google-cloud/storage');
 const storage=new Storage({projectId:'demo-unispace-security'}); const file=storage.bucket('local-contract-bucket').file('users/owner/avatar.jpg');
 let captured;
 storage.request=(options,callback)=>{captured=options;callback(null,{generation:'12',metageneration:'4',metadata:{}});};
 await file.setMetadata({metadata:{firebaseStorageDownloadTokens:null}},{ifGenerationMatch:'12',ifMetagenerationMatch:'3'});
 assert.equal(captured.method,'PATCH');
 assert.equal(captured.qs.ifGenerationMatch,'12');
 assert.equal(captured.qs.ifMetagenerationMatch,'3');
 assert.equal(captured.qs.preconditionOpts,undefined);
});