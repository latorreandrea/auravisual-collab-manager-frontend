/// App-wide constants
/// Centralizing constants makes the app easier to maintain
class AppConstants {
  // Spacing constants
  static const double smallSpacing = 8.0;
  static const double defaultSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Padding constants
  static const double defaultPadding = 24.0;
  static const double smallPadding = 16.0;
  
  // API endpoints (you'll need to update these with your backend URLs)
  static const String baseUrl = 'https://your-backend-url.com/api';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  
  // Other constants
  static const int animationDuration = 300; // milliseconds
}