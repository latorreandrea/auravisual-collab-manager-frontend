import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import 'auth_service.dart';

/// Service for dashboard-related API calls
class DashboardService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get dashboard statistics (admin only)
  /// Uses GET /admin/dashboard endpoint from backend
  static Future<DashboardData> getDashboardData() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Dashboard API call: GET /admin/dashboard',
        name: 'DashboardService.getDashboardData',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return DashboardData.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load dashboard data: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Dashboard service error: $error',
        name: 'DashboardService.getDashboardData',
        error: error,
      );
      throw Exception('Error fetching dashboard data: $error');
    }
  }

  /// Get client projects (client only)
  /// Uses GET /client/projects endpoint
  static Future<ClientDashboardData> getClientDashboardData() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/client/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Client dashboard API call: GET /client/projects',
        name: 'DashboardService.getClientDashboardData',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ClientDashboardData.fromJson(responseData);
      } else {
        throw Exception('Failed to load client data: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Client dashboard error: $error',
        name: 'DashboardService.getClientDashboardData',
        error: error,
      );
      throw Exception('Error fetching client dashboard data: $error');
    }
  }

  /// Get staff tasks summary (staff only)
  /// Uses GET /tasks/my/active endpoint
  static Future<StaffDashboardData> getStaffDashboardData() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      // Get active tasks
      final activeTasksResponse = await http.get(
        Uri.parse('$_baseUrl/tasks/my/active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Get all tasks for completed count
      final allTasksResponse = await http.get(
        Uri.parse('$_baseUrl/tasks/my'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (activeTasksResponse.statusCode == 200 && allTasksResponse.statusCode == 200) {
        final activeTasksData = json.decode(activeTasksResponse.body);
        final allTasksData = json.decode(allTasksResponse.body);
        
        return StaffDashboardData.fromApiResponses(activeTasksData, allTasksData);
      } else {
        throw Exception('Failed to load staff data');
      }
    } catch (error) {
      developer.log(
        'Staff dashboard error: $error',
        name: 'DashboardService.getStaffDashboardData',
        error: error,
      );
      throw Exception('Error fetching staff dashboard data: $error');
    }
  }
}

/// Dashboard data model for admin users
class DashboardData {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int totalClients;
  final int totalStaff;
  final int openTickets;
  final int activeTasks;

  const DashboardData({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.totalClients,
    required this.totalStaff,
    required this.openTickets,
    required this.activeTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final dashboard = json['dashboard'] ?? {};
    final projects = dashboard['projects'] ?? {};
    final clients = dashboard['clients'] ?? {};
    final staff = dashboard['staff'] ?? {};
    final tickets = dashboard['tickets'] ?? {};
    final tasks = dashboard['tasks'] ?? {};

    return DashboardData(
      totalProjects: projects['total'] ?? 0,
      activeProjects: projects['active'] ?? 0,
      completedProjects: projects['completed'] ?? 0,
      totalClients: clients['total'] ?? 0,
      totalStaff: staff['total'] ?? 0,
      openTickets: tickets['open'] ?? 0,
      activeTasks: tasks['active'] ?? 0,
    );
  }
}

/// Dashboard data model for client users
class ClientDashboardData {
  final int totalProjects;
  final int openTicketsCount;
  final List<String> projectNames;
  final String primaryPlan;

  const ClientDashboardData({
    required this.totalProjects,
    required this.openTicketsCount,
    required this.projectNames,
    required this.primaryPlan,
  });

  factory ClientDashboardData.fromJson(Map<String, dynamic> json) {
    final projects = json['projects'] as List<dynamic>? ?? [];
    final projectNames = projects.map((p) => p['name'] as String? ?? 'Unnamed Project').toList();
    final openTickets = projects.fold<int>(0, (sum, p) => sum + (p['open_tickets_count'] as int? ?? 0));
    final primaryPlan = projects.isNotEmpty ? (projects[0]['plan'] as String? ?? 'No Plan') : 'No Plan';

    return ClientDashboardData(
      totalProjects: json['total_projects'] ?? 0,
      openTicketsCount: openTickets,
      projectNames: projectNames,
      primaryPlan: primaryPlan,
    );
  }
}

/// Dashboard data model for staff users
class StaffDashboardData {
  final int activeTasks;
  final int completedTasks;
  final int totalProjects;

  const StaffDashboardData({
    required this.activeTasks,
    required this.completedTasks,
    required this.totalProjects,
  });

  factory StaffDashboardData.fromApiResponses(
    Map<String, dynamic> activeTasksData,
    Map<String, dynamic> allTasksData,
  ) {
    final activeTasks = activeTasksData['total_tasks'] ?? 0;
    final allTasks = allTasksData['tasks'] as List<dynamic>? ?? [];
    final completedTasks = allTasks.where((task) => task['status'] == 'completed').length;
    
    // Extract unique project count from tasks
    final projectIds = <String>{};
    for (final task in allTasks) {
      final projectId = task['project_id'] as String?;
      if (projectId != null && projectId.isNotEmpty) {
        projectIds.add(projectId);
      }
    }

    return StaffDashboardData(
      activeTasks: activeTasks,
      completedTasks: completedTasks,
      totalProjects: projectIds.length,
    );
  }
}