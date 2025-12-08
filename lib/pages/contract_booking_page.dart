import 'package:flutter/material.dart';

import '../theme.dart';

import '../supabase/supabase_config.dart';

import '../widgets/theme_toggle_button.dart';

import '../widgets/simple_location_picker.dart';

import '../utils/responsive.dart';

/// Contract Booking Page

///

/// This page provides a user-friendly interface for booking long-term

/// transportation contracts with different duration options.

class ContractBookingPage extends StatefulWidget {
  const ContractBookingPage({super.key});

  @override
  State<ContractBookingPage> createState() => _ContractBookingPageState();
}

class _ContractBookingPageState extends State<ContractBookingPage> {
  // Data lists

  List<Map<String, dynamic>> _vehicles = [];

  // Loading states

  bool _isLoadingVehicles = false;

  // Current selection

  String? _selectedVehicleId;

  Map<String, dynamic>? _selectedVehicle;

  // Form controllers

  final _formKey = GlobalKey<FormState>();

  final _pickupLocationController = TextEditingController();

  final _dropoffLocationController = TextEditingController();

  final _passengerCountController = TextEditingController(text: '1');

  final _descriptionController = TextEditingController();

  final _specialRequestsController = TextEditingController();

  // Form data

  int _passengerCount = 1;

  DateTime? _contractStartDate;

  TimeOfDay? _contractStartTime;

  String _contractDurationType = 'monthly';

  int _contractDurationValue = 1;

  DateTime? _contractEndDate;

  // Location coordinates

  double? _pickupLat;

  double? _pickupLng;

  double? _dropoffLat;

  double? _dropoffLng;

  // Pricing information

  // _distanceKm removed - no longer using distance calculations

  @override
  void initState() {
    super.initState();

    _loadVehicles();

    // User type loading removed - no longer needed for pricing
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();

    _dropoffLocationController.dispose();

    _passengerCountController.dispose();

    _descriptionController.dispose();

    _specialRequestsController.dispose();

    super.dispose();
  }

