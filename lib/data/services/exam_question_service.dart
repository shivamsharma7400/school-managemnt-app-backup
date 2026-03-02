import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_question_model.dart';

class ExamQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'exam_questions';

  Stream<List<ExamQuestionPaper>> getQuestionPapers(String examId, {String? className}) {
    var query = _firestore
        .collection(_collection)
        .where('examId', isEqualTo: examId);
        
    if (className != null) {
      query = query.where('className', isEqualTo: className);
    }
    
    return query
        .snapshots()
        .map((snapshot) {
          final papers = snapshot.docs
            .map((doc) => ExamQuestionPaper.fromFirestore(doc.data(), doc.id))
            .toList();
          // Sort in-memory to avoid index requirements
          papers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return papers;
        });
  }

  Future<void> saveQuestionPaper(ExamQuestionPaper paper) async {
    if (paper.id.isEmpty) {
      await _firestore.collection(_collection).add(paper.toMap());
    } else {
      await _firestore.collection(_collection).doc(paper.id).update(paper.toMap());
    }
  }

  Future<void> deleteQuestionPaper(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<ExamQuestionPaper?> getQuestionPaperById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return ExamQuestionPaper.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }
}
