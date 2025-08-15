import 'dart:convert';
import 'package:http/http.dart' as http;
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
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching tasks: $error');
    }
  }

  /// Get tasks filtered by status
  static Future<List<Map<String, dynamic>>> getTasksByStatus(String status) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/tasks?status=$status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load tasks by status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching tasks by status: $error');
    }
  }

  /// Get tasks assigned to a specific user
  static Future<List<Map<String, dynamic>>> getTasksByUser(String userId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/tasks?assigned_to=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load tasks by user: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching tasks by user: $error');
    }
  }

  /// Get active tasks count for each team member
  static Future<Map<String, int>> getActiveTasksCountByUser() async {
    try {
      final allTasks = await getTasksByStatus('in_progress');
      final Map<String, int> taskCounts = {};

      for (final task in allTasks) {
        final assignedTo = task['assigned_to']?.toString();
        if (assignedTo != null && assignedTo.isNotEmpty) {
          taskCounts[assignedTo] = (taskCounts[assignedTo] ?? 0) + 1;
        }
      }

      return taskCounts;
    } catch (error) {
      throw Exception('Error calculating task counts: $error');
    }
  }
}