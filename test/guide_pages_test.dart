import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/main.dart';
import 'package:UniSpace/features/guide/app_guide.dart';
import 'package:UniSpace/features/guide/guide_strings.dart';
import 'package:UniSpace/generated/l10n.dart';

Widget app(String language, Widget child, GlobalKey screenshot) =>
    RepaintBoundary(
      key: screenshot,
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Tajawal'),
        locale: Locale(language),
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        localizationsDelegates: const [
          S.delegate,
          ...GlobalMaterialLocalizations.delegates
        ],
        home: child,
      ),
    );

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_GUIDE')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/guide_previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    await loader.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final language in ['ar', 'en', 'fr']) {
    testWidgets('post and poll walkthrough targets resolve in $language',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(app(language, const CreatePostScreen(), key));
      await tester.pumpAndSettle();
      final i = language == 'ar'
          ? 0
          : language == 'fr'
              ? 2
              : 1;
      final next = ['التالي', 'Next', 'Suivant'][i];
      final done = ['إنهاء', 'Done', 'Terminer'][i];
      for (final id in [
        'post.title',
        'post.body',
        'post.images',
        'post.video',
        'post.poll',
        'post.tags',
        'post.publish'
      ]) {
        expect(find.text(guideMessages[id]![i].body), findsOneWidget,
            reason: id);
        expect(tester.takeException(), isNull, reason: id);
        if (id == 'post.title' && language == 'ar') {
          await capture(tester, key, 'post-ar');
        }
        await tester.tap(find.text(id == 'post.publish' ? done : next));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Icons.poll_outlined));
      await tester.pumpAndSettle();
      for (final id in ['poll.add', 'poll.elements', 'poll.save']) {
        expect(find.text(guideMessages[id]![i].body), findsOneWidget,
            reason: id);
        expect(tester.takeException(), isNull, reason: id);
        if (id == 'poll.add' && language == 'ar') {
          await capture(tester, key, 'poll-ar');
        }
        await tester.tap(find.text(id == 'poll.save' ? done : next));
        await tester.pumpAndSettle();
      }
      expect(find.byType(PollBuilderScreen), findsOneWidget);
      expect(find.byType(GuideHelpButton), findsNothing);
    });
  }
  testWidgets(
      'GPA guide explains both calculators and scrolls to faculty search',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester
        .pumpWidget(app('ar', const HomeLandingScreen(showAppBar: true), key));
    await tester.pumpAndSettle();
    for (final id in ['gpa.normal', 'gpa.quick', 'gpa.search']) {
      expect(find.text(guideMessages[id]![0].title), findsOneWidget,
          reason: id);
      expect(tester.takeException(), isNull, reason: id);
      if (id == 'gpa.quick') await capture(tester, key, 'gpa-ar');
      await tester.tap(find.text(id == 'gpa.search' ? 'إنهاء' : 'التالي'));
      await tester.pumpAndSettle();
    }
  });
}
