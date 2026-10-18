import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:UniSpace/services/community_search_text.dart';
import 'package:UniSpace/services/content_search_scan.dart';

void main() {
  test('Arabic, French, short prefixes and stopword-only searches match', () {
    for (final pair in [
      ['Économie française', 'economie'],
      ['E\u0301conomie', 'économie'],
      ['أحـمد', 'احمد'],
      ['محمد', 'مح'],
      ['Amine', 'ami'],
      ['في الجامعة', 'في'],
      ['C programming', 'c'],
    ]) {
      expect(
          communityTokensMatch(pair[0], communityQueryTokens(pair[1])), isTrue,
          reason: pair.toString());
    }
    expect(
        communityTokensMatch('science', communityQueryTokens('math')), isFalse);
    expect(
        communityTokensMatch('anything', communityQueryTokens('!!!')), isFalse);
  });
  test('a broken index falls back to recent authorized pages', () async {
    final calls = <int>[];
    final result = await scanContentSearch(
        indexed: true,
        current: () => true,
        loadPage: (page) async {
          calls.add(page);
          if (page == 0) {
            throw FirebaseFunctionsException(
                code: 'unavailable', message: 'offline');
          }
          return true;
        });
    expect(calls, [0, 1]);
    expect(result.incomplete, isTrue);
  });
  test('a later failure preserves completed pages and marks partial results',
      () async {
    final completed = <int>[];
    final result = await scanContentSearch(
        indexed: true,
        current: () => true,
        loadPage: (page) async {
          if (page == 2) {
            throw FirebaseFunctionsException(
                code: 'deadline-exceeded', message: 'timeout');
          }
          completed.add(page);
          return false;
        });
    expect(completed, [0, 1]);
    expect(result.incomplete, isTrue);
  });
  test('authorization failures remain fatal, never partial success', () async {
    for (final code in ['unauthenticated', 'permission-denied']) {
      await expectLater(
          scanContentSearch(
              indexed: true,
              current: () => true,
              loadPage: (_) async {
                throw FirebaseFunctionsException(code: code, message: 'denied');
              }),
          throwsA(isA<FirebaseFunctionsException>()));
    }
  });
  test('bounded scans report truncation and cancel stale requests', () async {
    var calls = 0;
    final result = await scanContentSearch(
        indexed: true,
        current: () => true,
        loadPage: (_) async {
          calls++;
          return false;
        });
    expect(calls, 6);
    expect(result.truncated, isTrue);
    await scanContentSearch(
        indexed: true,
        current: () => false,
        loadPage: (_) async {
          fail('stale query');
        });
  });
}
