import 'package:flutter/material.dart';

import '../theme.dart';

import '../supabase/supabase_config.dart';

import '../widgets/theme_toggle_button.dart';

import '../utils/responsive.dart';

/// Bus Service Booking Page
///
/// This page provides a user-friendly interface for booking bus services
/// with simplified booking flow for scheduled bus routes.
class BusBookingPage extends StatefulWidget {
  const BusBookingPage({super.key});

  @override
  State<BusBookingPage> createState() => _BusBookingPageState();
}

class _BusBookingPageState extends State<BusBookingPage> {
  // Data lists
  List<Map<String, dynamic>> _busServices = [];
  List<String> _allProviders = [];

  // Loading states
  bool _isLoadingServices = false;

  // Current selection
  String? _selectedServiceId;
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedService;
  String? _selectedProvider;
  String? _selectedOriginRegion;
  String? _selectedDestinationRegion;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _passengerCountController = TextEditingController(text: '1');
  final _specialRequestsController = TextEditingController();

  // Form data
  int _passengerCount = 1;

  // Namibia regions list
  static const List<String> _namibiaRegions = [
    'Khomas',
    'Erongo',
    'Oshana',
    'Kavango East',
    'Kavango West',
    'Zambezi',
    'Otjozondjupa',
    'Oshikoto',
    'Omaheke',
    'Hardap',
    'Karas',
    'Kunene',
    'Ohangwena',
    'Omusati',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusServices();
  }

