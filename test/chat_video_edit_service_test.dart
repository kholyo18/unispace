import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_video_edit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('trim rejects reversed, out-of-source and over-60-second intervals', () {
    expect(
      const ChatVideoEdit(startMs: 0, endMs: 60000).validFor(90000),
      isTrue,
    );
    expect(
      const ChatVideoEdit(startMs: 500, endMs: 500).validFor(90000),
      isFalse,
    );
    expect(
      const ChatVideoEdit(startMs: -1, endMs: 500).validFor(90000),
      isFalse,
    );
    expect(
      const ChatVideoEdit(startMs: 0, endMs: 60001).validFor(90000),
      isFalse,
    );
    expect(
      const ChatVideoEdit(startMs: 0, endMs: 2000).validFor(1000),
      isFalse,
    );
    expect(
      const ChatVideoEdit(
        startMs: 0,
        endMs: 500,
        quarterTurns: 4,
      ).validFor(90000),
      isFalse,
    );
  });
  const channel = MethodChannel('test/video-edit');
  final service = ChatVideoEditService(channel: channel);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'exports actual interval and effects through injected native boundary',
    () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        captured = call;
        return '/cache/edited.mp4';
      });
      final output = await service.export(
        File('/draft/input.mov'),
        const ChatVideoEdit(
          startMs: 1000,
          endMs: 2500,
          muted: true,
          quarterTurns: 1,
        ),
        3000,
      );
      expect(output.path, '/cache/edited.mp4');
      expect(captured?.method, 'export');
      expect(captured?.arguments, {
        'path': '/draft/input.mov',
        'startMs': 1000,
        'endMs': 2500,
        'muted': true,
        'quarterTurns': 1,
      });
    },
  );
  test('invalid trim never calls native exporter', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls++;
      return null;
    });
    await expectLater(
      service.export(
        File('/draft/input.mp4'),
        const ChatVideoEdit(startMs: 0, endMs: 80000),
        90000,
      ),
      throwsArgumentError,
    );
    expect(calls, 0);
  });
  test(
    'native export failure propagates rather than returning source',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'export-failed');
      });
      await expectLater(
        service.export(
          File('/draft/input.mp4'),
          const ChatVideoEdit(startMs: 0, endMs: 1000),
          2000,
        ),
        throwsA(isA<PlatformException>()),
      );
    },
  );
  test('cancel targets exporter instead of deleting original', () async {
    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });
    await service.cancel();
    expect(captured?.method, 'cancel');
  });
}
