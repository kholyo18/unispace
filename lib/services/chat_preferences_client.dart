/// Writes only the screen owner's preferences using document-shaped merge data.
/// Session checks protect stale UI work; Firestore Rules remain authoritative.
class ChatPreferencesClient {
  ChatPreferencesClient({
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
  Future<void> _pending = Future<void>.value();
  bool _closed = false;

  bool get isCurrent =>
      !_closed &&
      expectedUid.isNotEmpty &&
      _session != null &&
      currentUid() == expectedUid &&
      sessionKey() == _session;

  Future<bool> setNickname(String value) => _send(
    () => {
      'nicknames': {expectedUid: value.trim()},
    },
  );

  Future<bool> setMuted(bool value) => _send(
    () => {
      'muted': {expectedUid: value},
    },
  );

  Future<bool> setAutoTranslate(bool value) => _send(
    () => {
      'autoTranslate': {expectedUid: value},
    },
  );

  Future<bool> clearHistory() => _send(
    () => {
      'clearedAt': {expectedUid: serverTimestamp()},
    },
  );

  Future<bool> setBubbleColor(int color) {
    if (!_validColor(color)) {
      throw ArgumentError.value(color, 'color');
    }
    return _theme(
      () => {'bubbleColor': color, 'bubbleGradient': deleteField()},
    );
  }

  Future<bool> setBubbleGradient(List<int> colors) {
    if (colors.length < 2 || colors.length > 6 || !colors.every(_validColor)) {
      throw ArgumentError('A gradient needs two to six valid ARGB colors.');
    }
    final copy = List<int>.unmodifiable(colors);
    return _theme(() => {'bubbleGradient': copy, 'bubbleColor': deleteField()});
  }

  Future<bool> setWallpaper(String id, {String? photoUrl}) {
    if (id.isEmpty ||
        (id == 'photo'
            ? photoUrl == null || photoUrl.isEmpty
            : photoUrl != null)) {
      throw ArgumentError('A photo wallpaper requires its uploaded URL.');
    }
    return _theme(
      () => {'wallpaper': id, 'wallpaperUrl': photoUrl ?? deleteField()},
    );
  }

  Future<bool> _theme(Map<String, dynamic> Function() values) => _send(
    () => {
      'theme': {expectedUid: values()},
    },
  );

  Future<bool> _send(Map<String, dynamic> Function() payload) {
    if (!isCurrent) {
      return Future<bool>.value(false);
    }
    final operation = _pending.then((_) async {
      if (!isCurrent) {
        return false;
      }
      final data = payload();
      if (!isCurrent) {
        return false;
      }
      await merge(data);
      return isCurrent;
    });
    // Preserve caller-visible failures without poisoning the next operation.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  void dispose() => _closed = true;

  static bool _validColor(int value) => value >= 0 && value <= 0xFFFFFFFF;
}

/// Tolerates old malformed containers; never imports a peer's preferences.
/// Values remain in a shared chat document, not a confidential per-user store.
class ChatPreferencesSnapshot {
  ChatPreferencesSnapshot.fromData(Map<String, dynamic> data, String uid) {
    Object? own(String key) {
      final container = data[key];
      return container is Map ? container[uid] : null;
    }

    final rawTheme = own('theme');
    final theme = rawTheme is Map ? rawTheme : const <String, dynamic>{};
    String text(Object? value, String fallback) =>
        value is String ? value : fallback;
    muted = own('muted') == true;
    nickname = text(own('nicknames'), '');
    autoTranslate = own('autoTranslate') == true;
    autoTranslateLang = text(own('autoTranslateLang'), 'ar');
    wallpaper = text(theme['wallpaper'], 'default');
    wallpaperUrl = text(theme['wallpaperUrl'], '');
    final color = theme['bubbleColor'];
    bubbleColor = color is int && ChatPreferencesClient._validColor(color)
        ? color
        : 0xFF0D9488;
    final gradient = theme['bubbleGradient'];
    bubbleGradient =
        gradient is List &&
            gradient.length >= 2 &&
            gradient.length <= 6 &&
            gradient.every(
              (v) => v is int && ChatPreferencesClient._validColor(v),
            )
        ? List<int>.unmodifiable(gradient.cast<int>())
        : null;
    clearedAt = own('clearedAt');
  }

  late final bool muted;
  late final String nickname;
  late final bool autoTranslate;
  late final String autoTranslateLang;
  late final String wallpaper;
  late final String wallpaperUrl;
  late final int bubbleColor;
  late final List<int>? bubbleGradient;
  late final Object? clearedAt;
}
