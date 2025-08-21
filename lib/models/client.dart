/// Client model - represents a client user with project statistics
class Client {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final int activeProjectsCount;
  final int totalProjectsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Client({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.activeProjectsCount,
    required this.totalProjectsCount,
    required this.createdAt,
    this.updatedAt,
  });

  /// Display name for UI
  String get displayName => fullName.isNotEmpty ? fullName : username.isNotEmpty ? username : email.split('@')[0];

  /// Client initials for avatar
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 1).toUpperCase();
  }

  /// Activity status based on project count
  String get activityStatus {
    if (!isActive) return 'Inactive';
    if (activeProjectsCount == 0) return 'No Projects';
    if (activeProjectsCount >= 1) return '$activeProjectsCount Projects';

    return '$activeProjectsCount Projects';
  }

  /// Create Client from API JSON response
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'client',
      isActive: json['is_active'] ?? true,
      activeProjectsCount: json['active_projects_count'] ?? 0,
      totalProjectsCount: json['total_projects_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'active_projects_count': activeProjectsCount,
      'total_projects_count': totalProjectsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Client(id: $id, email: $email, fullName: $fullName, '
           'activeProjects: $activeProjectsCount, totalProjects: $totalProjectsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Client project model - simplified project info for client view
class ClientProject {
  final String id;
  final String name;
  final String status;
  final int openTicketsCount;
  final int openTasksCount;
  final DateTime createdAt;

  const ClientProject({
    required this.id,
    required this.name,
    required this.status,
    required this.openTicketsCount,
    required this.openTasksCount,
    required this.createdAt,
  });

  factory ClientProject.fromJson(Map<String, dynamic> json) {
    return ClientProject(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Untitled Project',
      status: json['status'] ?? 'unknown',
      openTicketsCount: json['open_tickets_count'] ?? 0,
      openTasksCount: json['open_tasks_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}