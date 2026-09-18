import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/settings/privacy/privacy_policy_screen.dart';
import 'simple_login_terms_test.dart'
    show control, showLogin, toggleTerms, expectLoginEnabled;

Future<void> openPrivacy(WidgetTester tester) async {
  await tester.ensureVisible(control('read-privacy'));
  await tester.pumpAndSettle();
  await tester.tap(control('read-privacy'));
  await tester.pumpAndSettle();
}

Future<void> closePrivacy(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('privacy-reader-back')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('privacy opens before agreement and does not enable login',
      (tester) async {
    await showLogin(tester);
    expect(find.text('قراءة سياسة الخصوصية'), findsOneWidget);
    expectLoginEnabled(tester, false);

    await openPrivacy(tester);
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-reader-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-reader-policy-notice')), findsOneWidget);

    await closePrivacy(tester);
    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, false);
    expectLoginEnabled(tester, false);
  });

  testWidgets('privacy reader exposes all eleven sections and reaches the end',
      (tester) async {
    await showLogin(tester);
    await openPrivacy(tester);

    for (var i = 1; i <= 11; i++) {
      expect(find.byKey(ValueKey('privacy-heading-$i')), findsOneWidget);
    }
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('1. من نحن وكيف تتواصل معنا'), findsOneWidget);
    expect(find.textContaining('نافذ من 18 سبتمبر 2026'), findsOneWidget);
    expect(find.textContaining('https://fachub-c631c.web.app/delete-account'), findsOneWidget);
    expect(find.textContaining('30 يومًا'), findsWidgets);
    expect(find.textContaining('90 يومًا'), findsWidgets);
    expect(find.textContaining('180 يومًا'), findsWidgets);
    expect(find.textContaining('نسخة منقحة للمراجعة'), findsNothing);

    final last = find.byKey(const ValueKey('privacy-heading-11'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(find.text('11. التغييرات على السياسة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy reading preserves typed fields and terms choice',
      (tester) async {
    await showLogin(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reader@example.test');
    await tester.enterText(fields.at(1), 'not-a-real-password');
    await toggleTerms(tester);

    await openPrivacy(tester);
    await closePrivacy(tester);

    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, true);
    expectLoginEnabled(tester, true);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'reader@example.test');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'not-a-real-password');
  });

  testWidgets('privacy page remains usable with narrow RTL and large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2.5),
        ),
        child: child!,
      ),
      home: const PrivacyPolicyScreen(),
    ));
    await tester.pumpAndSettle();

    final heading = find.byKey(const ValueKey('privacy-heading-1'));
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    await tester.ensureVisible(find.byKey(const ValueKey('privacy-heading-11')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
