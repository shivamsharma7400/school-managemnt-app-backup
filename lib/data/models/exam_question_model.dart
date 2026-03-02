import 'package:cloud_firestore/cloud_firestore.dart';

class ExamQuestionPaper {
  final String id;
  final String examId; // Link to ScheduledExam
  final String schoolName;
  final String examName;
  final String address;
  final String session;
  final String className;
  final String subject;
  final DateTime date;
  final String timeLimit;
  final int fullMarks;
  final List<QuestionSection> sections;
  final DateTime createdAt;

  ExamQuestionPaper({
    required this.id,
    required this.examId,
    required this.schoolName,
    required this.address,
    required this.examName,
    required this.session,
    required this.className,
    required this.subject,
    required this.date,
    required this.timeLimit,
    required this.fullMarks,
    required this.sections,
    required this.createdAt,
  });

  factory ExamQuestionPaper.fromFirestore(Map<String, dynamic> data, String id) {
    return ExamQuestionPaper(
      id: id,
      examId: data['examId'] ?? '',
      schoolName: data['schoolName'] ?? '',
      address: data['address'] ?? '',
      examName: data['examName'] ?? '',
      session: data['session'] ?? '',
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      date: data['date'] is Timestamp 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.now(),
      timeLimit: data['timeLimit']?.toString() ?? '',
      fullMarks: int.tryParse(data['fullMarks']?.toString() ?? '') ?? 0,
      sections: _parseSections(data['sections']),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  static List<QuestionSection> _parseSections(dynamic sectionsData) {
    if (sectionsData == null) return [];
    try {
      if (sectionsData is Iterable) {
        return sectionsData.map((s) {
          if (s is Map) {
             return QuestionSection.fromMap(Map<String, dynamic>.from(s));
          }
          return QuestionSection.fromMap({});
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing sections: $e');
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'schoolName': schoolName,
      'address': address,
      'examName': examName,
      'session': session,
      'className': className,
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'timeLimit': timeLimit,
      'fullMarks': fullMarks,
      'sections': sections.map((s) => s.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class QuestionSection {
  final String title;
  final String marksLabel; // e.g., [10 x 1 = 10]
  final List<QuestionItem> items;

  QuestionSection({
    required this.title,
    required this.marksLabel,
    required this.items,
  });

  factory QuestionSection.fromMap(Map<String, dynamic> data) {
    return QuestionSection(
      title: data['title']?.toString() ?? '',
      marksLabel: data['marksLabel']?.toString() ?? '',
      items: _parseItems(data['items']),
    );
  }

  static List<QuestionItem> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    try {
      if (itemsData is Iterable) {
        return itemsData.map((i) {
          if (i is Map) {
             return QuestionItem.fromMap(Map<String, dynamic>.from(i));
          }
          return QuestionItem.fromMap({});
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing items: $e');
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'marksLabel': marksLabel,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}

class QuestionItem {
  final String questionText;
  final String? marks; // Individual marks if applicable e.g., [4]
  final List<String> subQuestions;

  QuestionItem({
    required this.questionText,
    this.marks,
    this.subQuestions = const [],
  });

  factory QuestionItem.fromMap(Map<String, dynamic> data) {
    return QuestionItem(
      questionText: data['questionText']?.toString() ?? '',
      marks: data['marks']?.toString(),
      subQuestions: _parseSubQuestions(data['subQuestions']),
    );
  }

  static List<String> _parseSubQuestions(dynamic subQData) {
    if (subQData == null) return [];
    try {
      if (subQData is Iterable) {
        return subQData.map((sq) => sq.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing subQuestions: $e');
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'marks': marks,
      'subQuestions': subQuestions,
    };
  }
}
