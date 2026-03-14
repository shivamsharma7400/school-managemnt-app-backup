import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintService {
  final CollectionReference _complaintsCollection =
      FirebaseFirestore.instance.collection('complaints');

  // Submit a new complaint
  Future<void> submitComplaint(ComplaintModel complaint) async {
    await _complaintsCollection.doc(complaint.id).set(complaint.toMap());
  }


  // Get complaints for a specific user
  Stream<List<ComplaintModel>> getUserComplaints(String userId) {
    return _complaintsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort in memory to avoid Firestore Index requirement
      complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return complaints;
    });
  }

  // Get all pending complaints for Principal
  Stream<List<ComplaintModel>> getPendingComplaints() {
    return _complaintsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort in memory to avoid Firestore Index requirement
      complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return complaints;
    });
  }

  // Get all processed complaints (History)
  Stream<List<ComplaintModel>> getProcessedComplaints() {
    return _complaintsCollection
        .where('status', isNotEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort in memory
      complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return complaints;
    });
  }

  // Get pending complaints count for Principal Dashboard
  Stream<int> getPendingComplaintsCount() {
    return _complaintsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Approve a complaint with a response
  Future<void> approveComplaint(String id, String response) async {
    await _complaintsCollection.doc(id).update({
      'status': 'approved',
      'response': response,
    });
  }

  // Reject a complaint with a reason
  Future<void> rejectComplaint(String id, String reason) async {
    await _complaintsCollection.doc(id).update({
      'status': 'rejected',
      'response': reason,
    });
  }

}
