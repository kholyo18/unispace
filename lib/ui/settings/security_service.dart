import 'package:firebase_auth/firebase_auth.dart';

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
    // TODO: Wire backend session revocation (Cloud Functions / Admin SDK).
    await FirebaseAuth.instance.signOut();
    return const LogoutAllResult(
      signedOut: true,
      backendSupported: false,
    );
  }
}
