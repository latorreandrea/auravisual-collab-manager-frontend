import 'package:flutter/material.dart';
import '../widgets/login_form.dart';
import '../widgets/app_logo.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

/// Login screen with AuraVisual branding - Full height layout
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove any potential scrolling issues
      resizeToAvoidBottomInset: true,
      body: Container(
        // Takes full screen height and width
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightColor,
              AppTheme.whiteColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centra tutto verticalmente
              children: [
                // Spacer superiore ridotto
                const Spacer(flex: 1),
                
                // Logo section - takes full width
                const AppLogo(
                  height: 120, // Increased height for better visibility
                  showText: true,
                ),
                
                // Spacing between logo and form
                const SizedBox(height: AppConstants.extraLargeSpacing),
                
                // Login form section - non più flexible, dimensione naturale
                const LoginForm(),
                
                // Spacer inferiore più grande per bilanciare
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}