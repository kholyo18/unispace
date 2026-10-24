import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/services/sign_out_pipeline.dart';
import 'package:UniSpace/services/account_search_history.dart';
import 'package:UniSpace/features/exams/data/storage/exam_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every cleanup failure still signs out and attempts both providers',
      () async {
    final events = <String>[];
    await runSignOutPipeline(
      cleanup: {
        'revoke': () => throw StateError('offline'),
        'audio': () async => throw StateError('audio'),
        'purge': () => throw StateError('disk'),
        'diskImages': () async => throw StateError('cache'),
        'push': () {
          events.add('push');
        },
      },
      signOut: () async {
        events.add('firebase');
      },
      providers: {
        'google': () => throw StateError('google'),
        'disconnect': () {
          events.add('disconnect');
        },
      },
      onFailure: (stage, error, stack) {
        events.add('failed:$stage');
      },
      onAuthFailure: () => fail('Firebase succeeded'),
    );
    expect(events, [
      'failed:revoke',
      'failed:audio',
      'failed:purge',
      'failed:diskImages',
      'push',
      'firebase',
      'failed:google',
      'disconnect'
    ]);
  });
  test('Firebase failure propagates after provider logout and push reset',
      () async {
    final events = <String>[];
    final error = StateError('auth');
    await expectLater(
        runSignOutPipeline(
          cleanup: {},
          signOut: () async => throw error,
          providers: {
            'google': () {
              events.add('google');
            }
          },
          onFailure: (_, __, ___) => fail('unexpected cleanup failure'),
          onAuthFailure: () {
            events.add('reset');
          },
        ),
        throwsA(same(error)));
    expect(events, ['reset', 'google']);
  });
  test('a stalled revocation or cleanup cannot prevent local logout', () async {
    var signedOut = false;
    final failures = <String>[];
    await runSignOutPipeline(
      cleanup: {'revoke': () => Completer<void>().future, 'disk': () => Completer<void>().future},
      signOut: () async { signedOut = true; },
      providers: {'google': () => Completer<void>().future},
      stageTimeout: const Duration(milliseconds: 10),
      onFailure: (stage, _, __) => failures.add(stage),
      onAuthFailure: () => fail('unexpected auth failure'));
    expect(signedOut, isTrue);
    expect(failures, ['revoke', 'disk', 'google']);
  });
  test('search histories are isolated and unowned legacy data removed',
      () async {
    SharedPreferences.setMockInitialValues({
      AccountSearchHistory.legacyKey: ['private legacy']
    });
    expect(await AccountSearchHistory.load('a'), isEmpty);
    await AccountSearchHistory.save('a', ['alpha']);
    expect(await AccountSearchHistory.load('b'), isEmpty);
    await AccountSearchHistory.save('b', ['beta']);
    expect(await AccountSearchHistory.load('a'), ['alpha']);
    expect(await AccountSearchHistory.load('b'), ['beta']);
    expect(await AccountSearchHistory.load(null), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AccountSearchHistory.legacyKey), isFalse);
  });
  test('corrupt exam storage is retained for recovery rather than overwritten',
      () async {
    SharedPreferences.setMockInitialValues({'exam_calendar_items': '{broken'});
    await expectLater(ExamStorage().loadExams(), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('exam_calendar_items'), '{broken');
    await prefs.setString('exam_calendar_items', '[]');
    expect(await ExamStorage().loadExams(), isEmpty);
  });
}
