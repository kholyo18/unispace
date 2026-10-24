// Static wiring checks; Dart behavior is covered by executable Flutter tests.
const { test }=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');const root=path.resolve(__dirname,'../..');
const read=p=>require('./support/read-dart-library.cjs')(path.join(root,p));
test('all upload entry points and extracted chat helpers use the guarded service',()=>{
 for(const [file,count] of [['lib/main.dart',8],['lib/features/auth/signup_flow.dart',1],['lib/features/shell/chat_page.dart',3],['lib/features/shell/chat/chat_media_sender.dart',2]]) {
  const s=read(file);assert.equal((s.match(/StorageUploadService\.put(?:Data|File)\(/g)||[]).length,count,file);
  assert.doesNotMatch(s,/\bref\.put(?:Data|File)\(/,file);
 }
});
test('protected uploads stream signed PUTs and trust only server receipts and metadata',()=>{
 const s=read('lib/services/storage_upload_service.dart'),transport=read('lib/services/signed_upload_task.dart');
 assert.match(s,/ProtectedUploadCoordinator\(/);assert.match(s,/httpsCallable\(method\)/);
 assert.match(s,/source: file.openRead/);assert.doesNotMatch(s,/customMetadata|FirebaseFirestore|StorageUploadClient/);
 assert.match(transport,/invoke\('prepareProtectedUpload'/);assert.match(transport,/invoke\('finalizeProtectedUpload'/);
 assert.match(transport,/_client\.putUrl\(upload.uri\)/);assert.match(transport,/request\.addStream/);
 for(const source of [s,transport])assert.doesNotMatch(source,/getDownloadURL|ref\.put(?:Data|File)\(|prepareStorageUpload/);
 const server=read('functions/security/protected-upload.js');
 assert.match(server,/prepareUpload\.authorize\(/);
 assert.match(server,/metadata: \{ protectedUploadVersion: '1', uploadedBy: value.uid, uploadGrantId: value.grantId \}/);
 assert.match(server,/ifGenerationMatch: value.targetGeneration/);
 assert.match(server,/x-goog-if-generation-match': '0'/);
});

test('deployment and emulator configs use release rules and never review snapshots',()=>{
 const f=JSON.parse(read('firebase.json'));assert.equal(f.storage.rules,'storage.rules');assert.equal(f.firestore.rules,'firestore.rules');
 const t=JSON.parse(read('firebase.storage-security-test.json'));
 assert.equal(t.storage.rules,f.storage.rules);assert.equal(t.firestore.rules,f.firestore.rules);
 assert.equal(t.emulators.storage.host,'127.0.0.1');assert.equal(t.emulators.auth.host,'127.0.0.1');
});
test('upload grants are server-only and exported through the guarded callable registry',()=>{
 assert.match(read('functions/index.js'),/exports.prepareStorageUpload = onCall/);
 assert.match(read('firestore.rules'),/match \/storageUploadGrants\/\{grantId\} \{ allow read, write: if false; \}/);
 assert.match(read('storage.rules'),/g\.sessionId == request\.auth\.token\.sid/);assert.match(read('storage.rules'),/storageSessionSchema == 1/);
});
test('grants have account deletion and expiry cleanup paths',()=>{
 const s=read('functions/security/account-deletion-worker.js');
 assert.match(s,/collection\('storageUploadGrants'\)\.where\('uid', '==', uid\)/);
 assert.match(s,/collection\('storageUploadGrants'\)\.where\('expiresAt', '<=', cutoff\)/);
});

test('protected cutover configuration is separate from legacy deployment and blocks SDK reads and writes',()=>{
 const release=JSON.parse(read('firebase.protected-media-release.json')),emulator=JSON.parse(read('firebase.protected-media-test.json'));
 assert.equal(release.storage.rules,'storage.protected.rules');assert.equal(emulator.storage.rules,release.storage.rules);
 assert.equal(emulator.firestore.rules,'firestore.rules');
 for(const name of ['storage','auth','firestore'])assert.equal(emulator.emulators[name].host,'127.0.0.1');
 const rules=read(release.storage.rules);assert.doesNotMatch(rules,/allow\s+(?:read|write|list|get|create|update)\s*:/);
 assert.match(rules,/allow delete: if session\(\)/);
 const index=read('functions/index.js');
 assert.match(index,/exports.prepareProtectedUpload\s*=\s*onCall/);assert.match(index,/exports.finalizeProtectedUpload\s*=\s*onCall/);
});

test('protected staging cleanup and server-only receipts survive until account deletion',()=>{
 const rules=read('firestore.rules');
 assert.match(rules,/match \/protectedUploadTickets\/\{grantId\} \{ allow read, write: if false; \}/);
 assert.match(rules,/match \/maintenanceCursors\/\{cursor\} \{ allow read, write: if false; \}/);
 const worker=read('functions/security/account-deletion-worker.js');
 assert.match(worker,/collection\('protectedUploadTickets'\)\.where\('uid', '==', uid\)/);
 assert.match(worker,/'private_upload_staging\/' \+ uid \+ '\/'/);
 assert.match(read('functions/index.js'),/exports.cleanupProtectedUploadStaging\s*=\s*onSchedule/);
 const cleanup=read('functions/security/protected-upload-cleanup.js');
 assert.match(cleanup,/maintenanceCursors\/protectedUploadStaging/);assert.match(cleanup,/autoPaginate: false/);
 assert.match(cleanup,/ifGenerationMatch:/);assert.doesNotMatch(cleanup,/collection\('protectedUploadTickets'\)/);
});
