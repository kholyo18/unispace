import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/app/startup_tasks.dart';

void main() {
  test('local settings start while Firebase is pending; both gate readiness',
      () async {
    final firebase = Completer<void>();
    final local = Completer<void>();
    var localStarted = false;
    var ready = false;
    final startup = initializeStartupDependencies(
      initializeFirebase: () => firebase.future,
      initializeLocalSettings: () {
        localStarted = true;
        return local.future;
      },
    ).then((_) => ready = true);
    expect(localStarted, isTrue);
    firebase.complete();
    await Future<void>.delayed(Duration.zero);
    expect(ready, isFalse);
    local.complete();
    await startup;
    expect(ready, isTrue);
  });

  test('local completion cannot bypass pending Firebase', () async {
    final firebase = Completer<void>();
    var ready = false;
    final startup = initializeStartupDependencies(
      initializeFirebase: () => firebase.future,
      initializeLocalSettings: () async {},
    ).then((_) => ready = true);
    await Future<void>.delayed(Duration.zero);
    expect(ready, isFalse);
    firebase.complete();
    await startup;
    expect(ready, isTrue);
  });

  test('a failed group does not skip the independent group', () async {
    var localStarted = false;
    final error = StateError('unavailable');
    await expectLater(
        initializeStartupDependencies(
          initializeFirebase: () => throw error,
          initializeLocalSettings: () async {
            localStarted = true;
          },
        ),
        throwsA(same(error)));
    expect(localStarted, isTrue);
  });

  test('successful first attempt has no backoff', () async {
    var calls = 0;
    await initializeFirebaseWithRetry(
      initialize: () async {
        calls++;
      },
      onFailure: (_, __) => fail('unexpected failure'),
      delay: (_) async => fail('unexpected delay'),
    );
    expect(calls, 1);
  });

  test('recovery stops retrying immediately after success', () async {
    var calls = 0;
    final delays = <Duration>[];
    final failures = <int>[];
    await initializeFirebaseWithRetry(
      initialize: () async {
        if (++calls < 3) throw StateError('offline');
      },
      onFailure: (attempt, _) => failures.add(attempt),
      delay: (duration) async {
        delays.add(duration);
      },
    );
    expect(calls, 3);
    expect(failures, [1, 2]);
    expect(delays.map((d) => d.inMilliseconds), [250, 500]);
  });

  test('five failed attempts preserve error without final wasted delay',
      () async {
    var calls = 0;
    final error = StateError('offline');
    final delays = <Duration>[];
    await expectLater(
        initializeFirebaseWithRetry(
          initialize: () async {
            calls++;
            throw error;
          },
          onFailure: (_, __) {},
          delay: (duration) async {
            delays.add(duration);
          },
        ),
        throwsA(same(error)));
    expect(calls, 5);
    expect(delays.map((d) => d.inMilliseconds), [250, 500, 750, 1000]);
    expect(delays.fold<int>(0, (total, d) => total + d.inMilliseconds), 2500);
  });
}
