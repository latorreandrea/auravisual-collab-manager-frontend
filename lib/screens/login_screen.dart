import 'package:flutter/material.dart';
import '../widgets/login_form.dart';
import '../widgets/app_logo.dart';
import '../utils/constants.dart';

/// Login screen widget
/// This is a StatelessWidget because it doesn't manage state directly
/// State management is handled by child widgets (LoginForm)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color for the entire screen
      backgroundColor: Theme.of(context).colorScheme.surface,
      
      // SafeArea ensures content doesn't overlap with system UI (status bar, notches)
      body: SafeArea(
        child: SingleChildScrollView(
          // Add padding around the content
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          
          child: ConstrainedBox(
            // Ensure the content takes at least the full screen height
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom,
            ),
            
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacer to push content toward center
                SizedBox(height: AppConstants.largeSpacing),
                
                // App logo component (separated for reusability)
                AppLogo(),
                
                SizedBox(height: AppConstants.extraLargeSpacing),
                
                // Login form component
                LoginForm(),
                
                SizedBox(height: AppConstants.defaultSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}