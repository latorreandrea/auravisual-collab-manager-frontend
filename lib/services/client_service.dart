import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/constants.dart';
import '../models/client.dart';
import 'auth_service.dart';

/// Service for client-related API calls
class ClientService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get all clients with project statistics (admin only)
  static Future<List<Client>> getAllClients() async {
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
        
        return clientsData.map((clientJson) => Client.fromJson(clientJson)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. Admin privileges required.');
      } else {
        throw Exception('Failed to load clients: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'ClientService Error: $error',
        name: 'ClientService.getAllClients',
        error: error,
      );
      throw Exception('Error fetching clients: $error');
    }
  }

  /// Create a new client (admin only)
  static Future<Client> createClient(CreateClientRequest request) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      developer.log(
        'Create client request: ${request.toJson()}',
        name: 'ClientService.createClient',
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // The registration endpoint returns the created user data
        final userData = responseData['user'] ?? responseData;
        
        // Convert to Client model (with zero project counts for new clients)
        return Client(
          id: userData['id']?.toString() ?? '',
          email: userData['email'] ?? request.email,
          username: userData['username'] ?? '',
          fullName: userData['full_name'] ?? request.fullName,
          role: userData['role'] ?? 'client',
          isActive: userData['is_active'] ?? true,
          activeProjectsCount: 0, // New clients have no projects
          totalProjectsCount: 0,
          createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
          updatedAt: userData['updated_at'] != null 
              ? DateTime.tryParse(userData['updated_at']) 
              : null,
        );
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception('Invalid client data: ${errorData['detail'] ?? 'Unknown error'}');
      } else if (response.statusCode == 409) {
        throw Exception('A client with this email already exists');
      } else {
        throw Exception('Failed to create client: HTTP ${response.statusCode}');
      }
    } catch (error) {
      developer.log(
        'ClientService Create Error: $error',
        name: 'ClientService.createClient',
        error: error,
      );
      throw Exception('Error creating client: $error');
    }
  }

  

  /// Get client statistics for dashboard
  static Future<Map<String, dynamic>> getClientStatistics() async {
    try {
      final clients = await getAllClients();
      
      final totalClients = clients.length;
      final activeClients = clients.where((c) => c.isActive).length;
      final clientsWithProjects = clients.where((c) => c.activeProjectsCount > 0).length;
      final totalActiveProjects = clients.fold<int>(
        0, (sum, client) => sum + client.activeProjectsCount,
      );
      final totalProjects = clients.fold<int>(
        0, (sum, client) => sum + client.totalProjectsCount,
      );
      
      return {
        'total_clients': totalClients,
        'active_clients': activeClients,
        'clients_with_projects': clientsWithProjects,
        'total_active_projects': totalActiveProjects,
        'total_projects': totalProjects,
        'average_projects_per_client': totalClients > 0 
            ? (totalActiveProjects / totalClients).toStringAsFixed(1) 
            : '0',
      };
    } catch (error) {
      developer.log(
        'Error calculating client statistics: $error',
        name: 'ClientService.getClientStatistics',
        error: error,
      );
      throw Exception('Error calculating client statistics: $error');
    }
  }
}

/// Request model for creating a new client
class CreateClientRequest {
  final String email;
  final String password;
  final String fullName;

  const CreateClientRequest({
    required this.email,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': 'client',
    };
  }
}