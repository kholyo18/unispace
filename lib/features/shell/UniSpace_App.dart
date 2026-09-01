import 'package:flutter/material.dart';
import '../../../generated/l10n.dart';
import 'package:UniSpace/main.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:UniSpace/core//branding.dart';
import 'package:UniSpace/ui/theme.dart';
import 'package:UniSpace/ui/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class UniSpaceApp extends StatefulWidget {
//   const UniSpaceApp({
//     super.key,
//     required this.initialThemeMode,
//     required this.initialLocale,
//   });
//
//   final ThemeMode initialThemeMode;
//   final Locale initialLocale;
//
//   static _UniSpaceAppState of(BuildContext context) =>
//       context.findAncestorStateOfType<_UniSpaceAppState>()!;
//
//   @override
//   State<UniSpaceApp> createState() => _UniSpaceAppState();
// }
//
// class _UniSpaceAppState extends State<UniSpaceApp> {
//   ThemeMode _themeMode = ThemeMode.system;
//   Locale _locale = const Locale('en');
//
//   Color _primaryColor = AppPrimary.seed;
//   static const _kPrimary = 'pref_primaryColor';
//
//   Color get primaryColor => _primaryColor;
//
//
//
//   Future<void> setTealColor(Color c) async {
//     _tealColor = c;
//     AppTeal.apply(c);
//     setState(() {});
//     final p = await SharedPreferences.getInstance();
//     await p.setInt(_kTeal, c.value);
//   }
//
//   Future<void> setPrimaryColor(Color c) async {
//     _primaryColor = c;
//     AppPrimary.apply(c);
//     setState(() {});
//     final p = await SharedPreferences.getInstance();
//     await p.setInt(_kPrimary, c.value);
//   }
//   static const _kTheme = 'pref_themeMode';
//   static const _kLocale = 'pref_locale';
//   Color _tealColor = kDefaultTeal;
//   static const _kTeal = 'pref_tealColor';
//
//   Color get tealColor => _tealColor;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _themeMode = widget.initialThemeMode;
//     _locale = widget.initialLocale;
//     _restorePrefs();
//   }
//
//   Future<void> _restorePrefs() async {
//     final p = await SharedPreferences.getInstance();
//     final themeIdx = p.getInt(_kTheme);
//     final lang = p.getString(_kLocale);
//
//     final tealVal = p.getInt('pref_tealColor');
//     if (tealVal != null) AppTeal.apply(Color(tealVal));
//     final primaryVal = p.getInt(_kPrimary);
//     if (primaryVal != null) {
//       _primaryColor = Color(primaryVal);
//       AppPrimary.apply(_primaryColor);
//     }
//     if (tealVal != null) {
//       _tealColor = Color(tealVal);
//       AppTeal.apply(_tealColor);
//     }
//     if (themeIdx != null &&
//         themeIdx >= 0 &&
//         themeIdx < ThemeMode.values.length) {
//       _themeMode = ThemeMode.values[themeIdx];
//     }
//     if (lang != null && lang.isNotEmpty) {
//       _locale = Locale(lang);
//     }
//     if (mounted) setState(() {});
//   }
//
//   Future<void> setThemeMode(ThemeMode m) async {
//     setState(() => _themeMode = m);
//     final p = await SharedPreferences.getInstance();
//     await p.setInt(_kTheme, m.index);
//   }
//
//   Future<void> setLocale(Locale l) async {
//     setState(() => _locale = l);
//     final p = await SharedPreferences.getInstance();
//     await p.setString(_kLocale, l.languageCode);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'UniSpace',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light,
//       darkTheme: AppTheme.dark,
//       themeMode: _themeMode,
//       locale: _locale,
//       localizationsDelegates: [
//         S.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: S.delegate.supportedLocales,
//       builder: (context, child) {
//         return ValueListenableBuilder<SettingsData>(
//           valueListenable: AppSettings.instance.notifier,
//           builder: (context, settings, _) {
//             return MediaQuery(
//               data: MediaQuery.of(context).copyWith(
//                 textScaler: TextScaler.linear(settings.fontScale.scale),
//               ),
//               child: child ?? const SizedBox.shrink(),
//             );
//           },
//         );
//       },
//       home: const AuthGate(),
//     );
//   }
// }
