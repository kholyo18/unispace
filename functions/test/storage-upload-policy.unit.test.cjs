const { test } = require('node:test');
const assert = require('node:assert/strict');
const { uploadPolicy, audienceAllows, MIB } = require('../security/storage-upload-policy');
const cases = [
  ['users/alice/avatar.jpg','image/jpeg',20,'profile',true],
  ['community_posts/post/images/one.jpg','image/jpeg',20,'post',false],
  ['community_posts/post/videos/one.mov','video/quicktime',200,'post',false],
  ['community_posts/post/comments/alice/comment/media.gif','image/gif',40,'comment',false],
  ['chats/alice_bob/images/one.png','image/png',40,'chat',false],
  ['chats/alice_bob/videos/one.mp4','video/mp4',40,'chat',false],
  ['chats/alice_bob/audio/one.m4a','audio/mp4',40,'chat',false],
  ['chats/alice_bob/files/one.pdf','application/octet-stream',20,'chat',false],
  ['chats/alice_bob/wallpaper/alice.jpg','image/jpeg',20,'wallpaper',true],
];
for (const [path,mime,limit,kind,overwrite] of cases) {
  test(`media contract and exact size boundary: ${kind} ${mime}`, () => {
    const p = uploadPolicy(path,mime,limit*MIB,'alice');
    assert.equal(p.kind,kind); assert.equal(p.overwrite,overwrite); assert.equal(p.size,limit*MIB);
    for (const size of [0,-1,0.5,limit*MIB+1,NaN,Infinity,'3']) assert.throws(()=>uploadPolicy(path,mime,size,'alice'),{code:'invalid-argument'});
  });
}
for (const path of ['users/bob/avatar.jpg','users/alice/../x.jpg','users/alice//x.jpg','users/alice/a/b.jpg',
  'community_posts/post/comments/bob/comment/media.jpg','chats/a/wallpaper/bob.jpg','chats/a/other/a.jpg',
  '/users/alice/x.jpg','users/alice/a\\b.jpg','users/alice/%2F.jpg','users/alice/x\n.jpg']) {
  test(`reject unknown or escaping object path ${JSON.stringify(path)}`,()=>assert.throws(()=>uploadPolicy(path,'image/jpeg',3,'alice')));
}
test('active formats do not accept HTML, SVG or mismatched folder metadata',()=>{
  for (const mime of ['text/html','image/svg+xml','IMAGE/JPEG','image/jpeg; charset=utf8','application/octet-stream']) {
    assert.throws(()=>uploadPolicy('users/alice/a.jpg',mime,3,'alice'));
  }
  assert.throws(()=>uploadPolicy('chats/a/audio/a.jpg','image/jpeg',3,'alice'));
});
test('audience checks preserve default mutual messaging and reject unknown values',()=>{
  assert.equal(audienceAllows(undefined,false,false,'mutual'),false);
  assert.equal(audienceAllows(undefined,true,true,'mutual'),true);
  assert.equal(audienceAllows('followers',true,false,'everyone'),true);
  for(const value of ['none','invalid',{},true]) assert.equal(audienceAllows(value,true,true,'everyone'),false);
});
