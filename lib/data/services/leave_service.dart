import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/leave_request.dart';

class LeaveService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> applyLeave(LeaveRequest request) async {
    try {
      await _firestore.collection('leaves').add(request.toMap());
      notifyListeners();
    } catch (e) {
      print('Error applying leave: $e');
      rethrow;
    }
  }

  Stream<List<LeaveRequest>> getMyLeaves(String userId) {
    return _firestore
        .collection('leaves')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final leaves = snapshot.docs.map((doc) => LeaveRequest.fromMap(doc.data(), doc.id)).toList();
      leaves.sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
      return leaves;
    });
  }

  Stream<List<LeaveRequest>> getPendingLeaves() {
    return _firestore
        .collection('leaves')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final leaves = snapshot.docs.map((doc) => LeaveRequest.fromMap(doc.data(), doc.id)).toList();
      leaves.sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
      return leaves;
    });
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    try {
      await _firestore.collection('leaves').doc(leaveId).update({'status': status});
      notifyListeners();
    } catch (e) {
      print('Error updating leave status: $e');
      rethrow;
    }
  }
}
