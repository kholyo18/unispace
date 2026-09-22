const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { createRevokeAllSessionsHandler } = require('../security/revoke-all-sessions');

const project = 'demo-unispace-security';
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
  throw new Error('Run only through the local Firestore emulator. Production access is forbidden.');
}
const app = initializeApp({ projectId: project });
const db = getFirestore(app);
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const encode = x => Buffer.from(JSON.stringify(x)).toString('base64url');
function token(uid, authTime = 100) {
  const now = Math.floor(Date.now() / 1000);
  return `${encode({alg:'none',typ:'JWT'})}.${encode({
    iss:`https://securetoken.google.com/${project}`,aud:project,sub:uid,user_id:uid,
    iat:now,exp:now+3600,auth_time:authTime,firebase:{sign_in_provider:'password'},
  })}.`;
}
function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([k,v]) => [k,
    v === null ? {nullValue:null} : typeof v === 'boolean' ? {booleanValue:v}
      : typeof v === 'number' ? {integerValue:String(v)}
      : v instanceof Date ? {timestampValue:v.toISOString()} : {stringValue:v},
  ]));
}
async function request(path, {uid, authTime=100, method='GET', body}={}) {
  return fetch(`${base}${path}`, {method, headers:{
    'Content-Type':'application/json',...(uid?{Authorization:`Bearer ${token(uid,authTime)}`}:{})},
    ...(body?{body:JSON.stringify(body)}:{}),
  });
}
async function commit(doc, data, {uid, authTime=100, patch=false, timestamps=[]}={}) {
  return request(':commit', {uid,authTime,method:'POST',body:{writes:[{
    update:{name:`projects/${project}/databases/(default)/documents/${doc}`,fields:fields(data)},
    ...(patch?{updateMask:{fieldPaths:Object.keys(data)}}:{}),
    ...(timestamps.length?{updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))}:{}),
  }]}});
}
async function status(response, expected) {
  assert.equal(response.status,expected,await response.text());
}
function session(id) {
  const date=new Date('2026-01-01T00:00:00Z');
  return {sessionId:id,deviceId:'installation-123',alias:'Phone',platform:'android',model:'Phone',
    manufacturer:'Test',osVersion:'16',appVersion:'1',buildNumber:'1',locale:'ar',
    createdAt:date,lastSeenAt:date,updatedAt:date,isTrusted:false,isRevoked:false,
    revokedAt:null,revokeReason:null,networkType:null};
}
before(async()=>{
  const res=await fetch(`http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`,{method:'DELETE'});
  assert.equal(res.status,200);
});
after(async()=>{await db.terminate();await deleteApp(app);});

test('owner may create/read a session; anonymous and other users cannot',async()=>{
  await status(await commit('users/alice/sessions/a',session('a'),{uid:'alice'}),200);
  await status(await request('/users/alice/sessions/a',{uid:'alice'}),200);
  await status(await request('/users/alice/sessions/a'),403);
  await status(await request('/users/alice/sessions/a',{uid:'bob'}),403);
  await status(await commit('users/alice/sessions/b',session('b'),{uid:'bob'}),403);
});
test('activity and alias updates remain allowed',async()=>{
  await status(await commit('users/alice/sessions/a',{alias:'My phone',lastSeenAt:new Date()},{uid:'alice',patch:true}),200);
});
test('revocation is permanent even when an old client writes isRevoked=false',async()=>{
  await status(await commit('users/alice/sessions/a',{isRevoked:true,revokeReason:'manual'},
    {uid:'alice',patch:true,timestamps:['revokedAt','updatedAt']}),200);
  await status(await commit('users/alice/sessions/a',{isRevoked:false,revokedAt:null,revokeReason:null},
    {uid:'alice',patch:true}),403);
  await status(await request('/users/alice/sessions/a',{uid:'alice',method:'DELETE'}),403);
});
test('legacy sessions can be revoked without allowing arbitrary legacy edits',async()=>{
  await db.doc('users/legacy/sessions/old').set({deviceName:'Old phone',platform:'android'});
  await status(await commit('users/legacy/sessions/old',{deviceName:'Changed'},{uid:'legacy',patch:true}),403);
  await status(await commit('users/legacy/sessions/old',{isRevoked:true,revokeReason:'manual'},
    {uid:'legacy',patch:true,timestamps:['revokedAt','updatedAt']}),200);
});
test('clients cannot read or change the server revocation cutoff',async()=>{
  await db.doc('authRevocations/cutoff-user').set({revokedBefore:100});
  await status(await request('/authRevocations/cutoff-user',{uid:'cutoff-user',authTime:101}),403);
  await status(await commit('authRevocations/cutoff-user',{revokedBefore:0},{uid:'cutoff-user',authTime:101}),403);
});
test('old and equal-time logins lose access; a later login regains access',async()=>{
  await db.doc('users/cutoff-user').set({name:'User'});
  await db.doc('users/cutoff-user/sessions/s').set(session('s'));
  for(const authTime of [99,100]) {
    await status(await request('/users/cutoff-user',{uid:'cutoff-user',authTime}),403);
    await status(await request('/users/cutoff-user/sessions/s',{uid:'cutoff-user',authTime}),403);
    await status(await commit('users/cutoff-user/sessions/new',session('new'),{uid:'cutoff-user',authTime}),403);
    await status(await commit('users/cutoff-user',{name:'Changed'},{uid:'cutoff-user',authTime,patch:true}),403);
  }
  await status(await request('/users/cutoff-user',{uid:'cutoff-user',authTime:101}),200);
  await status(await commit('users/cutoff-user/sessions/new',session('new'),{uid:'cutoff-user',authTime:101}),200);
});
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
  let batch=db.batch();
  for(let i=0;i<401;i++){
    batch.set(db.doc(`users/server-user/sessions/s${i}`),{isRevoked:false});
    if(i===399){await batch.commit();batch=db.batch();}
  }
  await batch.commit();
  await db.doc('users/untouched/sessions/a').set({isRevoked:false});
  const {handler,calls}=backend('server-user');
  assert.deepEqual(await handler(callableRequest('server-user')),{revoked:true});
  assert.deepEqual(calls,['server-user']);
  assert.equal((await db.doc('authRevocations/server-user').get()).data().revokedBefore,200);
  const docs=await db.collection('users/server-user/sessions').get();
  assert.equal(docs.size,401);
  assert.ok(docs.docs.every(d=>d.data().isRevoked===true));
  assert.equal((await db.doc('users/untouched/sessions/a').get()).data().isRevoked,false);
  await assert.rejects(handler(callableRequest('server-user')),e=>e.code==='unauthenticated');
  assert.deepEqual(calls,['server-user']);
});

// Regression/compatibility coverage added after the full-backend audit exposed
// three failures in the inherited session policy. All writes target the emulator.
test('session metadata and trusted-device preferences remain editable',async()=>{
  const path='users/metadata-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'metadata-owner'}),200);
  await status(await commit(path,{alias:'Renamed phone',isTrusted:true,model:'Updated model',
    osVersion:'17',appVersion:'2',buildNumber:'2',locale:'fr',networkType:'wifi'},
    {uid:'metadata-owner',patch:true,timestamps:['lastSeenAt','updatedAt']}),200);
});
test('session heartbeat cannot create a missing record',async()=>{
  await status(await commit('users/missing-owner/sessions/missing',{},
    {uid:'missing-owner',patch:true,timestamps:['lastSeenAt','updatedAt']}),403);
});
test('session identity and original creation time are immutable',async()=>{
  const path='users/immutable-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'immutable-owner'}),200);
  for(const change of [{sessionId:'other'},{deviceId:'other'},{createdAt:new Date()}]) {
    await status(await commit(path,change,{uid:'immutable-owner',patch:true}),403);
  }
});
test('initialization without optional networkType matches the Flutter writer',async()=>{
  const record=session('new');delete record.networkType;
  await status(await commit('users/flutter-owner/sessions/new',record,{uid:'flutter-owner'}),200);
});
test('legacy initialization preserves legacy fields without granting arbitrary edits',async()=>{
  const path='users/legacy-init/sessions/old';
  await db.doc(path).set({deviceName:'Legacy name',platform:'android',legacyValue:'unchanged'});
  const record=session('old');delete record.networkType;
  await status(await commit(path,record,{uid:'legacy-init',patch:true}),200);
  assert.equal((await db.doc(path).get()).data().legacyValue,'unchanged');
  await status(await commit(path,{legacyValue:'forged'},{uid:'legacy-init',patch:true}),403);
  await status(await commit(path,{alias:'New alias'},{uid:'legacy-init',patch:true}),200);
});
test('unknown session fields and malformed metadata are denied',async()=>{
  const path='users/schema-owner/sessions/device';
  await status(await commit(path,{...session('device'),admin:true},{uid:'schema-owner'}),403);
  await status(await commit(path,{...session('device'),sessionId:'wrong'},{uid:'schema-owner'}),403);
  await status(await commit(path,{...session('device'),isTrusted:true},{uid:'schema-owner'}),403);
  await status(await commit(path,session('device'),{uid:'schema-owner'}),200);
  for(const change of [{admin:true},{alias:42},{isTrusted:'true'},{lastSeenAt:'invalid'},
    {isRevoked:'false'},{revokedAt:new Date()},{revokeReason:'forged'}]) {
    await status(await commit(path,change,{uid:'schema-owner',patch:true}),403);
  }
});
test('all current Flutter revocation reasons are allowed with server timestamps',async()=>{
  for(const reason of ['manual','logout_all','logout_all_other']) {
    const path=`users/reasons-owner/sessions/${reason}`;
    await status(await commit(path,session(reason),{uid:'reasons-owner'}),200);
    await status(await commit(path,{isRevoked:true,revokeReason:reason},
      {uid:'reasons-owner',patch:true,timestamps:['revokedAt','updatedAt']}),200);
  }
});
test('forged revocation timestamps and reasons are denied',async()=>{
  const path='users/revocation-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'revocation-owner'}),200);
  await status(await commit(path,{isRevoked:true,revokeReason:'manual',revokedAt:new Date(0),updatedAt:new Date(0)},
    {uid:'revocation-owner',patch:true}),403);
  await status(await commit(path,{isRevoked:true,revokeReason:'unexpected'},
    {uid:'revocation-owner',patch:true,timestamps:['revokedAt','updatedAt']}),403);
});
test('repeat revocation works without allowing revoked-record edits or resurrection',async()=>{
  const path='users/repeat-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'repeat-owner'}),200);
  for(let i=0;i<2;i++)await status(await commit(path,{isRevoked:true,revokeReason:'manual'},
    {uid:'repeat-owner',patch:true,timestamps:['revokedAt','updatedAt']}),200);
  await status(await commit(path,{alias:'not allowed'}, {uid:'repeat-owner',patch:true}),403);
  await status(await commit(path,{}, {uid:'repeat-owner',patch:true,timestamps:['lastSeenAt','updatedAt']}),403);
  await status(await commit(path,session('device'),{uid:'repeat-owner'}),403);
  await status(await request('/'+path,{uid:'repeat-owner',method:'DELETE'}),403);
});
test('session documents cannot be deleted even before revocation',async()=>{
  const path='users/no-delete-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'no-delete-owner'}),200);
  await status(await request('/'+path,{uid:'no-delete-owner',method:'DELETE'}),403);
});
test('active-session and full-session queries remain owner-scoped',async()=>{
  const path='users/list-owner/sessions/device';
  await status(await commit(path,session('device'),{uid:'list-owner'}),200);
  await status(await request('/users/list-owner/sessions',{uid:'list-owner'}),200);
  await status(await request('/users/list-owner/sessions',{uid:'stranger'}),403);
  const body={structuredQuery:{from:[{collectionId:'sessions'}],where:{fieldFilter:{
    field:{fieldPath:'isRevoked'},op:'EQUAL',value:{booleanValue:false},
  }},orderBy:[{field:{fieldPath:'lastSeenAt'},direction:'DESCENDING'}]}};
  await status(await request('/users/list-owner:runQuery',{uid:'list-owner',method:'POST',body}),200);
  await status(await request('/users/list-owner:runQuery',{uid:'stranger',method:'POST',body}),403);
});
test('malformed server cutoff denies profile and session reads',async()=>{
  const uid='malformed-cutoff-owner',path=`users/${uid}/sessions/device`;
  await db.doc(`users/${uid}`).set({displayName:'Owner'});
  await db.doc(path).set(session('device'));
  await db.doc(`authRevocations/${uid}`).set({revokedBefore:'invalid'});
  await status(await request(`/users/${uid}`,{uid}),403);
  await status(await request('/'+path,{uid}),403);
});
