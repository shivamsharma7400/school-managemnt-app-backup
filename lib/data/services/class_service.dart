import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';

class ClassService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of classes for a specific teacher
  Stream<List<ClassModel>> getClassesForTeacher(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream of all classes (Principal view or generic)
  Stream<List<ClassModel>> getAllClasses() {
    return _firestore
        .collection('classes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create a class (Principal only usually, but helper for us)
  Future<void> createClass(String name, String teacherId) async {
    await _firestore.collection('classes').add({
      'name': name,
      'teacherId': teacherId,
    });
  }
  // Fetch all classes as a one-time future
  Future<List<ClassModel>> fetchAllClasses() async {
    final snapshot = await _firestore.collection('classes').get();
    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateClassFee(String classId, double fee) async {
    await _firestore.collection('classes').doc(classId).update({
      'monthlyFee': fee,
    });
  }
}
