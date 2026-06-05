// ============================================================================
// UniSpace — main.dart (UPDATED: BottomBar + Notes + Reddit-like Community + Table)
// PART 1/3
// ============================================================================
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Local
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/verify_email_screen.dart';
import 'ui/auth/two_factor_otp_screen.dart';

// PDF / Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'ui/theme.dart';
import 'ui/contact/contact_us_sheet.dart';
import 'ui/widgets/widgets.dart';
import 'ui/faculty_search_page.dart';
import 'ui/settings/app_settings.dart';
import 'ui/settings/drawer_screens.dart';
import 'ui/settings/security_privacy_screen.dart';
import 'ui/settings/email_verification_service.dart';
import 'ui/settings/user_profile_service.dart';
import 'ui/settings/session_service.dart';
import 'services/auth_session_service.dart';
import 'services/two_factor_service.dart';
import 'features/auth/signup_flow.dart';
import 'features/settings/about/about_screen.dart';
import 'features/settings/privacy/privacy_policy_screen.dart';
import 'features/exams/presentation/pages/exams_calendar_page.dart';
import 'features/study_plan/presentation/smart_review_plan_page.dart';
import './moduls3.dart';
import './moduls.dart';
import 'module/moduls.dart';
import 'config/app_links.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package: UniSpace/generated/l10n.dart';
//import 'core/local/grades_local_store.dart';
import 'package:translator/translator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
//import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/rendering.dart';

Future<void> openPdf(String filePath) async {
  final result = await OpenFilex.open(filePath);
  print(result); // Optional: لمراجعة حالة الفتح
}

// ============================================================================
// Branding
// ============================================================================
const kUniSpaceGreen = Color(0xFFB2DFDB);
const kUniSpaceBlue = Color(0xFF004D40);
const kNoteYellow = Color(0xFFFFF3C4);

// ============================================================================
// Bootstrap
// ============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  await Hive.initFlutter();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Algiers'));

  // تسجيل Hive Adapter
  Hive.registerAdapter(ModuleModelAdapter());
  await AppSettings.instance.load();
  await UserProfileService.instance.initialize();
  runApp(const UniSpaceApp());
}

// ============================================================================
// App root (Theme + Locale)  — مع حفظ التفضيلات
// ============================================================================

class UniSpaceApp extends StatefulWidget {
  const UniSpaceApp({super.key});
  static _UniSpaceAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_UniSpaceAppState>()!;

  @override
  State<UniSpaceApp> createState() => _UniSpaceAppState();
}

class _UniSpaceAppState extends State<UniSpaceApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');

  static const _kTheme = 'pref_themeMode';
  static const _kLocale = 'pref_locale';

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  Future<void> _restorePrefs() async {
    final p = await SharedPreferences.getInstance();
    final themeIdx = p.getInt(_kTheme);
    final lang = p.getString(_kLocale);
    if (themeIdx != null &&
        themeIdx >= 0 &&
        themeIdx < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIdx];
    }
    if (lang != null && lang.isNotEmpty) {
      _locale = Locale(lang);
    }
    if (mounted) setState(() {});
  }

  Future<void> setThemeMode(ThemeMode m) async {
    setState(() => _themeMode = m);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTheme, m.index);
  }

  Future<void> setLocale(Locale l) async {
    setState(() => _locale = l);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, l.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SettingsData>(
      valueListenable: AppSettings.instance.notifier,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'UniSpace',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode,
          locale: _locale,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(settings.fontScale.scale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}

// ============================================================================
// Global End Drawer — يعمل فعليًا (مظهر/لغة/إعادة كلمة السر/روابط)
// ============================================================================
class AppEndDrawer extends StatefulWidget {
  const AppEndDrawer({super.key});

  @override
  State<AppEndDrawer> createState() => _AppEndDrawerState();
}

class _AppEndDrawerState extends State<AppEndDrawer> {
  static const bool _showPrivacyAndContactInDrawer = false;
  static const _privacyHideMenuKey = 'privacy_hide_menu_item';
  bool _sendingOtp = false;
  int _otpCooldownSeconds = 0;
  Timer? _otpTimer;
  bool _hidePrivacyEntry = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyDrawerVisibility();
  }

  Future<void> _loadPrivacyDrawerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_privacyHideMenuKey) ?? false;
    if (!mounted) return;
    setState(() => _hidePrivacyEntry = hidden);
  }

  Future<void> _sendOtp(User user) async {
    if (_sendingOtp) return;
    if (_otpCooldownSeconds > 0) return;
    setState(() => _sendingOtp = true);
    try {
      final result = await EmailVerificationService.instance.sendOtp(user: user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpSentSuccess)),
      );
      _startOtpCooldown(result.cooldownSeconds);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).otpSentFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }
  }

  void _startOtpCooldown(int seconds) {
    _otpTimer?.cancel();
    setState(() => _otpCooldownSeconds = seconds);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _otpCooldownSeconds = 0);
      } else {
        setState(() => _otpCooldownSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _rateApp() async {
    final launched = await launchUrl(
      Uri.parse(AppLinks.storeUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).rateAppFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = UniSpaceApp.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Drawer(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            return ValueListenableBuilder<UserProfileData>(
              valueListenable: UserProfileService.instance.notifier,
              builder: (context, profile, _) {
            final displayName = user?.displayName ??
                user?.email?.split('@').first ??
                S.of(context).guestUser;
            final emailText = user?.email == null
                ? S.of(context).emailUnavailable
                : profile.showEmailInProfile
                    ? user!.email!
                    : S.of(context).emailHidden;
            final isVerified = user?.emailVerified ?? false;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kUniSpaceBlue, kUniSpaceGreen],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: kUniSpaceBlue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  emailText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isVerified
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified
                                        ? Icons.verified
                                        : Icons.warning_amber_rounded,
                                    size: 16,
                                    color: isVerified
                                        ? Colors.green.shade200
                                        : Colors.orange.shade200,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isVerified
                                        ? S.of(context).emailVerified
                                        : S.of(context).emailNotVerified,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isVerified)
                              TextButton.icon(
                                onPressed: _sendingOtp || _otpCooldownSeconds > 0
                                    ? null
                                    : () => _sendOtp(user!),
                                icon: _sendingOtp
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.mark_email_unread),
                                label: Text(
                                  _otpCooldownSeconds > 0
                                      ? S.of(context)
                                          .otpCooldownLabel(_otpCooldownSeconds)
                                      : S.of(context).sendOtpNow,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _sectionHeader(context, S.of(context).drawerSectionAccount),
                _drawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: S.of(context).editProfile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),


                _sectionHeader(context, S.of(context).drawerSectionStudent),
                _drawerItem(
                  context,
                  icon: Icons.school_outlined,
                  title: S.of(context).gpu,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeLandingScreen(),
                      ),
                    );
                  },
                ),


                _sectionHeader(context, S.of(context).drawerSectionContent),
                _drawerItem(
                  context,
                  icon: Icons.download_outlined,
                  title: S.of(context).downloadsTitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DownloadsScreen(),
                      ),
                    );
                  },
                ),
                // _drawerItem(
                //   context,
                //   icon: Icons.star_border,
                //   title: S.of(context).favoritesTitle,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => const FavoritesScreen(),
                //       ),
                //     );
                //   },
                // ),

                _drawerItem(
                  context,
                  icon: Icons.note_alt_outlined,
                  title: S.of(context).clipboard,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotesScreen(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.psychology_outlined,
                  title: S.of(context).smartReviewPlanTitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmartReviewPlanPage(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: S.of(context).examCalendar,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExamsCalendarPage(),
                      ),
                    );
                  },
                ),
                _sectionHeader(context, S.of(context).drawerSectionApp),
                // _drawerItem(
                //   context,
                //   icon: Icons.text_fields_outlined,
                //   title: S.of(context).fontSizeTitle,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => const FontSizeScreen(),
                //       ),
                //     );
                //   },
                // ),
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: Text(S.of(context).changeTheme),
                  subtitle: Text(
                    app._themeMode == ThemeMode.light
                        ? S.of(context).lightMode
                        : app._themeMode == ThemeMode.dark
                            ? S.of(context).darkMode
                            : S.of(context).systemMode,
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _ThemeModeSheet(app: app),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(S.of(context).changeLanguage),
                  subtitle: Text(_langName(app._locale.languageCode)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _LanguageSheet(),
                    );
                  },
                ),
                if (!_hidePrivacyEntry)
                  _drawerItem(
                    context,
                    icon: Icons.security_outlined,
                    title: S.of(context).securityPrivacyTitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityPrivacyScreen(),
                        ),
                      ).then((_) => _loadPrivacyDrawerVisibility());
                    },
                  ),
                _drawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: S.of(context).notificationsSettingsTitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsSettingsScreen(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.star_rate_outlined,
                  title: S.of(context).rateApp,
                  onTap: _rateApp,
                ),
                _drawerItem(
                  context,
                  icon: Icons.share_outlined,
                  title: S.of(context).shareApp,
                  onTap: () => Share.share(AppLinks.shareMessage),
                ),
                if (_showPrivacyAndContactInDrawer)
                  _drawerItem(
                    context,
                    icon: Icons.email_outlined,
                    title: S.of(context).contactUs,
                    onTap: () {
                      _showContactDialog(context);
                    },
                  ),
                _drawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: S.of(context).aboutApp,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                if (_showPrivacyAndContactInDrawer)
                  _drawerItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: S.of(context).privacyPolicy,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                const Divider(height: 24),
                if (user != null)
                  _drawerItem(
                    context,
                    icon: Icons.logout,
                    title: S.of(context).logout,
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        await SessionService.instance.revokeCurrentSession(currentUser.uid);
                      }
                      if (kDebugMode) {
                        debugPrint('[Auth] drawer logout requested');
                      }
                      await AuthSessionService.signOutFully();
                      if (kDebugMode) {
                        debugPrint('[Auth] logout complete');
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  )
                else
                  _drawerItem(
                    context,
                    icon: Icons.login,
                    title: S.of(context).login,
                    onTap: () {
                      if (kDebugMode) {
                        debugPrint('[Auth] login drawer item tapped while signed out');
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'UniSpace © ${DateTime.now().year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.iconTheme.color),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }

  void _showContactDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ContactUsSheet(),
    );
  }

  static String _langName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'العربية';
    }
  }
}

class _ThemeModeSheet extends StatelessWidget {
  final _UniSpaceAppState app;
  const _ThemeModeSheet({required this.app});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          title: Text(S.of(context).chooseTheme),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          groupValue: app._themeMode,
          title: Text(S.of(context).light),
          onChanged: (v) => _apply(context, v!),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          groupValue: app._themeMode,
          title: Text(S.of(context).dark),
          onChanged: (v) => _apply(context, v!),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          groupValue: app._themeMode,
          title: Text(S.of(context).system),
          onChanged: (v) => _apply(context, v!),
        ),
      ]),
    );
  }

  void _apply(BuildContext context, ThemeMode m) {
    app.setThemeMode(m);
    Navigator.pop(context);
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = UniSpaceApp.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(S.of(context).chooseLanguage),
          ),
          RadioListTile<String>(
            value: 'ar',
            groupValue: app._locale.languageCode,
            title: Text(S.of(context).arabic),
            onChanged: (_) {
              app.setLocale(const Locale('ar'));
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            value: 'fr',
            groupValue: app._locale.languageCode,
            title: const Text("Français"),
            onChanged: (_) {
              app.setLocale(const Locale('fr'));
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            value: 'en',
            groupValue: app._locale.languageCode,
            title: const Text("English"),
            onChanged: (_) {
              app.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class AutoTranslate {
  static final translator = GoogleTranslator();

  static Future<String> tr(BuildContext context, String text) async {
    final lang = UniSpaceApp.of(context)._locale.languageCode;

    // إذا كانت نفس اللغة → لا حاجة للترجمة
    if (lang == 'ar') return text;

    try {
      final translation = await translator.translate(text, to: lang);
      return translation.text;
    } catch (_) {
      return text; // إذا فشلت الترجمة
    }
  }
}

final translator = GoogleTranslator(); // كائن الترجمة

/// ترجمة النص حسب لغة التطبيق
Future<String> translateSubject(BuildContext context, String subject) async {
  try {
    // جلب اللغة المختارة من التطبيق
    final lang = UniSpaceApp.of(context)._locale.languageCode;

    // إذا كانت العربية → نعيد النص كما هو
    if (lang == 'ar') return subject;

    // ترجمة للنص حسب اللغة المختارة
    var translation = await translator.translate(subject, to: lang);
    return translation.text;
  } catch (e) {
    // fallback عند حدوث خطأ
    return subject;
  }
}

class _DrawerLeading extends StatelessWidget {
  final bool showBack;
  const _DrawerLeading({required this.showBack});

  @override
  Widget build(BuildContext context) {
    final menuButton = Builder(
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu_open),
        tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
      ),
    );

    if (!showBack) {
      return menuButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 4),
        menuButton,
      ],
    );
  }
}