  @override
  void dispose() {
    _passengerCountController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  /// Load bus services and extract all unique providers
  Future<void> _loadBusServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      // Get bus services with provider_names from transportation_services table
      final services = await SupabaseConfig.getBusServicesWithProviderNames();
      
      // Extract all unique providers from all services
      Set<String> uniqueProviders = {};
      for (var service in services) {
        final providerNames = service['provider_names'] as List<dynamic>? ?? [];
        for (var providerName in providerNames) {
          if (providerName != null && providerName.toString().isNotEmpty) {
            uniqueProviders.add(providerName.toString());
          }
        }
      }
      
      setState(() {
        _busServices = services;
        _allProviders = uniqueProviders.toList()..sort();
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load bus services. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Check if a date is available for the selected service
  bool _isDateAvailable(DateTime date) {
    print('🔍 _isDateAvailable called for date: $date');

    if (_selectedService == null) {
      print('❌ No selected service');
      return false;
    }

    final daysOfWeek = _selectedService!['days_of_week'] as List<dynamic>?;
    print(
        '📋 Days of week from service: $daysOfWeek (type: ${daysOfWeek.runtimeType})');

    if (daysOfWeek == null || daysOfWeek.isEmpty) {
      print('❌ Days of week is null or empty');
      return false;
    }

    // Convert DateTime weekday (1=Monday, 7=Sunday) to day name
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[date.weekday - 1];
    print('📅 Date weekday: ${date.weekday}, Day name: $dayName');

    final isAvailable = daysOfWeek.contains(dayName);
    print('✅ Is $dayName available? $isAvailable');

    return isAvailable;
  }

  /// Handle provider selection from dropdown
  void _onProviderSelected(String? provider) {
    setState(() {
      _selectedProvider = provider;
      _selectedService = null;
      _selectedServiceId = null;
      _selectedDate = null;
      
      // Find a service that matches the selected provider
      if (provider != null) {
        for (var service in _busServices) {
          final providerNames = service['provider_names'] as List<dynamic>? ?? [];
          if (providerNames.contains(provider)) {
            _selectedService = service;
            _selectedServiceId = service['id'];
            break;
          }
        }
      }
    });
  }

  /// Handle origin region selection
  void _onOriginRegionSelected(String? region) {
    setState(() {
      _selectedOriginRegion = region;
    });
  }

  /// Handle destination region selection
  void _onDestinationRegionSelected(String? region) {
    setState(() {
      _selectedDestinationRegion = region;
    });
  }

  /// Handle date selection
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  /// Get total price for the service based on selected provider
  double _getTotalPrice() {
    if (_selectedService == null || _selectedProvider == null) return 0.0;

    // Use base service price since provider_names doesn't include pricing
    final servicePrice = (_selectedService!['price'] ?? 0.0).toDouble();
    return servicePrice * _passengerCount;
  }

  /// Get the effective price per passenger for the selected service and provider
  double _getEffectivePricePerPassenger() {
    if (_selectedService == null || _selectedProvider == null) return 0.0;

    // Use base service price since provider_names doesn't include pricing
    final servicePrice = (_selectedService!['price'] ?? 0.0).toDouble();
    return servicePrice;
  }

  /// Show confirmation dialog before booking

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a service'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a travel date'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a provider'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedOriginRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select origin region'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedDestinationRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select destination region'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final totalPrice = _getTotalPrice();
    final effectivePricePerPassenger = _getEffectivePricePerPassenger();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.confirmation_number,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Confirm Booking'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider information
              if (_selectedProvider != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Provider: $_selectedProvider',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Route information
              if (_selectedOriginRegion != null && _selectedDestinationRegion != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Route: $_selectedOriginRegion → $_selectedDestinationRegion',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                'Service: ${_selectedService?['name'] ?? 'Unknown'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${_selectedDate != null ? _formatDate(_selectedDate!) : 'Unknown'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Passengers: $_passengerCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LottoRunnersColors.primaryYellow.withOpacity(0.12),
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
                      'Total Price',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Price per passenger:'),
                        Text(
                          '\$${effectivePricePerPassenger.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of passengers:'),
                        Text('$_passengerCount'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitBooking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Submit bus service booking after confirmation
  Future<void> _submitBooking() async {
    try {
      final totalPrice = _getTotalPrice();

      final bookingData = {
        'user_id': SupabaseConfig.currentUser?.id,
        'service_id': _selectedServiceId,
        'selected_date': _selectedDate?.toIso8601String().split('T')[0],
        'passenger_count': _passengerCount,
        'booking_date': DateTime.now().toIso8601String().split('T')[0],
        'booking_time': _selectedService?['departure_time'] ?? '00:00:00',
        'selected_provider': _selectedProvider ?? 'Unknown Provider',
        'origin_region': _selectedOriginRegion,
        'destination_region': _selectedDestinationRegion,
        'special_requests': _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
        'estimated_price': totalPrice,
        'final_price': totalPrice,
        'status': 'pending',
        'payment_status': 'pending',
      };

      final result = await SupabaseConfig.createBusServiceBooking(bookingData);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bus service booking created successfully!'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );

          // Reset form
          _formKey.currentState!.reset();

          setState(() {
            _selectedServiceId = null;
            _selectedDate = null;
            _selectedService = null;
            _selectedProvider = null;
            _selectedOriginRegion = null;
            _selectedDestinationRegion = null;
            _passengerCount = 1;
          });

          _passengerCountController.text = '1';
          _specialRequestsController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create bus service booking'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bus service booking: $e'),
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
                Icons.directions_bus,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Bus Service Booking',
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
            // Bus services section
            _buildBusServicesSection(),

            SizedBox(height: isSmallMobile ? 16 : 24),

            // Booking form (visible even before selecting a service)
            _buildBookingForm(),
          ],
        ),
      ),
    );
  }

  /// Build provider and region selection section
  Widget _buildBusServicesSection() {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    if (_isLoadingServices) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_allProviders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: Text(
          'No bus providers available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isSmallMobile ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

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
            'Select Provider',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 16 : 20,
              letterSpacing: isSmallMobile ? 0 : 0.3,
            ),
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            isExpanded: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 13 : 14,
            ),
            iconSize: isSmallMobile ? 20 : 24,
            decoration: InputDecoration(
              hintText: 'Choose a provider',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
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
                horizontal: isSmallMobile ? 10 : 12,
                vertical: isSmallMobile ? 10 : 12,
              ),
              prefixIcon: Icon(
                Icons.business,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            items: _allProviders.map((provider) {
              return DropdownMenuItem<String>(
                value: provider,
                child: Text(
                  provider,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onProviderSelected,
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          Text(
            'Select Route',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 16 : 20,
              letterSpacing: isSmallMobile ? 0 : 0.3,
            ),
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          // Origin region dropdown
          DropdownButtonFormField<String>(
            value: _selectedOriginRegion,
            isExpanded: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 13 : 14,
            ),
            iconSize: isSmallMobile ? 20 : 24,
            decoration: InputDecoration(
              labelText: 'Where you come from',
              hintText: 'Select origin region',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
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
                horizontal: isSmallMobile ? 10 : 12,
                vertical: isSmallMobile ? 10 : 12,
              ),
              prefixIcon: Icon(
                Icons.location_on,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            items: _namibiaRegions.map((region) {
              return DropdownMenuItem<String>(
                value: region,
                child: Text(
                  region,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onOriginRegionSelected,
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          // Destination region dropdown
          DropdownButtonFormField<String>(
            value: _selectedDestinationRegion,
            isExpanded: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 13 : 14,
            ),
            iconSize: isSmallMobile ? 20 : 24,
            decoration: InputDecoration(
              labelText: 'Where you are going',
              hintText: 'Select destination region',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
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
                horizontal: isSmallMobile ? 10 : 12,
                vertical: isSmallMobile ? 10 : 12,
              ),
              prefixIcon: Icon(
                Icons.location_searching,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            items: _namibiaRegions.map((region) {
              return DropdownMenuItem<String>(
                value: region,
                child: Text(
                  region,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onDestinationRegionSelected,
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Show date picker
  Future<void> _showDatePicker() async {
    print('🗓️ _showDatePicker called');
    print('🔍 Selected service: ${_selectedService?['name']}');
    print('🔍 Days of week: ${_selectedService?['days_of_week']}');

    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = now.add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        final isAvailable = _isDateAvailable(date);
        print(
            '📅 Date ${date.toString().split(' ')[0]} - Available: $isAvailable');
        // Temporarily allow all dates to test if picker works
        return true; // isAvailable;
      },
    );

    print('📅 Picked date: $picked');
    if (picked != null && picked != _selectedDate) {
      print('✅ Setting selected date: $picked');
      _onDateSelected(picked);
    }
  }

  /// Build booking form

  Widget _buildBookingForm() {
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
                fontSize: isSmallMobile ? 14 : 16,
                letterSpacing: isSmallMobile ? 0 : 0.2,
              ),
            ),

            SizedBox(height: isSmallMobile ? 16 : 20),

            // Travel date

            InkWell(
              onTap: () => _showDatePicker(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallMobile ? 16 : 18),
                decoration: BoxDecoration(
                  color: _selectedDate != null
                      ? LottoRunnersColors.primaryBlue.withOpacity(0.05)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate != null
                        ? LottoRunnersColors.primaryBlue
                        : theme.colorScheme.outline,
                    width: _selectedDate != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: LottoRunnersColors.primaryYellow,
                      size: isSmallMobile ? 20 : 24,
                    ),
                    SizedBox(width: isSmallMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel Date *',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _selectedDate != null
                                  ? LottoRunnersColors.primaryBlue
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: isSmallMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isSmallMobile ? 2 : 4),
                          Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate!)
                                : 'Tap to select travel date',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _selectedDate != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: isSmallMobile ? 14 : 15,
                              fontWeight: _selectedDate != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedDate != null)
                      Icon(
                        Icons.check_circle,
                        color: LottoRunnersColors.primaryYellow,
                        size: isSmallMobile ? 18 : 20,
                      ),
                  ],
                ),
              ),
            ),


            // Passenger count

            TextFormField(
              controller: _passengerCountController,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallMobile ? 13 : 14,
              ),
              decoration: InputDecoration(
                labelText: 'Number of Passengers',
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
                  vertical: isSmallMobile ? 14 : 16,
                ),
                prefixIcon: Icon(
                  Icons.people,
                  color: LottoRunnersColors.primaryYellow,
                  size: isSmallMobile ? 20 : 24,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _passengerCount = int.tryParse(value) ?? 1;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter passenger count';
                }

                final count = int.tryParse(value);

                if (count == null || count < 1) {
                  return 'Please enter a valid number';
                }

                return null;
              },
            ),

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

            // Submit button

            SizedBox(
              width: double.infinity,
              height: isSmallMobile ? 46 : 50,
              child: ElevatedButton(
                onPressed: _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                  ),
                ),
                child: Text(
                  'Book Bus Service',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: isSmallMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
