import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_model.dart';

class ExamStorage {
  static const _storageKey = 'exam_calendar_items';

  Future<List<ExamModel>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ExamModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExams(List<ExamModel> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(exams.map((exam) => exam.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }
}
