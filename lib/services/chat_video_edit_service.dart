import 'dart:io';
import 'package:flutter/services.dart';

class ChatVideoEdit {
  const ChatVideoEdit({
    required this.startMs,
    required this.endMs,
    this.muted = false,
    this.quarterTurns = 0,
  });
  final int startMs;
  final int endMs;
  final bool muted;
  final int quarterTurns;
  bool validFor(int durationMs) =>
      startMs >= 0 &&
      endMs > startMs &&
      endMs <= durationMs &&
      endMs - startMs <= 60000 &&
      quarterTurns >= 0 &&
      quarterTurns <= 3;
  Map<String, Object> arguments(String path) => {
        'path': path,
        'startMs': startMs,
        'endMs': endMs,
        'muted': muted,
        'quarterTurns': quarterTurns,
      };
}

class ChatVideoEditService {
  const ChatVideoEditService({
    this.channel = const MethodChannel('unispace/video_editor'),
  });
  final MethodChannel channel;
  Future<File> export(File input, ChatVideoEdit edit, int durationMs) async {
    if (!edit.validFor(durationMs))
      throw ArgumentError('Invalid video selection');
    final path = await channel.invokeMethod<String>(
      'export',
      edit.arguments(input.path),
    );
    if (path == null || path.isEmpty) throw StateError('No exported video');
    return File(path);
  }

  Future<void> cancel() => channel.invokeMethod<void>('cancel');
  Future<int?> progress() => channel.invokeMethod<int>('progress');
  Future<String?> thumbnail(String path) =>
      channel.invokeMethod<String>('thumbnail', {'path': path});
}