// ============================================================================
// Auth Gate + SignIn
// ============================================================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _lastAuthUser;

  Future<bool> _isTwoFactorRequired(User user) async {
    final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final enabled = profile.data()?['twoFactorEnabled'] as bool? ?? false;
    if (!enabled) return false;
    return !(await TwoFactorService.instance.isCurrentSessionVerified(user));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TwoFactorService.instance.authRefresh,
      builder: (_, __, ___) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!identical(_lastAuthUser, snap.data)) {
              _lastAuthUser = snap.data;
              if (kDebugMode) {
                debugPrint(
                  '[AuthGate] authStateChanges user=${snap.data?.uid ?? 'null'}',
                );
              }
            }
            if (!snap.hasData) {
              if (kDebugMode) {
                debugPrint('[AuthGate] routing -> SignInScreen (no user)');
              }
              return const SignInScreen();
            }
            final user = snap.data!;
            final isPasswordUser = user.providerData.any((info) => info.providerId == 'password');
            if (isPasswordUser && !user.emailVerified) {
              if (kDebugMode) {
                debugPrint('[AuthGate] routing -> SignInScreen (email not verified)');
              }
              unawaited(
                AuthSessionService.signOutFully(
                  beforeSignOut: () => SessionService.instance.revokeCurrentSession(user.uid),
                ),
              );
              return const SignInScreen();
            }
            if (!isPasswordUser) {
              if (kDebugMode) {
                debugPrint('[AuthGate] routing -> HomeShell (social provider)');
              }
              return const HomeShell();
            }
            return FutureBuilder<bool>(
              future: _isTwoFactorRequired(user),
              builder: (context, twoFactorSnap) {
                if (twoFactorSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (twoFactorSnap.data == true) {
                  if (kDebugMode) {
                    debugPrint('[AuthGate] routing -> TwoFactorOtpScreen');
                  }
                  return TwoFactorOtpScreen(email: user.email ?? '');
                }
                if (kDebugMode) {
                  debugPrint('[AuthGate] routing -> HomeShell (authenticated)');
                }
                return const HomeShell();
              },
            );
          },
        );
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final GoogleSignIn _googleSignIn = AuthSessionService.googleSignIn;
  bool loading = false;
  bool googleLoading = false;

  String _mapAuthError(FirebaseAuthException error) {
    final localizations = S.of(context);
    switch (error.code) {
      case 'invalid-email':
        return localizations.invalidEmailError;
      case 'user-disabled':
        return localizations.userDisabledError;
      case 'user-not-found':
        return localizations.userNotFoundError;
      case 'wrong-password':
        return localizations.wrongPasswordError;
      case 'email-already-in-use':
        return localizations.emailAlreadyInUseError;
      case 'weak-password':
        return localizations.weakPasswordError;
      case 'operation-not-allowed':
        return localizations.emailAuthDisabledError;
      case 'network-request-failed':
        return localizations.networkError;
      case 'too-many-requests':
        return localizations.tooManyRequestsError;
      default:
        return error.message ?? localizations.genericAuthError;
    }
  }

  void _showAuthSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapGoogleAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'تحقق من اتصال الإنترنت ثم أعد المحاولة.';
        case 'invalid-credential':
          return 'بيانات الاعتماد غير صالحة. تحقق من إعدادات تسجيل الدخول.';
        case 'user-disabled':
          return 'تم تعطيل الحساب.';
        default:
          return error.message ??
              'حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.';
      }
    }
    if (error is PlatformException) {
      final details = [
        error.message,
        error.details?.toString(),
      ].where((value) => value != null && value!.trim().isNotEmpty).join(' ');
      final detailsLower = details.toLowerCase();
      if (error.code == 'sign_in_canceled') {
        return 'تم إلغاء تسجيل الدخول عبر Google.';
      }
      if (error.code == 'network_error') {
        return 'تحقق من اتصال الإنترنت ثم أعد المحاولة.';
      }
      if (error.code == 'api_exception' ||
          detailsLower.contains('apiexception: 10') ||
          detailsLower.contains('apiexception:10') ||
          detailsLower.contains('12500')) {
        return 'تعذر إكمال تسجيل الدخول. تأكد من إعدادات Firebase/Google (SHA-1، الحزمة، OAuth) ثم أعد المحاولة.';
      }
      return 'حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.';
    }
    return 'حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.';
  }

  Future<void> _login() async {
    if (loading || googleLoading) {
      if (kDebugMode) {
        debugPrint('[Auth] email login ignored: another auth request is active');
      }
      return;
    }
    final trimmedEmail = email.text.trim();
    final trimmedPassword = password.text.trim();
    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      _showAuthSnack('الرجاء إدخال البريد الإلكتروني وكلمة المرور.');
      return;
    }
    if (!mounted) return;
    setState(() => loading = true);
    if (kDebugMode) {
      debugPrint('[Auth] email login started: $trimmedEmail');
    }
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      final user = credential.user;
      if (user != null) {
        final isPasswordUser =
            user.providerData.any((info) => info.providerId == 'password');
        if (isPasswordUser && !user.emailVerified) {
          await SessionService.instance.revokeCurrentSession(user.uid);
          await AuthSessionService.signOutFully();
          if (!mounted) return;
          await _showUnverifiedDialog(trimmedEmail, trimmedPassword);
          return;
        }
      }
      if (user != null) {
        if (kDebugMode) {
          debugPrint('[Auth] email login success uid=${user.uid}');
        }
        final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final twoFactorEnabled = profile.data()?['twoFactorEnabled'] as bool? ?? false;
        if (!twoFactorEnabled) {
          await SessionService.instance.initSession(user.uid);
        }
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Login failed: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Login failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack('حدث خطأ أثناء تسجيل الدخول.');
    } finally {
      if (kDebugMode) {
        debugPrint('[Auth] email login finished loading=false');
      }
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _showUnverifiedDialog(
    String email,
    String password,
  ) async {
    final localizations = S.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.verifyEmailTitle),
          content: Text(localizations.verifyEmailToContinue),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _resendVerificationEmail(email, password);
              },
              child: Text(localizations.resendVerificationEmail),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerifyEmailScreen(
                      email: email,
                      password: password,
                    ),
                  ),
                );
              },
              child: Text(localizations.checkNow),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendVerificationEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        _showAuthSnack(S.of(context).genericAuthError);
        return;
      }
      await user.sendEmailVerification();
      await SessionService.instance.revokeCurrentSession(user.uid);
      await AuthSessionService.signOutFully();
      _showAuthSnack(S.of(context).verificationEmailSent);
    } on FirebaseAuthException catch (e) {
      _showAuthSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Resend verification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(S.of(context).genericAuthError);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (googleLoading || loading) {
      if (kDebugMode) {
        debugPrint('[Auth] google login ignored: another auth request is active');
      }
      return;
    }
    if (!mounted) return;
    setState(() => googleLoading = true);
    if (kDebugMode) {
      debugPrint('[Auth] google login started');
    }
    try {
      // تأكد من إضافة SHA-1/SHA-256 في Firebase لكل من debug/release عند الحاجة.
      if (kDebugMode) {
        debugPrint('[Auth] google login before GoogleSignIn.signIn()');
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in canceled by user.');
        _showAuthSnack(
          _mapGoogleAuthError(
            PlatformException(code: 'sign_in_canceled'),
          ),
        );
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      if (kDebugMode) {
        debugPrint('[Auth] google login credential ready (idToken=${googleAuth.idToken != null})');
      }
      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;
      if (kDebugMode) {
        debugPrint('[Auth] google login FirebaseAuth.currentUser=${FirebaseAuth.instance.currentUser?.uid ?? 'null'}');
      }
      if (user != null) {
        if (kDebugMode) {
          debugPrint('[Auth] google login success uid=${user.uid}');
        }
        await SessionService.instance.initSession(user.uid);
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint(
        'Google sign-in failed (FirebaseAuthException): code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapGoogleAuthError(e));
    } on PlatformException catch (e, stackTrace) {
      debugPrint(
        'Google sign-in platform error: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack(_mapGoogleAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showAuthSnack('حدث خطأ أثناء تسجيل الدخول عبر Google. حاول مرة أخرى.');
    } finally {
      if (kDebugMode) {
        debugPrint('[Auth] google login finished loading=false');
      }
      if (mounted) setState(() => googleLoading = false);
    }
  }

  Future<void> _register() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpFlowScreen()),
    );
  }

  String _mapPasswordResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return S.of(context).invalidEmailError;
      case 'user-not-found':
        return S.of(context).userNotFoundError;
      case 'too-many-requests':
        return S.of(context).tooManyRequestsError;
      default:
        return S.of(context).resetLinkFailed;
    }
  }

  Future<void> _showForgotPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: email.text.trim(),
        onShowSnack: _showAuthSnack,
        mapPasswordResetError: _mapPasswordResetError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[700],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_rounded,
                    color: kUniSpaceBlue, size: 64),
                const SizedBox(height: 12),
                Text(S.of(context).welcomeUniSpace,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    labelText: S.of(context).email,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    labelText: S.of(context).password,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading || googleLoading
                        ? null
                        : _showForgotPasswordSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(S.of(context).forgotPassword),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilledButton.icon(
                        onPressed: loading || googleLoading ? null : _login,
                        icon: const Icon(Icons.login),
                        label: Text(S.of(context).login),
                      ),
                      OutlinedButton.icon(
                        onPressed: loading || googleLoading ? null : _register,
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(S.of(context).register),
                      ),
                    ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        loading || googleLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 3,
                      shadowColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (googleLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const FaIcon(
                              FontAwesomeIcons.google,
                              color: Color(0xFFDB4437),
                              size: 18,
                            ),
                          const SizedBox(width: 10),
                          const Text('تسجيل الدخول عبر Google'),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _PasswordResetErrorMapper = String Function(FirebaseAuthException error);

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.onShowSnack,
    required this.mapPasswordResetError,
  });

  final String initialEmail;
  final ValueChanged<String> onShowSnack;
  final _PasswordResetErrorMapper mapPasswordResetError;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _resetEmailController;
  late final FocusNode _resetFocusNode;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resetEmailController = TextEditingController(text: widget.initialEmail);
    _resetFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Dispose sheet-owned controllers/nodes to avoid dangling dependents when the sheet is swipe-dismissed.
    _resetEmailController.dispose();
    _resetFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final localizations = S.of(context);
    final trimmedEmail = _resetEmailController.text.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      widget.onShowSnack(localizations.invalidEmailValidation);
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmedEmail);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onShowSnack(localizations.resetLinkSentSuccess);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      widget.onShowSnack(widget.mapPasswordResetError(e));
    } catch (_) {
      if (!mounted) return;
      widget.onShowSnack(localizations.resetLinkFailed);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final localizations = S.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kUniSpaceBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: kUniSpaceBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.resetPasswordTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSending ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizations.resetPasswordHelper,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resetEmailController,
                focusNode: _resetFocusNode,
                enabled: !_isSending,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: localizations.email,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSending ? null : _sendResetEmail,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSending)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      if (_isSending) const SizedBox(width: 12),
                      Text(
                        _isSending
                            ? localizations.sendResetLinkLoading
                            : localizations.sendResetLink,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HomeShell — الشريط السفلي الجديد + سحب/انزلاق بين الصفحات
// ============================================================================


// ────────────────────────────── الشريط السفلي (الوحيد) ──────────────────────────────
class _BottomBar extends StatelessWidget {
  final int index;
  final void Function(int) onTap;
  final double hideProgress;

  const _BottomBar({
    super.key,
    required this.index,
    this.hideProgress = 0.0,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 20,
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      child: Opacity(                    // ← الأيقونات فقط تتلاشى
        opacity: 1 - hideProgress,
        child: Row(
          children: [
            Expanded(
              child: _BarItem(
                icon: Icons.home,
                selected: index == 0,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _BarItem(
                icon: Icons.public_outlined,
                selected: index == 1,
                onTap: () => onTap(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── _BarItem (أبيض/رمادي) ──────────────────────────────
class _BarItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BarItem({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color c = selected ? Colors.white : scheme.onSurfaceVariant.withValues(alpha: 0.3);

    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 1000,                    // ← لا تغيّره (مهم لمساحة النقر)
          width: 1000,
          child: Align(
            alignment: Alignment.topCenter,   // ← يرفع الأيقونة لأعلى
            child: Padding(
                // ← هنا التحكم
              child: Icon(icon, color: c, size: 25),
              padding: const EdgeInsets.only(bottom: 10),
            ),
        ),
      ),
    );
  }
}

// ============================================================================
// Home Landing — كروت كليات احترافية + دخول إلى Navigator الدراسة
// ============================================================================

class HomeLandingScreen extends StatefulWidget {
  const HomeLandingScreen({super.key});

  @override
  State<HomeLandingScreen> createState() => _HomeLandingScreenState();
}

class _HomeLandingScreenState extends State<HomeLandingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  Future<void> _openSearch(BuildContext context, String initialQuery) async {
    if (_isSearchOpen) {
      return;
    }
    _isSearchOpen = true;
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacultySearchPage(
          faculties: getDemoFaculties(context),
          initialQuery: initialQuery,
          onFacultySelected: _openFaculty,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _searchController.clear();
    _isSearchOpen = false;
  }

  void _openFaculty(BuildContext context, ProgramFaculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FacultyMajorsScreen(faculty: faculty)),
    );
  }

  void _openAcademicShortcut(BuildContext context, SettingsData settings) {
    final faculties = getDemoFaculties(context);
    final targetFaculty = settings.academicFacultyName.isNotEmpty
        ? settings.academicFacultyName
        : settings.academicFacultyId;
    final targetDepartment = settings.academicDepartmentName.isNotEmpty
        ? settings.academicDepartmentName
        : settings.academicDepartmentId;
    final targetSpecialty = settings.academicSpecialtyName.isNotEmpty
        ? settings.academicSpecialtyName
        : settings.academicSpecialtyId;
    final targetLevel = settings.academicLevel;

    ProgramFaculty? matchedFaculty;
    ProgramMajor? matchedMajor;
    ProgramTrack? matchedTrack;

    for (final faculty in faculties) {
      if (targetFaculty.isNotEmpty && faculty.name != targetFaculty) {
        continue;
      }
      matchedFaculty = faculty;
      for (final major in faculty.majors) {
        if (targetDepartment.isNotEmpty && major.name != targetDepartment) {
          continue;
        }
        matchedMajor = major;
        for (final track in major.tracks) {
          final matchesSpecialty = track.name == targetSpecialty ||
              (settings.academicSpecialtyId.isNotEmpty &&
                  track.name == settings.academicSpecialtyId);
          final matchesLevel =
              targetLevel.isEmpty || track.level == targetLevel;
          if (matchesSpecialty && matchesLevel) {
            matchedTrack = track;
            break;
          }
        }
        if (matchedTrack != null) {
          break;
        }
      }
      if (matchedTrack != null) {
        break;
      }
    }

    if (matchedTrack != null &&
        matchedMajor != null &&
        matchedFaculty != null) {
      final selectedFaculty = matchedFaculty;
      final selectedMajor = matchedMajor;
      final selectedTrack = matchedTrack;
      if (selectedFaculty == null ||
          selectedMajor == null ||
          selectedTrack == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      final specs = createSemesterSpecsForTrack(selectedTrack);
      final sem1 = _pickSemester(specs, 'S1');
      final sem2 = _pickSemester(specs, 'S2');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudiesTableScreen(
            facultyName: selectedFaculty.name,
            programName: '${selectedMajor.name} • ${selectedTrack.name}',
            collegeId: selectedFaculty.name,
            departmentId: selectedMajor.name,
            specialtyId: selectedTrack.name,
            level: selectedTrack.level,
            academicScopeId: buildAcademicStorageSignature(
              semester1: sem1,
              semester2: sem2,
              level: selectedTrack.level,
            ),
            semester1Modules: sem1,
            semester2Modules: sem2,
          ),
        ),
      );
      return;
    }

    if (matchedMajor != null && matchedFaculty != null) {
      final selectedMajor = matchedMajor;
      final selectedFaculty = matchedFaculty;
      if (selectedMajor == null || selectedFaculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MajorTracksScreen(
            major: selectedMajor,
            faculty: selectedFaculty,
          ),
        ),
      );
      return;
    }

    if (matchedFaculty != null) {
      final selectedFaculty = matchedFaculty;
      if (selectedFaculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AcademicSettingsScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacultyMajorsScreen(faculty: selectedFaculty),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).academicShortcutNotFound)),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AcademicSettingsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final faculties = getDemoFaculties(context).take(6).toList();

    final quickFaculty = faculties.isNotEmpty ? faculties.first : null;
    final gridFaculties = quickFaculty == null
        ? faculties
        : faculties.skip(1).toList(growable: false);

    return AppScaffold(
        // endDrawer:  AppEndDrawer(),
        appBar: AppBar(
          automaticallyImplyLeading: true,

          title: Row(
            children: [
              const SizedBox(width: 4),
              Align(
                  alignment: Alignment.center,
                  child: Text(
                    S.of(context).gpu,
                    style: TextStyle(

                      fontSize: 15,
                      fontWeight: FontWeight.w500,


                    ),
                  )),
            ],
          ),
        ),
        padding: EdgeInsets.zero,
        body:
        CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(1, 20, 10, 30),
              sliver: SliverToBoxAdapter(
                child: Container(

                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(4, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _openSearch(context, value);
                      }
                    },
                    onTap: () {
                      _openSearch(context, _searchController.text);
                    },
                    decoration: InputDecoration(
                      hintText: S.of(context).searchFaculty,
                      hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<SettingsData>(
                valueListenable: AppSettings.instance.notifier,
                builder: (context, settings, _) {
                  final theme = Theme.of(context);
                  final specialtyId =
                      settings.academicSpecialtyId.trim();
                  if (!settings.hasAcademicShortcut) {

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface
                                //.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).academicShortcutTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              S.of(context).academicShortcutEmptyTitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AcademicSettingsScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  S.of(context).academicShortcutEmptyAction,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final facultyName = (settings.academicFacultyName.isNotEmpty
                          ? settings.academicFacultyName
                          : settings.academicFacultyId)
                      .trim();
                  final specialtyName =
                      (settings.academicSpecialtyName.isNotEmpty
                              ? settings.academicSpecialtyName
                              : specialtyId)
                          .trim();
                  final displaySpecialty =
                      specialtyName.isNotEmpty ? specialtyName : '—';
                  final level = settings.academicLevel.trim();
                  final displayLevel = level.isNotEmpty ? level : '—';
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Dismissible(
                      key: ValueKey<String>(
                        'academic-shortcut-${settings.academicSpecialtyId}-${settings.academicLevel}',
                      ),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete,
                              color: theme.colorScheme.onError,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              S.of(context).academicShortcutDeleteTitle,
                              style:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: Text(
                                    S.of(dialogContext)
                                        .academicShortcutDeleteConfirmTitle,
                                  ),
                                  content: Text(
                                    S.of(dialogContext)
                                        .academicShortcutDeleteConfirmBody,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        S.of(dialogContext)
                                            .academicShortcutDeleteCancel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        S.of(dialogContext)
                                            .academicShortcutDeleteConfirm,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        await AppSettings.instance.clearAcademicShortcut();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              S.of(context)
                                  .academicShortcutDeleteSuccess,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).academicShortcutTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (facultyName.isNotEmpty)
                              Text(
                                facultyName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              S.of(context).academicShortcutDetails(
                                displaySpecialty,
                                displayLevel,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AcademicSettingsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    S.of(context).academicShortcutEdit,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _openAcademicShortcut(
                                    context,
                                    settings,
                                  ),
                                  child: Text(
                                    S.of(context).academicShortcutGo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (quickFaculty != null) ...[

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverToBoxAdapter(child:
                       Container(
                         decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),

                             border: Border.all(color:Theme.of(context).colorScheme.onSurface
                             )),
                          child: TextButton(onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuickAverageScreen(),
                              ),
                            );
                          },
                              child: Text(S.of(context).quickCalc2)),
                        )

                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final faculty = getDemoFaculties(context)[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: _FacultyQuickCard(
                          faculty: faculty,
                          onTap: () => _openFaculty(context, faculty),
                        ),
                      );
                    },
                    childCount: getDemoFaculties(context).length,
                  ),
                ),
              ),
            ],
          ],
        ));
  }
}

class _FacultyQuickCard extends StatelessWidget {
  const _FacultyQuickCard({required this.faculty, required this.onTap});

  final ProgramFaculty faculty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final majorsCount = faculty.majors.length;
    final tracksCount =
        faculty.majors.fold<int>(0, (sum, major) => sum + major.tracks.length);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: .2),
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.apartment_outlined),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      faculty.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: S.of(context).sections,
                      value: majorsCount.toString(),
                      icon: Icons.auto_awesome,
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      label: S.of(context).majors,
                      value: tracksCount.toString(),
                      icon: Icons.track_changes,
                      onTap: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ============================================================================
// Notes — واجهة ملاحظات احترافية (إنشاء/بحث/تثبيت/أرشفة)
// ============================================================================
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class SavedNote {
  final String subject;
  final double td;
  final double tp;
  final double exam;
  final double moy;
  final double coef;
  final double cred;

  SavedNote({
    required this.subject,
    required this.td,
    required this.tp,
    required this.exam,
    required this.moy,
    required this.coef,
    required this.cred,
  });
}

class NotesStorage {
  static List<SavedNote> savedNotes = [];
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  final _notes = <_NoteModel>[
    _NoteModel('خطة مذاكرة S1', 'رياضيات، فيزياء، برمجة...', pinned: true),
  ];
  final _archived = <_NoteModel>[];

  void _create() async {
    final res = await showModalBottomSheet<_NoteModel>(
      isScrollControlled: true,
      context: context,
      builder: (_) => const _NoteEditor(),
    );
    if (res != null) setState(() => _notes.insert(0, res));
  }

  void _edit(_NoteModel m) async {
    final res = await showModalBottomSheet<_NoteModel>(
      isScrollControlled: true,
      context: context,
      builder: (_) => _NoteEditor(initial: m),
    );
    if (res != null) {
      setState(() {
        final i = _notes.indexOf(m);
        if (i != -1) _notes[i] = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final pinned =
        _notes.where((e) => e.pinned && (q.isEmpty || e.match(q))).toList();
    final others =
        _notes.where((e) => !e.pinned && (q.isEmpty || e.match(q))).toList();
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.ltr,
          //mainAxisSize: MainAxisSize.min,
          children: [
            Row(textDirection: TextDirection.ltr, children: [
              // IconButton(
              //   icon: const Icon(Icons.menu),
              //   onPressed: () {
              //     Scaffold.of(context).openEndDrawer(); // لأنك تستخدم endDrawer
              //   },
              // ),
              Text(
                'NotePade',
                style: GoogleFonts.pacifico(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
            IconButton(
                onPressed: _create, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        //   Text('NotePade',
        //   style: GoogleFonts.pacifico(textStyle: Theme.of(context).textTheme.displayLarge,
        //   fontSize: 30,
        //   fontWeight: FontWeight.w500,
        //   fontStyle: FontStyle.italic,
        //   //color: Colors.teal[900],
        // ),),
        //leading: _DrawerLeading(showBack: canPop),
        //leadingWidth: canPop ? 96 : null,
        // actions: [
        //   IconButton(onPressed: _create, icon: const Icon(Icons.add_circle_outline)),
        // ],
      ),
      // endDrawer: const AppEndDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: S.of(context).searchClipboard,
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          if (pinned.isNotEmpty) ...[
            Text(S.of(context).pinned,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...pinned.map((n) => _NoteTile(
                  note: n,
                  onTap: () => _edit(n),
                  onPin: () => setState(() => n.pinned = !n.pinned),
                  onArchive: () => setState(() {
                    _notes.remove(n);
                    _archived.add(n);
                  }),
                )),
            const SizedBox(height: 10),
          ],
          if (others.isNotEmpty) ...[
            Text(S.of(context).otherNotes,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...others.map((n) => _NoteTile(
                  note: n,
                  onTap: () => _edit(n),
                  onPin: () => setState(() => n.pinned = !n.pinned),
                  onArchive: () => setState(() {
                    _notes.remove(n);
                    _archived.add(n);
                  }),
                )),
          ] else if (pinned.isEmpty)
            EmptyState(
                icon: Icons.note_alt_outlined, title: S.of(context).noNotesYet),
          const SizedBox(height: 12),
          if (_archived.isNotEmpty) ...[
            const Divider(),
            Text(S.of(context).archive,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ..._archived.map((n) => _NoteTile(
                  note: n,
                  archived: true,
                  onTap: () {},
                  onPin: null,
                  onArchive: () => setState(() {
                    _archived.remove(n);
                    _notes.add(n);
                  }),
                )),
          ],
        ],
      ),
    );
  }
}

class _NoteModel {
  String title;
  String body;
  bool pinned;
  _NoteModel(this.title, this.body, {this.pinned = false});
  bool match(String q) =>
      title.toLowerCase().contains(q) || body.toLowerCase().contains(q);
}

class _NoteTile extends StatelessWidget {
  final _NoteModel note;
  final bool archived;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  const _NoteTile(
      {required this.note,
      this.archived = false,
      this.onTap,
      this.onPin,
      this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kNoteYellow.withValues(alpha:
          Theme.of(context).brightness == Brightness.dark ? .12 : .35),
      child: ListTile(
        title: Text(note.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: onTap,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (onPin != null)
            IconButton(
                onPressed: onPin,
                icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined)),
          if (onArchive != null)
            IconButton(
                onPressed: onArchive,
                icon:
                    Icon(archived ? Icons.unarchive : Icons.archive_outlined)),
        ]),
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final _NoteModel? initial;
  const _NoteEditor({this.initial});
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _t;
  late final TextEditingController _b;
  bool _pin = false;

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.initial?.title ?? '');
    _b = TextEditingController(text: widget.initial?.body ?? '');
    _pin = widget.initial?.pinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).note,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _t,
                decoration: InputDecoration(labelText: S.of(context).title),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _b,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(labelText: S.of(context).content),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _pin,
                onChanged: (v) => setState(() => _pin = v ?? false),
                title: Text(S.of(context).pinNote),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  if (_t.text.trim().isEmpty && _b.text.trim().isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  Navigator.pop(context,
                      _NoteModel(_t.text.trim(), _b.text.trim(), pinned: _pin));
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(S.of(context).save),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Notes — واجهة الجامعة احترافية (إنشاء/بحث/تثبيت/أرشفة)
// ============================================================================

class UnispaceScreen extends StatefulWidget {
  const UnispaceScreen({super.key});

  @override
  State<UnispaceScreen> createState() => _UnispaceScreenState();
}

class _UnispaceScreenState extends State<UnispaceScreen> {
  final List<_Post> _posts = [
    _Post(
      author: 'CREATOR',
      title: 'Coming soon',
      body: 'A communication platform for only and all university students\n'
          '\n'
          'BE READY FOR IT🔥',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      votes: 100000000,
      tags: const [
        'communications',
        'students',
        'universities',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Concept of the app',
      body: 'An app for calculating university GPAs for students\n'
          '\nلا تتردد في مراسلتنا في حالة كانت لديك مطالب او اراء في ما يتعلق بالتطبيق '
          '\n'
          '\n'
          'contact us on IG: @klause_ds\n',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      votes: 100000000,
      tags: const [
        'Concept',
        'students',
        'GPA',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Directions to use',
      body:
      'بسبب اختلافات تقييم المواد من جامعة لاخرى ومن سنة دراسية لاخرى قد يجد بعض مستخدمينا اختلافات عن طريقتم في التقييم لدلك فيمكنكم تعديل اعدادات تقييم المواد ودالك من خلال علامة التعجب كما هو موضح في الصورة  \n'
          ':حيث \n'
          ' W.TD: معامل نقطة الاعمال الموجهة\n'
          'W.EXAM: معامل نقطة الاختبار\n'
          'W.TP: معامل نقطة الاعمال التطبيقية\n',
      imagePaths: [
        'assets/images/5917864502214986758.jpg',
        'assets/images/5917864502214986759.jpg',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      votes: 0,
      tags: const [
        'directions',
        'app',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Directions to use',
      body:
      'في حالة تسائلكم عن مكان تواجد نسب المواد فيمكنكم الاطلاع عليها من خلال تطبيق بروغرس كما هو موضح في الصور\n'
          'ففي حالة عدم وجود معلومات تخصصكم داخل التطبيق يمكنكم حساب المعدل من خلال خاصية الحساب السريع في القائمة او ارسال المعلومات الينا مباشرة ',
      imagePaths: [
        'assets/images/progress2.jpeg',
        'assets/images/progress.jpeg',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      votes: 0,
      tags: const [
        'directions',
        'app',
      ],
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   titleSpacing: 0,
      //   title: Row(
      //     textDirection: TextDirection.ltr,
      //     children: [
      //       IconButton(
      //         icon: const Icon(Icons.menu),
      //         onPressed: () {
      //           Scaffold.of(context).openEndDrawer();
      //         },
      //       ),
      //       const SizedBox(width: 4),
      //       Text(
      //         'Community',
      //         style: GoogleFonts.pacifico(
      //           textStyle: Theme.of(context).textTheme.displayLarge,
      //           fontSize: 30,
      //           fontWeight: FontWeight.w500,
      //           fontStyle: FontStyle.italic,
      //         ),
      //       ),
      //       const Spacer(),
      //       IconButton(
      //         icon: const Icon(Icons.add_circle_outline),
      //         onPressed:_newPost,
      //       ),
      //       IconButton(
      //           icon: const Icon(Icons.search),
      //           onPressed: () {
      //             // وظيفة البحث
      //           }),
      //       IconButton(
      //         icon: const Icon(Icons.account_circle),
      //         onPressed:
      //             () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (_) => const ProfileScreen(),
      //             ),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      padding: EdgeInsets.zero,
      body:  ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 120),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _PostCard(
          post: _posts[i],
          onVote: (delta) => setState(() => _posts[i].votes += delta),
          onComment: () async {
            final txt = await showDialog<String>(
              context: context,
              builder: (_) => const _CommentDialog(),
            );
            if (txt != null && txt.trim().isNotEmpty) {
              setState(() => _posts[i].comments.insert(
                0,
                _Comment(
                  id: UniqueKey().toString(),
                  author: 'you',
                  text: txt,
                  createdAt: DateTime.now(),
                ),
              ));
            }
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Notes — واجهة المحيط احترافية (إنشاء/بحث/تثبيت/أرشفة)
// ============================================================================

// ============================================================================
// عنصر EmptyHint (لازم لرسائل الفراغ)
// ============================================================================

// ============================================================================
// PART 2/3 — Community (Reddit-like) + Studies Navigator + Table Calculator
// ============================================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _current = 0;
  late final PageController _page;
  late final AnimationController _bottomBarController;
  final GlobalKey<_CommunityScreenState> _communityKey = GlobalKey<_CommunityScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = PageController(initialPage: 0);

    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initializeCurrentSession();
  }

  // ───── باقي الدوال (لا تغيرها) ─────
  Future<void> _initializeCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await SessionService.instance.initSession(user.uid);
  }

  Future<void> _touchCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final revoked = await SessionService.instance.isCurrentSessionRevoked(user.uid);
    if (revoked) {
      if (kDebugMode) debugPrint('[Auth] session revoked -> signOut');
      await AuthSessionService.signOutFully();
      return;
    }
    await SessionService.instance.updateLastSeen(user.uid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _touchCurrentSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _page.dispose();
    _bottomBarController.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _current = i);
    _page.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeInOut);
  }
  void _openEndDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              child: const AppEndDrawer(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }
  void _newPost() async {
    final result = await showModalBottomSheet<List<PostItem>>(
      isScrollControlled: true,
      context: context,
      builder: (_) => const _CreatePostSheet(),
    );

    if (result == null || result.isEmpty) return;

    String title = '';
    String body = '';
    final List<String> videoPaths = [];
    List<PollData> pollDataList = [];
    final List<Uint8List> imageBytesList = [];
    final List<String> directImagePaths = [];

    for (final item in result) {
      switch (item.type) {
        case PostItemType.text:
          if (title.isEmpty) {
            title = item.title;
          } else {
            body = item.title;
          }
          break;
        case PostItemType.image:
          if (item.imageBytes != null) {
            imageBytesList.add(item.imageBytes!);
          } else if (item.mediaPath != null) {
            directImagePaths.add(item.mediaPath!);
          }
          break;
        case PostItemType.video:
          if (item.mediaPath != null) videoPaths.add(item.mediaPath!);
          break;
        case PostItemType.poll:
          pollDataList = item.pollDataList ?? [];
          break;
      }
    }

    final List<String> finalImagePaths = List.from(directImagePaths);
    if (imageBytesList.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      for (int i = 0; i < imageBytesList.length; i++) {
        final file = File(
          '${tempDir.path}/post_${DateTime.now().millisecondsSinceEpoch}_$i.png',
        );
        await file.writeAsBytes(imageBytesList[i]);
        finalImagePaths.add(file.path);
      }
    }

    final newPost = _Post(
      author: 'current_user',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      imagePaths: finalImagePaths,
      videoPaths: videoPaths,
      pollDataList: pollDataList,
      tags: const [],
    );

    // ✅ هذا هو الحل — أضف مباشرة لـ CommunityScreen عبر GlobalKey
    _communityKey.currentState?.addPost(newPost);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).post)),
      );
    }
  }

  Widget _buildAppBarForCurrentPage() {
    return Builder(          // ← هذا الـ Builder هو الحل السحري
      builder: (context) {
        switch (_current) {
          case 0: // Home
            return AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                textDirection: TextDirection.ltr,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),

                    onPressed: _openEndDrawer,   // ← استدعاء دالة داخل HomeShell
                  ),
                  const SizedBox(width: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'UniSpace',
                      style: GoogleFonts.pacifico(
                        textStyle: Theme.of(context).textTheme.displayLarge,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Colors.teal[500],
                      ),
                    ),
                  ),
                ],
              ),
            );

          case 1: // ← CommunityScreen (غيّر حسب ما تريد)
            return  AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                textDirection: TextDirection.ltr,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),

                    onPressed: _openEndDrawer,   // ← استدعاء دالة داخل HomeShell
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Community',
                    style: GoogleFonts.pacifico(
                      textStyle: Theme.of(context).textTheme.displayLarge,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),

                    onPressed:_newPost,
                  ),
                  IconButton(
                      icon: const Icon(Icons.search),

                      onPressed: () {
                        // وظيفة البحث
                      }),
                  IconButton(
                    icon: const Icon(Icons.account_circle),

                    onPressed:
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );

          default: // Notes أو أي صفحة أخرى
            return AppBar(
              automaticallyImplyLeading: false,
              title: const Text('الملاحظات'),
              centerTitle: true,
            );
        }
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //endDrawer: const AppEndDrawer(),
      body: Stack(
        children: [
          // كشف التمرير
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                _bottomBarController.forward();
              } else if (notification.direction == ScrollDirection.forward) {
                _bottomBarController.reverse();
              }
              return false;
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 68),
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _current = i),
                children: [
                  //HomeLandingScreen(),
                  UnispaceScreen(),
                  CommunityScreen(key: _communityKey),

                  //NotesScreen(),
                ],
              ),
            ),
          ),

          // الشريط العلوي المتحرك (ديناميكي حسب الصفحة)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bottomBarController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -80 * _bottomBarController.value),
                child: Opacity(
                  opacity: 1 - _bottomBarController.value,
                  child: child!,
                ),
              ),
              child: _buildAppBarForCurrentPage(),
            ),
          ),

          // الشريط السفلي (كما هو)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bottomBarController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, 80 * _bottomBarController.value),
                child: Opacity(
                  opacity: 1 - _bottomBarController.value,
                  child: child!,
                ),
              ),
              child: _BottomBar(
                index: _current,
                onTap: _go,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= Community (Reddit-like) ===========================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<_Post> _posts = [
    _Post(
      author: 'CREATOR',
      title: 'Coming soon',
      body: 'A communication platform for only and all university students\n'
          '\n'
          'BE READY FOR IT🔥',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      votes: 100000000,
      tags: const [
        'communications',
        'students',
        'universities',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Concept of the app',
      body: 'An app for calculating university GPAs for students\n'
          '\nلا تتردد في مراسلتنا في حالة كانت لديك مطالب او اراء في ما يتعلق بالتطبيق '
          '\n'
          '\n'
          'contact us on IG: @klause_ds\n',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      votes: 100000000,
      tags: const [
        'Concept',
        'students',
        'GPA',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Directions to use',
      body:
          'بسبب اختلافات تقييم المواد من جامعة لاخرى ومن سنة دراسية لاخرى قد يجد بعض مستخدمينا اختلافات عن طريقتم في التقييم لدلك فيمكنكم تعديل اعدادات تقييم المواد ودالك من خلال علامة التعجب كما هو موضح في الصورة  \n'
          ':حيث \n'
          ' W.TD: معامل نقطة الاعمال الموجهة\n'
          'W.EXAM: معامل نقطة الاختبار\n'
          'W.TP: معامل نقطة الاعمال التطبيقية\n',
      imagePaths: [
        'assets/images/5917864502214986758.jpg',
        'assets/images/5917864502214986759.jpg',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      votes: 0,
      tags: const [
        'directions',
        'app',
      ],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Directions to use',
      body:
      'في حالة تسائلكم عن مكان تواجد نسب المواد فيمكنكم الاطلاع عليها من خلال تطبيق بروغرس كما هو موضح في الصور\n'
          'ففي حالة عدم وجود معلومات تخصصكم داخل التطبيق يمكنكم حساب المعدل من خلال خاصية الحساب السريع في القائمة او ارسال المعلومات الينا مباشرة ',
      imagePaths: [
        'assets/images/progress2.jpeg',
        'assets/images/progress.jpeg',
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      votes: 0,
      tags: const [
        'directions',
        'app',
      ],
    ),
  ];

  void _newPost() async {
    final result = await showModalBottomSheet<List<PostItem>>(
      isScrollControlled: true,
      context: context,
      builder: (_) => const _CreatePostSheet(),
    );

    if (result == null || result.isEmpty) return;

    // ✅ جمع البيانات أولاً بدون await
    String title = '';
    String body = '';
    final List<String> imagePaths = [];
    final List<String> videoPaths = [];
    List<PollData> pollDataList = [];
    final List<PostItem> pollBlocks = [];

    // ✅ افصل الـ imageBytes items عن الباقي
    final List<MapEntry<int, Uint8List>> imageByteItems = [];

    for (int idx = 0; idx < result.length; idx++) {
      final item = result[idx];
      switch (item.type) {
        case PostItemType.text:
          if (title.isEmpty) {
            title = item.title;
          } else {
            pollBlocks.add(item); // ✅ النصوص الإضافية → pollBlocks
          }
          break;
        case PostItemType.image:
          if (item.mediaPath != null) {
            pollBlocks.add(item); // ✅ صور PollBuilder → pollBlocks
          } else if (item.imageBytes != null) {
            imageByteItems.add(MapEntry(idx, item.imageBytes!));
          }
          break;
        case PostItemType.video:
          if (item.mediaPath != null) {
            pollBlocks.add(item); // ✅ فيديوهات PollBuilder → pollBlocks
          }
          break;
        case PostItemType.poll:
          pollDataList = item.pollDataList ?? [];
          break;
      }
    }

    // ✅ اكتب ملفات الصور إذا وجدت bytes
    if (imageByteItems.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      for (final entry in imageByteItems) {
        final file = File(
          '${tempDir.path}/post_${DateTime.now().millisecondsSinceEpoch}_${entry.key}.png',
        );
        await file.writeAsBytes(entry.value);
        imagePaths.add(file.path);
      }
    }

    // ✅ setState مباشرة بدون فحص mounted — نحن في نفس الـ State
    setState(() {
      _posts.insert(
        0,
        _Post(
          author: 'current_user',
          title: title,
          body: body,
          createdAt: DateTime.now(),
          imagePaths: List.from(imagePaths),
          videoPaths: List.from(videoPaths),
          pollDataList: List.from(pollDataList),
          //pollBlocks: pollBlocks,
          tags: const [],
        ),
      );
    });

    debugPrint('Post added: title=$title, images=${imagePaths.length}, videos=${videoPaths.length}, polls=${pollDataList.length}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).post)),
      );
    }
  }
  void addPost(_Post post) {
    setState(() {
      _posts.insert(0, post);
    });
  }
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   titleSpacing: 0,
      //   title: Row(
      //     textDirection: TextDirection.ltr,
      //     children: [
      //       IconButton(
      //         icon: const Icon(Icons.menu),
      //         onPressed: () {
      //           Scaffold.of(context).openEndDrawer();
      //         },
      //       ),
      //       const SizedBox(width: 4),
      //       Text(
      //         'Community',
      //         style: GoogleFonts.pacifico(
      //           textStyle: Theme.of(context).textTheme.displayLarge,
      //           fontSize: 30,
      //           fontWeight: FontWeight.w500,
      //           fontStyle: FontStyle.italic,
      //         ),
      //       ),
      //       const Spacer(),
      //       IconButton(
      //         icon: const Icon(Icons.add_circle_outline),
      //         onPressed:_newPost,
      //       ),
      //       IconButton(
      //           icon: const Icon(Icons.search),
      //           onPressed: () {
      //             // وظيفة البحث
      //           }),
      //       IconButton(
      //         icon: const Icon(Icons.account_circle),
      //         onPressed:
      //             () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder: (_) => const ProfileScreen(),
      //             ),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
      padding: EdgeInsets.zero,
      body: _posts.isEmpty
          ? EmptyState(
              icon: Icons.public_outlined,
              title: S.of(context).noPostsYet,
              subtitle: S.of(context).startDiscussion,
              action: PrimaryButton(
                label: S.of(context).createPoste,
                icon: Icons.add,
                onPressed: _newPost,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 120),
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _PostCard(
                post: _posts[i],
                onVote: (delta) => setState(() => _posts[i].votes += delta),
                onComment: () async {
                  final txt = await showDialog<String>(
                    context: context,
                    builder: (_) => const _CommentDialog(),
                  );
                  if (txt != null && txt.trim().isNotEmpty) {
                    setState(() => _posts[i].comments.insert(
                          0,
                          _Comment(
                            id: UniqueKey().toString(),
                            author: 'you',
                            text: txt,
                            createdAt: DateTime.now(),
                          ),
                        ));
                  }
                },
              ),
            ),
    );
  }
}

//=========================================================
class _Post {
  final String author;
  final String title;
  final String body;
  final DateTime createdAt;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final List<PollData> pollDataList;
  //final List<PostItem> pollBlocks; // بلوكات PollBuilder
  final List<String> tags;
  final String? mediaUrl;
  int votes;
  bool upvoted;
  bool downvoted;
  final List<_Comment> comments;

  _Post({
    required this.author,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.pollDataList = const [],
    //this.pollBlocks = const [],
    this.tags = const [],
    this.mediaUrl,
    this.votes = 0,
    this.upvoted = false,
    this.downvoted = false,
    List<_Comment>? comments,

  }) : comments = comments ?? [];

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo';
    return '${(difference.inDays / 365).floor()}y';
  }
}

