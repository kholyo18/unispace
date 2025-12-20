const List<String> communityBadWords = [
  'abuse',
  'bully',
  'harass',
  'hate',
  'racist',
  'sexist',
  'slur',
  'threat',
];

bool containsBadWords(String input) {
  final normalized = input.toLowerCase();
  if (normalized.trim().isEmpty) return false;
  final tokens = normalized.split(RegExp(r'[^a-z0-9]+')).where((token) {
    return token.trim().isNotEmpty;
  });
  for (final token in tokens) {
    if (communityBadWords.contains(token)) {
      return true;
    }
  }
  return false;
}

bool containsBadWordsInList(Iterable<String> values) {
  for (final value in values) {
    if (containsBadWords(value)) {
      return true;
    }
  }
  return false;
}
