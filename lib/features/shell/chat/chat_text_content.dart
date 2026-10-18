import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/chat_location_point.dart';

typedef ChatLinkLauncher = Future<bool> Function(Uri uri);

/// Displays message text without altering its content, with HTTP(S) links.
class ChatTextContent extends StatefulWidget {
  const ChatTextContent({
    super.key,
    required this.text,
    required this.style,
    this.onLaunchLink,
    this.onLinkFailure,
  });

  final String text;
  final TextStyle style;
  final ChatLinkLauncher? onLaunchLink;
  final VoidCallback? onLinkFailure;

  @override
  State<ChatTextContent> createState() => _ChatTextContentState();
}

class _ChatTextContentState extends State<ChatTextContent> {
  // The allowlist is intentionally limited to browser links. Other schemes
  // (including javascript:, intent:, tel:, and file:) remain plain text.
  static final _linkPattern =
      RegExp(r'''https?://[^\s<>"']+''', caseSensitive: false);
  final _recognizers = <TapGestureRecognizer>[];
  List<InlineSpan> _spans = const [];

  @override
  void initState() {
    super.initState();
    _buildSpans();
  }

  @override
  void didUpdateWidget(covariant ChatTextContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _buildSpans();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _buildSpans() {
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _linkPattern.allMatches(widget.text)) {
      var link = match.group(0)!;
      // Punctuation commonly follows a URL in a sentence. Keep it visible,
      // outside the link; balanced URL parentheses remain part of the link.
      while (link.isNotEmpty) {
        final last = link[link.length - 1];
        final sentenceEnd = '.,;:!?،؛。'.contains(last);
        final unmatchedClose = (last == ')' &&
                ')'.allMatches(link).length > '('.allMatches(link).length) ||
            (last == ']' &&
                ']'.allMatches(link).length > '['.allMatches(link).length) ||
            (last == '}' &&
                '}'.allMatches(link).length > '{'.allMatches(link).length);
        if (!sentenceEnd && !unmatchedClose) break;
        link = link.substring(0, link.length - 1);
      }
      final uri = Uri.tryParse(link);
      if (uri == null ||
          !const ['http', 'https'].contains(uri.scheme.toLowerCase()) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        continue;
      }
      if (match.start > offset) {
        spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _open(uri);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: link,
        style: const TextStyle(decoration: TextDecoration.underline),
        recognizer: recognizer,
      ));
      offset = match.start + link.length;
    }
    if (offset < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(offset)));
    }
    _spans = spans;
  }

  Future<void> _open(Uri uri) async {
    var opened = false;
    try {
      opened = await (widget.onLaunchLink?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      // A missing external application must not break the chat widget.
    }
    if (!opened && mounted) widget.onLinkFailure?.call();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = ChatLocationPoint.fromMapsLink(widget.text);
    if (point != null) {
      final language = Localizations.localeOf(context).languageCode;
      final title = language == 'ar'
          ? 'موقع مشارك'
          : language == 'fr'
              ? 'Position partagée'
              : 'Shared location';
      final action = language == 'ar'
          ? 'فتح في الخرائط'
          : language == 'fr'
              ? 'Ouvrir la carte'
              : 'Open in Maps';
      return Semantics(
        button: true,
        label: '$title, ${point.coordinates}, $action',
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('openSharedLocation'),
              onTap: () => _open(Uri.parse(widget.text.trim())),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // A location symbol, not a fabricated map preview.
                            ExcludeSemantics(
                                child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                        color: (widget.style.color ??
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onSurface)
                                            .withValues(alpha: .09),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(Icons.location_on_outlined,
                                        size: 26,
                                        color: widget.style.color ??
                                            Theme.of(context)
                                                .colorScheme
                                                .onSurface))),
                            const SizedBox(width: 11),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Text(title,
                                      style: widget.style.copyWith(
                                          fontSize: 15,
                                          height: 1.25,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 5),
                                  Text(point.coordinates,
                                      textDirection: TextDirection.ltr,
                                      style: widget.style.copyWith(
                                          fontSize: 11,
                                          height: 1.3,
                                          color: (widget.style.color ??
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurface)
                                              .withValues(alpha: .72))),
                                ])),
                          ]),
                      Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 10),
                          child: Divider(
                              height: 1,
                              color: (widget.style.color ??
                                      Theme.of(context).colorScheme.onSurface)
                                  .withValues(alpha: .12))),
                      Row(children: [
                        Expanded(
                            child: Text(action,
                                style: widget.style.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600))),
                        const SizedBox(width: 8),
                        Icon(Icons.open_in_new_rounded,
                            size: 16,
                            color: widget.style.color ??
                                Theme.of(context).colorScheme.onSurface),
                      ]),
                    ],
                  )),
            )),
      );
    }
    final fallbacks = <String>{
      ...?widget.style.fontFamilyFallback,
      'NotoColorEmoji',
    }.toList();
    return Text.rich(
      TextSpan(children: _spans),
      style: widget.style.copyWith(fontFamilyFallback: fallbacks),
    );
  }
}
