import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

/// Reusable app logo widget using actual AuraVisual logo
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 100, 
    this.showText = false,
  });

  final double height; 
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal logo container that takes full width
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: height, 
            minHeight: 60, // Minimum height for smaller screens
          ),
          
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain, // Maintains proportions, shows entire logo
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback with fixed height
                return Container(
                  height: height, // Use 'height' instead of 'maxHeight'
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.gradientStart,
                        AppTheme.gradientEnd,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'AURAVISUAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: AppConstants.smallSpacing),
          
          // Subtitle text (optional)
          Text(
            'Collab Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor, 
              fontWeight: FontWeight.bold, 
              fontSize: 20, 
            ),
          ),
        ],
      
        // Spacing below the logo
        const SizedBox(height: AppConstants.extraLargeSpacing),
      ],
    );
  }
}