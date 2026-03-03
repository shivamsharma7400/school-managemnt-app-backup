import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_record.dart';

class AttendanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mark attendance for a specific class and date
  Future<void> markAttendance(String classId, DateTime date, Map<String, String> attendanceData, {String? userId, String? userName}) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final recordId = "${classId}_$dateStr";

      await _firestore.collection('attendance').doc(recordId).set({
        'classId': classId,
        'date': Timestamp.fromDate(date),
        'records': attendanceData,
        'markedBy': userId,
        'markedByName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  /// Get stream of detailed attendance records for a given date
  Stream<List<AttendanceRecord>> getMarkedClassDetailsStream(DateTime date) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    return _firestore.collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => AttendanceRecord.fromJson(doc.data(), doc.id)).toList();
        });
  }

  /// Get attendance record for a class on a specific date
  Future<AttendanceRecord?> getAttendance(String classId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final recordId = "${classId}_$dateStr";

      final doc = await _firestore.collection('attendance').doc(recordId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return AttendanceRecord.fromJson(data, doc.id);
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

  /// Get summary of today's attendance across all classes (Stream version)
  Stream<Map<String, int>> getDailyAttendanceSummaryStream(DateTime date) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(Duration(days: 1));

    return _firestore.collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .snapshots()
        .map((snapshot) {
          int present = 0;
          int absent = 0;
          int totalMarked = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final classId = data['classId']?.toString() ?? '';

            if (classId.toUpperCase() == 'TEACHERS' || classId.toUpperCase() == 'DRIVERS') {
              continue;
            }

            final records = (data['records'] as Map?)?.map<String, String>(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ?? <String, String>{};
            totalMarked += records.length;
            records.forEach((_, status) {
              final s = status.toLowerCase();
              if (s == 'p' || s == 'present') present++;
              else if (s == 'a' || s == 'absent') absent++;
            });
          }

          return {
            'present': present,
            'absent': absent,
            'totalMarked': totalMarked,
          };
        });
  }

  /// Get summary of today's attendance across all classes (Future version for AI)
  Future<Map<String, int>> getDailyAttendanceSummaryFuture(DateTime date) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(Duration(days: 1));

      final snapshot = await _firestore.collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .get();

      int present = 0;
      int absent = 0;
      int totalMarked = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final classId = data['classId']?.toString() ?? '';

        if (classId.toUpperCase() == 'TEACHERS' || classId.toUpperCase() == 'DRIVERS') {
          continue;
        }

        final records = (data['records'] as Map?)?.map<String, String>(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ?? <String, String>{};
        totalMarked += records.length;
        records.forEach((_, status) {
          final s = status.toLowerCase();
          if (s == 'p' || s == 'present') present++;
          else if (s == 'a' || s == 'absent') absent++;
        });
      }

      return {
        'present': present,
        'absent': absent,
        'totalMarked': totalMarked,
      };
    } catch (e) {
      print('Error getting attendance summary: $e');
      return {'present': 0, 'absent': 0, 'totalMarked': 0};
    }
  }

  /// Get list of present IDs for a date (Students and Staff)
  Future<List<String>> getPresentIds(DateTime date) async {
    try {
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final snapshot = await _firestore.collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
          .where('date', isLessThan: Timestamp.fromDate(dateEnd))
          .get();

      List<String> presentIds = [];
      for (var doc in snapshot.docs) {
        final records = (doc.data()['records'] as Map?)?.map<String, String>(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ?? <String, String>{};
        records.forEach((id, status) {
          final s = status.toLowerCase();
          if (s == 'p' || s == 'present') {
            presentIds.add(id);
          }
        });
      }
      return presentIds;
    } catch (e) {
      print('Error getting present IDs: $e');
      return [];
    }
  }

  /// Get stream of class IDs that have marked attendance for a given date
  Stream<List<String>> getMarkedClassIdsStream(DateTime date) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    return _firestore.collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThan: Timestamp.fromDate(dateEnd))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()['classId'] as String).toList();
        });
  }
}
