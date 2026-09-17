import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/auth/terms_of_use_screen.dart';
import 'simple_login_terms_test.dart'
    show control, showLogin, toggleTerms, expectLoginEnabled;

Future<void> openTerms(WidgetTester tester) async {
  await tester.ensureVisible(control('read-terms'));
  await tester.pumpAndSettle();
  await tester.tap(control('read-terms'));
  await tester.pumpAndSettle();
}

Future<void> closeTerms(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('terms-reader-back')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('terms open before agreement and closing does not enable login',
      (tester) async {
    await showLogin(tester);
    expect(find.text('قراءة شروط الاستخدام'), findsOneWidget);
    expectLoginEnabled(tester, false);
    await openTerms(tester);
    expect(find.byType(TermsOfUseScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('terms-reader-draft-notice')), findsOneWidget);
    expect(find.text('شروط استخدام UniSpace'), findsOneWidget);
    await closeTerms(tester);
    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, false);
    expectLoginEnabled(tester, false);
  });

  testWidgets('reader includes all 22 original articles and reaches the last one',
      (tester) async {
    await showLogin(tester);
    await openTerms(tester);
    for (var i = 1; i <= 22; i++) {
      expect(find.byKey(ValueKey('terms-heading-$i')), findsOneWidget);
    }
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('1. التعريف والمشغّل'), findsOneWidget);
    final last = find.byKey(const ValueKey('terms-heading-22'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(tester.getCenter(last).dy, lessThan(tester.view.physicalSize.height));
    expect(find.text('22. التواصل والنفاذ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reading preserves an existing choice and typed login fields',
      (tester) async {
    await showLogin(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reader@example.test');
    await tester.enterText(fields.at(1), 'not-a-real-password');
    await toggleTerms(tester);
    await openTerms(tester);
    await closeTerms(tester);
    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, true);
    expectLoginEnabled(tester, true);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'reader@example.test');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'not-a-real-password');
    await toggleTerms(tester);
    expectLoginEnabled(tester, false);
  });

  testWidgets('system back returns to unchecked login without an auth request',
      (tester) async {
    await showLogin(tester);
    await openTerms(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TermsOfUseScreen), findsNothing);
    expectLoginEnabled(tester, false);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reopening the reader starts at its beginning without accepting',
      (tester) async {
    await showLogin(tester);
    await openTerms(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('terms-heading-22')));
    await tester.pumpAndSettle();
    await closeTerms(tester);
    await openTerms(tester);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0);
    await closeTerms(tester);
    expectLoginEnabled(tester, false);
  });

  testWidgets('read-only page supports narrow RTL and large text in both themes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2.5)),
          child: child!,
        ),
        home: const TermsOfUseScreen(),
      ));
      await tester.pumpAndSettle();
      final heading = find.byKey(const ValueKey('terms-heading-1'));
      expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
      await tester.ensureVisible(find.byKey(const ValueKey('terms-heading-22')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
