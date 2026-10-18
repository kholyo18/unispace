/// Legacy lists are read as one reaction per person, using the last selection.
String? chatReaction(Object? value) {
  if (value is String) return value.trim().isEmpty ? null : value;
  if (value is List) {
    for (final entry in value.reversed) {
      if (entry is String && entry.trim().isNotEmpty) return entry;
    }
  }
  return null;
}

List<String> nextChatReaction(Object? current, String emoji) =>
    chatReaction(current) == emoji ? const [] : [emoji];
