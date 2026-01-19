class ExamResult {
  final String id;
  final String studentId;
  final String examName;
  final List<Map<String, dynamic>> subjects; // List of { 'subject': String, 'obtained': double, 'full': double }
  final double totalObtainedMarks;
  final double totalFullMarks;
  final String rollNumber;
  final String grade;

  ExamResult({
    required this.id,
    required this.studentId,
    required this.examName,
    required this.subjects,
    required this.totalObtainedMarks,
    required this.totalFullMarks,
    required this.rollNumber,
    required this.grade,
  });

  factory ExamResult.fromFirestore(Map<String, dynamic> data, String id) {
    return ExamResult(
      id: id,
      studentId: data['studentId'] ?? '',
      examName: data['examName'] ?? '',
      subjects: List<Map<String, dynamic>>.from(data['subjects'] ?? []),
      totalObtainedMarks: (data['totalObtainedMarks'] as num?)?.toDouble() ?? 0.0,
      totalFullMarks: (data['totalFullMarks'] as num?)?.toDouble() ?? 0.0,
      rollNumber: data['rollNumber'] ?? '',
      grade: data['grade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'examName': examName,
      'subjects': subjects,
      'totalObtainedMarks': totalObtainedMarks,
      'totalFullMarks': totalFullMarks,
      'rollNumber': rollNumber,
      'grade': grade,
    };
  }
}
