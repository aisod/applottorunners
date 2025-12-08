import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../widgets/location_input_field.dart';

class ServiceSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onServiceSelected;
  final String? initialServiceType;
  final bool showTransportationOnly;

  const ServiceSelector({
    super.key,
    required this.onServiceSelected,
    this.initialServiceType,
    this.showTransportationOnly = false,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _transportationServices = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  List<Map<String, dynamic>> _towns = [];

  String? _selectedSubcategoryId;
  String? _selectedServiceId;
  String? _selectedVehicleTypeId;
  String? _selectedRouteId;
  String? _selectedOriginTownId;
  String? _selectedDestinationTownId;

  bool _isLoading = true;
  String _activeTab = 'services';

  // Booking details
  int _passengerCount = 1;
  bool _needsHomePickup = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _pickupLocation;
  String? _dropoffLocation;
  String _selectedVehicleClass = 'standard';

  // Text controllers for location fields
  late final TextEditingController _pickupLocationController;
  late final TextEditingController _dropoffLocationController;

  Map<String, dynamic>? _priceEstimate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showTransportationOnly ? 1 : 2,
      vsync: this,
    );

    if (widget.showTransportationOnly) {
      _activeTab = 'transportation';
    }

    // Initialize text controllers
    _pickupLocationController = TextEditingController();
    _dropoffLocationController = TextEditingController();

    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Load data in parallel for better performance
      final futures = <Future>[];

      if (!widget.showTransportationOnly) {
        futures.add(_loadServices());
      }

      futures.addAll([
        _loadSubcategories(),
        _loadVehicleTypes(),
        _loadTowns(),
      ]);

      await Future.wait(futures);
    } catch (e) {
      print('Error loading initial data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load services. Please check your internet connection and try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServices() async {
    final services = await SupabaseConfig.getServices();
    setState(() {
      _services = services;
    });
  }

  Future<void> _loadSubcategories() async {
    final subcategories = await SupabaseConfig.getTransportationSubcategories();
    setState(() {
      _subcategories = subcategories;
      _selectedSubcategoryId = null;
      _transportationServices.clear();
    });
  }

  Future<void> _loadTransportationServices(String subcategoryId) async {
    final services =
        await SupabaseConfig.getTransportationServices(subcategoryId);
    setState(() {
      _transportationServices = services;
      _selectedServiceId = null;
    });
  }

  Future<void> _loadVehicleTypes() async {
    final vehicleTypes = await SupabaseConfig.getVehicleTypes();
    setState(() {
      _vehicleTypes = vehicleTypes;
    });
  }

  Future<void> _loadVehicleTypesBySubcategory(String subcategoryId) async {
    final vehicleTypes =
        await SupabaseConfig.getVehicleTypesBySubcategory(subcategoryId);
    setState(() {
      _vehicleTypes = vehicleTypes;
    });
  }

  Future<void> _loadTowns() async {
    final towns = await SupabaseConfig.getTowns();
    setState(() {
      _towns = towns;
    });
  }

  Future<void> _calculatePrice() async {
    if (_selectedServiceId == null) return;

    try {
      final estimate = await SupabaseConfig.calculateTransportationServicePrice(
        serviceId: _selectedServiceId!,
        passengerCount: _passengerCount,
        includePickup: _needsHomePickup,
        bookingDate: _selectedDate,
      );

      setState(() {
        _priceEstimate = estimate;
      });
    } catch (e) {
      print('Error calculating price: $e');
    }
  }

  void _onSubcategorySelected(String subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
      _selectedServiceId = null;
      _priceEstimate = null;
    });
    _loadTransportationServices(subcategoryId);
    _loadVehicleTypesBySubcategory(subcategoryId);
  }

  void _onServiceSelected(Map<String, dynamic> service) {
    setState(() {
      _selectedServiceId = service['id'];
    });
    _calculatePrice();
  }

  void _onBookingDetailsChanged() {
    _calculatePrice();
  }

  void _submitSelection() {
    Map<String, dynamic> selectionData = {};

    if (_activeTab == 'services' && !widget.showTransportationOnly) {
      // Regular service selection
      final selectedService = _services.firstWhere(
        (service) => service['id'] == _selectedServiceId,
        orElse: () => {},
      );

      selectionData = {
        'type': 'service',
        'service': selectedService,
        'passenger_count': _passengerCount,
        'needs_pickup': _needsHomePickup,
        'selected_date': _selectedDate?.toIso8601String(),
        'selected_time': _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'pickup_location': _pickupLocation,
        'dropoff_location': _dropoffLocation,
        'price_estimate': _priceEstimate,
      };
    } else {
      // Transportation service selection
      final selectedService = _transportationServices.firstWhere(
        (service) => service['id'] == _selectedServiceId,
        orElse: () => {},
      );

      selectionData = {
        'type': 'transportation',
        'service': selectedService,
        'subcategory_id': _selectedSubcategoryId,
        'vehicle_type_id': _selectedVehicleTypeId,
        'route_id': _selectedRouteId,
        'origin_town_id': _selectedOriginTownId,
        'destination_town_id': _selectedDestinationTownId,
        'vehicle_class': _selectedVehicleClass,
        'passenger_count': _passengerCount,
        'needs_pickup': _needsHomePickup,
        'selected_date': _selectedDate?.toIso8601String(),
        'selected_time': _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'pickup_location': _pickupLocation,
        'dropoff_location': _dropoffLocation,
        'price_estimate': _priceEstimate,
      };
    }

    widget.onServiceSelected(selectionData);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showTransportationOnly) _buildTabBar(),
        Expanded(
          child: _activeTab == 'services' && !widget.showTransportationOnly
              ? _buildServicesTab()
              : _buildTransportationTab(),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _activeTab = index == 0 ? 'services' : 'transportation';
            _selectedServiceId = null;
            _priceEstimate = null;
          });
        },
        tabs: const [
          Tab(text: 'General Services'),
          Tab(text: 'Transportation'),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceGrid(),
          if (_selectedServiceId != null) ...[
            const SizedBox(height: 24),
            _buildBookingDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubcategorySelection(),
          if (_selectedSubcategoryId != null) ...[
            const SizedBox(height: 16),
            _buildTransportationServiceGrid(),
          ],
          if (_selectedServiceId != null) ...[
            const SizedBox(height: 24),
            _buildTransportationBookingDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context)
            ? 2
            : Responsive.isTablet(context)
                ? 3
                : 4,
        childAspectRatio: Responsive.isMobile(context) ? 1.1 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        final isSelected = service['id'] == _selectedServiceId;

        return GestureDetector(
          onTap: () => _onServiceSelected(service),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : LottoRunnersColors.gray50,
              border: Border.all(
                color: isSelected
                    ? LottoRunnersColors.primaryBlue
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.build,
                  size: 32,
                  color: isSelected
                      ? LottoRunnersColors.primaryBlue
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    service['name'] ?? 'Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? LottoRunnersColors.primaryBlue
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (service['description'] != null) ...[
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      service['description'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubcategorySelection() {
    if (_subcategories.isEmpty) {
      return const Center(
        child: Text('No subcategories available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.isMobile(context)
                ? 2
                : Responsive.isTablet(context)
                    ? 3
                    : 5,
            childAspectRatio: Responsive.isMobile(context) ? 1.2 : 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = _subcategories[index];
            final isSelected = subcategory['id'] == _selectedSubcategoryId;

            // Determine if this is a shuttle or contract service
            final isShuttle =
                subcategory['name']?.toLowerCase().contains('shuttle') ?? false;
            final isContract =
                subcategory['name']?.toLowerCase().contains('contract') ??
                    false;

            return GestureDetector(
              onTap: () => _onSubcategorySelected(subcategory['id']),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  border: Border.all(
                    color: isSelected
                        ? LottoRunnersColors.primaryBlue
                        : Colors.grey.shade700,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isShuttle || isContract
                          ? Icons.directions_car
                          : _getSubcategoryIcon(subcategory['icon']),
                      size: 32,
                      color: isSelected
                          ? (isShuttle || isContract
                              ? LottoRunnersColors.primaryBlue
                              : LottoRunnersColors.primaryBlue)
                          : Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        subcategory['name'] ?? 'Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isShuttle || isContract
                                  ? LottoRunnersColors.primaryBlue
                                  : LottoRunnersColors.primaryBlue)
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        isShuttle
                            ? 'On-Demand Vehicles'
                            : isContract
                                ? 'Business Contracts'
                                : 'Scheduled Services',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? (isShuttle || isContract
                                  ? LottoRunnersColors.primaryBlue
                                  : LottoRunnersColors.primaryBlue)
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransportationServiceGrid() {
    if (_transportationServices.isEmpty) {
      return const Center(
        child: Text('No services available for this category'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _transportationServices.length,
          itemBuilder: (context, index) {
            final service = _transportationServices[index];
            final isSelected = service['id'] == _selectedServiceId;
            final route = service['route'];
            final vehicleType = service['vehicle_type'];
            final provider = service['provider'];

            return GestureDetector(
              onTap: () => _onServiceSelected(service),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : LottoRunnersColors.gray50,
                  border: Border.all(
                    color: isSelected
                        ? LottoRunnersColors.primaryBlue
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service['name'] ?? 'Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? LottoRunnersColors.primaryBlue
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (provider != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              provider['name'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (service['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        service['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Responsive layout for route and vehicle info
                    Responsive.isMobile(context)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (route != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        route['name'] ?? 'Route',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (vehicleType != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${vehicleType['name']} (${vehicleType['capacity']} seats)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              if (route != null) ...[
                                Icon(
                                  Icons.route,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    route['name'] ?? 'Route',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                              if (vehicleType != null) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.directions_car,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${vehicleType['name']} (${vehicleType['capacity']} seats)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                    if (service['features'] != null &&
                        service['features'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (service['features'] as List)
                            .map<Widget>((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: LottoRunnersColors.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              feature.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: LottoRunnersColors.gray700,
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
          },
        ),
      ],
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildPassengerCountSelector(),
          const SizedBox(height: 16),
          _buildDateTimeSelector(),
          const SizedBox(height: 16),
          _buildLocationInputs(),
          const SizedBox(height: 16),
          _buildHomePickupToggle(),
          if (_priceEstimate != null) ...[
            const SizedBox(height: 16),
            _buildPriceEstimate(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportationBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transportation Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildVehicleClassSelector(),
          const SizedBox(height: 16),
          _buildPassengerCountSelector(),
          const SizedBox(height: 16),
          _buildDateTimeSelector(),
          const SizedBox(height: 16),
          _buildLocationInputs(),
          const SizedBox(height: 16),
          _buildHomePickupToggle(),
          if (_priceEstimate != null) ...[
            const SizedBox(height: 16),
            _buildPriceEstimate(),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Class:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildVehicleClassOption(
                'economic', 'Economic', Icons.directions_car, Colors.green),
            const SizedBox(width: 12),
            _buildVehicleClassOption(
                'standard', 'Standard', Icons.airport_shuttle, Colors.blue),
            const SizedBox(width: 12),
            _buildVehicleClassOption(
                'premium', 'Premium', Icons.directions_bus, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleClassOption(
      String value, String label, IconData icon, Color color) {
    final isSelected = _selectedVehicleClass == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVehicleClass = value;
          });
          _onBookingDetailsChanged();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCountSelector() {
    return Row(
      children: [
        const Text(
          'Passengers:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _passengerCount > 1
              ? () {
                  setState(() {
                    _passengerCount--;
                  });
                  _onBookingDetailsChanged();
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _passengerCount.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _passengerCount++;
            });
            _onBookingDetailsChanged();
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                    _onBookingDetailsChanged();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                    _onBookingDetailsChanged();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select Time',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInputs() {
    return Column(
      children: [
        LocationInputField(
          label: 'Pickup Location',
          hint: 'Enter pickup address or use current location',
          prefixIcon: Icons.location_on,
          controller: _pickupLocationController,
          onLocationChanged: () {
            setState(() {
              _pickupLocation = _pickupLocationController.text;
            });
            _onBookingDetailsChanged();
          },
          showCurrentLocationButton: true,
        ),
        const SizedBox(height: 12),
        LocationInputField(
          label: 'Drop-off Location',
          hint: 'Enter destination address',
          prefixIcon: Icons.flag,
          controller: _dropoffLocationController,
          onLocationChanged: () {
            setState(() {
              _dropoffLocation = _dropoffLocationController.text;
            });
            _onBookingDetailsChanged();
          },
          showCurrentLocationButton: false,
        ),
      ],
    );
  }

  Widget _buildHomePickupToggle() {
    return CheckboxListTile(
      value: _needsHomePickup,
      onChanged: (value) {
        setState(() {
          _needsHomePickup = value ?? false;
        });
        _onBookingDetailsChanged();
      },
      title: const Text('Home Pickup Required'),
      subtitle: const Text('Additional fees may apply'),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildPriceEstimate() {
    if (_priceEstimate == null) return const SizedBox.shrink();

    final totalPrice = _priceEstimate!['total_price']?.toDouble() ?? 0.0;
    final currency = _priceEstimate!['currency'] ?? 'NAD';
    final basePrice = _priceEstimate!['base_price']?.toDouble() ?? 0.0;
    final pickupFee = _priceEstimate!['pickup_fee']?.toDouble() ?? 0.0;

    // Format currency display
    final currencySymbol = currency == 'NAD' ? 'N\$' : '\$';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LottoRunnersColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LottoRunnersColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Estimate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LottoRunnersColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Price:'),
              Text('$currencySymbol${basePrice.toStringAsFixed(2)}'),
            ],
          ),
          if (pickupFee > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pickup Fee:'),
                Text('$currencySymbol${pickupFee.toStringAsFixed(2)}'),
              ],
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSubmit = _selectedServiceId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedServiceId = null;
                  _selectedSubcategoryId = null;
                  _priceEstimate = null;
                  _passengerCount = 1;
                  _needsHomePickup = false;
                  _selectedDate = null;
                  _selectedTime = null;
                  _pickupLocation = null;
                  _dropoffLocation = null;
                });
                // Clear text controllers
                _pickupLocationController.clear();
                _dropoffLocationController.clear();
              },
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: canSubmit ? _submitSelection : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'directions_bus':
        return Icons.directions_bus;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
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

  Color _getCategoryColor(String? colorHex) {
    if (colorHex == null) return Colors.grey.shade600;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey.shade600;
    }
  }
}
