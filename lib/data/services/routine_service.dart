
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RoutineService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of routines by type ('class' or 'bus')
  Stream<List<Map<String, dynamic>>> getRoutines(String type) {
    return _firestore
        .collection('routines')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addRoutine(String title, String description, String type, {String? imageUrl}) async {
    await _firestore.collection('routines').add({
      'title': title,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRoutine(String id, String title, String description, {String? imageUrl}) async {
    await _firestore.collection('routines').doc(id).update({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteRoutine(String id) async {
    await _firestore.collection('routines').doc(id).delete();
  }
}
