import 'package:flutter/material.dart';

/// App-wide theme configuration
/// Centralizing theme makes it easy to maintain consistent styling
class AppTheme {
  // Primary color palette for the app
  static const Color primaryColor = Color.fromARGB(255, 0, 3, 134); // Indigo
  static const Color secondaryColor = Color.fromRGBO(19,113,245,1.000); // Purple
  static const Color surfaceColor = Color.fromRGBO(248,249,251,1.000); // Light gray
  static const Color errorColor = Color(0xFFEF4444); // Red
  
  // Gradient colors (aggiungi queste costanti mancanti)
  static const Color gradientStart = Color.fromRGBO(51,56,124,1.000); // Same as primaryColor
  static const Color gradientEnd = Color.fromRGBO(39,175,155,1.000); // Same as secondaryColor
  static const Color darkColor = Color(0xFF1F2937); // Dark gray for text
  
  static const Color lightColor = Color(0xFFF8FAFC); // Light background - same as surfaceColor
  static const Color whiteColor = Color(0xFFFFFFFF); // Pure white

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      // Use Material 3 design system
      useMaterial3: true,
      
      // Color scheme definition
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        error: errorColor,
      ),
      
      // App bar styling
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      
      // Elevated button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input field styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
      ),
    );
  }
  
  /// Dark theme configuration (for future implementation)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}