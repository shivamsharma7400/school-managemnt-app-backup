import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';

class AssignmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _assignmentsCollection => _firestore.collection('assignments');

  // Add new assignment
  Future<void> addAssignment(Assignment assignment) async {
    try {
      await _assignmentsCollection.add(assignment.toJson());
      notifyListeners();
    } catch (e) {
      print('Error adding assignment: $e');
      rethrow;
    }
  }

  // Get assignments for a specific class (Student View)
  Stream<List<Assignment>> getAssignmentsForClass(String classId) {
    // Calculate cutoff date: Today - 3 days
    // We strive to show homework for: Today, Yesterday, DayBeforeYesterday, and 3DaysAgo.
    // So we subtract 3 days from the *start* of today to be inclusive.
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 3));

    return _assignmentsCollection
        .where('classId', isEqualTo: classId)
        .where('assignedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Assignment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get assignments created by a teacher (Teacher View)
  Stream<List<Assignment>> getAssignmentsByTeacher(String teacherId) {
    return _assignmentsCollection
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Assignment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // Delete assignment
  Future<void> deleteAssignment(String id) async {
    try {
      await _assignmentsCollection.doc(id).delete();
      notifyListeners();
    } catch (e) {
       print('Error deleting assignment: $e');
       rethrow;
    }
  }
}
