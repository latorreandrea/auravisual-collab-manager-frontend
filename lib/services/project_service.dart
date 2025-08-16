import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import '../models/project.dart';
import 'auth_service.dart';

/// Service for project-related API calls
class ProjectService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get all projects with client info, open tickets and active tasks (admin only)
  /// Uses the real API endpoint: GET /admin/projects
  static Future<List<Project>> getAllProjects() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> projectsData = responseData['projects'] ?? [];
        
        List<Project> projects = projectsData.map((projectJson) => 
            Project.fromJson(projectJson)).toList();
        
        // Sort by number of active tickets (descending), then by active tasks (descending)
        projects.sort((a, b) {
          final ticketComparison = b.openTicketsCount.compareTo(a.openTicketsCount);
          if (ticketComparison != 0) return ticketComparison;
          return b.openTasksCount.compareTo(a.openTasksCount);
        });
        
        return projects;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load projects: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'ProjectService Error: $error',
        name: 'ProjectService.getAllProjects',
        error: error,
      );
      throw Exception('Error fetching projects: $error');
    }
  }

  /// Get a specific project by ID
  static Future<Project?> getProjectById(String projectId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> projectData = json.decode(response.body);
        return Project.fromJson(projectData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load project: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Error fetching project $projectId: $error',
        name: 'ProjectService.getProjectById',
        error: error,
      );
      throw Exception('Error fetching project: $error');
    }
  }

  /// Get project statistics for dashboard
  static Future<Map<String, dynamic>> getProjectStatistics() async {
    try {
      final projects = await getAllProjects();
      
      final totalProjects = projects.length;
      final activeProjects = projects.where((p) => 
          p.status == 'in_development').length;
      final completedProjects = projects.where((p) => 
          p.status == 'completed').length;
      final totalOpenTickets = projects.fold<int>(
        0, (sum, project) => sum + project.openTicketsCount,
      );
      final totalOpenTasks = projects.fold<int>(
        0, (sum, project) => sum + project.openTasksCount,
      );
      final highPriorityProjects = projects.where((p) => 
          p.priority == 'High').length;
      
      return {
        'total_projects': totalProjects,
        'active_projects': activeProjects,
        'completed_projects': completedProjects,
        'total_open_tickets': totalOpenTickets,
        'total_open_tasks': totalOpenTasks,
        'high_priority_projects': highPriorityProjects,
        'average_tickets_per_project': totalProjects > 0 
            ? (totalOpenTickets / totalProjects).toStringAsFixed(1) 
            : '0',
      };
    } catch (error) {
      developer.log(
        'Error calculating project statistics: $error',
        name: 'ProjectService.getProjectStatistics',
        error: error,
      );
      throw Exception('Error calculating project statistics: $error');
    }
  }

  /// Create a new project (admin only)
  /// Uses the real API endpoint: POST /admin/projects
  static Future<Project> createProject(Project project) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/admin/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(project.toCreateJson()),
      );

      developer.log(
        'Create project request: ${project.toCreateJson()}',
        name: 'ProjectService.createProject',
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Backend returns { message: ..., project: { ... }, created_by: ... }
        final projectJson = responseData['project'] ?? responseData;
        return Project.fromJson(projectJson);
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception('Invalid project data: ${errorData['detail'] ?? 'Unknown error'}');
      } else {
        throw Exception('Failed to create project: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'ProjectService Create Error: $error',
        name: 'ProjectService.createProject',
        error: error,
      );
      throw Exception('Error creating project: $error');
    }
  }

  /// Get all clients for project creation dropdown (admin only)
  static Future<List<ProjectClient>> getAllClients() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users/clients'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> clientsData = responseData['clients'] ?? [];
        
        return clientsData.map((clientJson) => ProjectClient.fromJson(clientJson)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load clients: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Error fetching clients: $error',
        name: 'ProjectService.getAllClients',
        error: error,
      );
      throw Exception('Error fetching clients: $error');
    }
  }
}