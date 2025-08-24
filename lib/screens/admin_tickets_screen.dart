import 'package:flutter/material.dart';
import '../services/admin_ticket_service.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen>
    with TickerProviderStateMixin {
  final AdminTicketService _adminTicketService = AdminTicketService();
  
  List<Map<String, dynamic>> tickets = [];
  bool isLoading = true;
  String? errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final ticketList = await _adminTicketService.getTicketsForAdmin();
      
      setState(() {
        tickets = ticketList;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'to_read':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'to_read':
        return 'To Read';
      case 'processing':
        return 'In Progress';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  void _showCreateTasksDialog(String ticketId) {
    showDialog(
      context: context,
      builder: (context) => CreateTasksDialog(
        ticketId: ticketId,
        onTasksCreated: () {
          _loadTickets(); // Reload tickets when returning
        },
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? '';
    final message = ticket['message'] ?? '';
    final projectName = ticket['project']?['name'] ?? 'Unknown Project';
    final clientName = ticket['client']?['full_name'] ?? 'Unknown Client';
    final createdAt = ticket['created_at'] ?? '';
    
    // Parse and format date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(createdAt);
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      formattedDate = createdAt;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCreateTasksDialog(ticket['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                projectName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Client: $clientName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to create tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ticket Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tickets',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadTickets,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tickets available',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tickets to read or in progress',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Available tickets for management (${tickets.length})',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: tickets.length,
                              itemBuilder: (context, index) {
                                return _buildTicketCard(tickets[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class CreateTasksDialog extends StatefulWidget {
  final String ticketId;
  final VoidCallback onTasksCreated;

  const CreateTasksDialog({
    super.key,
    required this.ticketId,
    required this.onTasksCreated,
  });

  @override
  State<CreateTasksDialog> createState() => _CreateTasksDialogState();
}

class _CreateTasksDialogState extends State<CreateTasksDialog> {
  final AdminTicketService _adminTicketService = AdminTicketService();
  
  List<TaskForm> tasks = [TaskForm()];
  List<Map<String, dynamic>> staffMembers = [];
  bool isCreating = false;
  bool isLoadingStaff = true;

  @override
  void initState() {
    super.initState();
    _loadStaffMembers();
  }

  Future<void> _loadStaffMembers() async {
    try {
      final staff = await _adminTicketService.getStaffMembers();
      setState(() {
        staffMembers = staff;
        isLoadingStaff = false;
      });
    } catch (e) {
      setState(() {
        isLoadingStaff = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addTask() {
    setState(() {
      tasks.add(TaskForm());
    });
  }

  void _removeTask(int index) {
    if (tasks.length > 1) {
      setState(() {
        tasks.removeAt(index);
      });
    }
  }

  Future<void> _createTasks() async {
    // Validate all tasks
    final validTasks = <Map<String, dynamic>>[];
    
    for (final task in tasks) {
      if (task.action.trim().isEmpty || task.assignedTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All fields are required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      validTasks.add({
        'action': task.action.trim(),
        'assigned_to': task.assignedTo!,
        'priority': task.priority,
      });
    }

    try {
      setState(() {
        isCreating = true;
      });

      final result = await _adminTicketService.createTasksForTicket(
        widget.ticketId,
        validTasks,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${validTasks.length} tasks created successfully! Ticket moved to accepted status.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onTasksCreated();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Create Tasks for Ticket',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (isLoadingStaff)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Task ${index + 1}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (tasks.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeTask(index),
                                    tooltip: 'Remove task',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Task description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                tasks[index].action = value;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Assign to',
                                border: OutlineInputBorder(),
                              ),
                              value: tasks[index].assignedTo,
                              items: staffMembers.map((staff) {
                                return DropdownMenuItem<String>(
                                  value: staff['id'],
                                  child: Text(staff['full_name'] ?? staff['username'] ?? 'Staff'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  tasks[index].assignedTo = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                              value: tasks[index].priority,
                              items: const [
                                DropdownMenuItem(value: 'low', child: Text('Low')),
                                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'high', child: Text('High')),
                                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  tasks[index].priority = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Task'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCreating ? null : _createTasks,
                icon: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_task, size: 20),
                label: isCreating
                    ? const Text('Creating...')
                    : const Text('Create Tasks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 3,
                  shadowColor: Colors.green[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskForm {
  String action = '';
  String? assignedTo;
  String priority = 'medium';
}
