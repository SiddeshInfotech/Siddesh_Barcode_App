import 'package:flutter/material.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String memberSince;
  final String? imagePath;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    this.role = 'System Administrator',
    this.memberSince = 'January 2024',
    this.imagePath,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? memberSince,
    String? imagePath,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  bool rememberMe = false;
  bool isLoggedIn = false;

  final ValueNotifier<UserProfile> userNotifier = ValueNotifier<UserProfile>(
    const UserProfile(
      fullName: 'Admin User',
      email: 'admin@inventory.com',
      phone: '+1 (555) 019-2834',
    ),
  );

  UserProfile get currentUser => userNotifier.value;

  void setRememberMe(bool value) {
    rememberMe = value;
  }

  void setLoggedIn(bool value) {
    isLoggedIn = value;
  }

  void updateUserProfile({
    required String fullName,
    required String email,
    String? phone,
  }) {
    userNotifier.value = userNotifier.value.copyWith(
      fullName: fullName.trim().isEmpty ? 'Admin User' : fullName.trim(),
      email: email.trim().isEmpty ? 'admin@inventory.com' : email.trim(),
      phone: (phone != null && phone.trim().isNotEmpty)
          ? phone.trim()
          : userNotifier.value.phone,
    );
  }

  void updateProfileImage(String path) {
    userNotifier.value = userNotifier.value.copyWith(imagePath: path);
  }
}
