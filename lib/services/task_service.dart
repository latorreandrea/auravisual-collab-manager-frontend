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

  /// Get client's tasks from their tickets with active timer information
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
        
        // Get active timers for client's tasks to show work status
        try {
          final activeTimers = await getClientActiveTimers();
          for (final task in allTasks) {
            final taskId = task['id']?.toString();
            if (taskId != null && activeTimers.containsKey(taskId)) {
              task['active_timer'] = activeTimers[taskId];
              task['is_being_worked_on'] = true;
            } else {
              task['is_being_worked_on'] = false;
            }
          }
        } catch (e) {
          developer.log(
            'Could not fetch active timers for client tasks: $e',
            name: 'TaskService.getClientTasks',
          );
          // Continue without timer info if API call fails
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

  /// Start timer for a task - creates a new time tracking session
  static Future<void> startTaskTimer(String taskId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/timer/start'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}), // Empty body object
      );

      developer.log(
        'Start timer response - Status: ${response.statusCode}, Body: ${response.body}',
        name: 'TaskService.startTaskTimer',
      );

      if (response.statusCode == 422) {
        throw Exception('Validation error: ${response.body}');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to start task timer: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      developer.log(
        'Start task timer error: $error',
        name: 'TaskService.startTaskTimer',
        error: error,
      );
      throw Exception('Error starting task timer: $error');
    }
  }

  /// Stop timer for a task - completes the active time tracking session
  static Future<void> stopTaskTimer(String taskId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/timer/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}), // Empty body object
      );

      developer.log(
        'Stop timer response - Status: ${response.statusCode}, Body: ${response.body}',
        name: 'TaskService.stopTaskTimer',
      );

      if (response.statusCode == 422) {
        throw Exception('Validation error: ${response.body}');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to stop task timer: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      developer.log(
        'Stop timer error: $error',
        name: 'TaskService.stopTaskTimer',
        error: error,
      );
      throw Exception('Error stopping task timer: $error');
    }
  }

  /// Pause timer for a task - temporarily stops time tracking session
  static Future<void> pauseTaskTimer(String taskId, {String? note}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/timer/pause'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (note != null) 'note': note,
        }),
      );

      developer.log(
        'Pause timer response - Status: ${response.statusCode}, Body: ${response.body}',
        name: 'TaskService.pauseTaskTimer',
      );

      if (response.statusCode == 422) {
        throw Exception('Validation error: ${response.body}');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to pause task timer: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      developer.log(
        'Pause timer error: $error',
        name: 'TaskService.pauseTaskTimer',
        error: error,
      );
      throw Exception('Error pausing task timer: $error');
    }
  }

  /// Resume timer for a task - continues time tracking session after pause
  static Future<void> resumeTaskTimer(String taskId, {String? note}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/timer/resume'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (note != null) 'note': note,
        }),
      );

      developer.log(
        'Resume timer response - Status: ${response.statusCode}, Body: ${response.body}',
        name: 'TaskService.resumeTaskTimer',
      );

      if (response.statusCode == 422) {
        throw Exception('Validation error: ${response.body}');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to resume task timer: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      developer.log(
        'Resume timer error: $error',
        name: 'TaskService.resumeTaskTimer',
        error: error,
      );
      throw Exception('Error resuming task timer: $error');
    }
  }

  /// Get time summary for current user's tasks (includes active timer info)
  static Future<Map<String, dynamic>> getMyTimeSummary() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/my/time-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get time summary: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Time summary error: $error',
        name: 'TaskService.getMyTimeSummary',
        error: error,
      );
      throw Exception('Error getting time summary: $error');
    }
  }

  /// Check if user has an active timer for any task using time summary
  static Future<Map<String, dynamic>?> getActiveTimer() async {
    try {
      final timeSummary = await getMyTimeSummary();
      final tasks = timeSummary['tasks'] as List<dynamic>? ?? [];
      
      // Find task with active timer
      for (final task in tasks) {
        final hasActiveTimer = task['has_active_timer'] == true;
        if (hasActiveTimer) {          
          return {
            'task_id': task['task_id'],
            'task_title': task['task_title'],
            'start_time': DateTime.now().toIso8601String(),
            'status': 'active', // Default to active, UI will manage pause state locally
          };
        }
      }
      
      return null;
    } catch (error) {
      developer.log(
        'Get active timer error: $error',
        name: 'TaskService.getActiveTimer',
        error: error,
      );
      // Return null instead of throwing error to allow graceful handling
      return null;
    }
  }

  /// Get time logs for a specific task (admin only)
  static Future<List<Map<String, dynamic>>> getTaskTimeLogs(String taskId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$taskId/time-logs'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> timeLogsData = responseData['time_logs'] ?? [];
        return timeLogsData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get task time logs: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Get task time logs error: $error',
        name: 'TaskService.getTaskTimeLogs',
        error: error,
      );
      throw Exception('Error getting task time logs: $error');
    }
  }

  /// Get active timers for client's tasks (for transparency)
  static Future<Map<String, Map<String, dynamic>>> getClientActiveTimers() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/client/active-timers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> timersData = responseData['active_timers'] ?? [];
        
        // Convert to Map with task_id as key
        Map<String, Map<String, dynamic>> timersMap = {};
        for (final timer in timersData) {
          final taskId = timer['task_id']?.toString();
          if (taskId != null) {
            timersMap[taskId] = Map<String, dynamic>.from(timer);
          }
        }
        
        return timersMap;
      } else if (response.statusCode == 404) {
        // No active timers found
        return {};
      } else {
        throw Exception('Failed to get client active timers: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Get client active timers error: $error',
        name: 'TaskService.getClientActiveTimers',
        error: error,
      );
      // Return empty map instead of throwing error to allow graceful handling
      return {};
    }
  }
}