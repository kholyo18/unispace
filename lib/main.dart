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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Local
import 'package:shared_preferences/shared_preferences.dart';

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
import 'ui/widgets/widgets.dart';
import './moduls3.dart';
import './moduls.dart';
import 'module/moduls.dart';
import 'core/local/grades_local_store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package: UniSpace/generated/l10n.dart';
import 'package:translator/translator.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> openPdf(String filePath) async {
  final result = await OpenFilex.open(filePath);
  print(result); // Optional: لمراجعة حالة الفتح
}

// ============================================================================
// Branding
// ============================================================================
const kUniSpaceGreen = Color(0xFFB2DFDB);
const kUniSpaceBlue  = Color(0xFF004D40);
const kNoteYellow  = Color(0xFFFFF3C4);

// ============================================================================
// Bootstrap
// ============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // تسجيل Hive Adapter
  Hive.registerAdapter(ModuleModelAdapter());
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
    if (themeIdx != null && themeIdx >= 0 && themeIdx < ThemeMode.values.length) {
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
      home: const AuthGate(),
    );
  }

}

// ============================================================================
// Global End Drawer — يعمل فعليًا (مظهر/لغة/إعادة كلمة السر/روابط)
// ============================================================================
class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final app = UniSpaceApp.of(context);

    return SafeArea(
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kUniSpaceBlue, kUniSpaceGreen]),
              ),
              accountName: Text(user?.email?.split('@').first ?? 'Guest',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              accountEmail: Text(user?.email ?? 'غير مسجّل'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: kUniSpaceBlue, size: 36),
              ),
            ),

            // تنقّل سريع


            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('حاسبة المعدل'),
              onTap: () {
                Navigator.push
                  (context,
                    MaterialPageRoute(builder: (_) => const QuickAverageScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: Text(S.of(context).clipboard),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              },
            ),

            const Divider(height: 24),

            // المظهر واللغة
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

            const Divider(height: 24),

            // الحساب
            if (user != null) ...[
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: Text(S.of(context).resetPassword),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: user.email!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(S.of(context).resetSent),),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تعذر الإرسال: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(S.of(context).logout),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (_) => false,
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: Text(S.of(context).login),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
              ),
            ],

            const Divider(height: 24),

            // حول
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(S.of(context).aboutApp),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'UniSpace',
                applicationVersion: '1.0.0',
                applicationIcon: const CircleAvatar(
                  backgroundColor: kUniSpaceBlue,
                  child: Icon(Icons.school, color: Colors.teal),
                ),
                children: const [
                  Text('منصة لحساب المعدل الجامعي ومجتمع للطلبة، مع تدوين ملاحظات.'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(S.of(context).privacyPolicy),

              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) =>  AlertDialog(
                    title: Text(S.of(context).privacyPolicy),
                    content: Text(S.of(context).aboutAppDetails),
                  ),
                );
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
        ),
      ),
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
         ListTile(title: Text(S.of(context).chooseTheme),),
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
// class _LanguageSheet extends StatelessWidget {
//   final _UniSpaceAppState app;
//   const _LanguageSheet({required this.app});
//
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         const ListTile(title: Text('اختر اللغة')),
//         RadioListTile<String>(
//           value: 'ar',
//           groupValue: app._locale.languageCode,
//           title: const Text('العربية'),
//           onChanged: (_) => _apply(context, const Locale('ar')),
//         ),
//         RadioListTile<String>(
//           value: 'fr',
//           groupValue: app._locale.languageCode,
//           title: const Text('Français'),
//           onChanged: (_) => _apply(context, const Locale('fr')),
//         ),
//         RadioListTile<String>(
//           value: 'en',
//           groupValue: app._locale.languageCode,
//           title: const Text('English'),
//           onChanged: (_) => _apply(context, const Locale('en')),
//         ),
//       ]),
//     );
//   }
//
//   void _apply(BuildContext context, Locale l) {
//     app.setLocale(l);
//     Navigator.pop(context);
//   }
// }

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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData) return const SignInScreen();
        return const HomeShell();
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
  bool loading = false;

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا.';
      case 'operation-not-allowed':
        return 'طريقة تسجيل الدخول غير مفعّلة.';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بطريقة تسجيل دخول مختلفة.';
      case 'credential-already-in-use':
        return 'بيانات الدخول هذه مستخدمة بالفعل لحساب آخر.';
      case 'invalid-credential':
        return 'بيانات تسجيل الدخول غير صحيحة.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت وحاول مجددًا.';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات. حاول لاحقًا.';
      case 'channel-error':
        return 'تعذر بدء تسجيل الدخول عبر Google. حاول مرة أخرى.';
      default:
        return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
    }
  }

  String _errorMessage(Object error, {String? fallback}) {
    if (error is FirebaseAuthException) {
      return _authErrorMessage(error);
    }
    if (error is PlatformException) {
      switch (error.code) {
        case 'sign_in_canceled':
          return 'تم إلغاء تسجيل الدخول عبر Google.';
        case 'network_error':
          return 'تحقق من اتصال الإنترنت وحاول مجددًا.';
        default:
          return 'تعذر بدء تسجيل الدخول عبر Google. حاول مرة أخرى.';
      }
    }
    return fallback ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  String _googleAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'مشكلة في الانترنت، حاول مرة أخرى';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بطريقة تسجيل أخرى';
      case 'invalid-credential':
        return 'بيانات الدخول غير صالحة';
      default:
        return 'تعذّر تسجيل الدخول عبر Google، حاول مرة أخرى';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAuthError(Object error, {String? fallback}) {
    final message = _errorMessage(error, fallback: fallback);
    _showMessage(message);
  }

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } catch (e) {
      _showAuthError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _register() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } catch (e) {
      _showAuthError(e, fallback: 'تعذر إنشاء الحساب. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserDocument(userCredential.user);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in FirebaseAuthException: $e');
      _showMessage(_googleAuthErrorMessage(e));
    } on PlatformException catch (e) {
      debugPrint('Google sign-in PlatformException: $e');
      if (e.code == 'sign_in_canceled') {
        return;
      }
      if (e.code == 'network_error') {
        _showMessage('مشكلة في الانترنت، حاول مرة أخرى');
        return;
      }
      _showMessage('تعذّر تسجيل الدخول عبر Google، حاول مرة أخرى');
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _showMessage('تعذّر تسجيل الدخول عبر Google، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to create user document: $e');
      _showMessage('تم تسجيل الدخول، لكن تعذر حفظ بيانات الحساب. حاول لاحقًا.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[700],
      body:
      Center(
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
                const Icon(Icons.school_rounded, color: kUniSpaceBlue, size: 64),
                const SizedBox(height: 12),
                Text(S.of(context).welcomeUniSpace,
                style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:  InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    labelText: S.of(context).email,

                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration:  InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    labelText: S.of(context).password,
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  FilledButton.icon(
                    onPressed: loading ? null : _login,
                    icon: const Icon(Icons.login),
                    label: Text(S.of(context).login),

                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(S.of(context).register),

                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HomeShell — الشريط السفلي الجديد + سحب/انزلاق بين الصفحات
// ============================================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  // 0 = Home(الكليات), 1 = Community, 2 = Notes
  int _current = 0;
  late final PageController _page;

  @override
  void initState() {
    super.initState();
    _page = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _current = i);
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppEndDrawer(),
      body: PageView(
        controller: _page,
        onPageChanged: (i) => setState(() => _current = i),
        children: const [
          // الصفحة الرئيسية: كروت كليات + زر يدخل للدراسة الكاملة
          HomeLandingScreen(),
          // المجتمع بأسلوب Reddit
          CommunityScreen(),
          // الملاحظات الاحترافية
          NotesScreen(),

        ],
      ),
      bottomNavigationBar: _BottomBar(
        index: _current,
        controller: _page,
        pageCount: 3,
        onTap: _go,
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
       //floatingActionButton: _NoteFab(onTap: () => _go(2)),
    );
  }
}

// زر الملاحظات في المنتصف
// class _NoteFab extends StatelessWidget {
//   final VoidCallback onTap;
//   const _NoteFab({required this.onTap});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: SizedBox(
//         width: 56,
//         height: 56,
//         child: FloatingActionButton(
//           elevation: 3,
//           onPressed: onTap,
//           child: const Icon(Icons.note_alt_outlined, size: 26),
//         ),
//       ),
//     );
//   }
// }

// شريط سفلي مع شكل احترافي
class _BottomBar extends StatefulWidget {
  final int index;
  final void Function(int) onTap;
  final PageController controller;
  final int pageCount;
  const _BottomBar({
    required this.index,
    required this.onTap,
    required this.controller,
    this.pageCount = 3,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  double _dragExtent = 0;
  double _startPixels = 0;
  bool _isDragging = false;

  void _handlePanEnd([DragEndDetails? details]) {
    if (!_isDragging || !widget.controller.hasClients) {
      _dragExtent = 0;
      _isDragging = false;
      return;
    }

    _isDragging = false;
    final currentPage = widget.controller.page ?? widget.index.toDouble();
    int target = currentPage.round();
    final velocityX = details?.velocity.pixelsPerSecond.dx ?? 0;
    if (velocityX <= -200 && target < widget.pageCount - 1) {
      target += 1;
    } else if (velocityX >= 200 && target > 0) {
      target -= 1;
    }
    target = target.clamp(0, widget.pageCount - 1);
    _dragExtent = 0;
    widget.onTap(target);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        _dragExtent = 0;
        _isDragging = true;
        if (widget.controller.hasClients) {
          _startPixels = widget.controller.position.pixels;
        }
      },
      onPanUpdate: (details) {
        if (!widget.controller.hasClients) return;
        _dragExtent += details.delta.dx;
        final position = widget.controller.position;
        final target = (_startPixels - _dragExtent)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        position.jumpTo(target);
      },
      onPanEnd: _handlePanEnd,
      onPanCancel: () => _handlePanEnd(),
      child: BottomAppBar(
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(
              child: _BarItem(

                icon: Icons.home_outlined,
                label:S.of(context).home,

                selected: widget.index == 0,
                onTap: () => widget.onTap(0),

              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _BarItem(
                icon: Icons.public_outlined,
                label: S.of(context).community,
                selected: widget.index == 1,
                onTap: () => widget.onTap(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c),
          const SizedBox(height: 0),
          Text(label, style: TextStyle(color: c, fontSize: 10)),
        ]),
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
  late final TextEditingController _searchController;
  List<ProgramFaculty> _allFaculties = [];
  List<ProgramFaculty> _filteredFaculties = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _allFaculties = getDemoFaculties(context);
      _filteredFaculties = _allFaculties;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeText(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '');
    text = text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    text = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  bool _containsNormalized(String haystack, String needle) {
    final normalizedNeedle = _normalizeText(needle);
    if (normalizedNeedle.isEmpty) {
      return true;
    }
    return _normalizeText(haystack).contains(normalizedNeedle);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFaculties = _allFaculties;
        return;
      }
      _filteredFaculties = _allFaculties.where((faculty) {
        final fields = <String>[faculty.name];
        return fields.any((field) => _containsNormalized(field, query));
      }).toList(growable: false);
    });
  }

  void _openFaculty(ProgramFaculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FacultyMajorsScreen(faculty: faculty)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final faculties = _filteredFaculties.take(6).toList();

    final quickFaculty = faculties.isNotEmpty ? faculties.first : null;
    final gridFaculties =
        quickFaculty == null ? faculties : faculties.skip(1).toList(growable: false);

    return AppScaffold(
       // endDrawer:  AppEndDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0, // حتى يلتصق المحتوى باليسار
        title: Row(
          textDirection: TextDirection.ltr,
          //mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // لأنك تستخدم endDrawer
              },
            ),
            const SizedBox(width: 4),
            Align( alignment: Alignment.centerLeft,
                child: Text(
              'UniSpace',
              style: GoogleFonts.pacifico(
                textStyle: Theme.of(context).textTheme.displayLarge,
                fontSize: 30,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.teal[900],
              ),
            )),
          ],
        ),
      ),


      padding: EdgeInsets.zero,
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(

              child: Material(
                color: Colors.transparent, // للحفاظ على خلفية InfoCard
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white, // لون النصوص
                      displayColor: Colors.white,
                    ),
                  ),
                  child: InfoCard(
                    backgroundColor:Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    leadingIcon: Icons.school_outlined,
                    title: S.of(context).welcomeEmoji,
                    subtitle: S.of(context).homeSubtitle,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(1, 12, 1, 10),
            sliver: SliverToBoxAdapter(
              child: Container(

                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText:S.of(context).searchFaculty ,
                    hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
          if (_filteredFaculties.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text("لا توجد نتائج")),
            )
          else if (quickFaculty != null) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: S.of(context).faculties,
                  trailing: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FacultiesScreen(faculties: getDemoFaculties(context)),


                      ),
                    ),
                    child:  Text(S.of(context).viewAll),
                  ),
                ),
              ),
            ),
            // SliverPadding(
            //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            //   sliver: SliverToBoxAdapter(
            //     child: Column(
            //       children: [
            //         // الحاوية السوداء: الحساب السريع
            //         InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               MaterialPageRoute(builder: (_) => const QuickAverageScreen()),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(12),
            //           child: Container(
            //             width: 350,
            //             height: 60,
            //             padding: const EdgeInsets.symmetric(horizontal: 16),
            //             alignment: Alignment.centerLeft,
            //             decoration: BoxDecoration(
            //               color: Theme.of(context).colorScheme.surface, // لون الحاوية أسود
            //               borderRadius: BorderRadius.circular(12),
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: Theme.of(context).colorScheme.onSurface,
            //                   blurRadius: 10,
            //                   offset: const Offset(0, 1),
            //                 ),
            //               ],
            //             ),
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children:  [Row(
            //                   children: [
            //                 Icon(Icons.calculate_outlined,
            //                     color: Theme.of(context).colorScheme.onSurface, size: 28),
            //                 SizedBox(width: 12),
            //                 Text(S.of(context).quickCalc,
            //                   style: TextStyle(
            //                     color: Theme.of(context).colorScheme.onSurface,
            //                     fontSize: 18,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 )]),
            //                 Icon(
            //                    Icons.arrow_forward_ios,
            //                    color: Theme.of(context).colorScheme.onSurface,
            //                    size: 20,    )
            //               ],
            //             ),
            //
            //           ),
            //         ),
            //
            //
            //       ],
            //     ),
            //   ),
            // ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final faculty = _filteredFaculties[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: _FacultyQuickCard(
                        faculty: faculty,
                        onTap: () => _openFaculty(faculty),
                      ),
                    );
                  },
                  childCount: _filteredFaculties.length,
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
    final tracksCount = faculty.majors.fold<int>(0, (sum, major) => sum + major.tracks.length);


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
              //if (theme.brightness == Brightness.light)
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(.08),
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
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(.2),
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
                      label:S.of(context).majors ,
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

