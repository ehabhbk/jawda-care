class UserModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? bloodType;
  final List<String>? medicalConditions;
  final List<String>? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String role;
  final String? hospitalId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.bloodType,
    this.medicalConditions,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.role = 'patient',
    this.hospitalId,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'role': role,
      'hospitalId': hospitalId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'],
      bloodType: map['bloodType'],
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      role: map['role'] ?? 'patient',
      hospitalId: map['hospitalId'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? bloodType,
    List<String>? medicalConditions,
    List<String>? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? role,
    String? hospitalId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      role: role ?? this.role,
      hospitalId: hospitalId ?? this.hospitalId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
