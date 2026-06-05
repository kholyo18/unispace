import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../generated/l10n.dart';
import '../../../ui/contact/contact_us_sheet.dart';
import '../privacy/privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.aboutApp),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderSection(colorScheme: colorScheme),
          const SizedBox(height: 20),
          _InfoCard(
            child: Text(
              s.aboutAppDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aboutAppSummary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.calculate_outlined,
                  label: s.aboutAppFeatureGpa,
                ),
                _FeatureItem(
                  icon: Icons.auto_graph_outlined,
                  label: s.aboutAppFeatureReviewPlan,
                ),
                _FeatureItem(
                  icon: Icons.event_note_outlined,
                  label: s.aboutAppFeatureExams,
                ),
                _FeatureItem(
                  icon: Icons.note_alt_outlined,
                  label: s.aboutAppFeatureNotes,
                ),
                _FeatureItem(
                  icon: Icons.school_outlined,
                  label: s.aboutAppFeatureStudents,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: s.privacyPolicy,
                  onTap: () => _showPrivacyPolicy(context),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.mail_outline,
                  label: s.contactUs,
                  onTap: () => _showContactSheet(context),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.description_outlined,
                  label: s.aboutAppViewLicenses,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'UniSpace',
                    applicationVersion: '1.0.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.aboutAppFooter,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ContactUsSheet(),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
          child: SvgPicture.asset(
            'assets/brand/logo-mark.svg',
            height: 48,
            colorFilter: ColorFilter.mode(
              colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'UniSpace',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'v1.0.0',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.outline),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_left),
      contentPadding: EdgeInsets.zero,
    );
  }
}
