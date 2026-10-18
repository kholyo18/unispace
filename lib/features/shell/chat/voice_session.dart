import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'voice_capture.dart';

const int kVoiceBarCount = 40;
const Duration kVoiceHoldDelay = Duration(milliseconds: 180);
const double kVoiceLockDy = 78;
const double kVoiceCancelDx = 68;
const Duration kVoiceMinDuration = Duration(milliseconds: 400);
const Duration kVoiceMaxDuration = Duration(seconds: 60);

enum VoicePhase { idle, starting, recording, paused, sending }

abstract interface class VoicePreview {
  Stream<bool> get playing;
  Future<void> load(File file);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class LocalVoicePreview implements VoicePreview {
  LocalVoicePreview() {
    _subscription = _player.playerStateStream.listen((state) {
      _events.add(
          state.playing && state.processingState != ProcessingState.completed);
    }, onError: _events.addError);
  }
  final AudioPlayer _player = AudioPlayer();
  final _events = StreamController<bool>.broadcast();
  late final StreamSubscription<PlayerState> _subscription;
  @override
  Stream<bool> get playing => _events.stream;
  @override
  Future<void> load(File file) async {
    await _player.setFilePath(file.path);
  }

  @override
  Future<void> play() async {
    await _player.seek(Duration.zero);
    // play completes when playback ends; callers must not await that to resume.
    unawaited(_player.play().catchError((Object error) {
      if (!_events.isClosed) _events.addError(error);
    }));
  }

  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _player.dispose();
    await _events.close();
  }
}

class VoiceSessionController extends ChangeNotifier {
  VoiceSessionController(
      {VoiceCapture? capture,
      VoicePreview Function()? previewFactory,
      Stopwatch? clock})
      : _capture = capture ?? AacVoiceCapture(),
        _clock = clock ?? Stopwatch(),
        _previewFactory = previewFactory ?? LocalVoicePreview.new;
  final VoiceCapture _capture;
  final VoicePreview Function() _previewFactory;
  VoicePreview? _preview;
  StreamSubscription<bool>? _previewSub;
  StreamSubscription<Amplitude>? _ampSub;
  Future<void> _queue = Future.value();
  final Stopwatch _clock;
  Timer? _ticker;
  int _pending = 0;
  bool _alive = true;
  VoicePhase phase = VoicePhase.idle;
  String? lastError;
  bool previewPlaying = false;
  final List<double> bars = List.filled(kVoiceBarCount, 0.1);
  double liveLevel = 0;
  bool get busy => _pending > 0;
  bool get recording => phase != VoicePhase.idle;
  bool get paused => phase == VoicePhase.paused;
  bool get live => phase == VoicePhase.recording;
  bool get canResume => paused && elapsed < kVoiceMaxDuration && !busy;
  Duration get elapsed => _clock.elapsed;
  void _emit() {
    if (_alive) notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) {
    if (!_alive) return Future.value();
    _pending++;
    _emit();
    final result = _queue.then((_) async {
      if (!_alive) return;
      lastError = null;
      try {
        await action();
      } catch (error) {
        lastError = error.toString();
      }
    }).whenComplete(() {
      _pending--;
      _emit();
    });
    _queue = result;
    return result;
  }

  static double ampToLevel(double current, double max) {
    // record reports dBFS: 0 is full scale, never silence. Historical max is
    // intentionally ignored so an earlier loud sound cannot pin this meter.
    if (!current.isFinite) return 0;
    final normalized = ((current + 60) / 60).clamp(0.0, 1.0);
    return math.pow(normalized, 0.42).toDouble();
  }

