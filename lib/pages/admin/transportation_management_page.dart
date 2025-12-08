import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import '../../supabase/supabase_config.dart';
import '../../utils/responsive.dart';

class TransportationManagementPage extends StatefulWidget {
  const TransportationManagementPage({super.key});

  @override
  State<TransportationManagementPage> createState() =>
      _TransportationManagementPageState();
}

class _TransportationManagementPageState
    extends State<TransportationManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists
  List<Map<String, dynamic>> _vehicleTypes = [];
  //List<Map<String, dynamic>> _towns = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _transportationServices = [];
  List<Map<String, dynamic>> _bookings = [];

  bool _isLoading = true;

  String _formatDays(dynamic days) {
    if (days == null) return '';
    final List<dynamic> list =
        days is List ? List<dynamic>.from(days) : <dynamic>[days];
    final List<int> normalized = list
        .map((d) => d is int
            ? d
            : int.tryParse(d.toString()) ?? _dayNameToInt(d.toString()))
        .where((d) => d > 0 && d <= 7)
        .toSet()
        .toList()
      ..sort();
    final names = normalized.map(_dayIntToName).toList();
    return names.join(', ');
  }

  int _dayNameToInt(String name) {
    switch (name.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 0;
    }
  }

  String _dayIntToName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _loadVehicleTypes(),
        // _loadTowns(),
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

  Future<void> _loadVehicleTypes() async {
    final vehicleTypes = await SupabaseConfig.getAllVehicleTypes();
    setState(() => _vehicleTypes = vehicleTypes);
  }

  // Future<void> _loadTowns() async {
  //   final towns = await SupabaseConfig.getAllTowns();
  //   setState(() => _towns = towns);
  // }

  Future<void> _loadRoutes() async {
    final routes = await SupabaseConfig.getAllRoutes();
    setState(() => _routes = routes);
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await SupabaseConfig.getAllProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading providers: $e');
    }
  }

  Future<void> _loadTransportationServices() async {
    print('🔄 Loading transportation services...');
    final services = await SupabaseConfig.getAllTransportationServices();
    print('📊 Loaded ${services.length} transportation services');
    for (var service in services) {
      final providers =
          service['providers'] as List<Map<String, dynamic>>? ?? [];
      print(
          '🚌 Service "${service['name']}" has ${providers.length} providers');
      for (var provider in providers) {
        print(
            '  👤 Provider: ${provider['provider']?['name']} - Features: ${provider['features']}');
      }
    }
    setState(() => _transportationServices = services);
    print('✅ Transportation services state updated');
  }

  Future<void> _loadBookings() async {
    final bookings = await SupabaseConfig.getAllBookings();
    setState(() => _bookings = bookings);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Transportation Management',
          style: TextStyle(fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 22)),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        iconTheme: IconThemeData(color: LottoRunnersColors.primaryYellow),
        actionsIconTheme:
            IconThemeData(color: LottoRunnersColors.primaryYellow),
        bottom: TabBar(
          controller: _tabController,
          // Make tabs evenly spaced and centered across the width
          isScrollable: false,
          labelPadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 8 : 12,
          ),
          tabs: [
            Tab(
              icon: Icon(
                Icons.directions_car,
                size: isSmallMobile ? 24 : (isMobile ? 26 : 28),
              ),
              text: isSmallMobile ? null : 'Vehicle Types',
              height: isSmallMobile ? 56 : (isMobile ? 60 : 64),
            ),
            Tab(
              icon: Icon(
                Icons.route,
                size: isSmallMobile ? 24 : (isMobile ? 26 : 28),
              ),
              text: isSmallMobile ? null : 'Routes',
              height: isSmallMobile ? 56 : (isMobile ? 60 : 64),
            ),
            Tab(
              icon: Icon(
                Icons.person,
                size: isSmallMobile ? 24 : (isMobile ? 26 : 28),
              ),
              text: isSmallMobile ? null : 'Providers',
              height: isSmallMobile ? 56 : (isMobile ? 60 : 64),
            ),
            Tab(
              icon: Icon(
                Icons.local_shipping,
                size: isSmallMobile ? 24 : (isMobile ? 26 : 28),
              ),
              text: isSmallMobile ? null : 'Services',
              height: isSmallMobile ? 56 : (isMobile ? 60 : 64),
            ),
            Tab(
              icon: Icon(
                Icons.book_online,
                size: isSmallMobile ? 24 : (isMobile ? 26 : 28),
              ),
              text: isSmallMobile ? null : 'Bookings',
              height: isSmallMobile ? 56 : (isMobile ? 60 : 64),
            ),
          ],
          labelStyle: TextStyle(
            fontSize: isSmallMobile ? 10 : (isMobile ? 11 : 12),
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: LottoRunnersColors.primaryYellow,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _loadData();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVehicleTypesTab(),
                //  _buildTownsTab(),
                _buildRoutesTab(),
                _buildProvidersTab(),
                _buildTransportationServicesTab(),
                _buildBookingsTab(),
              ],
            ),
    );
  }

  Widget _buildVehicleTypesTab() {
    final EdgeInsets padding = Responsive.getResponsivePadding(context);
    if (_vehicleTypes.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Vehicle Types',
              'Manage available vehicle types',
              onAdd: () => _addVehicleType(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No vehicle types found')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Vehicle Types',
            'Manage available vehicle types',
            onAdd: () => _addVehicleType(),
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.isSmallMobile(context)
                  ? 1
                  : (Responsive.isMobile(context) ? 2 : 3),
              childAspectRatio: Responsive.isSmallMobile(context)
                  ? 0.7
                  : (Responsive.isMobile(context) ? 0.8 : 0.6),
              crossAxisSpacing: Responsive.getResponsiveSpacing(context),
              mainAxisSpacing: Responsive.getResponsiveSpacing(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final vehicleType = _vehicleTypes[index];
                return _buildVehicleTypeCard(vehicleType);
              },
              childCount: _vehicleTypes.length,
            ),
          ),
        ),
      ],
    );
  }
  //delete this
  // Widget _buildTownsTab() {
  //   return Column(
  //     children: [
  //       _buildSectionHeader(
  //         'Towns & Cities',
  //         'Manage destinations and pickup points',
  //         onAdd: () => _addTown(),
  //       ),
  //       Expanded(
  //         child: _towns.isEmpty
  //             ? const Center(child: Text('No towns found'))
  //             : ListView.builder(
  //                 padding: Responsive.getResponsivePadding(context),
  //                 itemCount: _towns.length,
  //                 itemBuilder: (context, index) {
  //                   final town = _towns[index];
  //                   return _buildTownCard(town);
  //                 },
  //               ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildRoutesTab() {
    final EdgeInsets padding = Responsive.getResponsivePadding(context);
    if (_routes.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Routes',
              'Manage transportation routes',
              onAdd: () => _addRoute(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No routes found')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Routes',
            'Manage transportation routes',
            onAdd: () => _addRoute(),
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final route = _routes[index];
                return _buildRouteCard(route);
              },
              childCount: _routes.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProvidersTab() {
    final EdgeInsets padding = Responsive.getResponsivePadding(context);
    if (_providers.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Service Providers',
              'Manage transportation service providers',
              onAdd: () => _addProvider(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No providers found')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Service Providers',
            'Manage transportation service providers',
            onAdd: () => _addProvider(),
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final provider = _providers[index];
                return _buildProviderCard(provider);
              },
              childCount: _providers.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportationServicesTab() {
    final EdgeInsets padding = Responsive.getResponsivePadding(context);
    if (_transportationServices.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Transportation Services',
              'Manage available transportation services',
              onAdd: () => _addTransportationService(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No services found')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Transportation Services',
            'Manage available transportation services',
            onAdd: () => _addTransportationService(),
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = _transportationServices[index];
                return _buildServiceCard(service);
              },
              childCount: _transportationServices.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    final EdgeInsets padding = const EdgeInsets.all(16);
    if (_bookings.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Shuttle Services',
              'View and manage transportation bookings',
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No bookings found')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            'Shuttle Services',
            'View and manage transportation bookings',
          ),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final booking = _bookings[index];
                return _buildBookingCard(booking);
              },
              childCount: _bookings.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (onAdd != null)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add),
              label: const Text('Add'),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeCard(Map<String, dynamic> vehicleType) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context) * 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: Responsive.isSmallMobile(context) ? 28 : 36,
                  height: Responsive.isSmallMobile(context) ? 28 : 36,
                  alignment: Alignment.center,
                  child: Icon(
                    _getVehicleIcon(vehicleType['icon']),
                    size: Responsive.isSmallMobile(context) ? 20 : 24,
                  ),
                ),
                SizedBox(width: Responsive.isSmallMobile(context) ? 6 : 8),
                Expanded(
                  child: Text(
                    vehicleType['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editVehicleType(vehicleType);
                    } else if (value == 'delete') {
                      _deleteVehicleType(vehicleType);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: Responsive.isSmallMobile(context) ? 4 : 6),
            // Dependency indicator removed per request
            SizedBox(height: Responsive.isSmallMobile(context) ? 4 : 6),
            Text(
              'Capacity: ${vehicleType['capacity']} seats',
              style: TextStyle(
                fontSize: Responsive.isSmallMobile(context) ? 11 : 13,
              ),
            ),
            if (vehicleType['service_subcategory_ids'] != null &&
                (vehicleType['service_subcategory_ids'] as List)
                    .isNotEmpty) ...[
              SizedBox(height: Responsive.isSmallMobile(context) ? 2 : 3),
              Text(
                'Service Types:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: Responsive.isSmallMobile(context) ? 9 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: Responsive.isSmallMobile(context) ? 1 : 2),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getSubcategoryNames(
                  vehicleType['service_subcategory_ids'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Wrap(
                      spacing: Responsive.isSmallMobile(context) ? 1 : 2,
                      runSpacing: Responsive.isSmallMobile(context) ? 1 : 2,
                      children: snapshot.data!
                          .map(
                            (subcategory) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    Responsive.isSmallMobile(context) ? 3 : 4,
                                vertical:
                                    Responsive.isSmallMobile(context) ? 1 : 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                subcategory['name'],
                                style: TextStyle(
                                  fontSize:
                                      Responsive.isSmallMobile(context) ? 7 : 9,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return Text(
                    'No service types',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: Responsive.isSmallMobile(context) ? 9 : 10,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
            ],

            // Pricing Information
            if (vehicleType['price_base'] != null ||
                vehicleType['price_business'] != null) ...[
              SizedBox(height: Responsive.isSmallMobile(context) ? 4 : 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pricing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isSmallMobile(context) ? 11 : 13,
                    ),
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 1 : 2),
                  if (vehicleType['price_base'] != null)
                    Text(
                      'Base: NAD ${vehicleType['price_base'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 10 : 12,
                      ),
                    ),
                  if (vehicleType['price_business'] != null)
                    Text(
                      'Business: NAD ${vehicleType['price_business'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 10 : 12,
                      ),
                    ),
                  // Removed Per KM display per requirements
                ],
              ),
            ],

            if (vehicleType['features'] != null &&
                vehicleType['features'].isNotEmpty) ...[
              SizedBox(height: Responsive.isSmallMobile(context) ? 4 : 6),
              Wrap(
                spacing: Responsive.isSmallMobile(context) ? 1 : 2,
                runSpacing: Responsive.isSmallMobile(context) ? 1 : 2,
                children: (vehicleType['features'] as List).map<Widget>((
                  feature,
                ) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isSmallMobile(context) ? 3 : 4,
                      vertical: Responsive.isSmallMobile(context) ? 1 : 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      feature.toString(),
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 8 : 10,
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

  // Helper method to get subcategory names from IDs
  Future<List<Map<String, dynamic>>> _getSubcategoryNames(
    List<dynamic> subcategoryIds,
  ) async {
    try {
      if (subcategoryIds.isEmpty) return [];

      final response = await SupabaseConfig.client
          .from('service_subcategories')
          .select('id, name')
          .inFilter('id', subcategoryIds);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching subcategory names: $e');
      return [];
    }
  }

  // Widget _buildTownCard(Map<String, dynamic> town) {
  //   final isSmallMobile = Responsive.isSmallMobile(context);

  //   return Card(
  //     margin: EdgeInsets.only(bottom: Responsive.getResponsiveSpacing(context)),
  //     child: ListTile(
  //       leading: Icon(
  //         Icons.location_city,
  //         size: isSmallMobile ? 20 : 24,
  //       ),
  //       title: Text(
  //         town['name'] ?? 'Unknown',
  //         style: TextStyle(
  //           fontSize: isSmallMobile ? 14 : 16,
  //         ),
  //       ),
  //       subtitle: Text(
  //         '${town['region']}, ${town['country'] ?? 'Namibia'}',
  //         style: TextStyle(
  //           fontSize: isSmallMobile ? 11 : 13,
  //         ),
  //       ),
  //       trailing: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Switch(
  //             value: town['is_active'] ?? false,
  //             onChanged: (value) => _toggleTownStatus(town['id'], value),
  //           ),
  //           PopupMenuButton(
  //             itemBuilder: (context) => [
  //               const PopupMenuItem(value: 'edit', child: Text('Edit')),
  //               const PopupMenuItem(value: 'delete', child: Text('Delete')),
  //             ],
  //             onSelected: (value) {
  //               if (value == 'edit') {
  //                 _editTown(town);
  //               } else if (value == 'delete') {
  //                 _deleteTown(town);
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.route),
        title: Text(route['route_name'] ?? 'Unknown Route'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${route['from_location']} → ${route['to_location']}'),
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
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editRoute(route);
                } else if (value == 'delete') {
                  _deleteRoute(route);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: LottoRunnersColors.primaryYellow.withOpacity(0.15),
          child: Icon(
            Icons.storefront,
            color: LottoRunnersColors.primaryYellow,
          ),
        ),
        title: Text(provider['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider['description'] != null &&
                provider['description'].toString().isNotEmpty)
              Text('Description: ${provider['description']}'),
            if (provider['contact_phone'] != null &&
                provider['contact_phone'].toString().isNotEmpty)
              Text('Phone: ${provider['contact_phone']}'),
            if (provider['contact_email'] != null &&
                provider['contact_email'].toString().isNotEmpty)
              Text('Email: ${provider['contact_email']}'),
            Text(
              'Rating: ${(provider['rating'] ?? 0.00).toStringAsFixed(2)}/5.00',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: provider['is_active'] ?? false,
              onChanged: (value) =>
                  _toggleProviderStatus(provider['id'], value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editProvider(provider);
                } else if (value == 'delete') {
                  _deleteProvider(provider);
                }
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider['description'] != null &&
                    provider['description'].toString().isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(provider['description']),
                  const SizedBox(height: 8),
                ],
                if (provider['contact_phone'] != null &&
                    provider['contact_phone'].toString().isNotEmpty) ...[
                  const Text(
                    'Contact Phone:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(provider['contact_phone']),
                  const SizedBox(height: 8),
                ],
                if (provider['contact_email'] != null &&
                    provider['contact_email'].toString().isNotEmpty) ...[
                  const Text(
                    'Contact Email:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(provider['contact_email']),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Rating:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${(provider['rating'] ?? 0.00).toStringAsFixed(2)}/5.00'),
                const SizedBox(height: 8),
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(provider['is_active'] == true ? 'Active' : 'Inactive'),
                const SizedBox(height: 8),
                const Text(
                  'Created:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  provider['created_at'] != null
                      ? DateTime.parse(
                          provider['created_at'],
                        ).toString().split('.')[0]
                      : 'Unknown',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final route = service['route'];
    final providers = service['providers'] as List<Map<String, dynamic>>? ?? [];
    final isMobile = Responsive.isMobile(context);

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Service Icon
                Container(
                  width: isMobile ? 40 : 48,
                  height: isMobile ? 40 : 48,
                  decoration: BoxDecoration(
                    color:
                        LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: LottoRunnersColors.primaryYellow,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                // Service Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] ?? 'Unknown Service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      if (route != null)
                        Text(
                          'Route: ${route['route_name']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: isMobile ? 11 : 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      Text(
                        'Providers: ${providers.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: (service['is_active'] ?? false)
                        ? Colors.green.shade50
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (service['is_active'] ?? false)
                          ? Colors.green.shade200
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    (service['is_active'] ?? false) ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w500,
                      color: (service['is_active'] ?? false)
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons Row
            Row(
              children: [
                if (!isMobile) ...[
                  TextButton.icon(
                    onPressed: () => _editTransportationService(service),
                    icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                    label: Text(
                      'Edit',
                      style: TextStyle(fontSize: isMobile ? 11 : 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteTransportationService(service),
                    icon: Icon(Icons.delete_forever, size: isMobile ? 16 : 18),
                    label: Text(
                      'Delete',
                      style: TextStyle(fontSize: isMobile ? 11 : 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                // Toggle Switch
                Switch(
                  value: service['is_active'] ?? false,
                  onChanged: (value) =>
                      _toggleServiceStatus(service['id'], value),
                ),
              ],
            ),
            // Mobile-only buttons
            if (isMobile) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editTransportationService(service),
                      icon: Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteTransportationService(service),
                      icon: Icon(Icons.delete_forever, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final service = booking['service'];
    final user = booking['user'];
    final isMobile = Responsive.isMobile(context);

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Booking Icon
                Container(
                  width: isMobile ? 40 : 48,
                  height: isMobile ? 40 : 48,
                  decoration: BoxDecoration(
                    color: _getBookingStatusColor(booking['status'])
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getBookingStatusIcon(booking['status']),
                    color: _getBookingStatusColor(booking['status']),
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                // Booking Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['booking_reference'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      if (user != null)
                        Text(
                          'Customer: ${user['first_name']} ${user['last_name']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: isMobile ? 11 : 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      if (service != null)
                        Text(
                          'Service: ${service['name']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: isMobile ? 11 : 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getBookingStatusColor(booking['status'])
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBookingStatusColor(booking['status'])
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    booking['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w500,
                      color: _getBookingStatusColor(booking['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Additional Info Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isMobile ? 14 : 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  '${booking['booking_date']} ${booking['booking_time']}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
                const Spacer(),
                if (booking['final_price'] != null)
                  Text(
                    'NAD ${booking['final_price']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showBookingDetails(booking),
                icon: Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for icons and colors

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
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Future<void> _addVehicleType() async {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final descriptionController = TextEditingController();
    final basePriceController = TextEditingController();
    final businessPriceController = TextEditingController();
    // Removed per-km pricing from UI
    // final pricePerKmController = TextEditingController();

    // Icon dropdown state
    String selectedIconName = 'directions_car';

    // Get service subcategories for multi-select
    final subcategories = await SupabaseConfig.getAllServiceSubcategories();
    final visibleSubcategories = subcategories
        .where((s) =>
            !(s['name']?.toString().toLowerCase().contains('bus') ?? false))
        .toList();
    List<String> selectedSubcategoryIds = [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (passengers) *',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              // Icon dropdown with preview icons
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return DropdownButtonFormField<String>(
                    value: selectedIconName,
                    decoration: const InputDecoration(labelText: 'Icon'),
                    items: const [
                      DropdownMenuItem(
                        value: 'directions_car',
                        child: Row(children: [
                          Icon(Icons.directions_car),
                          SizedBox(width: 8),
                          Text('Car')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'airport_shuttle',
                        child: Row(children: [
                          Icon(Icons.airport_shuttle),
                          SizedBox(width: 8),
                          Text('Shuttle')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'local_shipping',
                        child: Row(children: [
                          Icon(Icons.local_shipping),
                          SizedBox(width: 8),
                          Text('Truck/Delivery')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'local_taxi',
                        child: Row(children: [
                          Icon(Icons.local_taxi),
                          SizedBox(width: 8),
                          Text('Taxi')
                        ]),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedIconName = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Service Subcategories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Select the service types this vehicle can provide:',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleSubcategories
                        .map(
                          (subcategory) => FilterChip(
                            label: Text(
                              subcategory['name'],
                              style: TextStyle(
                                color: selectedSubcategoryIds
                                        .contains(subcategory['id'])
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: selectedSubcategoryIds
                                      .contains(subcategory['id'])
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            selected: selectedSubcategoryIds.contains(
                              subcategory['id'],
                            ),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedSubcategoryIds.add(subcategory['id']);
                                } else {
                                  selectedSubcategoryIds.remove(
                                    subcategory['id'],
                                  );
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Pricing Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(
                  labelText: 'Base Price (NAD)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: businessPriceController,
                decoration: const InputDecoration(
                  labelText: 'Business Price (NAD)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              // Removed Price per KM field
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  capacityController.text.isNotEmpty &&
                  selectedSubcategoryIds.isNotEmpty) {
                final capacity = int.tryParse(capacityController.text);
                if (capacity != null) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'capacity': capacity,
                    'description': descriptionController.text,
                    'icon': selectedIconName,
                    'service_subcategory_ids': selectedSubcategoryIds,
                    'price_base': basePriceController.text.isNotEmpty
                        ? double.tryParse(basePriceController.text) ?? 0.0
                        : 0.0,
                    'price_business': businessPriceController.text.isNotEmpty
                        ? double.tryParse(businessPriceController.text) ?? 0.0
                        : 0.0,
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all required fields and select at least one service subcategory',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newVehicleType = await SupabaseConfig.createVehicleType(result);
        if (newVehicleType != null) {
          _showSuccessSnackBar('Vehicle type added successfully');
          _loadVehicleTypes();
        } else {
          _showErrorSnackBar('Failed to add vehicle type');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding vehicle type: $e');
      }
    }
  }

  Future<void> _editVehicleType(Map<String, dynamic> vehicleType) async {
    final nameController = TextEditingController(
      text: vehicleType['name'] ?? '',
    );
    final capacityController = TextEditingController(
      text: (vehicleType['capacity'] ?? 0).toString(),
    );
    final descriptionController = TextEditingController(
      text: vehicleType['description'] ?? '',
    );
    // Icon dropdown state for edit
    String selectedIconName =
        (vehicleType['icon'] as String?) ?? 'directions_car';
    const List<String> allowedIconValues = <String>[
      'directions_car',
      'airport_shuttle',
      'local_shipping',
      'local_taxi',
    ];
    if (!allowedIconValues.contains(selectedIconName)) {
      selectedIconName = 'directions_car';
    }
    final basePriceController = TextEditingController(
      text: (vehicleType['price_base'] ?? 0.0).toString(),
    );
    final businessPriceController = TextEditingController(
      text: (vehicleType['price_business'] ?? 0.0).toString(),
    );
    // Removed per-km pricing from UI

    // Get service subcategories for multi-select
    final subcategories = await SupabaseConfig.getAllServiceSubcategories();
    final visibleSubcategories = subcategories
        .where((s) =>
            !(s['name']?.toString().toLowerCase().contains('bus') ?? false))
        .toList();
    List<String> selectedSubcategoryIds = [];

    // Load existing selected subcategories if available
    if (vehicleType['service_subcategory_ids'] != null) {
      selectedSubcategoryIds = List<String>.from(
        vehicleType['service_subcategory_ids'],
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (passengers) *',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              // Icon dropdown with preview icons
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return DropdownButtonFormField<String>(
                    value: allowedIconValues.contains(selectedIconName)
                        ? selectedIconName
                        : null,
                    decoration: const InputDecoration(labelText: 'Icon'),
                    items: const [
                      DropdownMenuItem(
                        value: 'directions_car',
                        child: Row(children: [
                          Icon(Icons.directions_car),
                          SizedBox(width: 8),
                          Text('Car')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'airport_shuttle',
                        child: Row(children: [
                          Icon(Icons.airport_shuttle),
                          SizedBox(width: 8),
                          Text('Shuttle')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'local_shipping',
                        child: Row(children: [
                          Icon(Icons.local_shipping),
                          SizedBox(width: 8),
                          Text('Truck/Delivery')
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'local_taxi',
                        child: Row(children: [
                          Icon(Icons.local_taxi),
                          SizedBox(width: 8),
                          Text('Taxi')
                        ]),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedIconName = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Service Subcategories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Select the service types this vehicle can provide:',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleSubcategories
                        .map(
                          (subcategory) => FilterChip(
                            label: Text(
                              subcategory['name'],
                              style: TextStyle(
                                color: selectedSubcategoryIds
                                        .contains(subcategory['id'])
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: selectedSubcategoryIds
                                      .contains(subcategory['id'])
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            selected: selectedSubcategoryIds.contains(
                              subcategory['id'],
                            ),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedSubcategoryIds.add(subcategory['id']);
                                } else {
                                  selectedSubcategoryIds.remove(
                                    subcategory['id'],
                                  );
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Pricing Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(
                  labelText: 'Base Price (NAD)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: businessPriceController,
                decoration: const InputDecoration(
                  labelText: 'Business Price (NAD)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              // Removed Price per KM field
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  capacityController.text.isNotEmpty &&
                  selectedSubcategoryIds.isNotEmpty) {
                // Validate name length
                if (nameController.text.length > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name cannot exceed 100 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final capacity = int.tryParse(capacityController.text);
                if (capacity == null || capacity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Capacity must be a positive number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (capacity > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Capacity cannot exceed 100 passengers'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate pricing fields
                if (basePriceController.text.isNotEmpty &&
                    double.tryParse(basePriceController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Base price must be a valid number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (businessPriceController.text.isNotEmpty &&
                    double.tryParse(businessPriceController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Business price must be a valid number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Removed per-km validation

                Navigator.pop(context, {
                  'name': nameController.text,
                  'capacity': capacity,
                  'description': descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  'icon': selectedIconName,
                  'service_subcategory_ids': selectedSubcategoryIds.isNotEmpty
                      ? selectedSubcategoryIds
                      : null,
                  'price_base': basePriceController.text.isNotEmpty
                      ? double.tryParse(basePriceController.text)
                      : null,
                  'price_business': businessPriceController.text.isNotEmpty
                      ? double.tryParse(businessPriceController.text)
                      : null,
                  // Removed per-km field
                });
              } else {
                // Show error message if required fields are empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all required fields and select at least one service subcategory',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Prepare vehicle data with pricing fields included
        final vehicleData = Map<String, dynamic>.from(result);

        // Debug: Print the data being sent
        print(
          'Updating vehicle type ${vehicleType['id']} with data: $vehicleData',
        );

        // Update vehicle type using the simpler method
        final success = await SupabaseConfig.updateVehicleType(
          vehicleType['id'],
          vehicleData,
        );

        if (success) {
          _showSuccessSnackBar('Vehicle type updated successfully');
          _loadVehicleTypes();
        } else {
          _showErrorSnackBar('Failed to update vehicle type');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating vehicle type: $e');
      }
    }
  }

  Future<void> _deleteVehicleType(Map<String, dynamic> vehicleType) async {
    // First check for dependencies
    final dependencies = await SupabaseConfig.getVehicleTypeDependencies(
      vehicleType['id'],
    );

    if (dependencies.isNotEmpty) {
      // Show dependency warning dialog
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Vehicle Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cannot delete "${vehicleType['name']}" because it is currently used by ${dependencies.length} transportation service(s):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...dependencies.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${service['name']}'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'To delete this vehicle type, you must first remove or reassign all transportation services that use it.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If no dependencies, proceed with deletion confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle Type'),
        content: Text(
          'Are you sure you want to delete "${vehicleType['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await SupabaseConfig.deleteVehicleType(
          vehicleType['id'],
        );
        if (success) {
          _showSuccessSnackBar('Vehicle type deleted successfully');
          _loadVehicleTypes();
        } else {
          _showErrorSnackBar('Failed to delete vehicle type');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting vehicle type: $e');
      }
    }
  }

  Future<void> _showVehicleTypeDependencies(
    Map<String, dynamic> vehicleType,
  ) async {
    try {
      final allDependencies =
          await SupabaseConfig.getAllVehicleTypeDependencies(vehicleType['id']);
      final services = allDependencies['services'] ?? [];
      final pricing = allDependencies['pricing'] ?? [];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Dependencies for ${vehicleType['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (services.isEmpty && pricing.isEmpty) ...[
                const Text(
                  'This vehicle type is not currently used by any transportation services or pricing tiers.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else ...[
                if (services.isNotEmpty) ...[
                  Text(
                    'Transportation Services (${services.length}):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Row(
                        children: [
                          Icon(
                            service['is_active'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: service['is_active'] == true
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(service['name'])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (pricing.isNotEmpty) ...[
                  Text(
                    'Pricing Tiers (${pricing.length}):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...pricing.map(
                    (tier) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Service ID: ${tier['service_id']} - Base Price: NAD ${tier['base_price']?.toStringAsFixed(2) ?? 'N/A'}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'To delete this vehicle type, you must first remove or reassign all dependencies.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            if (services.isNotEmpty) ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showReassignDialog(vehicleType, services);
                },
                child: const Text('Reassign Services'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error loading dependencies: $e');
    }
  }

  Future<void> _showReassignDialog(
    Map<String, dynamic> vehicleType,
    List<Map<String, dynamic>> dependencies,
  ) async {
    // Get all other vehicle types for reassignment
    final otherVehicleTypes =
        _vehicleTypes.where((vt) => vt['id'] != vehicleType['id']).toList();

    if (otherVehicleTypes.isEmpty) {
      _showErrorSnackBar('No other vehicle types available for reassignment');
      return;
    }

    String? selectedVehicleTypeId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Transportation Services'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a new vehicle type to reassign ${dependencies.length} transportation service(s) from "${vehicleType['name']}":',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedVehicleTypeId,
              decoration: const InputDecoration(
                labelText: 'New Vehicle Type',
                border: OutlineInputBorder(),
              ),
              items: otherVehicleTypes
                  .map(
                    (vt) => DropdownMenuItem<String>(
                      value: vt['id'] as String,
                      child: Text('${vt['name']} (${vt['capacity']} seats)'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                selectedVehicleTypeId = value;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Warning: This action will update all transportation services currently using "${vehicleType['name']}" to use the selected vehicle type instead.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedVehicleTypeId != null
                ? () => Navigator.pop(context, true)
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );

    if (confirmed == true && selectedVehicleTypeId != null) {
      try {
        final success = await SupabaseConfig.reassignTransportationServices(
          vehicleType['id'] as String,
          selectedVehicleTypeId!,
        );

        if (success) {
          _showSuccessSnackBar(
            'Transportation services reassigned successfully',
          );
          _loadTransportationServices(); // Refresh the services list
          _loadVehicleTypes(); // Refresh the vehicle types list
        } else {
          _showErrorSnackBar('Failed to reassign transportation services');
        }
      } catch (e) {
        _showErrorSnackBar('Error reassigning services: $e');
      }
    }
  }

  Future<void> _toggleRouteStatus(String id, bool isActive) async {
    try {
      final success = await SupabaseConfig.updateRoute(id, {
        'is_active': isActive,
      });
      if (success) {
        _showSuccessSnackBar('Route status updated');
        _loadRoutes();
      } else {
        _showErrorSnackBar('Failed to update route status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating route status: $e');
    }
  }

  // Future<void> _addTown() async {
  //   final nameController = TextEditingController();
  //   final regionController = TextEditingController();
  //   final countryController = TextEditingController(text: 'Namibia');
  //   final latitudeController = TextEditingController();
  //   final longitudeController = TextEditingController();

  //   final result = await showDialog<Map<String, dynamic>>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Add Town'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: nameController,
  //               decoration: const InputDecoration(labelText: 'Name *'),
  //             ),
  //             TextField(
  //               controller: regionController,
  //               decoration: const InputDecoration(labelText: 'Region'),
  //             ),
  //             TextField(
  //               controller: countryController,
  //               decoration: const InputDecoration(labelText: 'Country'),
  //             ),
  //             TextField(
  //               controller: latitudeController,
  //               decoration: const InputDecoration(labelText: 'Latitude'),
  //               keyboardType: TextInputType.number,
  //             ),
  //             TextField(
  //               controller: longitudeController,
  //               decoration: const InputDecoration(labelText: 'Longitude'),
  //               keyboardType: TextInputType.number,
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             if (nameController.text.isNotEmpty) {
  //               Navigator.pop(context, {
  //                 'name': nameController.text,
  //                 'region': regionController.text.isNotEmpty
  //                     ? regionController.text
  //                     : null,
  //                 'country': countryController.text.isNotEmpty
  //                     ? countryController.text
  //                     : 'Namibia',
  //                 'latitude': latitudeController.text.isNotEmpty
  //                     ? double.tryParse(latitudeController.text)
  //                     : null,
  //                 'longitude': longitudeController.text.isNotEmpty
  //                     ? double.tryParse(longitudeController.text)
  //                     : null,
  //                 'is_active': true,
  //               });
  //             }
  //           },
  //           child: const Text('Add'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (result != null) {
  //     try {
  //       final newTown = await SupabaseConfig.createTown(result);
  //       if (newTown != null) {
  //         _showSuccessSnackBar('Town added successfully');
  //         _loadTowns();
  //       } else {
  //         _showErrorSnackBar('Failed to add town');
  //       }
  //     } catch (e) {
  //       _showErrorSnackBar('Error adding town: $e');
  //     }
  //   }
  // }

  // Future<void> _editTown(Map<String, dynamic> town) async {
  //   final nameController = TextEditingController(text: town['name'] ?? '');
  //   final regionController = TextEditingController(text: town['region'] ?? '');
  //   final countryController =
  //       TextEditingController(text: town['country'] ?? 'Namibia');
  //   final latitudeController = TextEditingController(
  //       text: town['latitude'] != null ? town['latitude'].toString() : '');
  //   final longitudeController = TextEditingController(
  //       text: town['longitude'] != null ? town['longitude'].toString() : '');

  //   final result = await showDialog<Map<String, dynamic>>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Edit Town'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: nameController,
  //               decoration: const InputDecoration(labelText: 'Name *'),
  //             ),
  //             TextField(
  //               controller: regionController,
  //               decoration: const InputDecoration(labelText: 'Region'),
  //             ),
  //             TextField(
  //               controller: countryController,
  //               decoration: const InputDecoration(labelText: 'Country'),
  //             ),
  //             TextField(
  //               controller: latitudeController,
  //               decoration: const InputDecoration(labelText: 'Latitude'),
  //               keyboardType: TextInputType.number,
  //             ),
  //             TextField(
  //               controller: longitudeController,
  //               decoration: const InputDecoration(labelText: 'Longitude'),
  //               keyboardType: TextInputType.number,
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             if (nameController.text.isNotEmpty) {
  //               Navigator.pop(context, {
  //                 'name': nameController.text,
  //                 'region': regionController.text.isNotEmpty
  //                     ? regionController.text
  //                     : null,
  //                 'country': countryController.text.isNotEmpty
  //                     ? countryController.text
  //                     : 'Namibia',
  //                 'latitude': latitudeController.text.isNotEmpty
  //                     ? double.tryParse(latitudeController.text)
  //                     : null,
  //                 'longitude': longitudeController.text.isNotEmpty
  //                     ? double.tryParse(longitudeController.text)
  //                     : null,
  //               });
  //             }
  //           },
  //           child: const Text('Save'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (result != null) {
  //     try {
  //       final success = await SupabaseConfig.updateTown(town['id'], result);
  //       if (success) {
  //         _showSuccessSnackBar('Town updated successfully');
  //         //_loadTowns();
  //       } else {
  //         _showErrorSnackBar('Failed to update town');
  //       }
  //     } catch (e) {
  //       _showErrorSnackBar('Error updating town: $e');
  //     }
  //   }
  // }

  // Future<void> _deleteTown(Map<String, dynamic> town) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Delete Town'),
  //       content: Text(
  //           'Are you sure you want to delete "${town['name']}"? This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     try {
  //       final success = await SupabaseConfig.deleteTown(town['id']);
  //       if (success) {
  //         _showSuccessSnackBar('Town deleted successfully');
  //         //_loadTowns();
  //       } else {
  //         _showErrorSnackBar('Failed to delete town');
  //       }
  //     } catch (e) {
  //       _showErrorSnackBar('Error deleting town: $e');
  //     }
  //   }
  // }

  Future<void> _toggleProviderStatus(String id, bool isActive) async {
    try {
      final success = await SupabaseConfig.updateServiceProvider(id, {
        'is_active': isActive,
      });
      if (success) {
        _showSuccessSnackBar('Provider status updated');
        _loadProviders();
      } else {
        _showErrorSnackBar('Failed to update provider status');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating provider status: $e');
    }
  }

  Future<void> _addRoute() async {
    final nameController = TextEditingController();
    final fromLocationController = TextEditingController();
    final toLocationController = TextEditingController();
    final distanceController = TextEditingController();
    final durationController = TextEditingController();
    //final routeTypeController = TextEditingController();

    // Get transportation services for dropdown
    //final services = await SupabaseConfig.getAllTransportationServices();
    String? selectedServiceId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Route Name *'),
              ),
              // DropdownButtonFormField<String>(
              //   value: selectedServiceId,
              //   decoration: const InputDecoration(
              //     labelText: 'Transportation Service *',
              //   ),
              //   items: services
              //       .map<DropdownMenuItem<String>>(
              //         (service) => DropdownMenuItem<String>(
              //           value: service['id'] as String,
              //           child: Text(service['name'] as String),
              //         ),
              //       )
              //       .toList(),
              //   onChanged: (value) => selectedServiceId = value,
              // ),
              TextField(
                controller: fromLocationController,
                decoration: const InputDecoration(labelText: 'From Location *'),
              ),
              TextField(
                controller: toLocationController,
                decoration: const InputDecoration(labelText: 'To Location *'),
              ),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
              ),
              // DropdownButtonFormField<String>(
              //   value: routeTypeController.text.isNotEmpty
              //       ? routeTypeController.text
              //       : null,
              //   decoration: const InputDecoration(labelText: 'Route Type'),
              //   items: const [
              //     DropdownMenuItem(
              //       value: 'intercity',
              //       child: Text('Intercity'),
              //     ),
              //     DropdownMenuItem(value: 'local', child: Text('Local')),
              //     DropdownMenuItem(value: 'airport', child: Text('Airport')),
              //     DropdownMenuItem(value: 'shuttle', child: Text('Shuttle')),
              //   ],
              //   onChanged: (value) => routeTypeController.text = value ?? '',
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  //  selectedServiceId != null &&
                  fromLocationController.text.isNotEmpty &&
                  toLocationController.text.isNotEmpty) {
                Navigator.pop(context, {
                  //  'service_id': selectedServiceId,
                  'route_name': nameController.text,
                  'from_location': fromLocationController.text,
                  'to_location': toLocationController.text,
                  'distance_km': distanceController.text.isNotEmpty
                      ? double.tryParse(distanceController.text)
                      : null,
                  'estimated_duration_minutes':
                      durationController.text.isNotEmpty
                          ? int.tryParse(durationController.text)
                          : null,
                  // 'route_type': routeTypeController.text.isNotEmpty
                  //     ? routeTypeController.text
                  //     : 'intercity',
                  'is_active': true,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newRoute = await SupabaseConfig.createRoute(result);
        if (newRoute != null) {
          _showSuccessSnackBar('Route added successfully');
          _loadRoutes();
        } else {
          _showErrorSnackBar('Failed to add route');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding route: $e');
      }
    }
  }

  Future<void> _editRoute(Map<String, dynamic> route) async {
    final nameController = TextEditingController(
      text: route['route_name'] ?? '',
    );
    final fromLocationController = TextEditingController(
      text: route['from_location'] ?? '',
    );
    final toLocationController = TextEditingController(
      text: route['to_location'] ?? '',
    );
    final distanceController = TextEditingController(
      text: route['distance_km'] != null ? route['distance_km'].toString() : '',
    );
    final durationController = TextEditingController(
      text: route['estimated_duration_minutes'] != null
          ? route['estimated_duration_minutes'].toString()
          : '',
    );
    // final routeTypeController = TextEditingController(
    //   text: route['route_type'] ?? 'intercity',
    // );

    // Get transportation services for dropdown
    final services = await SupabaseConfig.getAllTransportationServices();
    String? selectedServiceId = route['service_id'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Route Name *'),
              ),
              // DropdownButtonFormField<String>(
              //   value: selectedServiceId,
              //   decoration: const InputDecoration(
              //     labelText: 'Transportation Service *',
              //   ),
              //   items: services
              //       .map<DropdownMenuItem<String>>(
              //         (service) => DropdownMenuItem<String>(
              //           value: service['id'] as String,
              //           child: Text(service['name'] as String),
              //         ),
              //       )
              //       .toList(),
              //   onChanged: (value) => selectedServiceId = value,
              // ),
              TextField(
                controller: fromLocationController,
                decoration: const InputDecoration(labelText: 'From Location *'),
              ),
              TextField(
                controller: toLocationController,
                decoration: const InputDecoration(labelText: 'To Location *'),
              ),
              TextField(
                controller: distanceController,
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
              ),
              // DropdownButtonFormField<String>(
              //   value: routeTypeController.text.isNotEmpty
              //       ? routeTypeController.text
              //       : null,
              //   decoration: const InputDecoration(labelText: 'Route Type'),
              //   items: const [
              //     DropdownMenuItem(
              //       value: 'intercity',
              //       child: Text('Intercity'),
              //     ),
              //     DropdownMenuItem(value: 'local', child: Text('Local')),
              //     DropdownMenuItem(value: 'airport', child: Text('Airport')),
              //     DropdownMenuItem(value: 'shuttle', child: Text('Shuttle')),
              //   ],
              //   onChanged: (value) => routeTypeController.text = value ?? '',
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  //  selectedServiceId != null &&
                  fromLocationController.text.isNotEmpty &&
                  toLocationController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'route_name': nameController.text,
                  'from_location': fromLocationController.text,
                  'to_location': toLocationController.text,
                  'distance_km': distanceController.text.isNotEmpty
                      ? double.tryParse(distanceController.text)
                      : null,
                  'estimated_duration_minutes':
                      durationController.text.isNotEmpty
                          ? int.tryParse(durationController.text)
                          : null,
                  // 'route_type': routeTypeController.text.isNotEmpty
                  //     ? routeTypeController.text
                  //     : 'intercity',
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final success = await SupabaseConfig.updateRoute(route['id'], result);
        if (success) {
          _showSuccessSnackBar('Route updated successfully');
          _loadRoutes();
        } else {
          _showErrorSnackBar('Failed to update route');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating route: $e');
      }
    }
  }

  Future<void> _deleteRoute(Map<String, dynamic> route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text(
          'Are you sure you want to delete "${route['route_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await SupabaseConfig.deleteRoute(route['id']);
        if (success) {
          _showSuccessSnackBar('Route deleted successfully');
          _loadRoutes();
        } else {
          _showErrorSnackBar('Failed to delete route');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting route: $e');
      }
    }
  }

  Future<void> _toggleServiceStatus(String id, bool isActive) async {
    final success = await SupabaseConfig.updateTransportationServiceStatus(
      id,
      isActive,
    );
    if (success) {
      _showSuccessSnackBar('Service status updated');
      _loadTransportationServices();
    } else {
      _showErrorSnackBar('Failed to update service status');
    }
  }

  // CRUD Operations for Providers (using service_providers table)
  Future<void> _addProvider() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final contactPhoneController = TextEditingController();
    final contactEmailController = TextEditingController();
    final ratingController = TextEditingController(text: '0.00');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Provider Name *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactEmailController,
                decoration: const InputDecoration(labelText: 'Contact Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (0.00 - 5.00)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  locationController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'location': locationController.text,
                  'description': descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  'contact_phone': contactPhoneController.text.isNotEmpty
                      ? contactPhoneController.text
                      : null,
                  'contact_email': contactEmailController.text.isNotEmpty
                      ? contactEmailController.text
                      : null,
                  'rating': double.tryParse(ratingController.text) ?? 0.00,
                  'is_active': true,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Provider name and location are required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newProvider = await SupabaseConfig.createProvider(result);
        if (newProvider != null) {
          _showSuccessSnackBar('Provider added successfully');
          _loadProviders();
        } else {
          _showErrorSnackBar('Failed to add provider');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding provider: $e');
      }
    }
  }

  Future<void> _editProvider(Map<String, dynamic> provider) async {
    final nameController = TextEditingController(text: provider['name'] ?? '');
    final locationController =
        TextEditingController(text: provider['location'] ?? '');
    final descriptionController = TextEditingController(
      text: provider['description'] ?? '',
    );
    final contactPhoneController = TextEditingController(
      text: provider['contact_phone'] ?? '',
    );
    final contactEmailController = TextEditingController(
      text: provider['contact_email'] ?? '',
    );
    final ratingController = TextEditingController(
      text: (provider['rating'] ?? 0.00).toString(),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Provider Name *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactEmailController,
                decoration: const InputDecoration(labelText: 'Contact Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (0.00 - 5.00)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  locationController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'location': locationController.text,
                  'description': descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  'contact_phone': contactPhoneController.text.isNotEmpty
                      ? contactPhoneController.text
                      : null,
                  'contact_email': contactEmailController.text.isNotEmpty
                      ? contactEmailController.text
                      : null,
                  'rating': double.tryParse(ratingController.text) ?? 0.00,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Provider name and location are required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final success = await SupabaseConfig.updateProvider(
          provider['id'],
          result,
        );
        if (success) {
          _showSuccessSnackBar('Provider updated successfully');
          _loadProviders();
        } else {
          _showErrorSnackBar('Failed to update provider');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating provider: $e');
      }
    }
  }

  Future<void> _deleteProvider(Map<String, dynamic> provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text(
          'Are you sure you want to delete "${provider['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await SupabaseConfig.deleteProvider(provider['id']);
        if (success) {
          _showSuccessSnackBar('Provider deleted successfully');
          _loadProviders();
        } else {
          _showErrorSnackBar('Failed to delete provider');
        }
      } catch (e) {
        // Handle specific error types with better user messages
        String errorMessage;
        if (e.toString().contains('foreign key constraint') &&
            e.toString().contains('transportation_services')) {
          errorMessage =
              'Cannot delete this provider because it is currently assigned to transportation services. '
              'Please remove the provider from all services before deleting.';
        } else if (e.toString().contains('foreign key constraint')) {
          errorMessage =
              'Cannot delete this provider because it is referenced by other data. '
              'Please remove all related services and bookings before deleting.';
        } else {
          errorMessage = 'Error deleting provider: ${e.toString()}';
        }

        // Show a detailed error dialog instead of just a snackbar
        _showDetailedErrorDialog(
          title: 'Cannot Delete Provider',
          message: errorMessage,
          details: e.toString(),
        );
      }
    }
  }

  // CRUD Operations for Transportation Services
  Future<void> _addTransportationService() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    // Get data for dropdowns
    final providers = await SupabaseConfig.getAllProviders();
    final activeProviders =
        providers.where((p) => (p['is_active'] ?? false) == true).toList();
    final routes = await SupabaseConfig.getAllRoutes();
    final activeRoutes =
        routes.where((r) => (r['is_active'] ?? false) == true).toList();

    String? selectedRouteId;
    List<Map<String, dynamic>> serviceProviders = [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Bus Service'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Service Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Service Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedRouteId,
                            decoration: const InputDecoration(
                              labelText: 'Route *',
                              border: OutlineInputBorder(),
                            ),
                            items: activeRoutes
                                .map<DropdownMenuItem<String>>(
                                  (route) => DropdownMenuItem<String>(
                                    value: route['id'] as String,
                                    child: Text(route['route_name'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedRouteId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Providers Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Service Providers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddProviderDialog(
                                  context,
                                  activeProviders,
                                  serviceProviders,
                                  setDialogState,
                                ),
                                icon: Icon(Icons.add),
                                label: const Text('Add Provider'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (serviceProviders.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'No providers added yet.\nClick "Add Provider" to add at least one provider.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: serviceProviders.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final provider = serviceProviders[index];
                                final providerInfo = activeProviders.firstWhere(
                                  (p) => p['id'] == provider['provider_id'],
                                  orElse: () => {'name': 'Unknown Provider'},
                                );

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            providerInfo['name'] ??
                                                'Unknown Provider',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    _editProviderDetails(
                                                  context,
                                                  index,
                                                  serviceProviders,
                                                  setDialogState,
                                                  '', // No service ID yet for new services
                                                ),
                                                icon: Icon(Icons.edit,
                                                    size: 20),
                                                tooltip: 'Edit',
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setDialogState(() {
                                                    serviceProviders
                                                        .removeAt(index);
                                                  });
                                                },
                                                icon: Icon(Icons.delete,
                                                    size: 20,
                                                    color: Colors.red),
                                                tooltip: 'Remove',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                'Price: KSH ${provider['price']}'),
                                          ),
                                          Expanded(
                                            child: Text(
                                                'Departure: ${provider['departure_time']}'),
                                          ),
                                        ],
                                      ),
                                      if (provider['check_in_time'] !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                            'Check-in: ${provider['check_in_time']}'),
                                      ],
                                      if (provider['days_of_week'] != null &&
                                          provider['days_of_week']
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                            'Days: ${_formatDays(provider['days_of_week'])}'),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Booking: ${provider['advance_booking_hours'] ?? 1}h advance, ${provider['cancellation_hours'] ?? 2}h cancellation',
                                        style: TextStyle(
                                            fontSize: 12, color: Theme.of(context).colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    selectedRouteId != null &&
                    serviceProviders.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'route_id': selectedRouteId,
                    'providers': serviceProviders,
                    'is_active': true,
                  });
                } else {
                  // Show validation message
                  String message = '';
                  if (nameController.text.isEmpty) {
                    message = 'Service name is required';
                  } else if (selectedRouteId == null) {
                    message = 'Route selection is required';
                  } else if (serviceProviders.isEmpty) {
                    message = 'At least one provider must be added';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Service'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final newService = await SupabaseConfig.createTransportationService(
          result,
        );
        if (newService != null) {
          _showSuccessSnackBar('Transportation service added successfully');
          _loadTransportationServices();
        } else {
          _showErrorSnackBar('Failed to add transportation service');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding transportation service: $e');
      }
    }
  }

  // Helper method to show add provider dialog
  void _showAddProviderDialog(
    BuildContext context,
    List<Map<String, dynamic>> providers,
    List<Map<String, dynamic>> serviceProviders,
    Function setDialogState,
  ) {
    final priceController = TextEditingController();
    final departureTimeController = TextEditingController();
    final checkInTimeController = TextEditingController();
    final advanceBookingController = TextEditingController(text: '1');
    final cancellationController = TextEditingController(text: '2');

    String? selectedProviderId;
    List<String> selectedDays = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setProviderDialogState) => AlertDialog(
          title: const Text('Add Provider Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedProviderId,
                  decoration: const InputDecoration(
                    labelText: 'Service Provider *',
                    border: OutlineInputBorder(),
                  ),
                  items: providers
                      .where((prov) => !serviceProviders
                          .any((sp) => sp['provider_id'] == prov['id']))
                      .where((prov) => (prov['is_active'] ?? false) == true)
                      .map<DropdownMenuItem<String>>(
                        (prov) => DropdownMenuItem<String>(
                          value: prov['id'] as String,
                          child: Text(prov['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setProviderDialogState(() {
                      selectedProviderId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (KSH) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: departureTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Departure Time *',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: checkInTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Time',
                    hintText: '07:30',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: advanceBookingController,
                        decoration: const InputDecoration(
                          labelText: 'Advance Booking (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cancellationController,
                        decoration: const InputDecoration(
                          labelText: 'Cancellation (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Days of the Week:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final days = [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: days.map((day) {
                        final selected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onSelected: (val) {
                            setProviderDialogState(() {
                              if (val) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
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
              onPressed: () {
                if (selectedProviderId != null &&
                    priceController.text.isNotEmpty &&
                    departureTimeController.text.isNotEmpty) {
                  // Get provider name
                  final selectedProvider = providers.firstWhere(
                    (p) => p['id'] == selectedProviderId,
                    orElse: () => {'name': 'Unknown Provider'},
                  );

                  setDialogState(() {
                    serviceProviders.add({
                      'provider_id': selectedProviderId,
                      'provider_name':
                          selectedProvider['name'] ?? 'Unknown Provider',
                      'price': double.tryParse(priceController.text) ?? 0,
                      'departure_time': departureTimeController.text,
                      'check_in_time': checkInTimeController.text.isNotEmpty
                          ? checkInTimeController.text
                          : null,
                      'days_of_week':
                          selectedDays.isNotEmpty ? selectedDays : null,
                      'advance_booking_hours':
                          int.tryParse(advanceBookingController.text) ?? 1,
                      'cancellation_hours':
                          int.tryParse(cancellationController.text) ?? 2,
                    });
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to edit provider details
  void _editProviderDetails(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> serviceProviders,
    Function setDialogState,
    String serviceId,
  ) {
    final provider = serviceProviders[index];
    final priceController = TextEditingController(
      text: provider['price']?.toString() ?? '',
    );
    final departureTimeController = TextEditingController(
      text: provider['departure_time'] ?? '',
    );
    final checkInTimeController = TextEditingController(
      text: provider['check_in_time'] ?? '',
    );
    final advanceBookingController = TextEditingController(
      text: provider['advance_booking_hours']?.toString() ?? '1',
    );
    final cancellationController = TextEditingController(
      text: provider['cancellation_hours']?.toString() ?? '2',
    );

    List<String> selectedDays = provider['days_of_week'] != null
        ? List<String>.from(provider['days_of_week'])
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setProviderDialogState) => AlertDialog(
          title: const Text('Edit Provider Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (KSH) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: departureTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Departure Time *',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: checkInTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Time',
                    hintText: '07:30',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: advanceBookingController,
                        decoration: const InputDecoration(
                          labelText: 'Advance Booking (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cancellationController,
                        decoration: const InputDecoration(
                          labelText: 'Cancellation (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Days of the week with visible colors
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Operating Days',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setDaysState) {
                    final theme = Theme.of(context);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ].map((day) {
                        final selected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onSelected: (val) {
                            setDaysState(() {
                              if (val) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Days of the Week:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ]
                      .map(
                        (day) => FilterChip(
                          label: Text(day),
                          selected: selectedDays.contains(day),
                          onSelected: (selected) {
                            setProviderDialogState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
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
              onPressed: () async {
                if (priceController.text.isNotEmpty &&
                    departureTimeController.text.isNotEmpty) {
                  final updatedProvider = {
                    'provider_id': provider['provider_id'],
                    'price': double.tryParse(priceController.text) ?? 0,
                    'departure_time': departureTimeController.text,
                    'check_in_time': checkInTimeController.text.isNotEmpty
                        ? checkInTimeController.text
                        : null,
                    'days_of_week':
                        selectedDays.isNotEmpty ? selectedDays : null,
                    'advance_booking_hours':
                        int.tryParse(advanceBookingController.text) ?? 1,
                    'cancellation_hours':
                        int.tryParse(cancellationController.text) ?? 2,
                  };

                  if (serviceId.isEmpty) {
                    // For new services being created, just update local state
                    setDialogState(() {
                      serviceProviders[index] = updatedProvider;
                    });
                    Navigator.pop(context);
                    _showSuccessSnackBar('Provider details updated');
                  } else {
                    // For existing services, save to database
                    try {
                      final success =
                          await SupabaseConfig.updateServiceProviderData(
                        serviceId,
                        provider['provider_id'],
                        updatedProvider,
                      );

                      if (success) {
                        // Update local state
                        setDialogState(() {
                          serviceProviders[index] = updatedProvider;
                        });
                        Navigator.pop(context);
                        _showSuccessSnackBar(
                            'Provider details updated successfully');
                        _loadTransportationServices(); // Refresh the data
                      } else {
                        _showErrorSnackBar('Failed to update provider details');
                      }
                    } catch (e) {
                      _showErrorSnackBar('Error updating provider details: $e');
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Add provider to existing service
  Future<void> _addProviderToService(Map<String, dynamic> service) async {
    final providers = await SupabaseConfig.getAllProviders();
    final existingProviders =
        service['providers'] as List<Map<String, dynamic>>? ?? [];
    List<Map<String, dynamic>> serviceProviders = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Provider to Service'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddProviderDialog(
                      context,
                      providers
                          .where((p) => !existingProviders
                              .any((ep) => ep['provider_id'] == p['id']))
                          .toList(),
                      serviceProviders,
                      setDialogState,
                    ),
                    icon: Icon(Icons.add),
                    label: const Text('Add Provider'),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: serviceProviders.isEmpty
                        ? const Center(
                            child: Text('No providers selected'),
                          )
                        : ListView.builder(
                            itemCount: serviceProviders.length,
                            itemBuilder: (context, index) {
                              final provider = serviceProviders[index];
                              final providerInfo = providers.firstWhere(
                                (p) => p['id'] == provider['provider_id'],
                                orElse: () => {'name': 'Unknown Provider'},
                              );
                              return ListTile(
                                title: Text(providerInfo['name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Price: KSH ${provider['price']} - Departure: ${provider['departure_time']}'),
                                    Text(
                                        'Booking: ${provider['advance_booking_hours'] ?? 1}h advance, ${provider['cancellation_hours'] ?? 2}h cancellation',
                                        style: TextStyle(
                                            fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      serviceProviders.removeAt(index);
                                    });
                                  },
                                  icon: Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              );
                            },
                          ),
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
                onPressed: () async {
                  if (serviceProviders.isNotEmpty) {
                    try {
                      // Add each provider individually using the array-based method
                      for (var provider in serviceProviders) {
                        await SupabaseConfig.addProviderToService(
                          service['id'],
                          provider,
                        );
                      }
                      Navigator.pop(context);
                      _showSuccessSnackBar('Provider(s) added successfully');
                      _loadTransportationServices();
                    } catch (e) {
                      _showErrorSnackBar('Error adding provider(s): $e');
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Edit service provider details
  Future<void> _editServiceProvider(
      String serviceId, Map<String, dynamic> providerDetail) async {
    final priceController = TextEditingController(
      text: providerDetail['price']?.toString() ?? '',
    );
    final departureTimeController = TextEditingController(
      text: providerDetail['departure_time'] ?? '',
    );
    final checkInTimeController = TextEditingController(
      text: providerDetail['check_in_time'] ?? '',
    );
    final advanceBookingController = TextEditingController(
      text: providerDetail['advance_booking_hours']?.toString() ?? '1',
    );
    final cancellationController = TextEditingController(
      text: providerDetail['cancellation_hours']?.toString() ?? '2',
    );

    List<String> selectedDays = providerDetail['days_of_week'] != null
        ? List<String>.from(providerDetail['days_of_week'])
        : [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Provider Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (KSH) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: departureTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Departure Time *',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: checkInTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Time',
                    hintText: '07:30',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: advanceBookingController,
                        decoration: const InputDecoration(
                          labelText: 'Advance Booking (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cancellationController,
                        decoration: const InputDecoration(
                          labelText: 'Cancellation (hours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Days of the Week',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ].map((day) {
                    final selected = selectedDays.contains(day);
                    final theme = Theme.of(context);
                    return FilterChip(
                      label: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
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
              onPressed: () {
                if (priceController.text.isNotEmpty &&
                    departureTimeController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'price': double.tryParse(priceController.text) ?? 0,
                    'departure_time': departureTimeController.text,
                    'check_in_time': checkInTimeController.text.isNotEmpty
                        ? checkInTimeController.text
                        : null,
                    'days_of_week':
                        selectedDays.isNotEmpty ? selectedDays : null,
                    'advance_booking_hours':
                        int.tryParse(advanceBookingController.text) ?? 1,
                    'cancellation_hours':
                        int.tryParse(cancellationController.text) ?? 2,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final ok = await SupabaseConfig.updateServiceProviderData(
          serviceId,
          providerDetail['provider_id'],
          result,
        );
        if (ok) {
          _showSuccessSnackBar('Provider details updated successfully');
          print('🔄 Refreshing transportation services after update...');
          await _loadTransportationServices();
          print('✅ Transportation services refreshed');
          setState(() {});
          print('✅ UI state updated');
        } else {
          _showErrorSnackBar('Update did not persist on the server');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating provider details: $e');
      }
    }
  }

  // Remove service provider
  Future<void> _removeServiceProvider(
      String serviceId, String providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Provider'),
        content: const Text(
          'Are you sure you want to remove this provider from the service? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.removeProviderFromService(serviceId, providerId);
        _showSuccessSnackBar('Provider removed successfully');
        _loadTransportationServices();
      } catch (e) {
        // Handle specific error types with better user messages
        String errorMessage;
        if (e.toString().contains('foreign key constraint') &&
            e.toString().contains('bus_service_bookings')) {
          errorMessage =
              'Cannot remove this provider because it has existing bookings. '
              'Please cancel or complete all bookings for this provider before removing.';
        } else if (e.toString().contains('foreign key constraint')) {
          errorMessage =
              'Cannot remove this provider because it is referenced by other data. '
              'Please resolve all related bookings before removing.';
        } else {
          errorMessage = 'Error removing provider: ${e.toString()}';
        }

        // Show a detailed error dialog instead of just a snackbar
        _showDetailedErrorDialog(
          title: 'Cannot Remove Provider',
          message: errorMessage,
          details: e.toString(),
        );
      }
    }
  }

  Future<void> _editTransportationService(Map<String, dynamic> service) async {
    final nameController = TextEditingController(text: service['name'] ?? '');
    final descriptionController = TextEditingController(
      text: service['description'] ?? '',
    );
    // final pickupRadiusController = TextEditingController(
    //   text: service['pickup_radius_km'] != null
    //       ? service['pickup_radius_km'].toString()
    //       : '',
    // );

    // Get data for dropdowns
    final routes = await SupabaseConfig.getAllRoutes();
    final activeRoutes =
        routes.where((r) => (r['is_active'] ?? false) == true).toList();

    String? selectedRouteId = service['route_id'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bus Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service Name *'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              // DropdownButtonFormField<String>(
              //   value: selectedSubcategoryId,
              //   decoration: const InputDecoration(labelText: 'Subcategory'),
              //   items: subcategories
              //       .map<DropdownMenuItem<String>>(
              //         (sub) => DropdownMenuItem<String>(
              //           value: sub['id'] as String,
              //           child: Text(sub['name'] as String),
              //         ),
              //       )
              //       .toList(),
              //   onChanged: (value) => selectedSubcategoryId = value,
              // ),
              // DropdownButtonFormField<String>(
              //   value: selectedVehicleTypeId,
              //   decoration: const InputDecoration(labelText: 'Vehicle Type'),
              //   items: vehicleTypes
              //       .map<DropdownMenuItem<String>>(
              //         (vt) => DropdownMenuItem<String>(
              //           value: vt['id'] as String,
              //           child: Text(
              //             '${vt['name']} (${vt['capacity']} passengers)',
              //           ),
              //         ),
              //       )
              //       .toList(),
              //   onChanged: (value) => selectedVehicleTypeId = value,
              // ),
              DropdownButtonFormField<String>(
                value: selectedRouteId,
                decoration: const InputDecoration(labelText: 'Route'),
                items: activeRoutes
                    .map<DropdownMenuItem<String>>(
                      (route) => DropdownMenuItem<String>(
                        value: route['id'] as String,
                        child: Text(route['route_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedRouteId = value,
              ),
              // TextField(
              //   controller: pickupRadiusController,
              //   decoration: const InputDecoration(
              //     labelText: 'Pickup Radius (km)',
              //   ),
              //   keyboardType: TextInputType.number,
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'route_id': selectedRouteId,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final success = await SupabaseConfig.updateTransportationService(
          service['id'],
          result,
        );
        if (success) {
          _showSuccessSnackBar('Bus service updated successfully');
          _loadTransportationServices();
        } else {
          _showErrorSnackBar('Failed to update bus service');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating bus service: $e');
      }
    }
  }

  Future<void> _deleteTransportationService(
    Map<String, dynamic> service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus Service'),
        content: Text(
          'Are you sure you want to delete "${service['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await SupabaseConfig.deleteTransportationService(
          service['id'],
        );
        if (success) {
          _showSuccessSnackBar('Bus service deleted successfully');
          _loadTransportationServices();
        } else {
          _showErrorSnackBar('Failed to delete bus service');
        }
      } catch (e) {
        // Handle specific error types with better user messages
        String errorMessage;
        if (e.toString().contains('foreign key constraint') &&
            e.toString().contains('bus_service_bookings')) {
          errorMessage =
              'Cannot delete this service because it has existing bookings. '
              'Please cancel or complete all bookings before deleting the service.';
        } else if (e.toString().contains('foreign key constraint')) {
          errorMessage =
              'Cannot delete this service because it is referenced by other data. '
              'Please remove all related bookings and data before deleting.';
        } else {
          errorMessage = 'Error deleting bus service: ${e.toString()}';
        }

        // Show error message with recommendation to use toggle
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cannot delete service: ${service['name']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(errorMessage),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recommendation: Use the toggle switch to deactivate instead',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  // Show delete error with deactivate option
  void _showDeleteErrorWithDeactivateOption({
    required Map<String, dynamic> service,
    required String errorMessage,
    required String technicalDetails,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cannot Delete Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instead of deleting, you can deactivate this service. This will:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Hide the service from users\n• Preserve existing bookings\n• Allow reactivation later',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deactivateTransportationService(service);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate Instead'),
          ),
        ],
      ),
    );
  }

  // Deactivate transportation service instead of deleting
  Future<void> _deactivateTransportationService(
      Map<String, dynamic> service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.pause_circle_outline,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deactivate Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to deactivate "${service['name']}"?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'What happens when deactivated:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Service will be hidden from users\n• Existing bookings will be preserved\n• Service can be reactivated later\n• No data will be lost',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    if (confirmed == true) {
      try {
        final success = await SupabaseConfig.updateTransportationService(
          service['id'],
          {'is_active': false},
        );

        if (success) {
          _showSuccessSnackBar(
              'Service "${service['name']}" has been deactivated successfully');
          _loadTransportationServices();
        } else {
          _showErrorSnackBar('Failed to deactivate service');
        }
      } catch (e) {
        _showErrorSnackBar('Error deactivating service: $e');
      }
    }
  }

  // Show detailed error dialog for better error handling
  void _showDetailedErrorDialog({
    required String title,
    required String message,
    String? details,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
            if (details != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Technical Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Removed pricing management
  // void _manageVehiclePricing(Map<String, dynamic> vehicleType) {}

  /*
  void _showVehiclePricingDialog(Map<String, dynamic> vehicleType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Pricing - ${vehicleType['name']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current pricing display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Pricing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base Price: NAD ${vehicleType['price_base']?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                    Text(
                      'Business Price: NAD ${vehicleType['price_business']?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pricing tiers (removed)
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  */

  void _showAddPricingTierDialog(String vehicleTypeId) {}

  /* void _showEditPricingTierDialog(Map<String, dynamic> tier) {
    final minDistanceController = TextEditingController(
      text: tier['min_distance_km']?.toString() ?? '',
    );
    final maxDistanceController = TextEditingController(
      text: tier['max_distance_km']?.toString() ?? '',
    );
    final basePriceController = TextEditingController(
      text: tier['base_price']?.toString() ?? '',
    );
    final businessPriceController = TextEditingController(
      text: tier['business_price']?.toString() ?? '',
    );
    final pricePerKmController = TextEditingController(
      text: tier['price_per_km']?.toString() ?? '',
    );
    final tierNameController = TextEditingController(
      text: tier['tier_name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pricing Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Min Distance (km) *',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: maxDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Max Distance (km)',
                  hintText: 'Leave empty for unlimited',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: basePriceController,
                decoration: const InputDecoration(
                  labelText: 'Base Price (NAD) *',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: businessPriceController,
                decoration: const InputDecoration(
                  labelText: 'Business Price (NAD) *',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: pricePerKmController,
                decoration: const InputDecoration(
                  labelText: 'Price per KM (NAD)',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              TextField(
                controller: tierNameController,
                decoration: const InputDecoration(
                  labelText: 'Tier Name',
                  hintText: 'e.g., Local, Regional, Long Distance',
                ),
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
            onPressed: () async {
              if (minDistanceController.text.isNotEmpty &&
                  basePriceController.text.isNotEmpty &&
                  businessPriceController.text.isNotEmpty) {
                final updates = {
                  'min_distance_km':
                      double.tryParse(minDistanceController.text) ?? 0,
                  'max_distance_km': maxDistanceController.text.isNotEmpty
                      ? double.tryParse(maxDistanceController.text)
                      : null,
                  'base_price': double.tryParse(basePriceController.text) ?? 0,
                  'business_price':
                      double.tryParse(businessPriceController.text) ?? 0,
                  'price_per_km': pricePerKmController.text.isNotEmpty
                      ? double.tryParse(pricePerKmController.text) ?? 0
                      : 0,
                  'tier_name': tierNameController.text.isNotEmpty
                      ? tierNameController.text
                      : null,
                };

                try {
                  await SupabaseConfig.updateVehiclePricingTier(
                    tier['id'],
                    updates,
                  );
                  Navigator.pop(context); // Close edit tier dialog
                  // Pricing dialog removed
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unable to update pricing tier. Please check your internet connection and try again.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  */

  Future<void> _deletePricingTier(String tierId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pricing Tier'),
        content: const Text(
          'Are you sure you want to delete this pricing tier?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.deleteVehiclePricingTier(tierId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing tier deleted successfully')),
        );
        // Refresh the pricing dialog
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to delete pricing tier. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _manageServiceSchedules(Map<String, dynamic> service) {}

  void _manageServicePricing(Map<String, dynamic> service) {}

  /// Manage schedules for a specific route

  void _showBookingDetails(Map<String, dynamic> booking) {}
}