// ==================== PostCard ====================
// ==================== PostCard ====================
class _PostCard extends StatefulWidget {
  final _Post post;
  final void Function(int delta) onVote;
  final VoidCallback onComment;

  const _PostCard({
    super.key,
    required this.post,
    required this.onVote,
    required this.onComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isNavigating = false;
  Timer? _updateTimer;


  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _openComments() async {
    if (_isNavigating) return;
    _isNavigating = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsScreen(post: widget.post)),
    );
    _isNavigating = false;
  }

  // ===== دوال بناء الشرائح =====
  Widget _buildImageSlide(String path) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullscreenImageViewer(
            images: [path],
            initialIndex: 0,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: path.startsWith('assets/')
            ? Image.asset(
          path,
          fit: BoxFit.cover,
          width: double.infinity,
        )
            : Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSlide(String path) {
    return _VideoSlideWidget(videoPath: path);
  }

  Widget _buildPollSlide(PollData poll) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        height: 200,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: PollPostWidget(polls: [poll]),
        ),
      ),
    );
  }

  Widget _buildTextSlide(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Directionality(
        textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(text)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
            textAlign: RegExp(r'[\u0600-\u06FF]').hasMatch(text)
                ? TextAlign.right
                : TextAlign.left,
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetItem(
      BuildContext context, {
        required IconData icon,
        required String text,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 14),
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _postMediaWidget(String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final isImage = url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 190,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image)),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: GestureDetector(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String formatVotes(int votes) {
    if (votes >= 1000000) return '${(votes / 1000000).toStringAsFixed(1)}M';
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}k';
    return votes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openComments,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Header =====
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor:
                        theme.colorScheme.onPrimary.withValues(alpha: .5),
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'u/${post.author}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              post.timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return DraggableScrollableSheet(
                                initialChildSize: 0.5,
                                minChildSize: 0.5,
                                maxChildSize: 0.85,
                                builder: (context, scrollController) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                      borderRadius:
                                      const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                            BorderRadius.circular(10),
                                          ),
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/repost.png',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/instagram.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/link.png',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/whatsapp.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/Facebook_f_logo_(2019).svg.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/messenger.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/Logo_of_Twitter.svg.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/discord.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/email.png',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () => Share.share(
                                                    'Check out this post: ${post.title}'),
                                                child: Image.asset(
                                                  'assets/icons/more.png',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView(
                                            controller: scrollController,
                                            padding:
                                            const EdgeInsets.all(12),
                                            children: [
                                              const SizedBox(height: 5),
                                              _bottomSheetItem(context,
                                                  icon:
                                                  Icons.bookmark_border,
                                                  text: S
                                                      .of(context)
                                                      .savePost),
                                              _bottomSheetItem(context,
                                                  icon: Icons
                                                      .report_gmailerrorred,
                                                  text: S
                                                      .of(context)
                                                      .blockAccount),
                                              _bottomSheetItem(context,
                                                  icon:
                                                  Icons.flag_outlined,
                                                  text: S
                                                      .of(context)
                                                      .report),
                                              _bottomSheetItem(context,
                                                  icon: Icons
                                                      .visibility_off_outlined,
                                                  text:
                                                  S.of(context).hide),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ===== العنوان =====
                if (post.title.trim().isNotEmpty)
                  Directionality(
                    textDirection:
                    RegExp(r'[\u0600-\u06FF]').hasMatch(post.title)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        post.title,
                        style: theme.textTheme.titleMedium,
                        textAlign:
                        RegExp(r'[\u0600-\u06FF]').hasMatch(post.title)
                            ? TextAlign.right
                            : TextAlign.left,
                      ),
                    ),
                  ),

                // ===== الجسم =====
                if (post.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: post.body,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                  ),
                ],

                const SizedBox(height: 8),

                // ===== Media URL =====
                _postMediaWidget(post.mediaUrl),

                // ✅ ===== المحتوى الوسائطي — كل شيء في carousel واحد =====
                Builder(builder: (context) {
                  final List<Widget> slides = [];

                  for (final path in post.imagePaths) {
                    slides.add(_buildImageSlide(path));
                  }

                  for (final path in post.videoPaths) {
                    slides.add(_buildVideoSlide(path));
                  }


                  for (final poll in post.pollDataList) {
                    switch (poll.type) {
                      case PollQuestionType.textBlock:
                        slides.add(_buildTextSlide(poll.blockText ?? ''));
                        break;
                      case PollQuestionType.imageBlock:
                        if (poll.blockMediaPath != null) {
                          slides.add(_buildImageSlide(poll.blockMediaPath!));
                        }
                        break;
                      case PollQuestionType.videoBlock:
                        if (poll.blockMediaPath != null) {
                          slides.add(_buildVideoSlide(poll.blockMediaPath!));
                        }
                        break;
                      default:
                        slides.add(_buildPollSlide(poll));
                        break;
                    }
                  }

                  if (slides.isEmpty) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const SizedBox(height: 4),
                      GestureDetector(
                        // ✅ يمنع النقر من فتح التعليقات عند التفاعل مع الوسائط
                        onTap: () {},
                        child: _MediaCarousel(slides: slides),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                // ===== أزرار التفاعل =====
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.grey, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    splashColor:
                                    Colors.teal.withValues(alpha: 0.3),
                                    highlightColor:
                                    Colors.teal.withValues(alpha: 0.15),
                                    onTap: () {
                                      setState(() {
                                        if (post.upvoted) {
                                          post.upvoted = false;
                                          post.votes--;
                                        } else {
                                          post.upvoted = true;
                                          if (post.downvoted) {
                                            post.downvoted = false;
                                            post.votes++;
                                          }
                                          post.votes++;
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: Icon(
                                        Icons.arrow_upward_outlined,
                                        size: 20,
                                        color: post.upvoted
                                            ? Colors.teal[700]
                                            : theme
                                            .colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration:
                                  const Duration(milliseconds: 180),
                                  transitionBuilder: (child,
                                      animation) =>
                                      ScaleTransition(
                                          scale: animation, child: child),
                                  child: Text(
                                    formatVotes(post.votes),
                                    key: ValueKey(
                                        '${post.votes}-${post.upvoted}-${post.downvoted}'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: post.upvoted
                                          ? Colors.teal[600]
                                          : post.downvoted
                                          ? Colors.red
                                          : theme
                                          .colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    splashColor:
                                    Colors.red.withValues(alpha: 0.3),
                                    highlightColor:
                                    Colors.red.withValues(alpha: 0.15),
                                    onTap: () {
                                      setState(() {
                                        if (post.downvoted) {
                                          post.downvoted = false;
                                          post.votes++;
                                        } else {
                                          post.downvoted = true;
                                          if (post.upvoted) {
                                            post.upvoted = false;
                                            post.votes--;
                                          }
                                          post.votes--;
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      child: Icon(
                                        Icons.arrow_downward_outlined,
                                        size: 20,
                                        color: post.downvoted
                                            ? Colors.red
                                            : theme
                                            .colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.grey, width: 1),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _openComments,
                                  icon: Icon(
                                    Icons.chat_bubble_outline_outlined,
                                    color: theme.colorScheme.onSurface,
                                    size: 18,
                                  ),
                                ),
                                Text(
                                  '${post.comments.length}',
                                  key: ValueKey(post.comments.length),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.transparent,
                            transitionDuration:
                            const Duration(milliseconds: 300),
                            pageBuilder: (context, anim1, anim2) {
                              return Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.95,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                      theme.colorScheme.surface,
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme
                                              .colorScheme.onSurface
                                              .withValues(alpha: 0.2),
                                          offset: const Offset(0, 10),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: post.tags
                                          .map((tag) => Chip(
                                        label: Text('c/$tag'),
                                        backgroundColor:
                                        Colors.transparent,
                                      ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.grey, width: 1),
                          ),
                          child: const Text('Tags #'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MediaCarousel ====================
class _MediaCarousel extends StatefulWidget {
  final List<Widget> slides;
  const _MediaCarousel({required this.slides});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  int _current = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: widget.slides[i],
            ),
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? Colors.teal[900]
                      : Colors.teal.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ==================== VideoSlideWidget ====================
class _VideoSlideWidget extends StatefulWidget {
  final String videoPath;
  const _VideoSlideWidget({required this.videoPath});

  @override
  State<_VideoSlideWidget> createState() => _VideoSlideWidgetState();
}

class _VideoSlideWidgetState extends State<_VideoSlideWidget> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true);
    _ctrl.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _ctrl.value.size.width,
                  height: _ctrl.value.size.height,
                  child: VideoPlayer(_ctrl),
                ),
              )
            else
              const CircularProgressIndicator(color: Colors.white),

            // زر fullscreen
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullscreenVideoViewer(controller: _ctrl),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.fullscreen,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            // زر تشغيل / إيقاف
            GestureDetector(
              onTap: () => setState(() {
                _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
              }),
              child: AnimatedOpacity(
                opacity: !_ctrl.value.isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 30),
                ),
              ),
            ),

            // شريط التقدم
            if (_ready)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _ctrl,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.teal,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//==============================================================
enum PostItemType { text, image, video, poll }

class PostItem {
  final PostItemType type;
  final String title;
  final String? mediaPath;
  final Uint8List? imageBytes;          // ✅ جديد
  final List<String>? pollOptions;
  final List<PollData>? pollDataList;

  PostItem({
    required this.type,
    required this.title,
    this.mediaPath,
    this.imageBytes,                    // ✅
    this.pollOptions,
    this.pollDataList,
  });
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({super.key});

  @override
  State<_CreatePostSheet> createState() => __CreatePostSheetState();
}

class __CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  int _currentImageIndex = 0;

  List<String> _tags = [];
  List<PostItem> _pollItems = [];
  List<PostBlock> _blocks = [];
  List<PollData> _pollDataList = [];

  PollData? _poll;
  int currentPage = 0;
  int get totalPages => _blocks.length + (_pollDataList.isNotEmpty ? 1 : 0);
  final List<String> _suggestedTags = [];
  List<File> _pickedVideos = [];
  int _currentVideoIndex = 0;
  List<VideoPlayerController> _videoControllers = [];
  List<Uint8List> _pickedImages = [];

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    if (!_tags.contains(tag.trim())) {
      setState(() => _tags.add(tag.trim()));
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _submitPost() {
    // ✅ لا async هنا — كل شيء synchronous
    final List<PostItem> items = [];

    // Poll
    if (_pollDataList.isNotEmpty) {
      items.add(PostItem(
        type: PostItemType.poll,
        title: '',
        pollDataList: _pollDataList,
      ));
    }

    // النصوص
    if (_titleController.text.trim().isNotEmpty) {
      items.add(PostItem(
        type: PostItemType.text,
        title: _titleController.text.trim(),
      ));
    }
    if (_bodyController.text.trim().isNotEmpty) {
      items.add(PostItem(
        type: PostItemType.text,
        title: _bodyController.text.trim(),
      ));
    }

    // ✅ الصور — نحفظها كـ bytes مباشرة بدون كتابة ملفات
    for (int i = 0; i < _pickedImages.length; i++) {
      items.add(PostItem(
        type: PostItemType.image,
        title: '',
        imageBytes: _pickedImages[i], // ✅ bytes مباشرة
      ));
    }

    // الفيديوهات
    for (int i = 0; i < _pickedVideos.length; i++) {
      items.add(PostItem(
        type: PostItemType.video,
        title: '',
        mediaPath: _pickedVideos[i].path,
      ));
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد محتوى للنشر')),
      );
      return;
    }
// ✅ بلوكات من PollBuilder
    for (final block in _blocks) {
      switch (block.type) {
        case BlockType.text:
          if ((block.textController?.text ?? '').trim().isNotEmpty) {
            items.add(PostItem(
              type: PostItemType.text,
              title: block.textController!.text.trim(),
            ));
          }
          break;
        case BlockType.image:
          if (block.image != null) {
            items.add(PostItem(
              type: PostItemType.image,
              title: '',
              mediaPath: block.image!.path,
            ));
          }
          break;
        case BlockType.video:
          if (block.video != null) {
            items.add(PostItem(
              type: PostItemType.video,
              title: '',
              mediaPath: block.video!.path,
            ));
          }
          break;
      }
    }
    Navigator.pop(context, items);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _pickedImages.add(bytes));
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final controller = VideoPlayerController.file(file)..setLooping(true);
    await controller.initialize();
    setState(() {
      _pickedVideos.add(file);
      _videoControllers.add(controller);
    });
  }

  // ✅ هذا هو سبب عدم النشر — دالة للتحقق هل يمكن النشر
  bool get _canPost {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasImages = _pickedImages.isNotEmpty;
    final hasVideos = _pickedVideos.isNotEmpty;
    final hasPoll = _pollDataList.isNotEmpty;
    final hasBlocks = _blocks.isNotEmpty;
    return hasTitle || hasImages || hasVideos || hasPoll || hasBlocks;
  }
  bool _isPosting = false;


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
          bottom: mediaQuery.viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 25),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Current User',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('u/current_user',
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 0),

            // أزرار الإضافة
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push<List<PostItem>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PollBuilderScreen(initialItems: _pollItems),
                      ),
                    );
                    if (result == null || result.isEmpty) return;
                    setState(() {
                      _pollItems = List.from(result);
                      _blocks.clear();
                      _poll = null;
                      for (var item in result) {
                        switch (item.type) {
                          case PostItemType.text:
                            _blocks.add(PostBlock.text()
                              ..textController!.text = item.title);
                            break;
                          case PostItemType.image:
                            if (item.mediaPath != null) {
                              final block = PostBlock.image()
                                ..image = File(item.mediaPath!);
                              block.textController!.text = item.title;
                              _blocks.add(block);
                            }
                            break;
                          case PostItemType.video:
                            if (item.mediaPath != null) {
                              final block = PostBlock.video()
                                ..video = File(item.mediaPath!)
                                ..textController!.text = item.title;
                              final controller = VideoPlayerController.file(block.video!);
                              controller.initialize().then((_) {
                                controller.setLooping(true);
                                setState(() {});
                              });
                              block.videoController = controller;
                              _blocks.add(block);
                            }
                            break;
                          case PostItemType.poll:
                            if (item.pollDataList != null &&
                                item.pollDataList!.isNotEmpty) {
                              _pollDataList = item.pollDataList!;
                            }
                            break;
                        }
                      }
                    });
                  },
                  icon: const Icon(Icons.list_rounded),
                  tooltip: 'Poll',
                ),
                IconButton(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_collection),
                  tooltip: 'Add video',
                ),
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library, size: 20),
                  tooltip: 'Add Images',
                ),
              ],
            ),
            const SizedBox(height: 8),

