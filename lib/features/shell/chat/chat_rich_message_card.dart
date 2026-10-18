import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Structured attachments, including legacy/malformed messages, fail visibly.
class ChatRichMessageCard extends StatefulWidget {
  const ChatRichMessageCard(
      {super.key,
      required this.data,
      required this.currentUid,
      required this.style,
      this.onVote,
      this.onRespondEvent});
  final Map<String, dynamic> data;
  final String currentUid;
  final TextStyle style;
  final Future<void> Function(int)? onVote;
  final Future<void> Function(bool)? onRespondEvent;
  @override
  State<ChatRichMessageCard> createState() => _ChatRichMessageCardState();
}

class _ChatRichMessageCardState extends State<ChatRichMessageCard> {
  static const _channel = MethodChannel('unispace/attachments');
  bool _busy = false;
  String? _error;
  String _s(String ar, String fr, String en) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'fr' => fr,
        _ => en
      };
  String _text(String key, [int limit = 2000]) {
    final value = widget.data[key];
    if (value is! String) return '';
    return value.length > limit ? value.substring(0, limit) : value;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
              'no-calendar-app' => _s(
                  'لا يوجد تطبيق تقويم متوافق مثبت. يمكنك متابعة الحدث داخل المحادثة.',
                  'Aucune application de calendrier compatible n’est installée. Vous pouvez suivre cet événement dans la discussion.',
                  'No compatible calendar app is installed. You can still follow this event in chat.'),
              'no-contacts-app' => _s(
                  'لا يوجد تطبيق جهات اتصال متوافق مثبت. يمكنك إضافة الرقم يدويًا.',
                  'Aucune application de contacts compatible n’est installée. Vous pouvez ajouter le numéro manuellement.',
                  'No compatible contacts app is installed. You can add the number manually.'),
              _ => _s(
                  'تعذّرت العملية. حاول مجددًا.',
                  'Échec de l’action. Réessayez.',
                  'Action failed. Please retry.'),
            });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = _s('تعذّرت العملية. حاول مجددًا.',
            'Échec de l’action. Réessayez.', 'Action failed. Please retry.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _invalid() => Text(_s('بيانات المرفق غير صالحة',
      'Pièce jointe invalide', 'Invalid attachment'));
  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_text('type', 30)) {
      case 'contact':
        body = _contact();
      case 'poll':
        body = _poll();
      case 'event':
        body = _event();
      default:
        body = _invalid();
    }
    final theme = Theme.of(context);
    final foreground = widget.style.color ?? theme.colorScheme.onSurface;
    final actionStyle = ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(foreground),
      iconColor: WidgetStatePropertyAll(foreground),
    );
    return Theme(
      data: theme.copyWith(
        iconTheme: theme.iconTheme.copyWith(color: foreground),
        textButtonTheme: TextButtonThemeData(style: actionStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: actionStyle.copyWith(
              side: WidgetStatePropertyAll(BorderSide(color: foreground))),
        ),
        progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(
          color: foreground,
          linearTrackColor: foreground.withValues(alpha: 0.2),
        ),
      ),
      child: IconTheme(
        data: theme.iconTheme.copyWith(color: foreground),
        child: DefaultTextStyle(
            style: widget.style,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      body,
                      if (_busy)
                        const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator()),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer)),
                        ),
                    ]))),
      ),
    );
  }

  Color get _foreground =>
      widget.style.color ?? Theme.of(context).colorScheme.onSurface;

  Widget _contact() {
    final name = _text('contactName', 150), phone = _text('contactPhone', 40);
    final valid = name.trim().isNotEmpty &&
        phone.length >= 3 &&
        RegExp(r'^[+0-9 ()\.\-]+$').hasMatch(phone) &&
        RegExp(r'[0-9]').hasMatch(phone);
    if (!valid) return _invalid();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _foreground.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_outline_rounded, size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_s('جهة اتصال', 'Contact', 'Contact'),
                    style: widget.style.copyWith(fontSize: 11)),
                const SizedBox(height: 3),
                Text(name,
                    style: widget.style
                        .copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                const SizedBox(height: 4),
                Text(phone,
                    textDirection: TextDirection.ltr,
                    style: widget.style.copyWith(fontSize: 13)),
              ],
            )),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child:
                Divider(height: 1, color: _foreground.withValues(alpha: .16)),
          ),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          if (!await launchUrl(
                              Uri(
                                  scheme: 'tel',
                                  path:
                                      phone.replaceAll(RegExp(r'[^+0-9]'), '')),
                              mode: LaunchMode.externalApplication)) {
                            throw StateError('unavailable');
                          }
                        }),
                icon: const Icon(Icons.call_outlined),
                label: Text(_s('اتصال', 'Appeler', 'Call'))),
            TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await _channel.invokeMethod<void>(
                              'saveContact', {'name': name, 'phone': phone});
                        }),
                icon: const Icon(Icons.person_add_alt),
                label:
                    Text(_s('حفظ جهة الاتصال', 'Enregistrer', 'Save contact'))),
          ]),
        ]);
  }

  Widget _poll() {
    List<String> options;
    try {
      final raw = jsonDecode(_text('optionsJson', 5000));
      if (raw is! List ||
          raw.length < 2 ||
          raw.length > 12 ||
          raw.any((e) => e is! String || e.trim().isEmpty || e.length > 200)) {
        return _invalid();
      }
      options = raw.cast<String>();
    } catch (_) {
      return _invalid();
    }
    final question = _text('question', 300);
    if (question.trim().isEmpty) return _invalid();
    final rawVotes = widget.data['votes'];
    final votes = rawVotes is Map ? rawVotes : const {};
    final counts = List<int>.filled(options.length, 0);
    int total = 0;
    for (final value in votes.values) {
      if (value is int && value >= 0 && value < options.length) {
        counts[value]++;
        total++;
      }
    }
    final selected = votes[widget.currentUid];
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(question,
              style: widget.style.copyWith(
                  fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 5),
          Row(children: [
            Icon(Icons.poll_outlined,
                size: 14, color: _foreground.withValues(alpha: .72)),
            const SizedBox(width: 5),
            Expanded(
                child: Text(
                    _s('اختر إجابة واحدة', 'Choisissez une réponse',
                        'Choose one answer'),
                    style: widget.style.copyWith(
                        fontSize: 12,
                        color: _foreground.withValues(alpha: .72)))),
          ]),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++)
            Semantics(
              selected: selected == i,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: OutlinedButton(
                      key: ValueKey('poll-choice-$i'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 9),
                        backgroundColor: _foreground.withValues(
                            alpha: selected == i ? .09 : 0),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _busy || widget.onVote == null
                          ? null
                          : () => _run(() => widget.onVote!(i)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                    selected == i
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: Text(options[i],
                                                style: widget.style.copyWith(
                                                    fontSize: 14,
                                                    height: 1.3,
                                                    fontWeight: selected == i
                                                        ? FontWeight.w600
                                                        : FontWeight.w400))),
                                        const SizedBox(width: 10),
                                        Text(
                                            '${total == 0 ? 0 : (counts[i] * 100 / total).round()}%',
                                            style: widget.style.copyWith(
                                                fontSize: 12,
                                                height: 1.5,
                                                fontWeight: FontWeight.w600))
                                      ]),
                                  const SizedBox(height: 7),
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                          value: total == 0
                                              ? 0
                                              : counts[i] / total,
                                          minHeight: 3)),
                                ])),
                          ]))),
            ),
          Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(_s('$total صوت', '$total vote(s)', '$total vote(s)'),
                  style: widget.style.copyWith(
                      fontSize: 11,
                      color: _foreground.withValues(alpha: .72)))),
        ]);
  }

  Widget _event() {
    final title = _text('title', 200),
        place = _text('place', 300),
        description = _text('description');
    final millis = widget.data['startsAtMs'];
    if (title.trim().isEmpty ||
        millis is! int ||
        millis <= 0 ||
        millis > 253402300799999) {
      return _invalid();
    }
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    final localizations = MaterialLocalizations.of(context);
    final attendees = widget.data['attendees'];
    final going = attendees is Map && attendees[widget.currentUid] == true;
    final count = attendees is Map
        ? attendees.values.where((value) => value == true).length
        : 0;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_outlined),
          Text(title,
              style: widget.style.copyWith(fontWeight: FontWeight.bold)),
          Text(
              '${localizations.formatMediumDate(time)} • ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time))}'),
          if (place.isNotEmpty) Text(place),
          if (description.isNotEmpty) Text(description),
          Text(_s('$count مشارك', '$count participant(s)', '$count attending')),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: _busy || widget.onRespondEvent == null
                    ? null
                    : () => _run(() => widget.onRespondEvent!(!going)),
                icon: Icon(
                    going ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(going
                    ? _s('إلغاء المشاركة', 'Ne plus participer',
                        'Cancel attendance')
                    : _s('سأشارك', 'Participer', 'Attend'))),
            TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await _channel.invokeMethod<void>('addEvent', {
                            'title': title,
                            'startsAtMs': millis,
                            'place': place,
                            'description': description
                          });
                        }),
                icon: const Icon(Icons.calendar_month),
                label: Text(_s('إضافة للتقويم', 'Ajouter au calendrier',
                    'Add to calendar'))),
          ]),
        ]);
  }
}
