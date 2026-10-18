const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { createRevokeAllSessionsHandler } = require('../security/revoke-all-sessions');
const { createSignInSessionHandler, createRevokeDeviceSessionsHandler } = require('../security/device-sessions');
const project='demo-unispace-security', host=process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local Firestore emulator required; production forbidden.');
const app=initializeApp({projectId:project}), db=getFirestore(app);
const base='http://'+host+'/v1/projects/'+project+'/databases/(default)/documents';
const encode=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const issue=createSignInSessionHandler({db,FieldValue});
async function actor(uid='actor-'+randomUUID()) {
  const {sessionClaims:{sid}}=await issue({eventId:randomUUID(),data:{uid}});
  await db.doc('users/'+uid).set({name:'Owner'});
  return {uid,sid,authTime:100};
}
function token(a) {
  const now=Math.floor(Date.now()/1000);
  return encode({alg:'none',typ:'JWT'})+'.'+encode({iss:'https://securetoken.google.com/'+project,
    aud:project,sub:a.uid,user_id:a.uid,iat:now,exp:now+3600,auth_time:a.authTime,sid:a.sid,
    firebase:{sign_in_provider:'password'}})+'.';
}
function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([k,v])=>[k,
    v===null?{nullValue:null}:typeof v==='boolean'?{booleanValue:v}:typeof v==='number'?{integerValue:String(v)}
      :v instanceof Date?{timestampValue:v.toISOString()}:{stringValue:v}]));
}
async function http(path,a,method='GET',body) {
  return fetch(base+path,{method,headers:{'Content-Type':'application/json',...(a?{Authorization:'Bearer '+token(a)}:{})},
    ...(body?{body:JSON.stringify(body)}:{})});
}
async function patch(path,a,data,timestamps=['updatedAt']) {
  return http(':commit',a,'POST',{writes:[{update:{name:'projects/'+project+'/databases/(default)/documents/'+path,fields:fields(data)},
    updateMask:{fieldPaths:Object.keys(data)},updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))}]});
}
async function status(r,want){assert.equal(r.status,want,await r.text());}
const path=a=>'users/'+a.uid+'/sessions/'+a.sid;
async function revoke(a,target=a.sid) {
  const auth={verifyIdToken:async()=>({uid:a.uid,sid:a.sid,auth_time:a.authTime})};
  return createRevokeDeviceSessionsHandler({auth,db,FieldValue})({
    auth:{uid:a.uid},rawRequest:{headers:{authorization:'Bearer local-test'}},data:{mode:'single',sessionId:target}});
}
after(async()=>{await db.terminate();await deleteApp(app);});