// class _FacultyTile extends StatefulWidget {
//   const _FacultyTile({required this.faculty, required this.onTap});
//
//   final ProgramFaculty faculty;
//   final VoidCallback onTap;
//
//   @override
//   State<_FacultyTile> createState() => _FacultyTileState();
// }
//
// class _FacultyTileState extends State<_FacultyTile> {
//   bool _hovered = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final majorsCount = widget.faculty.majors.length;
//     final subtitle = majorsCount == 0
//         ? 'لا تخصصات بعد'
//         : majorsCount == 1
//             ? 'تخصص واحد'
//             : '$majorsCount تخصصات';
//
//     return MouseRegion(
//       onEnter: (_) => setState(() => _hovered = true),
//       onExit: (_) => setState(() => _hovered = false),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: widget.onTap,
//           borderRadius: BorderRadius.circular(20),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             curve: Curves.easeInOut,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surface,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: _hovered
//                     ? theme.colorScheme.primary.withOpacity(.4)
//                     : theme.colorScheme.outlineVariant.withOpacity(.4),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Icon(Icons.apartment_outlined,
//                     color: theme.colorScheme.primary, size: 38),
//                 const Spacer(),
//                 Text(
//                   widget.faculty.name,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: theme.textTheme.titleSmall,
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   subtitle,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
    final pinned = _notes.where((e) => e.pinned && (q.isEmpty || e.match(q))).toList();
    final others = _notes.where((e) => !e.pinned && (q.isEmpty || e.match(q))).toList();
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title:  Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.ltr,
          //mainAxisSize: MainAxisSize.min,
          children: [
            Row(
            textDirection: TextDirection.ltr,
              children: [
        IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openEndDrawer(); // لأنك تستخدم endDrawer
        },
      ),
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
            IconButton(onPressed: _create, icon: const Icon(Icons.add_circle_outline)),
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
            decoration:  InputDecoration(
              hintText: S.of(context).searchClipboard,
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          if (pinned.isNotEmpty) ...[
             Text(S.of(context).pinned, style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...pinned.map((n) => _NoteTile(
              note: n,
              onTap: () => _edit(n),
              onPin: () => setState(() => n.pinned = !n.pinned),
              onArchive: () => setState(() { _notes.remove(n); _archived.add(n); }),
            )),
            const SizedBox(height: 10),
          ],
          if (others.isNotEmpty) ...[
             Text(S.of(context).otherNotes, style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...others.map((n) => _NoteTile(
              note: n,
              onTap: () => _edit(n),
              onPin: () => setState(() => n.pinned = !n.pinned),
              onArchive: () => setState(() { _notes.remove(n); _archived.add(n); }),
            )),
          ] else if (pinned.isEmpty)
             EmptyState(icon: Icons.note_alt_outlined,
                title: S.of(context).noNotesYet),
          const SizedBox(height: 12),
          if (_archived.isNotEmpty) ...[
            const Divider(),
             Text(S.of(context).archive, style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ..._archived.map((n) => _NoteTile(
              note: n,
              archived: true,
              onTap: () {},
              onPin: null,
              onArchive: () => setState(() { _archived.remove(n); _notes.add(n); }),
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
  bool match(String q) => title.toLowerCase().contains(q) || body.toLowerCase().contains(q);
}

class _NoteTile extends StatelessWidget {
  final _NoteModel note;
  final bool archived;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  const _NoteTile({required this.note, this.archived = false, this.onTap, this.onPin, this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kNoteYellow.withOpacity(Theme.of(context).brightness == Brightness.dark ? .12 : .35),
      child: ListTile(
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: onTap,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (onPin != null)
            IconButton(onPressed: onPin, icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined)),
          if (onArchive != null)
            IconButton(onPressed: onArchive, icon: Icon(archived ? Icons.unarchive : Icons.archive_outlined)),
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
              Text(S.of(context).note, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _t,
                decoration:  InputDecoration(labelText: S.of(context).title),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _b,
                minLines: 3,
                maxLines: 8,
                decoration:  InputDecoration(labelText: S.of(context).content),
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
                  Navigator.pop(context, _NoteModel(_t.text.trim(), _b.text.trim(), pinned: _pin));
                },
                icon: const Icon(Icons.save_outlined),
                label:Text(S.of(context).save),

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
// عنصر EmptyHint (لازم لرسائل الفراغ)
// ============================================================================

// ============================================================================
// PART 2/3 — Community (Reddit-like) + Studies Navigator + Table Calculator
// ============================================================================

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
      title: 'Coming soon ',
      body: 'A communication platform for only and all universitys students\n'
          '\n'
          'BE READY FOR IT🔥',
      votes: 100000000,
      tags: const ['communications', 'students', 'universitys',],
    ),

    _Post(
      author: 'CREATOR',
      title: 'Consept of the app',
      body: 'An app for calculating university GPAs for students\n'
          '\nلا تتردد في مراسلتنا في حالة كانت لديك مطالب او اراء في ما يتعلق بالتطبيق '

          '\n'
          '\n'

          'contact us on IG: @klause_ds\n',
      votes: 100000000,
      tags: const ['Consept', 'students', 'GPA',],
    ),
    _Post(
      author: 'CREATOR',
      title: 'Directions to use ',
      body: 'بسبب اختلافات تقييم المواد من جامعة لاخرى ومن سنة دراسية لاخرى قد يجد بعض مستخدمينا اختلافات عن طريقتم في التقييم لدلك فيمكنكم تعديل اعدادات تقييم المواد ودالك من خلال علامة التعجب كما هو موضح في الصورة \n'
          'حيث : W.TD: معامل نقطة الاعمال الموجهة\n'
          'W.EXAM: معامل نقطة الاختبار\n'
          'W.TP:معامل نقطة الاعمال التطبيقية\n ',
      votes: 100000000,
      tags: const ['directions', 'app',],
    ),

  ];

  void _newPost() async {
    final p = await showModalBottomSheet<_Post>(
      isScrollControlled: true,
      context: context,
      builder: (_) => const _CreatePostSheet(),
    );
    if (p != null) {
      setState(() => _posts.insert(0, p));
      ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text(S.of(context).post)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0, // حتى يلتصق المحتوى باليسار
        title: Row(
          textDirection: TextDirection.ltr,
          //mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer(); // لأنك تستخدم endDrawer
              },
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
          ],
        ),
       // leadingWidth: canPop ? 96 : null,
        // actions: [
        //   IconButton(
        //     tooltip: 'منشور جديد',
        //     onPressed: _newPost,
        //     icon: const Icon(Icons.add_circle_outline),
        //   ),
        // ],
      ),
      //endDrawer: const AppEndDrawer(),
      padding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newPost,
        icon: const Icon(Icons.edit_note),
        label: Text(S.of(context).createPost),

      ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                        0, _Comment(author: 'you', text: txt.trim())));
                  }
                },
              ),
            ),
    );
  }
}

