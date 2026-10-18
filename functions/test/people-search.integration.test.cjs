const {test, after} = require('node:test');
const assert = require('node:assert/strict');
const {db, auth, fixture, callableRequest, close} = require('./helpers/notification-fixture.cjs');
const {createSearchPeopleHandler} = require('../security/search-people');
after(close);
const handler = createSearchPeopleHandler({db, auth});
test('people search returns Arabic/French prefixes and handles through real Auth/Firestore', async () => {
  const f = await fixture();
  const unique = f.owner.uid.toLowerCase();
  await db.doc(`users/${f.owner.uid}`).set({firstName:'أحـمد',lastName:'Élodie',username:unique});
  for (const query of ['احمد', 'elodie', '@'+unique]) {
    const result = await handler(callableRequest(f.actor, {query}));
    assert.ok(result.people.some(p => p.id === f.owner.uid), query);
    assert.ok(result.people.every(p => p.id !== f.actor.uid));
  }
});
test('privacy opt-out, both block directions and disabled accounts stay excluded', async () => {
  const f = await fixture();
  const query = f.owner.uid.toLowerCase();
  const ref = db.doc(`users/${f.owner.uid}`);
  await ref.set({username:query});
  const search = () => handler(callableRequest(f.actor,{query}));
  assert.ok((await search()).people.some(p=>p.id===f.owner.uid));
  await ref.update({'privacy.appearInSearch':false});
  assert.equal((await search()).people.length,0);
  await ref.update({'privacy.appearInSearch':true});
  for (const [a,b] of [[f.owner,f.actor],[f.actor,f.owner]]) {
    const block = db.doc(`users/${a.uid}/blocked_accounts/${b.uid}`);
    await block.set({});
    assert.equal((await search()).people.length,0);
    await block.delete();
  }
  await auth.updateUser(f.owner.uid,{disabled:true});
  assert.equal((await search()).people.length,0);
});
test('unauthenticated and revoked viewers cannot search',async()=>{
  await assert.rejects(handler(callableRequest(null,{query:'amine'})),{code:'unauthenticated'});
  const f = await fixture();
  await db.doc(`authRevocations/${f.actor.uid}`).set({revokedBefore:f.actor.authTime});
  await assert.rejects(handler(callableRequest(f.actor,{query:'amine'})),{code:'unauthenticated'});
});
