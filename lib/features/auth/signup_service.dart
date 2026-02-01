import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';

class SignupServiceException implements Exception {
  SignupServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UsernameAvailability {
  const UsernameAvailability({required this.available, this.reason});

  final bool available;
  final String? reason;
}

class StartSignupResult {
  const StartSignupResult({
    required this.sessionId,
    required this.expiresInSeconds,
    required this.cooldownSeconds,
  });

  final String sessionId;
  final int expiresInSeconds;
  final int cooldownSeconds;
}

class VerifySignupResult {
  const VerifySignupResult({required this.customToken});

  final String customToken;
}

class SignupService {
  SignupService({FirebaseFunctions? functions, FirebaseAuth? auth})
      : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<UsernameAvailability> checkUsername(String username) async {
    try {
      final callable = _functions.httpsCallable('checkUsername');
      final result = await callable.call(<String, dynamic>{
        'username': username,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return UsernameAvailability(
        available: data['available'] == true,
        reason: data['reason'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw SignupServiceException(_mapFunctionsError(e));
    } catch (_) {
      throw SignupServiceException('تعذر التحقق من اسم المستخدم الآن.');
    }
  }

  Future<StartSignupResult> startSignup({
    required String email,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      final callable = _functions.httpsCallable('startSignup');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return StartSignupResult(
        sessionId: data['sessionId'] as String,
        expiresInSeconds: (data['expiresInSeconds'] as num).toInt(),
        cooldownSeconds: (data['cooldownSeconds'] as num).toInt(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw SignupServiceException(_mapFunctionsError(e));
    } catch (_) {
      throw SignupServiceException('تعذر بدء التسجيل الآن.');
    }
  }

  Future<void> resendOtp(String sessionId) async {
    try {
      final callable = _functions.httpsCallable('resendOtp');
      await callable.call(<String, dynamic>{
        'sessionId': sessionId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw SignupServiceException(_mapFunctionsError(e));
    } catch (_) {
      throw SignupServiceException('تعذر إعادة إرسال الرمز الآن.');
    }
  }

  Future<VerifySignupResult> verifyOtpAndCreateAccount({
    required String sessionId,
    required String otp,
    required String password,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyOtpAndCreateAccount');
      final result = await callable.call(<String, dynamic>{
        'sessionId': sessionId,
        'otp': otp,
        'password': password,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final token = data['customToken'] as String?;
      if (token == null || token.isEmpty) {
        throw SignupServiceException('تعذر تأكيد التسجيل.');
      }
      return VerifySignupResult(customToken: token);
    } on FirebaseFunctionsException catch (e) {
      throw SignupServiceException(_mapFunctionsError(e));
    } on SignupServiceException {
      rethrow;
    } catch (_) {
      throw SignupServiceException('تعذر تأكيد التسجيل الآن.');
    }
  }

  Future<void> signInWithCustomToken(String token) async {
    await _auth.signInWithCustomToken(token);
  }

  String _mapFunctionsError(FirebaseFunctionsException error) {
    switch (error.message) {
      case 'username_taken':
        return 'اسم المستخدم مستعمل بالفعل.';
      case 'invalid_username':
        return 'اسم المستخدم غير صالح.';
      case 'session_not_found':
        return 'جلسة التحقق غير موجودة. حاول إعادة التسجيل.';
      case 'otp_expired':
        return 'انتهت صلاحية رمز التحقق. أعد الإرسال.';
      case 'otp_invalid':
        return 'رمز التحقق غير صحيح.';
      case 'otp_attempts_exceeded':
        return 'تم تجاوز عدد المحاولات. أعد التسجيل.';
      case 'resend_limit':
        return 'تم تجاوز حد إعادة الإرسال.';
      case 'cooldown_active':
        return 'يرجى الانتظار قبل إعادة الإرسال.';
      case 'email_in_use':
        return 'البريد الإلكتروني مستخدم بالفعل.';
      default:
        switch (error.code) {
          case 'invalid-argument':
            return 'البيانات المدخلة غير صحيحة.';
          case 'already-exists':
            return 'البيانات مستخدمة بالفعل.';
          case 'failed-precondition':
            return 'تعذر إكمال الطلب. حاول لاحقًا.';
          case 'resource-exhausted':
            return 'تم تجاوز الحدود المسموح بها. حاول لاحقًا.';
          case 'unavailable':
            return 'الخدمة غير متاحة حاليًا.';
          default:
            return error.message ?? 'حدث خطأ غير متوقع.';
        }
    }
  }
}
