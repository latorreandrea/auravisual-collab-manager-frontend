import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import '../models/team_member.dart';
import 'auth_service.dart';

/// Service for staff-related API calls
class StaffService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get all internal staff members with task statistics (admin only)
  /// Uses the real API endpoint: GET /admin/users/staff
  static Future<List<TeamMember>> getStaffMembers() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> staffData = responseData['staff'] ?? [];
        
        return staffData.map((staffJson) => TeamMember.fromJson(staffJson)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load staff: HTTP ${response.statusCode}');
      }
    } catch (error) {
      // Log the error for debugging
      developer.log(
        'StaffService Error: $error',
        name: 'StaffService.getStaffMembers',
        error: error,
      );
      throw Exception('Error fetching staff members: $error');
    }
  }

  /// Refresh a specific staff member's task count
  /// This could be useful for real-time updates
  static Future<TeamMember?> refreshStaffMemberTasks(String staffId) async {
    try {
      final allStaff = await getStaffMembers();
      return allStaff.firstWhere(
        (member) => member.id == staffId,
        orElse: () => throw Exception('Staff member not found'),
      );
    } catch (error) {
      developer.log(
        'Error refreshing staff member tasks: $error',
        name: 'StaffService.refreshStaffMemberTasks',
        error: error,
      );
      return null;
    }
  }

  /// Get staff statistics for dashboard
  static Future<Map<String, dynamic>> getStaffStatistics() async {
    try {
      final staffMembers = await getStaffMembers();
      
      final totalStaff = staffMembers.length;
      final totalActiveTasks = staffMembers.fold<int>(
        0, (sum, member) => sum + member.activeTasks,
      );
      final totalAssignedTasks = staffMembers.fold<int>(
        0, (sum, member) => sum + member.totalTasks,
      );
      final availableMembers = staffMembers.where((m) => m.activeTasks == 0).length;
      final busyMembers = staffMembers.where((m) => m.activeTasks > 5).length;
      
      return {
        'total_staff': totalStaff,
        'total_active_tasks': totalActiveTasks,
        'total_assigned_tasks': totalAssignedTasks,
        'available_members': availableMembers,
        'busy_members': busyMembers,
        'average_workload': totalStaff > 0 ? (totalActiveTasks / totalStaff).toStringAsFixed(1) : '0',
      };
    } catch (error) {
      throw Exception('Error calculating staff statistics: $error');
    }
  }
}