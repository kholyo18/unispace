import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>?> showChatRichAttachmentSheet(BuildContext context,
    {required String kind}) {
  if (!const ['contact', 'poll', 'event'].contains(kind)) {
    throw ArgumentError.value(kind, 'kind');
  }
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChatRichAttachmentSheet(kind: kind),
  );
}

String normalizeChatContactPhone(String input) {
  var value = input.trim();
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value.replaceAll(RegExp(r'[\s()\-]'), '');
}

class ChatRichAttachmentSheet extends StatefulWidget {
  const ChatRichAttachmentSheet({super.key, required this.kind});
  final String kind;
  @override
  State<ChatRichAttachmentSheet> createState() =>
      _ChatRichAttachmentSheetState();
}

class _ChatRichAttachmentSheetState extends State<ChatRichAttachmentSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _phone = TextEditingController();
  final _place = TextEditingController();
  final _description = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  DateTime? _startsAt;
  Map<String, dynamic>? _preview;
  String? _error;
  bool _picking = false, _finished = false;

  String t(String ar, String en, String fr) {
    return switch (Localizations.localeOf(context).languageCode) {
      'ar' => ar,
      'fr' => fr,
      _ => en,
    };
  }

  @override
  void dispose() {
    for (final c in [_title, _phone, _place, _description, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final value = await const MethodChannel('unispace/attachments')
          .invokeMapMethod<String, dynamic>('pickContact');
      if (!mounted || value == null) return;
      _title.text = '${value['name'] ?? ''}';
      _phone.text = normalizeChatContactPhone('${value['phone'] ?? ''}');
    } catch (_) {
      if (mounted) {
        setState(() => _error = t(
            'تعذر فتح جهات الاتصال. يمكنك إدخال الاسم والرقم يدويًا.',
            'Contacts unavailable. Enter the name and number manually.',
            'Contacts indisponibles. Saisissez le nom et le numéro manuellement.'));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickDate() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final now = DateTime.now();
      final date = await showDatePicker(
          context: context,
          initialDate:
              _startsAt != null && _startsAt!.isAfter(now) ? _startsAt! : now,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)));
      if (!mounted || date == null) return;
      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
              _startsAt ?? now.add(const Duration(hours: 1))));
      if (!mounted || time == null) return;
      setState(() {
        _startsAt =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _error = null;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty
      ? t('هذا الحقل مطلوب', 'This field is required',
          'Ce champ est obligatoire')
      : null;

  bool _validDate() =>
      _startsAt != null &&
      _startsAt!.isAfter(DateTime.now()) &&
      !_startsAt!.isAfter(DateTime.now().add(const Duration(days: 365)));

  void _review() {
    if (!_form.currentState!.validate()) return;
    final data = <String, dynamic>{'type': widget.kind};
    if (widget.kind == 'contact') {
      data.addAll({
        'contactName': _title.text.trim(),
        'contactPhone': normalizeChatContactPhone(_phone.text)
      });
    } else if (widget.kind == 'poll') {
      final options = _options.map((c) => c.text.trim()).toList();
      if (options.map((s) => s.toLowerCase()).toSet().length !=
          options.length) {
        setState(() => _error = t('يجب أن تكون الخيارات مختلفة',
            'Options must be different', 'Les choix doivent être différents'));
        return;
      }
      data.addAll(
          {'question': _title.text.trim(), 'optionsJson': jsonEncode(options)});
    } else {
      if (!_validDate()) {
        setState(() => _error = t(
            'اختر موعدًا مستقبليًا خلال سنة',
            'Choose a future time within one year',
            'Choisissez une date future dans un an au maximum'));
        return;
      }
      data.addAll({
        'title': _title.text.trim(),
        'startsAtMs': _startsAt!.millisecondsSinceEpoch,
        if (_place.text.trim().isNotEmpty) 'place': _place.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim()
      });
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _preview = data;
      _error = null;
    });
  }

  String get _dateLabel => _startsAt == null
      ? t('اختيار التاريخ والوقت', 'Choose date and time',
          'Choisir la date et l’heure')
      : '${MaterialLocalizations.of(context).formatMediumDate(_startsAt!)} · ${TimeOfDay.fromDateTime(_startsAt!).format(context)}';

  Widget _field(TextEditingController controller, String key, String label,
          {int maxLength = 120,
          TextInputType? keyboard,
          String? Function(String?)? validate}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            key: ValueKey(key),
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboard,
            validator: (value) {
              if ((value ?? '').trim().length > maxLength) {
                return t(
                    'النص أطول من الحد المسموح',
                    'Text exceeds the length limit',
                    'Le texte dépasse la longueur autorisée');
              }
              return (validate ?? _required)(value);
            },
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
          ));

  void _send() {
    if (_finished || _preview == null) return;
    if (widget.kind == 'event' && !_validDate()) {
      setState(() {
        _preview = null;
        _error = t(
            'الموعد مضى. اختر موعدًا جديدًا.',
            'This time has passed. Choose another time.',
            'Cette date est passée. Choisissez-en une autre.');
      });
      return;
    }
    _finished = true;
    Navigator.of(context).pop(_preview);
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.kind == 'contact';
    final poll = widget.kind == 'poll';
    final title = contact
        ? t('مشاركة جهة اتصال', 'Share contact', 'Partager un contact')
        : poll
            ? t('إنشاء استطلاع', 'Create poll', 'Créer un sondage')
            : t('إنشاء حدث', 'Create event', 'Créer un événement');
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                  key: const ValueKey('attachment-cancel'),
                  tooltip: t('إلغاء', 'Cancel', 'Annuler'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop())
            ]),
            const SizedBox(height: 12),
            if (_preview == null)
              Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (contact)
                          TextButton.icon(
                              key: const ValueKey('contact-pick'),
                              onPressed: _picking ? null : _pickContact,
                              icon: const Icon(Icons.contacts_outlined),
                              label: Text(t('اختيار من جهات الاتصال',
                                  'Choose contact', 'Choisir un contact'))),
                        _field(
                            _title,
                            'attachment-title',
                            contact
                                ? t('الاسم', 'Name', 'Nom')
                                : poll
                                    ? t('السؤال', 'Question', 'Question')
                                    : t('عنوان الحدث', 'Event title',
                                        'Titre de l’événement'),
                            maxLength: poll ? 300 : 120),
                        if (contact)
                          _field(
                              _phone,
                              'contact-phone',
                              t('رقم الهاتف', 'Phone number',
                                  'Numéro de téléphone'),
                              maxLength: 40,
                              keyboard: TextInputType.phone, validate: (value) {
                            return RegExp(r'^\+?[0-9]{6,15}$').hasMatch(
                                    normalizeChatContactPhone(value ?? ''))
                                ? null
                                : t(
                                    'أدخل رقمًا من 6 إلى 15 رقمًا',
                                    'Enter a number with 6 to 15 digits',
                                    'Saisissez un numéro de 6 à 15 chiffres');
                          }),
                        if (poll) ...[
                          Text(t(
                              'يمكن لكل شخص اختيار إجابة واحدة.',
                              'Each person can choose one answer.',
                              'Chaque personne peut choisir une réponse.')),
                          const SizedBox(height: 10),
                          for (var i = 0; i < _options.length; i++)
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _field(
                                          _options[i],
                                          'poll-option-$i',
                                          '${t('الخيار', 'Option', 'Choix')} ${i + 1}')),
                                  if (_options.length > 2)
                                    IconButton(
                                        tooltip: t(
                                            'حذف الخيار',
                                            'Remove option',
                                            'Supprimer le choix'),
                                        onPressed: () {
                                          final removed = _options[i];
                                          setState(() => _options.removeAt(i));
                                          // The old field can still be attached until the next frame.
                                          WidgetsBinding.instance
                                              .addPostFrameCallback(
                                                  (_) => removed.dispose());
                                        },
                                        icon: const Icon(
                                            Icons.remove_circle_outline)),
                                ]),
                          if (_options.length < 8)
                            TextButton.icon(
                                key: const ValueKey('poll-add'),
                                onPressed: () => setState(() =>
                                    _options.add(TextEditingController())),
                                icon: const Icon(Icons.add),
                                label: Text(t('إضافة خيار', 'Add option',
                                    'Ajouter un choix'))),
                        ],
                        if (!contact && !poll) ...[
                          OutlinedButton.icon(
                              key: const ValueKey('event-date'),
                              onPressed: _picking ? null : _pickDate,
                              icon: const Icon(Icons.event),
                              label: Text(_dateLabel)),
                          _field(
                              _place,
                              'event-place',
                              t('المكان (اختياري)', 'Place (optional)',
                                  'Lieu (facultatif)'),
                              maxLength: 200,
                              validate: (_) => null),
                          _field(
                              _description,
                              'event-description',
                              t('الوصف (اختياري)', 'Description (optional)',
                                  'Description (facultative)'),
                              maxLength: 1000,
                              validate: (_) => null),
                        ],
                      ])),
            if (_preview != null)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                t(
                                    'معاينة قبل الإرسال',
                                    'Preview before sending',
                                    'Aperçu avant envoi'),
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 12),
                            Text(_title.text.trim(),
                                style: Theme.of(context).textTheme.titleMedium),
                            if (contact)
                              Text(normalizeChatContactPhone(_phone.text),
                                  textDirection: TextDirection.ltr),
                            if (poll)
                              for (final option in _options)
                                Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('○ ${option.text.trim()}')),
                            if (!contact && !poll) ...[
                              Text(_dateLabel),
                              if (_place.text.trim().isNotEmpty)
                                Text(_place.text.trim()),
                              if (_description.text.trim().isNotEmpty)
                                Text(_description.text.trim())
                            ],
                          ]))),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_error!,
                      key: const ValueKey('attachment-error'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (_preview != null)
              TextButton(
                  onPressed: () => setState(() => _preview = null),
                  child: Text(t('تعديل', 'Edit', 'Modifier'))),
            FilledButton(
                key: ValueKey(
                    _preview == null ? 'attachment-review' : 'attachment-send'),
                onPressed:
                    _picking ? null : (_preview == null ? _review : _send),
                child: Text(_preview == null
                    ? t('معاينة', 'Preview', 'Aperçu')
                    : t('إرسال', 'Send', 'Envoyer'))),
          ])),
    );
  }
}
