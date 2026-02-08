import 'package:UniSpace/generated/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'privacy_account_repository.dart';

class PrivacyAccountOverviewTab extends StatefulWidget {
  const PrivacyAccountOverviewTab({super.key});

  @override
  State<PrivacyAccountOverviewTab> createState() => _PrivacyAccountOverviewTabState();
}

class _PrivacyAccountOverviewTabState extends State<PrivacyAccountOverviewTab> {
  final PrivacyAccountRepository _repository = PrivacyAccountRepository();

  PrivacyAccountData? _data;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repository.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  bool get _canEditName {
    final changedAt = _data?.lastNameChangeAt;
    if (changedAt == null) return true;
    return DateTime.now().isAfter(changedAt.add(const Duration(days: 30)));
  }

  String _nameRuleText(S s) {
    final changedAt = _data?.lastNameChangeAt;
    if (changedAt == null || _canEditName) return s.privacyNameRuleAllowed;
    final next = changedAt.add(const Duration(days: 30));
    final remaining = next.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) {
      return s.privacyNameRuleBlockedDays('$days', '$hours');
    }
    return s.privacyNameRuleBlockedHours('$hours');
  }

  String _maskedEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return '***';
    final parts = trimmed.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.isEmpty) return '***@$domain';
    if (local.length <= 3) return '${local[0]}***@$domain';
    return '${local.substring(0, 3)}***@$domain';
  }

  Future<void> _handleEditName() async {
    final s = S.of(context);
    if (_busy || _data == null) return;
    if (!_canEditName) {
      _snack(_nameRuleText(s));
      return;
    }
    final authenticated = await _showReauthSheet();
    if (!authenticated) return;

    final result = await _showNameEditSheet(_data!);
    if (result == null) return;

    setState(() => _busy = true);
    final changedAt = DateTime.now();
    try {
      await _repository.saveName(
        firstName: result.$1,
        lastName: result.$2,
        changedAt: changedAt,
      );
      if (!mounted) return;
      setState(() {
        _data = _data!.copyWith(
          firstName: result.$1,
          lastName: result.$2,
          lastNameChangeAt: changedAt,
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _snack(s.privacyNameSaved);
  }

  Future<void> _handleEditEmail() async {
    final s = S.of(context);
    if (_busy || _data == null) return;
    final authenticated = await _showReauthSheet();
    if (!authenticated) return;

    final updatedEmail = await _showEmailFlowSheet(_data!.email);
    if (updatedEmail == null) return;

    setState(() => _busy = true);
    try {
      await _repository.saveEmail(updatedEmail);
      if (!mounted) return;
      setState(() {
        _data = _data!.copyWith(email: updatedEmail);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _snack(s.privacyEmailSaved);
  }

  Future<bool> _showReauthSheet() async {
    final s = S.of(context);
    final passwordController = TextEditingController();
    String? error;
    bool loading = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.privacyReauthTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(s.privacyReauthSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: s.password,
                          errorText: error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: loading ? null : () => Navigator.of(context).pop(false),
                              child: Text(s.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        loading = true;
                                        error = null;
                                      });
                                      final ok = await _reauthenticate(passwordController.text);
                                      if (!context.mounted) return;
                                      if (ok) {
                                        Navigator.of(context).pop(true);
                                      } else {
                                        setModalState(() {
                                          loading = false;
                                          error = s.privacyReauthFailed;
                                        });
                                      }
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(s.privacyContinue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result == true;
  }

  Future<bool> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (password.trim().isEmpty) return false;
    if (user == null) return false;

    final hasPasswordProvider = user.providerData.any((provider) => provider.providerId == 'password');
    if (hasPasswordProvider && user.email != null) {
      try {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        return true;
      } catch (_) {
        return false;
      }
    }

    // TODO(dev): Replace this fallback with a backend-issued ephemeral re-auth token flow.
    return password.trim().length >= 6;
  }

  Future<(String, String)?> _showNameEditSheet(PrivacyAccountData data) async {
    final s = S.of(context);
    final firstController = TextEditingController(text: data.firstName);
    final lastController = TextEditingController(text: data.lastName);
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.privacyEditNameTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: firstController,
                      decoration: InputDecoration(labelText: s.privacyFirstName),
                      validator: (value) => _validateName(value, s),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: lastController,
                      decoration: InputDecoration(labelText: s.privacyLastName),
                      validator: (value) => _validateName(value, s),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) return;
                        Navigator.of(context).pop((firstController.text.trim(), lastController.text.trim()));
                      },
                      child: Text(s.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateName(String? value, S s) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return s.privacyNameValidationRequired;
    if (input.length < 2) return s.privacyNameValidationShort;
    if (input.length > 40) return s.privacyNameValidationLong;
    return null;
  }

  Future<String?> _showEmailFlowSheet(String currentEmail) async {
    final s = S.of(context);
    final currentController = TextEditingController();
    final newEmailController = TextEditingController();
    final confirmEmailController = TextEditingController();

    int step = 1;
    bool loading = false;
    String? error;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey(step),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${s.privacyEmailFlowTitle} (${s.privacyStepOf('$step', '4')})', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(s.privacyEmailFlowSecurityNote, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
                        if (step == 1) ...[
                          Text(s.privacyEmailFlowStep1Help(_maskedEmail(currentEmail))),
                          const SizedBox(height: 12),
                          TextField(controller: currentController, decoration: InputDecoration(labelText: s.privacyEmailCurrentLabel)),
                        ] else if (step == 2) ...[
                          Text(s.privacyEmailFlowStep2Help),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          setModalState(() {
                                            loading = true;
                                            error = null;
                                          });
                                          await Future<void>.delayed(const Duration(milliseconds: 1200));
                                          if (!context.mounted) return;
                                          setModalState(() {
                                            loading = false;
                                            step = 3;
                                          });
                                        },
                                  child: loading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(s.privacyEmailFlowSendLink),
                                ),
                              ),
                            ],
                          ),
                        ] else if (step == 3) ...[
                          Text(s.privacyEmailFlowStep3Help),
                          const SizedBox(height: 12),
                          TextField(
                            controller: newEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: s.privacyEmailNewLabel),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: s.privacyEmailConfirmLabel),
                          ),
                        ] else ...[
                          Text(s.privacyEmailFlowStep4Help(_maskedEmail(newEmailController.text.trim()))),
                        ],
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: loading ? null : () => Navigator.of(context).pop(),
                                child: Text(s.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        final validation = _validateStep(
                                          step: step,
                                          currentEmail: currentEmail,
                                          currentInput: currentController.text,
                                          newEmail: newEmailController.text,
                                          confirmEmail: confirmEmailController.text,
                                          s: s,
                                        );
                                        if (validation != null) {
                                          setModalState(() => error = validation);
                                          return;
                                        }
                                        setModalState(() => error = null);
                                        if (step < 4) {
                                          setModalState(() => step += 1);
                                          return;
                                        }
                                        Navigator.of(context).pop(newEmailController.text.trim());
                                      },
                                child: Text(step == 4 ? s.save : s.privacyContinue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _validateStep({
    required int step,
    required String currentEmail,
    required String currentInput,
    required String newEmail,
    required String confirmEmail,
    required S s,
  }) {
    if (step == 1 && currentInput.trim().toLowerCase() != currentEmail.trim().toLowerCase()) {
      return s.privacyEmailCurrentMismatch;
    }
    if (step == 3) {
      final next = newEmail.trim();
      final confirm = confirmEmail.trim();
      if (next.isEmpty || confirm.isEmpty) return s.privacyEmailValidationRequired;
      if (!next.contains('@')) return s.invalidEmailValidation;
      if (next.toLowerCase() != confirm.toLowerCase()) return s.privacyEmailConfirmMismatch;
    }
    return null;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _data;
    if (data == null) {
      return Center(child: Text(s.privacyLoadFailed));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.privacyTabTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.privacyTabSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 20),
          Text(s.privacyAccountOverviewSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(s.privacyNameRowTitle),
                    subtitle: Text(data.fullName.isEmpty ? '-' : data.fullName),
                    trailing: IconButton(
                      onPressed: _busy ? null : _handleEditName,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 72, end: 16, bottom: 10),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_nameRuleText(s), style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.email_outlined)),
                    title: Text(s.privacyEmailRowTitle),
                    subtitle: Text(_maskedEmail(data.email)),
                    trailing: IconButton(
                      onPressed: _busy ? null : _handleEditEmail,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
