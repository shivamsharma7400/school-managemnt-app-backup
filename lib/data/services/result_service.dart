import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/result_model.dart';

class ResultService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _resultsCollection => _firestore.collection('results');

  /// Create a new exam result (Principal/Teacher)
  Future<void> addResult(ExamResult result) async {
    try {
      await _resultsCollection.add(result.toJson());
      notifyListeners();
    } catch (e) {
      print('Error adding result: $e');
      rethrow;
    }
  }

  /// Get results for a specific student
  Future<List<ExamResult>> getResultsForStudent(String studentId) async {
    try {
      final snapshot = await _resultsCollection
          .where('studentId', isEqualTo: studentId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExamResult.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching student results: $e');
      return [];
    }
  }

  /// Get all results (Optional: for filtering if needed later)
  Future<List<ExamResult>> getAllResults() async {
     try {
      final snapshot = await _resultsCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExamResult.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching all results: $e');
      return [];
    }
  }
}
