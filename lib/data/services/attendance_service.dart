import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_record.dart';

class AttendanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mark attendance for a specific class and date
  Future<void> markAttendance(String classId, DateTime date, Map<String, String> attendanceData) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final recordId = "${classId}_$dateStr";

      await _firestore.collection('attendance').doc(recordId).set({
        'classId': classId,
        'date': Timestamp.fromDate(date),
        'records': attendanceData,
      });
      notifyListeners();
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  /// Get attendance record for a class on a specific date
  Future<AttendanceRecord?> getAttendance(String classId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final recordId = "${classId}_$dateStr";

      final doc = await _firestore.collection('attendance').doc(recordId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return AttendanceRecord(
          id: doc.id,
          classId: data['classId'],
          date: (data['date'] as Timestamp).toDate(),
          attendance: Map<String, String>.from(data['records'] ?? {}),
        );
      }
      return null;
    } catch (e) {
      print('Error getting attendance: $e');
      return null;
    }
  }

  /// Get attendance history for a student
  Future<Map<DateTime, String>> getStudentAttendanceHistory(String studentId) async {
    try {
      // Note: This query might be expensive without proper indexing or structure optimization
      // Ideally, store attendance in subcollection of user OR duplicate data.
      // For this Phase, we scan 'attendance' collection where records map contains key.
      // Limitation: Firestore can't easily query inside a Map field's keys.
      // BEST PRACTICE FIX: We will just fetch the last 30 days of attendance for the class(es) the student is in.
      // But we don't know the class easily here without looking up user. 
      // Simplified approach: Query *all* attendance docs? No, too big.
      // Better approach: We should store a separate `student_attendance` collection or subcollection if we want efficient reads.
      // ALTERNATIVE: Use `where('records.$studentId', isNull: false)` IS NOT POSSIBLE in standard queries easily for existence.
      // 
      // REVISED ARCHITECTURE for Phase 5 Speed:
      // We will assume the student needs to see their attendance. 
      // We will fetch all 'attendance' docs (capped limit, e.g., last 30 days) and filter client side. NOT SCALABLE but fine for MVP.
      
      final snapshot = await _firestore.collection('attendance')
          .orderBy('date', descending: true)
          .limit(60) // Last 2 months
          .get();

      Map<DateTime, String> history = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final records = data['records'] as Map<String, dynamic>?;
        if (records != null && records.containsKey(studentId)) {
           final date = (data['date'] as Timestamp).toDate();
           history[date] = records[studentId];
        }
      }
      return history;

    } catch (e) {
      print('Error fetching student attendance: $e');
      return {};
    }
  }
}
