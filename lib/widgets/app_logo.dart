import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Reusable app logo widget
/// Can be used across different screens
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo container with decoration
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            // Use theme colors instead of hardcoded values
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // Add subtle shadow for depth - Fixed deprecated withOpacity
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.visibility,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultSpacing),
        
        // App name with consistent styling
        Text(
          'Auravisual',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        Text(
          'Collab Manager',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            // Fixed deprecated withOpacity
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}