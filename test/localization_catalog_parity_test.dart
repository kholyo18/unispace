import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/generated/intl/messages_ar.dart' as ar;
import 'package:UniSpace/generated/intl/messages_en.dart' as en;
import 'package:UniSpace/generated/intl/messages_fr.dart' as fr;

void main() {
  final catalogs = {
    for (final locale in ['ar', 'en', 'fr'])
      locale: jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync())
          as Map<String, dynamic>,
  };
  final generated = {
    'ar': ar.messages.messages,
    'en': en.messages.messages,
    'fr': fr.messages.messages,
  };
  Set<String> keys(Map<String, dynamic> catalog) =>
      catalog.keys.where((key) => !key.startsWith('@')).toSet();
  List<String> placeholders(String value) =>
      RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m[1]!).toSet().toList();

  test('all supported catalogs have identical keys and placeholder contracts',
      () {
    final expectedKeys = keys(catalogs['en']!);
    expect(expectedKeys.length, greaterThan(500));
    for (final locale in catalogs.keys) {
      final catalog = catalogs[locale]!;
      expect(catalog['@@locale'], locale);
      expect(keys(catalog), expectedKeys, reason: '$locale catalog keys');
      expect(generated[locale]!.keys.toSet(), expectedKeys,
          reason: '$locale generated lookup keys');
      for (final key in expectedKeys) {
        final actual = placeholders(catalog[key] as String).toSet();
        expect(actual, placeholders(catalogs['en']![key] as String).toSet(),
            reason: '$locale.$key placeholder names');
        final metadata = catalog['@$key'] as Map<String, dynamic>?;
        if (metadata?['placeholders'] != null) {
          expect((metadata!['placeholders'] as Map).keys.toSet(), actual,
              reason: '$locale.$key placeholder metadata');
        }
      }
    }
  });

  test('every generated message matches its ARB and substitutes its arguments',
      () {
    for (final locale in catalogs.keys) {
      final catalog = catalogs[locale]!;
      for (final key in keys(catalog)) {
        final template = catalog[key] as String;
        final names = placeholders(template);
        final arguments = [for (final name in names) '__${name}_value__'];
        var expected = template;
        for (var i = 0; i < names.length; i++) {
          expected = expected.replaceAll('{${names[i]}}', arguments[i]);
        }
        final actual = Function.apply(generated[locale]![key]!, arguments);
        expect(actual, expected, reason: '$locale.$key generated value');
      }
    }
  });

  test('language catalogs contain no swapped-language labels', () {
    final arabicScript = RegExp(r'[\u0600-\u06ff]');
    const sharedFrenchWords = {
      'sections',
      'note',
      'hashtag',
      'marketing',
      'finance',
      'contactDescriptionLabel',
      'smartReviewPlanRange',
      'smartReviewTaskDuration',
      'examNote',
      'notificationsSettingsTitle',
      'profileVisibilityPublic',
      'downloadsFilterImages',
      'sessionVersionLabel',
    };
    for (final key in keys(catalogs['en']!)) {
      expect(arabicScript.hasMatch(catalogs['en']![key] as String), isFalse,
          reason: 'English $key');
      expect(arabicScript.hasMatch(catalogs['fr']![key] as String), isFalse,
          reason: 'French $key');
      if (catalogs['fr']![key] == catalogs['en']![key]) {
        expect(sharedFrenchWords, contains(key),
            reason: 'Untranslated French $key');
      }
    }
  });

  test('generated S resolves corrected parameterized and profile labels',
      () async {
    await S.load(const Locale('en'));
    expect(S.current.commentsCount(3), 'Comments (3)');
    expect(S.current.clipboard, 'Notepad');
    await S.load(const Locale('ar'));
    expect(S.current.commentsCount(3), 'تعليقات (3)');
    expect(S.current.mood, 'المزاج');
    await S.load(const Locale('fr'));
    expect(S.current.university, 'Université');
    expect(S.current.userInfo, 'Informations utilisateur');
  });
}
