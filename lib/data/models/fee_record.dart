
class FeeRecord {
  final String id;
  final String userId;
  final String studentName;
  final String classId;
  final String month; // e.g., "January 2026"
  final double totalAmount;
  final double paidAmount;
  final double? _explicitDueAmount; // Internal storage for override

  FeeRecord({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.classId,
    required this.month,
    required this.totalAmount,
    required this.paidAmount,
    double? dueAmount, // Optional override
  }) : _explicitDueAmount = dueAmount;

  double get dueAmount => _explicitDueAmount ?? (totalAmount - paidAmount);
  
  String get status {
    if (dueAmount == 0) return 'Paid';
    if (paidAmount == 0) return 'Due';
    return 'Partial';
  }

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    return FeeRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      studentName: json['studentName'] ?? '',
      classId: json['classId'] ?? '',
      month: json['month'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // To save to Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'studentName': studentName,
      'classId': classId,
      'month': month,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      // 'id' is usually the document ID, so we might exclude it from the body or include it if needed.
      // Firestore best practice is often to exclude ID from the data payload if it's the doc ID.
    };
  }
}
