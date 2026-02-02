import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/smart_review_plan.dart';

class SmartReviewStorage {
  static const _storageKey = 'smart_review_plan';

  Future<SmartReviewPlan?> loadPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return SmartReviewPlan.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlan(SmartReviewPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(plan.toJson());
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }

  Future<void> clearPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
