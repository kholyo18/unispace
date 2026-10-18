import 'package:firebase_auth/firebase_auth.dart';

import 'otp_service.dart';

class EmailVerificationService {
  EmailVerificationService._();

  static final EmailVerificationService instance = EmailVerificationService._();

  Future<OtpSendResult> sendOtp({required User user}) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw StateError('Email not available');
    }
    await user.sendEmailVerification();
    return const OtpSendResult(
      cooldownSeconds: 60,
      expiresInSeconds: 0,
    );
  }
}
