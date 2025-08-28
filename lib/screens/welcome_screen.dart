import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';
import 'team_screen.dart';
import 'projects_screen.dart';
import 'client_projects_screen.dart';
import 'client_tasks_screen.dart';
import 'create_ticket_screen.dart';
import 'staff_tasks_screen.dart';

/// Welcome screen - shown after successful login
/// Displays personalized greeting and user role (if not client)
class WelcomeScreen extends StatefulWidget {
  final User user;

  const WelcomeScreen({
    super.key, 
    required this.user,
  });

    @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  DashboardData? dashboardData;
  ClientDashboardData? clientData;
  StaffDashboardData? staffData;
  bool isLoadingInsights = true;
  String? insightsError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        isLoadingInsights = true;
        insightsError = null;
      });

      if (widget.user.isAdmin) {
        final data = await DashboardService.getDashboardData();
        setState(() {
          dashboardData = data;
          isLoadingInsights = false;
        });
      } else if (widget.user.isClient) {
        final data = await DashboardService.getClientDashboardData();
        setState(() {
          clientData = data;
          isLoadingInsights = false;
        });
      } else if (widget.user.isStaff) {
        final data = await DashboardService.getStaffDashboardData();
        setState(() {
          staffData = data;
          isLoadingInsights = false;
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dashboard data loaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      setState(() {
        insightsError = error.toString();
        isLoadingInsights = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Failed to load insights: ${error.toString()}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadDashboardData,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Reusable Navigation Bar
                  AppNavBar(
                    user: widget.user,
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
                  
                  // Insights card with real data
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
      ),
    );
  }

  void _refreshPage(BuildContext context) {
    _loadDashboardData();
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
          widget.user.displayName.isNotEmpty 
            ? widget.user.displayName.substring(0, 1).toUpperCase()
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
          widget.user.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.darkColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Show role only if not client
        if (widget.user.shouldShowRole) ...[
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
              widget.user.roleDisplayName,
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
                    'Live Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Live indicator
                  if (!isLoadingInsights && insightsError == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading state
              if (isLoadingInsights)
                _buildInsightsLoading()
              // Error state
              else if (insightsError != null)
                _buildInsightsError()
              // Data loaded successfully
              else
                _buildInsightsData(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsLoading() {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading insights...',
            style: TextStyle(
              color: AppTheme.darkColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load insights. Please check your connection.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadDashboardData,
            child: Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsData() {
    if (widget.user.isAdmin && dashboardData != null) {
      return Column(
        children: [
          _buildInsightRow('Clients', '${dashboardData!.totalClients}'),
          _buildInsightRow('Projects', '${dashboardData!.totalProjects} (${dashboardData!.activeProjects} active)'),
          _buildInsightRow('Active Tasks', '${dashboardData!.activeTasks}'),
          _buildInsightRow('Open Tickets', '${dashboardData!.openTickets}'),
          _buildInsightRow('Staff Members', '${dashboardData!.totalStaff}'),
        ],
      );
    } else if (widget.user.isStaff && staffData != null) {
      return Column(
        children: [
          _buildInsightRow('Your Projects', '${staffData!.totalProjects}'),
          _buildInsightRow('Active Tasks', '${staffData!.activeTasks}'),
          _buildInsightRow('Completed Tasks', '${staffData!.completedTasks}'),
          _buildInsightRow('Total Tasks', '${staffData!.activeTasks + staffData!.completedTasks}'),
        ],
      );
    } else if (widget.user.isClient && clientData != null) {
      return Column(
        children: [
          _buildInsightRow('Your Projects', 
              clientData!.projectNames.isNotEmpty 
                  ? clientData!.projectNames.join(', ')
                  : 'No projects assigned'),
          _buildInsightRow('Total Projects', '${clientData!.totalProjects}'),
          _buildInsightRow('Open Tickets', '${clientData!.openTicketsCount}'),
          if (clientData!.totalTasks > 0) ...[
            _buildInsightRow('Active Tasks', '${clientData!.activeTasks}'),
            _buildInsightRow('Completed Tasks', '${clientData!.completedTasks}'),
          ],
          _buildInsightRow('Current Plan', clientData!.primaryPlan),
        ],
      );
    }

    return Text(
      'No insights available',
      style: TextStyle(
        color: AppTheme.darkColor.withValues(alpha: 0.6),
        fontSize: 14,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
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

              // Different button layout based on user role
            widget.user.isClient ? _buildClientQuickActions() : _buildAdminStaffQuickActions(),
          ],
        ),
      ),
    ),
  );
}
              

// Quick actions for admin and staff users (Projects, Tasks, Team)
Widget _buildAdminStaffQuickActions() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildActionButton(
        icon: Icons.folder_outlined,
        label: 'Projects',
        onTap: () => _openProjectsScreen(context),
      ),
      _buildActionButton(
        icon: Icons.task_outlined,
        label: 'Tasks',
        onTap: () => _openStaffTasksScreen(context),
      ),
      _buildActionButton(
        icon: Icons.people_outlined,
        label: 'Team',
        onTap: () => _openTeamScreen(context),
      ),
    ],
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

// Update the projects screen navigation to handle client users
void _openProjectsScreen(BuildContext context) {
  if (widget.user.isAdmin || widget.user.isStaff) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProjectsScreen(user: widget.user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.elasticOut;

          var scaleAnimation = Tween(begin: begin, end: end).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  } else if (widget.user.isClient) {
    // Navigate to client projects screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ClientProjectsScreen(user: widget.user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.elasticOut;

          var scaleAnimation = Tween(begin: begin, end: end).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  } else {
    // For staff, show projects they have access to (coming soon)
    _showComingSoon(context, 'Staff project view coming soon! Projects you\'re working on will be displayed here. 🔒');
  }
}

// Add new method for client tasks navigation
void _openClientTasksScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ClientTasksScreen(user: widget.user),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.elasticOut;

        var scaleAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    ),
  );
}

// Add new method for client ticket creation
void _openCreateTicketScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CreateTicketScreen(user: widget.user),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.elasticOut;

        var scaleAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    ),
  );
}

// Add new method for staff tasks navigation
void _openStaffTasksScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => StaffTasksScreen(user: widget.user),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.elasticOut;

        var scaleAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    ),
  );
}

// Quick actions for client users (Projects, Tasks, and Create Ticket)
Widget _buildClientQuickActions() {
  return Column(
    children: [
      // First row: Projects and Tasks
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.folder_outlined,
              label: 'Projects',
              onTap: () => _openProjectsScreen(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.task_outlined,
              label: 'Tasks',
              onTap: () => _openClientTasksScreen(context),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Second row: Tickets (centered)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: _buildActionButton(
              icon: Icons.confirmation_number_outlined,
              label: 'Create Ticket',
              onTap: () => _openCreateTicketScreen(context),
            ),
          ),
        ],
      ),
    ],
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

  void _openTeamScreen(BuildContext context) {
    if (widget.user.isAdmin) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TeamScreen(user: widget.user),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.elasticOut;

            var scaleAnimation = Tween(begin: begin, end: end).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      _showComingSoon(context, 'Team management is only available for administrators! 🔒');
    }
  }
}