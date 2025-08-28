import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import '../models/project.dart';
import 'auth_service.dart';

/// Service for project-related API calls
class ProjectService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get all projects (admin and staff access)
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
        
        return projectsData.map((projectJson) => Project.fromJson(projectJson)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin or Staff privileges required.');
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

  /// Get client's own projects
  static Future<List<Project>> getClientProjects() async {
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
        'Client projects API call: GET /client/projects',
        name: 'ProjectService.getClientProjects',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> projectsData = responseData['projects'] ?? [];
        
        return projectsData.map((projectJson) => Project.fromJson(projectJson)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else {
        throw Exception('Failed to load client projects: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Client projects error: $error',
        name: 'ProjectService.getClientProjects',
        error: error,
      );
      throw Exception('Error fetching client projects: $error');
    }
  }

  /// Get all clients for project creation (admin only)
  static Future<List<Map<String, dynamic>>> getAllClients() async {
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

      developer.log(
        'Get all clients API call: GET /admin/users/clients',
        name: 'ProjectService.getAllClients',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> clientsData = responseData['clients'] ?? [];
        
        return clientsData.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load clients: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Get all clients error: $error',
        name: 'ProjectService.getAllClients',
        error: error,
      );
      throw Exception('Error fetching clients: $error');
    }
  }

  /// Get project statistics for dashboard
  static Future<Map<String, dynamic>> getProjectStatistics() async {
    try {
      final projects = await getAllProjects();
      
      final totalProjects = projects.length;
      final activeProjects = projects.where((p) => p.status == 'in_development' || p.status == 'active').length;
      final completedProjects = projects.where((p) => p.status == 'completed').length;
      final totalOpenTickets = projects.fold<int>(0, (sum, project) => sum + project.openTicketsCount);
      final totalOpenTasks = projects.fold<int>(0, (sum, project) => sum + project.openTasksCount);
      
      return {
        'total_projects': totalProjects,
        'active_projects': activeProjects,
        'completed_projects': completedProjects,
        'total_open_tickets': totalOpenTickets,
        'total_open_tasks': totalOpenTasks,
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
  static Future<Project> createProject(CreateProjectRequest request) async {
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
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('project')) {
          return Project.fromJson(responseData['project']);
        } else {
          return Project.fromJson(responseData);
        }
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception('Failed to create project: $errorMessage');
      }
    } catch (error) {
      developer.log(
        'Create project error: $error',
        name: 'ProjectService.createProject',
        error: error,
      );
      throw Exception('Error creating project: $error');
    }
  }
}

/// Request model for creating a new project
class CreateProjectRequest {
  final String name;
  final String description;
  final String? clientId;
  final String? websiteUrl;
  final List<String>? socialLinks;
  final String plan;
  final String? contractSubscriptionDate;
  final String status;

  const CreateProjectRequest({
    required this.name,
    required this.description,
    this.clientId,
    this.websiteUrl,
    this.socialLinks,
    required this.plan,
    this.contractSubscriptionDate,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
      if (websiteUrl != null && websiteUrl!.isNotEmpty) 'website': websiteUrl,
      if (socialLinks != null && socialLinks!.isNotEmpty) 'socials': socialLinks!.join(', '),
      'plan': plan,
      if (contractSubscriptionDate != null) 'contract_subscription_date': contractSubscriptionDate,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'CreateProjectRequest(name: $name, plan: $plan, status: $status, clientId: $clientId)';
  }
}