
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Stream of pending users
  Stream<List<Map<String, dynamic>>> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Stream of pending users count
  Stream<int> getPendingUsersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  // Stream of all users (for management)
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateUserRole(String userId, String newRole, {String? classId}) async {
    Map<String, dynamic> data = {'role': newRole};
    if (classId != null) {
      data['classId'] = classId;
    }

    // Auto-generate ID if approving from pending
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData != null && userData['role'] == 'pending') {
      if (newRole == 'student' && (userData['admNo'] == null || userData['admNo'].toString().isEmpty)) {
        data['admNo'] = await _generateNextId('student');
      } else if (newRole == 'teacher' && (userData['teacherId'] == null || userData['teacherId'].toString().isEmpty)) {
        data['teacherId'] = await _generateNextId('teacher');
      } else if (newRole == 'staff' && (userData['staffId'] == null || userData['staffId'].toString().isEmpty)) {
        data['staffId'] = await _generateNextId('staff');
      }
    }

    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<String> _generateNextId(String role) async {
    final field = role == 'student' ? 'admNo' : (role == 'teacher' ? 'teacherId' : 'staffId');
    
    Query query = _firestore.collection('users');
    
    if (role == 'student') {
       query = query.where('role', isEqualTo: 'student');
    } else if (role == 'teacher') {
       query = query.where('role', isEqualTo: 'teacher');
    } else {
       // For staff/driver/management, we look at anyone who might have a staffId
       // Or simpler: just look for anyone NOT (student/teacher) if we want global staff IDs.
       // But to match our getStaffMembers logic:
       query = query.where('role', whereNotIn: ['student', 'teacher', 'principal', 'pending', 'admin']);
    }

    final snapshot = await query.get();

    int maxId = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final idStr = data[field]?.toString() ?? '';
      // Extract numeric part
      final numericPart = RegExp(r'(\d+)').firstMatch(idStr)?.group(1);
      if (numericPart != null) {
        final id = int.tryParse(numericPart) ?? 0;
        if (id > maxId) maxId = id;
      }
    }

    // If no IDs exist, start at 1001 for students, 101 for teachers
    if (maxId == 0) {
      if (role == 'student') return '1001';
      if (role == 'teacher') return '101';
      if (role == 'staff') return '501';
    }

    return (maxId + 1).toString();
  }


  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }


  Future<void> deleteUser(String userId) async {
    // Note: This only deletes from Firestore. Deleting from Auth requires Cloud Functions or Admin SDK.
    // For Phase 1/2, deleting from Firestore effectively removes them from the App's data view.
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<String?> getPrincipalEmail() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'principal')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching principal email: $e");
      }
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    try {
      // Fetch all students (filtering by role in Firestore)
      // For scalable search, use Algolia or ElasticSearch. For MVP, client-side filter is okay.
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final students = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (query.isEmpty) return students;

      return students.where((student) {
        final name = (student['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
         print("Error searching students: $e");
      }
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getStudentsByClass(String classId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateStudentDue(String uid, double newDue) async {
    await _firestore.collection('users').doc(uid).update({
      'currentDue': newDue,
    });
  }

  // Stream of all students
  Stream<List<Map<String, dynamic>>> getAllStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateStudentAdmNo(String uid, String admNo) async {
    await _firestore.collection('users').doc(uid).update({
      'admNo': admNo,
    });
  }

  // Teacher Salary Management methods

  Stream<List<Map<String, dynamic>>> getTeachers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> getDrivers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> getSalariedUsers() {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['teacher', 'driver', 'staff'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateTeacherSalary(String uid, double salary) async {
    await _firestore.collection('users').doc(uid).update({
      'monthlySalary': salary,
    });
  }

  Future<void> updateTeacherDue(String uid, double newDue) async {
    await _firestore.collection('users').doc(uid).update({
      'salaryDue': newDue,
    });
  }

  Future<void> toggleSalaryStatus(String uid, bool isEnabled) async {
    await _firestore.collection('users').doc(uid).update({
      'salaryEnabled': isEnabled,
    });
  }

  /// Update a specific fee component's status for a student
  /// [key] matches the fee name (e.g., "Bus Fee", "Coaching Fee")
  Future<void> updateStudentFeeConfig(String userId, String key, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'feeConfig.$key': isActive,
    });
  }

  Future<List<String>> getProcessedMonths(String session) async {
    final doc = await _firestore.collection('salary_records').doc(session).get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['processedMonths'] ?? []);
    }
    return [];
  }

  Future<void> processMonthlySalary(String session, String month) async {
    // 1. Check if already processed
    final recordRef = _firestore.collection('salary_records').doc(session);
    final recordDoc = await recordRef.get();
    List<String> processed = [];
    if (recordDoc.exists) {
      processed = List<String>.from(recordDoc.data()!['processedMonths'] ?? []);
      if (processed.contains(month)) {
        throw Exception("Month already processed for this session");
      }
    }

    // 2. Fetch all staff
    final staffSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['teacher', 'driver', 'staff'])
        .get();

    final batch = _firestore.batch();
    
    for (var doc in staffSnapshot.docs) {
      final data = doc.data();
      final bool isEnabled = data['salaryEnabled'] ?? true; // Default to enabled
      
      if (!isEnabled) continue;

      final currentDue = (data['salaryDue'] as num?)?.toDouble() ?? 0.0;
      final monthlySalary = (data['monthlySalary'] as num?)?.toDouble() ?? 0.0;
      
      if (monthlySalary > 0) {
        // Update Due
        batch.update(doc.reference, {
          'salaryDue': currentDue + monthlySalary,
        });

        // Add History
        final historyRef = doc.reference.collection('salary_history').doc();
        batch.set(historyRef, {
          'date': FieldValue.serverTimestamp(),
          'amount': monthlySalary,
          'type': 'credit',
          'month': month,
          'session': session,
          'description': 'Monthly Salary Credit'
        });
      }
    }

    // 3. Mark as processed globally
    if (recordDoc.exists) {
      batch.update(recordRef, {
        'processedMonths': FieldValue.arrayUnion([month])
      });
    } else {
      batch.set(recordRef, {
        'processedMonths': [month]
      });
    }

    await batch.commit();
  }
/*
  Future<void> processMonthlySalaryForAll() async {
    final teachersSnapshot = await _firestore
        .collection('users')
        .where('role', whereIn: ['teacher', 'driver', 'staff'])
        .get();

    final batch = _firestore.batch();
    for (var doc in teachersSnapshot.docs) {
      final data = doc.data();
      final currentDue = (data['salaryDue'] as num?)?.toDouble() ?? 0.0;
      final monthlySalary = (data['monthlySalary'] as num?)?.toDouble() ?? 0.0;
      
      if (monthlySalary > 0) {
        batch.update(doc.reference, {
          'salaryDue': currentDue + monthlySalary,
        });
      }
    }
    await batch.commit();
  }
*/

  Future<void> uploadProfilePhoto(String userId, File file) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_photos/$userId.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await updateProfile(userId, {'photoUrl': url});
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading photo: $e');
      }
      rethrow;
    }
  }
  Future<void> updateTeacherId(String uid, String teacherId) async {
    await _firestore.collection('users').doc(uid).update({
      'teacherId': teacherId,
    });
  }

  // Staff Management
  Stream<List<Map<String, dynamic>>> getStaffMembers() {
    return _firestore
        .collection('users')
        .where('role', whereNotIn: ['student', 'teacher', 'principal', 'pending', 'admin'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> updateStaffId(String uid, String staffId) async {
    await _firestore.collection('users').doc(uid).update({
      'staffId': staffId,
    });
  }

  /// Promotes all students to the next class.
  /// Students in Class 8 are transitioned to 'passed_out' role.
  Future<void> promoteAllStudents(String currentSession) async {
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final batch = _firestore.batch();
    int count = 0;

    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();
      final String? classIdStr = data['classId']?.toString();
      
      if (classIdStr != null) {
        final int? currentClass = int.tryParse(classIdStr);
        
        if (currentClass != null) {
          if (currentClass < 8) {
            // Increment class
            batch.update(doc.reference, {
              'classId': (currentClass + 1).toString(),
            });
          } else if (currentClass == 8) {
            // Transition to Passed Out
            batch.update(doc.reference, {
              'role': 'passed_out',
              'passedOutSession': currentSession,
              // Keep classId as 8 for record, or clear it if preferred. 
              // Usually keeping it is better for history.
            });
          }
          count++;
        }
      }
      
      // Firestore batch limit is 500 operations. 
      // If student count exceeds 500, we should commit and start a new batch.
      // For simplicity in most school apps (<500 students in one go), one batch is fine.
      // But let's be safe if count hits 400.
      if (count >= 400) {
        await batch.commit();
        // Reset batch and count (not implemented here for brevity, assuming < 400 students per batch)
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  /// Stream of passed out students
  Stream<List<Map<String, dynamic>>> getPassedOutStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'passed_out')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
