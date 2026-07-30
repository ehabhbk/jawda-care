class TripModel {
  final String? id;
  final String bookingId;
  final String ambulanceId;
  final String driverId;
  final String patientId;
  final String hospitalId;
  final double patientLat;
  final double patientLng;
  final double hospitalLat;
  final double hospitalLng;
  final double driverLat;
  final double driverLng;
  final String status;
  final double? eta;
  final double? distance;
  final DateTime? startedAt;
  final DateTime? arrivedAtPatientAt;
  final DateTime? arrivedAtHospitalAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  TripModel({
    this.id,
    required this.bookingId,
    required this.ambulanceId,
    required this.driverId,
    required this.patientId,
    required this.hospitalId,
    required this.patientLat,
    required this.patientLng,
    required this.hospitalLat,
    required this.hospitalLng,
    this.driverLat = 0,
    this.driverLng = 0,
    this.status = 'heading_to_patient',
    this.eta,
    this.distance,
    this.startedAt,
    this.arrivedAtPatientAt,
    this.arrivedAtHospitalAt,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bookingId': bookingId,
      'ambulanceId': ambulanceId,
      'driverId': driverId,
      'patientId': patientId,
      'hospitalId': hospitalId,
      'patientLat': patientLat,
      'patientLng': patientLng,
      'hospitalLat': hospitalLat,
      'hospitalLng': hospitalLng,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'status': status,
      'eta': eta,
      'distance': distance,
      'startedAt': startedAt?.toIso8601String(),
      'arrivedAtPatientAt': arrivedAtPatientAt?.toIso8601String(),
      'arrivedAtHospitalAt': arrivedAtHospitalAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripModel(
      id: documentId,
      bookingId: map['bookingId'] ?? '',
      ambulanceId: map['ambulanceId'] ?? '',
      driverId: map['driverId'] ?? '',
      patientId: map['patientId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      patientLat: (map['patientLat'] ?? 0).toDouble(),
      patientLng: (map['patientLng'] ?? 0).toDouble(),
      hospitalLat: (map['hospitalLat'] ?? 0).toDouble(),
      hospitalLng: (map['hospitalLng'] ?? 0).toDouble(),
      driverLat: (map['driverLat'] ?? 0).toDouble(),
      driverLng: (map['driverLng'] ?? 0).toDouble(),
      status: map['status'] ?? 'heading_to_patient',
      eta: (map['eta'] ?? 0).toDouble(),
      distance: (map['distance'] ?? 0).toDouble(),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      arrivedAtPatientAt: map['arrivedAtPatientAt'] != null ? DateTime.parse(map['arrivedAtPatientAt']) : null,
      arrivedAtHospitalAt: map['arrivedAtHospitalAt'] != null ? DateTime.parse(map['arrivedAtHospitalAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
