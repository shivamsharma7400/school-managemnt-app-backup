import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StudentQueryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitQuery({
    required String userId,
    required String userName,
    required String query,
    required String aiResponse,
  }) async {
    try {
      await _firestore.collection('student_queries').add({
        'userId': userId,
        'userName': userName,
        'query': query,
        'aiResponse': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'isReviewed': false,
      });
    } catch (e) {
      print('Error submitting query: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingQueries() {
    return _firestore
        .collection('student_queries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> markAsReviewed(String id) async {
    await _firestore.collection('student_queries').doc(id).update({'isReviewed': true});
  }
}
