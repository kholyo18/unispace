import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/l10n/main_strings.dart';
import 'package:UniSpace/main.dart';

Widget localizedApp(String language, Widget child) => MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

void main() {
  test('main catalog translations preserve interpolation arguments', () {
    final placeholder = RegExp(r'\{(\d+)\}');
    Set<String> parameters(String value) =>
        placeholder.allMatches(value).map((m) => m[1]!).toSet();
    for (final entry in mainMessageCatalog.entries) {
      expect(entry.value.length, inInclusiveRange(2, 3), reason: entry.key);
      for (final translation in entry.value) {
        expect(translation.trim(), isNotEmpty, reason: entry.key);
        expect(
            parameters(translation).difference(parameters(entry.key)), isEmpty,
            reason: entry.key);
      }
    }
    expect(mainTextForLocale('fr', 'تم حظر {0}', ['A {1} عربي']),
        'A {1} عربي a été bloqué');
    expect(mainTextForLocale('ar', 'تم حظر {0}', ['User']), 'تم حظر User');
    expect(mainTextForLocale('en', 'تم حظر {0}', ['User']), 'User blocked');
  });

  test('saved regional locales normalize to a supported language', () {
    expect(supportedAppLocale('fr-DZ'), const Locale('fr'));
    expect(supportedAppLocale('ar_DZ'), const Locale('ar'));
    expect(supportedAppLocale('de'), const Locale('en'));
  });

  testWidgets(
      'live locale switch updates text and direction without changing user content',
      (tester) async {
    for (final entry in [
      ('en', 'Settings', TextDirection.ltr),
      ('ar', 'الإعدادات', TextDirection.rtl),
      ('fr', 'Paramètres', TextDirection.ltr)
    ]) {
      await tester.pumpWidget(localizedApp(
          entry.$1,
          Scaffold(
              body: Builder(
                  builder: (context) => Column(children: [
                        Text(mainText(context, 'Settings')),
                        const Text('User content محتوى utilisateur'),
                      ])))));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('User content محتوى utilisateur'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(entry.$2))), entry.$3);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'report reason sheet switches language while preserving selected reason',
      (tester) async {
    Widget page(String language) => localizedApp(
        language,
        Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      onPressed: () => showCommunityReportSheet(context,
                          type: CommunityReportType.post),
                      child: const Text('open'),
                    ))));
    await tester.pumpWidget(page('en'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
        find.text(mainTextForLocale('en', 'إساءة أو تنمّر')), findsOneWidget);
    await tester.tap(find.text(mainTextForLocale('en', 'إساءة أو تنمّر')));
    for (final locale in ['fr', 'ar', 'en']) {
      await tester.pumpWidget(page(locale));
      await tester.pumpAndSettle();
      expect(find.text(mainTextForLocale(locale, 'إساءة أو تنمّر')),
          findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
