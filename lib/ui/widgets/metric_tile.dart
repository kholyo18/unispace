import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),border: Border.all(color: theme.colorScheme.onSurface ),
            boxShadow: [
              if (theme.brightness == Brightness.light)
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 0),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        value,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
