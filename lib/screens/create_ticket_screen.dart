import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../services/ticket_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/app_nav_bar.dart';

/// Create Ticket screen - allows clients to create tickets for their projects
class CreateTicketScreen extends StatefulWidget {
  final User user;

  const CreateTicketScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  List<Project> _availableProjects = [];
  Project? _selectedProject;
  bool _isLoadingProjects = false;
  bool _isCreating = false;
  String? _projectsError;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadClientProjects();
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

  Future<void> _loadClientProjects() async {
    try {
      setState(() {
        _isLoadingProjects = true;
        _projectsError = null;
      });

      final projects = await ProjectService.getClientProjects();
      
      setState(() {
        _availableProjects = projects;
        _isLoadingProjects = false;
      });
    } catch (error) {
      setState(() {
        _projectsError = error.toString();
        _isLoadingProjects = false;
        _availableProjects = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Failed to load projects: ${error.toString()}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadClientProjects,
            ),
          ),
        );
      }
    }
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project for your ticket'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await TicketService.createTicket(
        projectId: _selectedProject!.id,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ticket created successfully for "${_selectedProject!.name}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating ticket: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageController.dispose();
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
                onHomePressed: () => Navigator.pop(context),
              ),
              
              const SizedBox(height: 20),
              
              // Header
              _buildHeader(),
            ],
          ),
        ),
        
        // Scrollable form
        Expanded(
          child: _buildScrollableForm(),
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
          child: const Icon(Icons.confirmation_number, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Ticket',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'Request support for your project',
                style: TextStyle(
                  color: AppTheme.darkColor.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableForm() {
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Form header
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
                    'Ticket Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_note,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project selection
                    _buildProjectDropdown(),
                    
                    const SizedBox(height: 24),
                    
                    // Message input
                    _buildMessageInput(),
                    
                    const SizedBox(height: 32),
                    
                    // Create button
                    _buildCreateButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Info card
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Select Project *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the project for which you need support',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedProject == null ? Colors.grey.shade300 : AppTheme.gradientEnd,
              width: _selectedProject == null ? 1 : 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _selectedProject == null ? Colors.grey.shade50 : AppTheme.gradientEnd.withValues(alpha: 0.05),
          ),
          child: _isLoadingProjects 
              ? const ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Loading projects...'),
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _projectsError != null
                  ? ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Failed to load projects'),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadClientProjects,
                      ),
                    )
                  : _availableProjects.isEmpty
                      ? const ListTile(
                          leading: Icon(Icons.folder_off),
                          title: Text('No projects found'),
                          subtitle: Text('You don\'t have any projects assigned'),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<Project?>(
                            value: _selectedProject,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.folder_outlined),
                                SizedBox(width: 12),
                                Text('Select a project'),
                              ],
                            ),
                            items: _availableProjects.map((project) => DropdownMenuItem<Project?>(
                              value: project,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(project.statusColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          project.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          project.statusDisplayName,
                                          style: TextStyle(
                                            color: _getStatusColor(project.statusColor),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                            onChanged: (project) {
                              setState(() => _selectedProject = project);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.message, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Request Message *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Describe what you need help with or what changes you\'d like to request',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.darkColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Example: I need the header color changed to match our brand colors...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.gradientEnd, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe your request';
            }
            if (value.trim().length < 10) {
              return 'Please provide more details (minimum 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createTicket,
        icon: _isCreating 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send, color: Colors.white),
        label: Text(
          _isCreating ? 'Creating Ticket...' : 'Create Ticket',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.gradientEnd,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ticket Information',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Your ticket will be reviewed by our team\n'
            '• You\'ll receive updates on progress\n'
            '• Response time: Usually within 24 hours\n'
            '• Be specific to help us assist you better',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor.toLowerCase()) {
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
}
