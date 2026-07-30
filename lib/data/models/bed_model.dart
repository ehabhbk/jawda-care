class BedModel {
  final String? id;
  final String departmentId;
  final String hospitalId;
  final String name;
  final String nameAr;
  final String status;
  final String? patientName;
  final String? patientId;
  final String? bookingId;
  final DateTime createdAt;

  BedModel({
    this.id,
    required this.departmentId,
    required this.hospitalId,
    required this.name,
    required this.nameAr,
    this.status = 'available',
    this.patientName,
    this.patientId,
    this.bookingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'departmentId': departmentId,
      'hospitalId': hospitalId,
      'name': name,
      'nameAr': nameAr,
      'status': status,
      'patientName': patientName,
      'patientId': patientId,
      'bookingId': bookingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BedModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BedModel(
      id: documentId,
      departmentId: map['departmentId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      status: map['status'] ?? 'available',
      patientName: map['patientName'],
      patientId: map['patientId'],
      bookingId: map['bookingId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
