// Actual client authorization, confined to local Auth/Firestore emulators.
// Admin only seeds fixtures and inspects persisted state, never proves access.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const PROJECT = 'demo-unispace-security';
const fsHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const loopback = /^(localhost|127\.0\.0\.1):\d+$/;
if (!loopback.test(fsHost || '') || !loopback.test(authHost || '') ||
    (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== PROJECT)) {
  throw new Error('Demo project and local Auth/Firestore emulators required.');
}
const app = initializeApp({ projectId: PROJECT }, `activity-${randomUUID()}`);
const db = getFirestore(app);
const base = `http://${fsHost}/v1/projects/${PROJECT}/databases/(default)/documents`;
let author, peer, outsider;
async function signup() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: `activity-${randomUUID()}@example.test`,
      password: 'Local-fixture-password-29!', returnSecureToken: true }),
    signal: AbortSignal.timeout(15000),
  });
  assert.equal(response.ok, true, `Local signup returned ${response.status}`);
  const data = await response.json();
  const claims = JSON.parse(Buffer.from(data.idToken.split('.')[1], 'base64url'));
  return { uid: data.localId, token: data.idToken, authTime: claims.auth_time };
}
before(async () => { [author, peer, outsider] = await Promise.all([signup(), signup(), signup()]); });
after(async () => { await db.terminate(); await deleteApp(app); });
function val(v) {
  if (v instanceof Timestamp) return { timestampValue: v.toDate().toISOString() };
  if (v === null) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(val) } };
  return { mapValue: { fields: fields(v) } };
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, val(v)])); }
async function request(url, actor, body) {
  const response = await fetch(url, { method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(actor ? { Authorization: `Bearer ${actor.token}` } : {}) },
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000) });
  return { status: response.status, data: await response.json() };
}
function write(path, data, mask = Object.keys(data)) {
  return { update: { name: `projects/${PROJECT}/databases/(default)/documents/${path}`, fields: fields(data) },
    updateMask: { fieldPaths: mask } };
}
function commit(actor, writes) { return request(`${base}:commit`, actor, { writes }); }
function patch(path, actor, data, mask) { return commit(actor, [write(path, data, mask)]); }
function nested(path, field, uid, v) { return write(path, { [field]: { [uid]: v } }, [`${field}.${uid}`]); }
function ok(r) { assert.ok(r.status >= 200 && r.status < 300, `Expected success, got ${r.status}: ${r.data.error?.status}`); }
function denied(r) { assert.equal(r.status, 403); assert.equal(r.data.error?.status, 'PERMISSION_DENIED'); }

const oldTime = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
const futureTime = Timestamp.fromDate(new Date('2100-01-01T00:00:00Z'));
function fp(...parts) { return parts.map(p => '`' + p.replaceAll('\\', '\\\\').replaceAll('`', '\\`') + '`').join('.'); }
function stamp(path, field, uid, extra = {}, masks = Object.keys(extra)) {
  const w = write(path, extra, masks);
  w.updateTransforms = [{ fieldPath: fp(field, uid), setToServerValue: 'REQUEST_TIME' }];
  return w;
}
async function fixture(data = {}) {
  const chat = `chats/activity-${randomUUID()}`;
  await db.doc(chat).set({ memberIds: [author.uid, peer.uid], ...data });
  return chat;
}
async function unchanged(path, action) {
  const before = (await db.doc(path).get()).data();
  denied(await action());
  assert.deepEqual((await db.doc(path).get()).data(), before);
}

// Exact failure names are verified against immutable pre-fix main in CI.
test('ACTIVITYREGRESSION: member cannot forge peer seen time', async () => {
  const c = await fixture();
  await unchanged(c, () => commit(author, [stamp(c, 'lastReadAt', peer.uid)]));
});
test('ACTIVITYREGRESSION: parent replacement cannot erase peer seen time', async () => {
  const c = await fixture({ lastReadAt: { [peer.uid]: oldTime } });
  await unchanged(c, () => commit(author, [stamp(c, 'lastReadAt', author.uid, { lastReadAt: {} })]));
});
test('ACTIVITYREGRESSION: own seen time cannot be removed', async () => {
  const c = await fixture({ lastReadAt: { [author.uid]: oldTime } });
  await unchanged(c, () => patch(c, author, {}, [fp('lastReadAt', author.uid)]));
});
test('ACTIVITYREGRESSION: future seen timestamp is denied', async () => {
  const c = await fixture();
  await unchanged(c, () => patch(c, author, { lastReadAt: { [author.uid]: futureTime } }));
});
test('ACTIVITYREGRESSION: member cannot impersonate peer typing', async () => {
  const c = await fixture();
  await unchanged(c, () => commit(author, [stamp(c, 'typing', peer.uid)]));
});
test('ACTIVITYREGRESSION: member cannot erase peer typing', async () => {
  const c = await fixture({ typing: { [peer.uid]: oldTime } });
  await unchanged(c, () => patch(c, author, {}, ['typing']));
});
test('ACTIVITYREGRESSION: arbitrary typing timestamp is denied', async () => {
  const c = await fixture();
  await unchanged(c, () => patch(c, peer, { typing: { [peer.uid]: oldTime } }));
});
test('ACTIVITYREGRESSION: creation cannot prepopulate peer seen state', async () => {
  const c = `chats/activity-create-${randomUUID()}`;
  denied(await commit(author, [stamp(c, 'lastReadAt', peer.uid, { memberIds: [author.uid, peer.uid] })]));
  assert.equal((await db.doc(c).get()).exists, false);
});
test('ACTIVITYREGRESSION: creation cannot prepopulate peer typing', async () => {
  const c = `chats/activity-create-${randomUUID()}`;
  denied(await commit(author, [stamp(c, 'typing', peer.uid, { memberIds: [author.uid, peer.uid] })]));
  assert.equal((await db.doc(c).get()).exists, false);
});
test('ACTIVITYREGRESSION: summary edit cannot hide peer activity rewrite', async () => {
  const c = await fixture({ lastReadAt: { [peer.uid]: oldTime }, lastMessage: 'original' });
  await unchanged(c, () => commit(author, [stamp(c, 'lastReadAt', peer.uid, { lastMessage: 'changed' })]));
});

