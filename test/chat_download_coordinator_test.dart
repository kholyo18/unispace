import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_download_coordinator.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late ChatDownloadCoordinator downloads;
  var valid = true;
  var resolves = 0;
  var delay = false;
  setUp(() async {
    valid = true;
    resolves = 0;
    delay = false;
    directory =
        await Directory.systemTemp.createTemp('download-coordinator-test-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.contentLength = 4;
      request.response.add([1, 2]);
      await request.response.flush();
      if (delay) await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        request.response.add([3, 4]);
        await request.response.close();
      } catch (_) {}
    });
    downloads = ChatDownloadCoordinator(
        temporaryDirectory: () async => directory,
        resolve: (_, __) async {
          resolves++;
          if (!valid) throw StateError('Revoked');
          return ChatDownloadSource(
              Uri.parse('http://127.0.0.1:${server.port}/file'));
        });
  });
  tearDown(() async {
    await downloads.clear();
    downloads.dispose();
    await server.close(force: true);
    await directory.delete(recursive: true);
  });
  Future<File> start() => downloads.start(
      scope: 'session/chat',
      session: 'session',
      chatId: 'chat',
      messageId: 'message',
      name: 'file.bin',
      isCurrentSession: () => valid);
  test('completion revalidates and revoke removes only owned files', () async {
    final unrelated =
        await File('${directory.path}/draft').writeAsString('keep');
    final file = await start();
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
    expect(resolves, 2);
    await downloads.revokeScope('session/chat');
    expect(await file.exists(), false);
    expect(await unrelated.readAsString(), 'keep');
  });
  test('cancel cleans partially streamed file and retry authorizes anew',
      () async {
    delay = true;
    final started = Completer<void>();
    downloads.addListener(() {
      if (downloads.jobs.isNotEmpty &&
          downloads.jobs.first.progress != null &&
          !started.isCompleted) started.complete();
    });
    final pending = start();
    final failed = expectLater(pending, throwsA(anything));
    await started.future.timeout(const Duration(seconds: 3));
    downloads.cancel(downloads.jobs.first.id);
    await failed;
    expect(await directory.list().toList(), isEmpty);
    expect(downloads.jobs.first.status, ChatDownloadStatus.cancelled);
    delay = false;
    final file = await downloads.retry(downloads.jobs.first.id);
    expect(await file.exists(), true);
    expect(resolves, 3);
  });
  test('revoked session during transfer prevents retained completion',
      () async {
    delay = true;
    downloads.addListener(() {
      if (downloads.jobs.isNotEmpty && downloads.jobs.first.progress != null)
        valid = false;
    });
    await expectLater(start(), throwsA(anything));
    expect(await directory.list().toList(), isEmpty);
    expect(downloads.jobs.first.status, ChatDownloadStatus.cancelled);
  });
}