  void _listen() {
    var target = 0.0;
    var sampleAgeMs = 500;
    liveLevel = 0;
    _ampSub = _capture.amplitudes.listen((amp) {
      if (!live) return;
      target = ampToLevel(amp.current, amp.max);
      sampleAgeMs = 0;
    }, onError: (Object _) {
      target = 0;
      sampleAgeMs = 500;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (live) {
        // A stable cadence keeps the history moving even during real silence.
        // A failed/stalled microphone meter decays instead of freezing high.
        sampleAgeMs += 100;
        final level = sampleAgeMs <= 400 ? target : 0.0;
        liveLevel += (level - liveLevel) * (level > liveLevel ? 0.78 : 0.32);
        // Keep the fixed-size buffer: removeAt/add are unsupported by List.filled.
        for (var index = 1; index < bars.length; index++) {
          bars[index - 1] = bars[index];
        }
        bars[bars.length - 1] = (0.07 + liveLevel * 0.93).clamp(0.07, 1.0);
        if (elapsed >= kVoiceMaxDuration && !busy) {
          unawaited(pause()); // Never automatically upload private audio.
        }
      }
      _emit();
    });
  }

  Future<void> _stopMeters() async {
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
  }

  Future<bool> start() async {
    await _run(() async {
      if (phase != VoicePhase.idle) return;
      phase = VoicePhase.starting;
      _emit();
      try {
        if (!await _capture.hasPermission()) {
          lastError = 'mic-permission';
          phase = VoicePhase.idle;
          return;
        }
        if (!_alive) return;
        await _capture.start();
        _clock.reset();
        _clock.start();
        bars.fillRange(0, bars.length, 0.1);
        phase = VoicePhase.recording;
        _listen();
      } catch (_) {
        phase = VoicePhase.idle;
        await _capture.cancel();
        rethrow;
      }
    });
    return _alive && live;
  }

  Future<void> pause() => _run(() async {
        if (!live) return;
        await _capture.pause();
        await _stopMeters();
        phase = VoicePhase.paused;
      });

  Future<void> _stopPreview() async {
    await _preview?.stop();
    previewPlaying = false;
  }

  Future<void> resume() => _run(() async {
        if (!paused || elapsed >= kVoiceMaxDuration) return;
        await _stopPreview();
        await _capture.resume();
        _clock.start();
        phase = VoicePhase.recording;
        _listen();
      });

  Future<void> togglePreview() => _run(() async {
        if (!paused || elapsed < kVoiceMinDuration) return;
        if (previewPlaying) {
          await _stopPreview();
          return;
        }
        final file = await _capture.snapshot();
        if (_preview == null) {
          _preview = _previewFactory();
          _previewSub = _preview!.playing.listen((playing) {
            previewPlaying = playing;
            _emit();
          }, onError: (Object error) {
            previewPlaying = false;
            lastError = error.toString();
            _emit();
          });
        }
        await _preview!.load(file);
        await _preview!.play();
      });

  Future<File?> stopForSend() async {
    File? result;
    await _run(() async {
      if (!live && !paused) return;
      await _stopPreview();
      await _capture.pause();
      await _stopMeters();
      phase = VoicePhase.paused;
      if (elapsed < kVoiceMinDuration) {
        lastError = 'voice-too-short';
        return;
      }
      result = await _capture.finish();
      phase = VoicePhase.idle;
      _clock.reset();
    });
    return result;
  }

  Future<void> stopPreview() => _run(_stopPreview);
  Future<void> cancel() => _run(() async {
        try {
          await _stopPreview();
        } finally {
          try {
            await _capture.cancel();
          } finally {
            await _stopMeters();
            _clock.reset();
            phase = VoicePhase.idle;
          }
        }
      });

  @override
  void dispose() {
    _alive = false;
    _ticker?.cancel();
    // Serialize cleanup behind startup/preview so nothing starts after disposal.
    unawaited(_queue.then((_) async {
      await _stopMeters();
      await _previewSub?.cancel();
      try {
        await _preview?.dispose();
      } finally {
        await _capture.dispose();
      }
    }).catchError((Object error) {
      debugPrint('voice cleanup failed: $error');
    }));
    super.dispose();
  }
}
