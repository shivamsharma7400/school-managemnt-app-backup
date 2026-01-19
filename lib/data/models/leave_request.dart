import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime appliedOn;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.appliedOn,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> data, String documentId) {
    return LeaveRequest(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userRole: data['userRole'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      appliedOn: (data['appliedOn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status,
      'appliedOn': Timestamp.fromDate(appliedOn),
    };
  }
}
