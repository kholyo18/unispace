import 'package:UniSpace/l10n/shell_strings.dart';
import 'package:UniSpace/ui/widgets/error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget localized(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    );

void main() {
  test(
      'chat, permission, recording, attachment, and navigation text has three locales',
      () {
    for (final key in [
      'حفظ',
      'لا يمكن مراسلة هذا الحساب',
      'متابعة التسجيل',
      'إرفاق',
      'المجتمع',
      'إعادة المحاولة',
      'كشف تلقائي'
    ]) {
      expect(ShellStrings.text('ar', key), key);
      for (final locale in ['en', 'fr']) {
        final value = ShellStrings.text(locale, key);
        expect(value, isNotEmpty);
        expect(value, isNot(key));
        expect(RegExp(r'[\u0600-\u06ff]').hasMatch(value), isFalse);
      }
    }
    expect(ShellStrings.text('ar', 'Gallery'), 'المعرض');
    expect(ShellStrings.text('fr', 'Gallery'), 'Galerie');
    expect(ShellStrings.text('en', 'غير مسموح'), 'Not allowed');
    expect(ShellStrings.text('de', 'حفظ'), 'Save');
  });

  test(
      'formatting preserves user-supplied text and does not expand its placeholders',
      () {
    expect(ShellStrings.format('en', 'Replying to {0}', ['سارة {1}']),
        'Replying to سارة {1}');
    expect(ShellStrings.format('fr', 'آخر ظهور {0}', ['2 min']),
        'Dernière connexion 2 min');
    expect(ShellStrings.text('fr', 'A custom message'), 'A custom message');
  });

  testWidgets('locale changes rebuild visible chat text and direction',
      (tester) async {
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (_, value, __) => localized(value,
          Builder(builder: (context) => Text(shellText(context, 'حفظ')))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    locale.value = const Locale('fr');
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer'), findsOneWidget);
    locale.value = const Locale('ar');
    await tester.pumpAndSettle();
    expect(find.text('حفظ'), findsOneWidget);
    expect(
        Directionality.of(tester.element(find.text('حفظ'))), TextDirection.rtl);
  });

  testWidgets(
      'retry label is localized while caller message and action stay intact',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(localized(const Locale('fr'),
        ErrorBanner(message: 'حفظ', onRetry: () => retries++)));
    await tester.pumpAndSettle();
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(retries, 1);
  });
}
