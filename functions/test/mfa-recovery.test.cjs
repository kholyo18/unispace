const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { createRecoveryHandlers, createFirstFactorVerifier } = require('../security/mfa-recovery');
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host || !/^(127\.0\.0\.1|localhost):\d+$/.test(host)) throw Error('Local Firestore emulator required; production access forbidden.');
const app = initializeApp({projectId:'demo-unispace-security'}, 'recovery-tests');
const db = getFirestore(app);
after(async()=>{ await db.terminate(); await deleteApp(app); });
let sequence=0;
async function fixture() {
  const uid=`recovery-${Date.now()}-${++sequence}`;
  let clock=Date.now();
  const user={uid,email:`${uid}@example.com`,emailVerified:true,disabled:false,
    multiFactor:{enrolledFactors:[{uid:'factor-'+uid,factorId:'totp'}]},tokensValidAfterTime:new Date(clock-10000).toISOString()};
  const calls={verify:0,update:0,revoke:0,failUpdate:false,failSecondRevoke:false};
  const token={uid,auth_time:Math.floor(clock/1000)-1,firebase:{sign_in_second_factor:'totp'}};
  const auth={
    verifyIdToken:async()=>({...token}), getUser:async id=>{assert.equal(id,uid);return structuredClone(user);},
    getUserByEmail:async email=>{if(email!==user.email)throw Error('Unknown');return structuredClone(user);},
    revokeRefreshTokens:async()=>{calls.revoke++;if(calls.failSecondRevoke&&calls.revoke===2)throw Error('Network failure');user.tokensValidAfterTime=new Date(clock).toISOString();},
    updateUser:async(id,data)=>{assert.equal(id,uid);calls.update++;if(calls.failUpdate){calls.failUpdate=false;throw Error('Network failure');}user.multiFactor=data.multiFactor;return structuredClone(user);},
  };
  const verifyFirstFactor=async data=>{
    calls.verify++;
    if(data.password!=='correct-password' && data.googleIdToken!=='valid-google')throw Object.assign(Error('Denied'),{code:'permission-denied'});
    return user.multiFactor.enrolledFactors.length ? {localId:uid,mfaPendingCredential:'server-proof',
      mfaInfo:user.multiFactor.enrolledFactors.map(f=>({mfaEnrollmentId:f.uid}))} : {localId:uid,idToken:'new-id-token'};
  };
  const handlers=createRecoveryHandlers({auth,db,FieldValue,verifyFirstFactor,now:()=>clock});
  const request={auth:{uid},rawRequest:{headers:{authorization:'Bearer signed-token'}},data:{}};
  const generated=await handlers.generate(request);
  const data={provider:'password',email:user.email,password:'correct-password',key:generated.key};
  return {uid,user,token,calls,auth,handlers,request,data,advance:ms=>{clock+=ms;token.auth_time=Math.floor(clock/1000)-1;},now:()=>clock};
}

