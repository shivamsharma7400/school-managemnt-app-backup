import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/online_class_model.dart';

class OnlineClassService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a broadcast (Placeholder for YouTube API integration)
  // simulating adding a "Live" video to Firestore
  Future<void> createBroadcast({
    required String title,
    required String description,
    required String classId,
    required String teacherName,
    required String teacherId,
    required String youtubeVideoId, 
  }) async {
    try {
      await _firestore.collection('online_classes').add({
        'title': title,
        'description': description,
        'classId': classId,
        'teacherName': teacherName,
        'teacherId': teacherId,
        'youtubeVideoId': youtubeVideoId,
        'startedAt': FieldValue.serverTimestamp(),
        'status': 'live',
      });
      notifyListeners();
    } catch (e) {
      print('Error creating broadcast: $e');
      rethrow;
    }
  }

  // Get active classes for a student
  Stream<List<OnlineClass>> getActiveClassesForStudent(String classId) {
    return _firestore
        .collection('online_classes')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'live')
        // .orderBy('startedAt', descending: true) // Removed to avoid composite index
        .snapshots()
        .map((snapshot) {
      final classes = snapshot.docs.map((doc) => OnlineClass.fromMap(doc.data(), doc.id)).toList();
      // Client-side sorting
      classes.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return classes;
    });
  }

  // Get all classes for a student (both active and past)
  Stream<List<OnlineClass>> getAllClassesForStudent(String classId) {
    return _firestore
        .collection('online_classes')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
      final classes = snapshot.docs.map((doc) => OnlineClass.fromMap(doc.data(), doc.id)).toList();
      classes.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return classes;
    });
  }

  // Get history for a teacher
  Stream<List<OnlineClass>> getHistoryForTeacher(String teacherId) {
    return _firestore
        .collection('online_classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final classes = snapshot.docs.map((doc) => OnlineClass.fromMap(doc.data(), doc.id)).toList();
      classes.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return classes;
    });
  }

  // End a class
  Future<void> endClass(String id) async {
    try {
      await _firestore.collection('online_classes').doc(id).update({'status': 'ended'});
      notifyListeners();
    } catch (e) {
      print('Error ending class: $e');
      rethrow;
    }
  }
}
