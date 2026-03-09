import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';
import '../../core/constants/app_constants.dart';

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
            .where((c) => AppConstants.schoolClasses.contains(c.name))
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
        .where((c) => AppConstants.schoolClasses.contains(c.name))
        .toList();
  }

  Future<void> updateClassFee(String classId, double fee) async {
    await _firestore.collection('classes').doc(classId).update({
      'monthlyFee': fee,
    });
  }

  Future<void> updateClassFees({
    required String classId,
    double? coachingFee,
    double? busFee,
    double? hostelFee,
    double? milkFee,
    double? monthlyFee,
    Map<String, double>? otherFees,
  }) async {
    final Map<String, dynamic> data = {};
    if (coachingFee != null) data['coachingFee'] = coachingFee;
    if (busFee != null) data['busFee'] = busFee;
    if (hostelFee != null) data['hostelFee'] = hostelFee;
    if (milkFee != null) data['milkFee'] = milkFee;
    if (monthlyFee != null) data['monthlyFee'] = monthlyFee;
    if (otherFees != null) data['otherFees'] = otherFees;
    if (data.isNotEmpty) {
      await _firestore.collection('classes').doc(classId).update(data);
    }
  }

  Future<void> assignClassTeacher(String classId, String teacherId) async {
    // 1. Clear this teacher from any other class they might be assigned to (ensure 1:1)
    final existingClasses = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in existingClasses.docs) {
      if (doc.id != classId) {
        batch.update(doc.reference, {'teacherId': ''});
      }
    }

    // 2. Assign to new class (or clear if classId is empty)
    if (classId.isNotEmpty) {
      batch.update(_firestore.collection('classes').doc(classId), {'teacherId': teacherId});
    }
    
    await batch.commit();
    notifyListeners();
  }

  Future<void> addCustomColumn(String classId, String columnName) async {
    await _firestore.collection('classes').doc(classId).update({
      'customColumns': FieldValue.arrayUnion([columnName])
    });
    notifyListeners();
  }

  Future<void> removeCustomColumn(String classId, String columnName) async {
    await _firestore.collection('classes').doc(classId).update({
      'customColumns': FieldValue.arrayRemove([columnName])
    });
    notifyListeners();
  }
}
