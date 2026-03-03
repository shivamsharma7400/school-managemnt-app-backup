import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String type; // 'general', 'urgent', 'event'
  final String targetAudience; // 'student', 'teacher', 'all'

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    required this.targetAudience,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'general',
      targetAudience: data['targetAudience'] ?? 'all',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'type': type,
      'targetAudience': targetAudience,
    };
  }
}
