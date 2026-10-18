const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const project = 'demo-unispace-security';
if (!/^127\.0\.0\.1:\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || '') ||
    process.env.GCLOUD_PROJECT !== project || !process.env.FIREBASE_TOOLS_LIB) {
  throw Error('Local demo Firestore emulator and FIREBASE_TOOLS_LIB required; production forbidden.');
}
// These flags are confined to this local emulator test process.
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIREBASE_DEBUG_MODE = 'true';
process.env.FIREBASE_DEBUG_FEATURES = JSON.stringify({ skipTokenVerification: true });
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { beforeUserSignedIn } = require('firebase-functions/v2/identity');
const { createSignInSessionHandler, createRevokeDeviceSessionsHandler, assertActiveSession, createSessionGuard } = require('../security/device-sessions');
const express = require('express');
const { createApp } = require(process.env.FIREBASE_TOOLS_LIB + '/emulator/auth/server');
const deployed = require('../index');
const app = require('firebase-admin/app').getApp();
const db = getFirestore(app), auth = getAuth(app);
const issue = createSignInSessionHandler({ db, FieldValue });
const revoke = createRevokeDeviceSessionsHandler({ auth, db, FieldValue });
let authServer, hookServer, storage;
const decode = token => JSON.parse(Buffer.from(token.split('.')[1], 'base64url'));
async function api(path, data, method = 'POST') {
  const response = await fetch('http://127.0.0.1:9099/' + path, {
    method, headers: { 'Content-Type': 'application/json', ...(path.startsWith('emulator/') ? {Authorization:'Bearer owner'} : {}) },
    body: JSON.stringify(data),
  });
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  return body;
}
const signIn = (email, password) => api('identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake', {email,password,returnSecureToken:true});
const refresh = refreshToken => api('securetoken.googleapis.com/v1/token?key=fake', {grantType:'refresh_token',refreshToken});
async function loginPair() {
  const email = randomUUID() + '@example.test', password = 'Emulator-only-password-734!';
  const first = await api('identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake', {email,password,returnSecureToken:true});
  const second = await signIn(email, password);
  await db.doc('users/' + first.localId).set({name:'Test',accountStatus:'active'});
  return { a:first, b:second, uid:first.localId, email, password };
}
async function request(login, data) {
  return { auth: {uid:login.localId, token:await auth.verifyIdToken(login.idToken)}, data,
    rawRequest:{headers:{authorization:'Bearer '+login.idToken}} };
}
async function docRequest(path, login, method='GET', body) {
  const response = await fetch('http://' + process.env.FIRESTORE_EMULATOR_HOST +
    '/v1/projects/'+project+'/databases/(default)/documents/'+path, {
    method, headers:{Authorization:'Bearer '+login.idToken, 'Content-Type':'application/json'},
    ...(body ? {body:JSON.stringify(body)} : {}),
  });
  return response.status;
}
before(async () => {
  const { EmulatorRegistry } = require(process.env.FIREBASE_TOOLS_LIB + '/emulator/registry');
  const { StorageEmulator } = require(process.env.FIREBASE_TOOLS_LIB + '/emulator/storage');
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  EmulatorRegistry.set('firestore', {getInfo:()=>({host,port:Number(port)})});
  const rulesPath=require('node:path').resolve(__dirname,'../../storage.rules');
  storage=new StorageEmulator({projectId:project,host:'127.0.0.1',port:9199,
    rules:{name:rulesPath,content:require('node:fs').readFileSync(rulesPath,'utf8')}});
  EmulatorRegistry.set('storage', storage);
  await storage.start();
  const authApp = await createApp(project, 2);
  authServer = await new Promise(resolve => { const server = authApp.listen(9099,'127.0.0.1',()=>resolve(server)); });
  const serverApp = express();
  serverApp.use(express.json());
  serverApp.post('/sign-in', beforeUserSignedIn(issue));
  hookServer = await new Promise(resolve => { const server = serverApp.listen(0,'127.0.0.1',()=>resolve(server)); });
  await api('emulator/v1/projects/'+project+'/config', {
    blockingFunctions:{triggers:{beforeSignIn:{functionUri:'http://127.0.0.1:'+hookServer.address().port+'/sign-in'}}},
  }, 'PATCH');
});
after(async () => {
  if (hookServer) await new Promise(resolve=>hookServer.close(resolve));
  if (authServer) await new Promise(resolve=>authServer.close(resolve));
  if (storage) await storage.stop();
  await db.terminate(); await deleteApp(app);
});

