/// Team member model - represents internal staff members
class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final int activeTasks;
  final int totalTasks;
  final String? avatarUrl;
  final bool isActive;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.activeTasks,
    required this.totalTasks,
    this.avatarUrl,
    this.isActive = true,
  });

  /// Display name for UI
  String get displayName => name.trim().isNotEmpty ? name : email.split('@')[0];

  /// Avatar initials
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 1).toUpperCase();
  }

  /// Task status color based on workload
  String get workloadStatus {
    if (activeTasks == 0) return 'Available';
    if (activeTasks <= 2) return 'Light';
    if (activeTasks <= 4) return 'Moderate';
    return 'Heavy';
  }

  /// Create TeamMember from API JSON response from /admin/users/staff
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final taskCounts = json['task_counts'] as Map<String, dynamic>? ?? {};
    
    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: json['full_name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      role: _mapRoleToDisplayName(json['role'] ?? 'staff'),
      activeTasks: taskCounts['active_tasks'] ?? 0,
      totalTasks: taskCounts['total_assigned'] ?? 0,
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  /// Map backend role to user-friendly display name
  static String _mapRoleToDisplayName(String role) {
    switch (role) {
      case 'internal_staff':
        return 'Internal Staff';
      case 'admin':
        return 'Administrator';
      default:
        return role.replaceAll('_', ' ').split(' ')
            .map((word) => word.isEmpty ? '' : 
                 word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  /// Create a copy with updated task counts
  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? activeTasks,
    int? totalTasks,
    String? avatarUrl,
    bool? isActive,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      activeTasks: activeTasks ?? this.activeTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'activeTasks': activeTasks,
      'totalTasks': totalTasks,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
    };
  }

  /// Mock data for testing - only use if API fails
  static List<TeamMember> getMockData() {
    return [
      const TeamMember(
        id: '1',
        name: 'Sarah Johnson',
        email: 'sarah@auravisual.dk',
        role: 'Senior Developer',
        activeTasks: 4,
        totalTasks: 8,
      ),
      const TeamMember(
        id: '2',
        name: 'Marco Rossi',
        email: 'marco@auravisual.dk',
        role: 'UI/UX Designer',
        activeTasks: 2,
        totalTasks: 5,
      ),
      const TeamMember(
        id: '3',
        name: 'Anna Chen',
        email: 'anna@auravisual.dk',
        role: 'Project Manager',
        activeTasks: 7,
        totalTasks: 12,
      ),
      const TeamMember(
        id: '4',
        name: 'David Smith',
        email: 'david@auravisual.dk',
        role: 'Developer',
        activeTasks: 0,
        totalTasks: 3,
      ),
      const TeamMember(
        id: '5',
        name: 'Lisa Anderson',
        email: 'lisa@auravisual.dk',
        role: 'QA Engineer',
        activeTasks: 3,
        totalTasks: 6,
      ),
    ];
  }

  @override
  String toString() {
    return 'TeamMember(id: $id, name: $name, email: $email, role: $role, '
           'activeTasks: $activeTasks, totalTasks: $totalTasks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}