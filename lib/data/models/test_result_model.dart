import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  final String id;
  final String testId;
  final String testTitle;
  final String studentId;
  final String studentName;
  final int score;
  final int totalQuestions;
  final DateTime submittedAt;

  TestResult({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.submittedAt,
  });

  factory TestResult.fromMap(Map<String, dynamic> data, String documentId) {
    return TestResult(
      id: documentId,
      testId: data['testId'] ?? '',
      testTitle: data['testTitle'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'testTitle': testTitle,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'totalQuestions': totalQuestions,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
