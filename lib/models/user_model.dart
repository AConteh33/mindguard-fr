class UserModel {
  final String uid;
  final String? email;
  final String? phone;
  final String role;
  final String? name;
  final String? gender;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    this.email,
    this.phone,
    required this.role,
    this.name,
    this.gender,
    this.isActive = true,
    this.createdAt,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      phone: map['phone'],
      role: map['role'] ?? '',
      name: map['name'],
      gender: map['gender'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(), // Assuming field is stored as Timestamp in Firestore
    );
  }

  // Convert UserModel to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'role': role,
      'name': name,
      'gender': gender,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
  
  // CopyWith method to create updated version of the user model
  UserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? role,
    String? name,
    String? gender,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}