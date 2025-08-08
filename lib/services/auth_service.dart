import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/user.dart';

/// Authentication service
/// Handles all authentication-related API calls
class AuthService {
  static const _storage = FlutterSecureStorage();

  /// Login user with email and password
  /// Returns User object if successful, throws exception if failed
  Future<User> login(String email, String password) async {
    try {
      // Prepare request body matching backend API
      final body = {
        'email': email,
        'password': password,
      };
      
      debugPrint('🔐 Attempting login for: $email');
      debugPrint('🌐 Using API: ${AppConstants.baseUrl}${AppConstants.loginEndpoint}');
      
      // Make API call to FastAPI backend
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );
      
      debugPrint('📡 Login response status: ${response.statusCode}');
      if (AppConstants.isDebug) {
        debugPrint('📡 Login response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        // Login successful - parse response
        final data = json.decode(response.body);
        
        // Store authentication token securely
        final token = data['access_token'] as String;
        await _storeToken(token);
        
        // Create user from response data
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        // Store user data
        await _storeUser(user);
        
        debugPrint('✅ Login successful for: ${user.email} (${user.role})');
        return user;
        
      } else {
        // Login failed - parse error
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Login failed';
        debugPrint('❌ Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (error) {
      debugPrint('❌ Login error: $error');
      
      // Re-throw with user-friendly message
      if (error.toString().contains('Connection refused') || 
          error.toString().contains('Network') ||
          error.toString().contains('SocketException')) {
        throw Exception('Connection error. Please check your internet connection.');
      }
      
      if (error.toString().contains('FormatException')) {
        throw Exception('Server response error. Please try again later.');
      }
      
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }
  
  /// Get current authenticated user info from API
  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.meEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['user'] as Map<String, dynamic>;
        return User.fromJson(userData);
      } else {
        // Token might be expired, clear stored data
        await _clearAuthData();
        return null;
      }
      
    } catch (error) {
      debugPrint('❌ Get user error: $error');
      return null;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      final token = await getToken();
      
      if (token != null) {
        // Call logout endpoint
        await http.post(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      
      // Clear stored data regardless of API call result
      await _clearAuthData();
      debugPrint('🚪 Logout successful');
      
    } catch (error) {
      debugPrint('⚠️ Logout API error (clearing local data anyway): $error');
      await _clearAuthData();
    }
  }
  
  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Get stored authentication token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (error) {
      debugPrint('Error reading token: $error');
      return null;
    }
  }
  
  /// Get stored user data
  Future<User?> getStoredUser() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson != null && userJson.isNotEmpty) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userData);
      }
      return null;
    } catch (error) {
      debugPrint('Error reading user data: $error');
      return null;
    }
  }
  
  /// Private helper: Store authentication token
  Future<void> _storeToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }
  
  /// Private helper: Store user data
  Future<void> _storeUser(User user) async {
    final userJson = json.encode(user.toJson());
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }
  
  /// Private helper: Clear all authentication data
  Future<void> _clearAuthData() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}