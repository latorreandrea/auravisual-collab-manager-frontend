import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdminTicketService {
  static const String baseUrl = 'https://app.auravisual.dk';
  final AuthService _authService = AuthService();

  /// Get all tickets for admin (filtering for to_read and processing)
  Future<List<Map<String, dynamic>>> getAdminTickets({String? status}) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Get tickets from admin/projects endpoint which includes open tickets
      final response = await http.get(
        Uri.parse('$baseUrl/admin/projects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projects = List<Map<String, dynamic>>.from(data['projects'] ?? []);
        
        // Extract all open tickets from all projects
        final List<Map<String, dynamic>> allTickets = [];
        for (final project in projects) {
          final openTickets = List<Map<String, dynamic>>.from(project['open_tickets'] ?? []);
          for (final ticket in openTickets) {
            // Add project and client info to ticket
            ticket['project'] = {
              'id': project['id'],
              'name': project['name'],
              'status': project['status'],
            };
            ticket['client'] = project['client'];
            allTickets.add(ticket);
          }
        }
        
        return allTickets;
      } else {
        throw Exception('Error loading tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get tickets with to_read and processing status
  Future<List<Map<String, dynamic>>> getTicketsForAdmin() async {
    try {
      final allTickets = await getAdminTickets();
      
      // Filter for tickets that admin can work on
      return allTickets.where((ticket) {
        final status = ticket['status'] ?? '';
        return status == 'to_read' || status == 'processing';
      }).toList();
    } catch (e) {
      throw Exception('Error loading tickets: $e');
    }
  }

  /// Get detailed ticket information
  Future<Map<String, dynamic>?> getTicketDetails(String ticketId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Use client endpoint but with admin token to get ticket details
      final response = await http.get(
        Uri.parse('$baseUrl/client/tickets/$ticketId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ticket'];
      } else {
        throw Exception('Error loading ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Update ticket status to processing - This happens automatically when tasks are created
  /// So we don't need a separate endpoint, just create tasks directly
  Future<bool> updateTicketStatusToProcessing(String ticketId) async {
    // According to the API docs, ticket status changes to 'processing' automatically
    // when tasks are created via POST /admin/tickets/{id}/tasks
    // So this method is not needed, but we keep it for UI consistency
    return true;
  }

  /// Create bulk tasks for a ticket
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
        return data;
      } else {
        throw Exception('Error creating tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Get all staff members for task assignment
  Future<List<Map<String, dynamic>>> getStaffMembers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Get both staff and admin users for task assignment
      final [staffResponse, usersResponse] = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/admin/users/staff'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        http.get(
          Uri.parse('$baseUrl/admin/users'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      ]);

      final List<Map<String, dynamic>> allAssignableUsers = [];
      
      // Add staff members
      if (staffResponse.statusCode == 200) {
        final staffData = json.decode(staffResponse.body);
        allAssignableUsers.addAll(List<Map<String, dynamic>>.from(staffData['staff'] ?? []));
      }
      
      // Add admin users
      if (usersResponse.statusCode == 200) {
        final usersData = json.decode(usersResponse.body);
        final users = List<Map<String, dynamic>>.from(usersData['users'] ?? []);
        final admins = users.where((user) => user['role'] == 'admin').toList();
        allAssignableUsers.addAll(admins);
      }

      return allAssignableUsers;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
