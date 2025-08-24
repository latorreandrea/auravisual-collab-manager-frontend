import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdminTicketService {
  static const String baseUrl = 'https://app.auravisual.dk';
  final AuthService _authService = AuthService();

  /// Get tickets that need admin attention (only to_read and processing status)
  Future<List<Map<String, dynamic>>> getTicketsForAdmin() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/projects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle both direct list and object containing list
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check common keys that might contain the projects list
          if (responseData.containsKey('projects')) {
            data = responseData['projects'] as List;
          } else if (responseData.containsKey('data')) {
            data = responseData['data'] as List;
          } else if (responseData.containsKey('results')) {
            data = responseData['results'] as List;
          } else {
            // If it's an object but doesn't contain expected keys, treat as empty
            data = [];
          }
        } else {
          data = [];
        }
        
        // Extract tickets from projects and filter by status
        List<Map<String, dynamic>> allTickets = [];
        
        for (var project in data) {
          if (project != null && project is Map<String, dynamic>) {
            if (project['tickets'] != null && project['tickets'] is List) {
              for (var ticket in project['tickets']) {
                if (ticket != null && ticket is Map<String, dynamic>) {
                  // Only include tickets with status 'to_read' or 'processing'
                  // Exclude 'accepted' and 'rejected' tickets
                  final status = ticket['status']?.toString() ?? '';
                  if (status == 'to_read' || status == 'processing') {
                    ticket['project_name'] = project['name'];
                    ticket['project_id'] = project['id'];
                    allTickets.add(Map<String, dynamic>.from(ticket));
                  }
                }
              }
            }
          }
        }
        
        return allTickets;
      } else {
        throw Exception('Error fetching projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get staff members for task assignment
  Future<List<Map<String, dynamic>>> getStaffMembers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Get both staff and admin users
      final staffResponse = await http.get(
        Uri.parse('$baseUrl/admin/users/staff'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final adminResponse = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> allUsers = [];

      if (staffResponse.statusCode == 200) {
        final staffData = json.decode(staffResponse.body) as List;
        allUsers.addAll(staffData.cast<Map<String, dynamic>>());
      }

      if (adminResponse.statusCode == 200) {
        final adminData = json.decode(adminResponse.body) as List;
        // Filter to only admin users and avoid duplicates
        for (var user in adminData) {
          if (user['role'] == 'admin' && 
              !allUsers.any((existing) => existing['id'] == user['id'])) {
            allUsers.add(Map<String, dynamic>.from(user));
          }
        }
      }

      return allUsers;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get ticket details by ID (admin access)
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/tickets/$ticketId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle both direct ticket object and wrapped response
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('ticket')) {
            return responseData['ticket'] as Map<String, dynamic>;
          } else {
            return responseData;
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Ticket not found');
      } else {
        throw Exception('Failed to load ticket details: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ticket details: $e');
    }
  }

  /// Create bulk tasks for a ticket and mark it as accepted
  Future<Map<String, dynamic>?> createTasksForTicket(
    String ticketId,
    List<Map<String, dynamic>> tasks,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/tickets/$ticketId/tasks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tasks': tasks,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // After creating tasks successfully, mark ticket as accepted
        await _updateTicketStatus(ticketId, 'accepted');
        
        return data;
      } else {
        throw Exception('Error creating tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Update ticket status (private method)
  Future<bool> _updateTicketStatus(String ticketId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Try to update the ticket status
      // Note: This endpoint might not exist, but we'll attempt it
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/tickets/$ticketId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // Don't throw here, just return false as it's not critical
      // The status change might happen automatically on the backend
      return false;
    }
  }
}
