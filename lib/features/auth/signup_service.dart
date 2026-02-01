import 'package:firebase_auth/firebase_auth.dart';

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
  SignupService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  String? _pendingEmail;
  String? _pendingSessionId;

  Future<UsernameAvailability> checkUsername(String username) async {
    return const UsernameAvailability(available: true);
  }

  Future<StartSignupResult> startSignup({
    required String email,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    _pendingEmail = email;
    _pendingSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    return StartSignupResult(
      sessionId: _pendingSessionId!,
      expiresInSeconds: 0,
      cooldownSeconds: 0,
    );
  }

  Future<void> resendOtp(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw SignupServiceException('تعذر إعادة إرسال الرمز الآن.');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw SignupServiceException(_mapAuthError(e));
    } on SignupServiceException {
      rethrow;
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
      final email = _pendingEmail;
      if (email == null || email.isEmpty) {
        throw SignupServiceException('تعذر تأكيد التسجيل.');
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw SignupServiceException('تعذر تأكيد التسجيل.');
      }
      await user.sendEmailVerification();
      return VerifySignupResult(customToken: user.uid);
    } on FirebaseAuthException catch (e) {
      throw SignupServiceException(_mapAuthError(e));
    } on SignupServiceException {
      rethrow;
    } catch (_) {
      throw SignupServiceException('تعذر تأكيد التسجيل الآن.');
    }
  }

  Future<void> signInWithCustomToken(String token) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == token) {
      return;
    }
    throw SignupServiceException('تعذر تسجيل الدخول الآن.');
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة.';
      case 'operation-not-allowed':
        return 'التسجيل غير متاح حاليًا.';
      case 'user-disabled':
        return 'هذا الحساب معطل.';
      case 'user-not-found':
        return 'الحساب غير موجود.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      default:
        return error.message ?? 'حدث خطأ غير متوقع.';
    }
  }
}
