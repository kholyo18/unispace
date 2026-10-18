import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/shell/chat/chat_media_viewers.dart';
import 'package:UniSpace/services/chat_media_policy.dart';

void main() {
  const source = 'https://firebasestorage.googleapis.com/v0/b/test/o/photo';
  final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j8ioAAAAASUVORK5CYII=');
  testWidgets(
      'fullscreen reuses cached bytes and revocation removes displayed media',
      (tester) async {
    int downloads = 0;
    bool allowed = true;
    final cache = ChatImageMemoryCache(download: (_, __) async {
      downloads++;
      return png;
    });
    await cache.read('session/chat', source, authorized: () => allowed);
    await tester.pumpWidget(MaterialApp(
        home: ChatImageViewer(
            url: source,
            scope: 'session/chat',
            authorized: () => allowed,
            cache: cache)));
    expect(downloads, 1);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
    allowed = false;
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(Image), findsNothing);
    expect(find.text('This media is no longer available'), findsOneWidget);
    expect(cache.sizeBytes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    cache.dispose();
  });
  testWidgets('unauthorized fullscreen never requests bytes', (tester) async {
    int downloads = 0;
    final cache = ChatImageMemoryCache(download: (_, __) async {
      downloads++;
      return png;
    });
    await tester.pumpWidget(MaterialApp(
        home: ChatImageViewer(
            url: source,
            scope: 'session/chat',
            authorized: () => false,
            cache: cache)));
    expect(downloads, 0);
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    cache.dispose();
  });
}
