import 'chat_activity_client.dart';

/// Shared conversation display rules; membership authority remains on the server.
class ChatConversationMetadata {
  ChatConversationMetadata(this.data, this.viewerId);
  final Map<String, dynamic> data;
  final String viewerId;
  bool get isGroup => data['type'] == 'group';
  List<String> get otherIds => (data['memberIds'] as List? ?? const [])
      .whereType<String>()
      .where((id) => id != viewerId)
      .toSet()
      .toList();

  /// A shared tick means *all* other current participants reached this point.
  /// Missing/private receipts and a group with no peers never imply delivery.
  DateTime? receiptThrough(String field,
      {required DateTime? Function(Object?) timestamp}) {
    final ids = otherIds;
    final receipts = data[field];
    if (ids.isEmpty || receipts is! Map) return null;
    DateTime? earliest;
    for (final id in ids) {
      final time = timestamp(receipts[id]);
      if (time == null) return null;
      if (earliest == null || time.isBefore(earliest)) earliest = time;
    }
    return earliest;
  }

  Duration typingRemaining(
      {required DateTime? Function(Object?) timestamp, required DateTime now}) {
    final typing = data['typing'];
    if (typing is! Map) return Duration.zero;
    var remaining = Duration.zero;
    for (final id in otherIds) {
      final value =
          ChatActivityClient.typingRemaining(timestamp(typing[id]), now);
      if (value > remaining) remaining = value;
    }
    return remaining;
  }

  static bool startsDay(int? current, int? older) {
    if (current == null) return false;
    if (older == null) return true;
    final a = DateTime.fromMillisecondsSinceEpoch(current);
    final b = DateTime.fromMillisecondsSinceEpoch(older);
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}
