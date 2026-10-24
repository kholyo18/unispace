import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:UniSpace/widgets/brand_launch.dart';
import 'package:UniSpace/widgets/unispace_brand.dart';

void main() {
  testWidgets('launch is visible immediately and does not delay replacement',
      (tester) async {
    await tester.pumpWidget(const BrandLaunchApp());
    await tester.pump();
    expect(find.byType(UniSpaceBrandMark), findsOneWidget);
    expect(find.text('UniSpace'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Text('Ready')));
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(BrandLoadingScene), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reveal finishes without a repeating loading animation',
      (tester) async {
    await tester.pumpWidget(const BrandLaunchApp());
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(
        tester
            .widget<Opacity>(find
                .descendant(
                    of: find.byType(BrandLoadingScene),
                    matching: find.byType(Opacity))
                .first)
            .opacity,
        1);
  });

  testWidgets('compact Arabic dark screen honors reduced motion and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: const BrandLoadingScene(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('نجهّز مساحتك الجامعية'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(BrandLoadingScene))),
        TextDirection.rtl);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
