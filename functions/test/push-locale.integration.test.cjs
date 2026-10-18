const {test,after}=require('node:test');
const assert=require('node:assert/strict');
const {db,auth,FieldValue,Timestamp,fixture,callableRequest,hash,close}=require('./helpers/notification-fixture.cjs');
const {createSyncPushDeviceHandler}=require('../security/push-preferences');
const {createPushNotificationHandler}=require('../security/push-notification');
const {notificationBody}=require('../security/push-notification-text');
after(close);
const prefs={enabled:true,community:true,announcements:true,exams:true};
const sync=createSyncPushDeviceHandler({auth,db,FieldValue});
async function setup(){
 const f=await fixture(); const sid='locale-session';
 await auth.setCustomUserClaims(f.owner.uid,{sid});
 const user=await auth.getUser(f.owner.uid);
 const res=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:user.email,password:'Local-only-test-48!',returnSecureToken:true})});
 assert.equal(res.status,200); f.owner.token=(await res.json()).idToken;
 await db.doc(`users/${f.owner.uid}/sessions/${sid}`).set({sessionId:sid,isRevoked:false,createdAt:Timestamp.fromMillis(42000)});
 f.input=(token,locale)=>({token,sessionId:sid,platform:'android',preferences:prefs,...(locale===undefined?{}:{locale})});
 f.register=async(token,locale)=>sync(callableRequest(f.owner,f.input(token,locale)));
 f.deliver=async(send)=>createPushNotificationHandler({db,auth,messaging:{sendEachForMulticast:send}})({data:await f.ref.get(),params:{userId:f.owner.uid,notifId:f.ref.id}});
 return f;
}
const success=p=>({responses:p.tokens.map(()=>({success:true}))});
test('optional locale defaults to Arabic; all supported locales persist and dispatch independently',async()=>{
 const f=await setup(); const expected=new Map();
 for(const locale of [undefined,'ar','en','fr']){const token=`${f.owner.uid}-${locale}`;await f.register(token,locale); expected.set(token,locale||'ar'); assert.equal((await db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(token)}`).get()).data().locale,locale||'ar');}
 const sent=[]; await f.deliver(async p=>{sent.push(p);return success(p)});
 assert.equal(sent.length,3);assert.equal(sent.flatMap(p=>p.tokens).length,4);
 for(const p of sent){assert.equal(p.data.recipientId,f.owner.uid);assert.equal(p.notification.title,'Verified actor');for(const token of p.tokens)assert.equal(p.notification.body,notificationBody({type:'follow'},expected.get(token)));assert.equal(p.data.message,p.notification.body);}
});
test('unknown or malformed locales reject before registration; detach remains token-only',async()=>{
 const f=await setup();for(const locale of ['', 'de','fr-FR','AR',null,[],{}])await assert.rejects(f.register(`${f.owner.uid}-invalid`,locale),{code:'invalid-argument'});
 assert.equal((await db.collection(`users/${f.owner.uid}/fcm_tokens`).get()).size,0);
 const detach=createSyncPushDeviceHandler({auth,db,FieldValue},true);
 await assert.rejects(detach(callableRequest(f.owner,{token:'x',locale:'en'})),{code:'invalid-argument'});
});
test('later locale batches recheck unread status',async()=>{
 const f=await setup();for(const locale of ['ar','en','fr'])await f.register(`${f.owner.uid}-${locale}`,locale);
 let count=0;await f.deliver(async p=>{count++;await f.ref.update({read:true});return success(p)});assert.equal(count,1);
});
test('later locale batches recheck session revocation',async()=>{
 const f=await setup();for(const locale of ['ar','en','fr'])await f.register(`${f.owner.uid}-${locale}`,locale);
 let count=0;await f.deliver(async p=>{count++;await db.doc(`users/${f.owner.uid}/sessions/locale-session`).update({isRevoked:true});return success(p)});assert.equal(count,1);
});
test('stale response mapping deletes only failed token across locale batches',async()=>{
 const f=await setup();for(const locale of ['ar','en','fr'])await f.register(`${f.owner.uid}-${locale}`,locale);
 await f.deliver(async p=>({responses:p.tokens.map(token=>token.endsWith('-en')?{success:false,error:{code:'messaging/registration-token-not-registered'}}:{success:true})}));
 for(const locale of ['ar','en','fr'])assert.equal((await db.doc(`users/${f.owner.uid}/fcm_tokens/${hash(`${f.owner.uid}-${locale}`)}`).get()).exists,locale!=='en');
});
test('authored system notification content stays verbatim in every locale',async()=>{
 const f=await setup();for(const locale of ['ar','en','fr'])await f.register(`${f.owner.uid}-${locale}`,locale);
 for(const type of ['announcement','exam_reminder']){await f.ref.update({type,message:'Original authored العربية content'});let count=0;await f.deliver(async p=>{count++;assert.equal(p.notification.body,'Original authored العربية content');return success(p)});assert.equal(count,3);}
});
