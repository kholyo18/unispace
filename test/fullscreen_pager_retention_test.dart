import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/main.dart' show authorizedPagerMediaForTesting;
import 'package:UniSpace/services/post_media_links.dart';
import 'package:cloud_functions/cloud_functions.dart';

class _Lifetime extends StatefulWidget {
  const _Lifetime(
      {required this.active, required this.created, required this.disposed});
  final bool active;
  final VoidCallback created, disposed;
  @override
  State<_Lifetime> createState() => _LifetimeState();
}

class _LifetimeState extends State<_Lifetime> {
  @override
  void initState() {
    super.initState();
    widget.created();
  }

  @override
  void dispose() {
    widget.disposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('media:${widget.active}');
}

class _Harness {
  final requests = <Completer<void>>[];
  final policy = ValueNotifier<int>(0);
  final auth = StreamController<String?>.broadcast(sync: true);
  String? viewer = 'viewer';
  int created = 0, disposed = 0;
  final grants = <bool>[];
  Widget build({bool active = true, bool prepare = true}) => MaterialApp(
        home: authorizedPagerMediaForTesting(
          postId: 'post',
          active: active,
          prepare: prepare,
          authorize: (_) {
            final request = Completer<void>();
            requests.add(request);
            return request.future;
          },
          viewer: () => viewer,
          viewerChanges: auth.stream,
          policyChanges: [policy],
          builder: (allowed, revision) {
            grants.add(allowed);
            return _Lifetime(
                active: allowed,
                created: () => created++,
                disposed: () => disposed++);
          },
        ),
      );
  Future<void> grant(WidgetTester tester, int index) async {
    requests[index].complete();
    await tester.pump();
    await tester.pump();
  }

