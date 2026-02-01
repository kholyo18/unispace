import 'package:firebase_auth/firebase_auth.dart';

import 'otp_service.dart';

class EmailVerificationService {
  EmailVerificationService._();

  static final EmailVerificationService instance =
      EmailVerificationService._();

  Future<OtpSendResult> sendOtp({required User user}) async {
    if (user.email == null) {
      throw Exception('Email not available');
    }
    return OtpService.instance.sendEmailOtp(email: user.email!);
  }
}
