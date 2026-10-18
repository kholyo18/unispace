import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/ui/auth/account_recovery_screen.dart';

void main() {
  testWidgets('incomplete recovery credentials never start a request',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(locale: Locale('ar'), supportedLocales: [Locale('ar')], localizationsDelegates: GlobalMaterialLocalizations.delegates, home: AccountRecoveryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('استعادة بكلمة المرور'));
    await tester.pump();
    expect(find.text('أدخل مفتاح الاستعادة الكامل وبيانات الدخول.'),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving the recovery key enables the completion button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: RecoveryKeyScreen(
            recoveryKey: '1234-5678-90AB-CDEF-1234-5678-90AB-CDEF')));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    expect(find.byType(SelectableText), findsOneWidget);
  });
}
