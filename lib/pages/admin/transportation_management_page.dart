import 'package:flutter/material.dart';
import '../../supabase/supabase_config.dart';
import '../../utils/responsive.dart';

class TransportationManagementPage extends StatefulWidget {
  const TransportationManagementPage({Key? key}) : super(key: key);

  @override
  State<TransportationManagementPage> createState() =>
      _TransportationManagementPageState();
}

class _TransportationManagementPageState
    extends State<TransportationManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  List<Map<String, dynamic>> _towns = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _transportationServices = [];
  List<Map<String, dynamic>> _bookings = [];

  bool _isLoading = true;
  String _selectedTab = 'categories';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadCategories(),
        _loadSubcategories(),
        _loadVehicleTypes(),
        _loadTowns(),
        _loadRoutes(),
        _loadProviders(),
        _loadTransportationServices(),
        _loadBookings(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    final categories = await SupabaseConfig.getServiceCategories();
    setState(() => _categories = categories);
  }

  Future<void> _loadSubcategories() async {
    final subcategories = await SupabaseConfig.getServiceSubcategories();
    setState(() => _subcategories = subcategories);
  }

  Future<void> _loadVehicleTypes() async {
    final vehicleTypes = await SupabaseConfig.getVehicleTypes();
    setState(() => _vehicleTypes = vehicleTypes);
  }

  Future<void> _loadTowns() async {
    final towns = await SupabaseConfig.getTowns();
    setState(() => _towns = towns);
  }

  Future<void> _loadRoutes() async {
    final routes = await SupabaseConfig.getRoutes();
    setState(() => _routes = routes);
  }

  Future<void> _loadProviders() async {
    final providers = await SupabaseConfig.getServiceProviders();
    setState(() => _providers = providers);
  }

  Future<void> _loadTransportationServices() async {
    final services = await SupabaseConfig.getTransportationServices();
    setState(() => _transportationServices = services);
  }

  Future<void> _loadBookings() async {
    final bookings = await SupabaseConfig.getAllBookings();
    setState(() => _bookings = bookings);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transportation Management'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            setState(() {
              _selectedTab = [
                'categories',
                'subcategories',
                'vehicles',
                'towns',
                'routes',
                'providers',
                'services',
                'bookings'
              ][index];
            });
          },
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Subcategories'),
            Tab(text: 'Vehicles'),
            Tab(text: 'Towns'),
            Tab(text: 'Routes'),
            Tab(text: 'Providers'),
            Tab(text: 'Services'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildSubcategoriesTab(),
                _buildVehicleTypesTab(),
                _buildTownsTab(),
                _buildRoutesTab(),
                _buildProvidersTab(),
                _buildServicesTab(),
                _buildBookingsTab(),
              ],
            ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Service Categories',
          'Manage transportation service categories',
          onAdd: () => _showAddCategoryDialog(),
        ),
        Expanded(
          child: _categories.isEmpty
              ? const Center(child: Text('No categories found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubcategoriesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Service Subcategories',
          'Manage transportation service subcategories',
          onAdd: () => _showAddSubcategoryDialog(),
        ),
        Expanded(
          child: _subcategories.isEmpty
              ? const Center(child: Text('No subcategories found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = _subcategories[index];
                    return _buildSubcategoryCard(subcategory);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Vehicle Types',
          'Manage available vehicle types',
          onAdd: () => _showAddVehicleTypeDialog(),
        ),
        Expanded(
          child: _vehicleTypes.isEmpty
              ? const Center(child: Text('No vehicle types found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _vehicleTypes.length,
                  itemBuilder: (context, index) {
                    final vehicleType = _vehicleTypes[index];
                    return _buildVehicleTypeCard(vehicleType);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTownsTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Towns & Cities',
          'Manage destinations and pickup points',
          onAdd: () => _showAddTownDialog(),
        ),
        Expanded(
          child: _towns.isEmpty
              ? const Center(child: Text('No towns found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _towns.length,
                  itemBuilder: (context, index) {
                    final town = _towns[index];
                    return _buildTownCard(town);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoutesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Routes',
          'Manage transportation routes',
          onAdd: () => _showAddRouteDialog(),
        ),
        Expanded(
          child: _routes.isEmpty
              ? const Center(child: Text('No routes found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return _buildRouteCard(route);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProvidersTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Service Providers',
          'Manage transportation service providers',
          onAdd: () => _showAddProviderDialog(),
        ),
        Expanded(
          child: _providers.isEmpty
              ? const Center(child: Text('No providers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return _buildProviderCard(provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Transportation Services',
          'Manage available transportation services',
          onAdd: () => _showAddServiceDialog(),
        ),
        Expanded(
          child: _transportationServices.isEmpty
              ? const Center(child: Text('No services found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transportationServices.length,
                  itemBuilder: (context, index) {
                    final service = _transportationServices[index];
                    return _buildServiceCard(service);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    return Column(
      children: [
        _buildSectionHeader(
          'Transportation Bookings',
          'View and manage transportation bookings',
        ),
        Expanded(
          child: _bookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle,
      {VoidCallback? onAdd}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category['color']),
          child: Icon(
            _getCategoryIcon(category['icon']),
            color: Colors.white,
          ),
        ),
        title: Text(category['name'] ?? 'Unknown'),
        subtitle: Text(category['description'] ?? 'No description'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: category['is_active'] ?? false,
              onChanged: (value) =>
                  _toggleCategoryStatus(category['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _confirmDeleteCategory(category);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getSubcategoryIcon(subcategory['icon'])),
        title: Text(subcategory['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subcategory['service_categories'] != null)
              Text('Category: ${subcategory['service_categories']['name']}'),
            if (subcategory['description'] != null)
              Text(subcategory['description']),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: subcategory['is_active'] ?? false,
              onChanged: (value) =>
                  _toggleSubcategoryStatus(subcategory['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeCard(Map<String, dynamic> vehicleType) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getVehicleIcon(vehicleType['icon'])),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicleType['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Capacity: ${vehicleType['capacity']} seats'),
            if (vehicleType['features'] != null &&
                vehicleType['features'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    (vehicleType['features'] as List).map<Widget>((feature) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feature.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTownCard(Map<String, dynamic> town) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.location_city),
        title: Text(town['name'] ?? 'Unknown'),
        subtitle: Text('${town['region']}, ${town['country'] ?? 'Namibia'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: town['is_active'] ?? false,
              onChanged: (value) => _toggleTownStatus(town['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final originTown = route['origin_town'];
    final destinationTown = route['destination_town'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.route),
        title: Text(route['name'] ?? 'Unknown Route'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (originTown != null && destinationTown != null)
              Text('${originTown['name']} → ${destinationTown['name']}'),
            if (route['distance_km'] != null)
              Text('Distance: ${route['distance_km']} km'),
            if (route['estimated_duration_minutes'] != null)
              Text('Duration: ${route['estimated_duration_minutes']} min'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: route['is_active'] ?? false,
              onChanged: (value) => _toggleRouteStatus(route['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'schedules', child: Text('Schedules')),
                const PopupMenuItem(value: 'pricing', child: Text('Pricing')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(provider['name']?.substring(0, 1) ?? '?'),
        ),
        title: Text(provider['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider['contact_phone'] != null)
              Text('Phone: ${provider['contact_phone']}'),
            if (provider['rating'] != null)
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(
                      '${provider['rating']} (${provider['total_reviews']} reviews)'),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider['is_verified'] == true)
              const Icon(Icons.verified, color: Colors.green),
            Switch(
              value: provider['is_active'] ?? false,
              onChanged: (value) =>
                  _toggleProviderStatus(provider['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'verify', child: Text('Toggle Verification')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final subcategory = service['subcategory'];
    final provider = service['provider'];
    final vehicleType = service['vehicle_type'];
    final route = service['route'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.directions_bus),
        title: Text(service['name'] ?? 'Unknown Service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subcategory != null) Text('Category: ${subcategory['name']}'),
            if (provider != null) Text('Provider: ${provider['name']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: service['is_active'] ?? false,
              onChanged: (value) => _toggleServiceStatus(service['id'], value),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service['description'] != null) ...[
                  Text('Description: ${service['description']}'),
                  const SizedBox(height: 8),
                ],
                if (vehicleType != null) ...[
                  Text(
                      'Vehicle: ${vehicleType['name']} (${vehicleType['capacity']} seats)'),
                  const SizedBox(height: 8),
                ],
                if (route != null) ...[
                  Text('Route: ${route['name']}'),
                  const SizedBox(height: 8),
                ],
                if (service['features'] != null &&
                    service['features'].isNotEmpty) ...[
                  const Text('Features:'),
                  Wrap(
                    spacing: 4,
                    children:
                        (service['features'] as List).map<Widget>((feature) {
                      return Chip(
                        label: Text(feature.toString()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _manageServiceSchedules(service),
                      child: const Text('Schedules'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _manageServicePricing(service),
                      child: const Text('Pricing'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _editService(service),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final service = booking['service'];
    final user = booking['user'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getBookingStatusIcon(booking['status']),
          color: _getBookingStatusColor(booking['status']),
        ),
        title: Text(booking['booking_reference'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null)
              Text('Customer: ${user['first_name']} ${user['last_name']}'),
            if (service != null) Text('Service: ${service['name']}'),
            Text('Date: ${booking['booking_date']} ${booking['booking_time']}'),
            if (booking['final_price'] != null)
              Text('Price: NAD ${booking['final_price']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getBookingStatusColor(booking['status']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            booking['status']?.toUpperCase() ?? 'UNKNOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getBookingStatusColor(booking['status']),
            ),
          ),
        ),
        onTap: () => _showBookingDetails(booking),
      ),
    );
  }

  // Helper methods for icons and colors
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.category;
    }
  }

  IconData _getSubcategoryIcon(String? iconName) {
    switch (iconName) {
      case 'directions_bus':
        return Icons.directions_bus;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'flight':
        return Icons.flight;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  IconData _getVehicleIcon(String? iconName) {
    switch (iconName) {
      case 'directions_car':
        return Icons.directions_car;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_shipping':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  Color _getCategoryColor(String? colorHex) {
    if (colorHex == null) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getBookingStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle_outline;
      case 'no_show':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getBookingStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'no_show':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  // Status toggle methods
  Future<void> _toggleCategoryStatus(String id, bool isActive) async {
    final success =
        await SupabaseConfig.updateServiceCategoryStatus(id, isActive);
    if (success) {
      _showSuccessSnackBar('Category status updated');
      _loadCategories();
    } else {
      _showErrorSnackBar('Failed to update category status');
    }
  }

  Future<void> _toggleSubcategoryStatus(String id, bool isActive) async {
    // Implementation similar to category status
  }

  Future<void> _toggleTownStatus(String id, bool isActive) async {
    // Implementation for town status
  }

  Future<void> _toggleRouteStatus(String id, bool isActive) async {
    // Implementation for route status
  }

  Future<void> _toggleProviderStatus(String id, bool isActive) async {
    // Implementation for provider status
  }

  Future<void> _toggleServiceStatus(String id, bool isActive) async {
    final success =
        await SupabaseConfig.updateTransportationServiceStatus(id, isActive);
    if (success) {
      _showSuccessSnackBar('Service status updated');
      _loadTransportationServices();
    } else {
      _showErrorSnackBar('Failed to update service status');
    }
  }

  // Dialog methods (implementations would be quite long, showing structure)
  void _showAddCategoryDialog() {
    // Show dialog to add new category
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    // Show dialog to edit category
  }

  void _confirmDeleteCategory(Map<String, dynamic> category) {
    // Show confirmation dialog to delete category
  }

  void _showAddSubcategoryDialog() {
    // Show dialog to add new subcategory
  }

  void _showAddVehicleTypeDialog() {
    // Show dialog to add new vehicle type
  }

  void _showAddTownDialog() {
    // Show dialog to add new town
  }

  void _showAddRouteDialog() {
    // Show dialog to add new route
  }

  void _showAddProviderDialog() {
    // Show dialog to add new provider
  }

  void _showAddServiceDialog() {
    // Show dialog to add new service
  }

  void _manageServiceSchedules(Map<String, dynamic> service) {
    // Navigate to schedule management
  }

  void _manageServicePricing(Map<String, dynamic> service) {
    // Navigate to pricing management
  }

  void _editService(Map<String, dynamic> service) {
    // Show edit service dialog
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    // Show detailed booking information
  }
}
