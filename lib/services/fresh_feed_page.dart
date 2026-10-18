import 'package:cloud_functions/cloud_functions.dart';

/// Request a short startup page, tolerating a server predating pageSize.
Future<Map<String, dynamic>> requestFeedPage({
  required Future<Map<String, dynamic>> Function(Map<String, dynamic>) call,
  required Map<String, dynamic>? cursor,
  int? pageSize,
}) async {
  try {
    return await call({'cursor': cursor, if (pageSize != null) 'pageSize': pageSize});
  } on FirebaseFunctionsException catch (error) {
    if (pageSize == null || error.code != 'invalid-argument') rethrow;
    return call({'cursor': cursor});
  }
}

/// One completed server response and the local filters read alongside it.
/// This object is never retained as a permission cache.
class FreshFeedPage {
  const FreshFeedPage(this.page, this.hidden, this.blocked);
  final Map<String, dynamic> page;
  final Set<String> hidden, blocked;

  // Older servers do not emit this capability: retain client author rechecks.
  bool get authorAccessRechecked => page['authorAccessRechecked'] == true;
}

Future<FreshFeedPage?> loadFreshFeedPage({
  required Future<Map<String, dynamic>> Function() readPage,
  required Future<Set<String>> Function() readHidden,
  required Future<Set<String>> Function() readBlocked,
  required bool Function() isCurrent,
}) async {
  if (!isCurrent()) return null;
  final values = await Future.wait<Object>([readPage(), readHidden(), readBlocked()]);
  if (!isCurrent()) return null;
  return FreshFeedPage(values[0] as Map<String, dynamic>,
      values[1] as Set<String>, values[2] as Set<String>);
}
