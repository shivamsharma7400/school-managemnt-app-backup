import 'package:flutter_test/flutter_test.dart';
import 'package:vps/data/models/attendance_record.dart';
import 'package:vps/data/models/class_model.dart';

void main() {
  group('Data Model Robustness Tests', () {
    test('AttendanceRecord.fromJson handles IdentityMap and casting', () {
      final mockJson = {
        'classId': 'test_class',
        'records': {
          'student_1': 'Present',
          'student_2': 'Absent',
        },
        'markedBy': 'teacher_1',
        'markedByName': 'Mr. Test',
      };
      
      final record = AttendanceRecord.fromJson(mockJson, 'test_id');
      
      expect(record.id, 'test_id');
      expect(record.attendance, isA<Map<String, String>>());
      expect(record.attendance['student_1'], 'Present');
    });

    test('ClassModel.fromMap handles Map casting', () {
      final mockData = {
        'name': '10-A',
        'teacherId': 'teacher_1',
        'monthlyFee': 1000,
        'otherFees': {
          'Exam Fee': 500,
        },
        'customColumns': ['Col1', 'Col2'],
      };
      
      final model = ClassModel.fromMap(mockData, 'class_id');
      
      expect(model.id, 'class_id');
      expect(model.otherFees, isA<Map<String, double>>());
      expect(model.otherFees['Exam Fee'], 500.0);
      expect(model.customColumns, isA<List<String>>());
      expect(model.customColumns.first, 'Col1');
    });
  });
}
