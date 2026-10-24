import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:UniSpace/services/signed_upload_task.dart';

class MemoryTransport implements ProtectedUploadTransport {
  final List<int> bytes = [];
  bool closed = false;
  void Function()? afterChunk;
  @override
  Future<void> send(ProtectedUploadRequest request, Stream<List<int>> source,
      int size, void Function(int) progress, void Function() guard) async {
    await for (final chunk in source) {
      guard();
      bytes.addAll(chunk);
      progress(bytes.length);
      afterChunk?.call();
    }
    guard();
  }

  @override
  void close() {
    closed = true;
  }
}

class Fixture {
  String? uid = 'sender', session = 'session-1';
  final transport = MemoryTransport();
  final finalized = Completer<Map<String, dynamic>>();
  int finalCalls = 0, prepareCalls = 0;
  void Function(Map<String, dynamic>)? alterGrant;
  void Function()? afterPrepare;
  late final coordinator = ProtectedUploadCoordinator(
    currentUid: () => uid,
    sessionKey: () => session,
    transportFactory: () => transport,
    invoke: (method, data) async {
      if (method == 'finalizeProtectedUpload') {
        finalCalls++;
        return finalized.future;
      }
      prepareCalls++;
      final grant = <String, dynamic>{
        'grantId': '12345678901234567890',
        'uid': uid,
        'path': 'chats/chat/images/a.jpg',
        'bucket': 'test-bucket',
        'contentType': 'image/jpeg',
        'size': 4,
        'expiresAt': DateTime.now().millisecondsSinceEpoch + 120000,
        'stagingPath': 'private_upload_staging/sender/12345678901234567890',
        'uploadUrl':
            'https://storage.googleapis.com/test-bucket/private_upload_staging/sender/12345678901234567890?signature=test',
        'uploadHeaders': <String, String>{
          'Content-Type': 'image/jpeg',
          'Content-Length': '4',
          'x-goog-if-generation-match': '0',
          'x-goog-meta-uploadedby': 'sender',
          'x-goog-meta-uploadgrantid': '12345678901234567890'
        },
      };
      alterGrant?.call(grant);
      afterPrepare?.call();
      return grant;
    },
  );
  Map<String, dynamic> get receipt => {
        'uid': 'sender',
        'path': 'chats/chat/images/a.jpg',
        'bucket': 'test-bucket',
        'url': ProtectedUploadCoordinator.locator(
            'test-bucket', 'chats/chat/images/a.jpg'),
      };
  Future<Map<String, dynamic>> upload(
          {void Function(ProtectedUploadTask)? onTask}) =>
      coordinator.upload(
          path: 'chats/chat/images/a.jpg',
          bucket: 'test-bucket',
          contentType: 'image/jpeg',
          size: 4,
          source: () => Stream.fromIterable([
                [1, 2],
                [3, 4]
              ]),
          onTask: onTask);
}