// ===== عرض بلوكات النص والصورة والفيديو من PollBuilder =====
            if (_blocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _blocks.length,
                itemBuilder: (context, index) {
                  final block = _blocks[index];
                  return Dismissible(
                    key: ValueKey(block),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => setState(() {
                      block.videoController?.dispose();
                      _blocks.removeAt(index);
                    }),
                    child: _buildBlock(block),
                  );
                },
              ),
            ],
            // ===== عرض الصور + الفيديوهات (الشكل القديم) =====
            if (_pickedImages.isNotEmpty || _pickedVideos.isNotEmpty)
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      itemCount: _pickedImages.length + _pickedVideos.length,
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) {
                        if (index < _pickedImages.length) {
                          final imageBytes = _pickedImages[index];
                          return Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final tempDir = await getTemporaryDirectory();
                                      final tempFile = await File('${tempDir.path}/image_$index.png')
                                          .writeAsBytes(_pickedImages[index]);
                                      Navigator.of(context, rootNavigator: true).push(
                                        MaterialPageRoute(
                                          builder: (_) => FullscreenImageViewer(
                                            images: [tempFile.path],
                                            initialIndex: 0,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Image.memory(
                                      imageBytes,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 200,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => setState(() => _pickedImages.removeAt(index)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final videoIndex = index - _pickedImages.length;
                          final controller = _videoControllers[videoIndex];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => FullscreenVideoViewer(controller: controller),
                                    ),
                                  ),
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.black,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (controller.value.isInitialized)
                                          FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: controller.value.size.width,
                                              height: controller.value.size.height,
                                              child: VideoPlayer(controller),
                                            ),
                                          )
                                        else
                                          const Center(child: CircularProgressIndicator()),
                                        IconButton(
                                          iconSize: 56,
                                          color: Colors.white,
                                          icon: Icon(
                                            controller.value.isPlaying
                                                ? Icons.pause_circle
                                                : Icons.play_circle,
                                          ),
                                          onPressed: () => setState(() {
                                            controller.value.isPlaying
                                                ? controller.pause()
                                                : controller.play();
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      controller.dispose();
                                      _pickedVideos.removeAt(videoIndex);
                                      _videoControllers.removeAt(videoIndex);
                                    }),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (controller.value.isInitialized)
                                  Positioned(
                                    bottom: 30,
                                    left: 5,
                                    right: 5,
                                    child: SizedBox(
                                      height: 8,
                                      child: VideoProgressIndicator(
                                        controller,
                                        allowScrubbing: true,
                                        colors: const VideoProgressColors(
                                          playedColor: Colors.red,
                                          bufferedColor: Colors.white38,
                                          backgroundColor: Colors.white24,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    if ((_pickedImages.length + _pickedVideos.length) > 1)
                      Positioned(
                        bottom: 10,
                        child: Row(
                          children: List.generate(
                            _pickedImages.length + _pickedVideos.length,
                                (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentImageIndex == i ? 10 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentImageIndex == i
                                    ? Colors.teal[900]
                                    : Colors.teal.shade900.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // ===== عرض البول (منفصل تماماً) =====
            if (_pollDataList.isNotEmpty) ...[
              const SizedBox(height: 16),
              PollPostWidget(polls: _pollDataList),
            ],

            const SizedBox(height: 20),
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                labelText: 'Add Tag',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _addTag(_tagController.text);
                    _tagController.clear();
                  },
                ),
              ),
              onSubmitted: (value) {
                _addTag(value);
                _tagController.clear();
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _suggestedTags.map((tag) {
                final isAdded = _tags.contains(tag);
                return ChoiceChip(
                  label: Text(tag),
                  selected: isAdded,
                  onSelected: (_) => isAdded ? _removeTag(tag) : _addTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: _tags
                    .map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag),
                ))
                    .toList(),
              ),
            const SizedBox(height: 12),

            // زر Post
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_canPost && !_isPosting) ? _submitPost : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isPosting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Post'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(PostBlock block) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TEXT
            if (block.type == BlockType.text)
              (block.textController?.text ?? '').trim().isNotEmpty
                  ? Text(
                block.textController!.text,
                style: const TextStyle(fontSize: 15),
              )
                  : const Text(
                'نص فارغ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

            // IMAGE
            if (block.type == BlockType.image && block.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  block.image!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // VIDEO
            if (block.type == BlockType.video && block.videoController != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (block.videoController!.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: block.videoController!.value.size.width,
                            height: block.videoController!.value.size.height,
                            child: VideoPlayer(block.videoController!),
                          ),
                        )
                      else
                        const CircularProgressIndicator(color: Colors.white),
                      IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        icon: Icon(
                          block.videoController!.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                        onPressed: () => setState(() {
                          block.videoController!.value.isPlaying
                              ? block.videoController!.pause()
                              : block.videoController!.play();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    for (final c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }
}

//=================================================================

class PollPostWidget extends StatefulWidget {
  final List<PollData> polls;
  const PollPostWidget({super.key, required this.polls});

  @override
  State<PollPostWidget> createState() => _PollPostWidgetState();
}

class _PollPostWidgetState extends State<PollPostWidget> {
  // نستخدم Map منفصلة لكل نوع لتجنب مشاكل الـ casting
  final Map<int, Set<int>> _setSelections = {};        // checkbox / multipleChoice
  final Map<int, List<List<bool>>> _gridSelections = {}; // grid / checkboxGrid
  final Map<int, Map<int, Set<int>>> _dateSelections = {}; // date
  final Map<int, TimeOfDay> _timeSelections = {};       // time
  final Map<int, dynamic> _simpleSelections = {};       // scale / dropdown / text
  final Map<int, TextEditingController> _textControllers = {};

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    // تنظيف الـ controllers
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    for (int i = 0; i < widget.polls.length; i++) {
      final poll = widget.polls[i];
      switch (poll.type) {

        case PollQuestionType.checkbox:
        case PollQuestionType.multipleChoice:
          _setSelections[i] = <int>{};
          break;
        case PollQuestionType.grid:
        case PollQuestionType.checkboxGrid:
          if (poll.gridRows.isNotEmpty && poll.gridColumns.isNotEmpty) {
            _gridSelections[i] = List.generate(
              poll.gridRows.length,
                  (_) => List<bool>.filled(poll.gridColumns.length, false),
            );
          }
          break;
        case PollQuestionType.date:
          _dateSelections[i] = <int, Set<int>>{};
          if (poll.dateConfig != null) {
            for (final m in poll.dateConfig!.months) {
              _dateSelections[i]![m] = <int>{};
            }
          }
          break;
        case PollQuestionType.time:
          if (poll.selectedTime != null) {
            _timeSelections[i] = poll.selectedTime!;
          }
          break;
        default:
          break;
      }
    }
  }

  // أضفها داخل _PollPostWidgetState
  bool _isArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  @override
  Widget build(BuildContext context) {
    if (widget.polls.isEmpty) return const SizedBox.shrink();

    // ✅ استخدم Column مع Expanded بدل SizedBox ثابت
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ بدل SizedBox(height:220) استخدم ConstrainedBox
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 150,
            maxHeight: 220,
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.polls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final poll = widget.polls[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.polls.length > 1)
                      Text(
                        '${i + 1} / ${widget.polls.length}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    if (poll.question.isNotEmpty) ...[
                      Directionality(
                        textDirection:
                        RegExp(r'[\u0600-\u06FF]').hasMatch(poll.question)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            poll.question,
                            textAlign:
                            RegExp(r'[\u0600-\u06FF]').hasMatch(poll.question)
                                ? TextAlign.right
                                : TextAlign.left,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          child: _buildInput(i, poll),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // نقاط المؤشر
        if (widget.polls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.polls.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 14 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.teal.shade900
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildInput(int i, PollData poll) {
    switch (poll.type) {

      case PollQuestionType.textBlock:
        return Center(
          child: Text(poll.blockText ?? '', style: const TextStyle(fontSize: 15)),
        );

      case PollQuestionType.imageBlock:
        if (poll.blockMediaPath != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(poll.blockMediaPath!),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        }
        return const SizedBox.shrink();

      case PollQuestionType.videoBlock:
        if (poll.blockMediaPath != null) {
          return _VideoSlideWidget(videoPath: poll.blockMediaPath!);
        }
        return const SizedBox.shrink();
    // ===== نص قصير =====
      case PollQuestionType.shortText:
        _textControllers.putIfAbsent(i, () {
          final ctrl = TextEditingController(
            text: _simpleSelections[i] as String? ?? '',
          );
          return ctrl;
        });
        final shortCtrl = _textControllers[i]!;
        final shortConfirmed = (_simpleSelections[i] as String?)?.isNotEmpty ?? false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: shortCtrl,
              maxLines: 1,
              onChanged: (v) => setState(() => _simpleSelections[i] = v),
              decoration: InputDecoration(
                hintText: 'اكتب إجابتك هنا...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.teal.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // زر التأكيد
            Row(
              children: [
                if (shortConfirmed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.teal, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'تم الحفظ',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                // ElevatedButton(
                //   onPressed: shortCtrl.text.trim().isEmpty
                //       ? null
                //       : () {
                //     setState(() {
                //       _simpleSelections[i] = shortCtrl.text.trim();
                //     });
                //     FocusScope.of(context).unfocus();
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.teal,
                //     foregroundColor: Colors.white,
                //     disabledBackgroundColor: Colors.grey.shade200,
                //     disabledForegroundColor: Colors.grey.shade400,
                //     elevation: 0,
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 24, vertical: 10),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'تأكيد',
                //     style: TextStyle(
                //         fontWeight: FontWeight.w600, fontSize: 14),
                //   ),
                // ),
              ],
            ),
          ],
        );

// ===== نص طويل =====
      case PollQuestionType.longText:
        _textControllers.putIfAbsent(i, () {
          final ctrl = TextEditingController(
            text: _simpleSelections[i] as String? ?? '',
          );
          return ctrl;
        });
        final longCtrl = _textControllers[i]!;
        final longConfirmed = (_simpleSelections[i] as String?)?.isNotEmpty ?? false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: longCtrl,
              maxLines: 5,
              onChanged: (v) => setState(() => _simpleSelections[i] = v),
              decoration: InputDecoration(
                hintText: 'اكتب إجابتك هنا...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.teal.withValues(alpha: 0.04),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // عداد الأحرف
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${longCtrl.text.length} حرف',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (longConfirmed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.teal, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'تم الحفظ',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
                // ElevatedButton(
                //   onPressed: longCtrl.text.trim().isEmpty
                //       ? null
                //       : () {
                //     setState(() {
                //       _simpleSelections[i] = longCtrl.text.trim();
                //     });
                //     FocusScope.of(context).unfocus();
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.teal,
                //     foregroundColor: Colors.white,
                //     disabledBackgroundColor: Colors.grey.shade200,
                //     disabledForegroundColor: Colors.grey.shade400,
                //     elevation: 0,
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 24, vertical: 10),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'تأكيد',
                //     style: TextStyle(
                //         fontWeight: FontWeight.w600, fontSize: 14),
                //   ),
                // ),
              ],
            ),
          ],
        );

// ===== Checkbox — اختيار واحد فقط =====
      case PollQuestionType.checkbox:
        return SizedBox(
          height: 150,
          child: Scrollbar(
            child: ListView.builder(
              itemCount: poll.options.length,
              itemBuilder: (context, index) {
                final isChecked = _setSelections[i]?.contains(index) ?? false;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _setSelections[i] = {index};
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? Colors.teal.withValues(alpha: 0.07)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked
                            ? Colors.teal
                            : Colors.grey.shade300,
                        width: isChecked ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // مربع الاختيار
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isChecked ? Colors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isChecked
                                  ? Colors.teal
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            poll.options[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isChecked
                                  ? Colors.teal.shade800
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

// ===== Multiple Choice — اختيار متعدد =====
      case PollQuestionType.multipleChoice:
        return SizedBox(
          height: 150,
          child: Scrollbar(
            child: ListView.builder(
              itemCount: poll.options.length,
              itemBuilder: (context, index) {
                final isSelected = _setSelections[i]?.contains(index) ?? false;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _setSelections[i] ??= <int>{};
                      if (isSelected) {
                        _setSelections[i]!.remove(index);
                      } else {
                        _setSelections[i]!.add(index);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.teal.withValues(alpha: 0.07)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.teal
                            : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // دائرة الاختيار
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.teal : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSelected ? 10 : 0,
                              height: isSelected ? 10 : 0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            poll.options[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.teal.shade800
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

    // ===== Dropdown =====
      case PollQuestionType.dropdown:
        final currentVal = _simpleSelections[i] as String?;
        final validVal = poll.options.contains(currentVal) ? currentVal : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.teal.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintText: 'اختر خياراً...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              value: validVal,
              // مهم: isExpanded يمنع overflow
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.teal),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              items: poll.options.map((o) {
                return DropdownMenuItem<String>(
                  value: o,
                  child: Text(
                    o,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _simpleSelections[i] = v);
              },
              // عرض القيمة المختارة بشكل مميز
              selectedItemBuilder: (context) {
                return poll.options.map((o) {
                  return Text(
                    o,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  );
                }).toList();
              },
            ),
            // مؤشر الاختيار
            if (validVal != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.teal, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      validVal,
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

    // ===== Linear Scale =====
      case PollQuestionType.linearScale:
        return _buildScale(i, poll);

    // ===== Grid =====
      case PollQuestionType.grid:
        return _buildGrid(i, poll, multiSelect: false);

    // ===== Checkbox Grid =====
      case PollQuestionType.checkboxGrid:
        return _buildGrid(i, poll, multiSelect: true);

    // ===== Date =====
      case PollQuestionType.date:
        return _buildDateView(i, poll);

    // ===== Time =====
      case PollQuestionType.time:
        return _buildTimeView(i);
    }
  }

  // ==================== Scale ====================
  Widget _buildScale(int i, PollData poll) {
    final size = poll.scaleSize ?? 5;
    final style = poll.scaleStyle ?? LinearScaleStyle.numbers;

    switch (style) {

    // ===== Numbers =====
      case LinearScaleStyle.numbers:
        final selected = _simpleSelections[i] as int?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Center(
                child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(size, (j) {
                final isSelected = selected == j;
                return GestureDetector(
                  onTap: () => setState(() => _simpleSelections[i] = j),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.teal
                          : Colors.teal.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected
                            ? Colors.teal
                            : Colors.teal.withValues(alpha: 0.25),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${j + 1}',
                        style: TextStyle(
                          fontSize: isSelected ? 15 : 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: selected != null ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selected != null ? '${selected + 1} / $size' : '-',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );

    // ===== Line =====
      case LinearScaleStyle.line:
        final raw = _simpleSelections[i];
        final val = raw is int ? raw.toDouble() : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // أرقام فوق الـ Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(size, (j) {
                  final isActive = val.round() == j + 1;
                  return SizedBox(
                    width: 24,
                    child: Center(
                      child: Text(
                        '${j + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? Colors.teal
                              : Colors.grey.shade400,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 13,
                  elevation: 2,
                ),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 22),
                activeTrackColor: Colors.teal,
                inactiveTrackColor: Colors.teal.withValues(alpha: 0.15),
                thumbColor: Colors.white,
                overlayColor: Colors.teal.withValues(alpha: 0.12),
                valueIndicatorColor: Colors.teal.shade700,
                valueIndicatorShape:
                const PaddleSliderValueIndicatorShape(),
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: Slider(
                value: val,
                min: 1,
                max: size.toDouble(),
                divisions: size - 1,
                label: val.round().toString(),
                onChanged: (v) =>
                    setState(() => _simpleSelections[i] = v.round()),
              ),
            ),
            // Low / High
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                  Text('High',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 0),
            // القيمة في دائرة بالمنتصف
            Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    val.round().toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );

    // ===== Emoji =====
      case LinearScaleStyle.emoji:
        final emojis = ['😡', '😕', '😐', '🙂', '😄'];
        final selected = _simpleSelections[i] as int?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(size, (j) {
                final isSelected = selected == j;
                return GestureDetector(
                  onTap: () => setState(() => _simpleSelections[i] = j),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.withValues(alpha: 0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Text(
                            emojis[j % emojis.length],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 6 : 0,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        );

    // ===== Emoji 1 =====
      case LinearScaleStyle.emoji1:
        final emojis = ['😭', '😢', '😐', '🙂', '😄'];
        final selected = _simpleSelections[i] as int?;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(size, (j) {
                final isSelected = selected == j;
                return GestureDetector(
                  onTap: () => setState(() => _simpleSelections[i] = j),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.withValues(alpha: 0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Text(
                            emojis[j % emojis.length],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 6 : 0,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        );
    }
  }
  // ==================== Grid ====================
  Widget _buildGrid(int i, PollData poll, {required bool multiSelect}) {
    if (poll.gridRows.isEmpty || poll.gridColumns.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للشبكة'));
    }

    // تأكد من تهيئة صحيحة الأبعاد
    final existing = _gridSelections[i];
    if (existing == null ||
        existing.length != poll.gridRows.length ||
        existing[0].length != poll.gridColumns.length) {
      _gridSelections[i] = List.generate(
        poll.gridRows.length,
            (_) => List<bool>.filled(poll.gridColumns.length, false),
      );
    }

    final sel = _gridSelections[i]!;

    if (!multiSelect) {
      // ===== Grid — يطابق PollGridWidget تماماً =====
      return SizedBox(
        height: 200,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (n) => n.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (poll.gridColumns.length + 1) * 110.0,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    columns: [
                      const DataColumn(label: Text('')),
                      ...poll.gridColumns.map(
                            (c) => DataColumn(
                          label: Text(
                            c,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                    rows: List.generate(poll.gridRows.length, (ri) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            poll.gridRows[ri],
                            style: Theme.of(context).textTheme.bodyMedium,
                          )),
                          ...List.generate(poll.gridColumns.length, (ci) {
                            final isSelected = sel[ri][ci];
                            return DataCell(
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    // ✅ grid: toggle حر — يمكن اختيار أكثر من عمود
                                    sel[ri][ci] = !sel[ri][ci];
                                  });
                                },
                                child: AnimatedScale(
                                  scale: isSelected ? 1.12 : 1.0,
                                  duration:
                                  const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 220),
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.teal.withValues(alpha: 0.10)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.teal.shade900
                                            : Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.6),
                                        width: isSelected ? 2.2 : 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 180),
                                      width: isSelected ? 10 : 0,
                                      height: isSelected ? 10 : 0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // ===== Checkbox Grid — يطابق PollCheckboxGridWidget تماماً =====
      return LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth = constraints.maxWidth;
          final columnWidth =
          (minTableWidth / (poll.gridColumns.length + 1))
              .clamp(90, 140)
              .toDouble();

          return SizedBox(
            height: 180,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minTableWidth),
                    child: DataTable(
                      columnSpacing: 0,
                      headingRowHeight: 44,
                      dataRowHeight: 52,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      columns: [
                        DataColumn(
                          label: SizedBox(
                              width: columnWidth, child: const Text('')),
                        ),
                        ...poll.gridColumns.map(
                              (c) => DataColumn(
                            label: SizedBox(
                              width: columnWidth,
                              child: Center(
                                child: Text(
                                  c,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(poll.gridRows.length, (ri) {
                        return DataRow(cells: [
                          DataCell(SizedBox(
                            width: columnWidth,
                            child: Text(poll.gridRows[ri]),
                          )),
                          ...List.generate(poll.gridColumns.length, (ci) {
                            final isSelected = sel[ri][ci];
                            return DataCell(
                              SizedBox(
                                width: columnWidth,
                                child: Center(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setState(() {
                                        // ✅ checkboxGrid: صف واحد → عمود واحد فقط
                                        for (int c = 0; c < sel[ri].length; c++) {
                                          sel[ri][c] = false;
                                        }
                                        sel[ri][ci] = true;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 200),
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.teal.shade900
                                              : Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          width: 2,
                                        ),
                                      ),
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.0 : 0.0,
                                        duration: const Duration(
                                            milliseconds: 150),
                                        curve: Curves.easeInOut,
                                        child: Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // ==================== Date ====================
  Widget _buildDateView(int i, PollData poll) {
    if (poll.dateConfig == null) {
      return const Center(child: Text('لم يُحدَّد تاريخ'));
    }

    final config = poll.dateConfig!;
    final monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];

    // تأكد من وجود Map للتاريخ
    _dateSelections[i] ??= <int, Set<int>>{};
    for (final m in config.months) {
      _dateSelections[i]!.putIfAbsent(m, () => <int>{});
    }

    final monthsList = List<int>.from(config.months)..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          ' ${config.year}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            //color: Colors.teal,
          ),
        ),
        const SizedBox(height: 0),
        ...monthsList.map((m) {
          final days = _dateSelections[i]![m]!;
          final daysInMonth = DateTime(config.year, m + 1, 0).day;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthNames[m - 1],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  //color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(daysInMonth, (d) {
                  final day = d + 1;
                  final isSelected = days.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          days.remove(day);
                        } else {
                          days.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.teal : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected
                              ? Colors.teal
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                            isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
            ],
          );
        }),
      ],
    );
  }

  // ==================== Time ====================
  Widget _buildTimeView(int i) {
    final selected = _timeSelections[i];

    return Column(

      children: [
        const SizedBox(height: 0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            //color: Colors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Text(
            selected != null
                ? '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}'
                : '--:--',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.teal,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(

            children: [
             SizedBox(width:180 ,),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            //backgroundColor: Colors.teal,
            //foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selected ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() => _timeSelections[i] = picked);
            }
          },
          icon: const Icon(Icons.access_time),
          label: Text(selected != null ? 'تغيير الوقت' : 'اختيار وقت'),
        )]),
      ],
    );
  }
}

class PollBuilderScreen extends StatefulWidget {
  final List<PostItem>? initialItems;

  const PollBuilderScreen({
    Key? key,
    this.initialItems,
  }) : super(key: key);

  @override
  State<PollBuilderScreen> createState() => _PollBuilderScreenState();
}

class _PollBuilderScreenState extends State<PollBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFab = true;
  final List<PollQuestion> _pollQuestions = [];
  List<PollData> _pollDataList = [];

  final TextEditingController titleCtrl = TextEditingController();
  final List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
  ];

  final TextEditingController _timeController = TextEditingController();
  final List<PostBlock> _blocks = [];

  void _savePoll() {
    final List<PostItem> items = [];
      final List<PollData> allSlides = [];

      // ✅ البلوكات → PollData مباشرة
      for (final block in _blocks) {
        switch (block.type) {
          case BlockType.text:
            final text = block.textController?.text.trim() ?? '';
            if (text.isNotEmpty) {
              allSlides.add(PollData(
                question: '',
                type: PollQuestionType.textBlock,
                options: const [],
                gridRows: const [],
                gridColumns: const [],
                blockText: text,
              ));
            }
            break;
          case BlockType.image:
            if (block.image != null) {
              allSlides.add(PollData(
                question: '',
                type: PollQuestionType.imageBlock,
                options: const [],
                gridRows: const [],
                gridColumns: const [],
                blockMediaPath: block.image!.path,
              ));
            }
            break;
          case BlockType.video:
            if (block.video != null) {
              allSlides.add(PollData(
                question: '',
                type: PollQuestionType.videoBlock,
                options: const [],
                gridRows: const [],
                gridColumns: const [],
                blockMediaPath: block.video!.path,
              ));
            }
            break;
        }
      }

      // ✅ أسئلة البول
      for (final q in _pollQuestions) {
        allSlides.add(PollData.fromQuestion(q));
      }

      if (allSlides.isNotEmpty) {
        items.add(PostItem(
          type: PostItemType.poll,
          title: '',
          pollDataList: allSlides,
        ));
      }

      Navigator.pop(context, items);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, // عدد التابات (نص / صورة / فيديو)
      vsync: this,
    );
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      for (final item in widget.initialItems!) {
        switch (item.type) {
          case PostItemType.text:
            _blocks.add(
              PostBlock.text()
                ..textController!.text = item.title,
            );
            break;

          case PostItemType.image:
            if (item.mediaPath != null) {
              final block = PostBlock.image()
                ..image = File(item.mediaPath!);
              block.textController!.text = item.title;
              _blocks.add(block);
            }
            break;

          case PostItemType.video:
            if (item.mediaPath != null) {
              final block = PostBlock.video()
                ..video = File(item.mediaPath!)
                ..textController!.text = item.title;

              final controller = VideoPlayerController.file(block.video!);

              controller.initialize().then((_) {
                setState(() {});
                controller.setLooping(true);
              });

              block.videoController = controller;
              _blocks.add(block);
            }
            break;

          case PostItemType.poll:
            if (item.pollDataList != null && item.pollDataList!.isNotEmpty) {
              // ✅ أعد بناء _pollQuestions من PollData المحفوظة
              for (final data in item.pollDataList!) {
                _pollQuestions.add(PollQuestion.fromPollData(data));
              }
            }
            break;}
        }
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // ⬅️ مهم جدًا

    for (final block in _blocks) {
      block.videoController?.dispose();
      block.textController?.dispose();
      block.focusNode?.dispose();
    }
    super.dispose();
  }

  void _addTextBlock() {
    setState(() {
      _blocks.add(PostBlock.text());
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_blocks.isNotEmpty) {
        _blocks.last.focusNode?.requestFocus();
      }
    });
  }

  void _addImageBlock() {
    setState(() {
      _blocks.add(PostBlock.image());
    });
  }

  void _openPollQuestionPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _pollTypeTile(' نص قصير      ', PollQuestionType.shortText),
                _pollTypeTile('نص طويل      ', PollQuestionType.longText),
              ],
            ),
            Row(
              children: [
                _pollTypeTile('Linear Scale', PollQuestionType.linearScale),
                _pollTypeTile('Dropdown', PollQuestionType.dropdown),
              ],
            ),
            Row(
              children: [
                _pollTypeTile('Checkbox       ', PollQuestionType.checkbox),
                _pollTypeTile(
                    'Multiple Choice', PollQuestionType.multipleChoice),
              ],
            ),
            Row(
              children: [
                _pollTypeTile('     Grid       ', PollQuestionType.grid),
                _pollTypeTile('Checkbox Grid', PollQuestionType.checkboxGrid),
              ],
            ),
            Row(
              children: [
                _pollTypeTile('     Date      ', PollQuestionType.date),
                _pollTypeTile('     Time      ', PollQuestionType.time),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageForBlock(PostBlock block) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        block.image = File(picked.path);
      });
    }
  }

  Widget _pollTypeTile(String title, PollQuestionType type) {
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return GestureDetector(
          onTap: () {
            // نفعّل تأثير الضغط أولًا
            setInnerState(() {
              isPressed = true;
            });

            // بعد 200 مللي ثانية، نغلق القائمة ونضيف العنصر
            Future.delayed(const Duration(milliseconds: 50), () {
              Navigator.pop(context); // إغلاق القائمة بعد التأثير
              setState(() {
                _pollQuestions.add(PollQuestion(type));
              });
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: isPressed
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isPressed
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(
                  width: 6,
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fabIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Poll'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الخصائص'),
            Tab(text: 'الردود'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'حفظ',
            onPressed: _savePoll,
          )
        ],
      ),
      floatingActionButton: _showFab
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fabIcon(
                    icon: Icons.add_circle_outline,
                    tooltip: 'إضافة Poll',
                    onTap: _openPollQuestionPicker,
                  ),
                  _fabIcon(
                    icon: Icons.text_fields,
                    tooltip: 'إضافة نص',
                    onTap: _addTextBlock,
                  ),
                  _fabIcon(
                    icon: Icons.add_photo_alternate_outlined,
                    tooltip: 'إضافة صورة',
                    onTap: _addImageBlock,
                  ),
                  _fabIcon(
                    icon: Icons.video_collection,
                    tooltip: 'إضافة فيديو',
                    onTap: () async {
                      // أولاً إنشاء بلوك فيديو جديد
                      final newBlock = PostBlock.video();
                      setState(() {
                        _blocks.add(newBlock);
                      });

                      // ثم اختيار الفيديو
                      final picked = await ImagePicker()
                          .pickVideo(source: ImageSource.gallery);
                      if (picked != null) {
                        final file = File(picked.path);
                        final controller = VideoPlayerController.file(file);
                        await controller.initialize();
                        controller.setLooping(true);

                        setState(() {
                          newBlock.video = file;
                          newBlock.videoController = controller;
                        });
                      }

                      // وضع التركيز على البلوك الأخير (اختياري)
                      Future.delayed(const Duration(milliseconds: 100), () {
                        newBlock.focusNode?.requestFocus();
                      });
                    },
                  ),
                ],
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProperties(),
          _buildResponses(),
        ],
      ),
    );
  }

  // =======================
  // واجهة الخصائص
  // =======================
  Widget _buildProperties() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blocks.length + _pollQuestions.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _blocks.removeAt(oldIndex);
            _blocks.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          // =======================
// POLL QUESTIONS (بعد البلوكات)
// =======================
          if (index >= _blocks.length) {
            final pollIndex = index - _blocks.length;
            final question = _pollQuestions[pollIndex];

            return Card(
              key: ValueKey(question),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildPollQuestionCard(question, index),
            );
          }

          final block = _blocks[index];

          return Dismissible(
              key: ValueKey(block),
              direction: DismissDirection.endToStart, // ⬅️ سحب لليسار
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                setState(() {
                  block.videoController?.dispose();
                  _blocks.removeAt(index);
                });
              },
              child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ⬇️ محتوى البلوك (TEXT / IMAGE / VIDEO)

                          // =======================
                          // TEXT BLOCK
                          // =======================
                          if (block.type == BlockType.text)
                            TextField(
                              controller: block.textController,
                              focusNode: block.focusNode,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'اكتب النص هنا...',
                                border: InputBorder.none,
                              ),
                            ),

                          // =======================
                          // IMAGE BLOCK
                          // =======================
                          if (block.type == BlockType.image) ...[
                            TextField(
                              controller: block.textController,
                              focusNode: block.focusNode,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'وصف الصورة...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                if (block.image != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullscreenImageViewer(
                                        images: [
                                          block.image!.path
                                        ], // ✅ تمرير List
                                        initialIndex: 0,
                                      ),
                                    ),
                                  );
                                } else {
                                  _pickImageForBlock(block);
                                }
                              },
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  image: block.image != null
                                      ? DecorationImage(
                                          image: FileImage(block.image!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: block.image == null
                                    ? _placeholder(
                                        icon:
                                            Icons.add_photo_alternate_outlined,
                                        text: 'إضافة صورة',
                                      )
                                    : null,
                              ),
                            ),
                          ],

                          // =======================
                          // VIDEO BLOCK ✅
                          // =======================
                          if (block.type == BlockType.video &&
                              block.videoController != null) ...[
                            // وصف الفيديو
                            TextField(
                              controller: block.textController,
                              focusNode: block.focusNode,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'وصف الفيديو...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullscreenVideoViewer(
                                      controller: block.videoController!,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 180, // ✅ الحد الأقصى للطول
                                  width: double.infinity,
                                  color: Colors.black,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: block.videoController!.value
                                              .size.width,
                                          height: block.videoController!.value
                                              .size.height,
                                          child: InteractiveViewer(
                                            maxScale: 2.5,
                                            minScale: 1.0,
                                            child: VideoPlayer(
                                                block.videoController!),
                                          ),
                                        ),
                                      ),

                                      // زر تشغيل / إيقاف
                                      IconButton(
                                        iconSize: 56,
                                        color: Colors.white,
                                        icon: Icon(
                                          block.videoController!.value.isPlaying
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            block.videoController!.value
                                                    .isPlaying
                                                ? block.videoController!.pause()
                                                : block.videoController!.play();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // شريط التقدم (مصغّر)
                            SizedBox(
                              height: 6,
                              child: VideoProgressIndicator(
                                block.videoController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.red,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  )));
        },
      ),
    );
  }

  Widget _buildPollQuestionCard(PollQuestion q, int index) {
    return Dismissible(
      key: ValueKey('poll_$index'), // ✅ FIX
      direction: DismissDirection.horizontal,

      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.undo, color: Colors.white),
      ),

      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return true; // delete
        }

        if (direction == DismissDirection.startToEnd) {
          setState(() {
            q.reset(); // ✅ undo
          });
          return false;
        }

        return false;
      },

      onDismissed: (_) {
        setState(() {
          _pollQuestions.removeAt(index);
        });
      },

      child: Card(
        key: q.rebuildKey, // ✅ rebuild widget
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: q.questionCtrl,
                decoration: const InputDecoration(
                  hintText: 'اكتب السؤال هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _buildPollQuestionInput(q),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPollQuestionInput(PollQuestion q) {
    if (!q.confirmed) {
    switch (q.type) {

      case PollQuestionType.textBlock:
      case PollQuestionType.imageBlock:
      case PollQuestionType.videoBlock:
        return const SizedBox.shrink();
      case PollQuestionType.shortText:
        return const TextField(
          enabled: false,
          decoration: InputDecoration(hintText: 'إجابة قصيرة'),
        );

      case PollQuestionType.longText:
        return const TextField(
          enabled: false,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'إجابة طويلة'),
        );

      case PollQuestionType.checkbox:
        return PollCheckboxWidget(
          key: ValueKey(q), // مهم لكل سؤال ليكون مستقل
          question: q,
        );

      case PollQuestionType.multipleChoice:
        return PollMultipleChoiceWidget(question: q);


      case PollQuestionType.dropdown:
        return PollDropdownWidget(question: q);


      case PollQuestionType.linearScale:
        return StatefulBuilder(
          builder: (context, setStateInner) {
            // إذا لم يتم التأكيد بعد، أظهر الـ Selector
            if (!q.scaleConfirmed) {
              return LinearScaleSelector(
                initialStyle: q.scaleStyle,
                initialSize: q.scaleSize,
                onStyleChanged: (v) {
                  setStateInner(() => q.scaleStyle = v);
                },
                onSizeChanged: (v) {
                  setStateInner(() => q.scaleSize = v);
                },
                onConfirm: () {
                  setState(() {
                    q.scaleConfirmed = true; // حفظ التأكيد على السؤال
                  });
                },
              );
            }

            // بعد التأكيد، عرض المقياس داخل Card أنيق (غير قابل للتعديل)
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ===== NUMBERS =====
                    if (q.scaleStyle == LinearScaleStyle.numbers)

                      SizedBox(
                        height: 35, // ارتفاع الشريط
                        child: Center(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: q.scaleSize,
                            padding: EdgeInsets.symmetric(horizontal: 16), // مسافة من الجانبين
                            itemBuilder: (context, i) {
                              final isSelected = q.selectedNumber == i + 1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    q.selectedNumber = i + 1;
                                    setState(() {}); // تحديث الواجهة
                                  },
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // ===== LINE =====
                    if (q.scaleStyle == LinearScaleStyle.line)
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text('Low'),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Slider(
                                  value: q.lineValue.toDouble(),
                                  min: 1,
                                  max: q.scaleSize.toDouble(),
                                  divisions: q.scaleSize - 1,
                                  label: '${q.lineValue}',
                                  onChanged: (v) {
                                    setState(() {
                                      q.lineValue = v.round();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('High'),
                            ],
                          )

                        ],
                      ),

                    // ===== EMOJI =====
                    if (q.scaleStyle == LinearScaleStyle.emoji)
                      SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(q.scaleSize, (i) {
                            final emojis = ['😡', '😕', '😐', '🙂', '😄'];
                            final mid = emojis.length ~/ 2;
                            int index = (i <= mid)
                                ? i
                                : emojis.length - (q.scaleSize - i);

                            final isSelected = q.selectedEmoji == i;

                            return GestureDetector(
                              onTap: () {
                                q.selectedEmoji = i;
                                setState(() {}); // تحديث الواجهة
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.4 : 1.0, // تكبير عند التحديد
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    emojis[index],
                                    style: TextStyle(
                                      fontSize: 26,
                                      color: isSelected ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                    // ===== EMOJI =====
                    if (q.scaleStyle == LinearScaleStyle.emoji1)
                      SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(q.scaleSize, (i) {
                            final emojis = ['😭', '😢', '😐', '🙂', '😄'];
                            final mid = emojis.length ~/ 2;
                            int index = (i <= mid)
                                ? i
                                : emojis.length - (q.scaleSize - i);

                            final isSelected = q.selectedEmoji1 == i;

                            return GestureDetector(
                              onTap: () {
                                q.selectedEmoji1 = i;
                                setState(() {}); // تحديث الواجهة
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.4 : 1.0, // تكبير عند التحديد
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    emojis[index],
                                    style: TextStyle(
                                      fontSize: 26,
                                      color: isSelected ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                  ],
                ),
              ),
            );

          },
        );


      case PollQuestionType.grid:
        return PollGridWidget(question: q);

      case PollQuestionType.checkboxGrid:
        return PollCheckboxGridWidget(
          question: q,
        );


      case PollQuestionType.date:
        return DatePollWidget(
          initialConfig: q.dateConfig,
          onConfirm: (config) {
            setState(() {
              q.dateConfig = config; // ✅ حفظ الإعداد
            });
          },
        );

      case PollQuestionType.time:
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: q.selectedTime ?? TimeOfDay.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        q.selectedTime = picked;
                        q.timeController!.text = picked.format(context);
                      });
                    }
                  },
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8), // لون الزر
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface, // لون النص والأيقونة
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: q.selectedTime ?? TimeOfDay.now(),
                        );

                        if (picked != null) {
                          setState(() {
                            q.selectedTime = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        q.selectedTime != null
                            ? ' ${q.selectedTime!.format(context)}'
                            : 'اختيار وقت',
                      ),
                    )
                  ]),
                ),
              ],
            );
          },
        );
    }}return const SizedBox.shrink();
  }



  // =======================
  // واجهة الردود
  // =======================
  Widget _buildResponses() {
    return const Center(
      child: Text(
        'ستظهر الردود هنا بعد نشر المنشور',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

//=============================================================
class LinearScaleSelector extends StatefulWidget {
  final LinearScaleStyle initialStyle;
  final int initialSize;
  final ValueChanged<LinearScaleStyle> onStyleChanged;
  final ValueChanged<int> onSizeChanged;
  final VoidCallback onConfirm;

  const LinearScaleSelector({
    super.key,
    required this.initialStyle,
    required this.initialSize,
    required this.onStyleChanged,
    required this.onSizeChanged,
    required this.onConfirm,
  });

  @override
  State<LinearScaleSelector> createState() => _LinearScaleSelectorState();
}

class _LinearScaleSelectorState extends State<LinearScaleSelector> {
  late LinearScaleStyle _style;
  late int _size;

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle;
    _size = widget.initialSize;

    if (_style == LinearScaleStyle.emoji1) _size = 5;
    if (_style == LinearScaleStyle.emoji) _size = 5;// حجم افتراضي للإيموجي
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slider الحجم يظهر فقط للأرقام والخط
        if (_style != LinearScaleStyle.emoji  && _style != LinearScaleStyle.emoji1) ...[
          Row(
            children: [
              const Text('Size'),
              const Spacer(),
              Text('$_size'),
            ],
          ),
          Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: _size.toDouble(),
            onChanged: (v) {
              int newValue = v.round();
              if (_style == LinearScaleStyle.emoji && newValue.isEven) newValue += 1;

              setState(() => _size = newValue);
              widget.onSizeChanged(newValue);
            },
          ),
          const SizedBox(height: 12),
        ],


        const SizedBox(height: 0),
Text('Style :'),SizedBox(height: 8,),
        // NUMBERS
        _ScaleOptionCard(
          selected: _style == LinearScaleStyle.numbers,
          label: 'Numbers',
          onTap: () {
            setState(() => _style = LinearScaleStyle.numbers);
            widget.onStyleChanged(_style);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
                  (i) => CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text('${i + 1}'),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // LINE
        _ScaleOptionCard(
          selected: _style == LinearScaleStyle.line,
          label: 'Line',
          onTap: () {
            setState(() => _style = LinearScaleStyle.line);
            widget.onStyleChanged(_style);
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [Text('Low'), Text('High')],
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // EMOJI
        _ScaleOptionCard(
          selected: _style == LinearScaleStyle.emoji,
          label: 'Emoji',
          onTap: () {
            setState(() {
              _style = LinearScaleStyle.emoji;
              _size = 5; // الحجم الافتراضي للإيموجي
            });
            widget.onStyleChanged(_style);
            widget.onSizeChanged(_size);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('😡', style: TextStyle(fontSize: 22)),
              Text('😕', style: TextStyle(fontSize: 22)),
              Text('😐', style: TextStyle(fontSize: 26)),
              Text('🙂', style: TextStyle(fontSize: 22)),
              Text('😄', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
        _ScaleOptionCard(
          selected: _style == LinearScaleStyle.emoji1,
          label: 'Emoji ',
          onTap: () {
            setState(() {
              _style = LinearScaleStyle.emoji1;
              _size = 5; // الحجم الافتراضي للإيموجي
            });
            widget.onStyleChanged(_style);
            widget.onSizeChanged(_size);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('😭', style: TextStyle(fontSize: 22)),
              Text('😢', style: TextStyle(fontSize: 22)),
              Text('😐', style: TextStyle(fontSize: 26)),
              Text('🙂', style: TextStyle(fontSize: 22)),
              Text('😄', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            child: const Text('تأكيد'),
          ),
        ),
      ],
    );
  }
}

class _ScaleOptionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String label;

  const _ScaleOptionCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: selected ? 4 : 1,
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              child,
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
//==========================================

class PollDropdownWidget extends StatefulWidget {
  final PollQuestion question;

  const PollDropdownWidget({super.key, required this.question});

  @override
  State<PollDropdownWidget> createState() => _PollDropdownWidgetState();
}

class _PollDropdownWidgetState extends State<PollDropdownWidget> {
  late List<TextEditingController> _localControllers;
  String? _selectedValue;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // إنشاء نسخة مستقلة لكل Dropdown
    _localControllers = widget.question.options.isNotEmpty
        ? widget.question.options
        .map((c) => TextEditingController(text: c.text))
        .toList()
        : [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    for (var ctrl in _localControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.question),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, child: child),
          ),
          child: _confirmed ? _buildDropdown() : _buildInputFields(),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أدخل الخيارات:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._localControllers.map((ctrl) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'خيار',
              border: OutlineInputBorder(),
            ),
          ),
        )),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() => _localControllers.add(TextEditingController()));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // إزالة الخيارات الفارغة
                _localControllers.removeWhere((c) => c.text.trim().isEmpty);
                if (_localControllers.isEmpty) return;

                // نسخ النصوص إلى widget.question.options مع إنشاء Controllers جديدة
                widget.question.options =
                    _localControllers.map((c) => TextEditingController(text: c.text)).toList();

                setState(() {
                  _confirmed = true;
                  _selectedValue = null; // إعادة تهيئة الاختيار
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      key: const ValueKey('dropdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose :',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: widget.question.options
              .map((c) => DropdownMenuItem<String>(
            value: c.text,
            child: Text(c.text),
          ))
              .toList(),
          onChanged: (v) {
            setState(() => _selectedValue = v);
          },
        ),
      ],
    );
  }
}

//=================================================
class PollCheckboxWidget extends StatefulWidget {
  final PollQuestion question;

  const PollCheckboxWidget({super.key, required this.question});

  @override
  State<PollCheckboxWidget> createState() => _PollCheckboxWidgetState();
}

class _PollCheckboxWidgetState extends State<PollCheckboxWidget> {
  late List<TextEditingController> _localControllers;
  late List<bool> _selectedValues;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // نسخة محلية من الخيارات لتجنب مشاركة Controllers بين الأسئلة
    _localControllers = widget.question.options.isNotEmpty
        ? widget.question.options
        .map((c) => TextEditingController(text: c.text))
        .toList()
        : [TextEditingController(), TextEditingController()];

    _selectedValues = List.filled(_localControllers.length, false);
  }

  @override
  void dispose() {
    for (var c in _localControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.question),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, child: child)),
          child: _confirmed ? _buildCheckboxList() : _buildInputFields(),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('أدخل الخيارات:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._localControllers.map((ctrl) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'خيار',
              border: OutlineInputBorder(),
            ),
          ),
        )),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _localControllers.add(TextEditingController());
                  _selectedValues.add(false);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة خيار'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // إزالة الفارغة
                _localControllers.removeWhere((c) => c.text.trim().isEmpty);
                if (_localControllers.isEmpty) return;

                widget.question.options = _localControllers
                    .map((c) => TextEditingController(text: c.text))
                    .toList();

                _selectedValues = List.filled(widget.question.options.length, false);

                setState(() {
                  _confirmed = true;
                });
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckboxList() {
    return Column(
      key: const ValueKey('checkbox'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        Container(
          height: 160, // ارتفاع ثابت للقائمة، يمكن تغييره حسب الحاجة
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.0), // تأثير شفاف في الأسفل
              ],
            ),
          ),
          child: Scrollbar(
            child: ListView.builder(
              itemCount: widget.question.options.length,
              itemBuilder: (context, index) {
                final ctrl = widget.question.options[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: _selectedValues[index],
                    activeColor: Colors.teal,
                    title: Text(ctrl.text),
                    onChanged: (v) {
                      setState(() {
                        for (int i = 0; i < _selectedValues.length; i++) {
                          _selectedValues[i] = i == index;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

  }
}

//==========================================================
class PollMultipleChoiceWidget extends StatefulWidget {
  final PollQuestion question;

  const PollMultipleChoiceWidget({super.key, required this.question});

  @override
  State<PollMultipleChoiceWidget> createState() => _PollMultipleChoiceWidgetState();
}
class _PollMultipleChoiceWidgetState extends State<PollMultipleChoiceWidget> {
  late List<TextEditingController> _localControllers;
  late List<bool> _selectedValues;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    // نسخة محلية من الخيارات لتجنب مشاركة Controllers بين الأسئلة
    _localControllers = widget.question.options.isNotEmpty
        ? widget.question.options.map((c) => TextEditingController(text: c.text)).toList()
        : [TextEditingController(), TextEditingController()];
    _selectedValues = List.filled(_localControllers.length, false);
  }

  @override
  void dispose() {
    for (var c in _localControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.question),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, child: child)),
          child: _confirmed ? _buildOptionsGrid() : _buildInputFields(),
        ),
      ),
    );
  }

  // مرحلة إدخال الخيارات قبل التأكيد
  Widget _buildInputFields() {
    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('أدخل الخيارات:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._localControllers.map((ctrl) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'خيار',
              border: OutlineInputBorder(),
            ),
          ),
        )),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _localControllers.add(TextEditingController());
                  _selectedValues.add(false);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة خيار'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                _localControllers.removeWhere((c) => c.text.trim().isEmpty);
                if (_localControllers.isEmpty) return;
                widget.question.options = _localControllers
                    .map((c) => TextEditingController(text: c.text))
                    .toList();
                _selectedValues = List.filled(widget.question.options.length, false);
                setState(() => _confirmed = true);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ],
    );
  }

  // مرحلة العرض النهائي مع إمكانية اختيار أكثر من خيار
  Widget _buildOptionsGrid() {
    return Column(
      key: const ValueKey('Multi Choices :'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose :', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          height: 140, // ارتفاع ثابت للقائمة
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.0), // تلميح بصري لوجود خيارات إضافية
              ],
            ),
          ),
          child: Scrollbar(
            child: ListView.builder(
              itemCount: widget.question.options.length,
              itemBuilder: (context, index) {
                final ctrl = widget.question.options[index];
                final isSelected = _selectedValues[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedValues[index] = !isSelected; // تبديل الاختيار
                      });
                    },
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.teal.shade900 : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected ? Colors.blue.withValues(alpha: 0.0) : Colors.transparent,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 12 : 0,
                          height: isSelected ? 12 : 0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.teal : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    title: Text(ctrl.text),
                    visualDensity: const VisualDensity(vertical: -4),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );


  }
}

//==============================================================
class PollGridWidget extends StatefulWidget {
  final PollQuestion question;

  const PollGridWidget({super.key, required this.question});

  @override
  State<PollGridWidget> createState() => _PollGridWidgetState();
}

class _PollGridWidgetState extends State<PollGridWidget> {
  late List<TextEditingController> _rows;
  late List<TextEditingController> _columns;
  late List<List<bool>> _gridSelections;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // تحويل نصوص الصفوف والأعمدة من PollQuestion إلى TextEditingController
    _rows = widget.question.gridRows
        .map((text) => TextEditingController(text: text))
        .toList();
    if (_rows.isEmpty) _rows = [TextEditingController(), TextEditingController()];

    _columns = widget.question.gridColumns
        .map((text) => TextEditingController(text: text))
        .toList();
    if (_columns.isEmpty) _columns = [TextEditingController(), TextEditingController()];

    _gridSelections = List.generate(
      _rows.length,
          (i) => List.filled(_columns.length, false),
    );

    _confirmed = widget.question.gridConfirmed;
  }

  @override
  void dispose() {
    for (var c in _rows) c.dispose();
    for (var c in _columns) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _confirmed ? _buildGrid(context) : _buildInput(),

        ),
      ),
    );
  }

  // ================= INPUT =================

  Widget _buildInput() {
    return Column(
      key: const ValueKey('grid_input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vertical options (Rows):',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        ...List.generate(_rows.length, (i) => _optionField(_rows[i], i, true)),

        TextButton.icon(
          onPressed: () {
            setState(() => _rows.add(TextEditingController()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Row'),
        ),

        const SizedBox(height: 12),

        const Text('Horizontal options (Columns):',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        ...List.generate(_columns.length, (i) => _optionField(_columns[i], i, false)),

        TextButton.icon(
          onPressed: () {
            setState(() => _columns.add(TextEditingController()));
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Column'),
        ),

        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _confirm,
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _optionField(TextEditingController c, int index, bool isRow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: ValueKey(isRow ? 'row_$index' : 'col_$index'), // 🔑 مفتاح ثابت
        controller: c,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Option',
        ),
      ),
    );
  }


  void _confirm() {
    _rows.removeWhere((c) => c.text.trim().isEmpty);
    _columns.removeWhere((c) => c.text.trim().isEmpty);

    if (_rows.isEmpty || _columns.isEmpty) return;

    _gridSelections = List.generate(
      _rows.length,
          (_) => List.generate(_columns.length, (_) => false),
    );

    setState(() {
      _confirmed = true;

      // حفظ البيانات في PollQuestion
      widget.question.gridRows = _rows.map((c) => c.text).toList();
      widget.question.gridColumns = _columns.map((c) => c.text).toList();
      widget.question.gridSelections = _gridSelections;
      widget.question.gridConfirmed = true;
      widget.question.rebuildKey = UniqueKey(); // force rebuild عند Undo
    });
  }
  @override
  void didUpdateWidget(covariant PollGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث النصوص الموجودة فقط
    for (int i = 0; i < widget.question.gridRows.length && i < _rows.length; i++) {
      _rows[i].text = widget.question.gridRows[i];
    }
    for (int i = 0; i < widget.question.gridColumns.length && i < _columns.length; i++) {
      _columns[i].text = widget.question.gridColumns[i];
    }

    _gridSelections = widget.question.gridSelections
        .map((row) => row.cast<bool>())
        .toList();

    _confirmed = widget.question.gridConfirmed;
  }




  // ================= GRID =================

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final verticalController = ScrollController();
    final horizontalController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grid:',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 200,
          child: Scrollbar(
            controller: verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: verticalController,
              child: Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                notificationPredicate: (n) => n.depth == 1,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: (_columns.length + 1) * 110,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(
                        colorScheme.surfaceVariant,
                      ),
                      columns: [
                        const DataColumn(label: Text('')),
                        ..._columns.map(
                              (c) => DataColumn(
                            label: Text(
                              c.text,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                      rows: List.generate(_rows.length, (rowIndex) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                _rows[rowIndex].text,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            ...List.generate(_columns.length, (colIndex) {
                              final isSelected =
                              _gridSelections[rowIndex][colIndex];

                              return DataCell(
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gridSelections[rowIndex][colIndex] = !isSelected;
                                    });
                                  },
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.12 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      width: 25,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.teal.withValues(alpha: 0.10)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.teal.shade900
                                              : colorScheme.outline.withValues(alpha: 0.6),
                                          width: isSelected ? 2.2 : 1.5,
                                        ),
                                        // boxShadow: isSelected
                                        //     ? [
                                        //   BoxShadow(
                                        //     color: Colors.teal.withValues(alpha: 0.25),
                                        //     blurRadius: 6,
                                        //     spreadRadius: 1,
                                        //   ),
                                        // ]
                                        //     : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: isSelected ? 10 : 0,
                                        height: isSelected ? 10 : 0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),


                              );
                            }),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


}

//===========================================================
class PollCheckboxGridWidget extends StatefulWidget {
  final PollQuestion question;

  const PollCheckboxGridWidget({
    super.key,
    required this.question,
  });

  @override
  State<PollCheckboxGridWidget> createState() =>
      _PollCheckboxGridWidgetState();
}

class _PollCheckboxGridWidgetState extends State<PollCheckboxGridWidget> {
  late List<TextEditingController> _rows = [];
  late List<TextEditingController> _columns = [];

  late List<List<bool>> _gridSelections;

  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // تحويل نصوص الصفوف والأعمدة من PollQuestion إلى TextEditingController
    _rows = widget.question.gridRows
        .map((text) => TextEditingController(text: text))
        .toList();
    if (_rows.isEmpty) _rows = [TextEditingController(), TextEditingController()];

    _columns = widget.question.gridColumns
        .map((text) => TextEditingController(text: text))
        .toList();
    if (_columns.isEmpty) _columns = [TextEditingController(), TextEditingController()];

    _gridSelections = List.generate(
      _rows.length,
          (i) => List.filled(_columns.length, false),
    );

    _confirmed = widget.question.gridConfirmed;
  }

  @override
  void dispose() {
    for (var c in _rows) c.dispose();
    for (var c in _columns) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _confirmed ? _buildGrid(context) : _buildInput(),
        ),
      ),
    );
  }

  // ================= INPUT =================

  Widget _buildInput() {
    return Column(
      key: const ValueKey('checkbox_grid_input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vertical options (Rows)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...List.generate(_rows.length, (i) => _optionField(_rows[i], i, true)),
        TextButton.icon(
          onPressed: () =>
              setState(() => _rows.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: const Text('Add Row'),
        ),

        const SizedBox(height: 12),

        const Text('Horizontal options (Columns)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...List.generate(_columns.length, (i) => _optionField(_columns[i], i, false)),
        TextButton.icon(
          onPressed: () =>
              setState(() => _columns.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: const Text('Add Column'),
        ),

        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _confirm,
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _optionField(TextEditingController c, int index, bool isRow) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: ValueKey(isRow ? 'row_$index' : 'col_$index'), // 🔑 مفتاح ثابت
        controller: c,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Option',
        ),
      ),
    );
  }


  void _confirm() {
    _rows.removeWhere((c) => c.text.trim().isEmpty);
    _columns.removeWhere((c) => c.text.trim().isEmpty);

    if (_rows.isEmpty || _columns.isEmpty) return;

    _gridSelections = List.generate(
      _rows.length,
          (_) => List.generate(_columns.length, (_) => false),
    );

    setState(() {
      _confirmed = true;

      // حفظ البيانات في PollQuestion
      widget.question.gridRows = _rows.map((c) => c.text).toList();
      widget.question.gridColumns = _columns.map((c) => c.text).toList();
      widget.question.gridSelections = _gridSelections;
      widget.question.gridConfirmed = true;
      widget.question.rebuildKey = UniqueKey(); // force rebuild عند Undo
    });
  }

  @override
  void didUpdateWidget(covariant PollCheckboxGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث النصوص الموجودة فقط
    for (int i = 0; i < widget.question.gridRows.length && i < _rows.length; i++) {
      _rows[i].text = widget.question.gridRows[i];
    }
    for (int i = 0; i < widget.question.gridColumns.length && i < _columns.length; i++) {
      _columns[i].text = widget.question.gridColumns[i];
    }

    _gridSelections = widget.question.gridSelections
        .map((row) => row.cast<bool>())
        .toList();

    _confirmed = widget.question.gridConfirmed;
  }

  // ================= GRID =================

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTableWidth = constraints.maxWidth;
        final columnWidth =
        (minTableWidth / (_columns.length + 1)).clamp(90, 140).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checkbox Grid :', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minTableWidth),
                      child: DataTable(
                        columnSpacing: 0,
                        headingRowHeight: 44,
                        dataRowHeight: 52,
                        headingRowColor:
                        WidgetStateProperty.all(colorScheme.surfaceVariant),
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: columnWidth,
                              child: const Text(''),
                            ),
                          ),
                          ..._columns.map(
                                (c) => DataColumn(
                              label: SizedBox(
                                width: columnWidth,
                                child: Center(
                                  child: Text(
                                    c.text,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(_rows.length, (rowIndex) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: columnWidth,
                                  child: Text(_rows[rowIndex].text),
                                ),
                              ),
                              ...List.generate(_columns.length, (colIndex) {
                                final isSelected = _gridSelections[rowIndex][colIndex];

                                return DataCell(
                                  SizedBox(
                                    width: columnWidth,
                                    child: Center(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() {
                                            for (int i = 0; i < _gridSelections[rowIndex].length; i++) {
                                              _gridSelections[rowIndex][i] = false;
                                            }
                                            _gridSelections[rowIndex][colIndex] = true;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 22,
                                          height: 22,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: isSelected
                                                ? Colors.transparent
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.teal.shade900
                                                  : colorScheme.outline,
                                              width: 2,
                                            ),
                                          ),
                                          child: AnimatedScale(
                                            scale: isSelected ? 1 : 0,
                                            duration: const Duration(milliseconds: 150),
                                            curve: Curves.easeInOut,
                                            child: Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


}

//=======================================================
class PollDateConfig {
  int year;
  List<int> months; // 1..12

  PollDateConfig({
    required this.year,
    required this.months,
  });
}

class PollData {
  final String question;
  final PollQuestionType type;

  final String? blockText;
  final String? blockMediaPath;
  // checkbox / multipleChoice / dropdown
  final List<String> options;

  // grid / checkboxGrid
  final List<String> gridRows;
  final List<String> gridColumns;

  // linearScale
  final LinearScaleStyle? scaleStyle;
  final int? scaleSize;

  // date
  final PollDateConfig? dateConfig;

  // time
  final TimeOfDay? selectedTime;

  PollData({
    required this.question,
    required this.type,
    this.options = const [],
    this.gridRows = const [],
    this.gridColumns = const [],
    this.scaleStyle,
    this.scaleSize,
    this.dateConfig,
    this.selectedTime,
    this.blockText,
    this.blockMediaPath,
  });

  // تحويل من PollQuestion إلى PollData
  factory PollData.fromQuestion(PollQuestion q) {
    return PollData(
      question: q.questionCtrl.text.trim(),
      type: q.type,
      options: q.options
          .map((c) => c.text.trim())
          .where((o) => o.isNotEmpty)
          .toList(),
      gridRows: List.from(q.gridRows),
      gridColumns: List.from(q.gridColumns),
      scaleStyle: q.scaleStyle,
      scaleSize: q.scaleSize,
      dateConfig: q.dateConfig,
      selectedTime: q.selectedTime,
    );
  }
}

class DatePollWidget extends StatefulWidget {
  final PollDateConfig? initialConfig;
  final void Function(PollDateConfig config) onConfirm;

  const DatePollWidget({
    super.key,
    this.initialConfig,
    required this.onConfirm,
  });

  @override
  State<DatePollWidget> createState() => _DatePollWidgetState();
}

class _DatePollWidgetState extends State<DatePollWidget> {
  late TextEditingController _yearController;
  final Set<int> _selectedMonths = {};
  bool _confirmed = false;
  late PageController _pageController;
  int _currentPage = 0;
  static const int maxSelectableDays = 31;

// year -> month -> days
  final Map<int, Map<int, Set<int>>> _selectedDays = {};

  Set<int> _daysFor(int year, int month) {
    _selectedDays.putIfAbsent(year, () => {});
    _selectedDays[year]!.putIfAbsent(month, () => {});
    return _selectedDays[year]![month]!;
  }

  bool _isDaySelected(int year, int month, int day) {
    return _daysFor(year, month).contains(day);
  }

  void _toggleDay(int year, int month, int day) {
    final days = _daysFor(year, month);

    setState(() {
      if (days.contains(day)) {
        days.remove(day);
      } else {
        if (days.length >= maxSelectableDays) return;
        days.add(day);
      }
    });
  }

  static const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _yearController = TextEditingController(
      text: widget.initialConfig?.year.toString(),
    );

    if (widget.initialConfig != null) {
      _selectedMonths.addAll(widget.initialConfig!.months);
      _confirmed = true;
    }

    _pageController = PageController();
  }

  Widget _buildCalendars() {
    final year = int.parse(_yearController.text);
    final monthsList = _selectedMonths.toList()..sort();

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: monthsList.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
            },
            itemBuilder: (context, index) {
              final month = monthsList[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          child: CalendarDatePicker(
                            initialDate: DateTime(year, month, 1),
                            firstDate: DateTime(year, month, 1),
                            lastDate: DateTime(year, month + 1, 0),
                            onDateChanged: (date) {
                              _toggleDay(year, month, date.day);
                            },
                            selectableDayPredicate: (date) {
                              final days = _daysFor(year, month);
                              return days.contains(date.day) ||
                                  days.length < maxSelectableDays;
                            },
                          ),
                        ),
                        const SizedBox(height: 0),
                        // بدل الـ Wrap
                        if (_daysFor(year, month).isNotEmpty)
                          SizedBox(
                            height: 40, // ارتفاع الشريط
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _daysFor(year, month)
                                  .map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Chip(
                                        label: Text('$d'),
                                        onDeleted: () =>
                                            _toggleDay(year, month, d),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 👇 المؤشر السفلي (العلامة المائية)
        _buildPageIndicator(monthsList.length),
      ],
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ⬇⬇⬇ الكود الذي سألت عنه يوضع هنا ⬇⬇⬇
  @override
  Widget build(BuildContext context) {
    if (_confirmed) return _buildCalendars();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _yearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'السنة'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: List.generate(12, (i) {
            final m = i + 1;
            return ChoiceChip(
              label: Text(months[i]),
              selected: _selectedMonths.contains(m),
              onSelected: (v) {
                setState(() {
                  v ? _selectedMonths.add(m) : _selectedMonths.remove(m);
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _yearController.text.isEmpty || _selectedMonths.isEmpty
              ? null
              : () {
                  setState(() => _confirmed = true);
                  widget.onConfirm(
                    PollDateConfig(
                      year: int.parse(_yearController.text),
                      months: _selectedMonths.toList(),
                    ),
                  );
                },
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}

//==========================================================

enum PollQuestionType {
  shortText,
  longText,
  checkbox,
  linearScale,
  dropdown,
  multipleChoice,
  grid,
  checkboxGrid,
  date,
  time,
  textBlock,
  imageBlock,
  videoBlock,
}

enum LinearScaleStyle { numbers, line, emoji, emoji1 }

class PollQuestion {
  PollQuestionType type;
// أضفه داخل class PollQuestion
  factory PollQuestion.fromPollData(PollData data) {
    final q = PollQuestion(data.type);
    q.questionCtrl.text = data.question;

    // options
    if (data.options.isNotEmpty) {
      q.options = data.options
          .map((o) => TextEditingController(text: o))
          .toList();
      q.selectedOptions = List.filled(q.options.length, false);
    }

    // grid
    if (data.gridRows.isNotEmpty) {
      q.gridRows = List.from(data.gridRows);
      q.gridColumns = List.from(data.gridColumns);
      q.gridConfirmed = true;
      q.initGrid();
    }

    // linearScale
    if (data.scaleStyle != null) {
      q.scaleStyle = data.scaleStyle!;
      q.scaleSize = data.scaleSize ?? 5;
      q.scaleConfirmed = true;
    }

    // date
    if (data.dateConfig != null) {
      q.dateConfig = data.dateConfig;
    }

    // time
    if (data.selectedTime != null) {
      q.selectedTime = data.selectedTime;
      q.timeController ??= TextEditingController();
    }

    return q;
  }
  // ===== عام =====
  TextEditingController questionCtrl = TextEditingController();
  bool confirmed = false;
  Key rebuildKey = UniqueKey();

  // ===== Options (checkbox / radio / dropdown) =====
  List<TextEditingController> options = [];
  List<bool> selectedOptions = []; // checkbox + multiple
  int? selectedOptionIndex;        // radio + dropdown

  // ===== Grid / CheckboxGrid =====
  List<String> gridRows = [];
  List<String> gridColumns = [];
  List<List<bool>> gridSelections = [];
  bool gridConfirmed = false;

  // ===== Date =====
  PollDateConfig? dateConfig;

  // ===== Linear Scale =====
  LinearScaleStyle scaleStyle;
  int scaleSize;
  bool scaleConfirmed;

  int? selectedNumber;
  int lineValue;
  int? selectedEmoji;
  int? selectedEmoji1;

  // ===== Time =====
  TextEditingController? timeController;
  TimeOfDay? selectedTime;

  // ================= CONSTRUCTOR =================

  PollQuestion(this.type)
      : scaleStyle = LinearScaleStyle.numbers,
        scaleSize = 5,
        scaleConfirmed = false,
        lineValue = 1 {
    if (_needsOptions(type)) {
      options = [
        TextEditingController(),
        TextEditingController(),
      ];

      selectedOptions = List.filled(options.length, false);
    }

    if (type == PollQuestionType.time) {
      timeController = TextEditingController();
    }
  }

  // ================= GRID INIT =================

  void initGrid() {
    if (gridRows.isNotEmpty && gridColumns.isNotEmpty) {
      gridSelections = List.generate(
        gridRows.length,
            (_) => List.filled(gridColumns.length, false),
      );
    }
  }

  // ================= RESET (UNDO) =================

  void reset() {
    confirmed = false;
    rebuildKey = UniqueKey();

    switch (type) {
      case PollQuestionType.linearScale:
        scaleConfirmed = false;
        selectedNumber = null;
        selectedEmoji = null;
        selectedEmoji1 = null;
        lineValue = 1;
        break;

      case PollQuestionType.grid:
      case PollQuestionType.checkboxGrid:
        gridConfirmed = false;
        initGrid();
        break;

      case PollQuestionType.checkbox:
      case PollQuestionType.multipleChoice:
        selectedOptions = List.filled(options.length, false);
        break;

      case PollQuestionType.dropdown:
        selectedOptionIndex = null;
        break;

      case PollQuestionType.time:
        selectedTime = null;
        timeController?.clear();
        break;

      case PollQuestionType.date:
        dateConfig = null;
        break;

      default:
        break;
    }
  }

  // ================= HELPERS =================

  static bool _needsOptions(PollQuestionType type) {
    return const [
      PollQuestionType.checkbox,
      PollQuestionType.dropdown,
      PollQuestionType.multipleChoice,
      PollQuestionType.grid,
      PollQuestionType.checkboxGrid,
    ].contains(type);
  }
}

enum BlockType { text, image, video }

class PostBlock {
  final BlockType type;
  final TextEditingController? textController;
  File? image;
  File? video;
  final FocusNode? focusNode;
  VideoPlayerController? videoController;

  PostBlock.text()
      : type = BlockType.text,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null;

  PostBlock.image()
      : type = BlockType.image,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null;

  PostBlock.video()
      : type = BlockType.video,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null,
        video = null,
        videoController = null;
}

Widget _placeholder({required IconData icon, required String text}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 40, color: Colors.grey),
      const SizedBox(height: 8),
      Text(text, style: const TextStyle(color: Colors.grey)),
    ],
  );
}

//=====================================================================
class PostImagesSlider extends StatefulWidget {
  final List<String> images;
  const PostImagesSlider({super.key, required this.images});

  @override
  State<PostImagesSlider> createState() => _PostImagesSliderState();
}

class _PostImagesSliderState extends State<PostImagesSlider> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ يدعم assets وfile paths معاً
  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity);
      } else {
        return Container(
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final path = widget.images[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenImageViewer(
                      images: widget.images,
                      initialIndex: index,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(path),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (widget.images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: _currentIndex == index ? 14 : 8,
                height: _currentIndex == index ? 6 : 4,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.teal[900]
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }
}
//================================================================
class VideoPreviewTile extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onRemove;

  const VideoPreviewTile({
    super.key,
    required this.controller,
    this.onRemove,
  });

  @override
  State<VideoPreviewTile> createState() => _VideoPreviewTileState();
}

class _VideoPreviewTileState extends State<VideoPreviewTile> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
    if (!widget.controller.value.isInitialized) {
      widget.controller.initialize().then((_) => setState(() {}));
    }
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      children: [
        /// الفيديو
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenVideoViewer(controller: controller),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// عرض الفيديو
                  if (controller.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: InteractiveViewer(
                          maxScale: 2.5,
                          minScale: 1.0,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  /// زر تشغيل / إيقاف
                  IconButton(
                    iconSize: 56,
                    color: Colors.white,
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle_outline,
                    ),
                    onPressed: () {
                      setState(() {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      });
                    },
                  ),

                  /// زر الحذف (اختياري)
                  if (widget.onRemove != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: widget.onRemove,
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        /// شريط التقدم (مصغّر)
        if (controller.value.isInitialized)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 4, // قصّرنا الارتفاع
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoListWidget extends StatefulWidget {
  final List<String> videoPaths;
  const _VideoListWidget({required this.videoPaths});

  @override
  State<_VideoListWidget> createState() => _VideoListWidgetState();
}

class _VideoListWidgetState extends State<_VideoListWidget> {
  late final List<VideoPlayerController> _controllers;
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controllers = widget.videoPaths.map((path) {
      final ctrl = VideoPlayerController.file(File(path))..setLooping(true);
      ctrl.initialize().then((_) {
        if (mounted) setState(() {});
      });
      return ctrl;
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _controllers.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final ctrl = _controllers[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (ctrl.value.isInitialized)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: ctrl.value.size.width,
                            height: ctrl.value.size.height,
                            child: VideoPlayer(ctrl),
                          ),
                        )
                      else
                        const CircularProgressIndicator(color: Colors.white),
                      // زر fullscreen
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullscreenVideoViewer(controller: ctrl),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // زر تشغيل / إيقاف
                      GestureDetector(
                        onTap: () => setState(() {
                          ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                        }),
                        child: AnimatedOpacity(
                          opacity: !ctrl.value.isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // شريط التقدم
        if (_controllers.isNotEmpty &&
            _controllers[_currentIndex].value.isInitialized)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: VideoProgressIndicator(
              _controllers[_currentIndex],
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.teal,
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        // نقاط المؤشر
        if (_controllers.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_controllers.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == i ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentIndex == i
                      ? Colors.teal
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
// ==================== Comments Screen ====================

class _Comment {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;
  final String? replyToAuthor;
  int votes;
  bool upvoted;
  bool downvoted;
  final List<_Comment> replies;

  _Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.replyToAuthor,
    this.votes = 0,
    this.upvoted = false,
    this.downvoted = false,
    List<_Comment>? replies,
  }) : replies = replies ?? [];

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo';
    return '${(difference.inDays / 365).floor()}y';
  }
}

class CommentsScreen extends StatefulWidget {
  final _Post post;
  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  _Comment? _replyTo;
  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
        textDirection: TextDirection.ltr, // 🔒 قفل الاتجاه نهائيًا
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Comments'),
          ),
          body: CustomScrollView(
            slivers: [
              // =======================
              // المنشور (يتحرك مع التمرير)
              // =======================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.post.body,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          if (widget.post.imagePaths.isNotEmpty)
                            PostImagesSlider(images: widget.post.imagePaths),
                          const SizedBox(height: 12),
                          Text(
                            'Posted by u/${widget.post.author} • ${_timeAgo(widget.post.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // =======================
              // قائمة التعليقات (Scrollable طبيعي)
              // =======================
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comment = widget.post.comments[index];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 12, 20),
                      child: Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardColor, // background color
                            border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey
                                      .withValues(alpha: 0.5), // border color
                                  width: 2,
                                ),
                                left: BorderSide(
                                  color: Colors.grey
                                      .withValues(alpha: 0.5), // border color
                                  width: 2,
                                ),
                                top: BorderSide(
                                  color: Colors.grey
                                      .withValues(alpha: 0.5), // border color
                                  width: 2,
                                )),
                            borderRadius: BorderRadius.circular(
                                10), // optional rounded corners
                          ),
                          child: CommentTile(
                            key: ValueKey(comment.id),
                            comment: comment,
                            depth: 0,
                            onReply: (_Comment c) {
                              setState(() {
                                _replyTo = c;
                                _commentController.text = '';
                              });
                            },
                          )),
                    );
                  },
                  childCount: widget.post.comments.length,
                ),
              ),

              // مسافة أسفل حتى لا يغطي حقل الإدخال
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // =======================
          // حقل كتابة التعليق (ثابت)
          // =======================
          bottomNavigationBar: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =======================
                  // شريط "الرد على"
                  // =======================
                  if (_replyTo != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border(
                          top: BorderSide(
                            width: 2,
                            color:
                                Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  TextSpan(
                                    text: 'u/${_replyTo!.author} : \n',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  TextSpan(text: '     ${_replyTo!.text}'),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _replyTo = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // =======================
                  // صندوق كتابة التعليق
                  // =======================
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              maxHeight: 120, // ✅ ارتفاع ثابت أقصى
                            ),
                            child: Scrollbar(
                              child: TextField(
                                controller: _commentController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                maxLines: null,
                                minLines: 1,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: _replyTo == null
                                      ? 'Add a comment...'
                                      : 'Replying to u/${_replyTo!.author}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _submitComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  // =======================
  // إضافة تعليق / رد
  // =======================
  void _submitComment() {
    final txt = _commentController.text.trim();
    if (txt.isEmpty) return;

    setState(() {
      final newComment = _Comment(
        id: UniqueKey().toString(),
        author: 'you',
        text: txt,
        createdAt: DateTime.now(),
        replyToAuthor: _replyTo?.author,
      );

      if (_replyTo != null) {
        _replyTo!.replies.insert(0, newComment);
      } else {
        widget.post.comments.insert(0, newComment);
      }

      _replyTo = null;
      _commentController.clear();
    });
  }
}

// ==================== Comment Tile ====================

class CommentTile extends StatefulWidget {
  final _Comment comment;
  final int depth;

  final void Function(_Comment) onReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.depth,
    required this.onReply,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  static const double indent = 16.0;
  static const double lineWidth = 1.1;

  bool _collapsed = false;
  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  void _upvote() {
    setState(() {
      if (widget.comment.upvoted) {
        widget.comment.upvoted = false;
        widget.comment.votes--;
      } else {
        if (widget.comment.downvoted) {
          widget.comment.downvoted = false;
          widget.comment.votes++;
        }
        widget.comment.upvoted = true;
        widget.comment.votes++;
      }
    });
  }

  void _downvote() {
    setState(() {
      if (widget.comment.downvoted) {
        widget.comment.downvoted = false;
        widget.comment.votes++;
      } else {
        if (widget.comment.upvoted) {
          widget.comment.upvoted = false;
          widget.comment.votes--;
        }
        widget.comment.downvoted = true;
        widget.comment.votes--;
      }
    });
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(S.of(context).report),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred),
              title: Text(S.of(context).blockAccount),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.follow_the_signs_sharp),
              title: Text(S.of(context).followComment),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(S.of(context).copyText),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(S.of(context).share),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final hasReplies = widget.comment.replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            // عند الضغط على التعليق الرئيسي، يتم فتح أو غلق الردود
            if (widget.comment.replies.isNotEmpty) {
              setState(() {
                _collapsed = !_collapsed;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(0),
              // boxShadow: [
              //   BoxShadow(
              //     color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              //     blurRadius: 0,
              //     offset: const Offset(0, 2),
              //   ),
              //],
            ),
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, size: 14),
                    ),
                    const SizedBox(width: 6),
                    // النص الذي يظهر اسم الكاتب أو الرد
                    Text(
                      widget.comment.replyToAuthor != null
                          ? 'u/${widget.comment.author} '
                          //'→ u/${widget.comment.replyToAuthor}'
                          : 'u/${widget.comment.author}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(width: 6),
                    Text(
                      widget.comment.timeAgo,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const Spacer(),
                    // زر الثلاث نقاط
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onPressed: () => _showMenu(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 0),

                // النص
                ExpandableText(
                  text: widget.comment.text,
                ),

                // const SizedBox(height: 6),

                // Actions
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Upvote
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color:
                            widget.comment.upvoted ? Colors.teal : Colors.grey,
                      ),
                      onPressed: _upvote,
                    ),

                    Text(
                      widget.comment.votes.toString(),
                      style: theme.textTheme.bodySmall,
                    ),

                    // Downvote
                    IconButton(
                      icon: Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color:
                            widget.comment.downvoted ? Colors.red : Colors.grey,
                      ),
                      onPressed: _downvote,
                    ),

                    const SizedBox(width: 12),

                    // Reply

                    TextButton(
                      onPressed: () => widget.onReply(widget.comment),
                      child: const Text('Reply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ===== الردود =====
        if (!_collapsed && widget.comment.replies.isNotEmpty)
          RepliesRenderer(
            replies: widget.comment.replies,
            depth: widget.depth + 1,
            onReply: widget.onReply,
          ),
      ],
    );
  }
}

class RepliesRenderer extends StatelessWidget {
  final List<_Comment> replies;
  final int depth;
  final int maxDepth;
  final void Function(_Comment) onReply;

  const RepliesRenderer({
    super.key,
    required this.replies,
    required this.depth,
    required this.onReply,
    this.maxDepth = 8,
  });

  static const double indentStep = 6.0;
  static const double replyWidthFactor = 0.95; // عرض ثابت نسبي

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final replyWidth = screenWidth * replyWidthFactor;
    final indent = depth * indentStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: replies.map((reply) {
        return Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(left: indent),
              child: SizedBox(
                width: replyWidth, // 🔴 عرض ثابت (مهم جداً)
                child: ReplyTile(
                  reply: reply,
                  depth: depth,
                  onReply: onReply,
                  maxDepth: maxDepth,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ReplyTile extends StatelessWidget {
  final _Comment reply;
  final int depth;
  final int maxDepth;
  final void Function(_Comment) onReply;

  const ReplyTile({
    super.key,
    required this.reply,
    required this.depth,
    required this.onReply,
    this.maxDepth = 1000000,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
        child: CommentTile(
          key: ValueKey(reply.id),
          comment: reply,
          depth: depth,
          onReply: onReply,
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog({super.key});

  @override
  State<_CommentDialog> createState() => __CommentDialogState();
}

class __CommentDialogState extends State<_CommentDialog> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Comment'),
      content: TextField(
        controller: _commentController,
        decoration: const InputDecoration(hintText: 'Enter your comment'),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_commentController.text.trim().isNotEmpty) {
              Navigator.pop(context, _commentController.text);
            }
          },
          child: const Text('Post'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
//================================================
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  String _normalizeNewLines(String text) {
    return text.replaceAll('\r\n', '\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // التحقق مما إذا كان النص طويل
        final span = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);
        final isOverflowing = tp.didExceedMaxLines;
        final isArabic = _isArabic(widget.text);
        final normalizedText = _normalizeNewLines(widget.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              normalizedText,
              softWrap: true, // 🔴 مهم
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              maxLines: _expanded ? null : widget.maxLines,
              overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),

              style: widget.style,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _expanded ? 'Show less' : 'Show more',
                    style: widget.style?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ) ??
                        const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
//=============================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ImagePicker _picker = ImagePicker();

  File? profileImage;
  File? coverImage;

  String userName = 'KAOSU DS';
  String email = 'kaosu@email.com';
  String mood = '🚀 Feeling motivated';

  String uni = '';
  String fac = '';
  String clas = '';
  String section = '';
  final List<String> followingUsers = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =======================
  // اختيار صورة الحساب
  // =======================
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      profileImage = File(image.path);
    });
  }

  // =======================
  // اختيار صورة الغلاف
  // =======================
  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      coverImage = File(image.path);
    });
  }

  // =======================
  // تعديل البيانات النصية
  // =======================
  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        name: userName,
        mood: mood,
        uni: uni,
        fac: fac,
        clas: clas,
        section: section,
        onSave: (n, m, u, f, c, s) {
          setState(() {
            userName = n;
            mood = m;
            uni = u;
            fac = f;
            clas = c;
            section = s;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final emailText = user?.email ?? email;

    return Scaffold(
      drawer: _buildProfileDrawer(context),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) {
          return [
            SliverAppBar(
              title: Text(S.of(context).profile),
              expandedHeight: 260,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.line_style),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editProfile,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ===== صورة الغلاف =====
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: coverImage == null
                          ? Container(
                        color: Colors.grey[400],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image,
                            size: 60, color: Colors.white),
                      )
                          : Image.file(
                        coverImage!,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // ===== التدرج =====
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.colorScheme.surface.withValues(alpha: 0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ===== الحساب متداخل =====
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              child: CircleAvatar(
                                radius: 38,
                                backgroundImage: profileImage != null
                                    ? FileImage(profileImage!)
                                    : null,
                                child: profileImage == null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                ValueListenableBuilder<UserProfileData>(
                                  valueListenable:
                                  UserProfileService.instance.notifier,
                                  builder: (context, profile, _) {
                                    return Text(
                                      profile.showEmailInProfile
                                          ? emailText
                                          : S.of(context).emailHidden,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    );
                                  },
                                ),
                                Text(mood,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: S.of(context).posts),
                Tab(text: S.of(context).comments),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UserPosts(),
                  _UserComments(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildProfileDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== رأس القائمة =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.of(context).userInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            // ===== معلومات الدراسة =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _infoRow(Icons.school, S.of(context).university, uni),
                  _infoRow(Icons.account_balance, S.of(context).faculty, fac),
                  _infoRow(Icons.apartment, S.of(context).department, clas),
                  _infoRow(Icons.menu_book, S.of(context).major, section),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 1),
            ),

            // ===== المتابعون =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                S.of(context).following,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: followingUsers.length,
                itemBuilder: (context, index) {
                  final user = followingUsers[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(user),
                    onTap: () {
                      // افتح بروفايل المستخدم
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INFO ROW =================
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String mood;
  final String uni;
  final String fac;
  final String clas;
  final String section;
  final Function(String, String, String, String, String, String) onSave;

  const _EditProfileSheet(
      {required this.name,
        required this.mood,
        required this.uni,
        required this.fac,
        required this.clas,
        required this.section,
        required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController moodCtrl;
  late TextEditingController uniCtrl;
  late TextEditingController facCtrl;
  late TextEditingController clasCtrl;
  late TextEditingController sectionCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    moodCtrl = TextEditingController(text: widget.mood);
    uniCtrl = TextEditingController(text: widget.uni);
    facCtrl = TextEditingController(text: widget.fac);
    clasCtrl = TextEditingController(text: widget.clas);
    sectionCtrl = TextEditingController(text: widget.section);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تعديل الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: S.of(context).name)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: moodCtrl,
              decoration: InputDecoration(labelText: S.of(context).mood)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: uniCtrl,
              decoration: InputDecoration(labelText: S.of(context).university)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: facCtrl,
              decoration: InputDecoration(labelText: S.of(context).faculty)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: clasCtrl,
              decoration: InputDecoration(labelText: S.of(context).department)),
          SizedBox(
            height: 15,
          ),
          TextField(
              controller: sectionCtrl,
              decoration: InputDecoration(labelText: S.of(context).major)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              widget.onSave(nameCtrl.text, moodCtrl.text, uniCtrl.text,
                  facCtrl.text, clasCtrl.text, sectionCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _UserPosts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 0,
      itemBuilder: (_, i) {
        return Card(
          child: ListTile(
            title: Text('منشور رقم ${i + 1}'),
            subtitle: const Text('هذا مثال على منشور المستخدم'),
          ),
        );
      },
    );
  }
}

class _UserComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 0,
      itemBuilder: (_, i) {
        return Card(
          child: ListTile(
            title: Text('تعليق رقم ${i + 1}'),
            subtitle: const Text('هذا مثال على تعليق المستخدم'),
          ),
        );
      },
    );
  }
}

//======================================================================
class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  Future<void> _saveImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('assets/')) {
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      } else {
        bytes = await File(path).readAsBytes();
      }
      // final result = await ImageGallerySaver.saveImage(bytes);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(result['isSuccess'] ? 'Saved to gallery!' : 'Failed to save')),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}
              //=> _saveImage(widget.images[currentIndex]),
              ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          final path = widget.images[index];
          Widget imageWidget = path.startsWith('assets/')
              ? Image.asset(path, fit: BoxFit.contain)
              : Image.file(File(path), fit: BoxFit.contain);

          return InteractiveViewer(
            maxScale: 4.0,
            minScale: 1.0,
            child: Center(
              child: imageWidget,
            ),
          );
        },
      ),
    );
  }
}

class FullscreenVideoViewer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullscreenVideoViewer({
    super.key,
    required this.controller,
  });

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: InteractiveViewer(
                  maxScale: 5.0,
                  minScale: 1.0,
                  child: VideoPlayer(widget.controller),
                ),
              ),
            ),
          ),

          // شريط التحكم
          VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            padding: const EdgeInsets.all(12),
            colors: VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.white54,
              backgroundColor: Colors.white24,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                color: Colors.white,
                icon: Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    widget.controller.value.isPlaying
                        ? widget.controller.pause()
                        : widget.controller.play();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// =========================== Calculator Hub (Quick) ==========================

class QuickAverageScreen extends StatefulWidget {
  const QuickAverageScreen({super.key});

  @override
  State<QuickAverageScreen> createState() => _QuickAverageScreenState();
}

class _QuickAverageScreenState extends State<QuickAverageScreen> {
  static const String _quickCalcStorageKey = 'quick_calc_state_v1';
  static const double _dismissThreshold = 0.4;
  final List<NoteData> subjects = [];
  double threshold = 10;
  double avg = 0;
  double totalcred = 0;
  bool _hasSavedState = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  void _add() => setState(() {
        subjects.add(NoteData(subject: ''));
      });

  void _calc() {
    double totalWeighted = 0;
    double totalCoef = 0;
    double totalCred = 0;

    for (final s in subjects) {
      final moy = s.moy;
      totalWeighted += moy * s.coef;
      totalCoef += s.coef;
      if (moy >= 10) {
        totalCred += s.cred;
      }
    }

    setState(() {
      avg = totalCoef == 0 ? 0 : totalWeighted / totalCoef;
      totalcred = totalCred;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
              'subject': s.subject,
              'coef': s.coef,
              'cred': s.cred,
              'td': s.td,
              'exam': s.exam,
              'tp': s.tp,
              'wtd': s.Wtd,
              'wexam': s.Wexam,
              'wtp': s.Wtp,
            },
          )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
    _hasSavedState = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved ✅')),
    );
  }

  Future<void> _persistStateSilently() async {
    if (!_hasSavedState) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'threshold': threshold,
      'avg': avg,
      'totalcred': totalcred,
      'isSucceeded': avg >= threshold,
      'subjects': subjects
          .map(
            (s) => <String, dynamic>{
              'subject': s.subject,
              'coef': s.coef,
              'cred': s.cred,
              'td': s.td,
              'exam': s.exam,
              'tp': s.tp,
              'wtd': s.Wtd,
              'wexam': s.Wexam,
              'wtp': s.Wtp,
            },
          )
          .toList(),
    };
    await prefs.setString(_quickCalcStorageKey, jsonEncode(payload));
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quickCalcStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    _hasSavedState = true;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final decodedSubjects = decoded['subjects'];
    final List<NoteData> loaded = [];
    if (decodedSubjects is List) {
      for (final entry in decodedSubjects) {
        if (entry is! Map) continue;
        loaded.add(
          NoteData(
            subject: entry['subject']?.toString() ?? '',
            coef: _toInt(entry['coef'], fallback: 1),
            cred: _toInt(entry['cred'], fallback: 1),
            td: _toDouble(entry['td'], fallback: 0),
            exam: _toDouble(entry['exam'], fallback: 0),
            tp: _toDouble(entry['tp'], fallback: 0),
            Wtd: _toDouble(entry['wtd'], fallback: 0.4),
            Wexam: _toDouble(entry['wexam'], fallback: 0.6),
            Wtp: _toDouble(entry['wtp'], fallback: 0),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      subjects
        ..clear()
        ..addAll(loaded);
      threshold = _toDouble(decoded['threshold'], fallback: 10);
      avg = _toDouble(decoded['avg'], fallback: 0);
      totalcred = _toDouble(decoded['totalcred'], fallback: 0);
    });
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickCalcStorageKey);
    _hasSavedState = false;
    if (!mounted) return;
    setState(() {
      subjects.clear();
      avg = 0;
      totalcred = 0;
      threshold = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared ✅')),
    );
  }

  Future<void> _removeSubjectAt(int index) async {
    final removed = subjects.removeAt(index);
    setState(() {});
    await _persistStateSilently();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            subjects.insert(index, removed);
            setState(() {});
            await _persistStateSilently();
          },
        ),
      ),
    );
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Widget _quickCalcActionButton({
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    required IconData icon,
    required String label,
    required double horizontalPadding,
  }) {
    return FilledButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).quickCalc),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...subjects.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _QuickCalcDismissibleItem(
                data: s,
                index: i,
                threshold: _dismissThreshold,
                onRemove: _removeSubjectAt,
              ),
            );
          }),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 8.0 : 12.0;
              return Row(
                children: [
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _add,
                      icon: Icons.add,
                      label: S.of(context).add,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _calc,
                      icon: Icons.calculate,
                      label: S.of(context).calculate,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickCalcActionButton(
                      onPressed: _saveState,
                      onLongPress: _clearSavedState,
                      icon: Icons.save,
                      label: S.of(context).save,
                      horizontalPadding: horizontalPadding,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: Text(
                      'Moy: ${avg.toStringAsFixed(2)}',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      avg == 0
                          ? '___'
                          : (avg >= threshold ? "✅ Succeeded" : "❌ Failed"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: avg == 0
                            ? Colors.grey
                            : (avg >= threshold ? Colors.green : Colors.red),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cred: $totalcred',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18),
                  )),
            ],
          )
        ],
      ),
    );
  }
}

// -------------------------
// بيانات البطاقة
// -------------------------
class NoteData {
  String subject;
  int coef;
  int cred;
  double td;
  double exam;
  double tp;
  double Wtd;
  double Wexam;
  double Wtp;

  NoteData({
    this.subject = '',
    this.coef = 1,
    this.cred = 1,
    this.td = 0,
    this.exam = 0,
    this.tp = 0,
    this.Wtd = 0.4,
    this.Wexam = 0.6,
    this.Wtp = 0,
  });

  double get moy => (td * Wtd + exam * Wexam + tp * Wtp);
}

class _QuickCalcDismissibleItem extends StatefulWidget {
  const _QuickCalcDismissibleItem({
    required this.data,
    required this.index,
    required this.threshold,
    required this.onRemove,
  });

  final NoteData data;
  final int index;
  final double threshold;
  final Future<void> Function(int index) onRemove;

  @override
  State<_QuickCalcDismissibleItem> createState() =>
      _QuickCalcDismissibleItemState();
}

class _QuickCalcDismissibleItemState extends State<_QuickCalcDismissibleItem> {
  double _progress = 0;
  bool _hapticTriggered = false;

  void _handleUpdate(DismissUpdateDetails details) {
    final progress = details.progress.clamp(0.0, 1.0);
    if (progress >= widget.threshold && !_hapticTriggered) {
      HapticFeedback.lightImpact();
      _hapticTriggered = true;
    }
    if (progress < widget.threshold && _hapticTriggered) {
      _hapticTriggered = false;
    }
    if (_progress != progress) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<bool> _confirmDismiss() async {
    return _progress >= widget.threshold;
  }

  @override
  Widget build(BuildContext context) {
    final ambientDirection = Directionality.of(context);
    final eased = Curves.easeOut.transform(_progress);
    final backgroundColor = Color.lerp(
      Colors.red.withValues(alpha: 0.08),
      Colors.red.shade600,
      eased,
    )!;
    final iconScale = 0.9 + (0.2 * eased);

    final dismissBackground = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor.withValues(alpha: 0.9),
              backgroundColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: iconScale,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dismissible(
        key: ValueKey(widget.data),
        direction: DismissDirection.startToEnd,
        movementDuration: const Duration(milliseconds: 220),
        resizeDuration: const Duration(milliseconds: 200),
        dismissThresholds: {DismissDirection.startToEnd: widget.threshold},
        background: dismissBackground,
        confirmDismiss: (_) => _confirmDismiss(),
        onUpdate: _handleUpdate,
        onDismissed: (_) => widget.onRemove(widget.index),
        child: Directionality(
          textDirection: ambientDirection,
          child: NoteCardWidget(
            data: widget.data,
          ),
        ),
      ),
    );
  }
}

// -------------------------
// واجهة البطاقة
// -------------------------
class NoteCardWidget extends StatefulWidget {
  final NoteData data;

  const NoteCardWidget({
    super.key,
    required this.data,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  late TextEditingController nameController;
  late TextEditingController coefController;
  late TextEditingController credController;
  late TextEditingController tdController;
  late TextEditingController tpController;
  late TextEditingController WtdController;
  late TextEditingController WtpController;
  late TextEditingController WexamController;
  late TextEditingController examController;

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.subject);
    coefController = TextEditingController(text: widget.data.coef.toString());
    credController = TextEditingController(text: widget.data.cred.toString());
    tdController = TextEditingController(
        text: widget.data.td == 0 ? '' : widget.data.td.toString());
    examController = TextEditingController(
        text: widget.data.exam == 0 ? '' : widget.data.exam.toString());
    tpController = TextEditingController(
        text: widget.data.tp == 0 ? '' : widget.data.tp.toString());
    WexamController = TextEditingController(text: widget.data.Wexam.toString());
    WtdController = TextEditingController(text: widget.data.Wtd.toString());
    WtpController = TextEditingController(text: widget.data.Wtp.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      child: Column(
        children: [
          // Header: Delete, Subject Name, Moy
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: nameController,
                    onChanged: (v) {
                      widget.data.subject = v;
                      setState(() {});
                    },
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.data.moy.toStringAsFixed(2),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                icon: Icon(expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              )
            ],
          ),
          if (expanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coef & Cred أولاً
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //coef
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text("Coef"),
                            TextField(
                              controller: coefController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (v) {
                                widget.data.coef = int.tryParse(v) ?? 1;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      //cred
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            const Text("Cred"),
                            TextField(
                              controller: credController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                              decoration: const InputDecoration(
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (v) {
                                widget.data.cred = int.tryParse(v) ?? 1;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 180,
                  width: 1,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      // wTD / wTP / wExam
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildScoreField("W.TD", WtdController, (v) {
                              widget.data.Wtd = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("W.TP", WtpController, (v) {
                              widget.data.Wtp = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("W.EX", WexamController, (v) {
                              widget.data.Wexam = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // TD / TP / Exam
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildScoreField("TD", tdController, (v) {
                              widget.data.td = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("TP", tpController, (v) {
                              widget.data.tp = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                            const SizedBox(height: 5),
                            Container(
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                              width: double.infinity,
                            ),
                            _buildScoreField("Exam", examController, (v) {
                              widget.data.exam = double.tryParse(v) ?? 0;
                              setState(() {});
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller,
      Function(String) onChange) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (v) => onChange(v),
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== GPA Table Data Model (public) ========================
class EvalWeight {
  final String label;
  final double weight;
  const EvalWeight({required this.label, required this.weight});
}

class ModuleSpec {
  final String id;
  final String name;
  final double coef;
  final double credits;
  final List<EvalWeight> evalWeights;
  const ModuleSpec({
    required this.id,
    required this.name,
    required this.coef,
    required this.credits,
    required this.evalWeights,
  });

  double get totalWeight =>
      evalWeights.fold<double>(0, (sum, item) => sum + item.weight);
}

class SemesterSpec {
  final String name;
  final List<ModuleSpec> modules;
  const SemesterSpec({required this.name, required this.modules});
}

List<SemesterSpec> createSemesterSpecsForTrack(ProgramTrack track) {
  return track.semesters.asMap().entries.map(
    (semEntry) {
      final semIndex = semEntry.key;
      final sem = semEntry.value;
      // جمع كل modules من كل الوحدات داخل السداسي
      final allModules =
          sem.unit.expand((u) => u.modules).toList(growable: false);

      return SemesterSpec(
        name: sem.label,
        modules: allModules
            .asMap()
            .entries
            .map(
              (moduleEntry) {
                final moduleIndex = moduleEntry.key;
                final module = moduleEntry.value;
                return ModuleSpec(
                  id: 'sem${semIndex + 1}-module${moduleIndex + 1}',
                  name: module.name,
                  coef: module.coef.toDouble(),
                  credits: module.credits.toDouble(),
                  evalWeights: _normalizeEvalWeights(module.components),
                );
              },
            )
            .toList(growable: false),
      );
    },
  ).toList(growable: false);
}

List<SemesterSpec> demoL1GpaSpecs(BuildContext context) {
  final track = getDemoFaculties(context).first.majors.first.tracks.first;

  return createSemesterSpecsForTrack(track);
}

List<EvalWeight> _normalizeEvalWeights(List<ProgramComponent> components) {
  final Map<String, double> weights = {
    'TD': 0,
    'TP': 0,
    'EXAM': 0,
  };
  for (final c in components) {
    final key = c.label.toUpperCase();
    if (weights.containsKey(key)) {
      weights[key] = c.weight;
    }
  }
  return [
    EvalWeight(label: 'TD', weight: weights['TD']!),
    EvalWeight(label: 'TP', weight: weights['TP']!),
    EvalWeight(label: 'EXAM', weight: weights['EXAM']!),
  ];
}

String _slugifyModuleId(String value) {
  final slug = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isNotEmpty) {
    return slug;
  }
  final encoded = base64UrlEncode(utf8.encode(value));
  return encoded.replaceAll('=', '');
}

String _moduleIdForSemester(String semester, String moduleName) {
  final normalizedSemester = semester.trim().toUpperCase();
  final normalizedModule = moduleName.trim();
  return _slugifyModuleId('$normalizedSemester-$normalizedModule');
}

String buildAcademicStorageSignature({
  required SemesterSpec semester1,
  required SemesterSpec semester2,
  required String level,
}) {
  String moduleFingerprint(ModuleSpec module) {
    final weights = module.evalWeights
        .map((weight) => '${weight.label.toUpperCase()}:${weight.weight}')
        .join('|');
    return '${module.name.trim()}#${module.coef}#${module.credits}#$weights';
  }

  String semesterFingerprint(SemesterSpec semester) {
    final modules = semester.modules
        .map(moduleFingerprint)
        .join('||');
    return '${semester.name.trim().toUpperCase()}::${modules}';
  }

  final raw = [
    level.trim().toUpperCase(),
    semesterFingerprint(semester1),
    semesterFingerprint(semester2),
  ].join('###');

  return base64UrlEncode(utf8.encode(raw)).replaceAll('=', '');
}

class ModuleModel {
  ModuleModel({
    required this.id,
    required this.title,
    required num coef,
    required num credits,
    required double tdWeight,
    required double tpWeight,
    required double examWeight,
  })  : coef = coef.toDouble(),
        credits = credits.toDouble(),
        _hasTD = tdWeight > 0,
        _hasTP = tpWeight > 0,
        wTD = tdWeight / 100,
        wTP = tpWeight / 100,
        wEX = examWeight / 100,
        td = 0,
        tp = 0,
        exam = 0;

  final String id;
  final String title;
  double coef;
  double credits;
  final bool _hasTD;
  final bool _hasTP;
  double wTD;
  double wTP;
  double wEX;
  double? td;
  double? tp;
  double? exam;
  double? tdWeight = 0.4;
  double? tpWeight = 0;
  double? examWeight = 0.6;

  bool get hasTD => _hasTD;
  bool get hasTP => _hasTP;

  double get moy {
    final totalW = wTD + wTP + wEX; // مجموع الأوزان
    if (totalW <= 0) return 0;

    double normalize(double weight) => weight / totalW;

    final value = (td ?? 0) * normalize(wTD) +
        (tp ?? 0) * normalize(wTP) +
        (exam ?? 0) * normalize(wEX);

    return double.parse(value.toStringAsFixed(2));
  }
}

class SemesterModel {
  SemesterModel({
    required this.name,
    required this.modules,
    required VoidCallback onChanged,
  }) : _onChanged = onChanged;

  factory SemesterModel.fromSpec(
    SemesterSpec spec, {
    required VoidCallback onChanged,
  }) {
    final modules = spec.modules.map((module) {
      double weightFor(String label) {
        return module.evalWeights
            .firstWhere(
              (w) => w.label.toUpperCase() == label,
              orElse: () => const EvalWeight(label: 'TMP', weight: 0),
            )
            .weight;
      }

      return ModuleModel(
        id: module.id.trim().isNotEmpty
            ? module.id
            : _moduleIdForSemester(spec.name, module.name),
        title: module.name,
        coef: module.coef,
        credits: module.credits,
        tdWeight: weightFor('TD'),
        tpWeight: weightFor('TP'),
        examWeight: weightFor('EXAM'),
      );
    }).toList(growable: false);

    return SemesterModel(
        name: spec.name, modules: modules, onChanged: onChanged);
  }

  final String name;
  final List<ModuleModel> modules;
  final VoidCallback _onChanged;

  void recompute() => _onChanged();

  double moduleAverage(ModuleModel module) {
    return module.moy;
  }

  double moduleCreditsEarned(ModuleModel module) {
    final avg = moduleAverage(module);
    return avg >= 10 ? module.credits : 0;
  }

  double semesterAverage() {
    double weighted = 0;
    double coefs = 0;
    for (final module in modules) {
      weighted += moduleAverage(module) * module.coef;
      coefs += module.coef;
    }
    if (coefs == 0) {
      return 0;
    }
    final value = weighted / coefs;
    return double.parse(value.toStringAsFixed(2));
  }

  double creditsEarned() {
    return modules.fold<double>(
        0, (sum, module) => sum + moduleCreditsEarned(module));
  }

  SemesterModel convertProgramSemester(
    ProgramSemester ps,
    VoidCallback onChanged,
  ) {
    final allModules =
        ps.unit.expand((u) => u.modules).toList(growable: false);
    return SemesterModel(
      name: ps.label,
      onChanged: onChanged,
      modules: allModules.asMap().entries.map((entry) {
        final moduleIndex = entry.key;
        final m = entry.value;
        // تحويل ProgramComponent إلى أوزان TD/TP/EXAM
        double td = 0;
        double tp = 0;
        double exam = 0;

        for (var c in m.components) {
          if (c.label.toUpperCase() == 'TD') td = c.weight.toDouble();
          if (c.label.toUpperCase() == 'TP') tp = c.weight.toDouble();
          if (c.label.toUpperCase() == 'EXAM') exam = c.weight.toDouble();
        }

        return ModuleModel(
          id: 'sem${ps.label.trim().toUpperCase()}-module${moduleIndex + 1}',
          title: m.name,
          coef: m.coef,
          credits: m.credits,
          tdWeight: td,
          tpWeight: tp,
          examWeight: exam,
        );
      }).toList(),
    );
  }
}

// ---------- Table helpers ----------
class DecimalSanitizer extends TextInputFormatter {
  DecimalSanitizer({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final sanitized = newValue.text.replaceAll(',', '.');
    final pattern = decimalPlaces > 0
        ? RegExp(r'^\d*([.]\d{0,' + decimalPlaces.toString() + r'})?$')
        : RegExp(r'^\d*$');
    if (sanitized.isEmpty || pattern.hasMatch(sanitized)) {
      return newValue.copyWith(text: sanitized);
    }
    return oldValue;
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.value,
    required this.onChanged,
    this.width = 64,
    this.decimalPlaces = 2,
    this.inputRangePattern,
  });

  final double? value;
  final ValueChanged<double?> onChanged;
  final double width;
  final int decimalPlaces;
  final RegExp? inputRangePattern;

  @override
  Widget build(BuildContext context) {
    final initial = value == null ? '' : value!.toStringAsFixed(decimalPlaces);
    return SizedBox(
      width: width,
      child: TextFormField(
        textAlign: TextAlign.center,
        initialValue: initial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        ),
        inputFormatters: [
          DecimalSanitizer(decimalPlaces: decimalPlaces),
          if (inputRangePattern != null)
            FilteringTextInputFormatter.allow(inputRangePattern!),
        ],
        onChanged: (s) {
          final sanitized = s.replaceAll(',', '.');
          if (sanitized.isEmpty) {
            onChanged(null);
            return;
          }
          final parsed = double.tryParse(sanitized);
          if (parsed == null) {
            return;
          }
          onChanged(parsed);
        },
      ),
    );
  }
}

// Compact text widget that never wraps:
Widget _cell(String s, {bool bold = false, bool center = false}) => Text(
      s,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
    );
// -----------------------------------

SemesterSpec _pickSemester(List<SemesterSpec> specs, String label) {
  final normalizedLabel = label.toUpperCase();
  if (specs.isEmpty) {
    return const SemesterSpec(name: 'S?', modules: []);
  }
  return specs.firstWhere(
    (s) => s.name.toUpperCase() == normalizedLabel,
    orElse: () {
      if (normalizedLabel == 'S1') {
        return specs.first;
      }
      if (normalizedLabel == 'S2' && specs.length > 1) {
        return specs.last;
      }
      return specs.first;
    },
  );
}

// ================================ UI: Faculties ==============================
class FacultiesScreen extends StatelessWidget {
  final List<ProgramFaculty> faculties;
  const FacultiesScreen({super.key, required this.faculties});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(S.of(context).faculties),
      ),
      padding: EdgeInsets.zero,
      body: ListView.separated(
        itemCount: faculties.length,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final f = faculties[i];
          final theme = Theme.of(context);
          final majorsCount = f.majors.length;
          final subtitleText = majorsCount == 0
              ? S.of(context).noMajorsYet
              : majorsCount == 1
                  ? S.of(context).oneMajor
                  : '$majorsCount تخصصات';
          return Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceVariant
                .withValues(alpha: theme.brightness == Brightness.dark ? .35 : .6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FacultyMajorsScreen(faculty: f)),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.apartment_rounded),
                ),
                title: Text(f.name),
                subtitle: Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================== UI: Majors =================================
class FacultyMajorsScreen extends StatelessWidget {
  final ProgramFaculty faculty;
  const FacultyMajorsScreen({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppScaffold(
      appBar:
          AppBar(automaticallyImplyLeading: true, title: Text(faculty.name)),
      //endDrawer: const AppEndDrawer(),
      padding: EdgeInsets.zero,
      body: ListView.separated(
        itemCount: faculty.majors.length,
        separatorBuilder: (_, __) => const Divider(height: 5),
        itemBuilder: (_, i) {
          final m = faculty.majors[i];
          return ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(m.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MajorTracksScreen(
                    major: m,
                    faculty: faculty,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =============================== UI: Tracks =================================
class MajorTracksScreen extends StatelessWidget {
  final ProgramMajor major;
  final ProgramFaculty faculty;

  const MajorTracksScreen({
    super.key,
    required this.major,
    required this.faculty,
  });

  @override
  Widget build(BuildContext context) {
    // تجميع التراكات حسب المستوى
    final Map<String, List<ProgramTrack>> tracksByLevel = {};
    for (var track in major.tracks) {
      tracksByLevel.putIfAbsent(track.level, () => []).add(track);
    }

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            major.name,
          )),
     // endDrawer: const AppEndDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...tracksByLevel.entries.map((entry) {
            final level = entry.key;
            final tracks = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child:
                        // عنوان المستوى
                        Text(
                      level,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    )),

                const SizedBox(height: 12),

                // قائمة التخصصات داخل المستوى مع فاصل بين كل عنصر
                ...tracks.map((track) {
                  return Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: .4),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.view_stream_outlined),
                          title: Text(track.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final specs = createSemesterSpecsForTrack(track);
                            final sem1 = _pickSemester(specs, 'S1');
                            final sem2 = _pickSemester(specs, 'S2');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudiesTableScreen(
                                  facultyName: track.name,
                                  programName: '${major.name} • ${track.name}',
                                  collegeId: faculty.name,
                                  departmentId: major.name,
                                  specialtyId: track.name,
                                  level: track.level,
                                  academicScopeId: buildAcademicStorageSignature(
                                    semester1: sem1,
                                    semester2: sem2,
                                    level: track.level,
                                  ),
                                  semester1Modules: sem1,
                                  semester2Modules: sem2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // الفاصل بين التخصصات
                      const SizedBox(height: 14),
                    ],
                  );
                }).toList(),

                // فاصل بين المستويات
                const SizedBox(height: 25),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ========================== UI: Studies GPA Table ============================
class StudiesTableScreen extends StatefulWidget {
  final String facultyName;
  final String programName;
  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;
  final SemesterSpec semester1Modules;
  final SemesterSpec semester2Modules;

  const StudiesTableScreen({
    super.key,
    required this.facultyName,
    required this.programName,
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
    required this.semester1Modules,
    required this.semester2Modules,
  });

  @override
  State<StudiesTableScreen> createState() => _StudiesTableScreenState();
}

class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم لمنع ضياع الحالة
    return widget.child;
  }
}

class _StudiesTableScreenState extends State<StudiesTableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late SemesterModel _semester1;
  late SemesterModel _semester2;
  late GradesLocalStore _gradesStore;
  final Set<String> _loadedModuleStates = {};

  int currentIndex = 0; // ← هذا يمثل index الحالي

  @override
  void initState() {
    super.initState();
    _initializeGradesStore();
    _tabController = TabController(length: 2, vsync: this);
    _initSemesters();
    Future.microtask(() async {
      await loadSemesterNotes();
    });

    // الاستماع لتغييرات الـ index عند التمرير أو الضغط على الـ Tab
    _tabController.addListener(() {
      if (_tabController.index == currentIndex) return;
      setState(() {
        currentIndex = _tabController.index;
      });
      Future.microtask(() async {
        await loadSemesterNotes();
      });
    });
  }

  void _initializeGradesStore() {
    _gradesStore = GradesLocalStore(
      scope: GradesStorageScope(
        collegeId: widget.collegeId,
        departmentId: widget.departmentId,
        specialtyId: widget.specialtyId,
        level: widget.level,
        academicScopeId: widget.academicScopeId,
      ),
    );
  }


  void _initSemesters() {
    _semester1 = SemesterModel.fromSpec(
      widget.semester1Modules,
      onChanged: () => setState(() {}),
    );
    _semester2 = SemesterModel.fromSpec(
      widget.semester2Modules,
      onChanged: () => setState(() {}),
    );
  }
  // Regression checklist (manual):
  // 1) Edit grades/coef/cred/weights in Department A + Specialty X, then Save.
  // 2) Open Department B + Specialty Y (same level/semester/module names) => values must remain unchanged.
  // 3) Return to Department A + Specialty X => edited values must persist.
  // 4) First load with old global data migrates once into scoped storage, then reads scoped keys only.
  /// ==================== حفظ بيانات الفصل الحالي باستخدام SharedPreferences ====================
  Future<void> saveCurrentSemesterNotes() async {
    debugPrint('SAVE_CLICKED');
    FocusScope.of(context).unfocus(); // ← يفرض إنهاء تحرير أي TextField

    final currentSemester =
        _tabController.index == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    for (final module in currentSemester.modules) {
      debugPrint(
        'SAVE_PAYLOAD semesterKey=$semesterKey moduleId=${module.id} '
        'cred=${module.credits} coef=${module.coef} td=${module.td} '
        'exam=${module.exam} tp=${module.tp} '
        'wTd=${module.wTD} wExam=${module.wEX} wTp=${module.wTP}',
      );
    }
    try {
      await _gradesStore.saveModuleStates(
        semesterKey,
        currentSemester.modules,
      );
      final readBack = await _gradesStore.loadModuleStates(semesterKey);
      debugPrint(
        'SAVE_READBACK semesterKey=$semesterKey data=${jsonEncode(readBack)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved")),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('SAVE_ERROR semesterKey=$semesterKey error=$error');
      debugPrint('SAVE_STACK $stackTrace');
    }
  }

  /// ==================== تحميل بيانات الفصل الحالي من SharedPreferences ====================
  Future<void> loadSemesterNotes() async {
    final currentSemester =
        _tabController.index == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name.trim().toUpperCase();
    debugPrint('LOAD_START semesterKey=$semesterKey');
    final overrides = await _gradesStore.loadModuleStates(semesterKey);
    debugPrint(
      'LOAD_OVERRIDES semesterKey=$semesterKey data=${jsonEncode(overrides)}',
    );
    if (overrides.isEmpty) {
      debugPrint(
        'LOAD_DEFAULT semesterKey=$semesterKey reason=no_saved_data',
      );
    }

    var updated = false;
    if (!_loadedModuleStates.contains(semesterKey)) {
      for (final module in currentSemester.modules) {
        final moduleOverride = overrides[module.id];
        if (moduleOverride == null) {
          debugPrint(
            'LOAD_DEFAULT semesterKey=$semesterKey moduleId=${module.id} '
            'reason=missing_override',
          );
          continue;
        }
        module.coef = moduleOverride['coef']?.toDouble() ?? module.coef;
        module.credits = moduleOverride['cred']?.toDouble() ?? module.credits;
        module.td = moduleOverride['td'] ?? module.td;
        module.tp = moduleOverride['tp'] ?? module.tp;
        module.exam = moduleOverride['exam'] ?? module.exam;
        module.wTD = moduleOverride['wTD'] ?? module.wTD;
        module.wEX = moduleOverride['wEX'] ?? module.wEX;
        module.wTP = moduleOverride['wTP'] ?? module.wTP;
        updated = true;
      }
      _loadedModuleStates.add(semesterKey);
    }

    if (mounted && updated) setState(() {});
  }





  @override
  void didUpdateWidget(covariant StudiesTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trackChanged = oldWidget.collegeId != widget.collegeId ||
        oldWidget.departmentId != widget.departmentId ||
        oldWidget.specialtyId != widget.specialtyId ||
        oldWidget.level != widget.level;
    final modulesChanged = oldWidget.semester1Modules != widget.semester1Modules ||
        oldWidget.semester2Modules != widget.semester2Modules;
    if (trackChanged || modulesChanged) {
      if (trackChanged) {
        _initializeGradesStore();
      }
      _initSemesters();
      _loadedModuleStates.clear();
      Future.microtask(() async {
        await loadSemesterNotes();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Widget _buildSemesterTabContent(SemesterModel semester) {
    return Builder(
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        const summaryPadding = 220.0;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            //key: ValueKey('${semester.name}_${semester.modules.length}'),
            padding: EdgeInsets.fromLTRB(0, 8, 0, bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // محتوى الجدول الخاص بالفصل
                buildSemesterTable(context, semester),

                const SizedBox(height: 16),

                // بطاقة الملخص السنوي داخل التمرير
                if (_tabController.index == 0)
                  _AnnualSummaryCard(
                    semester1: _semester1,
                    semester2: _semester2,
                    showS1: true,
                    showS2: false,
                    showAnnual: false,
                  ),
                if (_tabController.index == 1)
                  _AnnualSummaryCard(
                    semester1: _semester1,
                    semester2: _semester2,
                    showS1: false,
                    showS2: true,
                    showAnnual: true,
                  )
              ],
            ),
          ),
        );
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    final sem1 = _semester1;
    final sem2 = _semester2;
    final canPop = Navigator.canPop(context);

    return AppScaffold(

        body:
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                expandedHeight: 50,
                actionsIconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurface
                    ,size: 15
                ),
                flexibleSpace:
                FlexibleSpaceBar(
                    background: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 0, vertical: 1),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 45),
                              // النص طويل
                              Expanded(
                                child: Text(
                                  widget.facultyName+' :',
                                  style: TextStyle(fontSize: 20,
                                      color: Theme.of(context).colorScheme.onSurface),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // زر الحفظ
                              IconButton(
                                icon: Icon(Icons.save, color: Theme.of(context).colorScheme.onSurface ),
                                onPressed: saveCurrentSemesterNotes,
                                tooltip: "Save current semester",
                                iconSize:  25,
                              ),
                              IconButton(
                                icon:  Icon(Icons.insert_drive_file_rounded,
                                    color: Theme.of(context).colorScheme.onSurface),
                                iconSize: 25,
                                tooltip: "Download as PDF",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(
                                        semester1: _semester1,
                                        semester2: _semester2,
                                        programLabel: '${widget.programName}',
                                      ),
                                    ),
                                  );
                                },
                              )

                            ]
                        )
                    )
                )
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'S1'),
                    Tab(text: 'S2'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _KeepAlive(child: _buildSemesterTabContent(sem1)),
              _KeepAlive(child: _buildSemesterTabContent(sem2)),
            ],
          ),
        )
    );
  }
}

class GradesStorageScope {
  const GradesStorageScope({
    required this.collegeId,
    required this.departmentId,
    required this.specialtyId,
    required this.level,
    required this.academicScopeId,
  });

  final String collegeId;
  final String departmentId;
  final String specialtyId;
  final String level;
  final String academicScopeId;

  String _sanitize(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    // Keep non-latin identifiers stable (e.g. Arabic) to avoid collisions
    // across tracks that would otherwise be reduced to empty/unknown values.
    return Uri.encodeComponent(normalized);
  }

  String get storageKey {
    final scope = _sanitize(academicScopeId);
    if (scope.isNotEmpty) {
      return 'scope__$scope';
    }

    // Fallback for safety in case the new scope id is missing unexpectedly.
    final lvl = _sanitize(level);
    return [
      'scope__legacy',
      if (lvl.isNotEmpty) lvl else 'unknown_level',
    ].join('__');
  }
}

class GradesLocalStore {
  static const bool _debugGradeStorageKeys = false;
  static const String _globalStorageKey = 'unispace_grades_v1';
  static const String _modulesStoragePrefix = 'modules_';
  static const String _scopedStoragePrefix = 'unispace_grades_v2_';

  GradesLocalStore({required this.scope});

  final GradesStorageScope scope;

  String get _storageKey => '$_scopedStoragePrefix${scope.storageKey}';

  String _normalizeSemesterKey(String semester) {
    return semester.trim().toUpperCase();
  }

  String _entryKey(String semester, String moduleId) {
    final normalizedSemester = _normalizeSemesterKey(semester);
    return '$normalizedSemester|$moduleId';
  }

  String _legacyModulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix$normalizedSemester';
  }

  String _modulesKey(String semester) {
    final normalizedSemester = _normalizeSemesterKey(semester).toLowerCase();
    return '$_modulesStoragePrefix${scope.storageKey}_$normalizedSemester';
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_ALL key=$_storageKey');
    }
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _loadLegacyGlobalAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_globalStorageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_ALL key=$_storageKey entries=${data.length}');
    }
    try {
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (error, stackTrace) {
      debugPrint('SAVE_ALL_ERROR error=$error');
      debugPrint('SAVE_ALL_STACK $stackTrace');
      rethrow;
    }
  }


  Future<void> _migrateLegacyGradeEntryIfNeeded(
    String semester,
    String moduleId,
  ) async {
    final scoped = await _loadAll();
    final key = _entryKey(semester, moduleId);
    if (scoped.containsKey(key)) {
      return;
    }
    final legacy = await _loadLegacyGlobalAll();
    final legacyEntry = legacy[key];
    if (legacyEntry == null) {
      return;
    }
    scoped[key] = legacyEntry;
    await _saveAll(scoped);
  }

  Future<void> _migrateLegacyModulesIfNeeded(String semester) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _modulesKey(semester);
    final scopedRaw = prefs.getString(scopedKey);
    if (scopedRaw != null && scopedRaw.isNotEmpty) {
      return;
    }

    final legacyKey = _legacyModulesKey(semester);
    final legacyRaw = prefs.getString(legacyKey);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      await prefs.setString(scopedKey, legacyRaw);
      return;
    }

    final legacyGlobal = await _loadLegacyGlobalAll();
    final normalizedSemester = _normalizeSemesterKey(semester);
    final migratedPayload = <Map<String, dynamic>>[];
    for (final entry in legacyGlobal.entries) {
      final key = entry.key;
      if (!key.startsWith('$normalizedSemester|')) continue;
      final data = entry.value;
      if (data is! Map) continue;
      final moduleId = key.substring('$normalizedSemester|'.length);
      if (moduleId.isEmpty) continue;
      migratedPayload.add({
        'moduleId': moduleId,
        'moduleName': null,
        'semester': semester,
        'coef': data['coef'],
        'cred': data['cred'],
        'td': data['td'],
        'tp': data['tp'],
        'exam': data['exam'],
        'moy': data['moy'],
        'wTD': data['wTD'],
        'wEX': data['wEX'],
        'wTP': data['wTP'],
      });
    }
    if (migratedPayload.isNotEmpty) {
      await prefs.setString(scopedKey, jsonEncode(migratedPayload));
    }
  }

  Future<Map<String, double?>?> loadGrade(
      String semester,
      String moduleId,
      ) async {
    await _migrateLegacyGradeEntryIfNeeded(semester, moduleId);
    final all = await _loadAll();
    final entryKey = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_LOAD_GRADE key=$_storageKey entry=$entryKey');
    }
    final entry = all[entryKey];
    if (entry is! Map) {
      return null;
    }
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return {
      'td': toDouble(entry['td']),
      'exam': toDouble(entry['exam']),
      'tp': toDouble(entry['tp']),
      'moy': toDouble(entry['moy']),
      'coef': toDouble(entry['coef']),
      'cred': toDouble(entry['cred']),
      'wTD': toDouble(entry['wTD']),
      'wEX': toDouble(entry['wEX']),
      'wTP': toDouble(entry['wTP']),
    };

  }

  Future<void> saveGrade(
      String semester,
      String moduleId,
      double? td,
      double? exam,
      double? tp,
      double? moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP,
      ) async {
    final all = await _loadAll();

    final hasValues =
        td != null ||
            exam != null ||
            tp != null ||
            moy != null ||
            coef != 0 ||
            cred != 0;

    final key = _entryKey(semester, moduleId);
    if (_debugGradeStorageKeys) {
      debugPrint('GRADES_SAVE_GRADE key=$_storageKey entry=$key');
    }

    if (!hasValues) {
      all.remove(key);
      try {
        await _saveAll(all);
      } catch (error, stackTrace) {
        debugPrint('SAVE_GRADE_REMOVE_ERROR key=$key error=$error');
        debugPrint('SAVE_GRADE_REMOVE_STACK $stackTrace');
        rethrow;
      }
      return;
    }

    all[key] = <String, dynamic>{
      'td': td,
      'exam': exam,
      'tp': tp,
      'moy': moy,
      'coef': coef,
      'cred': cred,
      'wTD': wTD,
      'wEX': wEX,
      'wTP': wTP,
    };

    try {
      await _saveAll(all);
    } catch (error, stackTrace) {
      debugPrint('SAVE_GRADE_ERROR key=$key error=$error');
      debugPrint('SAVE_GRADE_STACK $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> loadModuleStates(
      String semester) async {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final Map<String, Map<String, dynamic>> states = {};
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyModulesIfNeeded(semester);
    final modulesKey = _modulesKey(semester);
    final raw = prefs.getString(modulesKey);
    debugPrint('LOAD_MODULES_RAW key=$modulesKey raw=$raw');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        debugPrint(
          'LOAD_MODULES_PARSED key=$modulesKey payload=${jsonEncode(decoded)}',
        );
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is! Map) continue;
            final id = entry['moduleId']?.toString() ?? entry['id']?.toString();
            if (id == null || id.isEmpty) continue;
            states[id] = {
              'moduleId': id,
              'moduleName': entry['moduleName']?.toString() ??
                  entry['name']?.toString(),
              'semester': entry['semester']?.toString() ?? semester,
              'coef': toDouble(entry['coef']),
              'cred': toDouble(entry['cred']),
              'td': toDouble(entry['td']),
              'tp': toDouble(entry['tp']),
              'exam': toDouble(entry['exam']),
              'moy': toDouble(entry['moy']),
              'wTD': toDouble(entry['wTD']),
              'wEX': toDouble(entry['wEX']),
              'wTP': toDouble(entry['wTP']),
            };
          }
        }
      } catch (error, stackTrace) {
        debugPrint('LOAD_MODULES_ERROR key=$modulesKey error=$error');
        debugPrint('LOAD_MODULES_STACK $stackTrace');
      }
    }

    return states;
  }

  Future<void> saveModuleStates(
      String semester, List<ModuleModel> modules) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = modules
        .map(
          (module) {
            final hasValues =
                module.td != null || module.tp != null || module.exam != null;
            final moy = hasValues ? module.moy : null;
            return <String, dynamic>{
              'moduleId': module.id,
              'moduleName': module.title,
              'semester': semester,
              'coef': module.coef,
              'cred': module.credits,
              'td': module.td,
              'tp': module.tp,
              'exam': module.exam,
              'moy': moy,
              'wTD': module.wTD,
              'wEX': module.wEX,
              'wTP': module.wTP,
            };
          },
        )
        .toList(growable: false);
    final modulesKey = _modulesKey(semester);
    debugPrint(
      'SAVE_MODULES key=$modulesKey payload=${jsonEncode(payload)}',
    );
    try {
      await prefs.setString(modulesKey, jsonEncode(payload));
    } catch (error, stackTrace) {
      debugPrint('SAVE_MODULES_ERROR key=$modulesKey error=$error');
      debugPrint('SAVE_MODULES_STACK $stackTrace');
      rethrow;
    }
    final readBack = prefs.getString(modulesKey);
    debugPrint('SAVE_MODULES_READBACK key=$modulesKey raw=$readBack');
  }

  Future<void> clearGrade(String semester, String moduleId) async {
    final all = await _loadAll();
    all.remove(_entryKey(semester, moduleId));
    await _saveAll(all);
  }
}

Widget buildSemesterTable(BuildContext context, SemesterModel sem) {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: SingleChildScrollView(
      child: Column(
        children: sem.modules.map((module) {
          return Column(
            children: [
              NoteCard(
                coef: module.coef,
                cred: module.credits,
                subject: module.title,
                wTD: module.wTD,
                wEX: module.wEX,
                wTP: module.wTP,

                initialTd: module.td == 0 ? null : module.td,
                initialTp: module.tp == 0 ? null : module.tp,
                initialExam: module.exam == 0 ? null : module.exam,

                onChanged: (td, tp, exam, moy, coef, cred, wTD, wEX, wTP) {
                  module.td = td ?? 0;
                  module.tp = tp ?? 0;
                  module.exam = exam ?? 0;

                  module.coef = coef;
                  module.credits = cred;

                  module.wTD = wTD;
                  module.wEX = wEX;
                  module.wTP = wTP;

                  sem.recompute();
                  (context as Element).markNeedsBuild();
                },

              ),

              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    ),
  );
}

/// بطاقة المادة NoteCard
class NoteCard extends StatefulWidget {
  final double coef;
  final double cred;
  final String subject;
  final double wTD;
  final double wEX;
  final double wTP;
  final double? initialTd;
  final double? initialTp;
  final double? initialExam;
  final Function(
      double? td,
      double? tp,
      double? exam,
      double moy,
      double coef,
      double cred,
      double wTD,
      double wEX,
      double wTP
      ) onChanged;




  const NoteCard({
    super.key,

    required this.coef,
    required this.cred,
    required this.subject,
    required this.onChanged,
    required this.wTD,
    required this.wEX,
    required this.wTP,
    this.initialTd,
    this.initialTp,
    this.initialExam,

  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}
class NoteResult {
  final double td;
  final double tp;
  final double exam;
  final double moy;
  final double coef;
  final double cred;

  NoteResult(
      this.td,
      this.tp,
      this.exam,
      this.moy,
      this.coef,
      this.cred);
}
class _NoteCardState extends State<NoteCard> {
  double? td;
  double? tp;
  double? exam;
  double moy = 0.0;

  late double coef;
  late double cred;
  late double wTD;
  late double wEX;
  late double wTP;
  late TextEditingController _tdController;
  late TextEditingController _tpController;
  late TextEditingController _examController;
  late TextEditingController _coefController;
  late TextEditingController _credController;

  String? translatedSubject;

  @override
  void initState() {
    super.initState();
    cred = widget.cred; // نهيئه بالقيمة الأصلية
    coef = widget.coef;
    wTD = widget.wTD;
    wEX = widget.wEX;
    wTP = widget.wTP;
    td = widget.initialTd;
    tp = widget.initialTp;
    exam = widget.initialExam;
    calculateMoy();
    _tdController = TextEditingController(text: _formatGrade(td));
    _tpController = TextEditingController(text: _formatGrade(tp));
    _examController = TextEditingController(text: _formatGrade(exam));
    _coefController = TextEditingController(text: coef.toStringAsFixed(0));
    _credController = TextEditingController(text: cred.toStringAsFixed(0));
    _loadTranslatedSubject();

  }
  void _loadTranslatedSubject() async {
    try {
      final result = await translateSubject(context, widget.subject);
      if (mounted) {
        setState(() {
          translatedSubject = result;
        });
      }
    } catch (_) {
      translatedSubject = widget.subject; // fallback عند الخطأ
    }
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTd != td ||
        widget.initialTp != tp ||
        widget.initialExam != exam) {
      setState(() {
        td = widget.initialTd;
        tp = widget.initialTp;
        exam = widget.initialExam;
        calculateMoy();
        _tdController.text = _formatGrade(td);
        _tpController.text = _formatGrade(tp);
        _examController.text = _formatGrade(exam);
      });
    }
    if (widget.coef != coef || widget.cred != cred) {
      setState(() {
        coef = widget.coef;
        cred = widget.cred;
        _coefController.text = coef.toStringAsFixed(0);
        _credController.text = cred.toStringAsFixed(0);
      });
    }
    if (widget.wTD != wTD || widget.wEX != wEX || widget.wTP != wTP) {
      setState(() {
        wTD = widget.wTD;
        wEX = widget.wEX;
        wTP = widget.wTP;
        calculateMoy();
      });
    }
  }

  @override
  void dispose() {
    _tdController.dispose();
    _tpController.dispose();
    _examController.dispose();
    _coefController.dispose();
    _credController.dispose();
    super.dispose();
  }

  String _formatGrade(double? value) {
    if (value == null || value == 0) return '';
    return value.toString();
  }


  double? _parseGrade(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized);
  }

  int? _parseNonNegativeInt(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) return 0;
    final parsed = int.tryParse(sanitized);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
  void onTDChanged(String v) {
    setState(() {
      td = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void notifyParent() {
    widget.onChanged(td, tp, exam, moy, coef, cred, wTD, wEX, wTP);
  }

  void onExamChanged(String v) {
    setState(() {
      exam = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void onTPChanged(String v) {
    setState(() {
      tp = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void calculateMoy() {
    if (td == null && tp == null && exam == null) {
      moy = 0;
      return;
    }
// هنا معادلة حساب المعدل
    moy = ((td ?? 0) * wTD) + ((exam ?? 0) * wEX) + ((tp ?? 0) * wTP);
  }
  void updateCred(double newValue) {
    setState(() {
      cred = newValue;
      notifyParent();
    });
  }
  void updateCoef(double newValue) {
    setState(() {
      coef = newValue;
      notifyParent();
    });
  }
  void _showWeightsDialog() {
    TextEditingController wTDController = TextEditingController(text: wTD.toString());
    TextEditingController wEXController = TextEditingController(text: wEX.toString());
    TextEditingController wTPController = TextEditingController(text: wTP.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).editWeights),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: translateSubject(context,widget.subject),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('...'); // أثناء التحميل
                  } else if (snapshot.hasError) {
                    return Text(widget.subject); // fallback عند الخطأ
                  } else {
                    return Text(
                      textAlign: TextAlign.start,
                      snapshot.data!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15,),
              TextField(
                  controller: wTDController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "W. TD"),
                  textAlign: TextAlign.center
              ),const SizedBox(height: 10,),
              TextField(
                controller: wEXController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. EXAM",),
                textAlign: TextAlign.center,
              ),const SizedBox(height: 10,),
              TextField(
                controller: wTPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "W. TP"),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  wTD = double.tryParse(wTDController.text) ?? wTD;
                  wEX = double.tryParse(wEXController.text) ?? wEX;
                  wTP = double.tryParse(wTPController.text) ?? wTP;
                  calculateMoy();
                  notifyParent();
                });

                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity,height: 218,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border:  Border.all(
          width: 3,
          color: moy == 0
              ? Theme.of(context).colorScheme.onSurface
              : moy < 10
              ? Colors.red.withValues(alpha: 0.7)
              : Colors.green.withValues(alpha: 0.7),
        ),

      ),
      child: Column(
        children: [
          //------------------ الصف العلوي --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اسم المادة
              Expanded(
                child:
                Column(
                  children: [

                    Text(
                      translatedSubject ?? widget.subject, // يظهر الاسم الثابت أو fallback أثناء التحميل
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Container(

                      child:
                      const SizedBox(width: 10, height: 15,),
                    ),
                  ],
                ),),
              Row(

                children: [
                  // Coef
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Coef", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                        width: 60,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              width: 1,
                              color: Theme.of(context).colorScheme.onSurface,)
                        ),
                        child:

                        TextField(
                          controller: _coefController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = _parseNonNegativeInt(v);
                            if (parsed == null) return;
                            setState(() {
                              coef = parsed.toDouble();
                              notifyParent();
                            });
                          }
                          ,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 15),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                            border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                          ),
                        ),



                      ),

                    ],
                  ),

                  const SizedBox(width: 5),

                  // Cred
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Cred", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Container(
                          width: 60,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.onSurface,)
                          ),
                          child:
                          TextField(
                            controller: _credController,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final parsed = _parseNonNegativeInt(v);
                              if (parsed == null) return;
                              setState(() {
                                cred = parsed.toDouble();
                                notifyParent();
                              });
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 15),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                              border: InputBorder.none, // إزالة الحد الافتراضي إذا تريد
                            ),
                          )


                      ),
                    ],
                  ),
                ],
              ),




            ],
          ),

          const SizedBox(height: 5),
          Container(height: 2,
            color: moy == 0
                ? Theme.of(context).colorScheme.onSurface
                : moy < 10
                ? Colors.red.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).notesTdTpExam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,

                  ),),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    _showWeightsDialog();
                  },
                ),

              ]),

          const SizedBox(height: 0),

          //------------------ حقول TD + EXAM + MOY --------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(children: [

                // EXAM
                if (wEX != 0)
                  Column(
                    children: [
                      const Text("EXAM"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: TextField(
                          controller: _examController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onExamChanged(v);
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',

                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),

                // TD
                if (wTD != 0)
                  Column(
                    children: [

                      const Text("TD"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tdController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTDChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 5,),
                //TP
                if (wTP != 0)
                  Column(
                    children: [

                      const Text("TP"),
                      const SizedBox(height: 2),
                      Container(
                        width: 70,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(40),

                        ),
                        child: TextField(
                          controller: _tpController,
                          textAlign: TextAlign.center,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            onTPChanged(v);
                          },

                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(top: 50, bottom: 23, left: 0, right: 0),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  )

              ]),
              // MOY
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Moy:        ",
                      style: TextStyle(
                        fontSize: 15,

                      )),
                  Text(
                    moy.toStringAsFixed(2),
                    style:  TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: moy == 0
                          ? Theme.of(context).colorScheme.onSurface
                          : moy < 10
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


}


class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Material يعطي خلفية ورفع مناسب للـ TabBar
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarDelegate oldDelegate) {
    // عدّل إلى true لو أردت إعادة البناء عند تغيّر محتوى الـ TabBar
    return false;
  }
}
/// ------------------------ Résumé annuel -------------------------------
class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({
    Key? key,
    required this.semester1,
    required this.semester2,
    this.showAnnual = true,
    this.showS1 = true,
    this.showS2 = true,
  }) : super(key: key);

  final SemesterModel semester1;
  final SemesterModel semester2;

  final bool showAnnual; // عرض الملخص السنوي
  final bool showS1; // عرض بطاقة S1
  final bool showS2; // عرض بطاقة S2

  Widget buildInfoCard(
      String title, double value, IconData icon, BuildContext cx) {
    return Container(
      width: 140,
      height: 63,
      padding: const EdgeInsets.fromLTRB(15, 10, 5, 2),
      decoration: BoxDecoration(
        color: Theme.of(cx).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 2, color: Theme.of(cx).colorScheme.onSurface),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, size: 20),
            const SizedBox(
              width: 5,
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ]),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = ((moy1 + moy2) / 2);
    final creds = semester1.creditsEarned() + semester2.creditsEarned();
    final S1cred = semester1.creditsEarned();
    final S2cred = semester2.creditsEarned();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------- قسم S1 ----------------------
        if (showS1)
          Directionality(
              textDirection:
                  TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S1 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S1 Moyenne", moy1, Icons.filter_1, context),
                        buildInfoCard(
                            "S1 Credits", S1cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- قسم S2 ----------------------
        if (showS2)
          Directionality(
              textDirection:
                  TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("S2 Résumé",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard(
                            "S2 Moyenne", moy2, Icons.filter_2, context),
                        buildInfoCard(
                            "S2 Credits", S2cred, Icons.auto_graph, context),
                      ],
                    ),
                  ],
                ),
              )),

        // ---------------------- الملخص السنوي ----------------------
        if (showAnnual)
          Directionality(
              textDirection:
                  TextDirection.ltr, // ← يمنع الانعكاس داخل البطاقة فقط
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      width: 3, color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Résumé Annual",
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildInfoCard("Année", ann, Icons.verified, context),
                        buildInfoCard(
                            "Total Credits", creds, Icons.auto_graph, context),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          width: 3,
                          color: ann == 0
                              ? Theme.of(context).colorScheme.onSurface
                              : ann < 10
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Résultat: في البداية
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Résultat:",
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),

                          const SizedBox(height: 0),

                          // النتيجة في الوسط
                          Center(
                            child: Text(
                              ann == 0
                                  ? '---'
                                  : (ann >= 10
                                      ? '✨u Succeeded✨'
                                      : 'u Failed ❌'),
                              style: GoogleFonts.dmMono(
                                  textStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : ann < 10
                                        ? Colors.red
                                        : Colors.green,
                              )),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )),
      ],
    );
  }
}

