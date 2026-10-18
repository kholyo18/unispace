import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:UniSpace/features/shell/chat/voice_capture.dart';

// Structurally valid ADTS headers with dummy payload (no decoding in these tests).
Uint8List frame(int value) => Uint8List.fromList(
    [255, 241, 80, 64, 1, 127, 252, value, value, value, value]);

class Recorder implements VoiceStreamRecorder {
  StreamController<Uint8List>? stream;
  int starts = 0;
  Uint8List? nativeTail;
  bool active = false;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Stream<Amplitude> get amplitudes => const Stream.empty();
  @override
  Future<Stream<Uint8List>> start() async {
    starts++;
    active = true;
    stream = StreamController<Uint8List>();
    return stream!.stream;
  }

  @override
  Future<void> stop() async {
    // Native stop emits its final encoded frame before closing the stream.
    stream!.add(nativeTail ?? frame(starts));
    await stream!.close();
    active = false;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late Directory temp;
  late Recorder recorder;
  late AacVoiceCapture capture;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('voice-test-');
    recorder = Recorder();
    capture = AacVoiceCapture(
        recorder: recorder, temporaryDirectory: () async => temp);
  });
  tearDown(() async {
    await capture.dispose();
    await temp.delete(recursive: true);
  });

  test(
      'pause drains native tail, preview is cached, resume appends full segments',
      () async {
    await capture.start();
    recorder.stream!.add(frame(7));
    await capture.pause();
    final preview = await capture.snapshot();
    expect(await preview.readAsBytes(), [...frame(7), ...frame(1)]);
    expect((await capture.snapshot()).path, preview.path);
    await capture.resume();
    expect(await preview.exists(), false);
    recorder.stream!.add(frame(8));
    final sent = await capture.finish();
    expect(await sent.readAsBytes(),
        [...frame(7), ...frame(1), ...frame(8), ...frame(2)]);
    expect(recorder.active, false);
    await capture.cancel();
    expect(await sent.exists(), true, reason: 'Upload owns final file');
  });

  test('cancel removes local preview and clears earlier audio', () async {
    await capture.start();
    await capture.pause();
    final preview = await capture.snapshot();
    await capture.cancel();
    expect(await preview.exists(), false);
    await capture.start();
    await capture.pause();
    expect(await (await capture.snapshot()).readAsBytes(), frame(2));
  });

  test('split stream chunks are joined before ADTS validation', () async {
    await capture.start();
    final data = frame(9);
    recorder.stream!.add(Uint8List.sublistView(data, 0, 3));
    recorder.stream!.add(Uint8List.sublistView(data, 3));
    await capture.pause();
    expect(
        await (await capture.snapshot()).readAsBytes(), [...data, ...frame(1)]);
  });

  test('native stream errors do not upload a partial draft', () async {
    await capture.start();
    recorder.stream!.addError(StateError('device lost'));
    await capture.pause();
    await expectLater(capture.finish(), throwsStateError);
  });

  test('invalid, truncated and changed-format segments are rejected', () {
    expect(() => validateVoiceAdts(Uint8List(0)), throwsFormatException);
    expect(() => validateVoiceAdts(Uint8List.fromList([1, 2, 3])),
        throwsFormatException);
    expect(() => validateVoiceAdts(Uint8List.sublistView(frame(1), 0, 10)),
        throwsFormatException);
    final changed = frame(2)..[2] = 84;
    expect(
        () => validateVoiceAdts(Uint8List.fromList([...frame(1), ...changed])),
        throwsFormatException);
  });
  test(
      'real encoded AAC segments preserve both tones across preview and resume',
      () async {
    final a = await File('test/fixtures/voice/tone1.aac').readAsBytes();
    final b = await File('test/fixtures/voice/tone2.aac').readAsBytes();
    recorder.nativeTail = a;
    await capture.start();
    await capture.pause();
    expect(await (await capture.snapshot()).readAsBytes(), a);
    recorder.nativeTail = b;
    await capture.resume();
    final file = await capture.finish();
    expect(await file.readAsBytes(), [...a, ...b]);
    final decodeOutput = Platform.environment['VOICE_DECODE_OUTPUT'];
    if (decodeOutput != null) await file.copy(decodeOutput);
  });
}