test('members can mark own read time and reset own unread while preserving peer', async () => {
  const c = await fixture({ unread: { [author.uid]: 2, [peer.uid]: 5 }, lastReadAt: { [peer.uid]: oldTime } });
  const r = await commit(author, [stamp(c, 'lastReadAt', author.uid, { unread: { [author.uid]: 0 } }, [fp('unread', author.uid)])]);
  ok(r);
  const d = (await db.doc(c).get()).data();
  assert.equal(d.unread[author.uid], 0); assert.equal(d.unread[peer.uid], 5);
  assert.deepEqual(d.lastReadAt[peer.uid], oldTime);
  // REQUEST_TIME is not commitTime: compare the server's returned transform result.
  assert.equal(d.lastReadAt[author.uid].toDate().toISOString(),
    new Date(r.data.writeResults[0].transformResults[0].timestampValue).toISOString());
  assert.equal(Object.hasOwn(d, `lastReadAt.${author.uid}`), false);
});
test('repeat read acknowledgements retain peer and use server time', async () => {
  const c = await fixture({ lastReadAt: { [peer.uid]: oldTime } });
  for (let i=0;i<2;i++) ok(await commit(author, [stamp(c, 'lastReadAt', author.uid)]));
  assert.deepEqual((await db.doc(c).get()).data().lastReadAt[peer.uid], oldTime);
});
test('typing starts and stops without erasing another participant', async () => {
  const c = await fixture({ typing: { [author.uid]: oldTime } });
  ok(await commit(peer, [stamp(c, 'typing', peer.uid)]));
  ok(await patch(c, peer, {}, [fp('typing', peer.uid)]));
  assert.deepEqual((await db.doc(c).get()).data().typing, { [author.uid]: oldTime });
});
test('stopping absent own typing is idempotent', async () => {
  const c = await fixture({ typing: { [author.uid]: oldTime } });
  for(let i=0;i<2;i++) ok(await patch(c, peer, {}, [fp('typing', peer.uid)]));
});
test('whole typing map can be removed when all entries belong to caller', async () => {
  const c = await fixture({ typing: { [peer.uid]: oldTime } });
  ok(await patch(c, peer, {}, ['typing']));
  assert.equal(Object.hasOwn((await db.doc(c).get()).data(), 'typing'), false);
});
test('concurrent member timestamp updates preserve both identities', async () => {
  const c = await fixture();
  (await Promise.all([author, peer].map(a => commit(a, [stamp(c, 'lastReadAt', a.uid), stamp(c, 'typing', a.uid)])))).forEach(ok);
  const d = (await db.doc(c).get()).data();
  for(const key of ['lastReadAt','typing']) assert.deepEqual(Object.keys(d[key]).sort(), [author.uid,peer.uid].sort());
});
test('parent replacement can update self while retaining peer values', async () => {
  const c = await fixture({ lastReadAt: { [peer.uid]: oldTime } });
  ok(await commit(author,[stamp(c,'lastReadAt',author.uid,{lastReadAt:{[peer.uid]:oldTime}})]));
  assert.deepEqual((await db.doc(c).get()).data().lastReadAt[peer.uid], oldTime);
});
test('normal direct-chat bootstrap without activity remains valid', async () => {
  const c = `chats/activity-create-${randomUUID()}`;
  ok(await patch(c, author, { type:'direct',memberIds:[author.uid,peer.uid],members:{[author.uid]:{name:'A'},[peer.uid]:{name:'B'}} }));
  ok(await patch(c, peer, { type:'direct',memberIds:[author.uid,peer.uid] }));
});
test('new chats permit empty activity or own server-timestamp values', async () => {
  const c = `chats/activity-create-${randomUUID()}`;
  ok(await patch(c, author, { memberIds:[author.uid,peer.uid],lastReadAt:{},typing:{} }));
  const fresh = `chats/activity-create-${randomUUID()}`;
  ok(await commit(author,[stamp(fresh,'lastReadAt',author.uid,{memberIds:[author.uid,peer.uid]})]));
});
test('third-party activity keys are denied', async () => {
  for(const key of ['lastReadAt','typing']) {
    const c=await fixture(); await unchanged(c,()=>commit(peer,[stamp(c,key,outsider.uid)]));
  }
});
for(const [label,bad] of Object.entries({null:null,number:12,string:'now',bool:true,object:{seconds:12},array:[]})) {
  test(`non-timestamp activity value denied: ${label}`, async () => {
    for(const key of ['lastReadAt','typing']) {
      const c=await fixture(); await unchanged(c,()=>patch(c,author,{[key]:{[author.uid]:bad}}));
    }
  });
}
test('malformed activity containers cannot replace maps', async () => {
  for(const key of ['lastReadAt','typing']) {
    const c=await fixture({[key]:{[peer.uid]:oldTime}});
    for(const bad of [null,[],'bad',1]) await unchanged(c,()=>patch(c,author,{[key]:bad}));
  }
});
test('server timestamp may repair own legacy future value without changing peer', async () => {
  for(const key of ['lastReadAt','typing']) {
    const c=await fixture({[key]:{[author.uid]:futureTime,[peer.uid]:oldTime}});
    ok(await commit(author,[stamp(c,key,author.uid)]));
    const d=(await db.doc(c).get()).data()[key];
    assert.ok(d[author.uid].toMillis()<futureTime.toMillis());assert.deepEqual(d[peer.uid],oldTime);
  }
});
test('unchanged malformed legacy containers permit unrelated summary updates', async () => {
  const c=await fixture({lastReadAt:null,typing:'legacy'});
  ok(await patch(c,author,{lastMessage:'normal'}));
  await unchanged(c,()=>commit(author,[stamp(c,'lastReadAt',author.uid)]));
});
test('literal dotted legacy fields do not become canonical activity', async () => {
  const c=await fixture({[`lastReadAt.${peer.uid}`]:futureTime});
  ok(await commit(author,[stamp(c,'lastReadAt',author.uid)]));
  const d=(await db.doc(c).get()).data();
  assert.equal(d.lastReadAt[peer.uid],undefined);assert.deepEqual(d[`lastReadAt.${peer.uid}`],futureTime);
});
test('mark-read cannot authorize membership replacement', async () => {
  const c=await fixture();
  await unchanged(c,()=>commit(author,[stamp(c,'lastReadAt',author.uid,{memberIds:[author.uid,outsider.uid]})]));
});
test('outsiders and anonymous callers cannot publish activity', async () => {
  const c=await fixture();
  for(const a of [null,outsider]) await unchanged(c,()=>commit(a,[stamp(c,'typing',peer.uid)]));
});
test('removed member cannot publish activity', async () => {
  const c=await fixture(); await db.doc(c).update({memberIds:[author.uid,outsider.uid]});
  await unchanged(c,()=>commit(peer,[stamp(c,'lastReadAt',peer.uid)]));
});
test('revocation and suspension prevent member activity', async () => {
  const c=await fixture(), cutoff=db.doc(`authRevocations/${peer.uid}`);
  await cutoff.set({revokedBefore:peer.authTime});
  try{await unchanged(c,()=>commit(peer,[stamp(c,'lastReadAt',peer.uid)]));}finally{await cutoff.delete();}
  const controls=db.doc(`accountStateControls/${peer.uid}`);
  await controls.set({schemaVersion:1,adminSuspended:true});
  try{await unchanged(c,()=>commit(peer,[stamp(c,'typing',peer.uid)]));}finally{await controls.delete();}
});
test('mixed valid and forged activity is rejected atomically', async () => {
  const c=await fixture();
  await unchanged(c,()=>commit(author,[stamp(c,'typing',author.uid),stamp(c,'lastReadAt',peer.uid)]));
});
test('existing send summary and unread increment remain allowed', async () => {
  const c=await fixture({unread:{[peer.uid]:0},lastReadAt:{[peer.uid]:oldTime}});
  const w=stamp(c,'typing',author.uid,{lastMessage:'hello',lastSenderId:author.uid});
  w.updateTransforms.push({fieldPath:fp('unread',peer.uid),increment:val(1)});
  ok(await commit(author,[w]));
  const d=(await db.doc(c).get()).data();assert.equal(d.unread[peer.uid],1);assert.deepEqual(d.lastReadAt[peer.uid],oldTime);
});
