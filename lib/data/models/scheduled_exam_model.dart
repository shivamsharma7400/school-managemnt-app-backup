import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledExam {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final Map<String, dynamic>? routineConfig;
  final Map<String, dynamic>? accessPermissions;

  ScheduledExam({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = 'Upcoming',
    this.routineConfig,
    this.accessPermissions,
  });

  Map<String, dynamic> get safeAccessPermissions => accessPermissions ?? const {
    'routine': false,
    'admitCard': false,
    'result': false,
  };

  factory ScheduledExam.fromFirestore(Map data, String id) {
    return ScheduledExam(
      id: id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'Upcoming',
      routineConfig: (data['routine_config'] as Map?)?.cast<String, dynamic>(),
      accessPermissions: (data['accessPermissions'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'routine_config': routineConfig,
      'accessPermissions': safeAccessPermissions,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledExam &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
