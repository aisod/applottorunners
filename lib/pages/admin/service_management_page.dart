import 'package:flutter/material.dart';

import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/service_icons.dart';

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

  final _serviceNameController = TextEditingController();

  final _descriptionController = TextEditingController();

  final _basePriceController = TextEditingController();

  final _businessPriceController = TextEditingController();

  final _discountPercentageController = TextEditingController();

  bool _requiresVehicle = false;

  String _iconName = 'task_alt';

  // Available icons for services

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'task_alt', 'icon': Icons.task_alt, 'label': 'General Task'},
    {
      'name': 'local_grocery_store',
      'icon': Icons.local_grocery_store,
      'label': 'Grocery'
    },
    {'name': 'description', 'icon': Icons.description, 'label': 'Document'},
    {
      'name': 'local_shipping',
      'icon': Icons.local_shipping,
      'label': 'Delivery'
    },
    {
      'name': 'directions_car',
      'icon': Icons.directions_car,
      'label': 'License Discs'
    },
    {'name': 'verified', 'icon': Icons.verified, 'label': 'Document Services'},
    {
      'name': 'content_copy',
      'icon': Icons.content_copy,
      'label': 'Document Copies'
    },
    {'name': 'elderly', 'icon': Icons.elderly, 'label': 'Elderly Services'},
    {'name': 'how_to_reg', 'icon': Icons.how_to_reg, 'label': 'Registration'},
    {'name': 'people_alt', 'icon': Icons.people_alt, 'label': 'Sitting'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Shopping'},
    {
      'name': 'cleaning_services',
      'icon': Icons.cleaning_services,
      'label': 'Cleaning'
    },
    {
      'name': 'local_car_wash',
      'icon': Icons.local_car_wash,
      'label': 'Car Wash'
    },
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Pet Care'},
    {'name': 'grass', 'icon': Icons.grass, 'label': 'Gardening'},
    {'name': 'build', 'icon': Icons.build, 'label': 'Maintenance'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Home Service'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Food'},
    {
      'name': 'local_hospital',
      'icon': Icons.local_hospital,
      'label': 'Medical'
    },
    {'name': 'school', 'icon': Icons.school, 'label': 'Education'},
    {'name': 'work', 'icon': Icons.work, 'label': 'Business'},
  ];

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

    final isMobile = Responsive.isMobile(context);

    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Service Management',
          style: (isSmallMobile
                  ? theme.textTheme.titleMedium
                  : (isMobile
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleLarge))
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LottoRunnersColors.primaryBlue,
                LottoRunnersColors.primaryBlueDark,
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: LottoRunnersColors.primaryYellow),
        actionsIconTheme:
            const IconThemeData(color: LottoRunnersColors.primaryYellow),
        actions: [
          Padding(
            padding: EdgeInsets.all(isSmallMobile ? 4 : 8),
            child: ElevatedButton.icon(
              onPressed: _showAddServiceDialog,
              icon: Icon(
                Icons.add,
                color: theme.colorScheme.onPrimary,
                size: isSmallMobile ? 18 : 24,
              ),
              label: Text(
                isSmallMobile ? 'Add' : 'Add Service',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallMobile ? 12 : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 8 : 16,
                  vertical: isSmallMobile ? 8 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Container(
                color: theme.colorScheme.surface,
                padding: Responsive.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceStats(theme),
                    SizedBox(
                        height: Responsive.getResponsiveSpacing(context) * 2),
                    _buildServicesGrid(theme, isDesktop),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceStats(ThemeData theme) {
    final totalServices = _services.length;
    final activeServices =
        _services.where((s) => s['is_active'] == true).length;
    final inactiveServices = totalServices - activeServices;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total Services', totalServices.toString(),
              Icons.build, theme.colorScheme.primary),
          SizedBox(width: Responsive.getResponsiveSpacing(context)),
          _buildStatCard('Active', activeServices.toString(),
              Icons.check_circle, theme.colorScheme.tertiary),
          SizedBox(width: Responsive.getResponsiveSpacing(context)),
          _buildStatCard('Inactive', inactiveServices.toString(),
              Icons.pause_circle, theme.colorScheme.secondary),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    final isSmallMobile = Responsive.isSmallMobile(context);

    final isMobile = Responsive.isMobile(context);

    return Container(
      width: 160, // Fixed width for consistent card sizing
      padding: Responsive.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallMobile ? 24 : (isMobile ? 28 : 32),
          ),
          SizedBox(height: isSmallMobile ? 8 : 12),
          Text(
            value,
            style: (isSmallMobile
                    ? theme.textTheme.titleMedium
                    : (isMobile
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleLarge))
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 13),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(ThemeData theme, bool isDesktop) {
    final filteredServices = _services;

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new service to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isDesktop) {
      crossAxisCount = 3;
      childAspectRatio = 1.8; // More height for desktop cards
      spacing = 20.0;
    } else {
      crossAxisCount = 1;
      childAspectRatio =
          2.2; // More height for mobile cards to prevent overflow
      spacing = 16.0;
    }

    // Calculate the height needed for the grid
    final itemHeight = 200.0; // Approximate height of each service card
    final rows = (filteredServices.length / crossAxisCount).ceil();
    final gridHeight = rows * itemHeight + (rows - 1) * spacing;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return _buildServiceCard(service, theme);
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, ThemeData theme) {
    final isActive = service['is_active'] == true;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with icon, name, category, and menu

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    ServiceIcons.getIcon(service['icon_name']),
                    color: LottoRunnersColors.primaryYellow,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] ?? 'Unnamed Service',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleServiceAction(value, service),
                  icon: const Icon(
                    Icons.more_vert,
                    color: LottoRunnersColors.primaryYellow,
                    size: 20,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: isActive ? 'deactivate' : 'activate',
                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description with proper overflow handling

            Flexible(
              child: Text(
                service['description'] ?? 'No description',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Price and status row

            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 14,
                  color: LottoRunnersColors.primaryYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  'N\$${(service['base_price'] ?? 0).toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LottoRunnersColors.primaryBlue,
                  ),
                ),
                const Spacer(),
                if (service['requires_vehicle'] == true) ...[
                  const Icon(
                    Icons.directions_car,
                    size: 14,
                    color: LottoRunnersColors.primaryYellow,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            // Discount info (if available)

            if (service['discount_percentage'] != null &&
                service['discount_percentage'] > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.local_offer,
                    size: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Discount: ${service['discount_percentage'].toStringAsFixed(0)}% OFF',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Business pricing info (if available)

            if (service['business_price'] != null &&
                service['business_price'] > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 12,
                    color: LottoRunnersColors.primaryYellow,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Business: N\$${service['business_price'].toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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

    _businessPriceController.clear();

    _discountPercentageController.clear();

    _requiresVehicle = false;

    _iconName = 'task_alt';
  }

  void _populateServiceForm(Map<String, dynamic> service) {
    _serviceNameController.text = service['name'] ?? '';

    _descriptionController.text = service['description'] ?? '';

    _basePriceController.text = service['base_price']?.toString() ?? '';

    _businessPriceController.text = service['business_price']?.toString() ?? '';

    _discountPercentageController.text = service['discount_percentage']?.toString() ?? '0';

    _requiresVehicle = service['requires_vehicle'] == true;

    final candidateIconName = service['icon_name'];
    // Ensure the currently stored icon exists in the available list to avoid
    // DropdownButton assertion errors when opening the dialog
    if (candidateIconName is String &&
        _availableIcons.any((icon) => icon['name'] == candidateIconName)) {
      _iconName = candidateIconName;
    } else {
      _iconName = 'task_alt';
    }

    //
  }

  void _showServiceDialog(String title, Map<String, dynamic>? service) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Service Name

                TextField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description

                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    hintText: 'Describe what this service offers...',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Category

                // FutureBuilder<List<Map<String, dynamic>>>(
                //   future: SupabaseConfig.getAllCategories(),
                //   builder: (context, snapshot) {
                //     if (snapshot.hasData) {
                //       final categories = snapshot.data!;
                //       // Remove duplicates and ensure unique values
                //       final uniqueCategories =
                //           categories.fold<List<Map<String, dynamic>>>(
                //         [],
                //         (list, category) {
                //           if (!list
                //               .any((item) => item['name'] == category['name'])) {
                //             list.add(category);
                //           }
                //           return list;
                //         },
                //       );
                //       // Set initial value if not set and categories exist
                //       if (_selectedServiceCategory == null &&
                //           uniqueCategories.isNotEmpty) {
                //         _selectedServiceCategory = uniqueCategories.first['name'];
                //       }
                //       return DropdownButtonFormField<String>(
                //         value: _selectedServiceCategory,
                //         decoration: InputDecoration(
                //           labelText: 'Category *',
                //           border: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           focusedBorder: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(12),
                //             borderSide: BorderSide(
                //               color: theme.colorScheme.primary,
                //               width: 2,
                //             ),
                //           ),
                //         ),
                //         items: uniqueCategories.map((category) {
                //           return DropdownMenuItem<String>(
                //             value: category['name'],
                //             child: Text(category['display_name']),
                //           );
                //         }).toList(),
                //         onChanged: (value) {
                //           if (value != null) {
                //             setStateDialog(() => _selectedServiceCategory = value);
                //           }
                //         },
                //       );
                //     } else {
                //       return DropdownButtonFormField<String>(
                //         decoration: InputDecoration(
                //           labelText: 'Category *',
                //           border: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //         ),
                //         items: const [],
                //         onChanged: null,
                //       );
                //     }
                //   },
                // ),

                //  const SizedBox(height: 16),

                // Icon Selection

                DropdownButtonFormField<String>(
                  // Guard against invalid/legacy icon values to prevent the
                  // DropdownButton assertion: there must be exactly one item
                  value:
                      _availableIcons.any((icon) => icon['name'] == _iconName)
                          ? _iconName
                          : null,
                  decoration: InputDecoration(
                    labelText: 'Service Icon *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: _availableIcons.map((iconData) {
                    return DropdownMenuItem<String>(
                      value: iconData['name'],
                      child: Row(
                        children: [
                          Icon(
                            iconData['icon'],
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(iconData['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setStateDialog(() => _iconName = value!),
                ),

                const SizedBox(height: 16),

                // Pricing Section

                Text(
                  'Pricing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                // Base Price

                TextField(
                  controller: _basePriceController,
                  decoration: InputDecoration(
                    labelText: 'Base Price (N\$) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Business Price

                TextField(
                  controller: _businessPriceController,
                  decoration: InputDecoration(
                    labelText: 'Business Price (N\$) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.business,
                      color: theme.colorScheme.primary,
                    ),
                    hintText: 'Price for business users',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Discount Percentage

                TextField(
                  controller: _discountPercentageController,
                  decoration: InputDecoration(
                    labelText: 'Discount Percentage (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.percent,
                      color: theme.colorScheme.primary,
                    ),
                    hintText: 'Enter discount (0-100)',
                    helperText: 'Leave 0 for no discount',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Requires Vehicle

                CheckboxListTile(
                  title: Text(
                    'Requires Vehicle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Check if this service needs a vehicle',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _requiresVehicle,
                  onChanged: (value) =>
                      setStateDialog(() => _requiresVehicle = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveService(service),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                service == null ? 'Add' : 'Save Changes',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveService(Map<String, dynamic>? existingService) async {
    try {
      // Validate required fields

      if (_serviceNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Service name is required'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );

        return;
      }

      // if (_selectedServiceCategory == null ||
      //     _selectedServiceCategory!.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: const Text('Service category is required'),
      //       backgroundColor: Theme.of(context).colorScheme.error,
      //     ),
      //   );
      //   return;
      // }

      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service description is required'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final basePrice = double.tryParse(_basePriceController.text);

      if (basePrice == null || basePrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid base price'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final businessPrice = double.tryParse(_businessPriceController.text);

      if (businessPrice == null || businessPrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid business price'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final discountPercentage = double.tryParse(_discountPercentageController.text) ?? 0.0;

      if (discountPercentage < 0 || discountPercentage > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount percentage must be between 0 and 100'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final serviceData = {
        'name': _serviceNameController.text.trim(),

        'description': _descriptionController.text.trim(),

        'base_price': basePrice,

        'business_price': businessPrice,

        'discount_percentage': discountPercentage,

        'requires_vehicle': _requiresVehicle,

        'icon_name': _iconName,

        'is_active': true, // Always set to active when creating/updating
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

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    try {
      final newStatus = !(service['is_active'] == true);

      final action = newStatus ? 'activate' : 'deactivate';

      // Show confirmation dialog for deactivation

      if (!newStatus) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Deactivate Service'),
            content: Text(
                'Are you sure you want to deactivate "${service['name']}"? This will make it unavailable to customers.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Deactivate'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      if (newStatus) {
        // Activate service

        await SupabaseConfig.updateService(
            service['id'], {'is_active': newStatus});
      } else {
        // Deactivate service

        await SupabaseConfig.deactivateService(service['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service ${action}d successfully!'),
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
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${service['name']}"?'),
            const SizedBox(height: 16),
            const Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Permanently remove the service from the database'),
            const Text('• Delete all associated pricing tiers'),
            const Text('• This action cannot be undone'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ WARNING: This will completely remove the service!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              try {
                // Show loading indicator

                if (mounted) {
                  ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('Deleting service...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                final success =
                    await SupabaseConfig.deleteService(service['id']);

                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Service "${service['name']}" deleted successfully'),
                        backgroundColor: LottoRunnersColors.accent,
                      ),
                    );

                    await _loadServices();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Failed to delete service. Please try again.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(rootContext).hideCurrentSnackBar();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting service: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }

                print('Delete service error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // Icon mapping moved to ServiceIcons utility for consistency across app.

  @override
  void dispose() {
    _serviceNameController.dispose();

    _descriptionController.dispose();

    _basePriceController.dispose();

    _businessPriceController.dispose();

    super.dispose();
  }
}
