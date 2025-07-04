import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

class ServiceManagementPage extends StatefulWidget {
  const ServiceManagementPage({super.key});

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerMileController = TextEditingController();
  String _selectedServiceCategory = 'grocery';
  bool _requiresVehicle = false;
  String _iconName = 'task_alt';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoading = true);
      final services = await SupabaseConfig.getAllServices();
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading services: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _showAddServiceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryFilter(theme),
                  const SizedBox(height: 24),
                  _buildServiceStats(theme),
                  const SizedBox(height: 32),
                  Expanded(child: _buildServicesGrid(theme, isDesktop)),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    final categories = [
      'all',
      'grocery',
      'delivery',
      'document',
      'shopping',
      'cleaning',
      'maintenance',
      'other'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: LottoRunnersColors.primaryBlue.withOpacity(0.2),
              checkmarkColor: LottoRunnersColors.primaryBlue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceStats(ThemeData theme) {
    final totalServices = _services.length;
    final activeServices =
        _services.where((s) => s['is_active'] == true).length;
    final categories = _services.map((s) => s['category']).toSet().length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Total Services', totalServices.toString(),
                Icons.build, LottoRunnersColors.primaryBlue)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('Active', activeServices.toString(),
                Icons.check_circle, LottoRunnersColors.accent)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('Categories', categories.toString(),
                Icons.category, LottoRunnersColors.primaryYellow)),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: LottoRunnersColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(ThemeData theme, bool isDesktop) {
    final filteredServices = _selectedCategory == 'all'
        ? _services
        : _services
            .where((service) => service['category'] == _selectedCategory)
            .toList();

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.2 : 3,
      ),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return _buildServiceCard(service, theme);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, ThemeData theme) {
    final isActive = service['is_active'] == true;
    final pricingTiers = service['service_pricing_tiers'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? LottoRunnersColors.primaryBlue.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getServiceIcon(service['icon_name'] ?? 'task_alt'),
                    color: LottoRunnersColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(service['category'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service['category'].toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(service['category']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleServiceAction(value, service),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'pricing', child: Text('Manage Pricing')),
                    PopupMenuItem(
                      value: isActive ? 'deactivate' : 'activate',
                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              service['description'] ?? 'No description',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.attach_money,
                    size: 16, color: LottoRunnersColors.accent),
                Text(
                  'N\$${service['base_price'].toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LottoRunnersColors.accent,
                  ),
                ),
                const Spacer(),
                if (service['requires_vehicle'] == true)
                  Icon(Icons.directions_car,
                      size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? LottoRunnersColors.accent
                        : theme.colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (pricingTiers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${pricingTiers.length} pricing tier${pricingTiers.length != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: LottoRunnersColors.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleServiceAction(String action, Map<String, dynamic> service) {
    switch (action) {
      case 'edit':
        _showEditServiceDialog(service);
        break;
      case 'pricing':
        _showPricingManagementDialog(service);
        break;
      case 'activate':
      case 'deactivate':
        _toggleServiceStatus(service);
        break;
      case 'delete':
        _showDeleteConfirmDialog(service);
        break;
    }
  }

  void _showAddServiceDialog() {
    _clearServiceForm();
    _showServiceDialog('Add Service', null);
  }

  void _showEditServiceDialog(Map<String, dynamic> service) {
    _populateServiceForm(service);
    _showServiceDialog('Edit Service', service);
  }

  void _clearServiceForm() {
    _serviceNameController.clear();
    _descriptionController.clear();
    _basePriceController.clear();
    _pricePerHourController.clear();
    _pricePerMileController.clear();
    _selectedServiceCategory = 'grocery';
    _requiresVehicle = false;
    _iconName = 'task_alt';
  }

  void _populateServiceForm(Map<String, dynamic> service) {
    _serviceNameController.text = service['name'] ?? '';
    _descriptionController.text = service['description'] ?? '';
    _basePriceController.text = service['base_price']?.toString() ?? '';
    _pricePerHourController.text = service['price_per_hour']?.toString() ?? '';
    _pricePerMileController.text = service['price_per_mile']?.toString() ?? '';
    _selectedServiceCategory = service['category'] ?? 'grocery';
    _requiresVehicle = service['requires_vehicle'] == true;
    _iconName = service['icon_name'] ?? 'task_alt';
  }

  void _showServiceDialog(String title, Map<String, dynamic>? service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serviceNameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseConfig.getAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final categories = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedServiceCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Text(category['display_name']),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedServiceCategory = value!),
                    );
                  } else {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [],
                      onChanged: null,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _basePriceController,
                decoration:
                    const InputDecoration(labelText: 'Base Price (N\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pricePerHourController,
                decoration:
                    const InputDecoration(labelText: 'Price per Hour (N\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pricePerMileController,
                decoration:
                    const InputDecoration(labelText: 'Price per Mile (N\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Requires Vehicle'),
                value: _requiresVehicle,
                onChanged: (value) => setState(() => _requiresVehicle = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveService(service),
            child: Text(service == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveService(Map<String, dynamic>? existingService) async {
    try {
      final serviceData = {
        'name': _serviceNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedServiceCategory,
        'base_price': double.tryParse(_basePriceController.text) ?? 0,
        'price_per_hour': double.tryParse(_pricePerHourController.text) ?? 0,
        'price_per_mile': double.tryParse(_pricePerMileController.text) ?? 0,
        'requires_vehicle': _requiresVehicle,
        'icon_name': _iconName,
      };

      if (existingService == null) {
        await SupabaseConfig.createService(serviceData);
      } else {
        await SupabaseConfig.updateService(existingService['id'], serviceData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Service ${existingService == null ? 'added' : 'updated'} successfully!'),
            backgroundColor: LottoRunnersColors.accent,
          ),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving service: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPricingManagementDialog(Map<String, dynamic> service) {
    // TODO: Implement pricing management dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pricing management coming soon!')),
    );
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    try {
      final newStatus = !(service['is_active'] == true);
      await SupabaseConfig.updateService(
          service['id'], {'is_active': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Service ${newStatus ? 'activated' : 'deactivated'} successfully!'),
            backgroundColor: LottoRunnersColors.accent,
          ),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating service: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
            'Are you sure you want to delete "${service['name']}"? This will deactivate the service.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseConfig.deleteService(service['id']);
              _loadServices();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String iconName) {
    switch (iconName) {
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'description':
        return Icons.description;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'local_car_wash':
        return Icons.local_car_wash;
      case 'pets':
        return Icons.pets;
      case 'grass':
        return Icons.grass;
      default:
        return Icons.task_alt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'grocery':
        return LottoRunnersColors.accent;
      case 'delivery':
        return LottoRunnersColors.primaryBlue;
      case 'document':
        return LottoRunnersColors.primaryYellow;
      case 'shopping':
        return LottoRunnersColors.primaryBlueDark;
      case 'cleaning':
        return Colors.purple;
      case 'maintenance':
        return Colors.orange;
      default:
        return LottoRunnersColors.gray600;
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _pricePerHourController.dispose();
    _pricePerMileController.dispose();
    super.dispose();
  }
}
