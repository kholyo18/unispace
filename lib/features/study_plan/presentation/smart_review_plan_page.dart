import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unispace/generated/l10n.dart';

import '../../exams/data/models/exam_model.dart';
import '../../exams/data/storage/exam_storage.dart';
import '../../exams/presentation/pages/exams_calendar_page.dart';
import '../application/smart_review_plan_generator.dart';
import '../data/smart_review_repository.dart';
import '../data/smart_review_storage.dart';
import '../domain/models/smart_review_plan.dart';

class SmartReviewPlanPage extends StatefulWidget {
  const SmartReviewPlanPage({super.key});

  @override
  State<SmartReviewPlanPage> createState() => _SmartReviewPlanPageState();
}

class _SmartReviewPlanPageState extends State<SmartReviewPlanPage> {
  final ExamStorage _examStorage = ExamStorage();
  final SmartReviewRepository _repository =
      SmartReviewRepository(SmartReviewStorage());
  final SmartReviewPlanGenerator _generator = SmartReviewPlanGenerator();

  SmartReviewPlan? _plan;
  List<ExamModel> _exams = [];
  bool _contentVisible = false;
  bool _isLoading = true;
  bool _isCreating = false;
  bool _ctaPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _contentVisible = true);
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final exams = await _examStorage.loadExams();
    final plan = await _repository.loadPlan();
    if (!mounted) return;
    setState(() {
      _exams = exams;
      _plan = plan;
      _isLoading = false;
    });
  }

  List<ExamModel> get _upcomingExams {
    final today = _dateOnly(DateTime.now());
    final upcoming = _generator.filterUpcomingExams(_exams, today);
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming;
  }

  Future<void> _handleCreatePlan() async {
    if (_isCreating) return;
    setState(() {
      _isCreating = true;
      _ctaPressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      setState(() => _ctaPressed = false);
    }

    final generated = _generator.generatePlan(exams: _upcomingExams);
    if (!mounted) return;
    if (generated == null) {
      setState(() => _isCreating = false);
      _showSnackBar(S.of(context).smartReviewEmptyNoExamsBody);
      return;
    }

    await _repository.savePlan(generated);
    if (!mounted) return;
    setState(() {
      _plan = generated;
      _isCreating = false;
    });
  }

  Future<void> _handleClearPlan() async {
    await _repository.clearPlan();
    if (!mounted) return;
    setState(() => _plan = null);
    _showSnackBar(S.of(context).smartReviewPlanCleared);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = S.of(context);

    final chipStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.smartReviewTitle),
        actions: [
          if (_plan != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _handleClearPlan();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(t.smartReviewActionClearPlan),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.4,
                  colors: [
                    scheme.primary.withOpacity(0.08),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: AnimatedOpacity(
                      opacity: _contentVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: AnimatedSlide(
                        offset: _contentVisible
                            ? Offset.zero
                            : const Offset(0, 0.06),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroHeaderCard(t: t),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  label: t.smartReviewChipExams,
                                  icon: Icons.event_available_outlined,
                                  textStyle: chipStyle,
                                ),
                                _InfoChip(
                                  label: t.smartReviewChipTime,
                                  icon: Icons.access_time,
                                  textStyle: chipStyle,
                                ),
                                _InfoChip(
                                  label: t.smartReviewChipReminders,
                                  icon: Icons.notifications_active_outlined,
                                  textStyle: chipStyle,
                                ),
                                _InfoChip(
                                  label: t.smartReviewChipSimple,
                                  icon: Icons.auto_awesome_outlined,
                                  textStyle: chipStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_upcomingExams.isEmpty)
                              _EmptyStateCard(
                                title: t.smartReviewEmptyNoExamsTitle,
                                description: t.smartReviewEmptyNoExamsBody,
                                buttonLabel: t.smartReviewActionAddExam,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ExamsCalendarPage(),
                                    ),
                                  );
                                },
                              )
                            else if (_plan == null) ...[
                              Text(
                                t.smartReviewPreviewTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _PreviewCard(
                                title: t.smartReviewPreviewItem1,
                                icon: Icons.check_circle_outline,
                                subtitle: t.smartReviewChipTime,
                              ),
                              const SizedBox(height: 12),
                              _PreviewCard(
                                title: t.smartReviewPreviewItem2,
                                icon: Icons.auto_graph_outlined,
                                subtitle: t.smartReviewChipReminders,
                              ),
                              const SizedBox(height: 12),
                              _PreviewCard(
                                title: t.smartReviewPreviewItem3,
                                icon: Icons.tips_and_updates_outlined,
                                subtitle: t.smartReviewChipSimple,
                              ),
                              const SizedBox(height: 20),
                              _EmptyStateCard(
                                title: t.smartReviewEmptyNoPlanTitle,
                                description: t.smartReviewEmptyNoPlanBody,
                                buttonLabel: t.smartReviewCtaCreate,
                                isPrimary: true,
                                onPressed: _isCreating ? null : _handleCreatePlan,
                                isLoading: _isCreating,
                                isPressed: _ctaPressed,
                              ),
                            ] else ...[
                              _PlanRangeCard(
                                title: t.smartReviewPlanSectionTitle,
                                subtitle: t.smartReviewPlanRange(
                                  _formatDate(context, _plan!.rangeStart),
                                  _formatDate(context, _plan!.rangeEnd),
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (final day in _plan!.days) ...[
                                _PlanDayCard(
                                  title: _formatDay(context, day.date),
                                  tasks: day.tasks
                                      .map(
                                        (task) => _TaskItem(
                                          icon: _taskIcon(task.type),
                                          title: _taskTitle(t, task),
                                          subtitle: t.smartReviewTaskDuration(
                                            task.durationMinutes,
                                          ),
                                          notes: task.notes,
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                t.smartReviewTipsTitle,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.smartReviewTipsBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (_plan == null)
                              Card(
                                elevation: 0,
                                color: scheme.surfaceVariant.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: scheme.outlineVariant),
                                ),
                                child: Theme(
                                  data: theme.copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    leading: Icon(
                                      Icons.lightbulb_outline,
                                      color: scheme.primary,
                                    ),
                                    title: Text(
                                      t.smartReviewTipsTitle,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    children: [
                                      Text(
                                        t.smartReviewTipsBody,
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  String _formatDay(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.EEEE(locale).add_MMMd().format(date);
  }

  String _taskTitle(S t, SmartReviewTask task) {
    switch (task.type) {
      case SmartReviewTaskType.focusSession:
        return t.smartReviewTaskFocusTitle(task.subjectName);
      case SmartReviewTaskType.practiceQuiz:
        return t.smartReviewTaskPracticeTitle(task.subjectName);
      case SmartReviewTaskType.summaryReview:
        return t.smartReviewTaskSummaryTitle(task.subjectName);
      case SmartReviewTaskType.mockTest:
        return t.smartReviewTaskMockTitle(task.subjectName);
    }
  }

  IconData _taskIcon(SmartReviewTaskType type) {
    switch (type) {
      case SmartReviewTaskType.focusSession:
        return Icons.track_changes;
      case SmartReviewTaskType.practiceQuiz:
        return Icons.quiz_outlined;
      case SmartReviewTaskType.summaryReview:
        return Icons.sticky_note_2_outlined;
      case SmartReviewTaskType.mockTest:
        return Icons.assignment_outlined;
    }
  }
}

class _HeroHeaderCard extends StatelessWidget {
  const _HeroHeaderCard({required this.t});

  final S t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 1,
      shadowColor: scheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withOpacity(0.7),
              scheme.surface,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.smartReviewTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.smartReviewSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    this.textStyle,
  });

  final String label;
  final IconData icon;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: scheme.primary),
      label: Text(label, style: textStyle),
      backgroundColor: scheme.surfaceVariant.withOpacity(0.6),
      side: BorderSide(color: scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
    this.isPressed = false,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final button = isPrimary
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(buttonLabel),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.event_available_outlined),
            label: Text(buttonLabel),
          );

    return Card(
      elevation: 0,
      color: scheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedScale(
              scale: isPressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 120),
              child: SizedBox(width: double.infinity, child: button),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRangeCard extends StatelessWidget {
  const _PlanRangeCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_today_outlined, color: scheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PlanDayCard extends StatelessWidget {
  const _PlanDayCard({required this.title, required this.tasks});

  final String title;
  final List<_TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final task in tasks) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(task.icon, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (task.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (task != tasks.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskItem {
  const _TaskItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.notes,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? notes;
}
