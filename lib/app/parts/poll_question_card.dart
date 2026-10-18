part of '../../main.dart';

class GoogleFormQuestionCard extends StatelessWidget {
  final String typeLabel;
  final IconData typeIcon;
  final Widget? questionField;
  final Widget? body; // الخيارات أو المحتوى الخاص
  final bool isRequired;
  final ValueChanged<bool>? onRequiredChanged;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onMore;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;

  const GoogleFormQuestionCard({
    super.key,
    required this.typeLabel,
    required this.typeIcon,
    required this.questionField,
    this.body,
    this.isRequired = false,
    this.onRequiredChanged,
    this.onDuplicate,
    this.onDelete,
    this.onMore,
    this.onMoveUp,
    this.onMoveDown,
    this.canMoveUp = false,
    this.canMoveDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== رأس النوع =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800
                  : const Color(0xFFF1F3F4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // أزرار الترتيب
                if (onMoveUp != null)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: canMoveUp ? onMoveUp : null,
                  ),
                if (onMoveDown != null)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: canMoveDown ? onMoveDown : null,
                  ),
              ],
              )),

          // ===== المحتوى =====
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (questionField != null) questionField!,
                if (body != null) ...[
                  if (questionField != null) const SizedBox(height: 12),
                  body!,
                ],
              ],
            ),
          ),

          // ===== الشريط السفلي =====
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Required
                if (onRequiredChanged != null) ...[
                  Text(
                    mainText(context, "Required"),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: isRequired,
                    onChanged: onRequiredChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
                const Spacer(),
                if (onDuplicate != null)
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    tooltip: mainText(context, "Duplicate"),
                    onPressed: onDuplicate,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
                if (onMore != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: onMore,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//=======================================================

class _DateModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DateModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? theme.colorScheme.primary : theme.hintColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//================GoogleFormQuestionCard========================
