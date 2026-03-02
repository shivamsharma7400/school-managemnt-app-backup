import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineClass {
  final String id;
  final String title;
  final String description;
  final String youtubeVideoId;
  final String classId;
  final String teacherName;
  final String teacherId;
  final DateTime startedAt;
  final String status; // 'live', 'ended'

  OnlineClass({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeVideoId,
    required this.classId,
    required this.teacherName,
    required this.teacherId,
    required this.startedAt,
    required this.status,
  });

  factory OnlineClass.fromMap(Map<String, dynamic> data, String documentId) {
    return OnlineClass(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      classId: data['classId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'ended',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'youtubeVideoId': youtubeVideoId,
      'classId': classId,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'startedAt': Timestamp.fromDate(startedAt),
      'status': status,
    };
  }
}
