import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/l10n/modules_strings.dart';
import 'package:UniSpace/l10n/shell_strings.dart';
import 'package:UniSpace/moduls2.dart' as legacy;
import 'package:UniSpace/moduls3.dart' as current;
import 'package:UniSpace/services/media_upload_limits.dart';

void main() {
  test(
      'every known academic literal is mapped except two opaque source abbreviations',
      () {
    const unresolved = {
      'ك.ع.خ.اع. بالغة الانجليزية',
      'ك.ع.خ.اع. باللغة الانجليزية'
    };
    final names = <String>{};
    for (final path in ['lib/moduls2.dart', 'lib/moduls3.dart']) {
      final source = File(path).readAsStringSync();
      names.addAll(RegExp(r"(?:name|label):\s*'([^']+)'")
          .allMatches(source)
          .map((m) => m[1]!));
    }
    expect(names.length, greaterThan(600));
    final missing =
        names.where((name) => !AcademicStrings.hasTranslation(name)).toSet();
    expect(missing, unresolved);
    for (final name in names.difference(unresolved)) {
      for (final language in ['en', 'fr']) {
        final translated = AcademicStrings.text(language, name);
        expect(translated, isNotEmpty, reason: '$language: $name');
        expect(RegExp(r'[\u0600-\u06ff]').hasMatch(translated), isFalse,
            reason: '$language: $name');
      }
    }
  });

  test(
      'display lookup handles numbered spellings without changing unknown content',
      () {
    expect(AcademicStrings.text('fr', 'محاسبة مالية1'),
        'Comptabilité financière 1');
    expect(AcademicStrings.text('en', 'اقتصاد كلي 2 '), 'Macroeconomics 2');
    expect(AcademicStrings.text('ar', 'اقتصاد كلي 2 '), 'اقتصاد كلي 2 ');
    expect(AcademicStrings.text('ar', ' Coming soon'), 'قريبًا');
    expect(AcademicStrings.text('fr', 'My custom course 12'),
        'My custom course 12');
    expect(AcademicStrings.text('ar', 'EXAM'), 'الامتحان');
  });

  testWidgets(
      'both catalog models keep canonical names and grading values across locales',
      (tester) async {
    const oldModule = legacy.ProgramModule(
        name: 'محاسبة مالية1',
        coef: 3,
        credits: 6,
        components: [
          legacy.ProgramComponent('TD', 40),
          legacy.ProgramComponent('EXAM', 60)
        ]);
    const newModule = current.ProgramModule(
        name: 'محاسبة مالية1',
        coef: 3,
        credits: 6,
        components: [
          current.ProgramComponent('TD', 40),
          current.ProgramComponent('EXAM', 60)
        ]);
    for (final language in ['ar', 'en', 'fr']) {
      await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
              builder: (context) => Column(children: [
                    Text(oldModule.displayName(context)),
                    Text(newModule.displayName(context)),
                  ]))));
      await tester.pumpAndSettle();
      expect(find.text(AcademicStrings.text(language, newModule.name)),
          findsNWidgets(2));
      expect(oldModule.name, 'محاسبة مالية1');
      expect(newModule.name, 'محاسبة مالية1');
      expect(oldModule.coef, 3);
      expect(newModule.credits, 6);
      expect(newModule.components.map((c) => c.weight), [40, 60]);
      expect(oldModule.components.map((c) => c.label), ['TD', 'EXAM']);
    }
  });

  test(
      'service display localization preserves validation and exception contracts',
      () {
    try {
      validateMediaUploadSize(0, video: false);
      fail('Empty uploads must still fail');
    } on MediaUploadValidation catch (error) {
      expect(error.message, 'الملف فارغ أو يتجاوز الحد المسموح: 20 ميغابايت');
      expect(ShellStrings.error('en', error),
          'The file is empty or exceeds the 20 MB limit');
      expect(ShellStrings.error('fr', error),
          'Le fichier est vide ou dépasse la limite de 20 Mo');
    }
    expect(() => postVideoContentType('exe'),
        throwsA(isA<MediaUploadValidation>()));
    expect(
        ShellStrings.error(
            'fr', const MediaUploadValidation('صيغة الفيديو غير مدعومة')),
        'Format vidéo non pris en charge');
    final error = StateError('تغيّر الحساب أثناء رفع الملف.');
    expect(ShellStrings.error('en', error), 'Account changed during upload.');
    expect(error.message, 'تغيّر الحساب أثناء رفع الملف.');
    expect(ShellStrings.error('fr', StateError('Unknown diagnostic')),
        'Bad state: Unknown diagnostic');
  });
}
