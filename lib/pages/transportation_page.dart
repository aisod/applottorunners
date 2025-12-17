import 'package:flutter/material.dart';
import '../theme.dart';
import '../supabase/supabase_config.dart';
// import '../services/location_service.dart'; // Removed - no longer using distance calculations
import '../widgets/theme_toggle_button.dart';
import '../widgets/simple_location_picker.dart';
import '../widgets/looking_for_driver_popup.dart';
import '../utils/responsive.dart';

/// Shuttle Services Page
///
/// This page provides a user-friendly interface for booking transportation services
/// by browsing subcategories and available vehicles/services.
class TransportationPage extends StatefulWidget {
  const TransportationPage({super.key});

  @override
  State<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends State<TransportationPage> {
  // Data lists
  List<Map<String, dynamic>> _vehicles = [];

  // Loading states
  bool _isLoadingSubcategories = false;
  // Removed: _isLoadingVehicles, not needed with dropdown UI

  // Current selection
  String? _selectedVehicleId;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  // Removed passenger count controller - using static pricing
  final _bookingDateController = TextEditingController();
  final _bookingTimeController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  // Form data
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  // Removed passenger count - using static pricing

  // Location coordinates
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  // Pricing information

  String _userType = 'individual';
  // _distanceKm removed - no longer using distance calculations

  // Booking type selection
  bool _isImmediateBooking = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadShuttleServices();
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    // Removed passenger count controller disposal
    _bookingDateController.dispose();
    _bookingTimeController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  /// Load user type for pricing calculations
  Future<void> _loadUserType() async {
    try {
      final userType = await SupabaseConfig.getUserType();
      setState(() {
        _userType = userType;
      });
    } catch (e) {
      print('Error loading user type: $e');
    }
  }

  // /// Load transportation data for tabs
  // Future<void> _loadTransportationData() async {
  //   try {
  //     final userId = SupabaseConfig.currentUser?.id;
  //     if (userId != null) {
  //       // Load user's transportation bookings
  //       final userBookings = await SupabaseConfig.getUserBookings(userId);

  //       setState(() {
  //         _allTransportation = userBookings;
  //         _activeTransportation = userBookings
  //             .where((booking) =>
  //                 booking['status'] == 'confirmed' ||
  //                 booking['status'] == 'in_progress')
  //             .toList();
  //         _pendingTransportation = userBookings
  //             .where((booking) => booking['status'] == 'pending')
  //             .toList();
  //         _completedTransportation = userBookings
  //             .where((booking) => booking['status'] == 'completed')
  //             .toList();
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading transportation data: $e');
  //   }
  // }

  /// Calculate pricing when locations change (distance calculation removed)
  Future<void> _calculatePricing() async {
    if (_selectedVehicleId == null) {
      print('Pricing calculation skipped: no vehicle selected');
      return;
    }

    print('Starting pricing calculation...');
    print('Selected vehicle ID: $_selectedVehicleId');
    print('User type: $_userType');

    // Trigger UI update to show pricing
    setState(() {
      // This will trigger the UI to rebuild and show pricing
    });
  }

  /// Load all available vehicles
  Future<void> _loadShuttleServices() async {
    setState(() {
      _isLoadingSubcategories = true;
    });

    try {
      setState(() {
        _isLoadingSubcategories = false;
      });

      // Load all vehicles (not filtered by subcategory)
      _loadVehicles(null);
    } catch (e) {
      setState(() {
        _isLoadingSubcategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load vehicles. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Load all available vehicles (not filtered by subcategory)
  Future<void> _loadVehicles(String? subcategoryId) async {
    // No separate loading state needed for dropdown

    try {
      // Get all available vehicle types (same as contract page)
      final availableVehicles = await SupabaseConfig.getAllVehicleTypes();

      // Filter out mini truck, bicycle, truck, and motorcycle for ride requests
      final filteredVehicles = availableVehicles.where((vehicle) {
        final name = (vehicle['name'] ?? '').toString().toLowerCase();
        return !name.contains('mini truck') && 
               !name.contains('bicycle') && 
               !name.contains('truck') && 
               !name.contains('motorcycle');
      }).toList();

      print('Loaded vehicles: ${filteredVehicles.length}');
      for (var vehicle in filteredVehicles) {
        print(
            'Vehicle: ${vehicle['name']}, Base Price: ${vehicle['price_base']}, Business Price: ${vehicle['price_business']}, Price per KM: ${vehicle['price_per_km']}');
      }

      setState(() {
        _vehicles = filteredVehicles;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      // Keep UI responsive without explicit loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load vehicles. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle location changes
  void _onLocationChanged() {
    _calculatePricing();
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _bookingDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  /// Show time picker
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _bookingTimeController.text = picked.format(context);
      });
    }
  }

  /// Reset the booking form
  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      // Removed passenger count reset
      _isImmediateBooking = false;

      // Clear location coordinates
      _pickupLat = null;
      _pickupLng = null;
      _dropoffLat = null;
      _dropoffLng = null;
    });
    _pickupLocationController.clear();
    _dropoffLocationController.clear();
    // Removed passenger count reset
    _specialRequestsController.clear();
  }

  /// Submit transportation booking
  Future<void> _submitBooking() async {
    print('🚀 DEBUG: [TRANSPORTATION PAGE] _submitBooking called');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ DEBUG: [TRANSPORTATION PAGE] Form validation failed');
      return;
    }
    print('✅ DEBUG: [TRANSPORTATION PAGE] Form validation passed');

    if (_selectedVehicleId == null) {
      print('❌ DEBUG: [TRANSPORTATION PAGE] No vehicle selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a vehicle type'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    print('✅ DEBUG: [TRANSPORTATION PAGE] Vehicle selected: $_selectedVehicleId');

    try {
      print('🚀 DEBUG: [TRANSPORTATION PAGE] Starting booking submission...');
      print('👤 DEBUG: [TRANSPORTATION PAGE] Current user ID: ${SupabaseConfig.currentUser?.id}');
      print('👤 DEBUG: [TRANSPORTATION PAGE] Current user email: ${SupabaseConfig.currentUser?.email}');
      print('🚗 DEBUG: [TRANSPORTATION PAGE] Selected vehicle ID: $_selectedVehicleId');
      print('📍 DEBUG: [TRANSPORTATION PAGE] Pickup location: ${_pickupLocationController.text}');
      print('📍 DEBUG: [TRANSPORTATION PAGE] Dropoff location: ${_dropoffLocationController.text}');
      print('🗓️ DEBUG: [TRANSPORTATION PAGE] Is immediate booking: $_isImmediateBooking');
      print('📅 DEBUG: [TRANSPORTATION PAGE] Selected date: $_selectedDate');
      print('⏰ DEBUG: [TRANSPORTATION PAGE] Selected time: $_selectedTime');
      print('📝 DEBUG: [TRANSPORTATION PAGE] Special requests: ${_specialRequestsController.text}');

      // Validate coordinates
      print('🌐 DEBUG: [TRANSPORTATION PAGE] Coordinate validation:');
      print('   - Pickup lat: $_pickupLat, lng: $_pickupLng');
      print('   - Dropoff lat: $_dropoffLat, lng: $_dropoffLng');

      final bookingData = {
        'user_id': SupabaseConfig.currentUser?.id,
        'vehicle_type_id': _selectedVehicleId,
        'pickup_location': _pickupLocationController.text,
        'dropoff_location': _dropoffLocationController.text,
        'pickup_lat': _pickupLat,
        'pickup_lng': _pickupLng,
        'dropoff_lat': _dropoffLat,
        'dropoff_lng': _dropoffLng,
        'passenger_count': 1, // Static passenger count
        'booking_date': _isImmediateBooking
            ? null
            : _selectedDate?.toIso8601String().split('T')[0],
        'booking_time':
            _isImmediateBooking ? null : _selectedTime?.format(context),
        'special_requests': _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
        'estimated_price': 0.0, // No pricing calculation
        'final_price': 0.0, // No pricing calculation
        'status': 'pending',
        'payment_status': 'pending',
        'is_immediate': _isImmediateBooking, // Add flag for immediate bookings
      };

      print('📦 DEBUG: [TRANSPORTATION PAGE] Booking data prepared:');
      print('   - user_id: ${bookingData['user_id']}');
      print('   - vehicle_type_id: ${bookingData['vehicle_type_id']}');
      print('   - pickup_location: ${bookingData['pickup_location']}');
      print('   - dropoff_location: ${bookingData['dropoff_location']}');
      print('   - is_immediate: ${bookingData['is_immediate']}');
      print('   - booking_date: ${bookingData['booking_date']}');
      print('   - booking_time: ${bookingData['booking_time']}');
      print('   - status: ${bookingData['status']}');

      print('🔄 DEBUG: [TRANSPORTATION PAGE] Calling createTransportationBooking...');
      final result =
          await SupabaseConfig.createTransportationBooking(bookingData);

      print('📊 DEBUG: [TRANSPORTATION PAGE] Booking creation result received');
      print('📊 DEBUG: [TRANSPORTATION PAGE] Result is null: ${result == null}');
      if (result != null) {
        print('📊 DEBUG: [TRANSPORTATION PAGE] Result ID: ${result['id']}');
        print('📊 DEBUG: [TRANSPORTATION PAGE] Full result: $result');
      } else {
        print('❌ DEBUG: [TRANSPORTATION PAGE] Booking creation returned null - check error logs above');
      }

      if (result != null && result['id'] != null) {
        if (mounted) {
          if (_isImmediateBooking) {
            // Show looking for driver popup for immediate bookings
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LookingForDriverPopup(
                bookingId: result['id'],
                pickupLocation: _pickupLocationController.text,
                dropoffLocation: _dropoffLocationController.text,
                onRetry: () {
                  // Retry the booking request
                  _submitBooking();
                },
                onCancel: () {
                  // Cancel the booking request
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ride request cancelled'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  _resetForm();
                },
                onDriverFound: () {
                  // Driver found, close popup and show success
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Driver accepted your ride!'),
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  );
                  _resetForm();
                },
              ),
            );
          } else {
            // Show success message for scheduled bookings
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('Transportation booking created successfully!'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
            // Reset form
            _resetForm();
          }
        }
      } else {
        print('❌ DEBUG: [TRANSPORTATION PAGE] Booking creation failed - result is null or missing ID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create transportation booking. Please check the console for details.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: [TRANSPORTATION PAGE] Exception caught in _submitBooking');
      print('❌ DEBUG: [TRANSPORTATION PAGE] Error type: ${e.runtimeType}');
      print('❌ DEBUG: [TRANSPORTATION PAGE] Error message: $e');
      print('❌ DEBUG: [TRANSPORTATION PAGE] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating transportation booking: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: LottoRunnersColors.primaryYellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Shuttle Services',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallMobile ? 18 : 24,
                  letterSpacing: isSmallMobile ? 0 : 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          // ThemeToggleButton(), // Commented out dark mode for now
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation to other transportation services
            // _buildServiceNavigationCards(),
            // SizedBox(height: isSmallMobile ? 16 : 24),

            // Subcategories section
            _buildSubcategoriesSection(),
            SizedBox(height: isSmallMobile ? 16 : 24),

            // Services/Vehicles section with dropdown
            _buildServicesVehiclesSection(),
            SizedBox(height: isSmallMobile ? 16 : 24),

            // Next steps message
            if (_selectedVehicleId == null) _buildNextStepsMessage(),

            // Booking form (always visible like bus/contract pages)
            _buildBookingForm(),
          ],
        ),
      ),
    );
  }

  /// Build shuttle services header
  Widget _buildSubcategoriesSection() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    if (_isLoadingSubcategories) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox.shrink();
  }

  /// Build vehicles section
  Widget _buildServicesVehiclesSection() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: isSmallMobile ? 8 : 10,
            offset: Offset(0, isSmallMobile ? 1 : 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline,
          width: isSmallMobile ? 0.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service Type',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 16 : 20,
              letterSpacing: isSmallMobile ? 0 : 0.3,
            ),
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          // Visual vehicle selection cards
          _buildVehicleSelectionCards(theme, isSmallMobile),
        ],
      ),
    );
  }

  /// Build pricing display
  Widget _buildPricingDisplay() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    if (_selectedVehicleId == null) return const SizedBox.shrink();

    final selectedVehicle = _vehicles.firstWhere(
        (v) => v['id'] == _selectedVehicleId,
        orElse: () => <String, dynamic>{});

    if (selectedVehicle.isEmpty) return const SizedBox.shrink();

    // Get pricing based on user type
    double basePrice = 0.0;
    String priceLabel = 'Price';

    if (_userType == 'business') {
      basePrice = 100.0;  // Fixed price for all vehicles for business users
      priceLabel = 'Business Price';
    } else {
      basePrice = 75.0;  // Fixed price for all vehicles for individual users
      priceLabel = 'Individual Price';
    }

    // Apply discount if available
    final discountPercentage = (selectedVehicle['discount_percentage'] ?? 0.0).toDouble();
    final originalPrice = basePrice;
    if (discountPercentage > 0) {
      basePrice = SupabaseConfig.calculateDiscountedPrice(basePrice, discountPercentage);
    }

    // Use static price (no passenger count multiplication)
    final totalPrice = basePrice;

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: LottoRunnersColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LottoRunnersColors.primaryYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Information',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: LottoRunnersColors.primaryYellow,
              fontSize: isSmallMobile ? 13 : 14,
            ),
          ),
          SizedBox(height: isSmallMobile ? 6 : 8),
          // Show discount badge if applicable
          if (discountPercentage > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${discountPercentage.toStringAsFixed(0)}% Discount Applied!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallMobile ? 6 : 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$priceLabel:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isSmallMobile ? 11 : 12,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (discountPercentage > 0)
                    Text(
                      'N\$${originalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: isSmallMobile ? 10 : 11,
                        color: theme.colorScheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    'N\$${basePrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallMobile ? 11 : 12,
                      color: discountPercentage > 0 ? Colors.orange : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallMobile ? 4 : 6),
          const Divider(height: 1),
          SizedBox(height: isSmallMobile ? 4 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallMobile ? 12 : 13,
                  color: discountPercentage > 0 ? Colors.orange : LottoRunnersColors.primaryYellow,
                ),
              ),
              Text(
                'N\$${totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallMobile ? 12 : 13,
                  color: discountPercentage > 0 ? Colors.orange : LottoRunnersColors.primaryYellow,
                ),
              ),
            ],
          ),
          if (discountPercentage > 0) ...[
            SizedBox(height: isSmallMobile ? 4 : 6),
            Text(
              'You save N\$${(originalPrice - totalPrice).toStringAsFixed(2)}!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: isSmallMobile ? 10 : 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build next steps message
  Widget _buildNextStepsMessage() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: LottoRunnersColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LottoRunnersColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: LottoRunnersColors.accent,
            size: isSmallMobile ? 20 : 24,
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(
            child: Text(
              'Select a service type to proceed with your booking',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LottoRunnersColors.accent,
                fontWeight: FontWeight.w500,
                fontSize: isSmallMobile ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Deprecated: vehicle selection list replaced by dropdown
  // Removed legacy _buildVehiclesList() implementation

  /// Build booking form
  Widget _buildBookingForm() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: isSmallMobile ? 15 : 16,
              ),
            ),
            SizedBox(height: isSmallMobile ? 16 : 20),

            // Pickup location
            SimpleLocationPicker(
              initialAddress: _pickupLocationController.text.isNotEmpty
                  ? _pickupLocationController.text
                  : null,
              hintText: 'Enter pickup address or use current location',
              labelText: 'Pickup Location *',
              prefixIcon: Icons.location_on,
              iconColor: LottoRunnersColors.primaryYellow,
              onLocationSelected: (address, lat, lng) {
                setState(() {
                  _pickupLocationController.text = address;
                  _pickupLat = lat;
                  _pickupLng = lng;
                });
                _onLocationChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pickup location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dropoff location
            SimpleLocationPicker(
              initialAddress: _dropoffLocationController.text.isNotEmpty
                  ? _dropoffLocationController.text
                  : null,
              hintText: 'Enter destination address',
              labelText: 'Dropoff Location *',
              prefixIcon: Icons.location_on_outlined,
              iconColor: LottoRunnersColors.primaryYellow,
              onLocationSelected: (address, lat, lng) {
                setState(() {
                  _dropoffLocationController.text = address;
                  _dropoffLat = lat;
                  _dropoffLng = lng;
                });
                _onLocationChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dropoff location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Booking type selection
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: isSmallMobile ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 10 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isImmediateBooking = false;
                              _selectedDate = null;
                              _selectedTime = null;
                              _bookingDateController.clear();
                              _bookingTimeController.clear();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallMobile ? 10 : 12, 
                              horizontal: isSmallMobile ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: !_isImmediateBooking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(isSmallMobile ? 6 : 8),
                              border: Border.all(
                                color: !_isImmediateBooking
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSmallMobile ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: !_isImmediateBooking
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  size: isSmallMobile ? 18 : 20,
                                ),
                                SizedBox(width: isSmallMobile ? 6 : 8),
                                Flexible(
                                  child: Text(
                                    'Scheduled',
                                    style: TextStyle(
                                      color: !_isImmediateBooking
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isSmallMobile ? 13 : 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallMobile ? 10 : 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isImmediateBooking = true;
                              _selectedDate = DateTime.now();
                              _selectedTime = TimeOfDay.now();
                              _bookingDateController.text = _selectedDate!
                                  .toIso8601String()
                                  .split('T')[0];
                              _bookingTimeController.text =
                                  _selectedTime!.format(context);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallMobile ? 10 : 12, 
                              horizontal: isSmallMobile ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: _isImmediateBooking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(isSmallMobile ? 6 : 8),
                              border: Border.all(
                                color: _isImmediateBooking
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSmallMobile ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flash_on,
                                  color: _isImmediateBooking
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  size: isSmallMobile ? 18 : 20,
                                ),
                                SizedBox(width: isSmallMobile ? 6 : 8),
                                Flexible(
                                  child: Text(
                                    'Request Now',
                                    style: TextStyle(
                                      color: _isImmediateBooking
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isSmallMobile ? 13 : 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
              ),
            ),
            SizedBox(height: isSmallMobile ? 14 : 16),

            // Date and time row (only show for scheduled bookings)
            if (!_isImmediateBooking) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bookingDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
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
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: LottoRunnersColors.primaryYellow,
                        ),
                      ),
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bookingTimeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Time',
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
                        prefixIcon: const Icon(
                          Icons.access_time,
                          color: LottoRunnersColors.primaryYellow,
                        ),
                      ),
                      onTap: _selectTime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select time';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Removed passenger count field - using static pricing
            SizedBox(height: isSmallMobile ? 14 : 16),

            // Special requests
            TextFormField(
              controller: _specialRequestsController,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallMobile ? 13 : 14,
              ),
              decoration: InputDecoration(
                labelText: 'Special Requests (Optional)',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmallMobile ? 13 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: isSmallMobile ? 1.5 : 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 12 : 16,
                  vertical: isSmallMobile ? 12 : 14,
                ),
                prefixIcon: Icon(
                  Icons.note,
                  color: LottoRunnersColors.primaryYellow,
                  size: isSmallMobile ? 20 : 24,
                ),
              ),
              maxLines: isSmallMobile ? 2 : 3,
              minLines: isSmallMobile ? 2 : 3,
            ),
            SizedBox(height: isSmallMobile ? 18 : 24),

            // Pricing and Submit
            // Pricing summary removed
            SizedBox(height: isSmallMobile ? 18 : 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: isSmallMobile ? 46 : 50,
              child: ElevatedButton.icon(
                onPressed: _submitBooking,
                icon: Icon(
                  _isImmediateBooking ? Icons.flash_on : Icons.check,
                  color: theme.colorScheme.onPrimary,
                  size: isSmallMobile ? 18 : 20,
                ),
                label: Text(
                  _isImmediateBooking ? 'Request Ride Now' : 'Submit Booking',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: isSmallMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pricing summary

  /// Get vehicle image URL from Supabase storage
  String _getVehicleImageUrl(String vehicleName) {
    String imageName;
    
    // Map vehicle names to image files in the icons bucket
    if (vehicleName.toLowerCase().contains('sedan')) {
      imageName = 'sedan.png';
    } else if (vehicleName.toLowerCase().contains('7') || 
               vehicleName.toLowerCase().contains('minivan') ||
               vehicleName.toLowerCase().contains('seater')) {
      imageName = '7seater.png';
    } else if (vehicleName.toLowerCase().contains('minibus') || 
               vehicleName.toLowerCase().contains('mini bus')) {
      imageName = 'mini bus.png';
    } else {
      // Default to sedan if no match
      imageName = 'sedan.png';
    }
    
    return SupabaseConfig.client.storage
        .from('icons')
        .getPublicUrl(imageName);
  }

  /// Build vehicle selection cards with images (horizontal scrollable)
  Widget _buildVehicleSelectionCards(ThemeData theme, bool isSmallMobile) {
    if (_vehicles.isEmpty) {
      return Center(
        child: Text(
          'No vehicles available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: isSmallMobile ? 180 : 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          final String id = vehicle['id'];
          final String name = vehicle['name'] ?? 'Unknown Vehicle';
          final bool isSelected = _selectedVehicleId == id;
          final bool hasDiscount = vehicle['discount_percentage'] != null && 
                                   vehicle['discount_percentage'] > 0;
          
          return Padding(
            padding: EdgeInsets.only(
              right: isSmallMobile ? 12 : 16,
              left: index == 0 ? 0 : 0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedVehicleId = id;
                });
                _calculatePricing();
              },
              borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
              child: Container(
                width: isSmallMobile ? 150 : 180,
                padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? LottoRunnersColors.primaryYellow.withOpacity(0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
                  border: Border.all(
                    color: isSelected 
                        ? LottoRunnersColors.primaryYellow
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: LottoRunnersColors.primaryYellow.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Selection indicator at top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.all(isSmallMobile ? 4 : 6),
                            decoration: BoxDecoration(
                              color: LottoRunnersColors.primaryYellow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallMobile ? 14 : 16,
                            ),
                          )
                        else
                          SizedBox(height: isSmallMobile ? 22 : 28),
                      ],
                    ),
                    
                    // Vehicle image
                    Container(
                      width: isSmallMobile ? 110 : 130,
                      height: isSmallMobile ? 70 : 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
                        child: Image.network(
                          _getVehicleImageUrl(name),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_car,
                              size: isSmallMobile ? 35 : 45,
                              color: LottoRunnersColors.primaryYellow,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: isSmallMobile ? 20 : 25,
                                height: isSmallMobile ? 20 : 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LottoRunnersColors.primaryYellow,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallMobile ? 8 : 10),
                    
                    // Vehicle info
                    Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallMobile ? 13 : 14,
                            color: isSelected 
                                ? LottoRunnersColors.primaryYellow
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: isSmallMobile ? 4 : 6),
                        // Price display
                        if (hasDiscount) ...[
                          Text(
                            'N\$${(_userType == 'business' ? '100.00' : '75.00')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w400,
                              fontSize: isSmallMobile ? 10 : 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            'N\$${SupabaseConfig.calculateDiscountedPrice(_userType == 'business' ? 100.0 : 75.0, vehicle['discount_percentage'].toDouble()).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallMobile ? 13 : 14,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: isSmallMobile ? 2 : 3),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 6 : 8,
                              vertical: isSmallMobile ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${vehicle['discount_percentage'].toStringAsFixed(0)}% OFF',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 8 : 9,
                              ),
                            ),
                          ),
                        ] else
                          Text(
                            'N\$${(_userType == 'business' ? '100.00' : '75.00')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: LottoRunnersColors.primaryYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallMobile ? 13 : 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.directions_car; // Or a van icon
      case 'bike':
        return Icons.directions_bike;
      case 'scooter':
        return Icons.directions_bike; // Or a scooter icon
      default:
        return Icons.directions_car;
    }
  }
}

