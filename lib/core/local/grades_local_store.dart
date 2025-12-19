import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GradesLocalStore {
  static const String _storageKey = 'unispace_grades_v1';

  String _entryKey(String semester, String moduleId) {
    return '$semester|$moduleId';
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<Map<String, double?>?> loadGrade(
    String semester,
    String moduleId,
  ) async {
    final all = await _loadAll();
    final entry = all[_entryKey(semester, moduleId)];
    if (entry is! Map) {
      return null;
    }
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return <String, double?>{
      'td': toDouble(entry['td']),
      'exam': toDouble(entry['exam']),
      'tp': toDouble(entry['tp']),
      'moy': toDouble(entry['moy']),
    };
  }

  Future<void> saveGrade(
    String semester,
    String moduleId,
    double? td,
    double? exam,
    double? tp,
    double? moy,
  ) async {
    final all = await _loadAll();
    final hasValues = td != null || exam != null || tp != null || moy != null;
    final key = _entryKey(semester, moduleId);
    if (!hasValues) {
      all.remove(key);
      await _saveAll(all);
      return;
    }
    all[key] = <String, double?>{
      'td': td,
      'exam': exam,
      'tp': tp,
      'moy': moy,
    };
    await _saveAll(all);
  }

  Future<void> clearGrade(String semester, String moduleId) async {
    final all = await _loadAll();
    all.remove(_entryKey(semester, moduleId));
    await _saveAll(all);
  }
}
