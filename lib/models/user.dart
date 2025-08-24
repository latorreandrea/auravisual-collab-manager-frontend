/// User model matching the backend API response
class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  /// Display name for UI
  String get displayName => fullName?.isNotEmpty == true ? fullName! : username ?? email;

  /// Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user is staff
  bool get isStaff => role.toLowerCase() == 'staff' || role.toLowerCase() == 'internal_staff';

  /// Check if user is client
  bool get isClient => role.toLowerCase() == 'client';

  /// Should show role badge (not for clients)
  bool get shouldShowRole => !isClient;

  /// Role display name
  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'staff':
      case 'internal_staff':
        return 'Staff Member';
      case 'client':
        return 'Client';
      default:
        return role;
    }
  }

  /// Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      fullName: json['full_name'],
      role: json['role'] ?? 'client',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role, fullName: $fullName)';
  }
}