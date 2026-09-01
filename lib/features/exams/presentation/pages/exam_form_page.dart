import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/l10n.dart';
import '../../data/models/exam_model.dart';

class ExamFormPage extends StatefulWidget {
  const ExamFormPage({super.key, this.exam});

  final ExamModel? exam;

  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _dateTime;
  bool _remindersEnabled = true;
  final List<int> _selectedOffsets = <int>[1440, 120, 30];

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    if (exam != null) {
      _subjectController.text = exam.subject;
      _roomController.text = exam.room ?? '';
      _noteController.text = exam.note ?? '';
      _dateTime = exam.dateTime;
      _remindersEnabled = exam.remindersEnabled;
      _selectedOffsets
        ..clear()
        ..addAll(exam.reminderOffsets);
    } else {
      _dateTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _toggleOffset(int offset, bool enabled) {
    setState(() {
      if (enabled) {
        if (!_selectedOffsets.contains(offset)) {
          _selectedOffsets.add(offset);
        }
      } else {
        _selectedOffsets.remove(offset);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newExam = ExamModel(
      id: widget.exam?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _subjectController.text.trim(),
      dateTime: _dateTime,
      room: _roomController.text.trim().isEmpty
          ? null
          : _roomController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      remindersEnabled: _remindersEnabled,
      reminderOffsets: List<int>.from(_selectedOffsets)..sort(),
    );

    Navigator.of(context).pop(newExam);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMd(locale).format(_dateTime);
    final timeLabel = DateFormat.Hm(locale).format(_dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam == null ? s.addExam : s.editExam),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: s.examSubject,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return s.examSubjectRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(dateLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(timeLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: s.examRoom,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.examNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(s.reminders),
                value: _remindersEnabled,
                onChanged: (value) => setState(() => _remindersEnabled = value),
              ),

              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text(s.reminder24h),
                value: _selectedOffsets.contains(1440),
                onChanged: _remindersEnabled
                    ? (value) => _toggleOffset(1440, value ?? false)
                    : null,
              ),
              CheckboxListTile(
                title: Text(s.reminder2h),
                value: _selectedOffsets.contains(120),
                onChanged: _remindersEnabled
                    ? (value) => _toggleOffset(120, value ?? false)
                    : null,
              ),
              CheckboxListTile(
                title: Text(s.reminder30m),
                value: _selectedOffsets.contains(30),
                onChanged: _remindersEnabled
                    ? (value) => _toggleOffset(30, value ?? false)
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.exam == null ? s.addExam : s.saveExam),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
