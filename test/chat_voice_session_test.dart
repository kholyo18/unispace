import 'dart:async';
import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:UniSpace/features/shell/chat/voice_capture.dart';
import 'package:UniSpace/features/shell/chat/voice_session.dart';

class Clock extends Stopwatch {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
  @override
  void reset() {
    value = Duration.zero;
  }
}

class Capture implements VoiceCapture {
  bool allowed = true, active = false, disposed = false, failResume = false;
  int starts = 0, resumes = 0, finishes = 0;
  Completer<void>? gate;
  final parts = <int>[];
  final meter = StreamController<Amplitude>.broadcast(sync: true);
  @override
  Future<bool> hasPermission() async => allowed;
  @override
  Future<void> start() async {
    starts++;
    await gate?.future;
    active = true;
    parts.add(1);
  }

  @override
  Future<void> pause() async {
    active = false;
  }

  @override
  Future<void> resume() async {
    if (failResume) throw StateError('native resume failed');
    resumes++;
    active = true;
    parts.add(2);
  }

  @override
  Future<File> snapshot() async {
    expect(active, false, reason: 'Preview must release microphone');
    return File('preview.aac');
  }

  @override
  Future<File> finish() async {
    finishes++;
    return File('final.aac');
  }

  @override
  Future<void> cancel() async {
    active = false;
    parts.clear();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    disposed = true;
    await meter.close();
  }

  @override
  Stream<Amplitude> get amplitudes => meter.stream;
}

class Preview implements VoicePreview {
  final events = StreamController<bool>.broadcast(sync: true);
  bool active = false, failStop = false;
  int loads = 0;
  @override
  Stream<bool> get playing => events.stream;
  @override
  Future<void> load(File file) async {
    loads++;
  }

  @override
  Future<void> play() async {
    active = true;
    events.add(true);
  }

