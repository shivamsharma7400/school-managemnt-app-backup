import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if promotion is pending (e.g., it's past March 31st and hasn't been done for this year)
  Future<bool> isPromotionPending() async {
    final now = DateTime.now();
    // Assuming academic year ends March 31st.
    // If today is after March 31st, we check if we have a record for this year's promotion.
    
    // For demo/simplicity, we might strictly check if month is April or later?
    // User requirement: "update ka fix date 31 march hoga" -> "Update fixed date is 31 March".
    // So on or after March 31st.
    
    if (now.month < 3) return false; // Jan, Feb - not yet
    if (now.month == 3 && now.day < 31) return false; // Early March - not yet

    final currentYear = now.year;
    
    // Check a special document in 'system' collection
    final doc = await _firestore.collection('system').doc('promotion_log').get();
    if (!doc.exists) return true; // Never run before

    final lastRunYear = doc.data()?['lastRunYear'];
    if (lastRunYear == null || lastRunYear < currentYear) {
      return true;
    }
    
    return false;
  }

  Future<Map<String, int>> runPromotion() async {
    // Returns stats: {promoted: X, graduated: Y}
    int promotedCount = 0;
    int graduatedCount = 0;

    // Get all students
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final batch = _firestore.batch();
    
    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();
      final currentClassId = data['classId'];
      
      if (currentClassId != null) {
        // Try to parse class
        int? classInt = int.tryParse(currentClassId);
        if (classInt != null) {
          if (classInt < 8) {
            // Promote
            batch.update(doc.reference, {'classId': (classInt + 1).toString()});
            promotedCount++;
          } else {
            // Graduate (Delete user or Archive)
            // User requirement: "user data se automatically remove ho jayega"
            batch.delete(doc.reference);
            graduatedCount++;
          }
        }
      }
    }

    // Mark as run for this year
    batch.set(_firestore.collection('system').doc('promotion_log'), {
      'lastRunYear': DateTime.now().year,
      'lastRunDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return {'promoted': promotedCount, 'graduated': graduatedCount};
  }
}
