import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/auth/signup_retry.dart';

void main() {
  for (final code in ['unavailable', 'deadline-exceeded']) {
    test('$code retries once and returns confirmed save', () async {
      var calls = 0;
      final result = await retrySignupSave(
          save: () async {
            if (++calls == 1) {
              throw FirebaseFunctionsException(code: code, message: 'network');
            }
            return 'saved';
          },
          isCurrentUser: () => true,
          wait: (_) async {});
      expect(result, 'saved');
      expect(calls, 2);
    });
  }
  test('persistent failure stops after two requests', () async {
    var calls = 0;
    await expectLater(
        retrySignupSave(
            save: () async {
              calls++;
              throw FirebaseFunctionsException(
                  code: 'unavailable', message: 'network');
            },
            isCurrentUser: () => true,
            wait: (_) async {}),
        throwsA(isA<FirebaseFunctionsException>()));
    expect(calls, 2);
  });
  test('auth, validation, quota and missing functions never retry', () async {
    for (final code in [
      'unauthenticated',
      'permission-denied',
      'invalid-argument',
      'resource-exhausted',
      'not-found',
      'already-exists'
    ]) {
      var calls = 0;
      await expectLater(
          retrySignupSave(
              save: () async {
                calls++;
                throw FirebaseFunctionsException(
                    code: code, message: 'rejected');
              },
              isCurrentUser: () => true,
              wait: (_) async {
                fail('unexpected retry');
              }),
          throwsA(isA<FirebaseFunctionsException>()));
      expect(calls, 1);
    }
  });
  test('a changed account cancels the retry', () async {
    var current = true;
    var calls = 0;
    await expectLater(
        retrySignupSave(
            save: () async {
              calls++;
              throw FirebaseFunctionsException(
                  code: 'unavailable', message: 'network');
            },
            isCurrentUser: () => current,
            wait: (_) async {
              current = false;
            }),
        throwsA(isA<FirebaseFunctionsException>()
            .having((e) => e.code, 'code', 'unauthenticated')));
    expect(calls, 1);
  });
}
