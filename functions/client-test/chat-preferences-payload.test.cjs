// Actual production Dart payloads -> authenticated client REST writes -> Rules.
// The REST adapter is test-only; this is not a phone/FlutterFire transport test.
const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const fs = require('node:fs');
const PROJECT = 'demo-unispace-security';
const fh = process.env.FIRESTORE_EMULATOR_HOST;
const ah = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const local = /^(localhost|127\.0\.0\.1):\d+$/;
if (!local.test(fh || '') || !local.test(ah || '') || process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw Error('Only loopback Auth/Firestore emulators without production credentials are allowed.');
}
if (!process.env.CHAT_PREFERENCES_PAYLOADS) throw Error('Export production Dart payloads first.');
const fixture = JSON.parse(fs.readFileSync(process.env.CHAT_PREFERENCES_PAYLOADS, 'utf8'));
assert.equal(fixture.uid, '1.preferences.viewer.`dot');
const uid = fixture.uid;
const peerUid = `2.preferences.peer.\`${randomUUID()}`;
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const app = initializeApp({projectId:PROJECT}, `prefs-${randomUUID()}`);
const db = getFirestore(app), auth = getAuth(app);
const base = `http://${fh}/v1/projects/${PROJECT}/databases/(default)/documents`;
const full = `projects/${PROJECT}/databases/(default)/documents`;
let owner, peer;
const docs = [];
async function makeUser(id) {
  await auth.createUser({uid:id});
  const customToken = await auth.createCustomToken(id);
  const response = await fetch(`http://${ah}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo-key`, {
    method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({token:customToken,returnSecureToken:true}), signal:AbortSignal.timeout(15000),
  });
  const body = await response.json();
  assert.equal(response.ok,true); assert.equal(typeof body.idToken,'string');
  return body.idToken;
}
before(async()=>{owner=await makeUser(uid);peer=await makeUser(peerUid);});
after(async()=>{
  await Promise.all(docs.map(path=>db.recursiveDelete(db.doc(path))));
  await Promise.all([uid,peerUid].map(id=>auth.deleteUser(id)));
  await db.terminate();await deleteApp(app);
});
async function seed() {
  const path=`chats/preferences-${randomUUID()}`;docs.push(path);
  await db.doc(path).set({memberIds:[uid,peerUid],
    nicknames:{[uid]:'original',[peerUid]:'peer nickname'},muted:{[uid]:false,[peerUid]:true},
    autoTranslate:{[uid]:false,[peerUid]:false},
    theme:{[uid]:{wallpaper:'photo',wallpaperUrl:'old-url',bubbleColor:1,bubbleGradient:[1,2],untouched:'keep'},
      [peerUid]:{wallpaper:'mint',bubbleColor:2}},
    clearedAt:{[peerUid]:Timestamp.fromMillis(1000)},
  });
  await db.doc(`${path}/messages/preserved`).set({authorId:peerUid,text:'keep history'});
  return path;
}
function fieldPath(parts) { return parts.map(p=>'`'+p.replaceAll('\\','\\\\').replaceAll('`','\\`')+'`').join('.'); }
function value(v) {
  if (v===null) return {nullValue:null};
  if (typeof v==='string') return {stringValue:v};
  if (typeof v==='boolean') return {booleanValue:v};
  if (typeof v==='number'&&Number.isSafeInteger(v)) return {integerValue:String(v)};
  if (Array.isArray(v)) return {arrayValue:{values:v.map(value)}};
  throw Error('Unsupported exported leaf');
}
function encoded(path, data) {
  const masks=[],transforms=[];
  function walk(map,parts=[]) {
    const fields={};
    for(const [key,v] of Object.entries(map)) {
      const partsNext=[...parts,key], field=fieldPath(partsNext);
      if(v && !Array.isArray(v) && typeof v==='object') {
        if(v.__operation==='delete') {masks.push(field);continue;}
        if(v.__operation==='serverTimestamp') {transforms.push({fieldPath:field,setToServerValue:'REQUEST_TIME'});continue;}
        const nested=walk(v,partsNext);
        if(Object.keys(nested).length) fields[key]={mapValue:{fields:nested}};
      } else {masks.push(field);fields[key]=value(v);}
    }
    return fields;
  }
  const fields=walk(data);
  return {update:{name:`${full}/${path}`,fields},updateMask:{fieldPaths:masks},
    ...(transforms.length?{updateTransforms:transforms}:{})};
}
async function send(path,data,token=owner) {
  const response=await fetch(`${base}:commit`, {method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},
    body:JSON.stringify({writes:[encoded(path,data)]}),signal:AbortSignal.timeout(15000)});
  return {status:response.status,body:await response.json()};
}
async function apply(path,name) {
  assert.ok(fixture.writes[name],name);
  const response=await send(path,fixture.writes[name]);
  assert.equal(response.status,200,JSON.stringify(response.body));
  const data=(await db.doc(path).get()).data();
  assert.deepEqual(data.theme[peerUid],{wallpaper:'mint',bubbleColor:2});
  assert.equal(data.nicknames[peerUid],'peer nickname');
  assert.equal(data.muted[peerUid],true);
  return data;
}
test('legacy dotted set characterization: write succeeds but canonical nickname is unchanged',async()=>{
  const path=await seed();const field=`nicknames.${uid}`;
  assert.equal((await send(path,{[field]:'legacy invisible'})).status,200);
  const data=(await db.doc(path).get()).data();
  assert.equal(data.nicknames[uid],'original');assert.equal(data[field],'legacy invisible');
});
test('production nickname payload updates exactly the current viewer entry',async()=>{
  const path=await seed();const data=await apply(path,'nickname');
  assert.equal(data.nicknames[uid],'Study friend');assert.equal(Object.hasOwn(data,`nicknames.${uid}`),false);
});
test('nickname can be cleared using its existing empty string representation',async()=>{
  const data=await apply(await seed(),'nicknameEmpty');assert.equal(data.nicknames[uid],'');
});
test('explicit mute and unmute round trip without touching peer',async()=>{
  const path=await seed();assert.equal((await apply(path,'mute')).muted[uid],true);
  assert.equal((await apply(path,'unmute')).muted[uid],false);
});
test('explicit translation flags persist without touching peer or invoking translation',async()=>{
  const path=await seed();assert.equal((await apply(path,'translate')).autoTranslate[uid],true);
  assert.equal((await apply(path,'translateOff')).autoTranslate[uid],false);
});
test('solid bubble write removes own gradient only and preserves unrelated theme fields',async()=>{
  const data=await apply(await seed(),'solid');
  assert.equal(data.theme[uid].bubbleColor,0xFF112233);assert.equal(Object.hasOwn(data.theme[uid],'bubbleGradient'),false);
  assert.equal(data.theme[uid].wallpaperUrl,'old-url');assert.equal(data.theme[uid].untouched,'keep');
});
test('gradient write removes own color only and preserves wallpaper',async()=>{
  const data=await apply(await seed(),'gradient');
  assert.deepEqual(data.theme[uid].bubbleGradient,[0xFF001100,0xFF002200]);
  assert.equal(Object.hasOwn(data.theme[uid],'bubbleColor'),false);assert.equal(data.theme[uid].wallpaper,'photo');
});
test('preset wallpaper removes own old photo URL without resetting bubble styling',async()=>{
  const data=await apply(await seed(),'preset');
  assert.equal(data.theme[uid].wallpaper,'ocean');assert.equal(Object.hasOwn(data.theme[uid],'wallpaperUrl'),false);
  assert.deepEqual(data.theme[uid].bubbleGradient,[1,2]);
});
test('custom wallpaper updates the canonical two leaves',async()=>{
  const data=await apply(await seed(),'photo');assert.equal(data.theme[uid].wallpaper,'photo');
  assert.equal(data.theme[uid].wallpaperUrl,'https://example.test/photo');assert.equal(data.theme[uid].bubbleColor,1);
});
test('clear-history uses a real server timestamp and retains peer cutoff and actual messages',async()=>{
  const path=await seed();const data=await apply(path,'clear');
  assert.ok(data.clearedAt[uid] instanceof Timestamp);assert.ok(data.clearedAt[uid].toMillis()>1000);
  assert.equal(data.clearedAt[peerUid].toMillis(),1000);assert.equal((await db.doc(`${path}/messages/preserved`).get()).exists,true);
});
test('same exported owner payload is rejected under peer authentication',async()=>{
  const path=await seed();const response=await send(path,fixture.writes.nickname,peer);
  assert.equal(response.status,403);assert.equal(response.body.error.status,'PERMISSION_DENIED');
  assert.equal((await db.doc(path).get()).data().nicknames[uid],'original');
});
test('anonymous caller cannot apply production preference payloads',async()=>{
  const response=await send(await seed(),fixture.writes.mute,null);
  assert.equal(response.status,403);assert.equal(response.body.error.status,'PERMISSION_DENIED');
});
