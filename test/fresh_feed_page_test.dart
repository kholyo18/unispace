import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/services/fresh_feed_page.dart';

void main() {
  test('startup requests eight rows and older backend falls back once', () async {
    final requests = <Map<String, dynamic>>[];
    final result = await requestFeedPage(cursor: null, pageSize: 8, call: (data) async {
      requests.add(data);
      if (data.containsKey('pageSize')) throw FirebaseFunctionsException(code: 'invalid-argument', message: 'legacy');
      return {'posts': []};
    });
    expect(requests, [{'cursor': null, 'pageSize': 8}, {'cursor': null}]);
    expect(result['posts'], isEmpty);
  });

  test('authorization and transport failures are never retried as legacy', () async {
    for (final code in ['unauthenticated', 'permission-denied', 'unavailable']) {
      var calls = 0;
      await expectLater(requestFeedPage(cursor: null, pageSize: 8, call: (_) async {
        calls++;
        throw FirebaseFunctionsException(code: code, message: 'fixture');
      }), throwsA(isA<FirebaseFunctionsException>()));
      expect(calls, 1);
    }
  });

  test('page and local privacy filters start together and all must finish', () async {
    final page = Completer<Map<String, dynamic>>();
    final hidden = Completer<Set<String>>();
    final blocked = Completer<Set<String>>();
    final started = <String>[];
    var completed = false;
    final future = loadFreshFeedPage(
      readPage: () { started.add('page'); return page.future; },
      readHidden: () { started.add('hidden'); return hidden.future; },
      readBlocked: () { started.add('blocked'); return blocked.future; },
      isCurrent: () => true,
    ).then((value) { completed = true; return value; });
    expect(started, ['page', 'hidden', 'blocked']);
    page.complete({'posts': [], 'authorAccessRechecked': true});
    hidden.complete({'hidden-post'});
    await Future<void>.delayed(Duration.zero);
    expect(completed, false);
    blocked.complete({'blocked-author'});
    final result = (await future)!;
    expect(result.hidden, {'hidden-post'});
    expect(result.blocked, {'blocked-author'});
    expect(result.authorAccessRechecked, true);
  });

  test('account or privacy generation change discards pending page', () async {
    var current = true;
    final page = Completer<Map<String, dynamic>>();
    final future = loadFreshFeedPage(readPage: () => page.future,
        readHidden: () async => {}, readBlocked: () async => {},
        isCurrent: () => current);
    current = false;
    page.complete({'authorAccessRechecked': true});
    expect(await future, isNull);
  });

  test('failed local privacy read never returns a usable page', () async {
    await expectLater(loadFreshFeedPage(
      readPage: () async => {'authorAccessRechecked': true},
      readHidden: () async => throw StateError('unavailable'),
      readBlocked: () async => {}, isCurrent: () => true,
    ), throwsStateError);
  });

  test('only explicit server capability permits skipping duplicate author reads', () {
    for (final flag in [null, false, 'true', 1]) {
      expect(FreshFeedPage({'authorAccessRechecked': flag}, {}, {}).authorAccessRechecked, false);
    }
    expect(const FreshFeedPage({'authorAccessRechecked': true}, {}, {}).authorAccessRechecked, true);
  });
}
