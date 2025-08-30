import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// Create Project screen - allows admin users to create new projects
class CreateProjectScreen extends StatefulWidget {
  final User user;

  const CreateProjectScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  List<Map<String, dynamic>> _availableClients = [];
  Map<String, dynamic>? _selectedClient;
  String _selectedPlan = 'Starter Launch';
  String _selectedStatus = 'in_development';
  DateTime? _contractDate;
  final List<String> _socialLinks = [];
  bool _isLoading = false;
  bool _isCreating = false;

  // Available plans based on database enum
  final List<String> _availablePlans = [
    'Starter Launch',
    'Aura Boost',
    'Aura Complete',
  ];

  // Available statuses based on database enum
  final List<String> _availableStatuses = [
    'in_development',
    'developed',
    'delivered',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadClients();
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

  Future<void> _loadClients() async {
    try {
      setState(() => _isLoading = true);
      final clients = await ProjectService.getAllClients();
      setState(() {
        _availableClients = clients;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clients: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectContractDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _contractDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _contractDate = date);
    }
  }

  void _addSocialLink() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        final formKey = GlobalKey<FormState>();
        
        return AlertDialog(
          title: const Text('Add Social Link'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Social Media URL',
                hintText: 'https://instagram.com/username or @username',
                helperText: 'Enter a social media URL or username',
              ),
              validator: Validators.socialUrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && controller.text.trim().isNotEmpty) {
                  String url = controller.text.trim();
                  
                  // Basic URL normalization
                  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('@')) {
                    // Add https:// if it looks like a URL but doesn't have protocol
                    if (url.contains('.') && !url.startsWith('www.')) {
                      url = 'https://$url';
                    } else if (url.startsWith('www.')) {
                      url = 'https://$url';
                    }
                  }
                  
                  setState(() {
                    _socialLinks.add(url);
                  });
                  Navigator.pop(context);
                } else if (controller.text.trim().isEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeSocialLink(int index) {
    setState(() {
      _socialLinks.removeAt(index);
    });
  }

  Future<void> _createProject() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isCreating = true);

  try {
      final request = CreateProjectRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      clientId: _selectedClient?['id'], 
      websiteUrl: _websiteUrlController.text.trim().isNotEmpty
          ? _websiteUrlController.text.trim()
          : null,
      socialLinks: _socialLinks.isNotEmpty ? _socialLinks : null,
      plan: _selectedPlan,
      contractSubscriptionDate: _contractDate?.toIso8601String(),
      status: _selectedStatus,
    );

    
    final createdProject = await ProjectService.createProject(request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Project "${createdProject.name}" created successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    }
  } catch (error) {
    print('Create project error: $error'); // Debug log
    if (mounted) {
      String errorMessage = 'Error creating project';
      
      // Try to extract meaningful error from the response
      if (error.toString().contains('validation') || error.toString().contains('invalid')) {
        errorMessage = 'Validation error: Please check all fields are valid';
      } else if (error.toString().contains('social') || error.toString().contains('url')) {
        errorMessage = 'URL validation error: Please check social links and website URL';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage\nDetails: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
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
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
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
        // Header
        _buildHeader(),
        
        // Form
        Expanded(
          child: _buildForm(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Add a new project to the system',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Project Name
            _buildTextFormField(
              controller: _nameController,
              label: 'Project Name',
              hint: 'Enter project name',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Description
            _buildTextFormField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter project description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Client Selection
            _buildClientDropdown(),
            
            const SizedBox(height: 20),
            
            // Website URL
            _buildTextFormField(
              controller: _websiteUrlController,
              label: 'Website URL (Optional)',
              hint: 'https://client-website.com',
              icon: Icons.language,
              validator: (value) => Validators.url(value, required: false),
            ),
            
            const SizedBox(height: 20),
            
            // Plan Selection
            _buildPlanDropdown(),
            
            const SizedBox(height: 20),
            
            // Status Selection
            _buildStatusDropdown(),
            
            const SizedBox(height: 20),
            
            // Contract Date
            _buildContractDatePicker(),
            
            const SizedBox(height: 20),
            
            // Social Links
            _buildSocialLinksSection(),
            
            const SizedBox(height: 30),
            
            // Create Button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildClientDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isLoading 
              ? const ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Loading clients...'),
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>?>(
                    value: _selectedClient,
                    isExpanded: true,
                    hint: const Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 12),
                        Text('Select a client (optional)'),
                      ],
                    ),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.person_off),
                            SizedBox(width: 12),
                            Text('No client assigned'),
                          ],
                        ),
                      ),
                      ..._availableClients.map((client) => DropdownMenuItem<Map<String, dynamic>?>(
                        value: client,
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getClientDisplayName(client),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (client) {
                      setState(() => _selectedClient = client);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Helper method to get client display name from map
  String _getClientDisplayName(Map<String, dynamic> client) {
    final fullName = client['full_name'] as String?;
    final username = client['username'] as String?;
    final email = client['email'] as String?;
    
    if (fullName?.isNotEmpty == true) return fullName!;
    if (username?.isNotEmpty == true) return username!;
    return email ?? 'Unknown Client';
  }

  Widget _buildPlanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlan,
              isExpanded: true,
              items: _availablePlans.map((plan) => DropdownMenuItem<String>(
                value: plan,
                child: Row(
                  children: [
                    const Icon(Icons.business_center),
                    const SizedBox(width: 12),
                    Text(plan),
                  ],
                ),
              )).toList(),
              onChanged: (plan) {
                if (plan != null) {
                  setState(() => _selectedPlan = plan);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: _availableStatuses.map((status) => DropdownMenuItem<String>(
                value: status,
                child: Row(
                  children: [
                    const Icon(Icons.flag),
                    const SizedBox(width: 12),
                    Text(_getStatusDisplayName(status)),
                  ],
                ),
              )).toList(),
              onChanged: (status) {
                if (status != null) {
                  setState(() => _selectedStatus = status);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contract Subscription Date (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectContractDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _contractDate != null 
                        ? '${_contractDate!.day}/${_contractDate!.month}/${_contractDate!.year}'
                        : 'Select contract date (optional)',
                    style: TextStyle(
                      color: _contractDate != null 
                          ? Colors.black87 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (_contractDate != null)
                  IconButton(
                    onPressed: () => setState(() => _contractDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Social Links (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            IconButton(
              onPressed: _addSocialLink,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_socialLinks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.link_off, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Text(
                  'No social links added',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ...List.generate(_socialLinks.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _socialLinks[index],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeSocialLink(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createProject,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Project...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Create Project'),
                ],
              ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    return status.replaceAll('_', ' ').split(' ')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
