import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/main.dart' show SignInScreen;
import 'package:UniSpace/widgets/unispace_brand.dart';
import 'package:UniSpace/widgets/brand_launch.dart';

void main() {
  Future<void> mount(WidgetTester tester, String locale, bool dark,
      {double width = 390,
      double height = 844,
      double scale = 1,
      bool keyboard = false,
      Widget? home}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        S.delegate,
        ...GlobalMaterialLocalizations.delegates
      ],
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard ? 250 : 0)),
          child: child!),
      home: RepaintBoundary(
          key: const ValueKey('brand-preview'),
          child: home ?? const SignInScreen()),
    ));
    await tester.pumpAndSettle();
  }

  for (final locale in ['ar', 'en', 'fr']) {
    for (final dark in [false, true]) {
      testWidgets(
          'branded sign-in preserves form in $locale dark=$dark with keyboard and large text',
          (tester) async {
        await mount(tester, locale, dark,
            width: 320, height: 640, scale: 1.6, keyboard: true);
        expect(find.byType(UniSpaceBrandMark), findsOneWidget);
        final fields = find.byType(TextField);
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.first, 'student@example.com');
        final consent = find.byKey(const ValueKey('login-terms-consent'));
        await tester.ensureVisible(consent);
        await tester.tap(consent);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<FilledButton>(
                    find.byKey(const ValueKey('login-email-submit')))
                .onPressed,
            isNotNull);
        expect(
            tester
                .widget<OutlinedButton>(
                    find.byKey(const ValueKey('login-google-submit')))
                .onPressed,
            isNotNull);
        await tester.ensureVisible(fields.first);
        expect(tester.widget<TextField>(fields.first).controller!.text,
            'student@example.com');
        expect(tester.takeException(), isNull);
      });
    }
  }
  if (const bool.fromEnvironment('CAPTURE_BRAND_PREVIEWS')) {
    testWidgets('capture actual branded screens', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        final google = FontLoader(
            'packages/font_awesome_flutter/FontAwesomeBrands')
          ..addFont(rootBundle.load(
              'packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf'));
        await google.load();
      });
      for (final entry in ['login-light', 'login-dark', 'launch']) {
        await mount(tester, 'ar', entry == 'login-dark',
            width: 430,
            height: 932,
            home: entry == 'launch' ? const BrandLoadingScene() : null);
        tester.view.physicalSize = const Size(860, 1864);
        tester.view.devicePixelRatio = 2;
        await tester.pump();
        final markImage = tester.widget<Image>(find.descendant(
            of: find.byType(UniSpaceBrandMark), matching: find.byType(Image)));
        await tester.runAsync(() => precacheImage(
            markImage.image, tester.element(find.byType(UniSpaceBrandMark))));
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('brand-preview')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/brand-previews/$entry.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    });
  }
}