test('key has 128 bits of random material; database stores only its hash',async()=>{
  const f=await fixture();assert.match(f.data.key,/^[0-9A-F]{4}(-[0-9A-F]{4}){7}$/);
  const stored=(await db.doc(`mfaRecovery/${f.uid}`).get()).data();
  assert.equal(stored.status,'ready');assert.equal(stored.keyHash.length,64);
  assert.ok(!JSON.stringify(stored).includes(f.data.key.replaceAll('-','')));
});
test('issuance requires recent native MFA, matching identity and no caller-supplied target',async()=>{
  const f=await fixture();
  await assert.rejects(f.handlers.generate({...f.request,data:{uid:'victim'}}),{code:'invalid-argument'});
  await assert.rejects(f.handlers.generate({...f.request,auth:{uid:'other'}}),{code:'failed-precondition'});
  f.token.firebase={};await assert.rejects(f.handlers.generate(f.request),{code:'failed-precondition'});
  f.token.firebase={sign_in_second_factor:'totp'};f.token.auth_time-=600;
  await assert.rejects(f.handlers.generate(f.request),{code:'failed-precondition'});
});
test('wrong password or key cannot remove a factor',async()=>{
  const f=await fixture();
  await assert.rejects(f.handlers.recover({data:{...f.data,password:'wrong'}}),{code:'permission-denied'});
  await assert.rejects(f.handlers.recover({data:{...f.data,key:'0'.repeat(32)}}),{code:'permission-denied'});
  assert.equal(f.calls.update,0);assert.equal(f.calls.revoke,0);
});
test('verified recovery revokes old sessions, removes lost TOTP and does not replay mutations',async()=>{
  const f=await fixture();assert.deepEqual(await f.handlers.recover({data:f.data}),{recovered:true});
  assert.equal(f.user.multiFactor.enrolledFactors.length,0);assert.equal(f.calls.update,1);assert.equal(f.calls.revoke,2);
  assert.equal((await db.doc(`mfaRecovery/${f.uid}`).get()).data().status,'complete');
  assert.ok((await db.doc(`authRevocations/${f.uid}`).get()).data().revokedBefore>f.token.auth_time);
  assert.deepEqual(await f.handlers.recover({data:f.data}),{recovered:true});assert.equal(f.calls.update,1);assert.equal(f.calls.revoke,2);
  f.advance(600001);await assert.rejects(f.handlers.recover({data:f.data}),{code:'permission-denied'});
});
test('a second concurrent request cannot perform another recovery',async()=>{
  const f=await fixture();const results=await Promise.allSettled([f.handlers.recover({data:f.data}),f.handlers.recover({data:f.data})]);
  assert.ok(results.some(r=>r.status==='fulfilled'));assert.equal(f.calls.update,1);assert.equal(f.calls.revoke,2);
});
test('failed Auth mutation can be resumed with the same credentials and key',async()=>{
  const f=await fixture();f.calls.failUpdate=true;
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'unavailable'});
  assert.equal((await db.doc(`mfaRecovery/${f.uid}`).get()).data().status,'processing');
  assert.deepEqual(await f.handlers.recover({data:f.data}),{recovered:true});assert.equal(f.user.multiFactor.enrolledFactors.length,0);
});
test('failure after factor removal can resume without issuing a custom token',async()=>{
  const f=await fixture();f.calls.failSecondRevoke=true;
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'unavailable'});
  assert.equal(f.user.multiFactor.enrolledFactors.length,0);
  assert.deepEqual(await f.handlers.recover({data:f.data}),{recovered:true});assert.equal(f.calls.update,1);
});
test('rotation invalidates old keys and changed enrollment invalidates recovery',async()=>{
  const f=await fixture();f.advance(61000);
  const next=await f.handlers.generate(f.request);
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'permission-denied'});
  f.data.key=next.key;f.user.multiFactor.enrolledFactors=[{uid:'new-factor',factorId:'totp'}];
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'permission-denied'});assert.equal(f.calls.update,0);
});
test('rate limit persists failed attempts and rejects before more password verification',async()=>{
  const f=await fixture();for(let i=0;i<10;i++)await assert.rejects(f.handlers.recover({data:{...f.data,password:'wrong'}}));
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'resource-exhausted'});assert.equal(f.calls.verify,10);
  f.advance(900001);assert.deepEqual(await f.handlers.recover({data:f.data}),{recovered:true});
});
test('Google identity is supported; foreign enrollment proof and disabled accounts are rejected',async()=>{
  const f=await fixture();const data={provider:'google',email:f.user.email,googleIdToken:'valid-google',key:f.data.key};
  const foreign=createRecoveryHandlers({auth:f.auth,db,FieldValue,verifyFirstFactor:async()=>({mfaPendingCredential:'foreign',mfaInfo:[{mfaEnrollmentId:'other'}]})});
  await assert.rejects(foreign.recover({data}),{code:'permission-denied'});
  f.user.disabled=true;await assert.rejects(f.handlers.recover({data}),{code:'permission-denied'});
  f.user.disabled=false;assert.deepEqual(await f.handlers.recover({data}),{recovered:true});
});
test('REST adapter uses a fixed endpoint and cannot create a new Google account',async()=>{
  let captured;
  const verify=createFirstFactorVerifier({apiKey:()=> 'configured-key',fetchImpl:async(url,options)=>{
    captured={url,options};return {ok:true,json:async()=>({mfaPendingCredential:'proof'})};
  }});
  await verify({provider:'google',googleIdToken:'a&b'});
  assert.match(captured.url,/^https:\/\/identitytoolkit.googleapis.com\/v1\/accounts:signInWithIdp\?key=configured-key$/);
  const body=JSON.parse(captured.options.body);assert.equal(body.autoCreate,false);assert.equal(body.postBody,'id_token=a%26b&providerId=google.com');
  assert.equal(captured.options.redirect,'error');
  await assert.rejects(createFirstFactorVerifier({apiKey:()=>''})({}),{code:'unavailable'});
});
test('Firestore clients cannot read or replace recovery records or attempt counters',async()=>{
  const f=await fixture();const project='demo-unispace-security';const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
  const t=Math.floor(Date.now()/1000);const token=`${enc({alg:'none',typ:'JWT'})}.${enc({iss:`https://securetoken.google.com/${project}`,aud:project,sub:f.uid,iat:t,exp:t+3600,auth_time:t})}.`;
  for(const document of [`mfaRecovery/${f.uid}`,'mfaRecoveryAttempts/arbitrary']) {
    const url=`http://${host}/v1/projects/${project}/databases/(default)/documents/${document}`;
    for(const method of ['GET','PATCH','DELETE']) {
      const r=await fetch(url,{method,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},...(method==='PATCH'?{body:JSON.stringify({fields:{}})}:{})});
      assert.equal(r.status,403,await r.text());
    }
  }
});

test('a first-factor token alone cannot redeem a ready recovery key',async()=>{
  const f=await fixture();
  const handler=createRecoveryHandlers({auth:f.auth,db,FieldValue,verifyFirstFactor:async()=>({localId:f.uid,idToken:'first-factor-only'})});
  await assert.rejects(handler.recover({data:f.data}),{code:'permission-denied'});
  assert.equal(f.calls.update,0);
});
test('recovery refuses to remove newly added SMS factors',async()=>{
  const f=await fixture();f.user.multiFactor.enrolledFactors.push({uid:'sms-factor',factorId:'phone'});
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'permission-denied'});
  assert.equal(f.calls.update,0);
});
test('fresh native MFA can replace a key after an interrupted operation releases its lease',async()=>{
  const f=await fixture();f.calls.failUpdate=true;
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'unavailable'});
  f.advance(61000);
  const next=await f.handlers.generate(f.request);
  await assert.rejects(f.handlers.recover({data:f.data}),{code:'permission-denied'});
  assert.deepEqual(await f.handlers.recover({data:{...f.data,key:next.key}}),{recovered:true});
});
