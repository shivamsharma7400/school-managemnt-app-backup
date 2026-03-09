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
          'paymentMethod': 'Online', // Default for legacy/automatic
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

  /// Process a general payment (e.g. paying off current due) without a specific fee record
  /// Process a general payment (e.g. paying off current due) without a specific fee record
  Future<void> processGeneralPayment({
    required String userId,
    required String studentName,
    required String classId,
    required double amount,
    String paymentMethod = 'Cash',
  }) async {
    try {
      // 1. Fetch current due and monthly charge to calculate split
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final double totalDue = (userData?['currentDue'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate derived monthly total for this user 
      // (This requires fetching class info, which is expensive, so for now we estimate or pass it in.
      // Better: Store 'lastMonthTotal' in user doc. For now, simplifed priority logic:
      // We assume anything > 'this month total' is previous due.
      // But since we don't have 'this month total' easily here without fetching class, 
      // we'll fetch class securely.)
      
      double monthlyTotal = 0.0;
      if (classId != 'Unknown') {
         final classDoc = await _firestore.collection('classes').doc(classId).get();
         if (classDoc.exists) {
            final classData = classDoc.data()!;
            final feeConfig = userData?['feeConfig'] as Map<String, dynamic>? ?? {};
            
            final double coachingFee = (classData['coachingFee'] as num?)?.toDouble() ?? 0.0;
            final double busFee = (classData['busFee'] as num?)?.toDouble() ?? 0.0;
            final double hostelFee = (classData['hostelFee'] as num?)?.toDouble() ?? 0.0;

            if (feeConfig['Coaching Fee'] != false) monthlyTotal += coachingFee;
            if (feeConfig['Bus Fee'] != false) monthlyTotal += busFee;
            if (feeConfig['Hostel Fee'] != false) monthlyTotal += hostelFee;
            
             if (classData['otherFees'] != null) {
              (classData['otherFees'] as Map<String, dynamic>).forEach((k, v) {
                if (feeConfig[k] != false) monthlyTotal += (v as num).toDouble();
              });
            }
         }
      }

      // Logic: 
      // If totalDue > monthlyTotal, then (totalDue - monthlyTotal) is likely previous arrears.
      // We prioritize clearing previous arrears.
      
      String description = 'Fee Payment';
      double previousDue = (totalDue - monthlyTotal).clamp(0, double.infinity);
      
      if (previousDue > 0) {
        double paidToPrevious = 0;
        double paidToCurrent = 0;

        if (amount <= previousDue) {
          paidToPrevious = amount;
        } else {
          paidToPrevious = previousDue;
          paidToCurrent = amount - previousDue;
        }
        
        description = 'Paid: ₹${amount.toInt()} (Prev: ₹${paidToPrevious.toInt()}, Curr: ₹${paidToCurrent.toInt()})';
      } else {
        description = 'Paid: ₹${amount.toInt()} (Current Month)';
      }

      // 2. Log Transaction
      await _firestore.collection('transactions').add({
        'userId': userId,
        'studentName': studentName,
        'classId': classId,
        'amount': amount,
        'type': 'Fee Payment',
        'paymentMethod': paymentMethod,
        'description': description, // Detailed breakdown
        'feesRecordId': null, 
        'date': FieldValue.serverTimestamp(),
      });

      // 3. Auto-deduct from User's Current Due
      await _firestore.collection('users').doc(userId).update({
        'currentDue': FieldValue.increment(-amount),
      });

      notifyListeners();
    } catch (e) {
      print('Error processing general payment: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllTransactions() {
    return _firestore.collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserTransactions(String userId) {
    return _firestore.collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final docs = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          // Sort in-memory to avoid Firebase Index requirement
          docs.sort((a, b) {
            final dateA = (a['date'] as dynamic)?.toDate() ?? DateTime(0);
            final dateB = (b['date'] as dynamic)?.toDate() ?? DateTime(0);
            return dateB.compareTo(dateA); // Descending
          });
          return docs;
        });
  }

  /// Get aggregated fee stats
  /// Collected: Sum of 'Fee Payment' transactions in this month
  /// Pending: Sum of 'currentDue' of all students (Total Outstanding)
  /// Expected: Collected + Pending (Total value handled)
  /// Get aggregated fee stats
  /// Expected: Sum of total monthly fees for all active students (Projected Revenue based on config)
  /// Pending: Sum of 'currentDue' for all students
  /// Collected: Expected - Pending (As per user request)
  Future<Map<String, double>> getMonthFeeStats(String monthYear) async {
    try {
      double expected = 0;
      double pending = 0;
      double totalGlobalDue = 0; // Total debt of the school (all students)

      // 1. Fetch all classes to get fee structures
      final classesSnapshot = await _firestore.collection('classes').get();
      Map<String, Map<String, dynamic>> classFees = {};
      for (var doc in classesSnapshot.docs) {
        classFees[doc.id] = doc.data();
      }

      // 2. Fetch all students and bus destinations
      final busSnapshot = await _firestore.collection('bus_destinations').get();
      Map<String, double> stopFees = {};
      for (var doc in busSnapshot.docs) {
        stopFees[doc.id] = (doc.data()['fee'] as num?)?.toDouble() ?? 0.0;
      }

      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // 3. Iterate students to calculate Expected and Pending
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final double currentDue = (data['currentDue'] as num?)?.toDouble() ?? 0.0;
        
        // Accumulate global due
        totalGlobalDue += currentDue;
        
        // --- Calculate Expected (Monthly Projected) ---
        final classId = data['classId'];
        if (classId != null && classFees.containsKey(classId)) {
           final classData = classFees[classId]!;
           final feeConfig = data['feeConfig'] as Map<String, dynamic>? ?? {};
           
           double studentExpected = 0.0;
           
           // Base fees
           final double coachingFee = (classData['coachingFee'] as num?)?.toDouble() ?? 0.0;
           final String? busStopId = data['busStopId']?.toString();
           final double busFee = (busStopId != null && stopFees.containsKey(busStopId)) 
               ? stopFees[busStopId]! 
               : (classData['busFee'] as num?)?.toDouble() ?? 0.0;
           final double hostelFee = (classData['hostelFee'] as num?)?.toDouble() ?? 0.0;

           if (feeConfig['Coaching Fee'] != false) studentExpected += coachingFee;
           if (feeConfig['Bus Fee'] != false) studentExpected += busFee;
           if (feeConfig['Hostel Fee'] != false) studentExpected += hostelFee;

           // Other fees
           if (classData['otherFees'] != null) {
              (classData['otherFees'] as Map<String, dynamic>).forEach((k, v) {
                 if (feeConfig[k] != false) {
                   studentExpected += (v as num).toDouble();
                 }
              });
           }
           
           expected += studentExpected;

           // --- Calculate Pending (This Month Only) ---
           // Pending for this month is the monthly fee, unless the total current due is less than that (meaning partial payment)
           if (currentDue > 0) {
             final double thisMonthPending = (currentDue < studentExpected) ? currentDue : studentExpected;
             pending += thisMonthPending;
           }
        }
      }

      // 4. Derived Collected (As per specific user logic)
      double collected = expected - pending;

      return {
        'expected': expected,
        'collected': collected,
        'pending': pending < 0 ? 0 : pending,
        'totalGlobalDue': totalGlobalDue,
      };
    } catch (e) {
      print('Error getting fee stats: $e');
      return {'expected': 0, 'collected': 0, 'pending': 0};
    }
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
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          // Sort in-memory to avoid Firebase Index requirement
          docs.sort((a, b) {
            final dateA = (a['date'] as dynamic)?.toDate() ?? DateTime(0);
            final dateB = (b['date'] as dynamic)?.toDate() ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
          return docs;
        });
  }

  /// Apply a fine to a student
  Future<void> applyFine({
    required String userId,
    required String studentName,
    required String classId,
    required double amount,
    required String reason,
  }) async {
    try {
      // 1. Log Transaction
      await _firestore.collection('transactions').add({
        'userId': userId,
        'studentName': studentName,
        'classId': classId,
        'amount': amount,
        'type': 'Fine',
        'reason': reason,
        'date': FieldValue.serverTimestamp(),
      });

      // 2. Add to User's Current Due
      await _firestore.collection('users').doc(userId).update({
        'currentDue': FieldValue.increment(amount),
      });

      notifyListeners();
    } catch (e) {
      print('Error applying fine: $e');
      rethrow;
    }
  }

  /// Process monthly fees for an entire class with dynamic component toggles
  Future<void> processMonthlyFeesForClass({
    required String classId,
    required String monthName,
    required double coachingFee,
    required double busFee,
    required double hostelFee,
    required Map<String, double> otherFees,
  }) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();

      final busSnapshot = await _firestore.collection('bus_destinations').get();
      Map<String, double> stopFees = {};
      for (var doc in busSnapshot.docs) {
        stopFees[doc.id] = (doc.data()['fee'] as num?)?.toDouble() ?? 0.0;
      }

      if (studentsSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (var doc in studentsSnapshot.docs) {
        final userId = doc.id;
        final data = doc.data();
        final studentName = data['name'] ?? 'Unknown';
        final feeConfig = data['feeConfig'] as Map<String, dynamic>? ?? {};

        double totalAmount = 0.0;

        // Calculate based on active components (default to true if not set)
        if (feeConfig['Coaching Fee'] != false) totalAmount += coachingFee;
        if (feeConfig['Bus Fee'] != false) {
          final String? busStopId = data['busStopId']?.toString();
          final double studentBusFee = (busStopId != null && stopFees.containsKey(busStopId)) 
              ? stopFees[busStopId]! 
              : busFee;
          totalAmount += studentBusFee;
        }
        if (feeConfig['Hostel Fee'] != false) totalAmount += hostelFee;
        
        otherFees.forEach((key, value) {
          if (feeConfig[key] != false) {
             totalAmount += value;
          }
        });

        if (totalAmount > 0) {
          // 1. Update Student Due
          batch.update(_firestore.collection('users').doc(userId), {
            'currentDue': FieldValue.increment(totalAmount),
          });

          // 2. Log Transaction
          final transRef = _firestore.collection('transactions').doc();
          batch.set(transRef, {
            'userId': userId,
            'studentName': studentName,
            'classId': classId,
            'amount': totalAmount,
            'type': 'Monthly Fee',
            'description': 'Monthly charges for $monthName',
            'date': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      notifyListeners();
    } catch (e) {
      print('Error processing monthly fees: $e');
      rethrow;
    }
  }

  /// Get list of months already processed for fees in a session
  Future<List<String>> getProcessedFeeMonths(String session) async {
    final doc = await _firestore.collection('fee_records').doc(session).get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['processedMonths'] ?? []);
    }
    return [];
  }

  /// Process monthly fees for ALL classes
  Future<void> processMonthlyFeesForAllClasses(String monthName, String session) async {
    // 1. Check if already processed
    final recordRef = _firestore.collection('fee_records').doc(session);
    final recordDoc = await recordRef.get();
    List<String> processed = [];
    if (recordDoc.exists) {
      processed = List<String>.from(recordDoc.data()!['processedMonths'] ?? []);
      if (processed.contains(monthName)) {
        throw Exception("Fees for $monthName have already been processed.");
      }
    }

    try {
      // 2. Fetch all classes
      final classesSnapshot = await _firestore.collection('classes').get();
      
      // 3. Iterate and process for each class
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        final classId = doc.id;
        
        // Extract fee structure
        final double coachingFee = (data['coachingFee'] as num?)?.toDouble() ?? 0.0;
        final double busFee = (data['busFee'] as num?)?.toDouble() ?? 0.0;
        final double hostelFee = (data['hostelFee'] as num?)?.toDouble() ?? 0.0;
        final Map<String, double> otherFees = {};
        if (data['otherFees'] != null) {
          (data['otherFees'] as Map<String, dynamic>).forEach((k, v) {
            otherFees[k] = (v as num).toDouble();
          });
        }

        await processMonthlyFeesForClass(
          classId: classId,
          monthName: monthName,
          coachingFee: coachingFee,
          busFee: busFee,
          hostelFee: hostelFee,
          otherFees: otherFees,
        );
      }

      // 4. Mark as processed globally
      if (recordDoc.exists) {
        await recordRef.update({
          'processedMonths': FieldValue.arrayUnion([monthName])
        });
      } else {
        await recordRef.set({
          'processedMonths': [monthName]
        });
      }

    } catch (e) {
      print('Error processing all classes: $e');
      rethrow;
    }
  }

  /// Get total fee collection for today (Manual/Specific Fee Payments only) as a Stream
  Stream<double> getTodayFeeCollectionStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _firestore.collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final type = data['type']?.toString() ?? '';
            // Match 'Fee Payment' exactly as used in markAttendance/processGeneralPayment
            if (type == 'Fee Payment') {
              total += (data['amount'] as num?)?.toDouble() ?? 0.0;
            }
          }
          return total;
        });
  }

  /// Get total fee collection for today (Manual/Specific Fee Payments only)
  Future<double> getTodayFeeCollection() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final snapshot = await _firestore.collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'Fee Payment') {
          total += (data['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      print('Error calculating today collection: $e');
      return 0.0;
    }
  }
  /// Get list of months already processed for fines in a session
  Future<List<String>> getProcessedFineMonths(String session) async {
    final doc = await _firestore.collection('fee_records').doc(session).get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['processedFineMonths'] ?? []);
    }
    return [];
  }

  /// Apply auto fines to all students with outstanding dues
  Future<void> applyAutoFinesToAllDueStudents({
    required double amount,
    required String monthName,
    required String session,
  }) async {
    // 1. Check if already processed
    final recordRef = _firestore.collection('fee_records').doc(session);
    final recordDoc = await recordRef.get();
    List<String> processed = [];
    if (recordDoc.exists) {
      processed = List<String>.from(recordDoc.data()!['processedFineMonths'] ?? []);
      if (processed.contains(monthName)) {
        throw Exception("Fines for $monthName have already been processed.");
      }
    }

    try {
      // 2. Fetch all students and filter in-memory to avoid composite index requirement
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final dueStudents = studentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final due = (data['currentDue'] as num?)?.toDouble() ?? 0.0;
        return due > 0;
      }).toList();

      if (dueStudents.isEmpty) {
        // Even if no students, mark as processed to avoid repeated checks
        await _markFineProcessed(recordRef, monthName, recordDoc.exists);
        return;
      }

      // 3. Apply via Batch
      final batch = _firestore.batch();
      for (var doc in dueStudents) {
        final userId = doc.id;
        final data = doc.data();
        final studentName = data['name'] ?? 'Unknown';
        final classId = data['classId'] ?? 'Unknown';

        // Update Student Due
        batch.update(_firestore.collection('users').doc(userId), {
          'currentDue': FieldValue.increment(amount),
        });

        // Log Transaction
        final transRef = _firestore.collection('transactions').doc();
        batch.set(transRef, {
          'userId': userId,
          'studentName': studentName,
          'classId': classId,
          'amount': amount,
          'type': 'Fine',
          'reason': 'Monthly Late Fee ($monthName)',
          'date': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // 4. Mark as processed globally
      await _markFineProcessed(recordRef, monthName, recordDoc.exists);

      notifyListeners();
    } catch (e) {
      print('Error applying auto fines: $e');
      rethrow;
    }
  }

  Future<void> _markFineProcessed(DocumentReference ref, String month, bool exists) async {
    if (exists) {
      await ref.update({
        'processedFineMonths': FieldValue.arrayUnion([month])
      });
    } else {
      await ref.set({
        'processedFineMonths': [month]
      });
    }
  }
}