test('real Auth signup and second login have independent server sessions and preserve provider', async () => {
  const f = await loginPair(), a=decode(f.a.idToken), b=decode(f.b.idToken);
  assert.match(a.sid,/^[a-f0-9]{64}$/); assert.notEqual(a.sid,b.sid);
  assert.equal(a.firebase.sign_in_provider,'password');
  await assertActiveSession({db,token:await auth.verifyIdToken(f.a.idToken)});
  await assertActiveSession({db,token:await auth.verifyIdToken(f.b.idToken)});
});
test('hook retry is idempotent and never resurrects a revoked row', async () => {
  const event={eventId:randomUUID(),data:{uid:'retry-'+randomUUID()}};
  const a=await issue(event), b=await issue(event);
  assert.deepEqual(a,b);
  await db.doc('users/'+event.data.uid+'/sessions/'+a.sessionClaims.sid).update({isRevoked:true});
  await assert.rejects(issue(event),{code:'permission-denied'});
});
test('selected revocation rejects old and refreshed token while current device stays active', async () => {
  const f=await loginPair(), sid=decode(f.a.idToken).sid;
  await revoke(await request(f.b,{mode:'single',sessionId:sid}));
  await assert.rejects(assertActiveSession({db,token:await auth.verifyIdToken(f.a.idToken)}),{code:'unauthenticated'});
  const refreshed=await refresh(f.a.refreshToken);
  const token=refreshed.id_token || refreshed.idToken;
  assert.equal(decode(token).sid,sid);
  await assert.rejects(assertActiveSession({db,token:await auth.verifyIdToken(token)}),{code:'unauthenticated'});
  await assertActiveSession({db,token:await auth.verifyIdToken(f.b.idToken)});
  const renewed=await signIn(f.email,f.password);
  assert.notEqual(decode(renewed.idToken).sid,sid);
});
test('all-other operation covers over 400 records and protects the signed current session', async () => {
  const f=await loginPair();
  const collection=db.collection('users/'+f.uid+'/sessions');
  for(let offset=0;offset<401;offset+=200) {
    const batch=db.batch();
    for(let i=offset;i<Math.min(offset+200,401);i++) batch.set(collection.doc('legacy-'+i),{isRevoked:false});
    await batch.commit();
  }
  await revoke(await request(f.b,{mode:'others'}));
  const current=decode(f.b.idToken).sid;
  const docs=await collection.get();
  assert.ok(docs.docs.every(d=>d.id===current ? d.data().isRevoked===false : d.data().isRevoked===true));
  await assertActiveSession({db,token:await auth.verifyIdToken(f.b.idToken)});
});
test('foreign target, forged exemption and revoked actor are denied', async () => {
  const f=await loginPair(), other=await loginPair();
  await assert.rejects(revoke(await request(f.b,{mode:'single',sessionId:decode(other.a.idToken).sid})),{code:'not-found'});
  await assert.rejects(revoke(await request(f.b,{mode:'others',currentSessionId:decode(f.a.idToken).sid})),{code:'invalid-argument'});
  await revoke(await request(f.b,{mode:'single',sessionId:decode(f.a.idToken).sid}));
  await assert.rejects(revoke(await request(f.a,{mode:'others'})),{code:'unauthenticated'});
});
test('callable wrapper denies revoked authenticated calls and preserves signed-out recovery', async () => {
  const f=await loginPair();
  const wrapped=createSessionGuard({db})(async()=>({allowed:true}));
  assert.deepEqual(await wrapped(await request(f.a,{})),{allowed:true});
  await revoke(await request(f.b,{mode:'single',sessionId:decode(f.a.idToken).sid}));
  await assert.rejects(wrapped(await request(f.a,{})),{code:'unauthenticated'});
  assert.deepEqual(await wrapped({data:{}}),{allowed:true});
});
test('rules deny revoked and refreshed device but retain live device reads', async () => {
  const f=await loginPair(), path='users/'+f.uid;
  assert.equal(await docRequest(path,f.a),200);
  await revoke(await request(f.b,{mode:'single',sessionId:decode(f.a.idToken).sid}));
  assert.equal(await docRequest(path,f.a),403);
  const refreshed=await refresh(f.a.refreshToken);
  assert.equal(await docRequest(path,{idToken:refreshed.id_token||refreshed.idToken}),403);
  assert.equal(await docRequest(path,f.b),200);
});
test('clients cannot forge, delete or resurrect server session authority', async () => {
  const f=await loginPair(), sid=decode(f.a.idToken).sid, path='users/'+f.uid+'/sessions/'+sid;
  assert.equal(await docRequest(path,f.b,'DELETE'),403);
  assert.equal(await docRequest(path,f.b,'PATCH',{fields:{authSessionVersion:{integerValue:'1'},isRevoked:{booleanValue:false}}}),403);
  const missing='users/'+f.uid+'/sessions/'+'a'.repeat(64);
  assert.equal(await docRequest(missing,f.b,'PATCH',{fields:{isRevoked:{booleanValue:false}}}),403);
});
test('global cutoff and malformed claim still deny access', async () => {
  const f=await loginPair(), token=await auth.verifyIdToken(f.a.idToken);
  for(const sid of [undefined,'', '../bad','b'.repeat(64)]) {
    await assert.rejects(assertActiveSession({db,token:{...token,sid}}),{code:'unauthenticated'});
  }
  await db.doc('authRevocations/'+f.uid).set({revokedBefore:token.auth_time});
  await assert.rejects(assertActiveSession({db,token}),{code:'unauthenticated'});
  assert.equal(await docRequest('users/'+f.uid,f.a),403);
});


