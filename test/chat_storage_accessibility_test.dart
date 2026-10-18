import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/chat_media_policy.dart';
import 'package:UniSpace/services/chat_local_persistence.dart';
import 'package:UniSpace/features/shell/chat/chat_conversation_storage_page.dart';
import 'package:UniSpace/features/shell/chat/chat_audio_player.dart';

class ProtectedStore extends ChatLocalStorage {
  int calls = 0;
  @override
  bool isCurrent = true;
  @override
  Future<String?> read(String key) async {
    calls++;
    return 'draft';
  }

  @override
  Future<void> write(String key, String? value) async {
    calls++;
  }

  @override
  Future<void> keepFile(String key, File file) async {
    calls++;
  }

  @override
  Future<File?> restoreFile(String key, String extension) async {
    calls++;
    return null;
  }

  @override
  Future<void> purge() async {
    calls++;
  }
}

void main() {
  const small =
      'https://firebasestorage.googleapis.com/v0/b/test/o/chats%2Fa%2Fsmall.png?token=private';
  const large =
      'https://firebasestorage.googleapis.com/v0/b/test/o/chats%2Fa%2Flarge.png?token=private';
  ChatImageMemoryCache cache() => ChatImageMemoryCache(
      download: (uri, _) async =>
          Uint8List(uri.toString().contains('large') ? 200 : 100));
  test('conversation metadata is scoped, sorted and does not expose URLs',
      () async {
    final images = cache();
    await images.read('session/a', small, authorized: () => true);
    await images.read('session/a', large, authorized: () => true);
    await images.read('session/b', small, authorized: () => true);
    final entries = images.describeScope('session/a', authorized: () => true);
    expect(entries.map((e) => e.bytes), [200, 100]);
    expect(entries.first.name, 'large.png');
    expect(entries.first.id, isNot(contains('token')));
    expect(
        images.removeScopedEntry('session/b', entries.first.id,
            authorized: () => true),
        0);
    expect(
        images.removeScopedEntry('session/a', entries.first.id,
            authorized: () => false),
        0);
    expect(
        images.removeScopedEntry('session/a', entries.first.id,
            authorized: () => true),
        200);
    expect(images.sizeBytes, 200);
    expect(images.describeScope('session/a', authorized: () => false), isEmpty);
    images.dispose();
  });
  testWidgets(
      'clearing conversation cache preserves other scopes and encrypted drafts',
      (tester) async {
    final images = cache();
    final store = ProtectedStore();
    await images.read('session/a', small, authorized: () => true);
    await images.read('session/b', large, authorized: () => true);
    await tester.pumpWidget(MaterialApp(
        home: ChatConversationStoragePage(
            scope: 'session/a',
            title: 'Study group',
            authorized: () => true,
            protectedStore: store,
            cache: images)));
    await tester.tap(find.text('Clear this conversation’s image cache'));
    await tester.pump();
    expect(images.sizeBytes, 200);
    expect(store.calls, 0);
    expect(find.text('No cached images for this conversation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    images.dispose();
  });
  testWidgets(
      'stale encrypted session does not expose cache rows or clear action',
      (tester) async {
    final images = cache();
    final store = ProtectedStore()..isCurrent = false;
    await images.read('session/a', small, authorized: () => true);
    await tester.pumpWidget(MaterialApp(
        home: ChatConversationStoragePage(
            scope: 'session/a',
            title: 'Study group',
            authorized: () => true,
            protectedStore: store,
            cache: images)));
    expect(find.text('Conversation unavailable'), findsOneWidget);
    expect(find.text('small.png'), findsNothing);
    expect(store.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    images.dispose();
  });
  testWidgets('audio supports large text and labeled play speed seek actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3)),
            child: Scaffold(
                body: ChatAudioPlayer(
                    url: 'https://example.invalid/audio',
                    scope: 'session/a',
                    mine: false,
                    totalDuration: const Duration(seconds: 12))))));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Play audio'), findsOneWidget);
    expect(find.bySemanticsLabel('Audio position'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Change playback speed: 1.0x'), findsOneWidget);
    expect(tester.getSize(find.bySemanticsLabel('Play audio')).height,
        greaterThanOrEqualTo(48));
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