Widget buildInfoCard(String title, double value, IconData icon) {
  return Card(
      //color:Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                Icon(
                  icon,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
}

extension SafeStringExt on String {
  String ellipsize(int max, {String ellipsis = '…'}) {
    if (length <= max) return this;
    if (max <= 0) return '';
    return substring(0, max) + ellipsis;
  }
}

// دالة تأخذك مباشرةً إلى واجهة “الدراسة”
void openStudiesNavigator(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => FacultiesScreen(faculties: getDemoFaculties(context))),
  );
}
/////////////////////////////////////////////////////////////////////////////
/////////////////////result screen///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

class ResultsScreen extends StatelessWidget {
  final SemesterModel semester1;
  final SemesterModel semester2;
  final String programLabel; // مثال: "Licence 2ème Année" (اختياري)

  const ResultsScreen({
    Key? key,
    required this.semester1,
    required this.semester2,
    this.programLabel = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // حسابات
    final double moy1 = semester1.semesterAverage();
    final double moy2 = semester2.semesterAverage();
    // إذا كان أحد الفصول فارغاً، إبقاء المتوسط = 0
    final double ann = _computeAnnual(moy1, moy2);
    final double cred1 = semester1.creditsEarned();
    final double cred2 = semester2.creditsEarned();
    final double totalCred = cred1 + cred2;

    final decisionColor = _decisionColor(context, ann);
    final decisionText = _decisionText(ann);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).studyResults),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final file = await PdfReportService.generateReport(
            faculty: programLabel, // مثال: يمكنك تمرير قيمة من parameters
            program: programLabel,
            semester1: semester1,
            semester2: semester2,
          );
          await OpenFilex.open(file.path);
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- عنوان السنة / البرنامج ----------
            if (programLabel.isNotEmpty) ...[
              Text(
                programLabel,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            // ---------- العنوان العام + البطاقة العليا ----------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: ann == 0
                    ? Theme.of(context).colorScheme.surface
                    : decisionColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: ann == 0
                      ? Theme.of(context).colorScheme.outline
                      : decisionColor,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Decision :',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      // -------- بطاقة المعدل السنوي --------
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Année',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                ann == 0 ? '0.0' : ann.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ann == 0
                                      ? Theme.of(context).colorScheme.onSurface
                                      : decisionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة الرصيد الإجمالي --------
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Credits',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              totalCred.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // -------- بطاقة النتيجة النهائية --------
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ann == 0
                              ? Theme.of(context).colorScheme.surface
                              : decisionColor,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Résultat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              ann == 0 ? '---' : decisionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ann == 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------- متوسط الفصل الأول و رصيده ----------
            _buildSemesterSummaryRow('S1', moy1, cred1, context),
            const SizedBox(height: 8),
            _buildSemesterSummaryRow('S2', moy2, cred2, context),
            const SizedBox(height: 12),

            const Divider(),

            // ---------- قوائم المواد: S1 ثم S2 ----------

            _buildModuleListSection(context, 'S1 Modules', semester1.modules),
            const SizedBox(height: 16),
            _buildModuleListSection(context, 'S2 Modules', semester2.modules),
          ],
        ),
      ),
    );
  }

  static double _computeAnnual(double moy1, double moy2) {
    // نعتبر 0 إن لم تكن هناك مواد؛ يمكن تعديل المنطق إذا كان مطلوباً غير ذلك
    if (moy1 == 0 && moy2 == 0) return 0.0;
    // لو أحدهم صفر ونريد حساب السنوي بناءً على الموجود فقط:
    if (moy1 == 0) return double.parse(moy2.toStringAsFixed(2));
    if (moy2 == 0) return double.parse(moy1.toStringAsFixed(2));
    return double.parse(((moy1 + moy2) / 2).toStringAsFixed(2));
  }

  static Color _decisionColor(BuildContext cx, double ann) {
    if (ann == 0) return Colors.grey.shade400;
    return ann < 10 ? Colors.red : Colors.green;
  }

  static String _decisionText(double ann) {
    if (ann == 0) return '---';
    return ann < 10 ? 'Failed' : 'Succeed';
  }

  Widget _buildSemesterSummaryRow(
      String label, double moy, double creds, BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;

    final Color color = moy == 0
        ? scheme.onSurface.withValues(alpha: 0.6)
        : (moy < 10 ? Colors.red : Colors.green);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        Row(
          children: [
            // بطاقة المعدل
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color),
                color: scheme.surface,
              ),
              child: Text(
                'Moy: ${moy == 0 ? '---' : moy.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // بطاقة الرصيد
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
                color: scheme.surface,
              ),
              child: Text(
                'Credits: ${creds.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleListSection(
      BuildContext context, String title, List<ModuleModel> modules) {
    final scheme = Theme.of(context).colorScheme;

    if (modules.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).noSubjectsThisSemester,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    return Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              textDirection: TextDirection.ltr,
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            )),
        const SizedBox(height: 8),
        ...modules.map((m) => _buildModuleRow(context, m)).toList(),
      ],
    );
  }

  Widget _buildModuleRow(BuildContext context, ModuleModel m) {
    final scheme = Theme.of(context).colorScheme;

    final grade = m.moy;
    final gradeColor = _getGradeColor(grade);

    return Card(
      color: scheme.surface,
      shadowColor: scheme.shadow,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? m.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            );
          },
        ),
        subtitle: Text(
          '${S.of(context).credits}: ${m.credits.toStringAsFixed(0)}  /  '
          '${S.of(context).coefficient}: ${m.coef.toStringAsFixed(0)}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                  Text(
                    _gradeLabel(grade),
                    style: TextStyle(color: gradeColor),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                    Icon(Icons.info_outline, size: 20, color: scheme.onSurface),
                onPressed: () => _showModuleWeightsDialog(context, m),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModuleWeightsDialog(BuildContext context, ModuleModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: FutureBuilder<String>(
          future: translateSubject(context, m.title),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('...'); // أثناء التحميل
            } else if (snapshot.hasError) {
              return Text(m.title); // fallback عند الخطأ
            } else {
              return Text(
                snapshot.data!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow('wTD', m.wTD),
            _infoRow('wTP', m.wTP),
            _infoRow('wEX', m.wEX),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).close)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 10) return Colors.green;
    //if (grade >= 8) return Colors.orange;
    return Colors.red;
  }

  String _gradeLabel(double grade) {
    if (grade >= 10) return 'SUCCEED';
    //if (grade >= 8) return 'FAILED';
    return 'FAILED';
  }
}

