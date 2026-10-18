import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import '../../../services/chat_message_readers.dart';

/// Displays only facts provided by the message; receipt timestamps are not
/// inferred from conversation-level delivery/read markers.
class ChatMessageInfoSheet extends StatelessWidget {
  const ChatMessageInfoSheet({
    super.key,
    required this.message,
    required this.senderName,
    required this.isMine,
    this.readers,
  });

  final types.Message message;
  final String senderName;
  final bool isMine;

  /// Null hides this section; an empty list means no shared receipt is known.
  final List<ChatMessageReader>? readers;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    String text(String ar, String fr, String en) => language == 'ar'
        ? ar
        : language == 'fr'
            ? fr
            : en;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final created = message.createdAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(message.createdAt!).toLocal();
    final String status;
    final IconData statusIcon;
    final bool failed =
        message.metadata?['failed'] == true || message.status?.name == 'error';
    if (failed) {
      status = text('تعذّر الإرسال', 'Échec de l’envoi', 'Failed to send');
      statusIcon = Icons.error_outline_rounded;
    } else if (message.metadata?['pending'] == true ||
        message.status?.name == 'sending') {
      status = text('جارٍ الإرسال', 'Envoi en cours', 'Sending');
      statusIcon = Icons.schedule_rounded;
    } else {
      switch (message.status?.name) {
        case 'seen':
          status = text('تمت القراءة', 'Lu', 'Read');
          statusIcon = Icons.done_all_rounded;
        case 'delivered':
          status = text('تم التسليم', 'Distribué', 'Delivered');
          statusIcon = Icons.done_all_rounded;
        case 'sent':
          status = text('تم الإرسال', 'Envoyé', 'Sent');
          statusIcon = Icons.check_rounded;
        default:
          status = text('غير متاحة', 'Indisponible', 'Unavailable');
          statusIcon = Icons.info_outline_rounded;
      }
    }
    final num? size = switch (message) {
      types.FileMessage value => value.size,
      types.ImageMessage value => value.size,
      types.VideoMessage value => value.size,
      types.AudioMessage value => value.size,
      _ => null,
    };
    String fileSize(num bytes) {
      final units = language == 'ar'
          ? ['بايت', 'ك.بايت', 'م.بايت', 'ج.بايت']
          : language == 'fr'
              ? ['o', 'Ko', 'Mo', 'Go']
              : ['B', 'KB', 'MB', 'GB'];
      var value = bytes.toDouble();
      var unit = 0;
      while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
      }
      final formatter = NumberFormat(unit == 0 ? '0' : '0.#', language);
      return '${formatter.format(value)} ${units[unit]}';
    }

    Widget row(IconData icon, String label, String value, {Color? accent}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (accent ?? colors.primary).withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: accent ?? colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600)),
                ])),
          ]),
        );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    text('معلومات الرسالة', 'Infos du message', 'Message info'),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                row(
                    Icons.person_outline_rounded,
                    text('المرسل', 'Expéditeur', 'Sender'),
                    senderName.trim().isEmpty
                        ? text('غير معروف', 'Inconnu', 'Unknown')
                        : senderName.trim()),
                const Divider(height: 1),
                row(
                    Icons.access_time_rounded,
                    text('وقت الإنشاء', 'Date de création', 'Created'),
                    created == null
                        ? '—'
                        : '${localizations.formatFullDate(created)}\n${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(created), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}'),
                if (isMine) ...[
                  const Divider(height: 1),
                  row(
                      statusIcon,
                      text('حالة الرسالة', 'État du message', 'Message status'),
                      status,
                      accent: failed ? colors.error : colors.primary),
                ],
                if (isMine && readers != null) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(text('قرأها', 'Lu par', 'Read by'),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (readers!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                          text(
                              'لا توجد تأكيدات قراءة مشتركة حتى الآن',
                              'Aucune confirmation de lecture partagée pour le moment',
                              'No shared read receipts yet'),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant)),
                    ),
                  for (final reader in readers!)
                    row(
                        Icons.done_all_rounded,
                        text('تمت القراءة', 'Lu', 'Read'),
                        reader.name.isEmpty
                            ? text('مستخدم', 'Utilisateur', 'User')
                            : reader.name),
                ],
                if (message.metadata?['edited'] == true) ...[
                  const Divider(height: 1),
                  row(
                      Icons.edit_outlined,
                      text('التعديل', 'Modification', 'Editing'),
                      text('تم تعديل الرسالة', 'Message modifié',
                          'Message edited')),
                ],
                if (size != null && size >= 0) ...[
                  const Divider(height: 1),
                  row(
                      Icons.insert_drive_file_outlined,
                      text('حجم الملف', 'Taille du fichier', 'File size'),
                      fileSize(size)),
                ],
              ]),
        ),
      ),
    );
  }
}
