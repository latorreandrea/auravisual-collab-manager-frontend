import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

/// Welcome screen - shown after successful login
/// Displays personalized greeting and user role (if not client)
class WelcomeScreen extends StatelessWidget {
  final User user;

  const WelcomeScreen({
    super.key, 
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar with logout
                _buildTopBar(context),
                
                // Main welcome content
                Expanded(
                  child: _buildWelcomeContent(context),
                ),
                
                // Bottom section
                _buildBottomSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App title
        Text(
          'Auravisual',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Logout button
        IconButton(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout),
          color: AppTheme.primaryColor,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Welcome icon/avatar
        _buildUserAvatar(),
        
        const SizedBox(height: AppConstants.extraLargeSpacing),
        
        // Welcome message
        _buildWelcomeMessage(context),
        
        const SizedBox(height: AppConstants.largeSpacing),
        
        // User info card
        _buildUserInfoCard(context),
        
        const SizedBox(height: AppConstants.extraLargeSpacing),
        
        // Quick actions (placeholder for future features)
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 120,
      height: 120,
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
            blurRadius: 20,
            offset: const Offset(0, 10),
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
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.smallSpacing),
        
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.darkColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Show role only if not client
        if (user.shouldShowRole) ...[
          const SizedBox(height: AppConstants.smallSpacing),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultSpacing,
              vertical: AppConstants.smallSpacing,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.gradientStart.withValues(alpha: 0.1),
                  AppTheme.gradientEnd.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.gradientEnd.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              user.roleDisplayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.gradientEnd,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.smallSpacing),
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultSpacing),
            
            _buildInfoRow('Email', user.email),
            if (user.username != null)
              _buildInfoRow('Username', user.username!),
            _buildInfoRow('Status', user.isActive ? 'Active' : 'Inactive'),
            if (user.createdAt != null)
              _buildInfoRow('Member since', _formatDate(user.createdAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallSpacing),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.smallSpacing),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultSpacing),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionButton(
                  icon: Icons.task_outlined,
                  label: 'Tasks',
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionButton(
                  icon: Icons.people_outlined,
                  label: 'Team',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.defaultSpacing,
          horizontal: AppConstants.smallSpacing,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultSpacing),
              decoration: BoxDecoration(
                color: AppTheme.gradientEnd.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.gradientEnd,
                size: 28,
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.darkColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Auravisual Collab Manager v1.0.0',
          style: TextStyle(
            color: AppTheme.darkColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        Text(
          'Ready to collaborate!',
          style: TextStyle(
            color: AppTheme.gradientEnd,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon! 🚀'),
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