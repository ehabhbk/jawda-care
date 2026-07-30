enum BookingType { icu, ambulance }

enum BookingStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled,
}

class BookingModel {
  final String? id;
  final String userId;
  final String userName;
  final String userPhone;
  final double? userLat;
  final double? userLng;
  final BookingType bookingType;
  final BookingStatus status;
  final String? departmentId;
  final String? departmentName;
  final String? departmentNameAr;
  final String? bedId;
  final String? bedName;
  final String? bedNameAr;
  final String? hospitalId;
  final String? hospitalName;
  final String? hospitalNameAr;
  final String? hospitalAddress;
  final String? ambulanceId;
  final String? driverName;
  final String? driverPhone;
  final String? plateNumber;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userLat,
    this.userLng,
    required this.bookingType,
    this.status = BookingStatus.pending,
    this.departmentId,
    this.departmentName,
    this.departmentNameAr,
    this.bedId,
    this.bedName,
    this.bedNameAr,
    this.hospitalId,
    this.hospitalName,
    this.hospitalNameAr,
    this.hospitalAddress,
    this.ambulanceId,
    this.driverName,
    this.driverPhone,
    this.plateNumber,
    this.notes,
    this.cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userLat': userLat,
      'userLng': userLng,
      'bookingType': bookingType.name,
      'status': status.name,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'departmentNameAr': departmentNameAr,
      'bedId': bedId,
      'bedName': bedName,
      'bedNameAr': bedNameAr,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'hospitalNameAr': hospitalNameAr,
      'hospitalAddress': hospitalAddress,
      'ambulanceId': ambulanceId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'plateNumber': plateNumber,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      userLat: (map['userLat'] ?? 0).toDouble(),
      userLng: (map['userLng'] ?? 0).toDouble(),
      bookingType: _parseBookingType(map['bookingType']),
      status: _parseBookingStatus(map['status']),
      departmentId: map['departmentId'],
      departmentName: map['departmentName'],
      departmentNameAr: map['departmentNameAr'],
      bedId: map['bedId'],
      bedName: map['bedName'],
      bedNameAr: map['bedNameAr'],
      hospitalId: map['hospitalId'],
      hospitalName: map['hospitalName'],
      hospitalNameAr: map['hospitalNameAr'],
      hospitalAddress: map['hospitalAddress'],
      ambulanceId: map['ambulanceId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      plateNumber: map['plateNumber'],
      notes: map['notes'],
      cancellationReason: map['cancellationReason'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  static BookingType _parseBookingType(String? type) {
    switch (type) {
      case 'ambulance':
        return BookingType.ambulance;
      default:
        return BookingType.icu;
    }
  }

  static BookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'accepted':
        return BookingStatus.accepted;
      case 'rejected':
        return BookingStatus.rejected;
      case 'inProgress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusLabelAr {
    switch (status) {
      case BookingStatus.pending:
        return 'قيد الانتظار';
      case BookingStatus.accepted:
        return 'مقبول';
      case BookingStatus.rejected:
        return 'مرفوض';
      case BookingStatus.inProgress:
        return 'قيد التنفيذ';
      case BookingStatus.completed:
        return 'مكتمل';
      case BookingStatus.cancelled:
        return 'ملغي';
    }
  }
}
