import 'package:flutter/material.dart';
import '../../../services/chat_translation.dart';
import 'chat_text_content.dart';

class ChatTranslatedText extends StatefulWidget {
  const ChatTranslatedText(
      {super.key,
      required this.text,
      required this.style,
      required this.enabled,
      required this.target,
      required this.service});
  final String text, target;
  final TextStyle style;
  final bool enabled;
  final ChatTranslationService service;
  @override
  State<ChatTranslatedText> createState() => _ChatTranslatedTextState();
}

class _ChatTranslatedTextState extends State<ChatTranslatedText> {
  int _generation = 0;
  ChatTranslation? _result;
  bool _original = false, _failed = false;
  String t(String ar, String en, String fr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ChatTranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.target != widget.target ||
        old.enabled != widget.enabled ||
        old.service != widget.service) _load();
  }

  void _load() {
    final generation = ++_generation;
    _result = null;
    _original = false;
    _failed = false;
    if (!widget.enabled || widget.text.trim().isEmpty) return;
    widget.service
        .translate(
      widget.text,
      widget.target,
      isCurrent: () => mounted && generation == _generation && widget.enabled,
    )
        .then((result) {
      if (mounted && generation == _generation)
        setState(() => _result = result);
    }, onError: (Object _) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final changed = _result?.canReplace(widget.text, widget.target) ?? false;
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatTextContent(
              text: changed && !_original ? _result!.text : widget.text,
              style: widget.style),
          if (widget.enabled && (changed || _failed))
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: widget.style.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
              onPressed: _failed
                  ? () => setState(_load)
                  : () => setState(() => _original = !_original),
              child: Text(
                  _failed
                      ? t(
                          'تعذرت الترجمة · إعادة المحاولة',
                          'Translation failed · Retry',
                          'Traduction échouée · Réessayer')
                      : _original
                          ? t('عرض الترجمة', 'Show translation',
                              'Voir la traduction')
                          : t(
                              'مترجمة · عرض الأصل',
                              'Translated · Show original',
                              'Traduit · Voir l’original'),
                  style: const TextStyle(fontSize: 11)),
            ),
        ]);
  }
}
