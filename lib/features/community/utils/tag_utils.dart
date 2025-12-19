const int kMaxTagLength = 24;

String? normalizeTag(String input) {
  var trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  while (trimmed.startsWith('#')) {
    trimmed = trimmed.substring(1);
  }

  final collapsed = trimmed.replaceAll(RegExp(r'\s+'), '');
  if (collapsed.isEmpty) return null;
  if (collapsed.length > kMaxTagLength) return null;

  return collapsed;
}

String displayTag(String tag) {
  final normalized = normalizeTag(tag);
  if (normalized == null) {
    return '#${tag.trim()}';
  }
  return '#$normalized';
}
