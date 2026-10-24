import 'package:shared_preferences/shared_preferences.dart';

class AccountSearchHistory {
  static const legacyKey = 'community_recent_searches';
  static String key(String uid) =>
      '${legacyKey}_${Uri.encodeComponent(uid)}';

  static Future<List<String>> load(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    // The previous shared list has no reliable owner and must not be migrated.
    await prefs.remove(legacyKey);
    if (uid == null || uid.isEmpty) return [];
    return prefs.getStringList(key(uid)) ?? [];
  }

  static Future<void> save(String? uid, List<String> searches) async {
    final snapshot = List<String>.of(searches);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyKey);
    if (uid == null || uid.isEmpty) return;
    await prefs.setStringList(key(uid), snapshot.take(10).toList());
  }
}