  void close() {
    policy.dispose();
    auth.close();
  }
}

void main() {
  for (final code in ['permission-denied', 'unauthenticated']) {
    testWidgets('bundle $code only recovers stale media through a fresh post read', (tester) async {
      var reads = 0;
      await tester.pumpWidget(MaterialApp(home: authorizedPagerMediaForTesting(
        postId: 'post', active: true, prepare: true, viewer: () => 'viewer',
        viewerChanges: const Stream.empty(), policyChanges: const [],
        authorize: (_) async { reads++; },
        readBundle: () async => throw FirebaseFunctionsException(code: code, message: 'unavailable'),
        observeGrant: (grant) => expect(grant, isNull),
        builder: (active, _) => Text('fallback:$active'))));
      await tester.pumpAndSettle();
      expect(reads, code == 'permission-denied' ? 1 : 0);
      expect(find.text('fallback:true'), code == 'permission-denied' ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'bundle is usable only in its fresh render pass and stale policy completion is ignored',
      (tester) async {
    final requests = <Completer<PostMediaGrant>>[];
    final policy = ValueNotifier<int>(0);
    final seenLinks = <String?>[];
    var fallbackReads = 0;
    PostMediaGrant grant() =>
        PostMediaGrant.fromResponse(viewer: 'viewer', postId: 'post', sources: [
          'source'
        ], response: {
          'post': {
            'id': 'post',
            'data': {
              'imageUrls': ['source']
            }
          },
          'items': [
            {
              'source': 'source',
              'url': 'https://storage.googleapis.com/b/p?generation=1',
              'expiresAt': DateTime.now().millisecondsSinceEpoch + 60000
            }
          ]
        });
    Widget page(bool active) => MaterialApp(
        home: authorizedPagerMediaForTesting(
            postId: 'post',
            active: active,
            prepare: true,
            viewer: () => 'viewer',
            viewerChanges: const Stream.empty(),
            policyChanges: [policy],
            authorize: (_) async {
              fallbackReads++;
            },
            readBundle: () {
              final pending = Completer<PostMediaGrant>();
              requests.add(pending);
              return pending.future;
            },
            observeGrant: (value) =>
                seenLinks.add(value?.link('viewer', 'post', 'source')),
            builder: (active, _) => Text('bundle:$active')));
    await tester.pumpWidget(page(false));
    final first = grant();
    requests[0].complete(first);
    await tester.pump();
    await tester.pump();
    expect(seenLinks.whereType<String>(), hasLength(1));
    expect(first.link('viewer', 'post', 'source'), isNull,
        reason: 'Post-frame sealing prevents later reuse');
    expect(fallbackReads, 0,
        reason: 'Bundle projection replaces the serial post read');
    await tester.pumpWidget(page(true));
    expect(requests, hasLength(2));
    policy.value++;
    await tester.pump();
    expect(requests, hasLength(3));
    requests[1].complete(grant());
    await tester.pump();
    expect(find.text('bundle:true'), findsNothing);
    final current = grant();
    requests[2].complete(current);
    await tester.pump();
    await tester.pump();
    expect(find.text('bundle:true'), findsOneWidget);
    expect(current.link('viewer', 'post', 'source'), isNull);
    expect(fallbackReads, 0);
    await tester.pumpWidget(const SizedBox());
    policy.dispose();
  });
  testWidgets(
      'neighbor prepares hidden child and reentry retains state behind a fresh check',
      (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.build(active: false));
    expect(h.requests, hasLength(1));
    await h.grant(tester, 0);
    expect(h.created, 1);
    expect(h.grants, everyElement(false));
    expect(find.text('media:false'), findsNothing);
    expect(find.text('media:false', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(h.build());
    expect(h.requests, hasLength(2));
    expect(h.created, 1);
    expect(h.disposed, 0);
    expect(find.text('media:true'), findsNothing);
    await h.grant(tester, 1);
    expect(find.text('media:true'), findsOneWidget);
    expect(h.created, 1);
    await tester.pumpWidget(h.build(active: false));
    expect(h.requests, hasLength(2));
    expect(h.disposed, 0);
    await tester.pumpWidget(h.build());
    expect(h.requests, hasLength(3));
    expect(find.text('media:true'), findsNothing);
    await h.grant(tester, 2);
    expect(h.created, 1);
    expect(h.disposed, 0);
    expect(find.text('media:true'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('denied activation destroys retained child without exposing it',
      (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.build(active: false));
    await h.grant(tester, 0);
    await tester.pumpWidget(h.build());
    h.requests[1].completeError(StateError('denied'));
    await tester.pump();
    expect(h.disposed, 1);
    expect(h.grants, everyElement(false));
    expect(find.text('media:true'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'policy invalidation disposes retained media and requires a fresh grant',
      (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.build());
    await h.grant(tester, 0);
    h.policy.value++;
    await tester.pump();
    expect(h.requests, hasLength(2));
    expect(h.disposed, 1);
    expect(find.text('media:true'), findsNothing);
    await h.grant(tester, 1);
    expect(h.created, 2);
    expect(find.text('media:true'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'rapid activation changes reject stale completions and radius eviction disposes media',
      (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.build(active: false));
    await tester.pumpWidget(h.build());
    await tester.pumpWidget(h.build(active: false));
    expect(h.requests, hasLength(3));
    await h.grant(tester, 1);
    await h.grant(tester, 0);
    expect(h.created, 0);
    await h.grant(tester, 2);
    expect(h.created, 1);
    expect(h.grants, everyElement(false));
    await tester.pumpWidget(h.build(active: false, prepare: false));
    expect(h.disposed, 1);
    expect(h.requests, hasLength(3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'background policy changes start no requests and resume checks again',
      (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await tester.pumpWidget(h.build());
    await h.grant(tester, 0);
    // Inactive is the last renderable phase; paused disables Flutter frames.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(h.disposed, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.policy.value++;
    await tester.pump();
    expect(h.requests, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(h.requests, hasLength(2));
    await h.grant(tester, 1);
    expect(h.created, 2);
    h.viewer = 'other';
    await tester.pumpWidget(h.build());
    expect(
        find.text('media:true'), findsNothing); // Before the auth stream event.
    h.auth.add('other');
    await tester.pump();
    expect(h.disposed, 2);
    expect(h.requests, hasLength(2));
    expect(find.text('media:true'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
