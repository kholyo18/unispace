import 'package:firebase_auth/firebase_auth.dart';

import 'session_service.dart';

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
    final currentSessionId = await SessionService.instance.getOrCreateSessionId();
    await SessionService.instance.deleteAllOtherSessions(
      uid: user.uid,
      currentSessionId: currentSessionId,
    );
    await FirebaseAuth.instance.signOut();
    return const LogoutAllResult(
      signedOut: true,
      backendSupported: true,
    );
  }
}
