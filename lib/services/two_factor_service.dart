import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorChallengeResult {
  const TwoFactorChallengeResult({
    required this.cooldownSeconds,
    required this.expiresInSeconds,
    required this.remainingAttempts,
    required this.lockedForSeconds,
  });

  final int cooldownSeconds;
  final int expiresInSeconds;
  final int remainingAttempts;
  final int lockedForSeconds;
}

class TwoFactorService {
  TwoFactorService._();

  static final TwoFactorService instance = TwoFactorService._();
  static const _verifiedPrefix = 'two_factor_verified_session_';

  final ValueNotifier<int> authRefresh = ValueNotifier<int>(0);

  Future<bool> isCurrentSessionVerified(User user) async {
    final signInTime = user.metadata.lastSignInTime;
    if (signInTime == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_verifiedPrefix${user.uid}_${signInTime.toIso8601String()}') ?? false;
  }

  Future<void> markCurrentSessionVerified(User user) async {
    final signInTime = user.metadata.lastSignInTime;
    if (signInTime == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_verifiedPrefix${user.uid}_${signInTime.toIso8601String()}', true);
    authRefresh.value = authRefresh.value + 1;
  }

  Future<TwoFactorChallengeResult> startChallenge() async {
    return _callChallengeFunction('startLoginTwoFactor');
  }

  Future<TwoFactorChallengeResult> resendChallenge() async {
    return _callChallengeFunction('resendLoginTwoFactor');
  }

  Future<void> verifyCode(String code) async {
    final callable = FirebaseFunctions.instance.httpsCallable('verifyLoginTwoFactor');
    await callable.call(<String, dynamic>{
      'code': code,
    });
  }

  Future<TwoFactorChallengeResult> _callChallengeFunction(String functionName) async {
    final callable = FirebaseFunctions.instance.httpsCallable(functionName);
    final result = await callable.call();
    final data = result.data as Map<Object?, Object?>?;
    return TwoFactorChallengeResult(
      cooldownSeconds: max(0, (data?['cooldownSeconds'] as num?)?.toInt() ?? 30),
      expiresInSeconds: max(0, (data?['expiresInSeconds'] as num?)?.toInt() ?? 300),
      remainingAttempts: max(0, (data?['remainingAttempts'] as num?)?.toInt() ?? 5),
      lockedForSeconds: max(0, (data?['lockedForSeconds'] as num?)?.toInt() ?? 0),
    );
  }
}
