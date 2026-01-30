import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n.dart';

const String _supportEmail = 'khaledfoll12@gmail.com';
const String _appVersion = '1.0.0+1';
const int _minMessageLength = 5;

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
                            onPressed: () => _handleSend(context),
                            icon: const Icon(Icons.send_rounded),
                            label: Text(s.contactSend),
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

    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    final categoryLabel = _category.label(context);
    final emailSubject = '[UniSpace] $categoryLabel - $subject';
    final emailBody = _buildEmailBody(
      context: context,
      description: description,
      includeUserInfo: _includeUserInfo,
    );

    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': emailSubject,
        'body': emailBody,
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.contactMailOpened)),
        );
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.contactMailUnavailable)),
      );
      await _showCopyDialog(context, emailSubject, emailBody);
    }
  }

  String _buildEmailBody({
    required BuildContext context,
    required String description,
    required bool includeUserInfo,
  }) {
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final buffer = StringBuffer()
      ..writeln(description)
      ..writeln('')
      ..writeln('---')
      ..writeln(s.contactMetadataHeader)
      ..writeln('${s.contactMetadataAppVersion}: $_appVersion')
      ..writeln('${s.contactMetadataPlatform}: ${Platform.operatingSystem}')
      ..writeln('${s.contactMetadataLocale}: $locale')
      ..writeln('${s.contactMetadataTimestamp}: $timestamp');

    if (includeUserInfo) {
      if (user != null) {
        buffer
          ..writeln('${s.contactMetadataUserId}: ${user.uid}')
          ..writeln('${s.contactMetadataEmail}: ${user.email ?? '-'}')
          ..writeln('${s.contactMetadataName}: ${user.displayName ?? '-'}');
      } else {
        buffer.writeln(s.contactUserInfoUnavailable);
      }
    }

    return buffer.toString();
  }

  Future<void> _showCopyDialog(
    BuildContext context,
    String subject,
    String body,
  ) async {
    final s = S.of(context);
    final message = '$subject\n\n$body';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.contactCopyDialogTitle),
        content: Text(s.contactCopyDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.contactCopied)),
              );
            },
            child: Text(s.contactCopyAction),
          ),
        ],
      ),
    );
  }
}
