import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import 'auth_service.dart';

/// Service for ticket-related API calls
class TicketService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Create a new ticket for a project (client only)
  static Future<Map<String, dynamic>> createTicket({
    required String projectId,
    required String message,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/client/projects/$projectId/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
        }),
      );

      developer.log(
        'Create ticket API call: POST /client/projects/$projectId/tickets',
        name: 'TicketService.createTicket',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        developer.log(
          'Ticket created successfully: ${responseData['ticket']?['id']}',
          name: 'TicketService.createTicket',
        );
        
        return responseData;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else if (response.statusCode == 404) {
        throw Exception('Project not found or you don\'t have access to it.');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception('Failed to create ticket: $errorMessage');
      }
    } catch (error) {
      developer.log(
        'Create ticket error: $error',
        name: 'TicketService.createTicket',
        error: error,
      );
      throw Exception('Error creating ticket: $error');
    }
  }

  /// Get client's tickets
  static Future<List<Map<String, dynamic>>> getClientTickets() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/client/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Get client tickets API call: GET /client/tickets',
        name: 'TicketService.getClientTickets',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ticketsData = responseData['tickets'] ?? [];
        
        return ticketsData.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else {
        throw Exception('Failed to load tickets: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Get client tickets error: $error',
        name: 'TicketService.getClientTickets',
        error: error,
      );
      throw Exception('Error fetching client tickets: $error');
    }
  }

  /// Get ticket details by ID
  static Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/client/tickets/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        'Get ticket details API call: GET /client/tickets/$ticketId',
        name: 'TicketService.getTicketDetails',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['ticket'] ?? responseData;
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Client authentication required.');
      } else if (response.statusCode == 404) {
        throw Exception('Ticket not found.');
      } else {
        throw Exception('Failed to load ticket details: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Get ticket details error: $error',
        name: 'TicketService.getTicketDetails',
        error: error,
      );
      throw Exception('Error fetching ticket details: $error');
    }
  }

  /// Update ticket status (admin only)
  static Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/tickets/$ticketId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      developer.log(
        'Update ticket status API call: PATCH /admin/tickets/$ticketId/status',
        name: 'TicketService.updateTicketStatus',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update ticket status: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'Update ticket status error: $error',
        name: 'TicketService.updateTicketStatus',
        error: error,
      );
      throw Exception('Error updating ticket status: $error');
    }
  }
}
