import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/generated/l10n.dart';
import 'package:UniSpace/ui/theme.dart';
import 'package:UniSpace/ui/settings/notifications_settings_screen.dart';
void main() {
  for (final dark in [false, true]) {
    testWidgets('settings color preview dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(390,844); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await (FontLoader('Tajawal')..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf'))).load();
        await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(MaterialApp(theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily:'Tajawal'),
        appBarTheme: theme.appBarTheme.copyWith(titleTextStyle: theme.textTheme.titleLarge?.copyWith(fontFamily:'Tajawal'))),
        locale: const Locale('ar'), supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [S.delegate,...GlobalMaterialLocalizations.delegates],
        home: const RepaintBoundary(key: ValueKey('preview'),child: NotificationsSettingsScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('preview')));
        final bitmap = await boundary.toImage(pixelRatio:2);
        final bytes = await bitmap.toByteData(format:ui.ImageByteFormat.png);
        await Directory('build/brand-previews').create(recursive:true);
        await File('build/brand-previews/balanced-settings-${dark?'dark':'light'}.png').writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
    },skip: !const bool.fromEnvironment('CAPTURE_BALANCED_PALETTE'));
  }
}
