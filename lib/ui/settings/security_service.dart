import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'session_service.dart';
import '../../services/auth_session_service.dart';

class LogoutAllResult {
  const LogoutAllResult({
    required this.signedOut,
    required this.backendSupported,
  });

  final bool signedOut;
  final bool backendSupported;
}

class SecurityService {
  SecurityService._();

  static final SecurityService instance = SecurityService._();

  Future<LogoutAllResult> logoutAllDevices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed in user');
    }
    // No silent fallback: success means the server revoked refresh tokens.
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('revokeAllUserSessions').call();
    if (result.data is! Map || result.data['revoked'] != true) {
      throw StateError('The server did not confirm revocation');
    }
    await SessionService.instance.clearCurrentSessionId(user.uid);
    await AuthSessionService.signOutFully();
    return const LogoutAllResult(
      signedOut: true,
      backendSupported: true,
    );
  }
}
