import 'package:flutter/material.dart';
import '../../../services/community_search_text.dart';

class ChatSearchEntry {
  const ChatSearchEntry({required this.id, required this.text});
  final String id;
  final String text;
}

/// Entries stay in the caller's order (newest first in a reversed chat list).
/// Updating loaded history preserves the selected message, not its old index.
class ChatMessageSearch {
  String _query = '';
  List<String> _matchIds = const [];
  int _selectedIndex = -1;

  /// Normalized query, suitable for deciding whether search is active.
  String get query => _query;
  List<String> get matchIds => _matchIds;
  int get selectedIndex => _selectedIndex;
  String? get selectedId =>
      _selectedIndex < 0 ? null : _matchIds[_selectedIndex];

  void update(String query, List<ChatSearchEntry> entries) {
    final normalized = normalizeCommunitySearch(query);
    final sameQuery = normalized == _query;
    final previousId = selectedId;
    final previousIndex = _selectedIndex;
    _query = normalized;
    _matchIds = List.unmodifiable(normalized.isEmpty
        ? <String>[]
        : entries
            .where((entry) =>
                normalizeCommunitySearch(entry.text).contains(normalized))
            .map((entry) => entry.id)
            .toSet());
    if (_matchIds.isEmpty) {
      _selectedIndex = -1;
    } else if (!sameQuery) {
      _selectedIndex = 0;
    } else {
      final preservedIndex =
          previousId == null ? -1 : _matchIds.indexOf(previousId);
      _selectedIndex = preservedIndex >= 0
          ? preservedIndex
          : previousIndex.clamp(0, _matchIds.length - 1);
    }
  }

  bool move(int delta) {
    final next = _selectedIndex + delta;
    if (_selectedIndex < 0 ||
        delta == 0 ||
        next < 0 ||
        next >= _matchIds.length) {
      return false;
    }
    _selectedIndex = next;
    return true;
  }
}

class ChatSearchNavigation extends StatelessWidget {
  const ChatSearchNavigation({
    super.key,
    required this.current,
    required this.total,
    required this.loading,
    required this.hasOlder,
    required this.onOlder,
    required this.onNewer,
  });

  /// One-based selected match, or zero when there is no match.
  final int current, total;
  final bool loading, hasOlder;
  final VoidCallback? onOlder, onNewer;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final isArabic = language == 'ar';
    final isFrench = language == 'fr';
    final older = isArabic
        ? 'النتيجة الأقدم'
        : isFrench
            ? 'Résultat plus ancien'
            : 'Older match';
    final newer = isArabic
        ? 'النتيجة الأحدث'
        : isFrench
            ? 'Résultat plus récent'
            : 'Newer match';
    final count = '$total${hasOlder ? '+' : ''}';
    final label = total == 0
        ? (isArabic
            ? 'لا توجد نتائج'
            : isFrench
                ? 'Aucun résultat'
                : 'No results')
        : isArabic
            ? '$current من $count'
            : isFrench
                ? '$current sur $count'
                : '$current of $count';
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Row(children: [
          const SizedBox(width: 12),
          if (loading) ...[
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
          ],
          Expanded(
              child: Semantics(
                  liveRegion: true,
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant)))),
          IconButton(
              tooltip: older,
              onPressed: onOlder,
              icon: const Icon(Icons.keyboard_arrow_up_rounded)),
          IconButton(
              tooltip: newer,
              onPressed: onNewer,
              icon: const Icon(Icons.keyboard_arrow_down_rounded)),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

class ChatSearchHighlight extends StatelessWidget {
  const ChatSearchHighlight(
      {super.key, required this.selected, required this.child});
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected
            ? colors.primary.withValues(alpha: .13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected
                ? colors.primary.withValues(alpha: .5)
                : Colors.transparent),
      ),
      child: child,
    );
  }
}
