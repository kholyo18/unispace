import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

/// Displays the localized privacy policy; it does not record legal consent.
/// Keep the actual policy text in the ARB files, not in this widget.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();

  // Recognize 1), ١), ۱), and 1. / ١. / ۱. followed by heading text.
  // A period must be followed by whitespace, so "1.0" is not a heading.
  static final RegExp _numberedHeading = RegExp(
    r'^[0-9٠-٩۰-۹]+(?:\)\s*\S|\.\s+\S)',
  );
  static final RegExp _bullet = RegExp(r'^[-*•]\s+(.+)$');
  static final RegExp _lineBreak = RegExp(r'\r\n|\r|\n');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
        .copyWith(height: 1.6);
    final headingStyle =
        (textTheme.titleSmall ?? const TextStyle(fontSize: 16)).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.5,
    );
    final titleStyle =
        (textTheme.headlineSmall ?? const TextStyle(fontSize: 24)).copyWith(
      fontWeight: FontWeight.w700,
      height: 1.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.privacyPolicy),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SelectionArea(
          child: ScrollConfiguration(
            // Avoid a second automatic scrollbar on desktop/web.
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('privacy-policy-scroll'),
                controller: _scrollController,
                primary: false,
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            s.privacyPolicyTitle,
                            textAlign: TextAlign.start,
                            style: titleStyle,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._buildPolicySections(
                          s.privacyPolicyBody,
                          bodyStyle: bodyStyle,
                          headingStyle: headingStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPolicySections(
    String body, {
    required TextStyle bodyStyle,
    required TextStyle headingStyle,
  }) {
    final widgets = <Widget>[];
    var pendingGap = false;

    for (final rawLine in body.split(_lineBreak)) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        // Collapse consecutive blank lines without removing any policy text.
        pendingGap = widgets.isNotEmpty;
        continue;
      }

      if (pendingGap) {
        widgets.add(const SizedBox(height: 12));
        pendingGap = false;
      }

      if (_numberedHeading.hasMatch(line)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                line,
                textAlign: TextAlign.start,
                style: headingStyle,
              ),
            ),
          ),
        );
        continue;
      }

      final bulletMatch = _bullet.firstMatch(line);
      if (bulletMatch != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The marker is decorative; select/read the item text once.
                ExcludeSemantics(
                  child: SelectionContainer.disabled(
                    child: Text('•', style: bodyStyle),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bulletMatch.group(1)!,
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
            line,
            textAlign: TextAlign.start,
            style: bodyStyle,
          ),
        ),
      );
    }

    return widgets;
  }
}
