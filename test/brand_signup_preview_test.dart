import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/features/auth/signup_flow.dart';
import 'package:firebase_core/firebase_core.dart';
// Firebase's test helper initializes the platform channel without a live backend.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:UniSpace/widgets/unispace_brand.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async { await Firebase.initializeApp(); });
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
          child: home ?? SignUpFlowScreen(key: ValueKey(dark), skipAccountCreation: true, initialFirstName: 'سارة', initialLastName: 'أحمد')),
    ));
    await tester.pumpAndSettle();
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
      for (final entry in ['signup-light', 'signup-dark']) {
        await mount(tester, 'ar', entry == 'signup-dark',
            width: 430,
            height: 932,
            home: null);
        final next = find.byKey(const ValueKey('signup-continue'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
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
