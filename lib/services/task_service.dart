import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import 'auth_service.dart';

/// Service for task-related API calls
class TaskService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get all tasks (admin only)
  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tasksData = responseData['tasks'] ?? [];
        
        return tasksData.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load tasks: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'TaskService Error: $error',
        name: 'TaskService.getAllTasks',
        error: error,
      );
      throw Exception('Error fetching tasks: $error');
    }
  }

  /// Get client's tasks from their tickets
  static Future<List<Map<String, dynamic>>> getClientTasks() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      // Get client's tickets which contain tasks
      final response = await http.get(
        Uri.parse('$_baseUrl/client/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Client tasks API call: GET /client/tickets',
        name: 'TaskService.getClientTasks',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ticketsData = responseData['tickets'] ?? [];
        
        // Extract tasks from all tickets
        List<Map<String, dynamic>> allTasks = [];
        
        for (final ticket in ticketsData) {
          final List<dynamic> tasks = ticket['tasks'] ?? [];
          final String projectName = ticket['project']?['name'] ?? 'Unknown Project';
          final String ticketMessage = ticket['message'] ?? 'No message';
          
          for (final task in tasks) {
            final Map<String, dynamic> taskMap = Map<String, dynamic>.from(task);
            // Add additional context for client view
            taskMap['project_name'] = projectName;
            taskMap['ticket_message'] = ticketMessage;
            taskMap['ticket_id'] = ticket['id'];
            taskMap['project_id'] = ticket['project']?['id'];
            
            // Ensure we have a title field for consistency
            if (!taskMap.containsKey('title') && taskMap.containsKey('action')) {
              taskMap['title'] = taskMap['action'];
            }
            
            allTasks.add(taskMap);
          }
        }
        
        return allTasks;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else {
        throw Exception('Failed to load client tasks: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Client tasks error: $error',
        name: 'TaskService.getClientTasks',
        error: error,
      );
      throw Exception('Error fetching client tasks: $error');
    }
  }

  /// Get user's assigned tasks  
  static Future<List<Map<String, dynamic>>> getMyTasks({String? status}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      String endpoint = '/tasks/my';
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tasksData = responseData['tasks'] ?? [];
        
        return tasksData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load tasks: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'My tasks error: $error',
        name: 'TaskService.getMyTasks',
        error: error,
      );
      throw Exception('Error fetching my tasks: $error');
    }
  }

  /// Get active tasks for current user
  static Future<List<Map<String, dynamic>>> getMyActiveTasks() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/my/active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tasksData = responseData['tasks'] ?? [];
        
        return tasksData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load active tasks: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Active tasks error: $error',
        name: 'TaskService.getMyActiveTasks',
        error: error,
      );
      throw Exception('Error fetching active tasks: $error');
    }
  }

  /// Update task status
  static Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.patch(
        Uri.parse('$_baseUrl/tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update task status: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Update task status error: $error',
        name: 'TaskService.updateTaskStatus',
        error: error,
      );
      throw Exception('Error updating task status: $error');
    }
  }
}