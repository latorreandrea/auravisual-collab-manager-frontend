import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';

/// Client Tasks screen - shows tasks associated with client's projects
class ClientTasksScreen extends StatefulWidget {
  final User user;

  const ClientTasksScreen({
    super.key,
    required this.user,
  });

  @override
  State<ClientTasksScreen> createState() => _ClientTasksScreenState();
}

class _ClientTasksScreenState extends State<ClientTasksScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? _refreshTimer;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadClientTasks();
    _searchController.addListener(_onSearchChanged);
    
    // Auto-refresh every 30 seconds to update timer status
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !isLoading) {
        _loadClientTasks(showSuccessMessage: false);
      }
    });
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

  Future<void> _loadClientTasks({bool showSuccessMessage = true}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load client's tasks
      final tasksList = await TaskService.getClientTasks();
      
      // Sort by creation date (newest first)
      tasksList.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        tasks = tasksList;
        filteredTasks = tasksList;
        isLoading = false;
      });

      if (mounted && showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${tasksList.length} tasks'),
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
        tasks = [];
        filteredTasks = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error loading tasks: ${error.toString()}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadClientTasks(),
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _filterTasks();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterTasks();
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTasks = tasks.where((task) {
        // Filter by status
        if (_selectedStatus != 'all' && task['status'] != _selectedStatus) {
          return false;
        }
        
        // Filter by search query
        if (query.isNotEmpty) {
          final title = (task['title'] ?? '').toString().toLowerCase();
          final projectName = (task['project_name'] ?? '').toString().toLowerCase();
          
          return title.contains(query) || 
                 projectName.contains(query);
        }
        
        return true;
      }).toList();
      
      // Keep sorted by creation date
      filteredTasks.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
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
              
              // Header
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Search and filter
              _buildSearchAndFilter(),
            ],
          ),
        ),
        
        // Scrollable tasks list
        Expanded(
          child: _buildScrollableTasksList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
          child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'Tasks from your projects',
                style: TextStyle(
                  color: AppTheme.darkColor.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          onPressed: _loadClientTasks,
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

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Status filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatusChip('all', 'All Tasks'),
              const SizedBox(width: 8),
              _buildStatusChip('pending', 'Pending'),
              const SizedBox(width: 8),
              _buildStatusChip('in_progress', 'In Progress'),
              const SizedBox(width: 8),
              _buildStatusChip('completed', 'Completed'),
              const SizedBox(width: 8),
              _buildStatusChip('cancelled', 'Cancelled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    final color = _getStatusColor(status);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onStatusChanged(status),
      backgroundColor: Colors.white,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppTheme.darkColor.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  Widget _buildScrollableTasksList() {
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
                  'Tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredTasks.length} of ${tasks.length}',
                  style: TextStyle(
                    color: AppTheme.darkColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppTheme.darkColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          
          // Scrollable list
          Expanded(
            child: isLoading ? _buildTasksListLoading() : _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (filteredTasks.isEmpty && errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredTasks.isEmpty && (_searchController.text.isNotEmpty || _selectedStatus != 'all')) {
      return _buildNoSearchResults();
    }

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredTasks.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        return _buildTaskTile(filteredTasks[index]);
      },
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    final status = task['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final createdAt = DateTime.tryParse(task['created_at'] ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final isBeingWorkedOn = task['is_being_worked_on'] == true;
    final activeTimer = task['active_timer'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBeingWorkedOn 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          width: isBeingWorkedOn ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task['title'] ?? 'Untitled Task',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isBeingWorkedOn) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplayName(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (task['project_name']?.isNotEmpty == true) ...[
                  Expanded(
                    child: Text(
                      task['project_name'],
                      style: TextStyle(
                        color: AppTheme.darkColor.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (isBeingWorkedOn && activeTimer != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Staff is working on this task',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (activeTimer['start_time'] != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• Started ${_formatTimeAgo(activeTimer['start_time'])}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              daysAgo == 0 ? 'Today' : 
              daysAgo == 1 ? '1 day ago' : 
              '$daysAgo days ago',
              style: TextStyle(
                color: AppTheme.darkColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              color: AppTheme.darkColor.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildTasksListLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Tasks Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any tasks assigned yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks match your current filters.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Tasks',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadClientTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    final status = task['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final createdAt = DateTime.tryParse(task['created_at'] ?? '') ?? DateTime.now();
    final isBeingWorkedOn = task['is_being_worked_on'] == true;
    final activeTimer = task['active_timer'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task['title'] ?? 'Untitled Task',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            if (isBeingWorkedOn) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'BEING WORKED ON',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStatusDisplayName(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                    // Active work status
                    if (isBeingWorkedOn && activeTimer != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_2_outlined, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Team Member Active',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A team member is currently working on this task.',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (activeTimer['start_time'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Started: ${_formatTimeAgo(activeTimer['start_time'])}',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Task details
                    _buildDetailRow('Project', task['project_name'] ?? 'No project assigned'),
                    _buildDetailRow('Status', _getStatusDisplayName(status)),
                    _buildDetailRow('Created', '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                    if (task['assigned_to_name']?.isNotEmpty == true)
                      _buildDetailRow('Assigned to', task['assigned_to_name']),
                    if (task['total_time_minutes'] != null && task['total_time_minutes'] > 0)
                      _buildDetailRow('Time logged', '${task['total_time_minutes']} minutes'),
                    
                    // Ticket context
                    if (task['ticket_message']?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Ticket Context',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          task['ticket_message'],
                          style: TextStyle(
                            color: AppTheme.darkColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'all':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTimeAgo(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'recently';
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }
}