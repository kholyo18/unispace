import 'dart:async';

/// Serializes user-initiated playback. Never starts a second player if pausing
/// the previous player fails; disposal invalidates queued requests.
class ChatAudioCoordinator {
  Future<void> _queue = Future.value();
  Object? _owner;
  Future<void> Function()? _pause;
  int _request = 0;
  Future<void> play(Object owner,
      {required Future<void> Function() start,
      required Future<void> Function() pause,
      required bool Function() valid}) {
    final request = ++_request;
    final result = _queue.then((_) async {
      if (request != _request || !valid()) return;
      if (_owner != null && !identical(_owner, owner)) await _pause!();
      if (request != _request || !valid()) return;
      _owner = owner;
      _pause = pause;
      await start();
      if (!valid() || request != _request) await pause();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  void release(Object owner) {
    if (identical(_owner, owner)) {
      _owner = null;
      _pause = null;
    }
  }

  Future<void> stop() {
    ++_request;
    final result = _queue.then((_) async {
      await _pause?.call();
      _owner = null;
      _pause = null;
    });
    _queue = result.catchError((Object _) {});
    return result;
  }
}

final chatAudioCoordinator = ChatAudioCoordinator();
