import 'dart:async';

/// Cleanup is best-effort; authentication failure is still propagated.
Future<void> runSignOutPipeline({
  required Map<String, FutureOr<void> Function()> cleanup,
  required Future<void> Function() signOut,
  required Map<String, FutureOr<void> Function()> providers,
  required void Function(String stage, Object error, StackTrace stack)
      onFailure,
  required void Function() onAuthFailure,
  Duration stageTimeout = const Duration(seconds: 5),
}) async {
  Future<void> attempt(String name, FutureOr<void> Function() action) async {
    try {
      await Future<void>.sync(action).timeout(stageTimeout);
    } catch (error, stack) {
      onFailure(name, error, stack);
    }
  }

  for (final entry in cleanup.entries) {
    await attempt(entry.key, entry.value);
  }
  try {
    await signOut();
  } catch (_) {
    onAuthFailure();
    rethrow;
  } finally {
    for (final entry in providers.entries) {
      await attempt(entry.key, entry.value);
    }
  }
}
