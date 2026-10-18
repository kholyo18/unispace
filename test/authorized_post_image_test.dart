import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/authorized_post_image.dart';
import 'package:UniSpace/services/post_media_links.dart';

void main() {
  final pixels = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j6WQAAAAASUVORK5CYII=',
  );
  const signed =
      'https://storage.googleapis.com/bucket/photo.jpg?generation=1&X-Goog-Signature=';

  testWidgets(
      'fresh bundle avoids a duplicate call but later activation rechecks',
      (tester) async {
    var reads = 0;
    PostMediaGrant grant() =>
        PostMediaGrant.fromResponse(viewer: 'viewer', postId: 'post', sources: [
          'source'
        ], response: {
          'post': {'id': 'post', 'data': {}},
          'items': [
            {
              'source': 'source',
              'url': '${signed}bundle',
              'expiresAt': DateTime.now().millisecondsSinceEpoch + 60000
            }
          ]
        });
    final bundle = grant();
    Widget page(bool active, PostMediaGrant value) => MaterialApp(
        home: AuthorizedPostImage.testing(
            postId: 'post',
            url: 'source',
            active: active,
            prepare: true,
            grant: value,
            readLink: () async {
              reads++;
              return '${signed}fresh';
            },
            currentViewer: () => 'viewer',
            imageProvider: (_, __) => MemoryImage(pixels)));
    await tester.pumpWidget(page(false, bundle));
    expect(reads, 0);
    expect(find.byType(Image), findsNothing);
    bundle.seal();
    await tester.pumpWidget(page(true, bundle));
    await tester.pump();
    expect(reads, 1);
    expect(find.byType(Image), findsOneWidget);
    final newBundle = grant();
    await tester.pumpWidget(page(true, newBundle));
    await tester.pump();
    expect(reads, 1,
        reason: 'The new response already authorizes this render pass');
    newBundle.seal();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'prepares hidden pixels and reauthorizes activation while retaining the image',
      (tester) async {
    final pending = <Completer<String>>[];
    final keys = <String>[];
    Future<String> read() {
      final c = Completer<String>();
      pending.add(c);
      return c.future;
    }

    Widget page(bool active) => MaterialApp(
            home: AuthorizedPostImage.testing(
          postId: 'post',
          url: 'source',
          active: active,
          prepare: true,
          readLink: read,
          currentViewer: () => 'viewer',
          imageProvider: (_, key) {
            keys.add(key);
            return MemoryImage(pixels);
          },
        ));
    await tester.pumpWidget(page(false));
    expect(pending, hasLength(1));
    pending[0].complete('${signed}first');
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    final hidden = find.byType(Image, skipOffstage: false);
    expect(hidden, findsOneWidget);
    final retained = tester.element(hidden);

    await tester.pumpWidget(page(true));
    expect(pending, hasLength(2),
        reason: 'Prepared bytes do not grant active access');
    expect(find.byType(Image), findsNothing);
    expect(tester.element(hidden), same(retained));
    pending[1].complete('${signed}second');
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(keys[0], keys[1],
        reason: 'Signature rotation retains the immutable byte identity');
    expect(tester.element(find.byType(Image)), same(retained));

    await tester.pumpWidget(page(false));
    expect(pending, hasLength(2),
        reason: 'Hiding an already prepared slide needs no extra request');
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(page(true));
    expect(pending, hasLength(3));
    pending[2].completeError(StateError('Access revoked'));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Could not load the image'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'policy revisions reject stale completions and account changes hide pixels',
      (tester) async {
    final pending = <Completer<String>>[];
    final keys = <String>[];
    String? viewer = 'viewer';
    Widget page(int revision) => MaterialApp(
            home: AuthorizedPostImage.testing(
          postId: 'post',
          url: 'source',
          active: true,
          policyRevision: revision,
          readLink: () {
            final c = Completer<String>();
            pending.add(c);
            return c.future;
          },
          currentViewer: () => viewer,
          imageProvider: (_, key) {
            keys.add(key);
            return MemoryImage(pixels);
          },
        ));
    await tester.pumpWidget(page(0));
    await tester.pumpWidget(page(1));
    pending[0].complete('${signed}old-policy');
    await tester.pump();
    expect(keys, isEmpty);
    expect(find.byType(Image), findsNothing);
    pending[1].complete('${signed}current-policy');
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    viewer = 'other-viewer';
    await tester.pumpWidget(page(1));
    expect(find.byType(Image, skipOffstage: false), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'inactive default does not prepare or render; account swap rejects pending work',
      (tester) async {
    final pending = Completer<String>();
    var calls = 0;
    String? viewer = 'viewer';
    Widget page(bool active) => MaterialApp(
            home: AuthorizedPostImage.testing(
          postId: 'post',
          url: 'source',
          active: active,
          readLink: () {
            calls++;
            return pending.future;
          },
          currentViewer: () => viewer,
          imageProvider: (_, __) => MemoryImage(pixels),
        ));
    await tester.pumpWidget(page(false));
    expect(calls, 0);
    expect(find.byType(Image, skipOffstage: false), findsNothing);
    await tester.pumpWidget(page(true));
    viewer = null;
    pending.complete('${signed}stale-viewer');
    await tester.pump();
    expect(find.byType(Image, skipOffstage: false), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
