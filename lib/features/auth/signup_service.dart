import 'package:firebase_auth/firebase_auth.dart';

import '../../ui/settings/session_service.dart';

class SignupServiceException implements Exception {
  SignupServiceException(this.code);
  final String code;

  @override
  String toString() => code;
}

class UsernameAvailability {
  const UsernameAvailability({required this.available, this.reason});

  final bool available;
  final String? reason;
}

class SignupService {
  SignupService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<UsernameAvailability> checkUsername(String username) async {
    return const UsernameAvailability(available: true);
  }

  Future<void> startSignup({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw SignupServiceException('missing-user');
      }
      await SessionService.instance.initSession(user.uid);
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw SignupServiceException(e.code);
    } on SignupServiceException {
      rethrow;
    } catch (_) {
      throw SignupServiceException('unknown');
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw SignupServiceException('missing-user');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw SignupServiceException(e.code);
    } on SignupServiceException {
      rethrow;
    } catch (_) {
      throw SignupServiceException('unknown');
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw SignupServiceException('missing-user');
      }
      await user.reload();
      final refreshed = _auth.currentUser;
      return refreshed?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      throw SignupServiceException(e.code);
    } on SignupServiceException {
      rethrow;
    } catch (_) {
      throw SignupServiceException('unknown');
    }
  }
}
