import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/legal/community_guidelines_screen.dart';
import 'package:UniSpace/features/settings/privacy/privacy_policy_screen.dart';
import 'package:UniSpace/features/settings/privacy/account_deletion_screen.dart';
import 'package:UniSpace/l10n/feature_strings.dart';

Widget app(String locale, Widget child) => MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

void main() {
  test('labels select static translations and preserve unknown canonical names',
      () {
    expect(featureTextForLanguage('ar', 'COEF'), 'المعامل');
    expect(featureTextForLanguage('en', 'S1 Résumé'), 'Semester 1 summary');
    expect(featureTextForLanguage('fr', 'S1 Résumé'), 'Résumé S1');
    expect(featureTextForLanguage('de', 'حفظ'), 'Save');
    for (final language in ['ar', 'en', 'fr']) {
      expect(featureTextForLanguage(language, 'Algebra 701'), 'Algebra 701');
    }
  });

  for (final locale in ['ar', 'en', 'fr']) {
    testWidgets(
        'policy readers expose all sections in $locale with correct direction',
        (tester) async {
      for (final item in [
        (
          widget: const CommunityGuidelinesScreen(),
          prefix: 'community',
          count: 12
        ),
        (widget: const PrivacyPolicyScreen(), prefix: 'privacy', count: 11),
      ]) {
        await tester.pumpWidget(app(locale, item.widget));
        await tester.pumpAndSettle();
        for (var i = 1; i <= item.count; i++) {
          expect(find.byKey(ValueKey('${item.prefix}-heading-$i')),
              findsOneWidget);
        }
        final title = find.byKey(ValueKey('${item.prefix}-reader-title'));
        expect(Directionality.of(tester.element(title)),
            locale == 'ar' ? TextDirection.rtl : TextDirection.ltr);
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data ?? '')
            .join('\n');
        expect(RegExp(r'[\u0600-\u06ff]').hasMatch(texts), locale == 'ar');
        expect(texts, contains('unispace.0.1.0@gmail.com'));
        expect(find.byType(Checkbox), findsNothing);
        if (item.prefix == 'privacy') {
          for (final period in ['30', '90', '180']) {
            expect(texts, contains(period));
          }
          expect(
              texts, contains('https://fachub-c631c.web.app/delete-account'));
        }
      }
    });

    testWidgets(
        'deletion disclosures and disabled consent gate localize in $locale',
        (tester) async {
      await tester.pumpWidget(app(locale, const AccountDeletionScreen()));
      await tester.pumpAndSettle();
      final title = tester
          .widget<Text>(find.byKey(const ValueKey('account-delete-title')));
      expect(
          title.data, featureTextForLanguage(locale, 'طلب حذف حساب UniSpace'));
      final button = tester.widget<FilledButton>(
          find.byKey(const ValueKey('account-delete-submit')));
      expect(button.onPressed, isNull);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .join('\n');
      expect(RegExp(r'[\u0600-\u06ff]').hasMatch(texts), locale == 'ar');
      for (final period in ['30', '90', '180']) {
        expect(texts, contains(period));
      }
    });
  }

  testWidgets(
      'visible text responds to a locale change without recreating the reader',
      (tester) async {
    await tester.pumpWidget(app('en', const CommunityGuidelinesScreen()));
    expect(find.text('UniSpace community guidelines'), findsOneWidget);
    await tester.pumpWidget(app('fr', const CommunityGuidelinesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Règles de la communauté UniSpace'), findsOneWidget);
    expect(find.text('UniSpace community guidelines'), findsNothing);
  });
}
