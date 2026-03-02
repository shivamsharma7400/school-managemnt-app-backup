
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

class MigrationService {
  final _uuid = const Uuid();

  // Parse CSV and return list of maps
  List<Map<String, dynamic>> parseCsv(String csvString) {
    if (csvString.isEmpty) return [];
    
    // Normalize line endings to help the parser
    final String normalizedCsv = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(normalizedCsv);
    if (rows.length < 2) return [];

    // Headers are in the first row
    final List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
    final List<Map<String, dynamic>> data = [];

    for (int i = 1; i < rows.length; i++) {
      // Skip empty rows
      if (rows[i].isEmpty || (rows[i].length == 1 && rows[i][0].toString().isEmpty)) continue;
      
      final Map<String, dynamic> item = {};
      for (int j = 0; j < headers.length; j++) {
        if (j < rows[i].length) {
          item[headers[j]] = rows[i][j];
        } else {
          item[headers[j]] = null;
        }
      }
      data.add(item);
    }
    return data;
  }

  // Import data to Firestore
  Future<int> importData(String role, List<Map<String, dynamic>> records) async {
    final firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();
    int count = 0;
    int totalImported = 0;

    // Get starting numeric ID to increment locally
    int nextNumericId = await _getStartId(role, firestore);

    for (var record in records) {
      final String docId = _uuid.v4();
      final DocumentReference docRef = firestore.collection('users').doc(docId);

      final Map<String, dynamic> userData = {
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'isMigrated': true,
        'isApproved': true, 
        ...record,
      };

      // Auto-generate IDs if missing
      final String idField = role == 'student' ? 'admNo' : (role == 'teacher' ? 'teacherId' : 'staffId');
      if (userData[idField] == null || userData[idField].toString().isEmpty) {
        userData[idField] = (nextNumericId++).toString();
      }

      batch.set(docRef, userData);
      count++;
      totalImported++;

      // Batch limit is 500, using 400 for safety
      if (count >= 400) {
        await batch.commit();
        batch = firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    return totalImported;
  }

  Future<int> _getStartId(String role, FirebaseFirestore firestore) async {
     final String field = role == 'student' ? 'admNo' : (role == 'teacher' ? 'teacherId' : 'staffId');
     Query query = firestore.collection('users');
     
     if (role == 'student') {
        query = query.where('role', isEqualTo: 'student');
     } else if (role == 'teacher') {
        query = query.where('role', isEqualTo: 'teacher');
     } else {
        query = query.where('role', whereNotIn: ['student', 'teacher', 'principal', 'pending', 'admin']);
     }

     final QuerySnapshot snapshot = await query.get();
     int maxId = 0;
     for (var doc in snapshot.docs) {
       final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
       final String idStr = data[field]?.toString() ?? '';
       final RegExpMatch? match = RegExp(r'(\d+)').firstMatch(idStr);
       if (match != null) {
         final int id = int.tryParse(match.group(1)!) ?? 0;
         if (id > maxId) maxId = id;
       }
     }

     if (maxId == 0) {
       if (role == 'student') return 1001;
       if (role == 'teacher') return 101;
       return 501;
     }
     return maxId + 1;
  }

  String getSampleCsv(String role) {
    if (role == 'student') {
      return "name,fatherName,motherName,classId,age,gender,phone,address,aadharNo,bankName,bankAccountNo,ifscCode\nJohn Doe,Richard Doe,Jane Doe,5,10,Male,9876543210,123 Street,123456789012,SBI,123456789,SBIN0001";
    } else {
      return "name,workField,role,phone,monthlySalary,address,aadharNo,bankName,bankAccountNo,ifscCode\nAlice Smith,Academics,teacher,9876543211,25000,456 Lane,234567890123,HDFC,987654321,HDFC0002";
    }
  }
}
