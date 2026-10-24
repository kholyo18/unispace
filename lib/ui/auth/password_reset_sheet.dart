import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../services/password_reset_service.dart';

Future<void> showPasswordResetSheet(
  BuildContext context, {
  required String initialEmail,
  bool lockEmail = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final sentMessage = S.of(context).resetLinkSentSuccess;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        PasswordResetSheet(initialEmail: initialEmail, lockEmail: lockEmail),
  );
  if (sent == true && context.mounted) {
    messenger.showSnackBar(SnackBar(content: Text(sentMessage)));
  }
}

class PasswordResetSheet extends StatefulWidget {
  const PasswordResetSheet(
      {super.key,
      required this.initialEmail,
      this.lockEmail = false,
      this.service});
  final String initialEmail;
  final bool lockEmail;
  final PasswordResetService? service;
  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _sending = false;
  String? _errorCode;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    if (!PasswordResetService.validEmail(_email.text)) {
      setState(() => _errorCode = 'invalid-email');
      return;
    }
    setState(() {
      _sending = true;
      _errorCode = null;
    });
    try {
      await (widget.service ?? PasswordResetService())
          .send(_email.text, Localizations.localeOf(context).languageCode);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _errorCode = error.code);
    } catch (_) {
      if (mounted) setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final error = switch (_errorCode) {
      null => null,
      'invalid-email' => s.invalidEmailValidation,
      'too-many-requests' => s.tooManyRequestsError,
      _ => s.resetLinkFailed,
    };
    return PopScope(
        canPop: !_sending,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lock_reset, color: colors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(s.resetPasswordTitle,
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                        onPressed:
                            _sending ? null : () => Navigator.pop(context),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 12),
                  Text(s.resetPasswordHelper,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  TextField(
                      key: const ValueKey('reset-email'),
                      controller: _email,
                      enabled: !_sending,
                      readOnly: widget.lockEmail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.email_outlined))),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                            liveRegion: true,
                            child: Text(error,
                                key: const ValueKey('reset-error'),
                                style: TextStyle(color: colors.error)))),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          key: const ValueKey('reset-send'),
                          onPressed: _sending ? null : _send,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(_sending
                                  ? s.sendResetLinkLoading
                                  : s.sendResetLink)))),
                  Center(
                      child: TextButton(
                          onPressed:
                              _sending ? null : () => Navigator.pop(context),
                          child: Text(s.cancel))),
                ]),
          ),
        ));
  }
}