class _Post {
  final String author;
  final String title;
  final String body;
  final List<String> tags;
  final String? mediaUrl;
  int votes;
  final List<_Comment> comments;
  _Post({
    required this.author,
    required this.title,
    required this.body,
    this.tags = const [],
    this.mediaUrl,
    this.votes = 0,
    List<_Comment>? comments,
  }) : comments = comments ?? [];
}

class _Comment {
  final String author;
  final String text;
  _Comment({required this.author, required this.text});
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final void Function(int delta) onVote;
  final VoidCallback onComment;
  const _PostCard(
      {required this.post, required this.onVote, required this.onComment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Text('u/${post.author}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (_) =>  [
                    PopupMenuItem(value: 'share', child: Text(S.of(context).share),),
                    PopupMenuItem(value: 'report', child:Text(S.of(context).report),
    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: theme.textTheme.titleMedium,
            ),
            if (post.body.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.body, style: theme.textTheme.bodyMedium),
            ],
            if (post.mediaUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.mediaUrl!,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags
                    .map((t) => NumberChip(text: t))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => onVote(1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Directionality(
                    key: ValueKey(post.votes),
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${post.votes}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onVote(-1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                const SizedBox(width: 0),
                TextButton.icon(
                  onPressed: onComment,
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text(S.of(context).comments),
//${post.comments.length})
                ),
              ],
            ),
            if (post.comments.isNotEmpty) ...[
              const Divider(height: 24),
              ...post.comments.take(4).map(
                (c) => ListTile(
                  leading: const Icon(Icons.comment, size: 20),
                  title: Text('u/${c.author}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text(c.text),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _media = TextEditingController();
  final _tag = TextEditingController();
  final List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(S.of(context).newPost,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration:  InputDecoration(labelText: S.of(context).title),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _body,
              minLines: 2,
              maxLines: 6,
              decoration:  InputDecoration(labelText: S.of(context).content),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _media,
              decoration: InputDecoration(
                  labelText: S.of(context).mediaUrl),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tag,
                    decoration: const InputDecoration(labelText: '#'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: () {
                      final t = _tag.text.trim();
                      if (t.isNotEmpty) {
                        setState(() {
                          _tags.add(t);
                          _tag.clear();
                        });
                      }
                    },
                    child: Text(S.of(context).add),),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _tags
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () => setState(() => _tags.remove(t)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                if (_title.text.trim().isEmpty &&
                    _body.text.trim().isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                Navigator.pop(
                    context,
                    _Post(
                      author: 'you',
                      title: _title.text.trim(),
                      body: _body.text.trim(),
                      mediaUrl: _media.text.trim().isEmpty
                          ? null
                          : _media.text.trim(),
                      tags: _tags,
                      votes: 1,
                    ));
              },
              icon: const Icon(Icons.send),
              label: Text(S.of(context).publish),

            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog();
  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).comment),
      content: TextField(
        controller: _c,
        minLines: 2,
        maxLines: 4,
        decoration:  InputDecoration(hintText: S.of(context).writeComment,)
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),),
        FilledButton(
            onPressed: () =>
                Navigator.pop(context, _c.text.trim()),
            child: Text(S.of(context).posted)),
      ],
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
  final List<NoteData> subjects = [];
  double threshold = 10;
  double avg = 0;
  double totalcred = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).quickCalc),),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...subjects.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: NoteCardWidget(
                key: ValueKey(s),
                data: s,
                onDelete: () => setState(() => subjects.removeAt(i)),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context).add),),
              const SizedBox(width: 8),
              FilledButton.icon(
                  onPressed: _calc,
                  icon: const Icon(Icons.calculate,),
                  label: Text(S.of(context).calculate),),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.save),
                label: Text(S.of(context).save,)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(textDirection: TextDirection.ltr,
                  children: [
              Text(
                'Moy: ${avg.toStringAsFixed(2)} /         ',
                textDirection: TextDirection.ltr,
                  style: TextStyle(fontWeight: FontWeight.w800,

                      fontSize: 18),),
                    Text(
                      avg == 0
                          ? '___'
                          : (avg >= threshold ? "✅ Succeeded" : "❌ Failed"),
                      style: TextStyle(
                        color: avg == 0
                            ? Colors.grey
                            : (avg >= threshold ? Colors.green : Colors.red),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    )
                  ]
              ),
              const SizedBox(height: 12),
              Align( alignment: Alignment.centerLeft, child:
              Text(
                'Cred: $totalcred',textDirection: TextDirection.ltr,
                style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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

// -------------------------
// واجهة البطاقة
// -------------------------
class NoteCardWidget extends StatefulWidget {
  final NoteData data;
  final VoidCallback onDelete;

  const NoteCardWidget({
    super.key,
    required this.data,
    required this.onDelete,
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
    tdController = TextEditingController(text: widget.data.td== 0 ? '' : widget.data.td.toString());
    examController = TextEditingController(text: widget.data.exam== 0 ? '' : widget.data.exam.toString());
    tpController = TextEditingController(text: widget.data.tp== 0 ? '' : widget.data.tp.toString());
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
              IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent)),
              Container(
                width: 150,
                height: 40,
                alignment: Alignment.center,

                child: TextField(

                  controller: nameController,
                  onChanged: (v) {
                    widget.data.subject = v;
                    setState(() {});
                  },
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,),

                ),
              ),const SizedBox(width: 46,),
              Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                    color: Colors.transparent, ),
                child: Text(

                  widget.data.moy.toStringAsFixed(2),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  icon: Icon(expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down))
            ],
          ),
          if (expanded)
            Row(crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment:MainAxisAlignment.spaceBetween ,
              children: [

                const Divider(),

                // Coef & Cred أولاً
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  //mainAxisSize: MainAxisSize.min,
                  children: [
                    //coef
                    Container(
                      width: 70,
                      child: Column(
                        children: [
                          const Text("Coef"),
                          SizedBox(width: 200,),
                          TextField(
                            controller: coefController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              counterText: '',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 5, ),
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
                    const SizedBox(height:  10),
                    //cred
                    Container(
                      width: 70,

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
                              contentPadding: EdgeInsets.symmetric(vertical: 5, ),
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
                //const SizedBox(width:  12),
                Container(color: Theme.of(context).colorScheme.onSurface,height: 180,width: 1,),
                //const SizedBox(width:  12),

                Row(children: [

                // wTD / wTP / wExam
                  Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScoreField("W.TD", WtdController, (v) {
                      widget.data.Wtd = double.tryParse(v) ?? 0;
                      setState(() {});
                    }),
                    const SizedBox(height: 5),
                    Container(color: Theme.of(context).colorScheme.onSurface,height: 1,width: 70,),
                    _buildScoreField("W.TP", WtpController, (v) {
                      widget.data.Wtp = double.tryParse(v) ?? 0;
                      setState(() {});
                    }),
                    const SizedBox(height: 5),
                    Container(color: Theme.of(context).colorScheme.onSurface,height: 1,width: 70,),
                    _buildScoreField("W.EX", WexamController, (v) {
                      widget.data.Wexam = double.tryParse(v) ?? 0;
                      setState(() {});
                    }),
                  ],
                ),
                  const SizedBox(width:  12),
                  // TD / TP / Exam
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreField("TD", tdController, (v) {
                        widget.data.td = double.tryParse(v) ?? 0;
                        setState(() {});
                      }),
                      const SizedBox(height: 5),
                      Container(color: Theme.of(context).colorScheme.onSurface,height: 1,width: 70,),
                      _buildScoreField("TP", tpController, (v) {
                        widget.data.tp = double.tryParse(v) ?? 0;
                        setState(() {});
                      }),
                      const SizedBox(height: 5),
                      Container(color: Theme.of(context).colorScheme.onSurface,height: 1,width: 70,),
                      _buildScoreField("Exam",
                          examController, (v) {
                            widget.data.exam = double.tryParse(v) ?? 0;
                            setState(() {});
                          }),
                    ],
                  ),
                ])
              ],
            )
        ],
      ),
    );
  }

  Widget _buildScoreField(
      String label, TextEditingController controller, Function(String) onChange) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          height: 40,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (v) => onChange(v),
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(top: 2, bottom: 0, left: 0, right: 0),
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
  final String name;
  final double coef;
  final double credits;
  final List<EvalWeight> evalWeights;
  const ModuleSpec({
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
  return track.semesters.map(
        (sem) {
      // جمع كل modules من كل الوحدات داخل السداسي
      final allModules = sem.unit
          .expand((u) => u.modules)
          .toList(growable: false);

      return SemesterSpec(
        name: sem.label,
        modules: allModules
            .map(
              (module) => ModuleSpec(
            name: module.name,
            coef: module.coef.toDouble(),
            credits: module.credits.toDouble(),
            evalWeights: _normalizeEvalWeights(module.components),
          ),
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

class ModuleModel {

  ModuleModel({
    required this.title,
    required num coef,
    required num credits,
    required double tdWeight,
    required double tpWeight,
    required double examWeight,
  })
      : coef = coef.toDouble(),
        credits = credits.toDouble(),
        _hasTD = tdWeight > 0,
        _hasTP = tpWeight > 0,
        wTD = tdWeight / 100,
        wTP = tpWeight / 100,
        wEX = examWeight / 100,
        td = null,
        tp = null,
        exam = null
  ;

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
  double ?tdWeight = 0.4;
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
        title: module.name,
        coef: module.coef,
        credits: module.credits,
        tdWeight: weightFor('TD'),
        tpWeight: weightFor('TP'),
        examWeight: weightFor('EXAM'),
      );
    }).toList(growable: false);

    return SemesterModel(name: spec.name, modules: modules, onChanged: onChanged);
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
    return modules.fold<double>
      (0, (sum, module) => sum + moduleCreditsEarned(module));
  }
  SemesterModel convertProgramSemester(
      ProgramSemester ps,
      VoidCallback onChanged,
      ) {
    return SemesterModel(
      name: ps.label,
      onChanged: onChanged,
      modules: ps.unit.expand((u) => u.modules) // جمع modules من جميع الوحدات
          .map((m) {
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
                .withOpacity(theme.brightness == Brightness.dark ? .35 : .6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FacultyMajorsScreen(faculty: f)),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                  foregroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.apartment_rounded),
                ),
                title: Text(f.name),
                subtitle: Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
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
      appBar: AppBar(
        automaticallyImplyLeading:true,
        title: Text(faculty.name)
      ),
      endDrawer: const AppEndDrawer(),
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
        title: Text(major.name,)
      ),
      endDrawer: const AppEndDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...tracksByLevel.entries.map((entry) {
            final level = entry.key;
            final tracks = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align( alignment: Alignment.centerLeft, child:
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
                                .withOpacity(.4),
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
                                  programName:
                                  '${major.name} • ${track.name}',
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
  final SemesterSpec semester1Modules;
  final SemesterSpec semester2Modules;

  const StudiesTableScreen({
    super.key,
    required this.facultyName,
    required this.programName,
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
  final GradesLocalStore _gradesStore = GradesLocalStore();

  int currentIndex = 0; // ← هذا يمثل index الحالي

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSemesters();
    Future.microtask(() async {
      await loadSemesterNotes();
    });

    // الاستماع لتغييرات الـ index عند التمرير أو الضغط على الـ Tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // تجاهل أثناء التغيير عن طريق الضغط
      setState(() {
        currentIndex = _tabController.index;
      });
      Future.microtask(() async {
        await loadSemesterNotes();});
    });




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
  /// ==================== حفظ بيانات الفصل الحالي باستخدام SharedPreferences ====================
  Future<void> saveCurrentSemesterNotes() async {
    final currentSemester = currentIndex == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name;
    for (final module in currentSemester.modules) {
      final hasValues =
          module.td != null || module.tp != null || module.exam != null;
      final moy = hasValues ? module.moy : null;
      await _gradesStore.saveGrade(
        semesterKey,
        module.title,
        module.td,
        module.exam,
        module.tp,
        moy,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semester notes saved ✅")),
    );
  }

  /// ==================== تحميل بيانات الفصل الحالي من SharedPreferences ====================
  Future<void> loadSemesterNotes() async {
    final currentSemester = currentIndex == 0 ? _semester1 : _semester2;
    final semesterKey = currentSemester.name;

    var updated = false;
    for (final module in currentSemester.modules) {
      final stored = await _gradesStore.loadGrade(semesterKey, module.title);
      if (stored == null) {
        continue;
      }
      module.td = stored['td'];
      module.tp = stored['tp'];
      module.exam = stored['exam'];
      updated = true;
    }

    if (mounted && updated) setState(() {});
  }





  @override
  void didUpdateWidget(covariant StudiesTableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.semester1Modules != widget.semester1Modules ||
        oldWidget.semester2Modules != widget.semester2Modules) {
      _initSemesters();
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




  // Widget _buildSemesterTabContent(SemesterModel semester) {
  //   return Builder(
  //     builder: (context) {
  //       final bottomInset = MediaQuery.of(context).viewInsets.bottom;
  //       const summaryPadding = 220.0;
  //       return AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 250),
  //         child: SingleChildScrollView(
  //           key: ValueKey('${semester.name}_${semester.modules.length}'),
  //           padding: EdgeInsets.fromLTRB(0, 8, 0, summaryPadding + bottomInset),
  //           keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  //           child: buildSemesterTable(context, semester),
  //         ),
  //       );
  //
  //     },
  //   );
  // }

  // Widget _buildStickyHeader(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final subtle = theme.textTheme.bodySmall?.color?.withOpacity(.7);
  //   return Material(
  //     elevation: 2,
  //     color: theme.colorScheme.surface,
  //     child: Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             widget.programName,
  //             style:
  //                 theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           // const SizedBox(height: 10),
  //           // Text(
  //           //   widget.facultyName,
  //           //   style: theme.textTheme.bodyMedium?.copyWith(color: subtle),
  //           // ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final sem1 = _semester1;
    final sem2 = _semester2;
    final canPop = Navigator.canPop(context);

    return AppScaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: true,
      //   title: Text(widget.facultyName),
      //   leading: _DrawerLeading(showBack: canPop),
      //   leadingWidth: canPop ? 96 : null,
      // ),
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

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
                initialTd: module.td,
                initialTp: module.tp,
                initialExam: module.exam,

                onChanged: (td, tp, exam, moy, coef, cred) {
                  module.td = td;
                  module.tp = tp;
                  module.exam = exam;
                  module.coef = coef;
                  module.credits = cred;
                  module.wTD = module.wTD;
                  module.wEX = module.wEX;
                  module.wTP = module.wTP;

                  // يعيد حساب كل شيء
                  sem.recompute();

                  // لتحديث الواجهة
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
  }

  @override
  void dispose() {
    _tdController.dispose();
    _tpController.dispose();
    _examController.dispose();
    super.dispose();
  }

  String _formatGrade(double? value) {
    if (value == null) return '';
    return value.toString();
  }

  double? _parseGrade(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized);
  }
  void onTDChanged(String v) {
    setState(() {
      td = _parseGrade(v);
      calculateMoy();
      notifyParent();
    });
  }
  void notifyParent() {
    widget.onChanged(td, tp, exam, moy, coef, cred);
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
            ? Colors.red
            : Colors.green,
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

                      FutureBuilder<String>(
                        future: translateSubject(context,widget.subject),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('...'); // أثناء التحميل
                          } else if (snapshot.hasError) {
                            return Text(widget.subject); // fallback عند الخطأ
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
                              controller: TextEditingController(text: coef.toStringAsFixed(0)),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final newValue = double.tryParse(v);
                                if (newValue != null) setState(() => coef = newValue);

                              }
                              ,
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
                           controller:
                           TextEditingController(text: cred.toStringAsFixed(0)),
                           keyboardType: TextInputType.number,
                           onChanged: (v) {
                             final newValue = double.tryParse(v);
                             if (newValue != null) setState(() => cred = newValue);

                           },
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
      ? Colors.red
          : Colors.green,),

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
  final bool showS1;     // عرض بطاقة S1
  final bool showS2;     // عرض بطاقة S2


  Widget buildInfoCard(String title, double value, IconData icon, BuildContext cx) {
    return Container(
      width: 150,
      height: 63,
      padding: const EdgeInsets.fromLTRB(15, 10, 5, 2),
      decoration: BoxDecoration(
        color: Theme.of(cx).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 2, color: Theme.of(cx).colorScheme.onSurface),
      ),
      child: Column(
        children: [Row(
            children: [
          Icon(icon, size: 20),
              const SizedBox(width: 5,),
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
              textDirection: TextDirection.ltr,   // ← يمنع الانعكاس داخل البطاقة فقط
              child:
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Align(
              alignment: Alignment.centerLeft,
              child: Text("S1 Résumé",
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoCard("S1 Moyenne", moy1, Icons.filter_1, context),
                    buildInfoCard("S1 Credits", S1cred, Icons.auto_graph, context),
                  ],
                ),
              ],
            ),
          )),

        // ---------------------- قسم S2 ----------------------
        if (showS2)
          Directionality(
              textDirection: TextDirection.ltr,   // ← يمنع الانعكاس داخل البطاقة فقط
              child:
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Align(
              alignment: Alignment.centerLeft,
              child: Text("S2 Résumé",
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Row(textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoCard("S2 Moyenne", moy2, Icons.filter_2, context),
                    buildInfoCard("S2 Credits", S2cred, Icons.auto_graph, context),
                  ],
                ),
              ],
            ),
          )),

        // ---------------------- الملخص السنوي ----------------------
        if (showAnnual)
    Directionality(
    textDirection: TextDirection.ltr,   // ← يمنع الانعكاس داخل البطاقة فقط
    child:
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Align(
              alignment: Alignment.centerLeft,
              child: Text("Résumé Annual",
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Row(textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildInfoCard("Année", ann, Icons.verified, context),
                    buildInfoCard("Total Credits", creds, Icons.auto_graph, context),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface
                        ,
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
                    crossAxisAlignment: CrossAxisAlignment.start, // Résultat: في البداية
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
                              : (ann >= 10 ? '✨u Succeeded✨' : 'u Failed ❌'),
                          style:
                          GoogleFonts.dmMono(
                            textStyle:
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: ann == 0
                                ? Theme.of(context).colorScheme.onSurface
                                : ann < 10
                                ? Colors.red
                                : Colors.green,
                          )
                          ),
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
      fontWeight: FontWeight.w600,)),
  Icon(icon, size: 20, ),
  ],
  ),
  const SizedBox(height: 0),
  Text(
  value.toStringAsFixed(2),
  style: const TextStyle(
  fontSize: 20, fontWeight: FontWeight.bold),
  ),
  ],
  ),
  ));
  }



// class _NoteField extends StatelessWidget {
//   const _NoteField({
//     required this.label,
//     required this.enabled,
//     required this.value,
//     required this.onChanged,
//     this.padding = const EdgeInsetsDirectional.only(start: 8),
//   });
//
//   final String label;
//   final bool enabled;
//   final double? value;
//   final ValueChanged<double?> onChanged;
//   final EdgeInsetsGeometry padding;
//
//   @override
//   Widget build(BuildContext context) {
//     final content = _NumField(
//       value: value,
//       onChanged: onChanged,
//       width: 64,
//       decimalPlaces: 2,
//       inputRangePattern: RegExp(r'^(?:|[0-1]?\d(?:[.]\d{0,2})?|20(?:[.]0{0,2})?)$'),
//     );
//     final field = enabled
//         ? content
//         : IgnorePointer(child: Opacity(opacity: 0.35, child: content));
//
//     return Padding(
//       padding: padding,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label, style: Theme.of(context).textTheme.bodySmall),
//           const SizedBox(height: 4),
//           field,
//         ],
//       ),
//     );
//   }
// }

// class _LabeledValueField extends StatelessWidget {
//   const _LabeledValueField({
//     required this.label,
//     required this.value,
//     required this.onChanged,
//   });
//
//   final String label;
//   final double value;
//   final ValueChanged<double?> onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: Theme.of(context).textTheme.bodySmall),
//         const SizedBox(height: 4),
//         _NumField(
//           value: value,
//           width: 72,
//           decimalPlaces: 2,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }
// }

// class _WeightField extends StatelessWidget {
//   const _WeightField({
//     required this.label,
//     required this.enabled,
//     required this.value,
//     required this.onChanged,
//     this.padding = const EdgeInsetsDirectional.only(start: 8),
//   });
//
//   final String label;
//   final bool enabled;
//   final double value;
//   final ValueChanged<double?> onChanged;
//   final EdgeInsetsGeometry padding;
//
//   @override
//   Widget build(BuildContext context) {
//     final content = _NumField(
//       value: value,
//       width: 72,
//       decimalPlaces: 4,
//       onChanged: onChanged,
//     );
//     final field = enabled
//         ? content
//         : IgnorePointer(child: Opacity(opacity: 0.35, child: content));
//
//     return Padding(
//       padding: padding,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label, style: Theme.of(context).textTheme.bodySmall),
//           const SizedBox(height: 8),
//           field,
//         ],
//       ),
//     );
//   }
// }



// ============================================================================
// PART 3/3 — Helpers, Colors, Studies helpers, Compatibility adapters
// ============================================================================

// لون خفيف للوسوم/الشرائح في المجتمع
// امتداد آمن للسلاسل (إن لم يكن موجوداً في أجزاء سابقة)
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
    MaterialPageRoute(builder: (_) => FacultiesScreen(faculties:  getDemoFaculties(context))),
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                    : decisionColor.withOpacity(0.10),
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
                    child:
                  Text(
                    'Decision :',
                    textDirection: TextDirection.ltr,

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )),
                  const SizedBox(height: 8),

                  Row(textDirection: TextDirection.ltr,
                    children: [
                      // -------- بطاقة المعدل السنوي --------
                      Expanded(
                        child: Container(
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
                                'Année',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
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
            )


            ,const SizedBox(height: 20),



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

  Widget _buildSemesterSummaryRow(String label, double moy, double creds, BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;

    final Color color = moy == 0
        ? scheme.onSurface.withOpacity(0.6)
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

  Widget _buildModuleListSection(BuildContext context, String title, List<ModuleModel> modules) {
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
            style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
          ),
        ],
      );
    }

    return Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
        alignment: Alignment.centerLeft,
        child:
        Text(
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
                icon: Icon(Icons.info_outline, size: 20, color: scheme.onSurface),
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
          future: translateSubject(context,m.title),
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
          TextButton(onPressed: () => Navigator.pop(context),
              child:  Text(S.of(context).close)),
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
    final pdf = pw.Document();

    // حساب المتوسطات
    final moy1 = semester1.semesterAverage();
    final moy2 = semester2.semesterAverage();
    final ann = (moy1 + moy2) / 2;

    final cred1 = semester1.creditsEarned();
    final cred2 = semester2.creditsEarned();
    final totalCred = cred1 + cred2;

    final decision =
    ann == 0 ? '---' : (ann >= 10 ? 'SUCCEED' : 'FAILED');
    final regularFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Tajawal-Regular.ttf"));
    final boldFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Tajawal-Bold.ttf"));

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) =>
        [
          pw.Text("Université ",
              style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.Text("Faculté : $faculty", style: pw.TextStyle(font: regularFont)),
          pw.Text("Programme : $program", style: pw.TextStyle(font: regularFont)),
          pw.SizedBox(height: 20),

          _sectionTitle("DÉCISION", font: boldFont),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Année : ${ann.toStringAsFixed(2)}",
                  style: pw.TextStyle(font: regularFont,fontSize: 16)),

              pw.Text("Total Crédits : $totalCred",
              style: pw.TextStyle(font: regularFont,fontSize: 16)),
              pw.Text("Résultat : $decision",
                  style: pw.TextStyle(font: regularFont,fontSize: 16),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          _sectionTitle("SEMESTRE 1", font: boldFont),
          pw.SizedBox(height: 10),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children:[
          pw.Text("Moyenne S1 : ${moy1.toStringAsFixed(2)}",
              style: pw.TextStyle(font: regularFont,fontSize: 16)),
          pw.Text(
              "Crédits S1 : $cred1",
              style: pw.TextStyle(font: regularFont,fontSize: 16))]),
          pw.SizedBox(height: 10),
          _modulesTable(semester1.modules, font: regularFont),
          pw.SizedBox(height: 10),

          _sectionTitle("SEMESTRE 2", font: boldFont),
          pw.SizedBox(height: 10),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children:[
          pw.Text("Moyenne S2 : ${moy2.toStringAsFixed(2)}",
              style: pw.TextStyle(font: regularFont,fontSize: 16)),
          pw.Text(
              "Crédits S2 : $cred2",
              style: pw.TextStyle(font: regularFont,fontSize: 16)),]),
          pw.SizedBox(height: 10),
          _modulesTable(semester2.modules, font: regularFont),

          // pw.SizedBox(height: 10),
          // _sectionTitle("Résumé Annuel", font: boldFont),
          // pw.SizedBox(height: 10),
          // pw.Text("Moyenne Année : ${ann.toStringAsFixed(2)}",
          //     style: pw.TextStyle(font: regularFont)),
          // pw.Text("Total Crédits : $totalCred",
          //     style: pw.TextStyle(font: regularFont)),
          // pw.Text("Résultat Final : $decision",
          //     style: pw.TextStyle(font: regularFont)),
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


  static pw.Widget _modulesTable(List<ModuleModel> modules,
      {required pw.Font font}) {
    return pw.Table.fromTextArray(
      headers: ["Module", "Coef", "Cred", "Moy"],
      data: modules.map((m) {
        return [
          m.title,
          m.coef.toString(),
          m.credits.toString(),
          m.moy.toStringAsFixed(2),
        ];
      }).toList(),
      cellStyle: pw.TextStyle(fontSize: 11, font: font),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
        font: font,
      ),
      border: pw.TableBorder.all(),
      cellAlignment: pw.Alignment.centerLeft,

    );
  }


}


// زر اختصار يفتح الدراسة (للاستخدام داخل AppBar.actions)
// class StudiesActionButton extends StatelessWidget {
//   const StudiesActionButton({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       tooltip: 'الدراسة (كليات → تخصّصات → مسارات → جدول)',
//       icon: const Icon(Icons.menu_book_outlined),
//       onPressed: () => openStudiesNavigator(context),
//     );
//   }
// }

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
