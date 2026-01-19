
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
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
    notifyListeners();
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

  Future<void> processMonthlySalaryForAll() async {
    final teachersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
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
}
