import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/l10n/feature_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/features/gpa/gpa.dart';
import 'package:UniSpace/moduls3.dart';

void main() {
  for (final locale in ['ar', 'en', 'fr']) {
    testWidgets('quick calculator labels and input remain usable in $locale',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        localizationsDelegates: const [
          S.delegate,
          ...GlobalMaterialLocalizations.delegates
        ],
        home: const QuickAverageScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.text(featureTextForLanguage(locale, 'أضف مادة')),
          findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  test('localized presentation preserves grade keys, names and weights', () {
    const track = ProgramTrack(
        name: 'Parcours canonique',
        level: 'Licence 1',
        semesters: [
          ProgramSemester(label: 'S1', unit: [
            ProgramUnit(label: 'Unité canonique', modules: [
              ProgramModule(
                  name: 'اسم المادة الأصلي',
                  coef: 3,
                  credits: 6,
                  components: [
                    ProgramComponent('TD', 40),
                    ProgramComponent('EXAM', 60),
                  ]),
            ]),
          ]),
        ]);
    final semesters = createSemesterSpecsForTrack(track);
    expect(semesters.single.name, 'S1');
    final module = semesters.single.modules.single;
    expect(module.name, 'اسم المادة الأصلي');
    expect(module.unitLabel, 'Unité canonique');
    expect(module.id, 'sem1-module1');
    expect(module.evalWeights.map((e) => e.label), ['TD', 'TP', 'EXAM']);
    expect(module.evalWeights.map((e) => e.weight), [40, 0, 60]);
    expect(module.totalWeight, 100);
  });
}
