import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

/// Reusable navigation bar widget for the app
/// Contains logo, navigation icons, and user actions
class AppNavBar extends StatelessWidget {
  final User user;
  final VoidCallback? onHomePressed;
  final VoidCallback? onProfilePressed;

  const AppNavBar({
    super.key,
    required this.user,
    this.onHomePressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/Brand section
          _buildBrandSection(),
          
          // Navigation icons
          _buildNavigationSection(context),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gradientStart,
                AppTheme.gradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.visibility,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'AuraVisual',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Row(
      children: [
        // Home icon
        _buildNavButton(
          context: context,
          icon: Icons.home_outlined,
          tooltip: 'Home',
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.gradientEnd.withValues(alpha: 0.1),
          onPressed: onHomePressed ?? () => _defaultHomeAction(context),
        ),
        
        const SizedBox(width: 8),
        
        // User profile icon
        _buildNavButton(
          context: context,
          icon: Icons.person_outlined,
          tooltip: 'Profile',
          color: AppTheme.primaryColor,
          backgroundColor: AppTheme.gradientEnd.withValues(alpha: 0.1),
          onPressed: onProfilePressed ?? () => _openUserProfile(context),
        ),
        
        const SizedBox(width: 8),
        
        // Logout icon
        _buildNavButton(
          context: context,
          icon: Icons.logout_outlined,
          tooltip: 'Logout',
          color: Colors.red,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: color,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Default actions
  void _defaultHomeAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Page refreshed! 🔄'),
        backgroundColor: AppTheme.gradientEnd,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserProfileModal(context),
    );
  }

  Widget _buildUserProfileModal(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modal header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: AppTheme.darkColor,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // User avatar
          _buildModalUserAvatar(),
          
          const SizedBox(height: 24),
          
          // User information
          _buildProfileInfo(context),
          
          const Spacer(),
          
          // Edit profile button
          _buildEditProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildModalUserAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.gradientStart,
            AppTheme.gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.displayName.isNotEmpty 
            ? user.displayName.substring(0, 1).toUpperCase()
            : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileInfoRow('Name', user.displayName),
            _buildProfileInfoRow('Email', user.email),
            if (user.shouldShowRole)
              _buildProfileInfoRow('Role', user.roleDisplayName),
            _buildProfileInfoRow('Member since', 'January 2024'), // TODO: real date
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.darkColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.darkColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showComingSoon(context, 'Profile editing feature coming soon! ✏️');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.gradientEnd,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, [String? customMessage]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? 'Feature coming soon! 🚀'),
        backgroundColor: AppTheme.gradientEnd,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().logout();
      
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}