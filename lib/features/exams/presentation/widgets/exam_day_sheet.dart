import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../generated/l10n.dart';
import '../../data/models/exam_model.dart';

class ExamDaySheet extends StatelessWidget {
  const ExamDaySheet({
    super.key,
    required this.day,
    required this.exams,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime day;
  final List<ExamModel> exams;
  final VoidCallback onAdd;
  final ValueChanged<ExamModel> onEdit;
  final ValueChanged<ExamModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMEEEEd(locale).format(day);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, controller) {
          return Material(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: s.addExam,
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: exams.isEmpty
                      ? Center(
                          child: Text(
                            s.noExamsDay,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final exam = exams[index];
                            final timeLabel =
                                DateFormat.Hm(locale).format(exam.dateTime);
                            return Card(
                              child: ListTile(
                                title: Text(exam.subject),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(timeLabel),
                                    if (exam.room != null &&
                                        exam.room!.trim().isNotEmpty)
                                      Text('${s.examRoom}: ${exam.room}'),
                                    if (exam.note != null &&
                                        exam.note!.trim().isNotEmpty)
                                      Text('${s.examNote}: ${exam.note}'),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: s.editExam,
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => onEdit(exam),
                                    ),
                                    IconButton(
                                      tooltip: s.deleteExam,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => onDelete(exam),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: exams.length,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
