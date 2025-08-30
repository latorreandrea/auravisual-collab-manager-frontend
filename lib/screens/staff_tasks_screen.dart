import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';

/// Staff Tasks screen - shows tasks assigned to the current staff member
class StaffTasksScreen extends StatefulWidget {
  final User user;

  const StaffTasksScreen({
    super.key,
    required this.user,
  });

  @override
  State<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends State<StaffTasksScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  Map<String, dynamic>? activeTimer;
  bool isLoading = true;
  String? errorMessage;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  // Available status filters
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Tasks'},
    {'value': 'in_progress', 'label': 'In Progress'},
    {'value': 'completed', 'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStaffTasks();
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _loadStaffTasks() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load staff's assigned tasks and active timer
      final tasksList = await TaskService.getMyTasks();
      final timer = await TaskService.getActiveTimer();
      
      // Sort by status (in_progress first) then by creation date
      tasksList.sort((a, b) {
        final statusA = a['status'] ?? '';
        final statusB = b['status'] ?? '';
        
        // In progress tasks first
        if (statusA == 'in_progress' && statusB != 'in_progress') return -1;
        if (statusB == 'in_progress' && statusA != 'in_progress') return 1;
        
        // Then by creation date (newest first)
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        tasks = tasksList;
        filteredTasks = tasksList;
        activeTimer = timer;
        isLoading = false;
      });

      // Show notification if there's an active timer
      if (timer != null && mounted) {
        final activeTaskName = tasksList.firstWhere(
          (task) => task['id'].toString() == timer['task_id'].toString(),
          orElse: () => {'action': 'Unknown Task'},
        )['action'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.timer, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('⏱️ Timer active for: $activeTaskName\nStarted: ${_formatDateTime(timer['start_time'])}'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                final activeTask = tasksList.firstWhere(
                  (task) => task['id'].toString() == timer['task_id'].toString(),
                  orElse: () => {},
                );
                if (activeTask.isNotEmpty) {
                  _showTaskDetails(activeTask);
                }
              },
            ),
          ),
        );
      } else if (mounted) {
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
        activeTimer = null;
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
              onPressed: _loadStaffTasks,
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTasks = tasks.where((task) {
        // Filter by status
        if (_selectedStatus != 'all' && task['status'] != _selectedStatus) {
          return false;
        }
        
        // Filter by search query
        if (query.isNotEmpty) {
          final title = (task['action'] ?? '').toString().toLowerCase();
          final projectName = (task['project_name'] ?? '').toString().toLowerCase();
          
          return title.contains(query) || 
                 projectName.contains(query);
        }
        
        return true;
      }).toList();
      
      // Keep sorted by status and date
      filteredTasks.sort((a, b) {
        final statusA = a['status'] ?? '';
        final statusB = b['status'] ?? '';
        
        if (statusA == 'in_progress' && statusB != 'in_progress') return -1;
        if (statusB == 'in_progress' && statusA != 'in_progress') return 1;
        
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'My Tasks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadStaffTasks,
            icon: Icon(
              isLoading ? Icons.refresh : Icons.refresh_outlined,
              color: Colors.white,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(user: widget.user),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Stats and filters header
        _buildHeader(),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSearchBar(),
        ),
        
        // Status filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatusFilter(),
        ),
        
        const SizedBox(height: 8),
        
        // Task count info
        if (!isLoading && filteredTasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.sort_by_alpha,
                  size: 16,
                  color: AppTheme.darkColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing ${filteredTasks.length} of ${tasks.length} tasks',
                  style: TextStyle(
                    color: AppTheme.darkColor.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        
        // Tasks list
        Expanded(
          child: isLoading ? _buildTasksListLoading() : _buildTasksList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.gradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${widget.user.fullName?.isNotEmpty == true ? widget.user.fullName!.split(' ').first : widget.user.username}! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Active timer indicator
          if (activeTimer != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Timer active on: ${activeTimer!['task_title'] ?? 'Unknown task'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          if (!isLoading && tasks.isNotEmpty)
            Row(
              children: [
                _buildStatCard(
                  '${tasks.where((t) => t['status'] == 'in_progress').length}',
                  'Active',
                  Icons.play_circle_outline,
                  Colors.white,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  '${tasks.where((t) => t['status'] == 'completed').length}',
                  'Completed',
                  Icons.check_circle_outline,
                  Colors.white70,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedStatus == filter['value'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = filter['value']!;
              });
              _onSearchChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : AppTheme.darkColor.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTasksList() {
    if (filteredTasks.isEmpty && errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredTasks.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoSearchResults();
    }

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredTasks[index]);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'] ?? 'in_progress';
    final isCompleted = status == 'completed';
    final priority = task['priority'] ?? 'medium';
    final taskId = task['id']?.toString() ?? '';
    final hasActiveTimer = activeTimer != null && activeTimer!['task_id'] == taskId;
    final isPaused = hasActiveTimer && activeTimer!['status'] == 'paused';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getPriorityColor(priority).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          task['action'] ?? 'Untitled Task',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted 
                ? AppTheme.darkColor.withValues(alpha: 0.6)
                : AppTheme.darkColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (task['project_name']?.isNotEmpty == true)
              Text(
                'Project: ${task['project_name']}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusDisplayName(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(priority),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (hasActiveTimer) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPaused ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaused ? Icons.pause : Icons.timer, 
                          size: 12, 
                          color: isPaused ? Colors.blue : Colors.orange
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaused ? 'PAUSED' : 'ACTIVE',
                          style: TextStyle(
                            color: isPaused ? Colors.blue : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isPaused) ...[
                          const SizedBox(width: 4),
                          Text(
                            _getElapsedTime(activeTimer!['start_time']),
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task['total_time_minutes'] != null && task['total_time_minutes'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${task['total_time_minutes']}m',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            // Time tracking buttons
            if (!isCompleted) ...[
              // Resume button for paused timers
              if (isPaused)
                IconButton(
                  onPressed: () => _resumeTimer(task),
                  icon: Icon(Icons.play_arrow, color: Colors.green),
                  tooltip: 'Resume timer',
                )
              else
                // Start/Stop/Pause button for active or inactive timers
                IconButton(
                  onPressed: () => _toggleTimer(task),
                  icon: Icon(
                    hasActiveTimer ? Icons.pause : Icons.play_arrow,
                    color: hasActiveTimer ? Colors.orange : Colors.green,
                  ),
                  tooltip: hasActiveTimer ? 'Timer options' : 'Start timer',
                ),
            ],
            // Status toggle button
            if (!isCompleted)
              IconButton(
                onPressed: () => _toggleTaskStatus(task),
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                tooltip: 'Mark as completed',
              )
            else
              IconButton(
                onPressed: () => _toggleTaskStatus(task),
                icon: Icon(
                  Icons.undo,
                  color: Colors.orange,
                ),
                tooltip: 'Mark as in progress',
              ),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildTasksListLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
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
            'No tasks assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your assigned tasks will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
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
            'Error loading tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadStaffTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
    final taskId = task['id']?.toString() ?? '';
    final hasActiveTimer = activeTimer != null && activeTimer!['task_id'] == taskId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
            // Header
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
                    child: Text(
                      task['action'] ?? 'Task Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task['project_name']?.isNotEmpty == true)
                      _buildDetailRow('Project', task['project_name']),
                    _buildDetailRow('Status', _getStatusDisplayName(task['status'] ?? '')),
                    _buildDetailRow('Priority', (task['priority'] ?? 'medium').toUpperCase()),
                    if (task['total_time_minutes'] != null && task['total_time_minutes'] > 0)
                      _buildDetailRow('Time Logged', '${task['total_time_minutes']} minutes'),
                    if (task['time_sessions_count'] != null && task['time_sessions_count'] > 0)
                      _buildDetailRow('Sessions', '${task['time_sessions_count']} work sessions'),
                    if (task['created_at'] != null)
                      _buildDetailRow('Created', _formatDate(task['created_at'])),
                    
                    if (hasActiveTimer) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.timer, color: Colors.orange, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Timer Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Started: ${_formatDateTime(activeTimer!['start_time'])}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Timer button
                  if (task['status'] != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (hasActiveTimer) {
                              // Stop timer and close modal
                              await _toggleTimer(task);
                              if (mounted) Navigator.pop(context);
                            } else {
                              // Start timer and update modal state
                              await _toggleTimer(task);
                              // Note: We can't use setModalState here as it's not StatefulBuilder
                              // So we close and reopen the modal to show the updated state
                              if (mounted) {
                                Navigator.pop(context);
                                _showTaskDetails(task);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Timer error: $e')),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          hasActiveTimer ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          hasActiveTimer ? 'Stop Timer & Close' : 'Start Timer',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasActiveTimer ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Status button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (mounted) Navigator.pop(context);
                        _toggleTaskStatus(task);
                      },
                      icon: Icon(
                        task['status'] == 'completed' 
                            ? Icons.undo 
                            : Icons.check_circle,
                      ),
                      label: Text(
                        task['status'] == 'completed' 
                            ? 'Mark as In Progress' 
                            : 'Mark as Completed',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: task['status'] == 'completed' 
                            ? Colors.orange 
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  // Time tracking functionality
  Future<void> _toggleTimer(Map<String, dynamic> task) async {
    final taskId = task['id']?.toString() ?? '';
    final hasActiveTimer = activeTimer != null && activeTimer!['task_id'] == taskId;
    
    try {
      if (hasActiveTimer) {
        // Show options for active timer
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Timer Options'),
            content: Text('Choose an action for timer on "${task['action']}"'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'pause'),
                child: const Text('⏸️ Pause'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'stop'),
                child: const Text('⏹️ Stop'),
              ),
            ],
          ),
        );
        
        if (action == 'stop') {
          await TaskService.stopTaskTimer(taskId);
          setState(() {
            activeTimer = null;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⏹️ Timer stopped for: ${task['action']}'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (action == 'pause') {
          await TaskService.pauseTaskTimer(taskId, note: 'Paused by user');
          setState(() {
            activeTimer!['status'] = 'paused';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⏸️ Timer paused for: ${task['action']}'),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Check if there's already an active timer for another task
        if (activeTimer != null) {
          // Show confirmation dialog
          final shouldStop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Active Timer Found'),
              content: Text('You have an active timer for "${activeTimer!['task_title']}". Stop it and start new timer?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Stop & Start New'),
                ),
              ],
            ),
          );
          
          if (shouldStop != true) return;
          
          // Stop the current active timer
          await TaskService.stopTaskTimer(activeTimer!['task_id']);
        }
        
        // Start new timer
        await TaskService.startTaskTimer(taskId);
        setState(() {
          activeTimer = {
            'task_id': taskId,
            'task_title': task['action'],
            'start_time': DateTime.now().toIso8601String(),
            'status': 'active',
          };
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('▶️ Timer started for: ${task['action']}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Reload tasks to get updated time
      _loadStaffTasks();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Timer error: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Resume paused timer
  Future<void> _resumeTimer(Map<String, dynamic> task) async {
    final taskId = task['id']?.toString() ?? '';
    
    try {
      await TaskService.resumeTaskTimer(taskId, note: 'Resumed by user');
      setState(() {
        if (activeTimer != null && activeTimer!['task_id'] == taskId) {
          activeTimer!['status'] = 'active';
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('▶️ Timer resumed for: ${task['action']}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Reload tasks to get updated time
      _loadStaffTasks();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Resume error: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskStatus(Map<String, dynamic> task) async {
    final currentStatus = task['status'] ?? 'in_progress';
    final newStatus = currentStatus == 'completed' ? 'in_progress' : 'completed';
    
    try {
      await TaskService.updateTaskStatus(task['id'], newStatus);
      
      // Update local state
      setState(() {
        task['status'] = newStatus;
        _onSearchChanged(); // Re-apply filters
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task marked as ${newStatus == 'completed' ? 'completed' : 'in progress'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update task: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getElapsedTime(String startTimeString) {
    try {
      final startTime = DateTime.parse(startTimeString);
      final now = DateTime.now();
      final elapsed = now.difference(startTime);
      
      if (elapsed.inHours > 0) {
        return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
      } else {
        return '${elapsed.inMinutes}m';
      }
    } catch (e) {
      return '0m';
    }
  }
}
