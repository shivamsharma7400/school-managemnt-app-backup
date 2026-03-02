import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/strategic_task.dart';

class StrategicPlanningService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tasksCollection => _firestore.collection('strategic_tasks');

  // Add Task
  Future<void> addTask(String title, DateTime date, String priority, String column) async {
    await _tasksCollection.add({
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': false,
      'priority': priority,
      'column': column,
      'createdAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // Get ALL Active Tasks (Client-side filtering for Scheduler UI consistency)
  Stream<List<StrategicTask>> getActiveTasks() {
    return _tasksCollection
        .where('isCompleted', isEqualTo: false) // Only active tasks
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return StrategicTask.fromJson(data);
      }).toList();
    });
  }

  // Get ALL Completed Tasks (History)
  Stream<List<StrategicTask>> getCompletedTasks() {
    return _tasksCollection
        .where('isCompleted', isEqualTo: true)
        // .orderBy('date', descending: true) // Removed server-side ordering to avoid index issues
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return StrategicTask.fromJson(data);
      }).toList();
    });
  }

  // Update Task Status (Completion)
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _tasksCollection.doc(taskId).update({
      'isCompleted': isCompleted,
    });
    notifyListeners();
  }

  // Update Task Column (Kanban move)
  Future<void> updateTaskColumn(String taskId, String newColumn) async {
    await _tasksCollection.doc(taskId).update({
      'column': newColumn,
    });
    notifyListeners();
  }
  
  // Delete Task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
    notifyListeners();
  }
}
