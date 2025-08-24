import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';
import 'create_project_screen.dart';

/// Projects screen - shows list of all projects with tickets and tasks
/// Only accessible by admin users
class ProjectsScreen extends StatefulWidget {
  final User user;

  const ProjectsScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  List<Project> projects = [];
  List<Project> filteredProjects = [];
  Map<String, dynamic> projectStats = {};
  bool isLoading = true;
  String? errorMessage;
  
  // Filter and sort options
  String _sortOption = 'default'; // 'default', 'alphabetical'
  String _filterOption = 'all'; // 'all', 'with_tickets', 'with_tasks'

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProjectsData();
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

  Future<void> _loadProjectsData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load real projects data from API
      final projectsList = await ProjectService.getAllProjects();
      final statistics = await ProjectService.getProjectStatistics();

      setState(() {
        projects = projectsList;
        filteredProjects = projectsList;
        projectStats = statistics;
        isLoading = false;
      });

      // Apply current filters
      _applyFiltersAndSort();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${projectsList.length} projects'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'We apologize, but there was an issue loading the projects data. Please try again later or contact support if the problem persists.\n\nError details: ${error.toString()}';
        isLoading = false;
        projects = [];
        projectStats = {};
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Unable to load projects data'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadProjectsData(),
            ),
          ),
        );
      }
    }
  }

  // Apply filters and sorting to projects list
  void _applyFiltersAndSort() {
    List<Project> filtered = List.from(projects);
    
    // Apply filters
    switch (_filterOption) {
      case 'with_tickets':
        filtered = filtered.where((project) => project.openTicketsCount > 0).toList();
        break;
      case 'with_tasks':
        filtered = filtered.where((project) => project.openTasksCount > 0).toList();
        break;
      case 'all':
      default:
        // No filter, show all projects
        break;
    }
    
    // Apply sorting
    switch (_sortOption) {
      case 'alphabetical':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'default':
      default:
        // Keep original order (usually by creation date)
        break;
    }
    
    setState(() {
      filteredProjects = filtered;
    });
  }

  // Handle sort option change
  void _onSortChanged(String sortOption) {
    setState(() {
      _sortOption = sortOption;
    });
    _applyFiltersAndSort();
  }

  // Handle filter option change
  void _onFilterChanged(String filterOption) {
    setState(() {
      _filterOption = filterOption;
    });
    _applyFiltersAndSort();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.user.isAdmin ? FloatingActionButton(
        onPressed: _openCreateProject,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
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

  void _openCreateProject() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProjectScreen(user: widget.user),
      ),
    );
    if (created == true) {
      // Reload projects after creation
      _loadProjectsData();
    }
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
              
              // Filter and sort options
              _buildFilterAndSortSection(),
              
              const SizedBox(height: 16),
              
              // Horizontal stats overview
              _buildHorizontalStats(),
            ],
          ),
        ),
        
        // Scrollable projects list
        Expanded(
          child: _buildScrollableProjectsList(),
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
          child: const Icon(Icons.folder_open, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    'All client projects',
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
          onPressed: _loadProjectsData,
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

  Widget _buildFilterAndSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort and filter header
        Row(
          children: [
            Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const Spacer(),
            Text(
              '${filteredProjects.length} of ${projects.length} projects',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Sort options
              _buildFilterChip(
                label: 'Default Order',
                isSelected: _sortOption == 'default',
                onTap: () => _onSortChanged('default'),
                icon: Icons.sort,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'A-Z',
                isSelected: _sortOption == 'alphabetical',
                onTap: () => _onSortChanged('alphabetical'),
                icon: Icons.sort_by_alpha,
              ),
              
              const SizedBox(width: 16),
              
              // Divider
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              
              const SizedBox(width: 16),
              
              // Filter options
              _buildFilterChip(
                label: 'All Projects',
                isSelected: _filterOption == 'all',
                onTap: () => _onFilterChanged('all'),
                icon: Icons.folder_outlined,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'With Tickets',
                isSelected: _filterOption == 'with_tickets',
                onTap: () => _onFilterChanged('with_tickets'),
                icon: Icons.confirmation_number_outlined,
                badgeCount: _getProjectsWithTicketsCount(),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'With Tasks',
                isSelected: _filterOption == 'with_tasks',
                onTap: () => _onFilterChanged('with_tasks'),
                icon: Icons.task_outlined,
                badgeCount: _getProjectsWithTasksCount(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    int? badgeCount,
  }) {
    final color = isSelected ? AppTheme.gradientEnd : AppTheme.darkColor.withValues(alpha: 0.6);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gradientEnd.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.gradientEnd : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.gradientEnd : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods for badge counts
  int _getProjectsWithTicketsCount() {
    return projects.where((project) => project.openTicketsCount > 0).length;
  }

  int _getProjectsWithTasksCount() {
    return projects.where((project) => project.openTasksCount > 0).length;
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
    final totalProjects = projectStats['total_projects'] ?? projects.length;
    final activeProjects = projectStats['active_projects'] ?? 
        projects.where((p) => p.status == 'in_development').length;
    final totalTickets = projectStats['total_open_tickets'] ?? 
        projects.fold<int>(0, (sum, p) => sum + p.openTicketsCount);
    final totalTasks = projectStats['total_open_tasks'] ?? 
        projects.fold<int>(0, (sum, p) => sum + p.openTasksCount);

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
                'Projects Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (projectStats.containsKey('average_tickets_per_project'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gradientEnd.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Avg: ${projectStats['average_tickets_per_project']} tickets/project',
                    style: TextStyle(
                      color: AppTheme.gradientEnd,
                      fontSize: 10,
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
                  'Projects',
                  totalProjects.toString(),
                  Icons.folder_outlined,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Active',
                  activeProjects.toString(),
                  Icons.play_circle_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Tickets',
                  totalTickets.toString(),
                  Icons.confirmation_number_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  'Tasks',
                  totalTasks.toString(),
                  Icons.task_alt,
                  Colors.green,
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
            'Loading project statistics...',
            style: TextStyle(
              color: AppTheme.darkColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableProjectsList() {
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
                  'All Projects',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${projects.length} projects',
                  style: TextStyle(
                    color: AppTheme.darkColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.sort,
                  size: 16,
                  color: AppTheme.darkColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          
          // Scrollable list
          Expanded(
            child: isLoading ? _buildProjectsListLoading() : _buildProjectsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    if (filteredProjects.isEmpty && projects.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Projects Match Filters',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter options',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _sortOption = 'default';
                  _filterOption = 'all';
                });
                _applyFiltersAndSort();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              (errorMessage?.isNotEmpty == true) ? 'Unable to load projects data' : 'No projects found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (errorMessage?.isNotEmpty == true) 
                ? 'Please check your connection and try again'
                : 'Projects will appear here when created',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            if (errorMessage?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadProjectsData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredProjects.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        return _buildProjectTile(filteredProjects[index]);
      },
    );
  }

  Widget _buildProjectTile(Project project) {
    
    Color statusColor = _getStatusColor(project.statusColor);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      title: Text(
        project.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              // Plan info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  project.plan,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Client name
              Expanded(
                child: Text(
                  project.client?.displayName ?? 'No client',
                  style: TextStyle(
                    color: AppTheme.darkColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tickets count
          _buildCompactCountChip(
            project.openTicketsCount.toString(),
            Icons.confirmation_number,
            Colors.orange,
          ),
          const SizedBox(width: 6),
          // Tasks count
          _buildCompactCountChip(
            project.openTasksCount.toString(),
            Icons.task_alt,
            Colors.green,
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            color: AppTheme.darkColor.withValues(alpha: 0.4),
            size: 18,
          ),
        ],
      ),
      onTap: () => _showProjectDetails(project),
    );
  }

  Widget _buildCompactCountChip(String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsListLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  height: 20,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 20,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showProjectDetails(Project project) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8, // Increased height
      margin: const EdgeInsets.all(16),
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
          // Fixed header
          Container(
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(project.statusColor).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: _getStatusColor(project.statusColor),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        project.client?.displayName ?? 'No client assigned',
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
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project details section
                  Text(
                    'Project Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow('Description', project.description.isNotEmpty 
                      ? project.description 
                      : 'No description available'),
                  _buildDetailRow('Status', project.statusDisplayName),
                  _buildDetailRow('Plan', project.plan),
                  _buildDetailRow('Priority', project.priority),
                  
                  if (project.websiteUrl?.isNotEmpty == true)
                    _buildDetailRow('Website', project.websiteUrl!),
                  
                  const SizedBox(height: 24),
                  
                  // Client information section
                  Text(
                    'Client Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow('Client Name', project.client?.displayName ?? 'No client assigned'),
                  _buildDetailRow('Client Email', project.client?.email ?? 'Not available'),
                  
                  const SizedBox(height: 24),
                  
                  // Task & Ticket statistics
                  Text(
                    'Project Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildProjectStatCard(
                          'Open Tickets',
                          '${project.openTicketsCount}',
                          Icons.confirmation_number,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProjectStatCard(
                          'Active Tasks',
                          '${project.openTasksCount}',
                          Icons.task_alt,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status overview card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.statusColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(project.statusColor).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline,
                          color: _getStatusColor(project.statusColor),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Project Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.statusDisplayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(project.statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social links section (if available)
                  if (project.socialLinks.isNotEmpty == true) ...[
                    Text(
                      'Social Links',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.socialLinks.map((link) => Chip(
                        label: Text(
                          link.length > 30 ? '${link.substring(0, 30)}...' : link,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Status indicator (at the bottom)
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
                  
                  // Extra space at bottom for better scrolling
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Add this helper method for project stat cards
Widget _buildProjectStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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