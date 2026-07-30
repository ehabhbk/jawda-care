class HospitalModel {
  final String? id;
  final String name;
  final String nameAr;
  final String address;
  final String addressAr;
  final String city;
  final String cityAr;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;
  final String password;
  final String? adminUid;
  final String? imageUrl;
  final double rating;
  final int totalBeds;
  final int availableBeds;
  final bool hasAmbulance;
  final List<String>? facilities;
  final List<String>? facilitiesAr;
  final bool isActive;
  final DateTime createdAt;

  HospitalModel({
    this.id,
    required this.name,
    required this.nameAr,
    required this.address,
    required this.addressAr,
    required this.city,
    required this.cityAr,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    required this.password,
    this.adminUid,
    this.imageUrl,
    this.rating = 0,
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.hasAmbulance = false,
    this.facilities,
    this.facilitiesAr,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'nameAr': nameAr,
      'address': address,
      'addressAr': addressAr,
      'city': city,
      'cityAr': cityAr,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'password': password,
      'adminUid': adminUid,
      'imageUrl': imageUrl,
      'rating': rating,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'hasAmbulance': hasAmbulance,
      'facilities': facilities,
      'facilitiesAr': facilitiesAr,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HospitalModel(
      id: documentId,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      address: map['address'] ?? '',
      addressAr: map['addressAr'] ?? '',
      city: map['city'] ?? '',
      cityAr: map['cityAr'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      adminUid: map['adminUid'],
      imageUrl: map['imageUrl'],
      rating: (map['rating'] ?? 0).toDouble(),
      totalBeds: map['totalBeds'] ?? 0,
      availableBeds: map['availableBeds'] ?? 0,
      hasAmbulance: map['hasAmbulance'] ?? false,
      facilities: map['facilities'] != null ? List<String>.from(map['facilities']) : null,
      facilitiesAr: map['facilitiesAr'] != null ? List<String>.from(map['facilitiesAr']) : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
