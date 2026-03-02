
import 'package:flutter_test/flutter_test.dart';
import 'package:vps/data/services/migration_service.dart';

void main() {
  group('MigrationService Tests', () {
    final service = MigrationService();

    test('Student CSV Parsing', () {
      final studentCsv = service.getSampleCsv('student');
      final studentData = service.parseCsv(studentCsv);
      
      expect(studentData.length, greaterThan(0));
      expect(studentData[0]['name'], 'John Doe');
      expect(studentData[0]['classId'], '5');
    });

    test('Staff CSV Parsing', () {
      final staffCsv = service.getSampleCsv('staff');
      final staffData = service.parseCsv(staffCsv);
      
      expect(staffData.length, greaterThan(0));
      expect(staffData[0]['name'], 'Alice Smith');
      expect(staffData[0]['role'], 'teacher');
    });

    test('Empty CSV Parsing', () {
      final data = service.parseCsv("");
      expect(data.length, 0);
    });
  });
}
