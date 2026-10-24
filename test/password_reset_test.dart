import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/services/password_reset_service.dart';
import 'package:UniSpace/ui/auth/password_reset_sheet.dart';
import 'package:UniSpace/main.dart' show SignInScreen;

class FakeAuth implements FirebaseAuth {
  final requests = <String>[];
  String? language;
  Object? failure;
  Completer<void>? pending;
  @override
  Future<void> setLanguageCode(String? value) async { language = value; }
  @override
  Future<void> sendPasswordResetEmail({required String email, ActionCodeSettings? actionCodeSettings}) async {
    requests.add(email);
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
Widget app(Widget home, {String locale = 'ar', bool dark = false}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  locale: Locale(locale), supportedLocales: S.delegate.supportedLocales,
  localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates], home: home);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('send trims email, chooses language and does not expose absent account', () async {
    final auth = FakeAuth(); final service = PasswordResetService(auth: auth);
    await service.send(' person@example.com ', 'fr');
    expect(auth.requests, ['person@example.com']); expect(auth.language, 'fr');
    auth.failure = FirebaseAuthException(code: 'user-not-found');
    await service.send('absent@example.com', 'ar');
    expect(auth.requests.last, 'absent@example.com');
  });
  test('invalid addresses never call Firebase', () async {
    final auth = FakeAuth(); final service = PasswordResetService(auth: auth);
    for (final email in ['', 'test', 'a@', 'a b@example.com', 'a@@example.com']) {
      await expectLater(service.send(email, 'en'), throwsA(isA<FirebaseAuthException>()));
    }
    expect(auth.requests, isEmpty);
  });
  for (final code in ['network-request-failed', 'too-many-requests', 'operation-not-allowed']) {
    test('$code is propagated without retry or false success', () async {
      final auth = FakeAuth()..failure = FirebaseAuthException(code: code);
      await expectLater(PasswordResetService(auth: auth).send('person@example.com', 'en'),
        throwsA(isA<FirebaseAuthException>().having((e)=>e.code, 'code', code)));
      expect(auth.requests, hasLength(1));
    });
  }
  for(final locale in ['ar', 'en', 'fr']) {
    for(final locked in [false, true]) {
      testWidgets('shared reset $locale accountEmailLocked=$locked validates, reports failure, retries and completes', (tester) async {
        final auth = FakeAuth(); bool? result;
        await tester.pumpWidget(app(Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () async { result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
            builder: (_) => PasswordResetSheet(initialEmail: locked ? 'account@example.com' : '',
              lockEmail: locked, service: PasswordResetService(auth: auth))); }, child: const Text('Open')))), locale: locale, dark: locked));
        await tester.tap(find.text('Open')); await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('reset-email'));
        final send = find.byKey(const ValueKey('reset-send'));
        expect(tester.widget<TextField>(input).readOnly, locked);
        if (!locked) {
          await tester.tap(send); await tester.pumpAndSettle();
          expect(auth.requests, isEmpty); expect(find.byKey(const ValueKey('reset-error')), findsOneWidget);
          await tester.enterText(input, ' person@example.com ');
        }
        auth.failure = FirebaseAuthException(code: 'too-many-requests');
        await tester.tap(send); await tester.pumpAndSettle();
        expect(result, isNull); expect(find.text(S.current.tooManyRequestsError), findsOneWidget);
        auth.failure = null; auth.pending = Completer<void>();
        final callback = tester.widget<FilledButton>(send).onPressed!;
        callback(); callback(); await tester.pump();
        expect(auth.requests, hasLength(2));
        expect(tester.widget<FilledButton>(send).onPressed, isNull);
        auth.pending!.complete(); await tester.pumpAndSettle();
        expect(result, isTrue); expect(find.byType(PasswordResetSheet), findsNothing);
        expect(auth.language, locale);
        expect(auth.requests.last, locked ? 'account@example.com' : 'person@example.com');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('login recovery opens the shared reset without terms agreement and prefills email', (tester) async {
    await tester.pumpWidget(app(const SignInScreen())); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'person@example.com');
    final forgot = find.widgetWithText(TextButton, S.current.forgotPassword);
    await tester.ensureVisible(forgot); await tester.pumpAndSettle(); await tester.tap(forgot); await tester.pumpAndSettle();
    expect(find.byType(PasswordResetSheet), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('reset-email'))).controller!.text, 'person@example.com');
    expect(tester.takeException(), isNull);
  });
}
