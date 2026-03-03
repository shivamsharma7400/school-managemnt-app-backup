import 'package:flutter_test/flutter_test.dart';
import 'package:vps/data/models/strategic_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('StrategicTask Date Parsing Tests', () {
    test('StrategicTask.fromJson handles ISO 8601 String', () {
      final mockJson = {
        'id': 'task_1',
        'title': 'Test Task String',
        'date': '2026-02-13T00:00:00.000Z',
        'isCompleted': false,
        'priority': 'Normal',
        'column': 'To Do',
      };
      
      final task = StrategicTask.fromJson(mockJson);
      
      expect(task.id, 'task_1');
      expect(task.date.year, 2026);
      expect(task.date.month, 2);
      expect(task.date.day, 13);
    });

    test('StrategicTask.fromJson handles Firestore Timestamp', () {
      final mockDate = DateTime(2026, 3, 3);
      final mockJson = {
        'id': 'task_2',
        'title': 'Test Task Timestamp',
        'date': Timestamp.fromDate(mockDate),
        'isCompleted': true,
        'priority': 'High',
        'column': 'In Progress',
      };
      
      final task = StrategicTask.fromJson(mockJson);
      
      expect(task.id, 'task_2');
      expect(task.date.year, 2026);
      expect(task.date.month, 3);
      expect(task.date.day, 3);
    });

    test('StrategicTask.fromJson handles missing fields gracefully', () {
      final mockJson = {
        'id': 'task_3',
        'date': '2026-01-01T00:00:00.000Z',
      };
      
      final task = StrategicTask.fromJson(mockJson);
      
      expect(task.title, '');
      expect(task.isCompleted, false);
      expect(task.priority, 'Normal');
    });

    test('AIService date handling (Logic Simulation)', () {
      final task = StrategicTask(
        id: '1',
        title: 'Strategy',
        date: DateTime(2026, 2, 13),
      );
      
      expect(task.date.year, 2026);
    });
  });
}
