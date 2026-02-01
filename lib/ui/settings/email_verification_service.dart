import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationService {
  EmailVerificationService._();

  static final EmailVerificationService instance =
      EmailVerificationService._();

  Future<void> sendOtp({required User user}) async {
    if (user.email == null) {
      throw Exception('Email not available');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    // TODO: Replace with real OTP/email verification flow.
  }
}
