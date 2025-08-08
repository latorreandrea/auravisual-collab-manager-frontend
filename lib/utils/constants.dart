/// Application constants
/// Centralizing constants makes the app easier to maintain
class AppConstants {
  // Spacing constants - optimized for mobile screens
  static const double smallSpacing = 8.0;
  static const double defaultSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Padding constants - reduced for better space usage
  static const double defaultPadding = 20.0;
  static const double smallPadding = 12.0;
  
  // Environment configuration
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
  
  // API configuration - Legge da build flags o usa default
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.auravisual.dk',
  );
  
  // API endpoints
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  static const String registerEndpoint = '/auth/register';
  
  // Storage keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';
  
  // Other constants
  static const int animationDuration = 300; // milliseconds
  
  // Debug helper
  static bool get isDebug => environment == 'development';
  
}