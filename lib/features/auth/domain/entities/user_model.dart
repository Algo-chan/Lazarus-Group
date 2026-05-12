import 'package:local_service_app/core/enums/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? profileImage;
  final bool isVerified;
  final bool? isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.isVerified = false,
    this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: UserRole.fromString(json['role'] ?? 'customer'),
      profileImage: json['profile_image'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'profile_image': profileImage,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
