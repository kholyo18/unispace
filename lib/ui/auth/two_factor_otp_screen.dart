import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../../services/two_factor_service.dart';
import '../settings/session_service.dart';

class TwoFactorOtpScreen extends StatefulWidget {
  const TwoFactorOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<TwoFactorOtpScreen> createState() => _TwoFactorOtpScreenState();
}

class _TwoFactorOtpScreenState extends State<TwoFactorOtpScreen> {
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _loading = false;
  int _remainingAttempts = 5;

  @override
  void initState() {
    super.initState();
    _sendOrRefreshCode();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendOrRefreshCode({bool resend = false}) async {
    setState(() => _loading = true);
    try {
      final result = resend
          ? await TwoFactorService.instance.resendChallenge()
          : await TwoFactorService.instance.startChallenge();
      if (!mounted) return;
      setState(() => _remainingAttempts = result.remainingAttempts);
      _startCooldown(result.cooldownSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).twoFactorCodeSent)),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapFunctionError(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).twoFactorGenericError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).twoFactorCodeInvalidFormat)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await TwoFactorService.instance.verifyCode(code);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await TwoFactorService.instance.markCurrentSessionVerified(user);
        await SessionService.instance.initSession(user.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).twoFactorVerifiedSuccess)),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      if (e.message == 'otp_invalid') {
        setState(() => _remainingAttempts = (_remainingAttempts - 1).clamp(0, 5));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapFunctionError(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).twoFactorGenericError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapFunctionError(FirebaseFunctionsException error) {
    final s = S.of(context);
    switch (error.message) {
      case 'challenge_not_found':
        return s.twoFactorChallengeMissing;
      case 'otp_expired':
        return s.twoFactorCodeExpired;
      case 'otp_invalid':
        return s.twoFactorCodeIncorrect;
      case 'otp_attempts_exceeded':
        return s.twoFactorTooManyAttempts;
      case 'cooldown_active':
        return s.twoFactorResendCooldown;
      case 'otp_send_failed':
        return s.twoFactorSendFailed;
      default:
        return s.twoFactorGenericError;
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds -= 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.twoFactorOtpTitle),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.twoFactorOtpDescription(widget.email)),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: s.twoFactorCodeLabel,
                hintText: s.twoFactorCodeHint,
              ),
            ),
            Text(
              s.twoFactorAttemptsRemaining(_remainingAttempts),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: Text(s.twoFactorConfirmButton),
            ),
            TextButton(
              onPressed: _loading || _cooldownSeconds > 0
                  ? null
                  : () => _sendOrRefreshCode(resend: true),
              child: Text(
                _cooldownSeconds > 0
                    ? s.twoFactorResendIn(_cooldownSeconds)
                    : s.twoFactorResendCode,
              ),
            ),
            TextButton(
              onPressed: _loading ? null : () => FirebaseAuth.instance.signOut(),
              child: Text(s.twoFactorBackToLogin),
            ),
          ],
        ),
      ),
    );
  }
}
