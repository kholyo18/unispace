class ExamModel {
  const ExamModel({
    required this.id,
    required this.subject,
    required this.dateTime,
    this.note,
    this.room,
    this.remindersEnabled = false,
    this.reminderOffsets = const [1440, 120, 30],
  });

  final String id;
  final String subject;
  final DateTime dateTime;
  final String? note;
  final String? room;
  final bool remindersEnabled;
  final List<int> reminderOffsets;

  ExamModel copyWith({
    String? id,
    String? subject,
    DateTime? dateTime,
    String? note,
    String? room,
    bool? remindersEnabled,
    List<int>? reminderOffsets,
  }) {
    return ExamModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      room: room ?? this.room,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'dateTime': dateTime.toIso8601String(),
      'note': note,
      'room': room,
      'remindersEnabled': remindersEnabled,
      'reminderOffsets': reminderOffsets,
    };
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      note: json['note'] as String?,
      room: json['room'] as String?,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      reminderOffsets: (json['reminderOffsets'] as List<dynamic>?)
              ?.map((item) => item as int)
              .toList() ??
          const [1440, 120, 30],
    );
  }
}
