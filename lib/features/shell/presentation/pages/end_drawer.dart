import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/branding.dart';
import '../../../../../generated/l10n.dart';
import 'package:app_links/app_links.dart' as deep_links;
import 'package:UniSpace/features/shell/UniSpace_App.dart';
import 'package:UniSpace/main.dart';

// class AppEndDrawer extends StatefulWidget {
//   const AppEndDrawer({super.key});
//
//   @override
//   State<AppEndDrawer> createState() => _AppEndDrawerState();
// }
//
// class _AppEndDrawerState extends State<AppEndDrawer> {
//   static const bool _showPrivacyAndContactInDrawer = false;
//   static const _privacyHideMenuKey = 'privacy_hide_menu_item';
//   bool _sendingOtp = false;
//   int _otpCooldownSeconds = 0;
//   Timer? _otpTimer;
//   bool _hidePrivacyEntry = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPrivacyDrawerVisibility();
//   }
//
//   Future<void> _loadPrivacyDrawerVisibility() async {
//     final prefs = await SharedPreferences.getInstance();
//     final hidden = prefs.getBool(_privacyHideMenuKey) ?? false;
//     if (!mounted) return;
//     setState(() => _hidePrivacyEntry = hidden);
//   }
//
//   Future<void> _sendOtp(User user) async {
//     if (_sendingOtp) return;
//     if (_otpCooldownSeconds > 0) return;
//     setState(() => _sendingOtp = true);
//     try {
//       final result = await EmailVerificationService.instance.sendOtp(user: user);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(S.of(context).otpSentSuccess)),
//       );
//       _startOtpCooldown(result.cooldownSeconds);
//     } catch (error) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(S.of(context).otpSentFailed)),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _sendingOtp = false);
//       }
//     }
//   }
//
//   void _startOtpCooldown(int seconds) {
//     _otpTimer?.cancel();
//     setState(() => _otpCooldownSeconds = seconds);
//     _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       if (_otpCooldownSeconds <= 1) {
//         timer.cancel();
//         setState(() => _otpCooldownSeconds = 0);
//       } else {
//         setState(() => _otpCooldownSeconds -= 1);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _otpTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _rateApp() async {
//     final launched = await launchUrl(
//       Uri.parse(AppLinks.storeUrl),
//       mode: LaunchMode.externalApplication,
//     );
//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(S.of(context).rateAppFailed)),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final app = UniSpaceApp.of(context);
//     final theme = Theme.of(context);
//
//     return SafeArea(
//       child: Drawer(
//         child: StreamBuilder<User?>(
//           stream: FirebaseAuth.instance.userChanges(),
//           initialData: FirebaseAuth.instance.currentUser,
//           builder: (context, authSnapshot) {
//             final user = authSnapshot.data;
//             return ValueListenableBuilder<UserProfileData>(
//               valueListenable: UserProfileService.instance.notifier,
//               builder: (context, profile, _) {
//                 final displayName = user?.displayName ??
//                     user?.email?.split('@').first ??
//                     S.of(context).guestUser;
//                 final emailText = user?.email == null
//                     ? S.of(context).emailUnavailable
//                     : profile.showEmailInProfile
//                     ? user!.email!
//                     : S.of(context).emailHidden;
//                 final isVerified = user?.emailVerified ?? false;
//
//                 return ListView(
//                   padding: EdgeInsets.zero,
//                   children: [
//                     Container(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [kUniSpaceBlue, kUniSpaceGreen],
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               const CircleAvatar(
//                                 backgroundColor: Colors.white,
//                                 child: Icon(
//                                   Icons.person,
//                                   color: kUniSpaceBlue,
//                                   size: 30,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       displayName,
//                                       style: theme.textTheme.titleMedium?.copyWith(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       emailText,
//                                       style: theme.textTheme.bodySmall?.copyWith(
//                                         color: Colors.white70,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (user?.email != null) ...[
//                             const SizedBox(height: 12),
//                             Wrap(
//                               spacing: 8,
//                               runSpacing: 8,
//                               crossAxisAlignment: WrapCrossAlignment.center,
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 6,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: isVerified
//                                         ? Colors.green.withValues(alpha: 0.2)
//                                         : Colors.orange.withValues(alpha: 0.2),
//                                     borderRadius: BorderRadius.circular(999),
//                                     border: Border.all(
//                                       color: isVerified
//                                           ? Colors.green.shade200
//                                           : Colors.orange.shade200,
//                                     ),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(
//                                         isVerified
//                                             ? Icons.verified
//                                             : Icons.warning_amber_rounded,
//                                         size: 16,
//                                         color: isVerified
//                                             ? Colors.green.shade200
//                                             : Colors.orange.shade200,
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         isVerified
//                                             ? S.of(context).emailVerified
//                                             : S.of(context).emailNotVerified,
//                                         style: theme.textTheme.bodySmall?.copyWith(
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 if (!isVerified)
//                                   TextButton.icon(
//                                     onPressed: _sendingOtp || _otpCooldownSeconds > 0
//                                         ? null
//                                         : () => _sendOtp(user!),
//                                     icon: _sendingOtp
//                                         ? const SizedBox(
//                                       width: 16,
//                                       height: 16,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                         : const Icon(Icons.mark_email_unread),
//                                     label: Text(
//                                       _otpCooldownSeconds > 0
//                                           ? S.of(context)
//                                           .otpCooldownLabel(_otpCooldownSeconds)
//                                           : S.of(context).sendOtpNow,
//                                     ),
//                                     style: TextButton.styleFrom(
//                                       foregroundColor: Colors.white,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     _sectionHeader(context, S.of(context).drawerSectionAccount),
//                     _drawerItem(
//                       context,
//                       icon: Icons.person_outline,
//                       title: S.of(context).editProfile,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ProfileScreen(),
//                           ),
//                         );
//                       },
//                     ),
//
//
//                     _sectionHeader(context, S.of(context).drawerSectionStudent),
//                     _drawerItem(
//                       context,
//                       icon: Icons.school_outlined,
//                       title: S.of(context).gpu,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const HomeLandingScreen(),
//                           ),
//                         );
//                       },
//                     ),
//
//
//                     _sectionHeader(context, S.of(context).drawerSectionContent),
//                     _drawerItem(
//                       context,
//                       icon: Icons.download_outlined,
//                       title: S.of(context).downloadsTitle,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const DownloadsScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                     // _drawerItem(
//                     //   context,
//                     //   icon: Icons.star_border,
//                     //   title: S.of(context).favoritesTitle,
//                     //   onTap: () {
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (_) => const FavoritesScreen(),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//
//                     _drawerItem(
//                       context,
//                       icon: Icons.note_alt_outlined,
//                       title: S.of(context).clipboard,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const NotesScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.psychology_outlined,
//                       title: S.of(context).smartReviewPlanTitle,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const SmartReviewPlanPage(),
//                           ),
//                         );
//                       },
//                     ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.calendar_month_outlined,
//                       title: S.of(context).examCalendar,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ExamsCalendarPage(),
//                           ),
//                         );
//                       },
//                     ),
//                     _sectionHeader(context, S.of(context).drawerSectionApp),
//                     // _drawerItem(
//                     //   context,
//                     //   icon: Icons.text_fields_outlined,
//                     //   title: S.of(context).fontSizeTitle,
//                     //   onTap: () {
//                     //     Navigator.push(
//                     //       context,
//                     //       MaterialPageRoute(
//                     //         builder: (_) => const FontSizeScreen(),
//                     //       ),
//                     //     );
//                     //   },
//                     // ),
//                     ListTile(
//                       leading: const Icon(Icons.color_lens_outlined),
//                       title: Text(S.of(context).changeTheme),
//                       subtitle: Text(
//                         app._themeMode == ThemeMode.light
//                             ? S.of(context).lightMode
//                             : app._themeMode == ThemeMode.dark
//                             ? S.of(context).darkMode
//                             : S.of(context).systemMode,
//                       ),
//                       onTap: () {
//                         showModalBottomSheet(
//                           context: context,
//                           isScrollControlled: true,
//                           builder: (_) => _ThemeModeSheet(app: app),
//                         );
//                       },
//                     ),
//                     ListTile(
//                       leading: const Icon(Icons.language_outlined),
//                       title: Text(S.of(context).changeLanguage),
//                       subtitle: Text(_langName(app._locale.languageCode)),
//                       onTap: () {
//                         showModalBottomSheet(
//                           context: context,
//                           builder: (_) => _LanguageSheet(),
//                         );
//                       },
//                     ),
//                     if (!_hidePrivacyEntry)
//                       _drawerItem(
//                         context,
//                         icon: Icons.security_outlined,
//                         title: S.of(context).securityPrivacyTitle,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const SecurityPrivacyScreen(),
//                             ),
//                           ).then((_) => _loadPrivacyDrawerVisibility());
//                         },
//                       ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.notifications_outlined,
//                       title: S.of(context).notificationsSettingsTitle,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const NotificationsSettingsScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.star_rate_outlined,
//                       title: S.of(context).rateApp,
//                       onTap: _rateApp,
//                     ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.share_outlined,
//                       title: S.of(context).shareApp,
//                       onTap: () => Share.share(AppLinks.shareMessage),
//                     ),
//                     if (_showPrivacyAndContactInDrawer)
//                       _drawerItem(
//                         context,
//                         icon: Icons.email_outlined,
//                         title: S.of(context).contactUs,
//                         onTap: () {
//                           _showContactDialog(context);
//                         },
//                       ),
//                     _drawerItem(
//                       context,
//                       icon: Icons.info_outline,
//                       title: S.of(context).aboutApp,
//                       onTap: () {
//                         Navigator.of(context).pop();
//                         Navigator.of(context).push(
//                           MaterialPageRoute(
//                             builder: (_) => const AboutScreen(),
//                           ),
//                         );
//                       },
//                     ),
//                     if (_showPrivacyAndContactInDrawer)
//                       _drawerItem(
//                         context,
//                         icon: Icons.privacy_tip_outlined,
//                         title: S.of(context).privacyPolicy,
//                         onTap: () {
//                           Navigator.of(context).pop();
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (_) => const PrivacyPolicyScreen(),
//                             ),
//                           );
//                         },
//                       ),
//                     const SizedBox(height: 8),
//                     const Divider(height: 24),
//                     if (user != null)
//                       _drawerItem(
//                         context,
//                         icon: Icons.logout,
//                         title: S.of(context).logout,
//                         iconColor: Colors.redAccent,
//                         textColor: Colors.redAccent,
//                         onTap: () async {
//                           final currentUser = FirebaseAuth.instance.currentUser;
//                           if (currentUser != null) {
//                             await SessionService.instance.revokeCurrentSession(currentUser.uid);
//                           }
//                           if (kDebugMode) {
//                             debugPrint('[Auth] drawer logout requested');
//                           }
//                           await AuthSessionService.signOutFully();
//                           if (kDebugMode) {
//                             debugPrint('[Auth] logout complete');
//                           }
//                           if (!context.mounted) return;
//                           Navigator.of(context).pop();
//                         },
//                       )
//                     else
//                       _drawerItem(
//                         context,
//                         icon: Icons.login,
//                         title: S.of(context).login,
//                         onTap: () {
//                           if (kDebugMode) {
//                             debugPrint('[Auth] login drawer item tapped while signed out');
//                           }
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     const SizedBox(height: 12),
//                     Center(
//                       child: Text(
//                         'UniSpace © ${DateTime.now().year}',
//                         style: const TextStyle(color: Colors.grey),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                   ],
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionHeader(BuildContext context, String title) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
//       child: Text(
//         title,
//         style: Theme.of(context).textTheme.titleSmall?.copyWith(
//           color: Theme.of(context).colorScheme.primary,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   Widget _drawerItem(
//       BuildContext context, {
//         required IconData icon,
//         required String title,
//         VoidCallback? onTap,
//         Color? iconColor,
//         Color? textColor,
//       }) {
//     final theme = Theme.of(context);
//     return ListTile(
//       leading: Icon(icon, color: iconColor ?? theme.iconTheme.color),
//       title: Text(
//         title,
//         style: TextStyle(color: textColor),
//       ),
//       onTap: onTap,
//     );
//   }
//
//   void _showContactDialog(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) => const ContactUsSheet(),
//     );
//   }
//
//   static String _langName(String code) {
//     switch (code) {
//       case 'fr':
//         return 'Français';
//       case 'en':
//         return 'English';
//       default:
//         return 'العربية';
//     }
//   }
// }
//
// class _ThemeModeSheet extends StatelessWidget {
//   final _UniSpaceAppState app;
//   const _ThemeModeSheet({required this.app});
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(title: Text(S.of(context).chooseTheme)),
//             RadioListTile<ThemeMode>(
//               value: ThemeMode.light,
//               groupValue: app._themeMode,
//               title: Text(S.of(context).light),
//               onChanged: (v) => _apply(context, v!),
//             ),
//             RadioListTile<ThemeMode>(
//               value: ThemeMode.dark,
//               groupValue: app._themeMode,
//               title: Text(S.of(context).dark),
//               onChanged: (v) => _apply(context, v!),
//             ),
//             RadioListTile<ThemeMode>(
//               value: ThemeMode.system,
//               groupValue: app._themeMode,
//               title: Text(S.of(context).system),
//               onChanged: (v) => _apply(context, v!),
//             ),
//             const Divider(height: 8),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: app.tealColor,
//                 child: const Icon(Icons.palette_outlined,
//                     color: Colors.white, size: 20),
//               ),
//               title: const Text('لون التيل'),
//               subtitle: const Text('يُطبَّق على المواضع الخضراء/التيل فقط'),
//               trailing: Container(
//                 width: 26,
//                 height: 26,
//                 decoration: BoxDecoration(
//                   color: app.tealColor,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.black12),
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   showDragHandle: true,
//                   builder: (_) => _AppColorWheelSheet(
//                     title: 'لون التيل',
//                     initial: app.tealColor,
//                     onApply: app.setTealColor,
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: app.primaryColor,
//                 child: const Icon(Icons.brush_outlined,
//                     color: Colors.white, size: 20),
//               ),
//               title: const Text('اللون الأساسي'),
//               subtitle: const Text('أزرار، تبويبات، وحقول الإدخال'),
//               trailing: Container(
//                 width: 26,
//                 height: 26,
//                 decoration: BoxDecoration(
//                   color: app.primaryColor,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.black12),
//                 ),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 showModalBottomSheet(
//                   context: context,
//                   isScrollControlled: true,
//                   showDragHandle: true,
//                   builder: (_) => _AppColorWheelSheet(
//                     title: 'اللون الأساسي',
//                     initial: app.primaryColor,
//                     onApply: app.setPrimaryColor,
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _apply(BuildContext context, ThemeMode m) {
//     app.setThemeMode(m);
//     Navigator.pop(context);
//   }
// }
// class _TealColorSheet extends StatefulWidget {
//   const _TealColorSheet({required this.app});
//   final _UniSpaceAppState app;
//
//   @override
//   State<_TealColorSheet> createState() => _TealColorSheetState();
// }
//
// class _TealColorSheetState extends State<_TealColorSheet> {
//   late HSVColor _hsv;
//
//   @override
//   void initState() {
//     super.initState();
//     _hsv = HSVColor.fromColor(widget.app.tealColor);
//   }
//
//   void _apply() {
//     widget.app.setTealColor(_hsv.toColor());
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final color = _hsv.toColor();
//     final bottom = MediaQuery.of(context).viewInsets.bottom;
//
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'اختر اللون',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 180,
//               child: _ColorWheel(
//                 hsv: _hsv,
//                 onChanged: (v) => setState(() => _hsv = v),
//               ),
//             ),
//             Row(
//               children: [
//                 const Text('السطوع'),
//                 Expanded(
//                   child: Slider(
//                     value: _hsv.value,
//                     onChanged: (v) =>
//                         setState(() => _hsv = _hsv.withValue(v)),
//                     activeColor: color,
//                   ),
//                 ),
//               ],
//             ),
//             Container(
//               height: 36,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: _apply,
//                 child: const Text('اعتماد اللون'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ColorWheel extends StatelessWidget {
//   const _ColorWheel({required this.hsv, required this.onChanged});
//
//   final HSVColor hsv;
//   final ValueChanged<HSVColor> onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final size = min(constraints.maxWidth, constraints.maxHeight);
//         final center = Offset(constraints.maxWidth / 2, size / 2);
//         final radius = size / 2 - 8;
//
//         return GestureDetector(
//           onPanDown: (d) => _update(d.localPosition, center, radius),
//           onPanUpdate: (d) => _update(d.localPosition, center, radius),
//           child: CustomPaint(
//             size: Size(constraints.maxWidth, size),
//             painter: _WheelPainter(hsv: hsv, radius: radius),
//           ),
//         );
//       },
//     );
//   }
//
//   void _update(Offset pos, Offset center, double radius) {
//     final offset = pos - center;
//     final dist = offset.distance.clamp(0.0, radius);
//     final angle = (atan2(offset.dy, offset.dx) * 180 / pi + 360) % 360;
//     onChanged(
//       hsv.withHue(angle).withSaturation((dist / radius).clamp(0.0, 1.0)),
//     );
//   }
// }
//
// class _WheelPainter extends CustomPainter {
//   _WheelPainter({required this.hsv, required this.radius});
//
//   final HSVColor hsv;
//   final double radius;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     const steps = 360;
//
//     for (int i = 0; i < steps; i++) {
//       final paint = Paint()
//         ..shader = SweepGradient(
//           colors: List.generate(
//             7,
//                 (j) => HSVColor.fromAHSV(1, (j * 60) % 360, 1, hsv.value).toColor(),
//           ),
//         ).createShader(Rect.fromCircle(center: center, radius: radius));
//       canvas.drawCircle(center, radius, paint);
//       break;
//     }
//
//     canvas.drawCircle(
//       center,
//       radius,
//       Paint()
//         ..shader = RadialGradient(
//           colors: [
//             HSVColor.fromAHSV(1, 0, 0, hsv.value).toColor(),
//             Colors.transparent,
//           ],
//         ).createShader(Rect.fromCircle(center: center, radius: radius)),
//     );
//
//     final thumbAngle = hsv.hue * pi / 180;
//     final thumbDist = hsv.saturation * radius;
//     final thumb = Offset(
//       center.dx + cos(thumbAngle) * thumbDist,
//       center.dy + sin(thumbAngle) * thumbDist,
//     );
//
//     canvas.drawCircle(thumb, 12, Paint()..color = Colors.white);
//     canvas.drawCircle(thumb, 9, Paint()..color = hsv.toColor());
//   }
//
//   @override
//   bool shouldRepaint(covariant _WheelPainter old) => old.hsv != hsv;
// }
// class _AppColorWheelSheet extends StatefulWidget {
//   const _AppColorWheelSheet({
//     required this.title,
//     required this.initial,
//     required this.onApply,
//   });
//
//   final String title;
//   final Color initial;
//   final Future<void> Function(Color) onApply;
//
//   @override
//   State<_AppColorWheelSheet> createState() => _AppColorWheelSheetState();
// }
//
// class _AppColorWheelSheetState extends State<_AppColorWheelSheet> {
//   late HSVColor _hsv;
//
//   @override
//   void initState() {
//     super.initState();
//     _hsv = HSVColor.fromColor(widget.initial);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final color = _hsv.toColor();
//     final bottom = MediaQuery.of(context).viewInsets.bottom;
//
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               widget.title,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 180,
//               child: _ColorWheel(
//                 hsv: _hsv,
//                 onChanged: (v) => setState(() => _hsv = v),
//               ),
//             ),
//             Row(
//               children: [
//                 const Text('السطوع'),
//                 Expanded(
//                   child: Slider(
//                     value: _hsv.value,
//                     onChanged: (v) =>
//                         setState(() => _hsv = _hsv.withValue(v)),
//                     activeColor: color,
//                   ),
//                 ),
//               ],
//             ),
//             Container(
//               height: 36,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: () async {
//                   await widget.onApply(_hsv.toColor());
//                   if (context.mounted) Navigator.pop(context);
//                 },
//                 child: const Text('اعتماد اللون'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class _LanguageSheet extends StatelessWidget {
//   const _LanguageSheet({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final app = UniSpaceApp.of(context);
//
//     return SafeArea(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             title: Text(S.of(context).chooseLanguage),
//           ),
//           RadioListTile<String>(
//             value: 'ar',
//             groupValue: app._locale.languageCode,
//             title: Text(S.of(context).arabic),
//             onChanged: (_) {
//               app.setLocale(const Locale('ar'));
//               Navigator.pop(context);
//             },
//           ),
//           RadioListTile<String>(
//             value: 'fr',
//             groupValue: app._locale.languageCode,
//             title: const Text("Français"),
//             onChanged: (_) {
//               app.setLocale(const Locale('fr'));
//               Navigator.pop(context);
//             },
//           ),
//           RadioListTile<String>(
//             value: 'en',
//             groupValue: app._locale.languageCode,
//             title: const Text("English"),
//             onChanged: (_) {
//               app.setLocale(const Locale('en'));
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
