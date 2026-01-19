import 'package:cloud_firestore/cloud_firestore.dart';

class Test {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String subject;
  final int durationMinutes;
  final String createdBy;
  final DateTime createdAt;
  final List<Question> questions;

  Test({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.subject,
    required this.durationMinutes,
    required this.createdBy,
    required this.createdAt,
    required this.questions,
  });

  factory Test.fromMap(Map<String, dynamic> data, String documentId) {
    return Test(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      classId: data['classId'] ?? '',
      subject: data['subject'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      questions: (data['questions'] as List<dynamic>)
          .map((q) => Question.fromMap(q))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'classId': classId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class Question {
  final String id;
  final String text;
  final String type; // 'mcq', 'fill_blank'
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      id: data['id'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'mcq',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}
