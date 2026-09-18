import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/settings/privacy/account_deletion_screen.dart';
import 'package:UniSpace/features/settings/privacy/data_retention_policy_screen.dart';

void main() {
  testWidgets('retention reader exposes all ten sections and reaches the end',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DataRetentionPolicyScreen(),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('retention-reader-review-notice')),
      findsOneWidget,
    );
    for (var i = 1; i <= 10; i++) {
      expect(find.byKey(ValueKey('retention-heading-$i')), findsOneWidget);
    }
    expect(find.byType(SelectionArea), findsOneWidget);

    final last = find.byKey(const ValueKey('retention-heading-10'));
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    expect(find.text('10. التواصل والصفحة الخارجية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retention reader remains usable with narrow RTL large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2.5),
        ),
        child: child!,
      ),
      home: const DataRetentionPolicyScreen(),
    ));
    await tester.pumpAndSettle();

    final heading = find.byKey(const ValueKey('retention-heading-1'));
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    await tester.ensureVisible(find.byKey(const ValueKey('retention-heading-10')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion page clearly states request-only status', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AccountDeletionScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-deletion-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-deletion-status-notice')),
      findsOneWidget,
    );
    expect(find.text('طلب حذف الحساب والبيانات'), findsOneWidget);
  });

  testWidgets('deletion request requires explicit confirmation and can cancel',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AccountDeletionScreen(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-deletion-submit')));
    await tester.pumpAndSettle();

    expect(find.text('طلب حذف الحساب والبيانات؟'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-deletion-confirm')), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('طلب حذف الحساب والبيانات؟'), findsNothing);
    expect(find.byKey(const ValueKey('account-deletion-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion page links to the retention policy', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AccountDeletionScreen(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('account-deletion-read-retention')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataRetentionPolicyScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('retention-reader-title')), findsOneWidget);
  });
}
