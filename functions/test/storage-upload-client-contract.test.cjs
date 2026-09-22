// Static wiring checks; Dart behavior is covered by executable Flutter tests.
const { test }=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');const root=path.resolve(__dirname,'../..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
test('all 17 existing upload sites use the tested guarded service',()=>{
 for(const [file,count] of [['lib/main.dart',8],['lib/features/auth/signup_flow.dart',1],['lib/features/shell/chat_page.dart',8]]) {
  const s=read(file);assert.equal((s.match(/StorageUploadService\.put(?:Data|File)\(/g)||[]).length,count,file);
  assert.doesNotMatch(s,/\bref\.put(?:Data|File)\(/,file);
 }
});
test('metadata authority overrides untrusted custom metadata and uses the real client',()=>{
 const s=read('lib/services/storage_upload_service.dart');assert.match(s,/StorageUploadClient\(/);
 assert.match(s,/\.httpsCallable\('prepareStorageUpload'\)/);assert.match(s,/\.\.\.\?original.customMetadata, \.\.\.grant/);
 assert.doesNotMatch(s,/FirebaseFirestore|catch[\s\S]*?ref\.put/);
});
test('candidate Storage rules stay isolated from production deployment configuration',()=>{
 const f=JSON.parse(read('firebase.json'));assert.equal(f.storage,undefined);
 const t=JSON.parse(read('firebase.storage-security-test.json'));
 assert.equal(t.storage.rules,'security/rules-review/storage.candidate.rules');
 assert.equal(t.emulators.storage.host,'127.0.0.1');assert.equal(t.emulators.auth.host,'127.0.0.1');
});
test('upload grants are server-only and exported through the guarded callable registry',()=>{
 assert.match(read('functions/index.js'),/exports.prepareStorageUpload = onCall/);
 assert.match(read('firestore.rules'),/match \/storageUploadGrants\/\{grantId\} \{ allow read, write: if false; \}/);
 assert.equal(read('firestore.rules'),read('security/rules-review/firestore.candidate.rules'));
});
test('grants have account deletion and expiry cleanup paths',()=>{
 const s=read('functions/security/account-deletion-worker.js');
 assert.match(s,/collection\('storageUploadGrants'\)\.where\('uid', '==', uid\)/);
 assert.match(s,/collection\('storageUploadGrants'\)\.where\('expiresAt', '<=', cutoff\)/);
});
