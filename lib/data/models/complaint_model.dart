import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'student', 'teacher', 'driver'
  final String subject;
  final String description;
  final String status; // 'pending', 'approved', 'rejected'
  final String? response; // Principal's response
  final DateTime timestamp;
  final String? originalDescription; // Store original if AI rewrote it? Optional but good for history. Let's keep it simple for now and just store description.

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.subject,
    required this.description,
    required this.status,
    this.response,
    required this.timestamp,
    this.originalDescription,
  });

  factory ComplaintModel.fromMap(Map map, String id) {
    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      response: map['response'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      originalDescription: map['originalDescription'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'subject': subject,
      'description': description,
      'status': status,
      'response': response,
      'timestamp': Timestamp.fromDate(timestamp),
      'originalDescription': originalDescription,
    };
  }
}
