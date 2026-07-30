class DepartmentModel {
  final String? id;
  final String hospitalId;
  final String name;
  final String nameAr;
  final DateTime createdAt;

  DepartmentModel({
    this.id,
    required this.hospitalId,
    required this.name,
    required this.nameAr,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hospitalId': hospitalId,
      'name': name,
      'nameAr': nameAr,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DepartmentModel(
      id: documentId,
      hospitalId: map['hospitalId'] ?? '',
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
