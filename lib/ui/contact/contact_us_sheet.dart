import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/l10n.dart';

const String _appVersion = '1.0.0+1';
const int _minMessageLength = 5;
const int _maxMessageLength = 2000;
const int _maxSubjectLength = 200;
const String _supportDeviceIdKey = 'support_device_id';

enum ContactCategory {
  issue,
  feature,
  improvement,
  report,
  other,
}

extension ContactCategoryLabel on ContactCategory {
  String label(BuildContext context) {
    final s = S.of(context);
    switch (this) {
      case ContactCategory.issue:
        return s.contactCategoryIssue;
      case ContactCategory.feature:
        return s.contactCategoryFeature;
      case ContactCategory.improvement:
        return s.contactCategoryImprovement;
      case ContactCategory.report:
        return s.contactCategoryReport;
      case ContactCategory.other:
        return s.contactCategoryOther;
    }
  }
}

class ContactUsSheet extends StatefulWidget {
  const ContactUsSheet({super.key});

  @override
  State<ContactUsSheet> createState() => _ContactUsSheetState();
}

class _ContactUsSheetState extends State<ContactUsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  ContactCategory _category = ContactCategory.issue;
  bool _includeUserInfo = true;
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final canIncludeUserInfo = user != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.contactUs,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                s.contactUsSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<ContactCategory>(
                      value: _category,
                      items: ContactCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _category = value);
                      },
                      decoration: InputDecoration(
                        labelText: s.contactCategoryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.contactSubjectLabel,
                        hintText: s.contactSubjectHint,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return s.contactValidationRequired;
                        }
                        if (text.length < _minMessageLength) {
                          return s.contactValidationMinLength(_minMessageLength);
                        }
                        if (text.length > _maxSubjectLength) {
                          return s.contactValidationMaxLength(_maxSubjectLength);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: s.contactDescriptionLabel,
                        hintText: s.contactDescriptionHint,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return s.contactValidationRequired;
                        }
                        if (text.length < _minMessageLength) {
                          return s.contactValidationMinLength(_minMessageLength);
                        }
                        if (text.length > _maxMessageLength) {
                          return s.contactValidationMaxLength(_maxMessageLength);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: Text(s.contactScreenshotPlaceholder),
                      subtitle: Text(s.contactScreenshotSoon),
                      enabled: false,
                      tileColor: Theme.of(context).colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: canIncludeUserInfo ? _includeUserInfo : false,
                      onChanged: canIncludeUserInfo
                          ? (value) {
                              if (value == null) return;
                              setState(() => _includeUserInfo = value);
                            }
                          : null,
                      title: Text(s.contactIncludeUserInfo),
                      subtitle: !canIncludeUserInfo
                          ? Text(s.contactUserInfoUnavailable)
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(s.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                _isSending ? null : () => _handleSend(context),
                            icon: _isSending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _isSending ? s.contactSending : s.contactSend,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend(BuildContext context) async {
    final s = S.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final subject = _subjectController.text.trim();
      final description = _descriptionController.text.trim();
      final user = FirebaseAuth.instance.currentUser;
      final includeAccountInfo = _includeUserInfo && user != null;
      final locale = Localizations.localeOf(context).toLanguageTag();
      final deviceId = await _getOrCreateDeviceId();

      await FirebaseFirestore.instance
          .collection('supportMessages')
          .add(<String, dynamic>{
        'uid': includeAccountInfo ? user?.uid : null,
        'email': includeAccountInfo ? user?.email : null,
        'phone': includeAccountInfo ? user?.phoneNumber : null,
        'displayName': includeAccountInfo ? user?.displayName : null,
        'includeAccountInfo': includeAccountInfo,
        'category': _category.name,
        'subject': subject,
        'message': description,
        'appVersion': _appVersion,
        'platform': Platform.operatingSystem,
        'locale': locale,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceInfo': <String, dynamic>{
          'deviceId': deviceId,
          'osVersion': Platform.operatingSystemVersion,
        },
        'status': 'queued',
      });

      if (!mounted) return;
      _subjectController.clear();
      _descriptionController.clear();
      setState(() {
        _category = ContactCategory.issue;
        _includeUserInfo = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.contactSendSuccess)),
      );
      Navigator.of(context).pop();
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.contactSendFailure)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.contactSendFailure)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_supportDeviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final newId = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_supportDeviceIdKey, newId);
    return newId;
  }
}
