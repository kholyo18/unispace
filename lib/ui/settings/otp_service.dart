import 'package:cloud_functions/cloud_functions.dart';

class OtpSendResult {
  const OtpSendResult({
    required this.cooldownSeconds,
    required this.expiresInSeconds,
  });

  final int cooldownSeconds;
  final int expiresInSeconds;
}

class OtpService {
  OtpService._();

  static final OtpService instance = OtpService._();

  Future<OtpSendResult> sendEmailOtp({required String email}) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('sendEmailVerificationOtp');
    final result = await callable.call(<String, dynamic>{
      'email': email,
    });
    final data = result.data as Map<Object?, Object?>?;
    final cooldownSeconds = (data?['cooldownSeconds'] as num?)?.toInt() ?? 60;
    final expiresInSeconds = (data?['expiresInSeconds'] as num?)?.toInt() ?? 600;
    return OtpSendResult(
      cooldownSeconds: cooldownSeconds,
      expiresInSeconds: expiresInSeconds,
    );
  }
}
