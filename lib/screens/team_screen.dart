import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/team_member.dart';
import '../services/staff_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';

/// Team screen - shows list of staff members and their active tasks
/// Only accessible by admin users
class TeamScreen extends StatefulWidget {
  final User user;

  const TeamScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  List<TeamMember> teamMembers = [];
  Map<String, dynamic> teamStats = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTeamData();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  Future<void> _loadTeamData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load real staff data from API
      final staffMembers = await StaffService.getStaffMembers();
      final statistics = await StaffService.getStaffStatistics();

      setState(() {
        teamMembers = staffMembers;
        teamStats = statistics;
        isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${staffMembers.length} staff members'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
        // Fallback to mock data on error
        teamMembers = TeamMember.getMockData();
        teamStats = _calculateMockStats();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Using demo data'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateMockStats() {
    final totalStaff = teamMembers.length;
    final totalActiveTasks = teamMembers.fold<int>(
      0, (sum, member) => sum + member.activeTasks,
    );
    final availableMembers = teamMembers.where((m) => m.activeTasks == 0).length;
    final busyMembers = teamMembers.where((m) => m.activeTasks > 5).length;
    
    return {
      'total_staff': totalStaff,
      'total_active_tasks': totalActiveTasks,
      'available_members': availableMembers,
      'busy_members': busyMembers,
    };
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Fixed header area
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // Navigation bar
              AppNavBar(
                user: widget.user,
                onHomePressed: () => _goBack(),
              ),
              
              const SizedBox(height: 20),
              
              // Compact header
              _buildCompactHeader(),
              
              const SizedBox(height: 16),
              
              // Horizontal stats overview
              _buildHorizontalStats(),
            ],
          ),
        ),
        
        // Scrollable team list
        Expanded(
          child: _buildScrollableTeamList(),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.people, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Staff overview',
                    style: TextStyle(
                      color: AppTheme.darkColor.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  if (errorMessage == null) ...[
                    const SizedBox(width: 8),
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
                ],
              ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          onPressed: _loadTeamData,
          icon: Icon(
            isLoading ? Icons.refresh : Icons.refresh_outlined,
            color: AppTheme.primaryColor,
          ),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.gradientEnd.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalStats() {
    if (isLoading) {
      return _buildHorizontalStatsLoading();
    }

    // Error banner
    if (errorMessage != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
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
                'Using demo data - API connection issue',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Stats in horizontal layout
    final totalStaff = teamStats['total_staff'] ?? teamMembers.length;
    final totalActiveTasks = teamStats['total_active_tasks'] ?? 
        teamMembers.fold<int>(0, (sum, member) => sum + member.activeTasks);
    final availableMembers = teamStats['available_members'] ?? 
        teamMembers.where((m) => m.activeTasks == 0).length;
    final busyMembers = teamStats['busy_members'] ?? 
        teamMembers.where((m) => m.activeTasks > 5).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (teamStats.containsKey('average_workload'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gradientEnd.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Avg: ${teamStats['average_workload']}',
                    style: TextStyle(
                      color: AppTheme.gradientEnd,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Horizontal stats row
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Staff',
                  totalStaff.toString(),
                  Icons.people_outline,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Tasks',
                  totalActiveTasks.toString(),
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Free',
                  availableMembers.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Busy',
                  busyMembers.toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.darkColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStatsLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading statistics...',
            style: TextStyle(
              color: AppTheme.darkColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTeamList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Team Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${teamMembers.length} members',
                  style: TextStyle(
                    color: AppTheme.darkColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable list
          Expanded(
            child: isLoading ? _buildTeamListLoading() : _buildTeamMembersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: teamMembers.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        return _buildOptimizedTeamMemberTile(teamMembers[index]);
      },
    );
  }

  Widget _buildOptimizedTeamMemberTile(TeamMember member) {
    Color workloadColor = _getWorkloadColor(member.activeTasks);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: workloadColor.withValues(alpha: 0.15),
        child: Text(
          member.initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: workloadColor,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        member.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        member.role,
        style: TextStyle(
          color: AppTheme.darkColor.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: workloadColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: workloadColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${member.activeTasks}',
              style: TextStyle(
                color: workloadColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: AppTheme.darkColor.withValues(alpha: 0.4),
            size: 18,
          ),
        ],
      ),
      onTap: () => _showMemberDetails(member),
    );
  }

  Widget _buildTeamListLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 20,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getWorkloadColor(int tasks) {
    if (tasks == 0) return Colors.green;
    if (tasks <= 3) return Colors.blue;
    if (tasks <= 6) return Colors.orange;
    return Colors.red;
  }

  void _showMemberDetails(TeamMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getWorkloadColor(member.activeTasks).withValues(alpha: 0.2),
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getWorkloadColor(member.activeTasks),
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        member.role,
                        style: TextStyle(
                          color: AppTheme.darkColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
            
            // Details
            _buildDetailRow('Email', member.email),
            _buildDetailRow('Active Tasks', '${member.activeTasks}'),
            if (member.totalTasks > 0)
              _buildDetailRow('Total Assigned', '${member.totalTasks}'),
            _buildDetailRow('Status', member.workloadStatus),
            
            const SizedBox(height: 20),
            
            // Status indicator
            if (errorMessage == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.api, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Real-time data from API',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  void _goBack() {
    Navigator.pop(context);
  }
}