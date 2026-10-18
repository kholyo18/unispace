import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A personal reminder on this device; never rewinds shared read receipts.
class ChatUnreadReminders extends ChangeNotifier {
  ChatUnreadReminders({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;
  static final instance = ChatUnreadReminders();
  final Future<SharedPreferences> Function() _preferences;
  final Map<String, Set<String>> _values = {};
  Future<void> _pending = Future.value();
  String _key(String uid) => 'chat.unread.reminders.v1.${Uri.encodeComponent(uid)}';
  bool contains(String uid, String chatId) => _values[uid]?.contains(chatId) ?? false;
  Future<void> load(String uid) async {
    if (uid.isEmpty || _values.containsKey(uid)) return;
    final prefs = await _preferences();
    _values.putIfAbsent(uid, () => (prefs.getStringList(_key(uid)) ?? []).toSet());
    notifyListeners();
  }
  Future<void> set(String uid, String chatId, bool value) {
    if (uid.isEmpty || chatId.isEmpty) return Future.value();
    final operation = _pending.then((_) async {
      await load(uid);
      final next = {..._values[uid]!};
      value ? next.add(chatId) : next.remove(chatId);
      final prefs = await _preferences();
      if (!await prefs.setStringList(_key(uid), next.toList())) {
        throw StateError('Unable to save reminder');
      }
      _values[uid] = next;
      notifyListeners();
    });
    _pending = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}
