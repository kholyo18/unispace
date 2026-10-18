import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/features/guide/app_guide.dart';
import 'package:UniSpace/features/guide/guide_strings.dart';

Widget page(
        {bool autoStart = false,
        String language = 'en',
        VoidCallback? onTap,
        List<GuideStep> steps = const [
          GuideStep('first', 'post.title'),
          GuideStep('second', 'post.publish')
        ],
        double textScale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      home: AppGuide(
          id: 'test',
          autoStart: autoStart,
          steps: steps,
          child: Scaffold(
            appBar: AppBar(actions: const [GuideHelpButton()]),
            body: Column(children: [
              GuideTarget(
                  id: 'first',
                  child: TextButton(
                      onPressed: onTap ?? () {},
                      child: const Text('protected action'))),
              const Spacer(),
              const GuideTarget(id: 'second', child: Text('second target')),
              const SizedBox(height: 50),
            ]),
          )),
    );

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Page guide'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('all guide messages contain three complete translations', () {
    for (final entry in guideMessages.entries) {
      expect(entry.value.length, 3, reason: entry.key);
      for (final copy in entry.value) {
        expect(copy.title, isNotEmpty);
        expect(copy.body, isNotEmpty);
      }
    }
  });
  testWidgets(
      'spotlight follows targets, blocks actions, supports back and completion',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(page(onTap: () => calls++));
    await open(tester);
    expect(find.text('Post title'), findsOneWidget);
    GuideScrimPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GuideScrimPainter>()
        .single;
    final first = painter().target!;
    expect(first.contains(tester.getCenter(find.text('protected action'))),
        isTrue);
    await tester.tap(find.text('protected action'), warnIfMissed: false);
    expect(calls, 0);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review, then publish'), findsOneWidget);
    expect(painter().target!.top, greaterThan(first.top));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Post title'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('protected action'));
    expect(calls, 1);
    expect((await SharedPreferences.getInstance()).getBool('app_guide_v1_test'),
        isTrue);
  });
  testWidgets('automatic guide is remembered, manual replay remains available',
      (tester) async {
    await tester.pumpWidget(page(autoStart: true));
    await tester.pumpAndSettle();
    expect(find.text('Post title'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(autoStart: true));
    await tester.pumpAndSettle();
    expect(find.text('Post title'), findsNothing);
    await open(tester);
    expect(find.text('Post title'), findsOneWidget);
  });
  testWidgets('missing conditional target is skipped without crashing',
      (tester) async {
    await tester.pumpWidget(page(steps: const [
      GuideStep('missing', 'post.body'),
      GuideStep('second', 'post.publish')
    ]));
    await open(tester);
    expect(find.text('Review, then publish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('all missing targets do not permanently suppress first-run guide',
      (tester) async {
    await tester
        .pumpWidget(page(steps: const [GuideStep('missing', 'post.body')]));
    await open(tester);
    expect(find.text('Post content'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('app_guide_v1_test'),
        isNull);
  });
  testWidgets('Arabic and French guide text uses active locale',
      (tester) async {
    for (final language in ['ar', 'fr']) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(language: language));
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      final title =
          language == 'ar' ? 'عنوان المنشور' : 'Titre de la publication';
      expect(find.text(title), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(title))),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'small viewport and enlarged text stay scrollable without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(page(textScale: 2));
    await open(tester);
    expect(find.text('Post title'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Review, then publish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'disposal during step preparation does not update a disposed state',
      (tester) async {
    await tester.pumpWidget(page());
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
