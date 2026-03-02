class ClassModel {
  final String id;
  final String name; // e.g. "10-A"
  final String teacherId; // The teacher in charge
  final double monthlyFee;
  final double coachingFee;
  final double busFee;
  final double hostelFee;
  final double milkFee;
  final Map<String, double> otherFees;

  final List<String> customColumns;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    this.monthlyFee = 0.0,
    this.coachingFee = 0.0,
    this.busFee = 0.0,
    this.hostelFee = 0.0,
    this.milkFee = 0.0,
    this.otherFees = const {},
    this.customColumns = const [],
  });

  factory ClassModel.fromMap(Map<String, dynamic> data, String id) {
    return ClassModel(
      id: id,
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
      monthlyFee: (data['monthlyFee'] ?? 0.0).toDouble(),
      coachingFee: (data['coachingFee'] ?? 0.0).toDouble(),
      busFee: (data['busFee'] ?? 0.0).toDouble(),
      hostelFee: (data['hostelFee'] ?? 0.0).toDouble(),
      milkFee: (data['milkFee'] ?? 0.0).toDouble(),
      otherFees: (data['otherFees'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      customColumns: List<String>.from(data['customColumns'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'monthlyFee': monthlyFee,
      'coachingFee': coachingFee,
      'busFee': busFee,
      'hostelFee': hostelFee,
      'milkFee': milkFee,
      'otherFees': otherFees,
      'customColumns': customColumns,
    };
  }
}
