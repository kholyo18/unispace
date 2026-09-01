import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// class AuthGate extends StatefulWidget {
//   const AuthGate({super.key});
//
//   @override
//   State<AuthGate> createState() => _AuthGateState();
// }
//
// class _AuthGateState extends State<AuthGate> {
//   User? _lastAuthUser;
//
//   Future<bool> _isTwoFactorRequired(User user) async {
//     final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//     final enabled = profile.data()?['twoFactorEnabled'] as bool? ?? false;
//     if (!enabled) return false;
//     return !(await TwoFactorService.instance.isCurrentSessionVerified(user));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<int>(
//       valueListenable: TwoFactorService.instance.authRefresh,
//       builder: (_, __, ___) {
//         return StreamBuilder<User?>(
//           stream: FirebaseAuth.instance.authStateChanges(),
//           builder: (ctx, snap) {
//             if (snap.connectionState == ConnectionState.waiting) {
//               return const Scaffold(body: Center(child: CircularProgressIndicator()));
//             }
//             if (!identical(_lastAuthUser, snap.data)) {
//               _lastAuthUser = snap.data;
//               if (kDebugMode) {
//                 debugPrint(
//                   '[AuthGate] authStateChanges user=${snap.data?.uid ?? 'null'}',
//                 );
//               }
//             }
//             if (!snap.hasData) {
//               if (kDebugMode) {
//                 debugPrint('[AuthGate] routing -> SignInScreen (no user)');
//               }
//               return const SignInScreen();
//             }
//             final user = snap.data!;
//             final isPasswordUser = user.providerData.any((info) => info.providerId == 'password');
//             if (isPasswordUser && !user.emailVerified) {
//               if (kDebugMode) {
//                 debugPrint('[AuthGate] routing -> SignInScreen (email not verified)');
//               }
//               unawaited(
//                 AuthSessionService.signOutFully(
//                   beforeSignOut: () => SessionService.instance.revokeCurrentSession(user.uid),
//                 ),
//               );
//               return const SignInScreen();
//             }
//             if (!isPasswordUser) {
//               if (kDebugMode) {
//                 debugPrint('[AuthGate] routing -> HomeShell (social provider)');
//               }
//               return const HomeShell();
//             }
//             return FutureBuilder<bool>(
//               future: _isTwoFactorRequired(user),
//               builder: (context, twoFactorSnap) {
//                 if (twoFactorSnap.connectionState == ConnectionState.waiting) {
//                   return const Scaffold(body: Center(child: CircularProgressIndicator()));
//                 }
//                 if (twoFactorSnap.data == true) {
//                   if (kDebugMode) {
//                     debugPrint('[AuthGate] routing -> TwoFactorOtpScreen');
//                   }
//                   return TwoFactorOtpScreen(email: user.email ?? '');
//                 }
//                 if (kDebugMode) {
//                   debugPrint('[AuthGate] routing -> HomeShell (authenticated)');
//                 }
//                 return const HomeShell();
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }