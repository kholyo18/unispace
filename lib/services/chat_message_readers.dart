/// A participant with an explicitly shared conversation read marker covering
/// the message. This model intentionally contains no per-message read time.
class ChatMessageReader {
  const ChatMessageReader({required this.uid, required this.name});
  final String uid;
  final String name;
}

/// Uses only the authorized chat snapshot and its voluntarily shared receipts.
/// A missing receipt is unknown, never proof that a participant has not read.
/// The timestamp adapter keeps Firebase types outside this pure projection.
List<ChatMessageReader> chatMessageReaders({
  required Map<String, dynamic> conversation,
  required String viewerId,
  required String authorId,
  required int? createdAt,
  required DateTime? Function(Object?) timestamp,
  bool pending = false,
  bool failed = false,
}) {
  final rawIds = conversation['memberIds'];
  final receipts = conversation['lastReadAt'];
  if (viewerId.isEmpty ||
      viewerId != authorId ||
      createdAt == null ||
      pending ||
      failed ||
      rawIds is! List ||
      receipts is! Map) {
    return const [];
  }
  final memberIds = rawIds.whereType<String>().toSet();
  if (!memberIds.contains(viewerId)) return const [];
  final members = conversation['members'];
  final readers = <ChatMessageReader>[];
  for (final uid in memberIds) {
    if (uid == authorId || uid.isEmpty) continue;
    final marker = timestamp(receipts[uid]);
    if (marker == null || marker.millisecondsSinceEpoch < createdAt) continue;
    final member = members is Map ? members[uid] : null;
    final name = member is Map && member['name'] is String
        ? (member['name'] as String).trim()
        : '';
    readers.add(ChatMessageReader(uid: uid, name: name));
  }
  return List.unmodifiable(readers);
}
