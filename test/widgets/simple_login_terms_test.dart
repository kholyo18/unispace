import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/main.dart' show SignInScreen;
import 'package:UniSpace/ui/auth/account_recovery_screen.dart';

Finder control(String name) => find.byKey(ValueKey('login-$name'));

Future<void> showLogin(WidgetTester tester,
    {ThemeMode mode = ThemeMode.light}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: mode,
    home: const SignInScreen(),
  ));
  await tester.pumpAndSettle();
}

Future<void> toggleTerms(WidgetTester tester) async {
  await tester.ensureVisible(control('terms-consent'));
  await tester.pumpAndSettle();
  await tester.tap(control('terms-consent'));
  await tester.pumpAndSettle();
}

// The legal links are now inline; retain this shared helper for reader tests.
Future<void> openLegalDetails(WidgetTester tester) async {
  expect(control('legal-details'), findsOneWidget);
  await tester.ensureVisible(control('legal-details'));
  await tester.pumpAndSettle();
  for (final name in ['terms', 'privacy', 'community']) {
    final link = control('read-$name');
    expect(link, findsOneWidget);
    expect(tester.widget<TextButton>(link).onPressed, isNotNull);
  }
}

void expectLoginEnabled(WidgetTester tester, bool enabled) {
  expect(tester.widget<FilledButton>(control('email-submit')).onPressed,
      enabled ? isNotNull : isNull);
  expect(tester.widget<OutlinedButton>(control('google-submit')).onPressed,
      enabled ? isNotNull : isNull);
}

void main() {
  testWidgets('authenticator recovery opens before terms agreement',
      (tester) async {
    await showLogin(tester);
    final link = control('authenticator-recovery');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(AccountRecoveryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expectLoginEnabled(tester, false);
  });
  for (final name in ['terms', 'privacy', 'community']) {
    testWidgets('legal $name opens before agreement and returns unchecked',
        (tester) async {
      await showLogin(tester);
      final link = control('read-$name');
      expect(tester.widget<TextButton>(link).onPressed, isNotNull);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen).hitTestable(), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(control('terms-consent')).value,
          false);
      expectLoginEnabled(tester, false);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('both login methods start disabled until explicit agreement',
      (tester) async {
    await showLogin(tester);
    expect(
        tester.widget<CheckboxListTile>(control('terms-consent')).value, false);
    expect(find.text('أوافق على شروط الاستخدام'), findsOneWidget);
    expect(control('legal-details'), findsOneWidget);
    expect(control('read-terms'), findsOneWidget);
    expect(control('read-privacy'), findsOneWidget);
    expect(control('read-community'), findsOneWidget);
    expectLoginEnabled(tester, false);
    await toggleTerms(tester);
    expect(
        tester.widget<CheckboxListTile>(control('terms-consent')).value, true);
    expectLoginEnabled(tester, true);
  });

  testWidgets('unchecking agreement disables email and Google again',
      (tester) async {
    await showLogin(tester);
    await toggleTerms(tester);
    expectLoginEnabled(tester, true);
    await toggleTerms(tester);
    expectLoginEnabled(tester, false);
  });

  testWidgets(
      'captured callbacks refuse to start authentication after agreement is removed',
      (tester) async {
    await showLogin(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reader@example.test');
    await tester.enterText(fields.at(1), 'not-a-real-password');
    await toggleTerms(tester);
    final email =
        tester.widget<FilledButton>(control('email-submit')).onPressed!;
    final google =
        tester.widget<OutlinedButton>(control('google-submit')).onPressed!;
    await toggleTerms(tester);
    // The real handlers return before touching either authentication provider.
    email();
    google();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expectLoginEnabled(tester, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a newly created login screen starts unchecked again',
      (tester) async {
    await showLogin(tester);
    await toggleTerms(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await showLogin(tester);
    expect(
        tester.widget<CheckboxListTile>(control('terms-consent')).value, false);
    expectLoginEnabled(tester, false);
  });

  testWidgets('existing recovery controls are not gated by agreement',
      (tester) async {
    await showLogin(tester);
    final recovery = find.widgetWithText(TextButton, 'فقدت تطبيق المصادقة؟');
    expect(tester.widget<TextButton>(recovery).onPressed, isNotNull);
    final forgot = find.widgetWithText(TextButton, S.current.forgotPassword);
    expect(tester.widget<TextButton>(forgot).onPressed, isNotNull);
    expectLoginEnabled(tester, false);
  });

  testWidgets('agreement remains usable with the existing dark login theme',
      (tester) async {
    await showLogin(tester, mode: ThemeMode.dark);
    expectLoginEnabled(tester, false);
    await toggleTerms(tester);
    expectLoginEnabled(tester, true);
    expect(tester.takeException(), isNull);
  });
}
