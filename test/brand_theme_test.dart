import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:UniSpace/core/branding.dart';
import 'package:UniSpace/ui/theme.dart';
import 'package:UniSpace/features/gpa/gpa.dart';
import 'package:UniSpace/generated/l10n.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { AppPrimary.apply(UniSpaceColors.forest); AppTeal.apply(UniSpaceColors.forest); });
  for (final dark in [false, true]) {
    test('brand roles have readable text and controls dark=$dark', () {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      final c = theme.colorScheme;
      for (final pair in [(c.onSurface, c.surface), (c.onSurfaceVariant, c.surface),
        (c.onPrimary, c.primary), (c.onPrimaryContainer, c.primaryContainer), (c.onSecondary, c.secondary), (c.onError, c.error),
        (c.onSecondaryContainer, c.secondaryContainer),
        (c.onSurface, theme.scaffoldBackgroundColor)]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(c.outline, c.surface), greaterThanOrEqualTo(3));
      expect(c.primary, dark ? UniSpaceColors.mint : UniSpaceColors.forest);
      expect(theme.scaffoldBackgroundColor, UniSpaceColors.background(dark));
      expect(theme.cardTheme.color, c.surface);
      expect(theme.dialogTheme.backgroundColor, c.surface);
      expect(theme.bottomSheetTheme.backgroundColor, c.surface);
      expect(c.error, isNot(c.primary));
    });
  }
  test('custom accent still changes primary and reset restores brand', () {
    AppPrimary.apply(const Color(0xFF5A3192));
    expect(AppTheme.light.colorScheme.primary, isNot(UniSpaceColors.forest));
    AppPrimary.apply(UniSpaceColors.forest);
    expect(AppTheme.light.colorScheme.primary, UniSpaceColors.forest);
    expect(AppTeal.main, UniSpaceColors.forest);
  });
  for (final locale in ['ar', 'en', 'fr']) {
    for (final dark in [false, true]) {
      testWidgets('quick calculator retains calculation and follows $locale dark=$dark', (tester) async {
        SharedPreferences.setMockInitialValues({
          'quick_calc_state_v1': '{"threshold":10,"avg":14,"totalcred":5,"subjects":[{"subject":"Math","coef":2,"cred":5,"exam":14,"td":14,"tp":14,"wexam":0.6,"wtd":0.4,"wtp":0}]}'
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: const bool.fromEnvironment('CAPTURE_PALETTE_PREVIEWS')
              ? (dark ? AppTheme.dark : AppTheme.light).copyWith(appBarTheme: (dark ? AppTheme.dark : AppTheme.light).appBarTheme.copyWith(
                    titleTextStyle: (dark ? AppTheme.dark : AppTheme.light).textTheme.titleLarge?.copyWith(fontFamily: 'Tajawal')), textTheme:
                  (dark ? AppTheme.dark : AppTheme.light).textTheme.apply(fontFamily: 'Tajawal'))
              : (dark ? AppTheme.dark : AppTheme.light),
          locale: Locale(locale), supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
          home: const RepaintBoundary(key: ValueKey('palette-preview'), child: QuickAverageScreen()),
        ));
        await tester.pumpAndSettle();
        expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          UniSpaceColors.background(dark));
        final context = tester.element(find.byType(QuickAverageScreen));
        await tester.tap(find.text(S.of(context).calculate));
        await tester.pumpAndSettle();
        expect(find.text('14.00'), findsWidgets);
        await tester.tap(find.text(S.of(context).save));
        await tester.pumpAndSettle();
        expect((await SharedPreferences.getInstance()).getString('quick_calc_state_v1'), contains('Math'));
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_PALETTE_PREVIEWS') && locale == 'ar') {
          await tester.runAsync(() async {
            final font = FontLoader('Tajawal')..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
            await font.load();
            final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
          });
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('palette-preview')));
            final img = await boundary.toImage(pixelRatio: 2);
            final data = await img.toByteData(format: ui.ImageByteFormat.png);
            await Directory('build/brand-previews').create(recursive: true);
            await File('build/brand-previews/calculator-${dark ? 'dark' : 'light'}.png').writeAsBytes(data!.buffer.asUint8List());
            img.dispose();
          });
        }
      });
    }
  }
}
