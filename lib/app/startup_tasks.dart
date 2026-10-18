import 'dart:async';

/// Both dependency groups must finish before the first application frame.
/// Callers retain their existing error handling inside each group.
Future<void> initializeStartupDependencies({
  required Future<void> Function() initializeFirebase,
  required Future<void> Function() initializeLocalSettings,
}) async {
  await Future.wait<void>([
    Future<void>.sync(initializeFirebase),
    Future<void>.sync(initializeLocalSettings),
  ]);
}

/// Five attempts, with backoff only when another attempt will follow.
Future<void> initializeFirebaseWithRetry({
  required Future<void> Function() initialize,
  required void Function(int attempt, Object error) onFailure,
  Future<void> Function(Duration) delay = Future<void>.delayed,
}) async {
  for (var attempt = 1; attempt <= 5; attempt++) {
    try {
      await initialize();
      return;
    } catch (error) {
      onFailure(attempt, error);
      if (attempt == 5) rethrow;
      await delay(Duration(milliseconds: 250 * attempt));
    }
  }
}
