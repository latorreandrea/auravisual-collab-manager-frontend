/// Project model - represents a client project with tickets and tasks
class Project {
  final String id;
  final String name;
  final String description;
  final String? clientId;
  final String? websiteUrl;
  final List<String> socialLinks;
  final String plan;
  final DateTime? contractSubscriptionDate;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Additional fields for UI display (from API response)
  final ProjectClient? client;
  final int openTicketsCount;
  final int openTasksCount;
  final List<ProjectTicket> openTickets;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    this.clientId,
    this.websiteUrl,
    this.socialLinks = const [],
    required this.plan,
    this.contractSubscriptionDate,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    // UI fields
    this.client,
    this.openTicketsCount = 0,
    this.openTasksCount = 0,
    this.openTickets = const [],
  });

  /// Get project status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'in_development':
        return 'blue';
      case 'completed':
        return 'green';
      case 'on_hold':
        return 'orange';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get project status display name
  String get statusDisplayName {
    return status.replaceAll('_', ' ').split(' ')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Get project priority based on active items
  String get priority {
    final totalActiveItems = openTicketsCount + openTasksCount;
    if (totalActiveItems >= 10) return 'High';
    if (totalActiveItems >= 5) return 'Medium';
    if (totalActiveItems > 0) return 'Low';
    return 'None';
  }

  /// Create Project from API JSON response
  factory Project.fromJson(Map<String, dynamic> json) {
    // Tickets (open subset in list endpoints)
    final ticketsData = json['open_tickets'] as List<dynamic>? ?? [];
    final openTickets = ticketsData.map((t) => ProjectTicket.fromJson(t)).toList();

    // Website can arrive as website OR website_url depending on endpoint/version
    final website = json['website_url'] ?? json['website'];

    // Social links may arrive as:
    // - social_links: ["https://..."] (array form – newer schema)
    // - socials: [ ... ] (array) or a single string (legacy backend create response)
    List<String> socialLinks = [];
    if (json['social_links'] is List) {
      socialLinks = (json['social_links'] as List).map((e) => e.toString()).toList();
    } else if (json['socials'] is List) {
      socialLinks = (json['socials'] as List).map((e) => e.toString()).toList();
    } else if (json['socials'] is String) {
      socialLinks = (json['socials'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Untitled Project',
      description: json['description'] ?? '',
      clientId: json['client_id']?.toString(),
      websiteUrl: website,
      socialLinks: socialLinks,
      plan: json['plan'] ?? 'Starter Launch',
      contractSubscriptionDate: json['contract_subscription_date'] != null
          ? DateTime.tryParse(json['contract_subscription_date'])
          : null,
      status: json['status'] ?? 'in_development',
      createdBy: json['created_by']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      client: json['client'] != null
          ? ProjectClient.fromJson(json['client'])
          : (json['clients'] != null ? ProjectClient.fromJson(json['clients']) : null),
      openTicketsCount: json['open_tickets_count'] ?? 0,
      openTasksCount: json['open_tasks_count'] ?? 0,
      openTickets: openTickets,
    );
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'client_id': clientId,
      'website_url': websiteUrl,
      'social_links': socialLinks,
      'plan': plan,
      'contract_subscription_date': contractSubscriptionDate?.toIso8601String().split('T')[0],
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // UI fields
      'client': client?.toJson(),
      'open_tickets_count': openTicketsCount,
      'open_tasks_count': openTasksCount,
    };
  }

  /// Convert to JSON for API creation request
  Map<String, dynamic> toCreateJson() {
    // Align with current backend /admin/projects endpoint which expects:
    // name (required), client_id (required), website (optional), socials (optional string)
    // Extra fields like description are ignored by backend but we include for forward compatibility.
    return {
      'name': name,
      'client_id': clientId,
      if (description.isNotEmpty) 'description': description,
      if (websiteUrl != null && websiteUrl!.isNotEmpty) 'website': websiteUrl,
      if (socialLinks.isNotEmpty) 'socials': socialLinks.join(', '),
    };
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, status: $status, '
           'tickets: $openTicketsCount, tasks: $openTasksCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Project client model
class ProjectClient {
  final String id;
  final String email;
  final String username;
  final String fullName;

  const ProjectClient({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
  });

  String get displayName => fullName.isNotEmpty ? fullName : username;

  factory ProjectClient.fromJson(Map<String, dynamic> json) {
    return ProjectClient(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
    };
  }
}

/// Project ticket model
class ProjectTicket {
  final String id;
  final String message;
  final String status;
  final int activeTasksCount;
  final List<ProjectTask> activeTasks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectTicket({
    required this.id,
    required this.message,
    required this.status,
    required this.activeTasksCount,
    required this.activeTasks,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectTicket.fromJson(Map<String, dynamic> json) {
    final tasksData = json['active_tasks'] as List<dynamic>? ?? [];
    final activeTasks = tasksData.map((taskJson) => 
        ProjectTask.fromJson(taskJson)).toList();

    return ProjectTicket(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'unknown',
      activeTasksCount: json['active_tasks_count'] ?? 0,
      activeTasks: activeTasks,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }
}

/// Project task model
class ProjectTask {
  final String id;
  final String action;
  final String assignedTo;
  final String status;
  final String priority;
  final DateTime createdAt;

  const ProjectTask({
    required this.id,
    required this.action,
    required this.assignedTo,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id']?.toString() ?? '',
      action: json['action'] ?? '',
      assignedTo: json['assigned_to']?.toString() ?? '',
      status: json['status'] ?? 'unknown',
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}