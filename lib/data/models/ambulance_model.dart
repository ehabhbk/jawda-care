class AmbulanceModel {
  final String? id;
  final String hospitalId;
  final String plateNumber;
  final String driverName;
  final String driverPhone;
  final String driverEmail;
  final String driverPassword;
  final double currentLat;
  final double currentLng;
  final String status;
  final DateTime createdAt;

  AmbulanceModel({
    this.id,
    required this.hospitalId,
    required this.plateNumber,
    required this.driverName,
    required this.driverPhone,
    required this.driverEmail,
    required this.driverPassword,
    this.currentLat = 0,
    this.currentLng = 0,
    this.status = 'available',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hospitalId': hospitalId,
      'plateNumber': plateNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'driverPassword': driverPassword,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AmbulanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AmbulanceModel(
      id: documentId,
      hospitalId: map['hospitalId'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      driverEmail: map['driverEmail'] ?? '',
      driverPassword: map['driverPassword'] ?? '',
      currentLat: (map['currentLat'] ?? 0).toDouble(),
      currentLng: (map['currentLng'] ?? 0).toDouble(),
      status: map['status'] ?? 'available',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
