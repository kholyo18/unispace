import 'package:cloud_functions/cloud_functions.dart';

/// A failed index or later page must not discard earlier authorized results.
Future<({bool incomplete, bool truncated})> scanContentSearch({
  required bool indexed,
  required Future<bool> Function(int page) loadPage,
  required bool Function() current,
}) async {
  var incomplete = false;
  Future<bool?> load(int page) async {
    try {
      return await loadPage(page);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'unauthenticated' ||
          error.code == 'permission-denied') {
        rethrow;
      }
      incomplete = true;
      return null;
    }
  }

  if (indexed && current()) await load(0);
  for (var page = 1; page <= 5 && current(); page++) {
    final exhausted = await load(page);
    if (exhausted == true || exhausted == null) {
      return (incomplete: incomplete, truncated: false);
    }
  }
  return (incomplete: incomplete, truncated: current());
}
