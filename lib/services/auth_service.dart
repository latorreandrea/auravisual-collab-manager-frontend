import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Authentication service
/// Handles all authentication-related API calls
class AuthService {
  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    try {
      // Prepare request body
      final body = {
        'email': email,
        'password': password,
      };
      
      // Make API call to your backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        // Login successful
        final data = json.decode(response.body);
        
        // Store authentication token
        final token = data['access_token'] as String?;
        // if (token != null) {
        //   // TODO: Store token using secure storage
        //   // await _storeToken(token);
        //   print('Token received: $token'); // Temporary debug print
        // }
        
        return true;
      } else {
        // Login failed
        throw Exception('Invalid credentials');
      }
    } catch (error) {
      // Network or other errors
      throw Exception('Network error: $error');
    }
  }
  
  /// Register new user
  Future<bool> register(String email, String password, String name) async {
    // TODO: Implement registration
    throw UnimplementedError('Registration not implemented yet');
  }
  
  /// Logout user
  Future<void> logout() async {
    // TODO: Implement logout
    // Clear stored tokens, etc.
    throw UnimplementedError('Logout not implemented yet');
  }
}