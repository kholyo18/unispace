import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:UniSpace/features/shell/chat/chat_audio_player.dart';
import 'package:UniSpace/features/shell/chat/chat_policy_image.dart';
import 'package:UniSpace/services/chat_media_policy.dart';
import 'package:UniSpace/services/chat_audio_coordinator.dart';

class PendingAudio extends VideoPlayerController {
  PendingAudio(this.pending)
      : super.networkUrl(Uri.parse('https://example.invalid/audio'));
  final Completer<void> pending;
  int plays = 0, pauses = 0, disposals = 0;
  @override
  Future<void> initialize() async {
    await pending.future;
    value = const VideoPlayerValue(
        duration: Duration(seconds: 2), isInitialized: true);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {}
  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  // ignore: must_call_super
  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class AllowedPolicy extends ChatMediaPolicy {
  @override
  Future<bool> allowsAutomatic() async => true;
}

void main() {
  testWidgets('delayed audio initialization cannot autoplay in background',
      (tester) async {
    final pending = Completer<void>();
    final player = PendingAudio(pending);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatAudioPlayer(
                url: 'https://example.invalid/audio',
                scope: 'session/chat',
                mine: false,
                totalDuration: const Duration(seconds: 2),
                controllerFactory: (_) => player))));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    pending.complete();
    await tester.pump();
    await tester.pump();
    expect(player.plays, 0);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(player.disposals, 1);
    await chatAudioCoordinator.stop();
  });
  testWidgets('closing an initializing audio player releases late controller',
      (tester) async {
    final pending = Completer<void>();
    final player = PendingAudio(pending);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ChatAudioPlayer(
                url: 'https://example.invalid/audio',
                scope: 'session/chat',
                mine: false,
                totalDuration: const Duration(seconds: 2),
                controllerFactory: (_) => player))));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    await tester.pump();
    expect(player.plays, 0);
    expect(player.disposals, 1);
  });
  testWidgets('same image starts automatic loading after membership is granted',
      (tester) async {
    bool authorized = false;
    int downloads = 0;
    final cache = ChatImageMemoryCache(download: (_, __) async {
      downloads++;
      return Uint8List(0);
    });
    final policy = AllowedPolicy();
    Widget page() => MaterialApp(
        home: Scaffold(
            body: ChatPolicyImage(
                source:
                    'https://firebasestorage.googleapis.com/v0/b/test/o/photo',
                scope: 'session/chat',
                authorized: () => authorized,
                cache: cache,
                policy: policy)));
    await tester.pumpWidget(page());
    await tester.pump();
    expect(downloads, 0);
    authorized = true;
    await tester.pumpWidget(page());
    await tester.pump();
    await tester.pump();
    expect(downloads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    cache.dispose();
    policy.dispose();
  });
}

