import 'package:flutter/material.dart';

class NumberChip extends StatelessWidget {
  const NumberChip({
    super.key,
    required this.text,
    this.onTap,
    this.selected = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: .12)
                : theme.colorScheme.surfaceVariant.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
