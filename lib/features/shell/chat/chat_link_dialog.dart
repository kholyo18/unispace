import 'package:flutter/material.dart';
import '../../../services/chat_attachment_input.dart';

Future<String?> showChatLinkDialog(BuildContext context) => showDialog<String>(
    context: context, builder: (_) => const ChatLinkDialog());

class ChatLinkDialog extends StatefulWidget {
  const ChatLinkDialog({super.key});
  @override
  State<ChatLinkDialog> createState() => _ChatLinkDialogState();
}

class _ChatLinkDialogState extends State<ChatLinkDialog> {
  final _controller = TextEditingController();
  bool _invalid = false, _confirmed = false;
  String t(String ar, String en, String fr) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_confirmed) return;
    final link = normalizeChatLink(_controller.text);
    if (link == null) {
      setState(() => _invalid = true);
      return;
    }
    _confirmed = true;
    Navigator.pop(context, link);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(t('إرسال رابط', 'Send link', 'Envoyer un lien')),
        content: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
                hintText: 'https://...',
                errorText: _invalid
                    ? t(
                        'أدخل رابط HTTP أو HTTPS صالحًا.',
                        'Enter a valid HTTP or HTTPS link.',
                        'Saisissez un lien HTTP ou HTTPS valide.')
                    : null)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('إلغاء', 'Cancel', 'Annuler'))),
          FilledButton(
              key: const ValueKey('sendLink'),
              onPressed: _send,
              child: Text(t('إرسال', 'Send', 'Envoyer'))),
        ],
      );
}
