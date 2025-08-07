import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// Login form widget with state management
/// This is a StatefulWidget because it needs to manage form state,
/// loading states, and user input
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Form key for validation - allows us to validate the entire form at once
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers to get values from input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State variables
  bool _isPasswordVisible = false; // Controls password visibility toggle
  bool _isLoading = false; // Controls loading state during API calls
  
  // Service for authentication (we'll create this)
  final _authService = AuthService();

  @override
  void dispose() {
    // Clean up controllers when widget is removed from widget tree
    // This prevents memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process
  Future<void> _handleLogin() async {
    // Validate form before proceeding
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Get values from controllers
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Call authentication service
      final success = await _authService.login(email, password);

      if (success && mounted) {
        // Login successful - navigate to dashboard
        // TODO: Navigate to dashboard screen
        _showSnackBar('Login successful!', isError: false);
      }
    } catch (error) {
      // Handle login error
      if (mounted) {
        _showSnackBar('Login failed: ${error.toString()}', isError: true);
      }
    } finally {
      // Hide loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Helper method to show snackbar messages
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Theme.of(context).colorScheme.error
          : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Takes minimum space needed
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email input field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: Icon(Icons.email_outlined),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            validator: Validators.email,
          ),
          
          const SizedBox(height: AppConstants.defaultSpacing),
          
          // Password input field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible 
                    ? Icons.visibility_off_outlined 
                    : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: Validators.password,
          ),
          
          const SizedBox(height: AppConstants.largeSpacing),
          
          // Login button
          SizedBox(
            height: 56, // Fixed height for better touch target
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: AppConstants.defaultSpacing),
          
          // Register link
          TextButton(
            onPressed: _isLoading ? null : () {
              _showSnackBar('Registration screen coming soon!', isError: false);
            },
            child: Text(
              'Don\'t have an account? Sign up',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}