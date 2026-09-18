import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/settings/privacy/account_deletion_screen.dart';

Finder deletionControl(String name) =>
    find.byKey(ValueKey('account-delete-$name'));

Future<void> showDeletion(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: const AccountDeletionScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deletion request starts disabled until explicit understanding',
      (tester) async {
    await showDeletion(tester);

    expect(find.text('طلب حذف حساب UniSpace'), findsOneWidget);
    expect(find.textContaining('30 يومًا'), findsWidgets);
    expect(find.textContaining('180 يومًا'), findsWidgets);
    expect(find.textContaining('90 يومًا'), findsWidgets);

    final submit =
        tester.widget<FilledButton>(deletionControl('submit'));
    expect(submit.onPressed, isNull);

    await tester.tap(deletionControl('understood'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CheckboxListTile>(deletionControl('understood')).value,
      true,
    );
    expect(
      tester.widget<FilledButton>(deletionControl('submit')).onPressed,
      isNotNull,
    );
  });

  testWidgets('unchecking understanding disables deletion request again',
      (tester) async {
    await showDeletion(tester);

    await tester.tap(deletionControl('understood'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(deletionControl('submit')).onPressed,
      isNotNull,
    );

    await tester.tap(deletionControl('understood'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(deletionControl('submit')).onPressed,
      isNull,
    );
  });

  testWidgets('deletion page supports narrow RTL and large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
          ),
          child: child!,
        ),
        home: const AccountDeletionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final title = deletionControl('title');
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
    await tester.ensureVisible(deletionControl('submit'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
