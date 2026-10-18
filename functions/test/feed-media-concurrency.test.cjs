const {test}=require('node:test');
const assert=require('node:assert/strict');
const {Timestamp}=require('firebase-admin/firestore');
const {createContentSearchPageHandler}=require('../security/content-search-page');
const {createMediaDownloadHandler}=require('../security/media-download');
function fixture(count=8){
 const records=new Map([['users/viewer',{displayName:'Viewer'}]]);
 const docs=Array.from({length:count},(_,n)=>{const id='post'+n,data={authorId:'author'+n,body:'body'+n,createdAt:new Timestamp(100-n,0),imageUrls:[]};records.set('users/author'+n,{displayName:'Author'});records.set('community_posts/'+id,data);return {id,exists:true,data:()=>data};});
 const snap=path=>({exists:records.has(path),data:()=>records.get(path)});
 const db={doc:path=>({path,get:async()=>snap(path)}),runTransaction:async fn=>fn({get:async ref=>snap(ref.path),getAll:async(...refs)=>refs.map(ref=>snap(ref.path)),set:()=>{}}),collection:()=>{const q={orderBy:()=>q,limit:()=>q,get:async()=>({docs,size:docs.length})};return q;}};
 const auth={verifyIdToken:async()=>({uid:'viewer',auth_time:100}),getUser:async()=>({disabled:false})};
 const request=data=>({auth:{uid:'viewer'},rawRequest:{headers:{authorization:'Bearer fixture'}},data});
 return {records,docs,db,auth,request};
}
// Hold all arrivals until the event loop advances, then complete in reverse order.
// No wall-clock threshold is used: the maximum simultaneous operations is observed.
function probe(){let active=0,max=0,pending=[],scheduled=false;return {get max(){return max;},wait:()=>new Promise(resolve=>{active++;max=Math.max(max,active);pending.push(resolve);if(!scheduled){scheduled=true;setImmediate(()=>{const batch=pending;pending=[];scheduled=false;for(const done of batch.reverse()){active--;done();}});}})};}
test('feed overlaps author checks within a bound and preserves query order',async()=>{
 const f=fixture(),p=probe();f.auth.getUser=async uid=>{if(uid!=='viewer')await p.wait();return {disabled:false};};
 const result=await createContentSearchPageHandler(f,false,true)(f.request({cursor:null}));
 assert.ok(p.max>1,'independent author reads must overlap');assert.ok(p.max<=4,'at most four projections in flight');
 assert.deepEqual(result.posts.map(row=>row.id),f.docs.map(row=>row.id));assert.equal(result.cursor.id,'post7');
});
test('feed still hides blocked authors and rejects revoked viewers',async()=>{
 const f=fixture();f.records.set('users/viewer/blocked_accounts/author2',{});
 const run=()=>createContentSearchPageHandler(f,false,true)(f.request({cursor:null}));
 assert.deepEqual((await run()).posts.map(row=>row.id),['post0','post1','post3','post4','post5','post6','post7']);
 f.records.set('authRevocations/viewer',{revokedBefore:100});await assert.rejects(run(),{code:'unauthenticated'});
});
function mediaFixture(){const f=fixture(1),p=probe();const urls=Array.from({length:8},(_,n)=>'https://firebasestorage.googleapis.com/v0/b/demo/o/'+encodeURIComponent('community_posts/post0/'+n+'.jpg'));
 f.records.get('community_posts/post0').imageUrls=urls;let afterSign=()=>{};
 const bucket=()=>({name:'demo',file:path=>({getMetadata:async()=>{await p.wait();return [{generation:'42',size:'100'}];},getSignedUrl:async options=>{assert.deepEqual(options.queryParams,{generation:'42'});afterSign();return ['https://signed.invalid/'+path];}})});
 return {...f,p,urls,bucket,mutate:fn=>{afterSign=fn;}};}
test('media overlaps metadata work within a bound and returns input order',async()=>{
 const f=mediaFixture(),result=await createMediaDownloadHandler(f,true)(f.request({postId:'post0',urls:f.urls}));
 assert.ok(f.p.max>1,'independent metadata reads must overlap');assert.ok(f.p.max<=4);
 assert.deepEqual(result.items.map(item=>item.source),f.urls);
});
test('batch does not disclose URLs when authorization changes during signing',async()=>{
 const f=mediaFixture();f.mutate(()=>f.records.set('users/author0/blocked_accounts/viewer',{}));
 await assert.rejects(createMediaDownloadHandler(f,true)(f.request({postId:'post0',urls:f.urls})),{code:'not-found'});
});
