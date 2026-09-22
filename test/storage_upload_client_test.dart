import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/storage_upload_client.dart';

void main() {
  late String? uid, session;
  late Map<String, dynamic> response;
  late List<Map<String, dynamic>> calls;
  late List<Map<String, String>> writes;
  late StorageUploadClient client;
  final now = DateTime.fromMillisecondsSinceEpoch(2000000);
  setUp(() {
    uid = 'alice'; session = 'session-1'; calls = []; writes = [];
    response = {'grantId': 'abcdefghijklmnopqrst', 'uid': 'alice', 'path': 'users/alice/avatar.jpg',
      'bucket': 'demo-bucket', 'contentType': 'image/jpeg', 'size': 3, 'expiresAt': 2060000};
    client = StorageUploadClient(currentUid: () => uid, sessionKey: () => session, now: () => now,
      invoke: (data) async { calls.add(Map.of(data)); return response; });
  });
  Future<String> upload({int size = 3}) => client.upload(expectedUid: 'alice', path: 'users/alice/avatar.jpg',
    bucket: 'demo-bucket', contentType: 'image/jpeg', size: size,
    send: (metadata) async { writes.add(metadata); return 'uploaded'; });
  test('production coordinator binds the exact path type size caller and metadata', () async {
    expect(await upload(), 'uploaded');
    expect(calls.single, {'expectedUid': 'alice', 'path': 'users/alice/avatar.jpg', 'contentType': 'image/jpeg', 'size': 3});
    expect(writes.single, {'uploadGrantId': 'abcdefghijklmnopqrst', 'uploadedBy': 'alice'});
  });
  test('signed out caller never requests or starts an upload', () async {
    uid = null; session = null; await expectLater(upload(), throwsStateError); expect(calls, isEmpty); expect(writes, isEmpty);
  });
  test('another caller cannot reuse an upload confirmation', () async {
    uid = 'bob'; await expectLater(upload(), throwsStateError); expect(calls, isEmpty);
  });
  for (final size in [0, -1, 200 * 1024 * 1024 + 1]) {
    test('invalid size $size is rejected before transport', () async {
      await expectLater(upload(size: size), throwsArgumentError); expect(calls, isEmpty); expect(writes, isEmpty);
    });
  }
  for (final entry in <String, dynamic>{'uid': 'bob', 'path': 'users/bob/avatar.jpg', 'bucket': 'other',
    'contentType': 'text/html', 'size': 4, 'grantId': '../invalid', 'expiresAt': 1999999}.entries) {
    test('mismatched ${entry.key} cannot authorize the SDK upload', () async {
      response[entry.key] = entry.value; await expectLater(upload(), throwsStateError); expect(writes, isEmpty);
    });
  }
  test('unreasonably long and non-numeric expiry is rejected', () async {
    for (final value in [9999999999, '2060000', null]) {
      response['expiresAt'] = value; await expectLater(upload(), throwsStateError);
    }
    expect(writes, isEmpty);
  });
  test('no upload fallback is used after a callable error', () async {
    client = StorageUploadClient(currentUid: () => uid, sessionKey: () => session,
      invoke: (_) => Future.error(StateError('permission denied')));
    await expectLater(upload(), throwsStateError); expect(writes, isEmpty);
  });
  test('account switch while waiting for authorization prevents the upload', () async {
    final pending = Completer<Map<String, dynamic>>();
    client = StorageUploadClient(currentUid: () => uid, sessionKey: () => session, now: () => now, invoke: (_) => pending.future);
    final result = upload(); uid = 'bob'; session = 'session-2'; pending.complete(response);
    await expectLater(result, throwsStateError); expect(writes, isEmpty);
  });
  test('replacement session for the same account rejects old authorization', () async {
    final pending = Completer<Map<String, dynamic>>();
    client = StorageUploadClient(currentUid: () => uid, sessionKey: () => session, now: () => now, invoke: (_) => pending.future);
    final result = upload(); session = 'session-2'; pending.complete(response);
    await expectLater(result, throwsStateError); expect(writes, isEmpty);
  });
  test('a completed old upload cannot return into a replacement account scope', () async {
    final pending = Completer<String>(), started = Completer<void>();
    final result = client.upload(expectedUid: 'alice', path: 'users/alice/avatar.jpg', bucket: 'demo-bucket',
      contentType: 'image/jpeg', size: 3, send: (_) { started.complete(); return pending.future; });
    await started.future; uid = 'bob'; session = 'session-2'; pending.complete('uploaded');
    await expectLater(result, throwsStateError);
  });
  test('storage errors propagate without retries or deleting an ambiguously uploaded file', () async {
    var attempts = 0;
    final result = client.upload(expectedUid: 'alice', path: 'users/alice/avatar.jpg', bucket: 'demo-bucket',
      contentType: 'image/jpeg', size: 3, send: (_) { attempts++; return Future<String>.error(StateError('network')); });
    await expectLater(result, throwsStateError); expect(attempts, 1);
  });
}
