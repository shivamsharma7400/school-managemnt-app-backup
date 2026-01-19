import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/test_model.dart';
import '../models/test_result_model.dart';
import 'auth_service.dart';

class TestService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new test
  Future<void> createTest(Test test) async {
    try {
      await _firestore.collection('tests').add(test.toMap());
      // notifyListeners(); // Not needed for Stream-based UI
    } catch (e) {
      print('Error creating test: $e');
      rethrow;
    }
  }

  // Get tests for a specific class
  Stream<List<Test>> getTestsForClass(String classId) {
    return _firestore
        .collection('tests')
        .where('classId', isEqualTo: classId)
        // .orderBy('createdAt', descending: true) // Removed to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
      final tests = snapshot.docs.map((doc) => Test.fromMap(doc.data(), doc.id)).toList();
      // Sort client-side
      tests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tests;
    });
  }

  // Submit test result
  Future<void> submitTestResult(TestResult result) async {
    try {
      await _firestore.collection('test_results').add(result.toMap());
      // notifyListeners(); // Not needed
    } catch (e) {
      print('Error submitting result: $e');
      rethrow;
    }
  }
  
  // Check if student already took the test
  Future<bool> hasStudentTakenTest(String testId, String studentId) async {
     final snapshot = await _firestore.collection('test_results')
         .where('testId', isEqualTo: testId)
         .where('studentId', isEqualTo: studentId)
         .limit(1)
         .get();
     return snapshot.docs.isNotEmpty;
  }
}
