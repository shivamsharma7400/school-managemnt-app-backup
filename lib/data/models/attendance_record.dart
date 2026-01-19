
class AttendanceRecord {
  final String id;
  final String classId;
  final DateTime date;
  final Map<String, String> attendance; // studentId : status (present, absent, leave)

  AttendanceRecord({
    required this.id,
    required this.classId,
    required this.date,
    required this.attendance,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      classId: json['classId'],
      date: DateTime.parse(json['date']),
      attendance: Map<String, String>.from(json['attendance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'date': date.toIso8601String(),
      'attendance': attendance,
    };
  }
}