test('server creates sessions; owner reads while anonymous and other users cannot',async()=>{
  const a=await actor(),b=await actor();
  await status(await http('/'+path(a),a),200);
  await status(await http('/'+path(a)),403);
  await status(await http('/'+path(a),b),403);
  await status(await patch('users/'+a.uid+'/sessions/forged',a,{isRevoked:false}),403);
});
test('activity and aliases remain allowed with server timestamps',async()=>{
  const a=await actor();
  await status(await patch(path(a),a,{alias:'My phone'},['updatedAt','lastSeenAt']),200);
});
test('revocation cannot be undone or deleted even by another active device',async()=>{
  const a=await actor(),b=await actor(a.uid);await revoke(b,a.sid);
  await status(await patch(path(a),b,{isRevoked:false,revokedAt:null,revokeReason:null}),403);
  await status(await http('/'+path(a),b,'DELETE'),403);
});
test('legacy sessions can be revoked through server only',async()=>{
  const a=await actor();
  const old='b'.repeat(64);
  await db.doc('users/'+a.uid+'/sessions/'+old).set({deviceName:'Old phone',platform:'android'});
  await status(await patch('users/'+a.uid+'/sessions/'+old,a,{deviceName:'Changed'}),403);
  await revoke(a,old);
  assert.equal((await db.doc('users/'+a.uid+'/sessions/'+old).get()).data().isRevoked,true);
});
test('clients cannot read or change the server revocation cutoff',async()=>{
  const a=await actor();
  await status(await http('/authRevocations/'+a.uid,a),403);
  await status(await patch('authRevocations/'+a.uid,a,{revokedBefore:0}),403);
});
test('old and equal-time logins lose data access; later authenticated session remains usable',async()=>{
  const a=await actor();await db.doc('authRevocations/'+a.uid).set({revokedBefore:100});
  for(const authTime of [99,100]) {
    await status(await http('/users/'+a.uid,{...a,authTime}),403);
    await status(await patch('users/'+a.uid,{...a,authTime},{name:'Changed'},[]),403);
  }
  await status(await http('/users/'+a.uid,{...a,authTime:101}),200);
});
test('revoked sessions reject heartbeat, alias changes and full replacement',async()=>{
  const a=await actor(),b=await actor(a.uid);await revoke(b,a.sid);
  for(const data of [{alias:'Restored'},{isTrusted:true},{isRevoked:false}]) await status(await patch(path(a),b,data),403);
  await status(await patch(path(a),a,{},['lastSeenAt','updatedAt']),403);
});
test('session identity stays immutable while current metadata refreshes',async()=>{
  const a=await actor();
  await status(await patch(path(a),a,{deviceId:'installation',model:'Phone',appVersion:'2',isTrusted:true},['lastSeenAt','updatedAt']),200);
  for(const data of [{sessionId:'other'},{deviceId:'other'},{createdAt:new Date()},{authSessionVersion:2},{role:'admin'}]) {
    await status(await patch(path(a),a,data),403);
  }
});
test('metadata and trusted-device preferences remain editable',async()=>{
  const a=await actor(),b=await actor(a.uid);
  await status(await patch(path(a),a,{alias:'Renamed',isTrusted:true,model:'Phone',osVersion:'17',appVersion:'2',buildNumber:'2',locale:'fr'},['lastSeenAt','updatedAt']),200);
  await status(await patch(path(a),b,{alias:'My other phone',isTrusted:false}),200);
});
test('heartbeat cannot create a missing record',async()=>{
  const a=await actor();await status(await patch('users/'+a.uid+'/sessions/missing',a,{},['lastSeenAt','updatedAt']),403);
});
test('initialization without optional networkType matches Flutter metadata writer',async()=>{
  const a=await actor();await status(await patch(path(a),a,{deviceId:'installation',alias:'Phone',model:'Phone',platform:'android',manufacturer:'Test',osVersion:'16',appVersion:'1',buildNumber:'1',locale:'ar'},['lastSeenAt','updatedAt']),200);
});
test('legacy initialization cannot promote a client-created record to authority',async()=>{
  const a=await actor(),p='users/'+a.uid+'/sessions/legacy';
  await db.doc(p).set({deviceName:'Legacy',platform:'android',legacyValue:'unchanged'});
  await status(await patch(p,a,{authSessionVersion:1,sessionId:a.sid,isRevoked:false}),403);
  assert.equal((await db.doc(p).get()).data().legacyValue,'unchanged');
});
test('unknown fields and malformed metadata are denied',async()=>{
  const a=await actor();
  for(const data of [{admin:true},{alias:42},{isTrusted:'true'},{lastSeenAt:'invalid'},{isRevoked:'false'},{revokedAt:new Date()},{revokeReason:'forged'}]) {
    await status(await patch(path(a),a,data),403);
  }
});
test('forged revocation timestamps and reasons are denied',async()=>{
  const a=await actor();await status(await patch(path(a),a,{isRevoked:true,revokeReason:'manual',revokedAt:new Date(0)},[]),403);
  await status(await patch(path(a),a,{isRevoked:true,revokeReason:'unexpected'}),403);
});
test('repeat selective revocation is idempotent without resurrection',async()=>{
  const a=await actor(),b=await actor(a.uid);
  await revoke(b,a.sid);await revoke(b,a.sid);
  await status(await patch(path(a),b,{alias:'not allowed'}),403);
  await status(await patch(path(a),a,{},['lastSeenAt','updatedAt']),403);
});
test('session documents cannot be deleted even before revocation',async()=>{
  const a=await actor();await status(await http('/'+path(a),a,'DELETE'),403);
});
test('active and full session queries stay owner scoped',async()=>{
  const a=await actor(),b=await actor();
  await status(await http('/users/'+a.uid+'/sessions',a),200);
  await status(await http('/users/'+a.uid+'/sessions',b),403);
  const body={structuredQuery:{from:[{collectionId:'sessions'}],where:{fieldFilter:{field:{fieldPath:'isRevoked'},op:'EQUAL',value:{booleanValue:false}}},orderBy:[{field:{fieldPath:'lastSeenAt'},direction:'DESCENDING'}]}};
  await status(await http('/users/'+a.uid+':runQuery',a,'POST',body),200);
  await status(await http('/users/'+a.uid+':runQuery',b,'POST',body),403);
});
test('malformed cutoff denies profile and other session reads',async()=>{
  const a=await actor(),b=await actor(a.uid);await db.doc('authRevocations/'+a.uid).set({revokedBefore:'invalid'});
  await status(await http('/users/'+a.uid,a),403);
  await status(await http('/'+path(b),a),403);
});

