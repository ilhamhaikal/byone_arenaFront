import 'dart:convert';

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role; // superadmin, admin, kasir
  final bool isActive;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get roleLabel {
    switch (role) {
      case 'superadmin': return 'Superadmin';
      case 'admin': return 'Admin';
      case 'kasir': return 'Kasir';
      default: return role;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    final p = json['permissions'];
    if (p is List) {
      perms = p.cast<String>();
    } else if (p is String && p.isNotEmpty) {
      try {
        final decoded = jsonDecode(p);
        if (decoded is List) perms = decoded.cast<String>();
      } catch (_) {}
    }
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      permissions: perms,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'role': role,
        'isActive': isActive,
      };
}
