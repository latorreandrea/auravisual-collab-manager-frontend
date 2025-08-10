import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

/// The main entry point of the application
/// This function is called when the app starts
void main() {
  runApp(const AuravisualApp());
}

/// Root widget of the application
/// This is a StatelessWidget because it doesn't need to manage state
class AuravisualApp extends StatelessWidget {
  const AuravisualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App title shown in task switcher (Android) or window title (desktop)
      title: 'Auravisual Collab Manager',
      
      // Custom theme configuration - separated for better maintainability
      theme: AppTheme.lightTheme,
      
      // Dark theme support (optional)
      darkTheme: AppTheme.darkTheme,
      
      // Follow system theme by default
      themeMode: ThemeMode.system,
      
      // Starting screen of the app
      home: const LoginScreen(),
      
      // Show debug banner only in development
      debugShowCheckedModeBanner: AppConstants.isDebug,
      
      // App-wide navigation routes (we'll add more screens later)
      routes: {
        '/login': (context) => const LoginScreen(),
        // TODO: Add more routes here as we create new screens
        // '/dashboard': (context) => const DashboardScreen(),
        // '/projects': (context) => const ProjectsScreen(),
      },
    );
  }
}