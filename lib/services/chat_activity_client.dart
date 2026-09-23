/// Coordinates only a participant's own read/typing metadata.
/// The injected writer uses a nested merge, never literal dotted set keys.
/// Local session checks are a UI safeguard; Firebase Rules provide authority.
class ChatActivityClient {
  ChatActivityClient({
    required this.expectedUid,
    required this.currentUid,
    required this.sessionKey,
    required this.merge,
    required this.serverTimestamp,
    required this.deleteField,
  }) : _session = sessionKey();

  final String expectedUid;
  final String? Function() currentUid;
  final String? Function() sessionKey;
  final Future<void> Function(Map<String, dynamic>) merge;
  final Object Function() serverTimestamp;
  final Object Function() deleteField;
  final String? _session;
  bool _closed = false;

  bool get isCurrent =>
      !_closed &&
      expectedUid.isNotEmpty &&
      _session != null &&
      currentUid() == expectedUid &&
      sessionKey() == _session;

  Future<bool> markRead() => _send(() => {
        'lastReadAt': {expectedUid: serverTimestamp()},
        'unread': {expectedUid: 0},
      });

  Future<bool> setTyping(bool active) => _send(() => {
        'typing': {expectedUid: active ? serverTimestamp() : deleteField()},
      });

  Future<bool> _send(Map<String, dynamic> Function() payload) async {
    if (!isCurrent) return false;
    final data = payload();
    if (!isCurrent) return false;
    await merge(data);
    return isCurrent;
  }

  void dispose() {
    _closed = true;
  }

  /// A stale/future timestamp must not leave the peer indicator stuck on.
  static Duration typingRemaining(DateTime? timestamp, DateTime now) {
    if (timestamp == null || timestamp.isAfter(now)) return Duration.zero;
    final remaining = const Duration(seconds: 4) - now.difference(timestamp);
    return remaining > Duration.zero ? remaining : Duration.zero;
  }
}
