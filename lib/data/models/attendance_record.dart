import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String classId;
  final DateTime date;
  final Map<String, String> attendance; // studentId : status (present, absent, leave)
  final String? markedBy;
  final String? markedByName;

  AttendanceRecord({
    required this.id,
    required this.classId,
    required this.date,
    required this.attendance,
    this.markedBy,
    this.markedByName,
  });

  factory AttendanceRecord.fromJson(Map json, [String? id]) {
    return AttendanceRecord(
      id: id ?? json['id'] ?? '',
      classId: json['classId'] ?? '',
      date: (json['date'] is Timestamp) 
          ? (json['date'] as Timestamp).toDate() 
          : DateTime.now(),
      attendance: (json['records'] as Map?)?.map<String, String>(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ?? <String, String>{},
      markedBy: json['markedBy'],
      markedByName: json['markedByName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'date': Timestamp.fromDate(date),
      'records': attendance,
      'markedBy': markedBy,
      'markedByName': markedByName,
    };
  }
}