// Retained global logout handler regression coverage.
function backend(uid,{authTime=100,cutoff=200,invalid=false}={}) {
  const calls=[];
  const auth={
    verifyIdToken:async(_,checkRevoked)=>{assert.equal(checkRevoked,true);if(invalid)throw Error('revoked');return{uid,auth_time:authTime};},
    revokeRefreshTokens:async target=>{calls.push(target);},
    getUser:async()=>({tokensValidAfterTime:new Date(cutoff*1000).toISOString()}),
  };
  return {handler:createRevokeAllSessionsHandler({auth,db,FieldValue}),calls};
}
function callableRequest(uid,data={}) {return {auth:{uid},data,rawRequest:{headers:{authorization:'Bearer test-token'}}};}
test('callable rejects anonymous, foreign targets, mismatched uid and revoked tokens',async()=>{
  const {handler,calls}=backend('caller');
  await assert.rejects(handler({data:{}}),e=>e.code==='unauthenticated');
  await assert.rejects(handler(callableRequest('caller',{uid:'victim'})),e=>e.code==='invalid-argument');
  await assert.rejects(handler(callableRequest('victim')),e=>e.code==='unauthenticated');
  await assert.rejects(backend('caller',{invalid:true}).handler(callableRequest('caller')),e=>e.code==='unauthenticated');
  assert.deepEqual(calls,[]);
});
test('server revokes only the authenticated user, including more than one batch',async()=>{
  const uid='server-user-'+randomUUID(), untouched='untouched-'+randomUUID();
  let batch=db.batch();
  for(let i=0;i<401;i++){
    batch.set(db.doc(`users/${uid}/sessions/s${i}`),{isRevoked:false});
    if(i===399){await batch.commit();batch=db.batch();}
  }
  await batch.commit();
  await db.doc('users/'+untouched+'/sessions/a').set({isRevoked:false});
  const {handler,calls}=backend(uid);
  assert.deepEqual(await handler(callableRequest(uid)),{revoked:true});
  assert.deepEqual(calls,[uid]);
  assert.equal((await db.doc('authRevocations/'+uid).get()).data().revokedBefore,200);
  const docs=await db.collection('users/'+uid+'/sessions').get();
  assert.equal(docs.size,401);
  assert.ok(docs.docs.every(d=>d.data().isRevoked===true));
  assert.equal((await db.doc('users/'+untouched+'/sessions/a').get()).data().isRevoked,false);
  await assert.rejects(handler(callableRequest(uid)),e=>e.code==='unauthenticated');
  assert.deepEqual(calls,[uid]);
});

