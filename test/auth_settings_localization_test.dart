import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/l10n/auth_settings_strings.dart';
import 'package:UniSpace/l10n/auth_terms_strings.dart';
import 'package:UniSpace/ui/auth/account_recovery_screen.dart';
import 'package:UniSpace/features/auth/terms_of_use_screen.dart';

Widget app(Locale locale, Widget child) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void main() {
  test('every auth/settings message has English and French with matching placeholders', () {
    final placeholder = RegExp(r'\{([a-zA-Z]+)\}');
    Set<String> parameters(String value) => placeholder.allMatches(value).map((m) => m[1]!).toSet();
    for (final entry in authSettingsCatalog.entries) {
      expect(entry.value, hasLength(2), reason: entry.key);
      for (final translation in entry.value) {
        expect(translation.trim(), isNotEmpty, reason: entry.key);
        expect(parameters(translation), parameters(entry.key), reason: entry.key);
      }
    }
  });

  test('interpolation preserves user values and does not recursively substitute', () {
    expect(authSettingsTextForLocale('fr', 'رقمك الحالي: {phone}', {'phone': '+213612345678'}), 'Votre numéro actuel : +213612345678');
    expect(authSettingsTextForLocale('en', 'المفتاح: {key}', {'key': '{count} بيانات'}), 'Key: {count} بيانات');
    expect(authSettingsTextForLocale('ar', 'المفتاح: {key}', {'key': 'ABC-123'}), 'المفتاح: ABC-123');
  });

  test('destructive confirmation uses the displayed language', () {
    expect(authSettingsTextForLocale('en', 'حذف'), 'DELETE');
    expect(authSettingsTextForLocale('fr', 'حذف'), 'SUPPRIMER');
    expect(authSettingsTextForLocale('ar', 'حذف'), 'حذف');
  });

  testWidgets('recovery key screen follows language switches without changing the key', (tester) async {
    for (final item in [('ar', 'احفظ مفتاح الاستعادة', TextDirection.rtl), ('en', 'Save your recovery key', TextDirection.ltr), ('fr', 'Enregistrez votre clé de récupération', TextDirection.ltr)]) {
      await tester.pumpWidget(app(Locale(item.$1), const RecoveryKeyScreen(recoveryKey: 'KEEP-THIS-KEY')));
      await tester.pumpAndSettle();
      expect(find.text(item.$2), findsOneWidget);
      expect(find.text('KEEP-THIS-KEY'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(item.$2))), item.$3);
      expect(tester.takeException(), isNull);
    }
  });

  test('all 22 terms sections include complete English and French text', () {
    expect(authTermsTranslations, hasLength(22));
    for (var index = 0; index < authTermsTranslations.length; index++) {
      final section = authTermsTranslations[index];
      expect(section, hasLength(4));
      expect(section[0], startsWith('${index + 1}. '));
      expect(section[1], startsWith('${index + 1}. '));
      expect(section[2].length, greaterThan(150));
      expect(section[3].length, greaterThan(150));
    }
  });

  testWidgets('terms reader changes headings and direction in all supported languages', (tester) async {
    for (final item in [('ar', 'شروط الاستخدام'), ('en', 'Terms of use'), ('fr', 'Conditions d’utilisation')]) {
      await tester.pumpWidget(app(Locale(item.$1), const TermsOfUseScreen()));
      await tester.pumpAndSettle();
      expect(find.text(item.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
