import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:typed_data';
import 'package:lotto_runners/theme.dart';

/// Delivery Service Form
/// Streamlined form for package and document delivery services
class DeliveryFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const DeliveryFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<DeliveryFormPage> createState() => _DeliveryFormPageState();
}

class _DeliveryFormPageState extends State<DeliveryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String _deliveryType = 'package';
  // Removed urgency selection in favor of Request Now vs Scheduled
  String? _vehicleType; // selected vehicle type name from DB
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoadingVehicleTypes = false;
  bool _requiresSignature = false;
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  double? _pickupLat;
  double? _pickupLng;
  double? _deliveryLat;
  double? _deliveryLng;
  final List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      setState(() => _isLoadingVehicleTypes = true);
      final types = await SupabaseConfig.getVehicleTypes();
      if (!mounted) return;

      setState(() {
        _vehicleTypes = types;
        _isLoadingVehicleTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingVehicleTypes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load vehicle types. Please check your internet connection and try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterVehicleTypesByDeliveryType() {
    return _vehicleTypes.where((type) {
      final name = (type['name'] ?? '').toString().toLowerCase();
      
      if (_deliveryType == 'food' || _deliveryType == 'document') {
        // Food and documents use motorcycle
        return name.contains('motorcycle');
      } else if (_deliveryType == 'package') {
        // Package uses truck, mini truck, sedan
        return name.contains('truck') || name.contains('sedan');
      }
      return false;
    }).toList();
  }

  String? _getVehicleIconUrl(String vehicleName) {
    const baseUrl = 'https://irfbqpruvkkbylwwikwx.supabase.co/storage/v1/object/public/icons';
    final name = vehicleName.toLowerCase();
    
    if (name.contains('motorcycle')) {
      return '$baseUrl/motorcycle.png';
    } else if (name.contains('sedan')) {
      return '$baseUrl/car.png';
    } else if (name.contains('mini') && name.contains('truck')) {
      return '$baseUrl/mini truck.png';
    } else if (name.contains('truck')) {
      return '$baseUrl/truck.png';
    }
    return null;
  }

  double _getVehiclePrice(String vehicleName) {
    final name = vehicleName.toLowerCase();
    final isBusiness = widget.userProfile?['user_type'] == 'business';
    
    if (name.contains('motorcycle')) {
      return isBusiness ? 75.0 : 43.0;
    } else if (name.contains('sedan')) {
      return isBusiness ? 100.0 : 75.0;
    } else if (name.contains('mini') && name.contains('truck')) {
      return isBusiness ? 650.0 : 350.0;
    } else if (name.contains('truck')) {
      return isBusiness ? 1200.0 : 850.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery Service',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: LottoRunnersColors.primaryBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : (isTablet ? 700 : 800),
            ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  _buildDeliveryTypeField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildVehicleTypeField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
              // Removed explicit urgency UI
                  _buildRequestNowToggle(theme, isMobile, isTablet),
              if (!_isImmediateRequest) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    _buildScheduledDateTime(theme, isMobile, isTablet),
                  ],
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildPickupLocationField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildDeliveryLocationField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildItemDescriptionField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildRecipientInfoFields(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildDeliveryOptionsField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildInstructionsField(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildImageSection(theme, isMobile, isTablet),
                  SizedBox(height: isMobile ? 28 : 32),
                  _buildSubmitButton(theme, isMobile),
                  SizedBox(height: isMobile ? 16 : 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'Choose what you need delivered *',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
          Row(
            children: [
              Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryType = 'food';
                    _vehicleType = null; // Reset vehicle selection
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 12,
                    horizontal: isMobile ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _deliveryType == 'food'
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: _deliveryType == 'food'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: _deliveryType == 'food' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                child: Column(
                  children: [
                      Icon(
                        Icons.restaurant,
                        color: _deliveryType == 'food'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        size: isMobile ? 24 : 28,
                      ),
                      SizedBox(height: isMobile ? 5 : 6),
                    Text(
                        'Food',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: isMobile ? 12 : 14,
                          color: _deliveryType == 'food'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryType = 'document';
                    _vehicleType = null; // Reset vehicle selection
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 12,
                    horizontal: isMobile ? 8 : 12,
                  ),
            decoration: BoxDecoration(
                    color: _deliveryType == 'document'
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: _deliveryType == 'document'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: _deliveryType == 'document' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                      Icon(
                        Icons.description,
                        color: _deliveryType == 'document'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        size: isMobile ? 24 : 28,
                      ),
                      SizedBox(height: isMobile ? 5 : 6),
                    Text(
                        'Documents',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: isMobile ? 12 : 14,
                          color: _deliveryType == 'document'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _deliveryType = 'package';
                    _vehicleType = null; // Reset vehicle selection
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 12,
                    horizontal: isMobile ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _deliveryType == 'package'
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: _deliveryType == 'package'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: _deliveryType == 'package' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
      children: [
                      Icon(
                        Icons.inventory_2,
                        color: _deliveryType == 'package'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        size: isMobile ? 24 : 28,
                      ),
                      SizedBox(height: isMobile ? 5 : 6),
        Text(
                        'Package',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: isMobile ? 12 : 14,
                          color: _deliveryType == 'package'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
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

  // Urgency UI removed in favor of Request Now vs Scheduled

  Widget _buildRequestNowToggle(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: isMobile ? 15 : 17,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isImmediateRequest = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12, 
                        horizontal: isMobile ? 8 : 16),
                    decoration: BoxDecoration(
                      color: !_isImmediateRequest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isImmediateRequest
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: !_isImmediateRequest
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          size: isMobile ? 18 : 20,
                        ),
                        SizedBox(width: isMobile ? 6 : 8),
                        Flexible(
                          child: Text(
                          'Scheduled',
                          style: TextStyle(
                            color: !_isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 13 : 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isImmediateRequest = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12, 
                        horizontal: isMobile ? 8 : 16),
                    decoration: BoxDecoration(
                      color: _isImmediateRequest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isImmediateRequest
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: _isImmediateRequest
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          size: isMobile ? 18 : 20,
                        ),
                        SizedBox(width: isMobile ? 6 : 8),
                        Flexible(
                          child: Text(
                          'Request Now',
                          style: TextStyle(
                            color: _isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                              fontSize: isMobile ? 13 : 15,
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
    );
  }

  Widget _buildScheduledDateTime(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _scheduledDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              helpText: 'Select date',
            );
            if (pickedDate != null) {
              setState(() => _scheduledDate = pickedDate);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date *',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
              prefixIcon: Icon(Icons.calendar_today, size: isMobile ? 20 : 24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 14,
              ),
            ),
              child: Text(
                _scheduledDate == null
                    ? 'Tap to choose date'
                    : '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ),
        SizedBox(height: isMobile ? 10 : 12),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _scheduledTime ?? TimeOfDay.fromDateTime(now),
              helpText: 'Select time',
            );
            if (pickedTime != null) {
              setState(() => _scheduledTime = pickedTime);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Time *',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
              prefixIcon: Icon(Icons.access_time, size: isMobile ? 20 : 24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 14,
              ),
            ),
              child: Text(
                _scheduledTime == null
                    ? 'Tap to choose time'
                    : _scheduledTime!.format(context),
              style: TextStyle(fontSize: isMobile ? 14 : 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeField(ThemeData theme, bool isMobile, bool isTablet) {
    final filteredVehicles = _filterVehicleTypesByDeliveryType();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the vehicle for your delivery *',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        if (_isLoadingVehicleTypes)
          const Center(child: CircularProgressIndicator())
        else if (filteredVehicles.isEmpty)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
              child: Row(
                children: [
                Icon(Icons.info, color: theme.colorScheme.error, size: isMobile ? 20 : 24),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'No vehicles available for this delivery type',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: isMobile ? 13 : 15,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: isMobile ? 95 : 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];
                final vehicleName = vehicle['name'];
                final isSelected = _vehicleType == vehicleName;
                final price = _getVehiclePrice(vehicleName);
                final iconUrl = _getVehicleIconUrl(vehicleName);
                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = isMobile 
                    ? (screenWidth * 0.55).clamp(160.0, 200.0)
                    : 220.0;
                
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(
                    right: isMobile ? 8 : 10,
                    left: index == 0 ? 4 : 0,
                  ),
                  child: _AnimatedShimmerCard(
                    onTap: () {
                      setState(() {
                        _vehicleType = vehicleName;
                      });
                    },
                    isSelected: isSelected,
                    theme: theme,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 8 : 10,
                      ),
                      child: Row(
                      children: [
                        // Vehicle Icon
                        Container(
                          width: isMobile ? 65 : 75,
                          height: isMobile ? 65 : 75,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: iconUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    iconUrl,
                                    fit: BoxFit.cover,
                                    width: isMobile ? 65 : 75,
                                    height: isMobile ? 65 : 75,
                                    cacheWidth: 128,
                                    cacheHeight: 128,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.directions_car,
                                          color: theme.colorScheme.onSurface,
                                          size: isMobile ? 32 : 38,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    color: theme.colorScheme.onSurface,
                                    size: isMobile ? 32 : 38,
                                  ),
                                ),
                        ),
                        SizedBox(width: isMobile ? 8 : 10),
                        // Vehicle Name and Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                vehicleName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isMobile ? 3 : 4),
                              Text(
                                'NAD ${price.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: isMobile ? 11 : 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selection Indicator
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: isMobile ? 18 : 20,
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
    );
  }

  Widget _buildPickupLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Location *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        SimpleLocationPicker(
          key: const ValueKey('pickup_location'),
          initialAddress: _pickupLocationController.text,
          labelText: 'Pickup Location',
          hintText: 'Enter pickup address',
          prefixIcon: Icons.location_on,
          iconColor: LottoRunnersColors.primaryYellow,
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _pickupLocationController.text = address;
              _pickupLat = lat;
              _pickupLng = lng;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pickup location is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Location *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        SimpleLocationPicker(
          key: const ValueKey('delivery_location'),
          initialAddress: _deliveryLocationController.text,
          labelText: 'Delivery Location',
          hintText: 'Enter delivery address',
          prefixIcon: Icons.location_on,
          iconColor: LottoRunnersColors.primaryYellow,
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _deliveryLocationController.text = address;
              _deliveryLat = lat;
              _deliveryLng = lng;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Delivery location is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildItemDescriptionField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Description *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
        ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _itemDescriptionController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Describe what needs to be delivered...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            errorStyle: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Item description is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRecipientInfoFields(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient Information *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
        ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        TextFormField(
          controller: _recipientNameController,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            labelText: 'Recipient Name *',
            labelStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            errorStyle: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.person,
                color: theme.colorScheme.tertiary, size: isMobile ? 20 : isTablet ? 22 : 24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Recipient name is required';
            }
            return null;
          },
        ),
        SizedBox(height: isMobile ? 12 : 16),
        TextFormField(
          controller: _recipientPhoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            labelText: 'Recipient Phone *',
            labelStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            errorStyle: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            prefixIcon: Icon(Icons.phone,
                color: theme.colorScheme.tertiary, size: isMobile ? 20 : isTablet ? 22 : 24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Recipient phone is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryOptionsField(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _requiresSignature ? Icons.verified : Icons.receipt,
            color: theme.colorScheme.primary,
            size: isMobile ? 24 : 28,
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signature Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 15 : 17,
                  ),
                ),
                Text(
                  _requiresSignature
                      ? 'Recipient must sign upon delivery'
                      : 'Delivery without signature requirement',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _requiresSignature,
            onChanged: (value) => setState(() => _requiresSignature = value),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
        ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Delivery instructions, access codes, etc...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            errorStyle: TextStyle(fontSize: isMobile ? 12 : isTablet ? 13 : 14),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Images (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
        ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          'Add photos of items to be delivered',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 16),
        if (_images.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: theme.colorScheme.onError,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isMobile) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(
              _isImmediateRequest
                  ? 'Request Now - N\$${_getSelectedVehiclePrice().toStringAsFixed(2)}'
                  : 'Submit Request - N\$${_getSelectedVehiclePrice().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  double _getBasePrice() {
    if (widget.userProfile?['user_type'] == 'business') {
      return (widget.selectedService['business_price'] ??
              widget.selectedService['base_price'] ??
              0.0)
          .toDouble();
    }
    return (widget.selectedService['base_price'] ?? 0.0).toDouble();
  }

  // Get selected vehicle price
  double _getSelectedVehiclePrice() {
    if (_vehicleType == null) return 0.0;
    return _getVehiclePrice(_vehicleType!);
  }

  // Urgency surcharge removed

  double _calculateFinalPrice() {
    // Use vehicle price instead of base service price
    final vehiclePrice = _getSelectedVehiclePrice();
    return vehiclePrice > 0 ? vehiclePrice : _getBasePrice();
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      Uint8List? imageBytes = fromCamera
          ? await ImageUploadHelper.captureImage()
          : await ImageUploadHelper.pickImageFromGallery();

      if (imageBytes != null) {
        setState(() => _images.add(imageBytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to add image. Please try again or select a different image.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate vehicle type is selected
    if (_vehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Please sign in to continue');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = '$userId/delivery_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Build scheduled start time
      DateTime? scheduledStart;
      if (!_isImmediateRequest) {
        if (_scheduledDate == null || _scheduledTime == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select date and time')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        scheduledStart = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      // Create errand
      final finalPrice = _calculateFinalPrice();
      final errandData = {
        'customer_id': userId,
        'title': 'Delivery Service',
        'description': _buildDescription(),
        'category': 'delivery',
        'price_amount': finalPrice,
        'calculated_price': finalPrice,
        'location_address': _pickupLocationController.text.trim(),
        'location_latitude': _pickupLat,
        'location_longitude': _pickupLng,
        'pickup_address': _pickupLocationController.text.trim(),
        'pickup_latitude': _pickupLat,
        'pickup_longitude': _pickupLng,
        'delivery_address': _deliveryLocationController.text.trim(),
        'delivery_latitude': _deliveryLat,
        'delivery_longitude': _deliveryLng,
        'vehicle_type': _vehicleType,
        'service_type': _vehicleType, // Store vehicle type as service_type for consistency
        'special_instructions': _buildSpecialInstructions(),
        'image_urls': imageUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time': scheduledStart?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'service_type_price': finalPrice,
          'service_type': _vehicleType, // Store vehicle type as service type
          'vehicle_type': _vehicleType,
          'vehicle_price': _getSelectedVehiclePrice(),
          'urgency_surcharge': 0.0,
          'user_type': widget.userProfile?['user_type'] ?? 'individual',
          'final_price': finalPrice,
        },
      };

      if (_isImmediateRequest) {
        // For immediate requests, store temporarily until accepted
        final pendingId = ImmediateErrandService.generatePendingErrandId();
        errandData['id'] = pendingId;

        // Add customer information for display
        errandData['customer'] = {
          'full_name': widget.userProfile?['full_name'] ?? 'Unknown Customer',
          'phone': widget.userProfile?['phone'] ?? '',
        };

        // Add created_at timestamp for display
        errandData['created_at'] = DateTime.now().toIso8601String();

        await ImmediateErrandService.storePendingErrand(errandData);

        if (mounted) {
          // Show "Looking for Runner" popup for immediate requests
          RunnerSearchService.instance.showLookingForRunnerPopup(
            context: context,
            errandId: pendingId,
            errandTitle: errandData['title'].toString(),
            onRetry: () {
              // Retry the immediate request
              _submitForm();
            },
            onCancel: () {
              // Cancel the request and remove from pending, but keep user in form
              ImmediateErrandService.removePendingErrand(pendingId);
              // Don't navigate away - keep user in the form
            },
            onRunnerFound: () {
              // Runner found, show success and go back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✅ Runner found! Your delivery request has been accepted.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
          );
        }
      } else {
        // For scheduled requests, create errand immediately
        await SupabaseConfig.createErrand(errandData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Delivery request posted successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your delivery request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a delivery request.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('validation') || e.toString().contains('constraint')) {
          errorMessage = 'Please check that all required fields are filled correctly.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildDescription() {
    final deliveryTypeNames = {
      'package': 'Package/Parcel',
      'document': 'Documents',
      'food': 'Food Delivery',
    };

    final details = [
      'Delivery Service Request',
      'Type: ${deliveryTypeNames[_deliveryType]}',
      'Request: ${_isImmediateRequest ? 'Request Now' : 'Scheduled'}',
      'Pickup: ${_pickupLocationController.text.trim()}',
      'Delivery: ${_deliveryLocationController.text.trim()}',
      'Recipient: ${_recipientNameController.text.trim()} (${_recipientPhoneController.text.trim()})',
      'Signature Required: ${_requiresSignature ? 'Yes' : 'No'}',
      '',
      'Item Description:',
      _itemDescriptionController.text.trim(),
    ];

    if (_instructionsController.text.trim().isNotEmpty) {
      details.add('\nInstructions: ${_instructionsController.text.trim()}');
    }

    return details.join('\n');
  }

  String _buildSpecialInstructions() {
    final details = <String>[];

    // Add delivery-specific information
    details.add('DELIVERY DETAILS:');
    details.add('• Delivery Type: $_deliveryType');
    details.add(
        '• Request Type: ${_isImmediateRequest ? 'Request Now' : 'Scheduled'}');
    details
        .add('• Item Description: ${_itemDescriptionController.text.trim()}');
    details.add('• Recipient Name: ${_recipientNameController.text.trim()}');
    details.add('• Recipient Phone: ${_recipientPhoneController.text.trim()}');
    details.add('• Signature Required: ${_requiresSignature ? 'Yes' : 'No'}');

    // Add custom instructions if provided
    if (_instructionsController.text.trim().isNotEmpty) {
      details.add('\nADDITIONAL INSTRUCTIONS:');
      details.add(_instructionsController.text.trim());
    }

    return details.join('\n');
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _itemDescriptionController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

// Shimmer animation widget for delivery type and vehicle cards
class _AnimatedShimmerCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;
  final ThemeData theme;

  const _AnimatedShimmerCard({
    required this.child,
    required this.onTap,
    required this.isSelected,
    required this.theme,
  });

  @override
  State<_AnimatedShimmerCard> createState() => _AnimatedShimmerCardState();
}

class _AnimatedShimmerCardState extends State<_AnimatedShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.theme.colorScheme.primary.withOpacity(0.1)
                  : widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? widget.theme.colorScheme.primary
                    : widget.theme.colorScheme.outline.withOpacity(0.3),
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Shimmer effect overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Transform.translate(
                      offset: Offset(_animation.value * 200, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              LottoRunnersColors.primaryYellow.withOpacity(0.2),
                              LottoRunnersColors.primaryYellow.withOpacity(0.5),
                              LottoRunnersColors.primaryYellow.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                child!,
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
