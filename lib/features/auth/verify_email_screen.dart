import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = false;
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownRemaining = 0);
      } else {
        if (mounted) setState(() => _cooldownRemaining--);
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<User?> _signInForVerification() async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: widget.email,
      password: widget.password,
    );
    return credential.user;
  }

  Future<void> _checkNow() async {
    setState(() => _loading = true);
    try {
      final user = await _signInForVerification();
      if (user == null) {
        _showSnack(S.of(context).genericAuthError);
        return;
      }
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed?.emailVerified == true) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      await FirebaseAuth.instance.signOut();
      _showSnack(S.of(context).verifyEmailToContinue);
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Verify email check failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showSnack(S.of(context).genericAuthError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _loading = true);
    try {
      final user = await _signInForVerification();
      if (user == null) {
        _showSnack(S.of(context).genericAuthError);
        return;
      }
      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _startCooldown(60);
      _showSnack(S.of(context).verificationEmailSent);
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Resend verification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showSnack(S.of(context).genericAuthError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    final localizations = S.of(context);
    switch (error.code) {
      case 'invalid-email':
        return localizations.invalidEmailError;
      case 'user-disabled':
        return localizations.userDisabledError;
      case 'user-not-found':
        return localizations.userNotFoundError;
      case 'wrong-password':
        return localizations.wrongPasswordError;
      case 'email-already-in-use':
        return localizations.emailAlreadyInUseError;
      case 'weak-password':
        return localizations.weakPasswordError;
      case 'operation-not-allowed':
        return localizations.emailAuthDisabledError;
      case 'network-request-failed':
        return localizations.networkError;
      case 'too-many-requests':
        return localizations.tooManyRequestsError;
      default:
        return error.message ?? localizations.genericAuthError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = S.of(context);
    return Scaffold(
      backgroundColor: Colors.blueGrey[700],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(localizations.verifyEmailTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.verifyEmailTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.verifyEmailToContinue,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.verifyEmailHelper,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _checkNow,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(localizations.checkNow),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _loading || _cooldownRemaining > 0
                              ? null
                              : _resendVerification,
                          child: Text(
                            _cooldownRemaining > 0
                                ? localizations.resendVerificationCooldown(
                                    _cooldownRemaining,
                                  )
                                : localizations.resendVerificationEmail,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