class PdfReportService {
  static Future<File> generateReport({
    required String faculty,
    required String program,
    required SemesterModel semester1,
    required SemesterModel semester2,
  }) async {
    final generatedAt = DateTime.now();
    final pdf = pw.Document(
      title: 'Relevé des résultats UniSpace',
      author: 'UniSpace',
      subject: 'Relevé annuel des résultats',
      creator: 'UniSpace Flutter App',
      producer: 'UniSpace PDF Service',
    );

    // حساب المتوسطات
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = (moy1 + moy2) / 2;

    final cred1 = semester1.creditsEarned();
    final cred2 = semester2.creditsEarned();
    final totalCred = cred1 + cred2;

    final decision = ann == 0 ? '---' : (ann >= 10 ? 'SUCCÈS' : 'AJOURNÉ');
    final regularFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Tajawal-Regular.ttf"));
    final boldFont =
        pw.Font.ttf(await rootBundle.load("assets/fonts/Tajawal-Bold.ttf"));
    final user = FirebaseAuth.instance.currentUser;
    final fullName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Étudiant UniSpace';
    final email = _maskEmail(user?.email);
    final docId = _buildDocumentId(generatedAt, semester1, semester2);
    final academicYear = _academicYear(generatedAt);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        footer: (context) => _footer(context, generatedAt, docId),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Université : Université UniSpace',
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text('Faculté : ${faculty.isEmpty ? 'Non renseignée' : faculty}'),
                pw.Text('Programme / Spécialité : ${program.isEmpty ? 'Non renseigné' : program}'),
                pw.Text('Année universitaire : $academicYear'),
                pw.Text('Nom & Prénom : $fullName'),
                pw.Text('Email : ${email ?? 'Non renseigné'}'),
                pw.SizedBox(height: 16),
                _sectionTitle('DÉCISION', font: boldFont),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(3),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(2),
                    5: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _decisionHeaderRow(),
                    _decisionValueRow(
                      ann,
                      totalCred,
                      decision,
                      moy1,
                      moy2,
                      cred1,
                      cred2,
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                _sectionTitle('SEMESTRE 1', font: boldFont),
                pw.SizedBox(height: 8),
                _modulesTable(semester1.modules),
                pw.SizedBox(height: 14),
                _sectionTitle('SEMESTRE 2', font: boldFont),
                pw.SizedBox(height: 8),
                _modulesTable(semester2.modules),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/results.pdf");
    return file.writeAsBytes(await pdf.save());
  }

  // ----------- Helpers -----------

  static pw.Widget _sectionTitle(String text, {required pw.Font font}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      color: PdfColors.grey300,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          font: font, // استخدم الخط الممرر
        ),
      ),
    );
  }

  static pw.TableRow _decisionHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('Année (moyenne générale)', bold: true),
        _tableCell('Total Crédits', bold: true),
        _tableCell('Résultat', bold: true),
        _tableCell('Moyenne S1', bold: true),
        _tableCell('Moyenne S2', bold: true),
        _tableCell('Crédits S1/S2', bold: true),
      ],
    );
  }

  static pw.TableRow _decisionValueRow(
    double ann,
    double totalCred,
    String decision,
    double moy1,
    double moy2,
    double cred1,
    double cred2,
  ) {
    return pw.TableRow(
      children: [
        _tableCell(ann.toStringAsFixed(2)),
        _tableCell(totalCred.toStringAsFixed(0)),
        _tableCell(decision),
        _tableCell(moy1.toStringAsFixed(2)),
        _tableCell(moy2.toStringAsFixed(2)),
        _tableCell('${cred1.toStringAsFixed(0)} / ${cred2.toStringAsFixed(0)}'),
      ],
    );
  }

  static pw.Widget _modulesTable(List<ModuleModel> modules) {
    final rows = modules
        .map((m) => [
              m.title.ellipsize(42),
              m.coef.toString(),
              m.credits.toString(),
              m.moy.toStringAsFixed(2),
            ])
        .toList();

    return pw.Table.fromTextArray(
      headers: const ['Module', 'Coef', 'Crédit', 'Moyenne'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle:
          pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      columnWidths: const {
        0: pw.FixedColumnWidth(250),
        1: pw.FixedColumnWidth(55),
        2: pw.FixedColumnWidth(55),
        3: pw.FixedColumnWidth(70),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _footer(
      pw.Context context, DateTime generatedAt, String docId) {
    final generated = _formatDate(generatedAt);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text('Généré le : $generated', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Document ID : $docId', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          'Ce document est généré automatiquement par UniSpace et n’a pas de valeur administrative officielle.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _academicYear(DateTime now) {
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return '$startYear-$endYear';
  }

  static String? _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final parts = email.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.length <= 2) return '$local@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }

  static String _buildDocumentId(
    DateTime generatedAt,
    SemesterModel semester1,
    SemesterModel semester2,
  ) {
    final ts =
        '${generatedAt.year}${_two(generatedAt.month)}${_two(generatedAt.day)}-${_two(generatedAt.hour)}${_two(generatedAt.minute)}${_two(generatedAt.second)}';
    final hashSeed = [
      semester1.modules.length,
      semester2.modules.length,
      (semester1.semesterAverage() * 100).round(),
      (semester2.semesterAverage() * 100).round(),
    ].join('-');
    final shortHash = hashSeed.codeUnits.fold<int>(0, (a, b) => (a + b) % 99999);
    return 'US-$ts-${shortHash.toRadixString(16).padLeft(4, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}



// ---------------------------------------------------------------------------
// توافقية: بعض الأقسام القديمة كانت تستدعي CalculatorScreen بالاسم القديم.
// حتى لا ينكسر أي استدعاء، نوفّر كلاس بنفس الاسم يشير إلى الشاشة الجديدة.
// ---------------------------------------------------------------------------
// class CalculatorScreen extends CalculatorHubScreen {
//   const CalculatorScreen({super.key});
// }

// ============================================================================
// END OF FILE — UniSpace
// ============================================================================
