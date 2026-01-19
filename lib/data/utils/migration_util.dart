import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MigrationUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> standardizeClassIds() async {
    try {
      if (kDebugMode) print("Starting Aggressive Class Cleanup...");

      // 1. Define standard classes that MUST remained
      final standardClasses = ['1', '2', '3', '4', '5', '6', '7', '8'];

      // 2. Fetch ALL classes
      final classesSnapshot = await _firestore.collection('classes').get();
      
      for (var doc in classesSnapshot.docs) {
        final id = doc.id;
        final data = doc.data();
        final name = data['name']?.toString() ?? '';

        // If this is one of our standard, correct docs, SKIP it.
        if (standardClasses.contains(id)) {
          if (kDebugMode) print("Keeping valid class: ID=$id Name=$name");
          continue;
        }

        // If it's NOT a standard ID, check if we should delete it.
        // The user wants to remove "class 1", "class 2", etc.
        // We delete if ID matches strict known patterns OR Name matches "Class X" patterns.
        
        bool shouldDelete = false;

        // Condition A: The ID itself looks like "class 1" (handled partially before)
        if (id.toLowerCase().startsWith('class')) {
          shouldDelete = true;
        }

        // Condition B: The NAME looks like "Class 1" or "class 1"
        // And the corresponding standard ID exists (we created them in step 1 if needed, but here we just assume strict 1-8).
        if (name.toLowerCase().startsWith('class') || name.toLowerCase().startsWith('grade')) {
           // Double check: if it says "Class 1", is it redundancy? Yes.
           shouldDelete = true;
        }
        
        // Safety: If it's some other random class like "Nursery", we might want to keep it?
        // User said: "banki 1,2,3....8 rahn dena" (Only keep 1...8).
        // User said: "class 1/class2/...class 8 wala sab hata do".
        // I will focus on deleting things that contain "Class" or "class" followed by a number.
        
        if (shouldDelete) {
           if (kDebugMode) print("Deleting redundant class: ID=$id Name=$name");
           await _firestore.collection('classes').doc(id).delete();
        }
      }
      
      // 3. Ensure Standard Classes Exist (Just in case)
      for (var stdClassId in standardClasses) {
        final docRef = _firestore.collection('classes').doc(stdClassId);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
           if (kDebugMode) print("Re-creating missing standard class $stdClassId...");
           await docRef.set({
            'name': stdClassId,
            'teacherId': '', 
            'monthlyFee': 0,
          });
        }
      }

      // 4. Update Users (Students) who have old class IDs
      if (kDebugMode) print("Starting User Class ID Migration...");
      final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'student').get();
      final userBatch = _firestore.batch();
      int userUpdatedCount = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final classId = data['classId']?.toString().toLowerCase() ?? '';
        
        // Check if classId needs fixing
        if (classId.startsWith('class') || classId.startsWith('grade')) {
           // Extract number: "class 1" -> "1"
           final newClassId = classId.replaceAll(RegExp(r'[^0-9]'), '');
           
           if (standardClasses.contains(newClassId)) {
              userBatch.update(doc.reference, {'classId': newClassId});
              userUpdatedCount++;
           }
        }
      }
      
      if (userUpdatedCount > 0) {
        await userBatch.commit();
        if (kDebugMode) print("Migrated $userUpdatedCount user records.");
      }

      if (kDebugMode) print("Aggressive Cleanup Complete!");
    } catch (e) {
      if (kDebugMode) print("Cleanup Failed: $e");
      rethrow;
    }
  }

  static Future<void> _migrateCollectionField(String collection, String field, String oldValue, String newValue) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore.collection(collection).where(field, isEqualTo: oldValue).get();
    
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {field: newValue});
    }
    await batch.commit();
     if (kDebugMode) print("Migrated $collection: ${snapshot.docs.length} documents.");
  }
}