test('all configured callable exports enforce selective revocation', async () => {
  const f=await loginPair();
  await revoke(await request(f.b,{mode:'single',sessionId:decode(f.a.idToken).sid}));
  const req=await request(f.a,{});
  const callables=Object.entries(deployed).filter(([,fn])=>fn.__endpoint?.callableTrigger);
  assert.ok(callables.length >= 40, 'The configured entrypoint must be covered');
  for(const [name,fn] of callables) {
    await assert.rejects(fn.run(req), e=>e.code==='unauthenticated', name);
  }
});
test('current device metadata and other-device alias work without changing authority', async () => {
  const f=await loginPair(), a=decode(f.a.idToken).sid, b=decode(f.b.idToken).sid;
  async function update(sid,login,data,timestamps=['updatedAt']) {
    const fields=Object.fromEntries(Object.entries(data).map(([k,v])=>[k,typeof v==='boolean'?{booleanValue:v}:{stringValue:v}]));
    const result=await fetch('http://'+process.env.FIRESTORE_EMULATOR_HOST+'/v1/projects/'+project+'/databases/(default)/documents:commit',{
      method:'POST',headers:{Authorization:'Bearer '+login.idToken,'Content-Type':'application/json'},
      body:JSON.stringify({writes:[{update:{name:'projects/'+project+'/databases/(default)/documents/users/'+f.uid+'/sessions/'+sid,fields},
        updateMask:{fieldPaths:Object.keys(data)},
        updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))}]}),
    });
    return result.status;
  }
  assert.equal(await update(a,f.a,{deviceId:'installation-a',alias:'Phone',model:'Android',platform:'android'},['updatedAt','lastSeenAt']),200);
  assert.equal(await update(a,f.b,{alias:'My phone',isTrusted:true}),200);
  assert.equal(await update(a,f.b,{model:'forged device'}),403);
  assert.equal(await update(a,f.a,{deviceId:'replacement'}),403);
  assert.equal(await update(a,f.a,{isRevoked:true}),403);
  await revoke(await request(f.b,{mode:'single',sessionId:a}));
  assert.equal(await update(a,f.b,{alias:'resurrected'}),403);
  assert.equal(await docRequest('users/'+f.uid+'/sessions/'+a,f.a),200);
  assert.equal(await docRequest('users/'+f.uid+'/sessions/'+b,f.a),403);
  assert.equal(await docRequest('users/'+f.uid+'/sessions',f.a),403);
  assert.equal(await docRequest('users/'+f.uid+'/sessions',f.b),200);
});
test('authenticated Storage reads and writes reject revoked tokens and retain the other device', async () => {
  const f=await loginPair(), path='users/'+f.uid+'/avatar.jpg';
  const base='http://127.0.0.1:9199/v0/b/'+project+'.appspot.com/o';
  const put=login=>fetch(base+'?uploadType=media&name='+encodeURIComponent(path),{
    method:'POST',headers:{Authorization:'Bearer '+login.idToken,'Content-Type':'image/jpeg'},body:Buffer.from([1,2,3]),
  });
  const read=login=>fetch(base+'/'+encodeURIComponent(path)+'?alt=media',{headers:{Authorization:'Bearer '+login.idToken}});
  let r=await put(f.a); assert.equal(r.status,200,await r.text());
  r=await read(f.b);assert.equal(r.status,200,await r.text());
  await revoke(await request(f.b,{mode:'single',sessionId:decode(f.a.idToken).sid}));
  r=await read(f.a);assert.equal(r.status,403,await r.text());
  r=await put(f.a);assert.equal(r.status,403,await r.text());
  const refreshed=await refresh(f.a.refreshToken);
  r=await read({idToken:refreshed.id_token||refreshed.idToken});assert.equal(r.status,403,await r.text());
  r=await read(f.b);assert.equal(r.status,200,await r.text());
  r=await put(f.b);assert.equal(r.status,200,await r.text());
});

