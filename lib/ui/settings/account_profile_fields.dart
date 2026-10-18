import 'package:cloud_firestore/cloud_firestore.dart';

/// Fields shared by signup and the account-information editor.
class AccountProfileFields {
  AccountProfileFields(Map<String, dynamic>? document)
      : _data = document ?? const {};
  final Map<String, dynamic> _data;

  String get username =>
      _data['username'] is String ? (_data['username'] as String).trim() : '';
  String get department => _data['department']?.toString() ?? '';
  String get faculty => _academicField('faculty', 'college');
  String get studyLevel => _academicField('studyLevel', 'level');

  String _academicField(String editorKey, String signupKey) {
    final academic = _data['academic'];
    // An explicitly empty editor value must not resurrect an older value.
    return (_data[editorKey] ??
                _data[signupKey] ??
                (academic is Map ? academic[signupKey] : null))
            ?.toString() ??
        '';
  }

  String get birthDate {
    final raw = _data['birthDate'];
    final DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is DateTime) {
      date = raw;
    } else if (raw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(raw);
    } else {
      // The existing editor already stores yyyy-MM-dd strings.
      return raw is String ? raw : '';
    }
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
