import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fee_record.dart';

class FeeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _feesCollection => _firestore.collection('fees');

  /// Create a new fee record (Principal only)
  Future<void> createFee(FeeRecord fee) async {
    try {
      await _feesCollection.add(fee.toJson());
      notifyListeners();
    } catch (e) {
      print('Error creating fee: $e');
      rethrow;
    }
  }

  /// Get fees for a specific student
  Future<List<FeeRecord>> getFeesForStudent(String userId) async {
    try {
      final snapshot = await _feesCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeeRecord.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching student fees: $e');
      return [];
    }
  }

  /// Get all fees (Principal view)
  /// Note: In a real app with many records, you'd want pagination.
  Future<List<FeeRecord>> getAllFees() async {
    try {
      final snapshot = await _feesCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeeRecord.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching all fees: $e');
      return [];
    }
  }

  /// Update payment amount (Principal only)
  /// Update payment amount (Principal only)
  Future<void> updatePayment(String recordId, double newPaidAmount) async {
    try {
      final docResult = await _feesCollection.doc(recordId).get();
      if (!docResult.exists) throw Exception("Fee record not found");
      
      final data = docResult.data() as Map<String, dynamic>;
      final double oldPaid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final String userId = data['userId'];
      final String studentName = data['studentName'] ?? 'Unknown';
      final String classId = data['classId'] ?? 'Unknown';

      final double paymentDiff = newPaidAmount - oldPaid;

      // 1. Log Transaction if payment increased
      if (paymentDiff > 0) {
        await _firestore.collection('transactions').add({
          'userId': userId,
          'studentName': studentName,
          'classId': classId,
          'amount': paymentDiff,
          'type': 'Fee Payment',
          'feesRecordId': recordId,
          'date': FieldValue.serverTimestamp(),
        });

        // 2. Auto-deduct from User's Current Due
        // Using FieldValue.increment for atomicity. If due is positive, this reduces it.
        await _firestore.collection('users').doc(userId).update({
          'currentDue': FieldValue.increment(-paymentDiff),
        });
      }

      // 3. Update Fee Record
      await _feesCollection.doc(recordId).update({
        'paidAmount': newPaidAmount,
      });
      notifyListeners();
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllTransactions() {
    return _firestore.collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Delete a fee record (Principal only - Optional utility)
  Future<void> deleteFee(String recordId) async {
    try {
      await _feesCollection.doc(recordId).delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting fee: $e');
      rethrow;
    }
  }

  // Extra Charges Management
  Future<void> addExtraCharge(String userId, double amount, String reason) async {
    await _firestore.collection('extra_fees').add({
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'date': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getExtraCharges(String userId) {
    return _firestore
        .collection('extra_fees')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
