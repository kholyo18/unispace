import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../exams/presentation/pages/exams_calendar_page.dart';

class SmartReviewPlanPage extends StatefulWidget {
  const SmartReviewPlanPage({super.key});

  @override
  State<SmartReviewPlanPage> createState() => _SmartReviewPlanPageState();
}

class _SmartReviewPlanPageState extends State<SmartReviewPlanPage> {
  bool _contentVisible = false;
  bool _isLoading = false;
  bool _ctaPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _contentVisible = true);
      }
    });
  }

  Future<void> _handleCreatePlan() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _ctaPressed = true;
    });
    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) {
      setState(() => _ctaPressed = false);
    }
    await Future.delayed(const Duration(milliseconds: 460));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showRequirementsSheet();
  }

  void _showRequirementsSheet() {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.smartReviewBottomSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.smartReviewBottomSheetBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(s.soon)),
                          );
                        },
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(s.smartReviewActionAddSubjects),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(this.context).push(
                            MaterialPageRoute(
                              builder: (_) => const ExamsCalendarPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(s.smartReviewActionAddExam),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.smartReviewActionLater),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = S.of(context);

    final chipStyle = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.smartReviewTitle),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: AnimatedOpacity(
                opacity: _contentVisible ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _contentVisible ? Offset.zero : const Offset(0, 0.06),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroHeaderCard(s: s),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: s.smartReviewChipExams,
                            icon: Icons.event_available_outlined,
                            textStyle: chipStyle,
                          ),
                          _InfoChip(
                            label: s.smartReviewChipTime,
                            icon: Icons.access_time,
                            textStyle: chipStyle,
                          ),
                          _InfoChip(
                            label: s.smartReviewChipReminders,
                            icon: Icons.notifications_active_outlined,
                            textStyle: chipStyle,
                          ),
                          _InfoChip(
                            label: s.smartReviewChipSimple,
                            icon: Icons.auto_awesome_outlined,
                            textStyle: chipStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        s.smartReviewPreviewTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _PreviewCard(
                        title: s.smartReviewPreviewItem1,
                        icon: Icons.check_circle_outline,
                        subtitle: s.smartReviewChipTime,
                      ),
                      const SizedBox(height: 12),
                      _PreviewCard(
                        title: s.smartReviewPreviewItem2,
                        icon: Icons.auto_graph_outlined,
                        subtitle: s.smartReviewChipReminders,
                      ),
                      const SizedBox(height: 12),
                      _PreviewCard(
                        title: s.smartReviewPreviewItem3,
                        icon: Icons.tips_and_updates_outlined,
                        subtitle: s.smartReviewChipSimple,
                      ),
                      const SizedBox(height: 24),
                      AnimatedScale(
                        scale: _ctaPressed ? 0.98 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleCreatePlan,
                            icon: _isLoading
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(s.smartReviewCtaCreate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              s.smartReviewTipsTitle,
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
                                s.smartReviewTipsBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
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
}

class _HeroHeaderCard extends StatelessWidget {
  const _HeroHeaderCard({required this.s});

  final S s;

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
                    s.smartReviewTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.smartReviewSubtitle,
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
