import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId; // e.g., "10-A"
  final DateTime dueDate;
  final DateTime assignedDate;
  final String teacherId;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.classId,
    required this.dueDate,
    required this.assignedDate,
    required this.teacherId,
  });

  factory Assignment.fromFirestore(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      classId: data['classId'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedDate: (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      teacherId: data['teacherId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'classId': classId,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedDate': Timestamp.fromDate(assignedDate),
      'teacherId': teacherId,
    };
  }
}