  @override
  Future<void> stop() async {
    if (failStop) throw StateError('player stop failed');
    active = false;
    events.add(false);
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Capture capture;
  late Preview preview;
  late Clock clock;
  late VoiceSessionController session;
  setUp(() {
    capture = Capture();
    preview = Preview();
    clock = Clock();
    session = VoiceSessionController(
        capture: capture, previewFactory: () => preview, clock: clock);
  });
  tearDown(() {
    session.dispose();
  });

  test('preview and resume preserve earlier audio and stop player first',
      () async {
    expect(await session.start(), true);
    clock.value = const Duration(seconds: 2);
    await session.pause();
    await session.togglePreview();
    expect(preview.active, true);
    expect(capture.active, false);
    await session.resume();
    expect(preview.active, false);
    expect(capture.parts, [1, 2]);
    expect(capture.active, true);
    clock.value = const Duration(seconds: 4);
    await session.pause();
    await session.togglePreview();
    expect(preview.loads, 2);
    expect(await session.stopForSend(), isA<File>());
    expect(preview.active, false);
    expect(capture.finishes, 1);
    expect(session.phase, VoicePhase.idle);
  });

  test('concurrent send requests finalize once', () async {
    await session.start();
    clock.value = const Duration(seconds: 1);
    final results =
        await Future.wait([session.stopForSend(), session.stopForSend()]);
    expect(results.whereType<File>(), hasLength(1));
    expect(capture.finishes, 1);
  });

  test('cancel during native startup runs after startup and releases mic',
      () async {
    capture.gate = Completer<void>();
    final start = session.start();
    await Future<void>.delayed(Duration.zero);
    final cancel = session.cancel();
    capture.gate!.complete();
    await start;
    await cancel;
    expect(capture.active, false);
    expect(capture.parts, isEmpty);
    expect(session.phase, VoicePhase.idle);
  });

  test('permission rejection does not start microphone', () async {
    capture.allowed = false;
    expect(await session.start(), false);
    expect(capture.starts, 0);
    expect(session.lastError, 'mic-permission');
  });

  test('short draft remains resumable rather than silently deleted', () async {
    await session.start();
    clock.value = const Duration(milliseconds: 100);
    expect(await session.stopForSend(), isNull);
    expect(session.paused, true);
    expect(session.lastError, 'voice-too-short');
    await session.resume();
    expect(capture.parts, [1, 2]);
  });

  test('failed resume preserves draft for retry and preview', () async {
    await session.start();
    clock.value = const Duration(seconds: 1);
    await session.pause();
    capture.failResume = true;
    await session.resume();
    expect(session.paused, true);
    expect(session.lastError, contains('native resume failed'));
    await session.togglePreview();
    expect(preview.active, true);
    expect(capture.parts, [1]);
  });

  test('duration limit pauses without sending and cannot resume', () async {
    await session.start();
    clock.value = kVoiceMaxDuration;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(session.paused, true);
    expect(capture.active, false);
    expect(capture.finishes, 0);
    await session.resume();
    expect(capture.resumes, 0);
  });
  test('player stop failure does not skip draft and microphone cancellation',
      () async {
    await session.start();
    clock.value = const Duration(seconds: 1);
    await session.pause();
    await session.togglePreview();
    preview.failStop = true;
    await session.cancel();
    expect(capture.active, false);
    expect(capture.parts, isEmpty);
    expect(session.phase, VoicePhase.idle);
    expect(session.lastError, contains('player stop failed'));
  });
  test('dBFS conversion uses current volume including full scale', () {
    expect(VoiceSessionController.ampToLevel(0, 0), 1);
    expect(VoiceSessionController.ampToLevel(-160, 0), 0);
    expect(VoiceSessionController.ampToLevel(-60, 0), 0);
    expect(VoiceSessionController.ampToLevel(-20, 0),
        greaterThan(VoiceSessionController.ampToLevel(-40, 0)));
    expect(VoiceSessionController.ampToLevel(double.nan, 0), 0);
    expect(VoiceSessionController.ampToLevel(double.infinity, 0), 0);
  });

  test('real samples move meter at fixed cadence then stale levels decay', () {
    fakeAsync((async) {
      final capture = Capture();
      final session = VoiceSessionController(capture: capture, clock: Clock());
      session.start();
      async.flushMicrotasks();
      expect(session.live, true);
      capture.meter.add(Amplitude(current: -50, max: 0));
      async.elapse(const Duration(milliseconds: 100));
      final quiet = session.bars.last;
      capture.meter.add(Amplitude(current: 0, max: 0));
      async.elapse(const Duration(milliseconds: 100));
      final loud = session.bars.last;
      expect(session.bars[session.bars.length - 2], quiet);
      expect(loud, greaterThan(quiet));
      async.elapse(const Duration(seconds: 2));
      expect(session.liveLevel, lessThan(0.01));
      expect(session.bars.last, lessThan(loud));
      expect(session.bars, hasLength(kVoiceBarCount));
      capture.meter.add(Amplitude(current: 0, max: 0));
      async.elapse(const Duration(milliseconds: 100));
      final beforeError = session.liveLevel;
      capture.meter.addError(StateError('meter unavailable'));
      async.elapse(const Duration(milliseconds: 100));
      expect(session.liveLevel, lessThan(beforeError));
      expect(session.live, true);
      session.dispose();
      async.flushMicrotasks();
      expect(async.periodicTimerCount, 0);
    });
  });

  test(
      'pause freezes history, resume accepts new samples, restart clears level',
      () async {
    Future<void> nextMeterTick() {
      final done = Completer<void>();
      void changed() {
        if (!done.isCompleted) done.complete();
      }

      session.addListener(changed);
      return done.future
          .timeout(const Duration(seconds: 2))
          .whenComplete(() => session.removeListener(changed));
    }

    await session.start();
    capture.meter.add(Amplitude(current: 0, max: 0));
    await nextMeterTick();
    expect(session.liveLevel, greaterThan(0));
    await session.pause();
    final frozen = List<double>.from(session.bars);
    capture.meter.add(Amplitude(current: -160, max: 0));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(session.bars, frozen);
    await session.resume();
    capture.meter.add(Amplitude(current: -160, max: 0));
    await nextMeterTick();
    expect(session.bars.last, closeTo(0.07, 0.0001));
    capture.meter.add(Amplitude(current: 0, max: 0));
    await nextMeterTick();
    expect(session.bars.last, greaterThan(0.5));
    await session.cancel();
    await session.start();
    expect(session.live, true);
    expect(session.liveLevel, 0);
    expect(session.bars, everyElement(0.1));
    await session.cancel();
  });
}
