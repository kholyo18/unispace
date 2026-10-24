import 'package:firebase_auth/firebase_auth.dart';

/// Sends through Firebase Auth's email action endpoint, not a callable function.
class PasswordResetService {
  PasswordResetService({FirebaseAuth? auth}) : _auth = auth;
  final FirebaseAuth? _auth;

  static bool validEmail(String email) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());

  Future<void> send(String email, String language) async {
    final normalized = email.trim();
    if (!validEmail(normalized)) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    final auth = _auth ?? FirebaseAuth.instance;
    await auth.setLanguageCode(language);
    try {
      await auth.sendPasswordResetEmail(email: normalized);
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether an address has an account.
      if (error.code != 'user-not-found') rethrow;
    }
  }
}
