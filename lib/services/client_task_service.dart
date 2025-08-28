import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import 'auth_service.dart';

/// Service for client task statistics and progress tracking
class ClientTaskService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get task statistics for all client projects
  static Future<Map<String, ProjectTaskStats>> getProjectTaskStats() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      // Get all client tickets which contain task information
      final response = await http.get(
        Uri.parse('$_baseUrl/client/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Client tickets API call: GET /client/tickets',
        name: 'ClientTaskService.getProjectTaskStats',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ticketsData = responseData['tickets'] ?? [];
        
        // Group tasks by project and calculate statistics
        Map<String, ProjectTaskStats> projectStats = {};
        
        for (final ticketJson in ticketsData) {
          final ticket = ticketJson as Map<String, dynamic>;
          final project = ticket['project'] as Map<String, dynamic>?;
          if (project == null) continue;
          
          final projectId = project['id'] as String;
          final projectName = project['name'] as String;
          
          // Initialize project stats if not exists
          if (!projectStats.containsKey(projectId)) {
            projectStats[projectId] = ProjectTaskStats(
              projectId: projectId,
              projectName: projectName,
              activeTasks: 0,
              completedTasks: 0,
              totalTasks: 0,
            );
          }
          
          // Count tasks in this ticket
          final tasks = ticket['tasks'] as List<dynamic>? ?? [];
          for (final taskJson in tasks) {
            final task = taskJson as Map<String, dynamic>;
            final status = task['status'] as String? ?? '';
            
            projectStats[projectId] = projectStats[projectId]!.copyWith(
              totalTasks: projectStats[projectId]!.totalTasks + 1,
              activeTasks: status == 'in_progress' 
                  ? projectStats[projectId]!.activeTasks + 1 
                  : projectStats[projectId]!.activeTasks,
              completedTasks: status == 'completed' 
                  ? projectStats[projectId]!.completedTasks + 1 
                  : projectStats[projectId]!.completedTasks,
            );
          }
        }
        
        return projectStats;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else {
        throw Exception('Failed to load task statistics: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Client task stats error: $error',
        name: 'ClientTaskService.getProjectTaskStats',
        error: error,
      );
      throw Exception('Error fetching task statistics: $error');
    }
  }

  /// Get task statistics for a specific project
  static Future<ProjectTaskStats?> getProjectTaskStatsById(String projectId) async {
    try {
      final allStats = await getProjectTaskStats();
      return allStats[projectId];
    } catch (error) {
      developer.log(
        'Error getting task stats for project $projectId: $error',
        name: 'ClientTaskService.getProjectTaskStatsById',
        error: error,
      );
      return null;
    }
  }
}

/// Model for project task statistics
class ProjectTaskStats {
  final String projectId;
  final String projectName;
  final int activeTasks;
  final int completedTasks;
  final int totalTasks;

  const ProjectTaskStats({
    required this.projectId,
    required this.projectName,
    required this.activeTasks,
    required this.completedTasks,
    required this.totalTasks,
  });

  /// Calculate completion percentage
  double get completionPercentage {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  /// Check if project has active work
  bool get hasActiveWork => activeTasks > 0;

  /// Copy with new values
  ProjectTaskStats copyWith({
    String? projectId,
    String? projectName,
    int? activeTasks,
    int? completedTasks,
    int? totalTasks,
  }) {
    return ProjectTaskStats(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      activeTasks: activeTasks ?? this.activeTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
    );
  }

  @override
  String toString() {
    return 'ProjectTaskStats(projectId: $projectId, name: $projectName, '
           'active: $activeTasks, completed: $completedTasks, total: $totalTasks)';
  }
}
