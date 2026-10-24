import 'package:UniSpace/core/brand_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'unispace_brand.dart';

/// The first Flutter frame while application dependencies initialize.
class BrandLaunchApp extends StatelessWidget {
  const BrandLaunchApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(brightness: Brightness.light, fontFamily: 'Tajawal'),
        darkTheme:
            ThemeData(brightness: Brightness.dark, fontFamily: 'Tajawal'),
        home: const BrandLoadingScene(animate: true),
      );
}

class BrandLoadingScene extends StatefulWidget {
  const BrandLoadingScene({super.key, this.message, this.animate = false});
  final String? message;
  final bool animate;
  @override
  State<BrandLoadingScene> createState() => _BrandLoadingSceneState();
}

class _BrandLoadingSceneState extends State<BrandLoadingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (!widget.animate ||
        media.disableAnimations ||
        media.accessibleNavigation) {
      _reveal.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ivory = UniSpaceColors.ivory;
    const forest = UniSpaceColors.forest;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF071F1C) : ivory;
    final foreground = dark ? ivory : forest;
    final label = widget.message ??
        switch (Localizations.localeOf(context).languageCode) {
          'ar' => 'نجهّز مساحتك الجامعية',
          'fr' => 'Votre espace universitaire se prépare',
          _ => 'Preparing your campus space',
        };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: background),
      child: ColoredBox(
          color: background,
          child: SafeArea(child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 440;
              return Center(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, child) {
                      final progress =
                          Curves.easeOutCubic.transform(_reveal.value);
                      return Opacity(
                          opacity: .25 + .75 * progress,
                          child: Transform.scale(
                              scale: .94 + .06 * progress, child: child));
                    },
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              (dark ? UniSpaceColors.emerald : Colors.white)
                                  .withValues(alpha: dark ? .12 : .75),
                              background.withValues(alpha: 0),
                            ]),
                          ),
                          child: UniSpaceBrandMark(width: compact ? 116 : 184)),
                      SizedBox(height: compact ? 12 : 26),
                      Text('UniSpace',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: foreground,
                              fontSize: compact ? 29 : 35,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.2,
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 16),
                      Container(
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                              color: UniSpaceColors.emerald,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 18),
                      Semantics(
                          liveRegion: true,
                          child: Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  height: 1.6,
                                  color: foreground.withValues(alpha: .72),
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.w400))),
                    ])),
              ));
            },
          ))),
    );
  }
}
