class ClassModel {
  final String id;
  final String name; // e.g. "10-A"
  final String teacherId; // The teacher in charge
  final double monthlyFee;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    this.monthlyFee = 0.0,
  });

  factory ClassModel.fromMap(Map<String, dynamic> data, String id) {
    return ClassModel(
      id: id,
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
      monthlyFee: (data['monthlyFee'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'monthlyFee': monthlyFee,
    };
  }
}
