import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/community_guidelines_screen.dart';
import 'simple_login_terms_test.dart'
    show control, showLogin, toggleTerms, expectLoginEnabled;

Future<void> openCommunity(WidgetTester tester) async {
  await tester.ensureVisible(control('read-community'));
  await tester.pumpAndSettle();
  await tester.tap(control('read-community'));
  await tester.pumpAndSettle();
}

Future<void> closeCommunity(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('community-reader-back')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('community rules open before agreement and do not enable login',
      (tester) async {
    await showLogin(tester);
    expect(find.text('قراءة قواعد المجتمع'), findsOneWidget);
    expectLoginEnabled(tester, false);

    await openCommunity(tester);
    expect(find.byType(CommunityGuidelinesScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('community-reader-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-reader-review-notice')),
      findsOneWidget,
    );

    await closeCommunity(tester);
    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, false);
    expectLoginEnabled(tester, false);
  });

  testWidgets('community reader exposes all twelve sections and reaches the end',
      (tester) async {
    await showLogin(tester);
    await openCommunity(tester);

    for (var i = 1; i <= 12; i++) {
      expect(find.byKey(ValueKey('community-heading-$i')), findsOneWidget);
    }
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('1. الهدف والنطاق'), findsOneWidget);

    final last = find.byKey(const ValueKey('community-heading-12'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(find.text('12. التطبيق والتغييرات والتواصل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reading community rules preserves typed fields and terms choice',
      (tester) async {
    await showLogin(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reader@example.test');
    await tester.enterText(fields.at(1), 'not-a-real-password');
    await toggleTerms(tester);

    await openCommunity(tester);
    await closeCommunity(tester);

    expect(tester.widget<CheckboxListTile>(control('terms-consent')).value, true);
    expectLoginEnabled(tester, true);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'reader@example.test',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'not-a-real-password',
    );
  });

  testWidgets('community page supports narrow RTL and large text', (tester) async {
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
      home: const CommunityGuidelinesScreen(),
    ));
    await tester.pumpAndSettle();

    final heading = find.byKey(const ValueKey('community-heading-1'));
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    await tester.ensureVisible(find.byKey(const ValueKey('community-heading-12')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
