String normalizeCommunitySearch(String value) {
  var text = value.toLowerCase();
  const folds = {
    'àáâãäå': 'a',
    'ç': 'c',
    'èéêë': 'e',
    'ìíîï': 'i',
    'ñ': 'n',
    'òóôõö': 'o',
    'ùúûü': 'u',
    'ýÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
    'أإآٱ': 'ا',
    'ىئ': 'ي',
    'ؤ': 'و',
    'ة': 'ه',
  };
  for (final entry in folds.entries) {
    for (final rune in entry.key.runes) {
      text = text.replaceAll(String.fromCharCode(rune), entry.value);
    }
  }
  return text
      .replaceAll(RegExp(r'[\u0300-\u036f\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> communityQueryTokens(String query) {
  const stop = {
    'في',
    'من',
    'علي',
    'الي',
    'عن',
    'مع',
    'ما',
    'لا',
    'ان',
    'او',
    'و',
    'هذا',
    'هذه',
    'ذلك',
    'the',
    'and'
  };
  final all = normalizeCommunitySearch(query)
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();
  final useful = all.where((t) => !stop.contains(t)).toList();
  return useful.isEmpty ? all : useful;
}

bool communityTokensMatch(String value, List<String> tokens) {
  if (tokens.isEmpty) return false;
  final words = normalizeCommunitySearch(value).split(' ');
  return tokens.every((token) => words.any((word) =>
      word == token || (token.length >= 2 && word.startsWith(token))));
}