  /// Load available vehicles for contract bookings

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    try {
      // Get all available vehicle types
      final vehicles = await SupabaseConfig.getAllVehicleTypes();

      // Filter out mini truck, bicycle, truck, and motorcycle for contract bookings
      final filteredVehicles = vehicles.where((vehicle) {
        final name = (vehicle['name'] ?? '').toString().toLowerCase();
        return !name.contains('mini truck') && 
               !name.contains('bicycle') && 
               !name.contains('truck') && 
               !name.contains('motorcycle');
      }).toList();

      setState(() {
        _vehicles = filteredVehicles;

        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVehicles = false;
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

  /// Handle vehicle selection

  void _onVehicleSelected(Map<String, dynamic> vehicle) {
    setState(() {
      _selectedVehicleId = vehicle['id'];

      _selectedVehicle = vehicle;
    });

    _calculatePricing();
  }

  /// Calculate pricing when locations change (distance calculation removed)

  Future<void> _calculatePricing() async {
    // Pricing calculation removed - no longer calculating transportation price
  }

  /// Handle location changes

  void _onLocationChanged() {
    _calculatePricing();
  }

  /// Show date picker for contract start

  Future<void> _selectContractStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _contractStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _contractStartDate = picked;

        _calculateContractEndDate();
      });
    }
  }

  /// Show time picker for contract start

  Future<void> _selectContractStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _contractStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _contractStartTime = picked;
      });
    }
  }

  /// Calculate contract end date based on duration

  void _calculateContractEndDate() {
    if (_contractStartDate == null) return;

    DateTime endDate;

    switch (_contractDurationType) {
      case 'weekly':
        endDate =
            _contractStartDate!.add(Duration(days: _contractDurationValue * 7));

        break;

      case 'monthly':
        endDate = DateTime(
          _contractStartDate!.year,
          _contractStartDate!.month + _contractDurationValue,
          _contractStartDate!.day,
        );

        break;

      case 'yearly':
        endDate = DateTime(
          _contractStartDate!.year + _contractDurationValue,
          _contractStartDate!.month,
          _contractStartDate!.day,
        );

        break;

      default:
        endDate = _contractStartDate!;
    }

    setState(() {
      _contractEndDate = endDate;
    });
  }

  /// Handle duration type change

  void _onDurationTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _contractDurationType = value;

        _calculateContractEndDate();
      });

      _calculatePricing();
    }
  }

  /// Handle duration value change

  void _onDurationValueChanged(String? value) {
    if (value != null) {
      final intValue = int.tryParse(value);

      if (intValue != null && intValue > 0) {
        setState(() {
          _contractDurationValue = intValue;

          _calculateContractEndDate();
        });

        _calculatePricing();
      }
    }
  }

  /// Submit contract booking

  Future<void> _submitContract() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a vehicle type'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    if (_contractStartDate == null || _contractStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select contract start date and time'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide a description of the contract'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    try {
      final contractData = {
        'user_id': SupabaseConfig.currentUser?.id,
        'vehicle_type_id': _selectedVehicleId,
        'pickup_location': _pickupLocationController.text,
        'pickup_lat': _pickupLat,
        'pickup_lng': _pickupLng,
        'dropoff_location': _dropoffLocationController.text,
        'dropoff_lat': _dropoffLat,
        'dropoff_lng': _dropoffLng,
        'passenger_count': _passengerCount,
        'contract_start_date':
            _contractStartDate!.toIso8601String().split('T')[0],
        'contract_start_time': _contractStartTime!.format(context),
        'contract_duration_type': _contractDurationType,
        'contract_duration_value': _contractDurationValue,
        'contract_end_date': _contractEndDate?.toIso8601String().split('T')[0],
        'description': _descriptionController.text,
        'special_requests': _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
        'estimated_price': 0.0, // No pricing calculation
        'final_price': 0.0, // No pricing calculation
        'status': 'pending',
        'payment_status': 'pending',
      };

      final result = await SupabaseConfig.createContractBooking(contractData);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contract booking created successfully!'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );

          // Reset form

          _formKey.currentState!.reset();

          setState(() {
            _selectedVehicleId = null;

            _selectedVehicle = null;

            _contractStartDate = null;

            _contractStartTime = null;

            _contractDurationType = 'monthly';

            _contractDurationValue = 1;

            _contractEndDate = null;

            _passengerCount = 1;

            _pickupLat = null;

            _pickupLng = null;

            _dropoffLat = null;

            _dropoffLng = null;
          });

          _pickupLocationController.clear();

          _dropoffLocationController.clear();

          _passengerCountController.text = '1';

          _descriptionController.clear();

          _specialRequestsController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create contract booking'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating contract booking: $e'),
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
                Icons.assignment,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Contract Booking',
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
            // Vehicles section

            _buildVehiclesSection(),

            SizedBox(height: isSmallMobile ? 16 : 24),

            // Next steps message

            if (_selectedVehicleId == null) _buildNextStepsMessage(),

            // Contract form

            _buildContractForm(),
          ],
        ),
      ),
    );
  }

  /// Build vehicles section

  Widget _buildVehiclesSection() {
    final theme = Theme.of(context);

    final isSmallMobile = Responsive.isSmallMobile(context);

    if (_isLoadingVehicles) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicles.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: Text(
          'No vehicles available',
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
            'Select Service Type',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 16 : 20,
              letterSpacing: isSmallMobile ? 0 : 0.3,
            ),
          ),
          SizedBox(height: isSmallMobile ? 16 : 20),
          // Horizontal scrollable vehicle cards
          SizedBox(
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
                      _onVehicleSelected(vehicle);
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
                              // Discount badge if available
                              if (hasDiscount)
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
                          ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
              'Select a vehicle type to proceed with your contract',
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

  /// Build contract form

  Widget _buildContractForm() {
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
              'Contract Details',
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

            SizedBox(height: isSmallMobile ? 14 : 16),

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

            SizedBox(height: isSmallMobile ? 14 : 16),

            // Contract start date and time row

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallMobile ? 13 : 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Contract Start Date',
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
                        Icons.calendar_today,
                        color: LottoRunnersColors.primaryYellow,
                        size: isSmallMobile ? 20 : 24,
                      ),
                    ),
                    onTap: _selectContractStartDate,
                    validator: (value) {
                      if (_contractStartDate == null) {
                        return 'Please select start date';
                      }

                      return null;
                    },
                    controller: TextEditingController(
                      text: _contractStartDate != null
                          ? '${_contractStartDate!.day}/${_contractStartDate!.month}/${_contractStartDate!.year}'
                          : '',
                    ),
                  ),
                ),
                SizedBox(width: isSmallMobile ? 12 : 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallMobile ? 13 : 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Start Time',
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
                        Icons.access_time,
                        color: LottoRunnersColors.primaryYellow,
                        size: isSmallMobile ? 20 : 24,
                      ),
                    ),
                    onTap: _selectContractStartTime,
                    validator: (value) {
                      if (_contractStartTime == null) {
                        return 'Please select start time';
                      }

                      return null;
                    },
                    controller: TextEditingController(
                      text: _contractStartTime?.format(context) ?? '',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallMobile ? 14 : 16),

            // Contract duration type and value row

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _contractDurationType,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallMobile ? 13 : 14,
                    ),
                    iconSize: isSmallMobile ? 20 : 24,
                    decoration: InputDecoration(
                      labelText: 'Duration Type',
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
                        Icons.schedule,
                        color: LottoRunnersColors.primaryYellow,
                        size: isSmallMobile ? 20 : 24,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'weekly', 
                        child: Text(
                          'Weekly',
                          style: TextStyle(fontSize: isSmallMobile ? 13 : 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'monthly', 
                        child: Text(
                          'Monthly',
                          style: TextStyle(fontSize: isSmallMobile ? 13 : 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'yearly', 
                        child: Text(
                          'Yearly',
                          style: TextStyle(fontSize: isSmallMobile ? 13 : 14),
                        ),
                      ),
                    ],
                    onChanged: _onDurationTypeChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select duration type';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(width: isSmallMobile ? 12 : 16),
                Expanded(
                  child: TextFormField(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallMobile ? 13 : 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Duration Value',
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
                        Icons.numbers,
                        color: LottoRunnersColors.primaryYellow,
                        size: isSmallMobile ? 20 : 24,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _contractDurationValue.toString(),
                    onChanged: _onDurationValueChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration value';
                      }

                      final count = int.tryParse(value);

                      if (count == null || count < 1) {
                        return 'Please enter a valid number';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallMobile ? 14 : 16),

            // Contract end date (read-only)

            if (_contractEndDate != null)
              TextFormField(
                readOnly: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmallMobile ? 13 : 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Contract End Date',
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isSmallMobile ? 13 : 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : 16,
                    vertical: isSmallMobile ? 14 : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.event_busy,
                    color: LottoRunnersColors.primaryYellow,
                    size: isSmallMobile ? 20 : 24,
                  ),
                ),
                controller: TextEditingController(
                  text:
                      '${_contractEndDate!.day}/${_contractEndDate!.month}/${_contractEndDate!.year}',
                ),
              ),

            if (_contractEndDate != null) SizedBox(height: isSmallMobile ? 14 : 16),

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

            // Contract description

            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallMobile ? 13 : 14,
              ),
              decoration: InputDecoration(
                labelText: 'Contract Description *',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isSmallMobile ? 13 : 14,
                ),
                hintText:
                    'Describe what this contract is about (e.g., daily commute, weekly shopping trips, etc.)',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isSmallMobile ? 12 : 13,
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
                  Icons.description,
                  color: LottoRunnersColors.primaryYellow,
                  size: isSmallMobile ? 20 : 24,
                ),
              ),
              maxLines: isSmallMobile ? 2 : 3,
              minLines: isSmallMobile ? 2 : 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a contract description';
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

            // Pricing and Submit

            // Pricing summary removed

            SizedBox(height: isSmallMobile ? 18 : 24),

            // Submit button

            SizedBox(
              width: double.infinity,
              height: isSmallMobile ? 46 : 50,
              child: ElevatedButton(
                onPressed: _submitContract,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
                  ),
                ),
                child: Text(
                  'Create Contract',
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

  /// Build pricing summary

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'car':
        return Icons.directions_car;

      case 'van':
        return Icons.directions_car;

      case 'bike':
        return Icons.directions_bike;

      case 'scooter':
        return Icons.directions_bike;

      default:
        return Icons.directions_car;
    }
  }
}






