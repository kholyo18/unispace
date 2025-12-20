const int kMaxTagLength = 24;

String? normalizeTag(String input) {
  var trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  while (trimmed.startsWith('#')) {
    trimmed = trimmed.substring(1).trimLeft();
  }

  final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.isEmpty) return null;
  final normalized = collapsed.toLowerCase();
  if (normalized.length > kMaxTagLength) return null;

  return normalized;
}

String displayTag(String tag) {
  final normalized = normalizeTag(tag);
  if (normalized == null) {
    return '#${tag.trim()}';
  }
  return '#$normalized';
}
