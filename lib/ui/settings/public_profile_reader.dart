/// Session-bound access to the server's authorized profile projection.
/// Injected boundaries let tests exercise the production logic without Firebase.
class PublicProfileReader {
  PublicProfileReader({
    required this.sessionKey,
    required this.fetchProfile,
  });

  final String? Function() sessionKey;
  final Future<Map<String, dynamic>> Function(String userId) fetchProfile;

  Future<Map<String, dynamic>> load(String userId) async {
    if (userId.isEmpty || userId.length > 128 || userId.contains('/') ||
        userId == '.' || userId == '..') {
      throw ArgumentError.value(userId, 'userId', 'Invalid profile identifier');
    }
    final session = sessionKey();
    if (session == null) throw StateError('Sign in before reading a profile');
    final response = await fetchProfile(userId);
    if (sessionKey() != session) throw StateError('Profile session changed');
    if (response['canViewContent'] is! bool || response['privacy'] is! Map) {
      throw StateError('Invalid profile response');
    }
    return Map<String, dynamic>.from(response);
  }

  // A private account can still be available: canViewContent is NOT an account
  // status. Missing, blocked, unauthorized and transient failures fail closed.
  Future<bool> isUnavailable(String userId) async {
    try {
      await load(userId);
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<Set<String>> unavailableUserIds(Iterable<String> ids) async {
    final unique = ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final list = unique.toList();
    final unavailable = <String>{};
    final session = sessionKey();
    if (session == null) return unique;
    // Never create an unbounded fan-out of callable requests.
    const batchSize = 5;
    for (var start = 0; start < list.length; start += batchSize) {
      if (sessionKey() != session) return unique;
      final end = start + batchSize < list.length ? start + batchSize : list.length;
      final batch = list.sublist(start, end);
      final results = await Future.wait(batch.map(isUnavailable));
      if (sessionKey() != session) return unique;
      for (var i = 0; i < batch.length; i++) {
        if (results[i]) unavailable.add(batch[i]);
      }
    }
    return unavailable;
  }

  // A watcher belongs to the session that opened it. It cannot silently carry
  // over to a different login, including a sign-out/sign-in of the same account.
  Stream<Map<String, dynamic>> watch(
    String userId, {
    Duration interval = const Duration(seconds: 30),
  }) async* {
    final session = sessionKey();
    if (session == null) throw StateError('Sign in before watching a profile');
    yield await load(userId);
    await for (final _ in Stream<void>.periodic(interval)) {
      if (sessionKey() != session) throw StateError('Profile session changed');
      yield await load(userId);
    }
  }
}