void main() {
  test('paused progress observer cannot block committed upload completion',
      () async {
    final f = Fixture();
    f.finalized.complete(f.receipt);
    late StreamSubscription<ProtectedUploadSnapshot> subscription;
    final result = await f.upload(onTask: (task) {
      subscription = task.snapshotEvents.listen((_) {})..pause();
    }).timeout(const Duration(seconds: 1));
    expect(result, f.receipt);
    await subscription.cancel();
  });
  test('progress stays running until finalization returns a validated receipt',
      () async {
    final f = Fixture();
    final events = <ProtectedUploadSnapshot>[];
    late ProtectedUploadTask task;
    final future = f.upload(onTask: (value) {
      task = value;
      value.snapshotEvents.listen(events.add);
    });
    await Future<void>.delayed(Duration.zero);
    expect(f.transport.bytes, [1, 2, 3, 4]);
    expect(f.finalCalls, 1);
    expect(task.snapshot.state, TaskState.running);
    expect(await task.cancel(), false);
    f.finalized.complete(f.receipt);
    expect(await future, f.receipt);
    expect(task.snapshot.state, TaskState.success);
    expect(
        events.map((e) => e.bytesTransferred), containsAllInOrder([0, 2, 4]));
    expect(await task.cancel(), false);
  });
  test('cancellation before preparation performs no request', () async {
    final f = Fixture();
    await expectLater(f.upload(onTask: (task) {
      unawaited(task.cancel());
    }),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'canceled')));
    expect(f.prepareCalls, 0);
    expect(f.finalCalls, 0);
    expect(f.transport.closed, true);
  });
  test('cancellation while streaming stops later chunks and never finalizes',
      () async {
    final f = Fixture();
    late ProtectedUploadTask task;
    f.transport.afterChunk = () {
      unawaited(task.cancel());
    };
    await expectLater(
        f.upload(onTask: (value) => task = value),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'canceled')));
    expect(f.transport.bytes, [1, 2]);
    expect(f.finalCalls, 0);
    expect(task.snapshot.state, TaskState.canceled);
  });
  test('account switch during prepare prevents any upload', () async {
    final f = Fixture()..afterPrepare = null;
    f.afterPrepare = () {
      f.uid = 'other';
    };
    await expectLater(f.upload(), throwsStateError);
    expect(f.transport.bytes, isEmpty);
    expect(f.finalCalls, 0);
  });
  test('same account with a different session cannot finish a pending upload',
      () async {
    final f = Fixture();
    f.transport.afterChunk = () {
      f.session = 'session-2';
    };
    await expectLater(f.upload(), throwsStateError);
    expect(f.transport.bytes, [1, 2]);
    expect(f.finalCalls, 0);
  });
  test('untrusted staging host and changed signed headers are rejected',
      () async {
    for (final corrupt in <void Function(Map<String, dynamic>)>[
      (g) {
        g['uploadUrl'] = 'https://example.com/stolen';
      },
      (g) {
        (g['uploadHeaders'] as Map)['x-goog-if-generation-match'] = '99';
      },
      (g) {
        g['expiresAt'] = 1;
      },
    ]) {
      final f = Fixture()..alterGrant = corrupt;
      await expectLater(f.upload(), throwsStateError);
      expect(f.transport.bytes, isEmpty);
    }
  });
  test('final receipt cannot introduce a permanent bearer token', () async {
    final f = Fixture();
    f.finalized
        .complete({...f.receipt, 'url': '${f.receipt['url']}&token=secret'});
    await expectLater(f.upload(), throwsStateError);
  });
  test('observer exception cancels the unstarted transport', () async {
    final f = Fixture();
    await expectLater(
        f.upload(onTask: (_) => throw StateError('broken observer')),
        throwsStateError);
    expect(f.prepareCalls, 0);
    expect(f.transport.closed, true);
  });
  test('HTTP transport streams an actual file into a PUT before finalization',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final directory =
        await Directory.systemTemp.createTemp('protected-upload-test');
    final file = File('${directory.path}/media.bin');
    final bytes = List.generate(256 * 1024, (i) => i % 251);
    await file.writeAsBytes(bytes);
    final received = Completer<List<int>>();
    server.listen((request) async {
      expect(request.method, 'PUT');
      final data = <int>[];
      await for (final chunk in request) {
        data.addAll(chunk);
      }
      received.complete(data);
      request.response.statusCode = 200;
      await request.response.close();
    });
    final task = ProtectedUploadTask(totalBytes: bytes.length);
    try {
      final result = await task.run(
          prepare: () async => ProtectedUploadRequest(
              Uri.parse('http://127.0.0.1:${server.port}/upload'),
              {'Content-Type': 'application/octet-stream'}),
          source: file.openRead,
          guard: () {},
          finalize: () async => 'committed');
      expect(result, 'committed');
      expect(await received.future, bytes);
      expect(task.snapshot.bytesTransferred, bytes.length);
      expect(task.snapshot.state, TaskState.success);
    } finally {
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
