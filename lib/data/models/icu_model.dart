class IcuModel {
  final String? id;
  final String hospitalId;
  final String hospitalName;
  final String hospitalNameAr;
  final String roomNumber;
  final String type;
  final String typeAr;
  final String description;
  final String descriptionAr;
  final double pricePerDay;
  final bool isAvailable;
  final List<String>? equipment;
  final List<String>? equipmentAr;
  final double? rating;
  final String? imageUrl;
  final DateTime createdAt;

  IcuModel({
    this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalNameAr,
    required this.roomNumber,
    required this.type,
    required this.typeAr,
    required this.description,
    required this.descriptionAr,
    required this.pricePerDay,
    this.isAvailable = true,
    this.equipment,
    this.equipmentAr,
    this.rating,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'hospitalNameAr': hospitalNameAr,
      'roomNumber': roomNumber,
      'type': type,
      'typeAr': typeAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'pricePerDay': pricePerDay,
      'isAvailable': isAvailable,
      'equipment': equipment,
      'equipmentAr': equipmentAr,
      'rating': rating,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IcuModel.fromMap(Map<String, dynamic> map, String documentId) {
    return IcuModel(
      id: documentId,
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      hospitalNameAr: map['hospitalNameAr'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      type: map['type'] ?? '',
      typeAr: map['typeAr'] ?? '',
      description: map['description'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      equipment: map['equipment'] != null ? List<String>.from(map['equipment']) : null,
      equipmentAr: map['equipmentAr'] != null ? List<String>.from(map['equipmentAr']) : null,
      rating: (map['rating'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  IcuModel copyWith({bool? isAvailable}) {
    return IcuModel(
      id: id,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      hospitalNameAr: hospitalNameAr,
      roomNumber: roomNumber,
      type: type,
      typeAr: typeAr,
      description: description,
      descriptionAr: descriptionAr,
      pricePerDay: pricePerDay,
      isAvailable: isAvailable ?? this.isAvailable,
      equipment: equipment,
      equipmentAr: equipmentAr,
      rating: rating,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }
}
