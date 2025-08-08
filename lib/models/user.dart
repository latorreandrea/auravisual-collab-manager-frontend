/// User model matching the backend API response
class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  /// Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String)
        : null,
    );
  }

  /// Convert User to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';
  
  /// Check if user is staff
  bool get isStaff => role == 'internal_staff';
  
  /// Check if user is client
  bool get isClient => role == 'client';

  /// Get display name
  String get displayName => username ?? fullName ?? email.split('@').first;

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'internal_staff':
        return 'Internal Staff';
      case 'client':
        return 'Client';
      default:
        return role.toUpperCase();
    }
  }

  /// Should show role on welcome screen (not for clients)
  bool get shouldShowRole => !isClient;

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role)';
  }
}