import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Pausing finalizes a segment and releases the microphone. AAC/ADTS frames
/// are appended on resume; preview never opens a still-recording MP4 container.
abstract interface class VoiceCapture {
  Future<bool> hasPermission();
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<File> snapshot();
  Future<File> finish();
  Stream<Amplitude> get amplitudes;
  Future<void> cancel();
  Future<void> dispose();
}

abstract interface class VoiceStreamRecorder {
  Future<bool> hasPermission();
  Future<Stream<Uint8List>> start();
  Future<void> stop();
  Stream<Amplitude> get amplitudes;
  Future<void> dispose();
}

class NativeVoiceStreamRecorder implements VoiceStreamRecorder {
  AudioRecorder? _recorder;
  AudioRecorder get recorder => _recorder ??= AudioRecorder();
  @override
  Future<bool> hasPermission() => recorder.hasPermission();
  @override
  Future<Stream<Uint8List>> start() => recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ));
  @override
  Future<void> stop() async {
    await recorder.stop();
  }

  @override
  Stream<Amplitude> get amplitudes =>
      recorder.onAmplitudeChanged(const Duration(milliseconds: 80));
  @override
  Future<void> dispose() async {
    await _recorder?.dispose();
  }
}

class AacVoiceCapture implements VoiceCapture {
  AacVoiceCapture(
      {VoiceStreamRecorder? recorder,
      Future<Directory> Function()? temporaryDirectory})
      : recorder = recorder ?? NativeVoiceStreamRecorder(),
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;
  final VoiceStreamRecorder recorder;
  final Future<Directory> Function() _temporaryDirectory;
  final _chunks = <Uint8List>[];
  final _previews = <File>[];
  Completer<void>? _drained;
  bool _active = false;
  Object? _streamError;
  int _byteCount = 0;

  @override
  Future<bool> hasPermission() => recorder.hasPermission();
  @override
  Stream<Amplitude> get amplitudes => recorder.amplitudes;

  @override
  Future<void> start() async {
    await cancel();
    await resume();
  }

  @override
  Future<void> resume() async {
    if (_active) return;
    for (final file in _previews) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _previews.clear();
    final stream = await recorder.start();
    _active = true;
    final done = Completer<void>();
    _drained = done;
    stream.listen((bytes) {
      _byteCount += bytes.length;
      if (_byteCount > 2 * 1024 * 1024) {
        _streamError = StateError('voice-size-limit');
      } else {
        _chunks.add(Uint8List.fromList(bytes));
      }
    }, onError: (Object error) {
      _streamError = error;
    }, onDone: () => done.complete());
  }

  @override
  Future<void> pause() async {
    if (!_active) return;
    await recorder.stop();
    await _drained?.future;
    _active = false;
  }

  Future<File> _write() async {
    if (_streamError != null) throw StateError('voice-capture-failed');
    if (_chunks.isEmpty) throw StateError('voice-empty');
    final dir = await _temporaryDirectory();
    final file =
        File('${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.aac');
    // Copy the completed frame list before the first asynchronous write.
    final bytes = BytesBuilder(copy: false);
    for (final chunk in _chunks) {
      bytes.add(chunk);
    }
    final data = bytes.takeBytes();
    validateVoiceAdts(data);
    return file.writeAsBytes(data, flush: true);
  }

  @override
  Future<File> snapshot() async {
    if (_active) throw StateError('Pause before preview');
    if (_previews.isNotEmpty) return _previews.last;
    final file = await _write();
    _previews.add(file);
    return file;
  }

  @override
  Future<File> finish() async {
    await pause();
    final file = await _write();
    await cancel();
    return file; // Ownership transfers to the upload/retry path.
  }

  @override
  Future<void> cancel() async {
    await pause();
    _chunks.clear();
    _byteCount = 0;
    _streamError = null;
    for (final file in _previews) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _previews.clear();
  }

  @override
  Future<void> dispose() async {
    try {
      await cancel();
    } finally {
      await recorder.dispose();
    }
  }
}

/// Validate complete ADTS frames and stable decoder configuration across resumes.
/// Transport chunks may split frames; validation runs only after stream drain.
void validateVoiceAdts(Uint8List data) {
  int offset = 0;
  int? format;
  while (offset < data.length) {
    if (data.length - offset < 7 ||
        data[offset] != 0xff ||
        data[offset + 1] & 0xf6 != 0xf0) {
      throw const FormatException('Invalid AAC frame');
    }
    final current = (data[offset + 2] << 2) | (data[offset + 3] >> 6);
    if (format != null && current != format) {
      throw const FormatException('AAC format changed while resuming');
    }
    format = current;
    final length = ((data[offset + 3] & 3) << 11) |
        (data[offset + 4] << 3) |
        (data[offset + 5] >> 5);
    final header = data[offset + 1] & 1 == 1 ? 7 : 9;
    if (length <= header || offset + length > data.length) {
      throw const FormatException('Incomplete AAC frame');
    }
    offset += length;
  }
  if (offset == 0) throw const FormatException('Empty AAC recording');
}
