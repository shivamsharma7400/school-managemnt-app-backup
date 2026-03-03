
import 'package:cloud_firestore/cloud_firestore.dart';

class StrategicTask {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final String priority; // 'To Do', 'In Progress', 'Done' (though Done implies completed) -> 'Normal', 'High'
  final String column; // 'To Do', 'In Progress'

  StrategicTask({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.priority = 'Normal',
    this.column = 'To Do',
  });

  factory StrategicTask.fromJson(Map json) {
    DateTime parsedDate;
    final dateValue = json['date'];
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else {
      parsedDate = DateTime.now();
    }

    return StrategicTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: parsedDate,
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 'Normal',
      column: json['column'] ?? 'To Do',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority,
      'column': column,
    };
  }
}
