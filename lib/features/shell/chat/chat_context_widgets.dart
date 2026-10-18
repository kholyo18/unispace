import 'dart:ui';
import 'package:flutter/material.dart';

String _text(BuildContext context, String ar, String fr, String en) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en
    };

class ChatEditingBanner extends StatelessWidget {
  const ChatEditingBanner(
      {super.key, required this.text, required this.onCancel});
  final String text;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 4),
        child: Row(children: [
          Icon(Icons.edit_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    _text(context, 'تعديل الرسالة', 'Modifier le message',
                        'Editing message'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700)),
                Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
          IconButton(
              onPressed: onCancel,
              tooltip: _text(context, 'إلغاء التعديل',
                  'Annuler la modification', 'Cancel editing'),
              icon: const Icon(Icons.close_rounded)),
        ]),
      );
}

class ChatRequestBadge extends StatelessWidget {
  const ChatRequestBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => count <= 0
      ? const SizedBox.shrink()
      : Badge(
          label: Text('$count'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
        );
}

/// Keeps text contrast stable over bright and dark personal photographs.
class ChatPhotoHeaderBackdrop extends StatelessWidget {
  const ChatPhotoHeaderBackdrop({super.key});
  @override
  Widget build(BuildContext context) => ClipRect(
          child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: .94)),
      ));
}
