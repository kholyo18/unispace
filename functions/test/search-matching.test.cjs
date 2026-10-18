const {test} = require('node:test');
const assert = require('node:assert/strict');
const {matchPerson} = require('../security/search-people');
const {searchKeywords} = require('../security/edit-post');

test('short account prefixes and @handles match', () => {
  assert.ok(matchPerson('u', {firstName:'Amine',username:'amine_42'}, 'ami'));
  assert.ok(matchPerson('u', {firstName:'Amine',username:'amine_42'}, '@ami'));
  assert.ok(matchPerson('u', {firstName:'محمد'}, 'مح'));
});
test('French accents and Arabic marks are normalized', () => {
  assert.ok(matchPerson('u', {firstName:'Élodie'}, 'elodie'));
  assert.ok(matchPerson('u', {firstName:'أحـمد'}, 'احمد'));
  assert.ok(searchKeywords({title:'Économie',body:'',tags:[]}, '').includes('economie'));
});
test('privacy exclusions and contact opt-ins remain enforced', () => {
  for (const fields of [{privacy:{appearInSearch:false}}, {security:{frozen:true}}, {accountStatus:'deleted'}]) {
    assert.equal(matchPerson('u', {firstName:'Amine',...fields}, 'Amine'), null);
  }
  const account = {firstName:'Amine',email:'secret@example.com',phone:'+213555123456'};
  assert.equal(matchPerson('u',account,'secret@example.com'),null);
  assert.equal(matchPerson('u',account,'+213555123456'),null);
  assert.ok(matchPerson('u',{...account,privacy:{findByEmail:true}},'secret@example.com'));
  assert.equal(matchPerson('u',{...account,privacy:{findByEmail:true}},'secret@exam'),null);
});
