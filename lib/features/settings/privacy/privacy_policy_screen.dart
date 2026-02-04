import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5);
    final headingStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final sections = _buildPolicySections(
      s.privacyPolicyBody,
      bodyStyle: bodyStyle,
      headingStyle: headingStyle,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.privacyPolicy),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.privacyPolicyTitle,
                textAlign: TextAlign.start,
                style: titleStyle,
              ),
              const SizedBox(height: 16),
              ...sections,
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPolicySections(
    String body, {
    required TextStyle? bodyStyle,
    required TextStyle? headingStyle,
  }) {
    final widgets = <Widget>[];
    final lines = body.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      if (_isNumberedHeading(trimmed)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              trimmed,
              textAlign: TextAlign.start,
              style: headingStyle,
            ),
          ),
        );
        continue;
      }

      if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•', style: bodyStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    textAlign: TextAlign.start,
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            trimmed,
            textAlign: TextAlign.start,
            style: bodyStyle,
          ),
        ),
      );
    }
    return widgets;
  }

  bool _isNumberedHeading(String line) {
    return RegExp(r'^\d+\)').hasMatch(line);
  }
}
