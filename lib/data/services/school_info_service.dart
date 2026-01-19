import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SchoolInfoService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'school_settings';
  static const String _docId = 'info';

  Future<void> updateSchoolInfo(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(_docId).set(data, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      print('Error updating school info: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getSchoolInfoStream() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((doc) => doc.data());
  }

  Future<Map<String, dynamic>?> getSchoolInfo() async {
    final doc = await _firestore.collection(_collection).doc(_docId).get();
    return doc.data();
  }
}
