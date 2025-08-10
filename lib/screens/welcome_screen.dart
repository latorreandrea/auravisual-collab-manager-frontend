import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Reusable Navigation Bar
                AppNavBar(
                  user: user,
                  onHomePressed: () => _refreshPage(context),
                  onProfilePressed: () => _showComingSoon(context, 'Profile feature coming soon! 👤'),
                ),
                
                const SizedBox(height: 40),
                
                // Avatar
                _buildUserAvatar(),
                
                const SizedBox(height: 32),
                
                // Welcome message
                _buildWelcomeMessage(context),
                
                const SizedBox(height: 32),
                
                // Insights card
                _buildInsightsCard(context),
                
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(context),
                
                const SizedBox(height: 40),
                
                // Bottom section
                _buildBottomSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshPage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Welcome screen refreshed! 🔄'),
        backgroundColor: AppTheme.gradientEnd,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildUserAvatar() {
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
        
        const SizedBox(height: 8),
        
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
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
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

  Widget _buildInsightsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Card(
        elevation: 8,
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Show insights based on user role
              if (user.isAdmin) ...[
                _buildInsightRow('Clients', 'TODO: total clients'),
                _buildInsightRow('Projects', 'TODO: total projects'),
                _buildInsightRow('Active Tasks', 'TODO: active tasks'),
                _buildInsightRow('Tickets', 'TODO: total tickets'),
              ] else if (user.isStaff) ...[
                _buildInsightRow('Projects', 'TODO: total projects'),
                _buildInsightRow('Completed Tasks', 'TODO: completed tasks'),
                _buildInsightRow('Pending Tasks', 'TODO: tasks to complete'),
              ] else if (user.isClient) ...[
                _buildInsightRow('Project(s)', 'TODO: project names'),
                _buildInsightRow('Subscribed Projects', 'TODO: number of projects'),
                _buildInsightRow('Plan', 'TODO: plan name'),
                _buildInsightRow('Open Tasks', 'TODO: open tasks'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
    return Container(
      width: double.infinity,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
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
          vertical: 16,
          horizontal: 12,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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

  void _showComingSoon(BuildContext context, [String? customMessage]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? 'Feature coming soon! 🚀'),
        backgroundColor: AppTheme.gradientEnd,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}