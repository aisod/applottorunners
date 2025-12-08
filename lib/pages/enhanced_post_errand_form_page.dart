import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:lotto_runners/theme.dart';

/// Enhanced Post Errand Form
/// Universal fallback form for any unhandled service categories
class EnhancedPostErrandFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const EnhancedPostErrandFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<EnhancedPostErrandFormPage> createState() =>
      _EnhancedPostErrandFormPageState();
}

class _EnhancedPostErrandFormPageState
    extends State<EnhancedPostErrandFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String? _vehicleType;
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoadingVehicleTypes = false;
  final bool _needsDelivery = false;
  final bool _isFlexibleTiming = true;
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  bool _needsVehicle = false; // New: Does this request need a vehicle?
  DateTime? _scheduledDate; // Selected date when scheduled
  TimeOfDay? _scheduledTime; // Selected time when scheduled
  double? _locationLat;
  double? _locationLng;
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
        if (_vehicleTypes.isNotEmpty) {
          _vehicleType = (_vehicleTypes.first['name'] ?? '').toString();
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.selectedService['name'] ?? 'Custom Service'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
          ),
        ),
        backgroundColor: LottoRunnersColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white),
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
              // Hide price banner for special orders
              if (widget.selectedService['category'] != 'special_orders')
                _buildServiceHeader(theme, isMobile, isTablet),
              if (widget.selectedService['category'] != 'special_orders')
                SizedBox(height: isMobile ? 20 : 24),
              _buildTitleField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildDescriptionField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildLocationField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildPickupLocationField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildDeliveryLocationField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRequestNowToggle(theme, isMobile, isTablet),
              if (!_isImmediateRequest) ...[
                SizedBox(height: isMobile ? 16 : 20),
                _buildScheduledDateTimeFields(theme, isMobile, isTablet),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              _buildVehicleRequirementQuestion(theme, isMobile, isTablet),
              if (_needsVehicle) ...[
                SizedBox(height: isMobile ? 16 : 20),
                _buildVehicleTypeField(theme, isMobile, isTablet),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              _buildInstructionsField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildImageSection(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 28 : 32),
              _buildSubmitButton(theme, isMobile, isTablet),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader(ThemeData theme, bool isMobile, bool isTablet) {
    final basePrice = _calculateFinalPrice();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              color: LottoRunnersColors.primaryYellow,
              size: isMobile ? 24 : 28),
          SizedBox(width: isMobile ? 8 : 12),
          Text(
            'Price: N\$${basePrice.toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : isTablet ? 20 : 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Title *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _titleController,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Brief title for your service request',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            prefixIcon: Icon(Icons.title,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 20 : isTablet ? 22 : 24),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Service title is required';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Description *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText:
                'Please provide detailed information about what you need...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            if (value.trim().length < 20) {
              return 'Please provide a more detailed description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return SimpleLocationPicker(
      key: const ValueKey('service_location'),
      initialAddress: _locationController.text,
      labelText: 'Service Location *',
      hintText: 'Enter where the service should be performed',
      prefixIcon: Icons.location_on,
      iconColor: LottoRunnersColors.primaryYellow,
      onLocationSelected: (address, lat, lng) {
        setState(() {
          _locationController.text = address;
          _locationLat = lat;
          _locationLng = lng;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Service location is required';
        }
        return null;
      },
    );
  }

  Widget _buildPickupLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return SimpleLocationPicker(
      key: const ValueKey('pickup_location'),
      initialAddress: _pickupLocationController.text,
      labelText: 'Pickup Location',
      hintText: 'Enter pickup address if items need to be collected',
      prefixIcon: Icons.my_location,
      iconColor: LottoRunnersColors.primaryYellow,
      onLocationSelected: (address, lat, lng) {
        setState(() {
          _pickupLocationController.text = address;
          _pickupLat = lat;
          _pickupLng = lng;
        });
      },
      validator: (value) {
        // Pickup location is optional, no validation needed
        return null;
      },
    );
  }

  Widget _buildDeliveryLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return SimpleLocationPicker(
      key: const ValueKey('delivery_location'),
      initialAddress: _deliveryLocationController.text,
      labelText: 'Delivery Location (Optional)',
      hintText: 'Enter delivery address if items need to be delivered',
      prefixIcon: Icons.local_shipping,
      iconColor: LottoRunnersColors.primaryYellow,
      onLocationSelected: (address, lat, lng) {
        setState(() {
          _deliveryLocationController.text = address;
          _deliveryLat = lat;
          _deliveryLng = lng;
        });
      },
      validator: (value) {
        // Delivery location is optional, no validation needed
        return null;
      },
    );
  }

  // Priority UI removed

  Widget _buildRequestNowToggle(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
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
              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
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
                      horizontal: isMobile ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: !_isImmediateRequest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
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
                              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                            ),
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
                      horizontal: isMobile ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: _isImmediateRequest
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
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
                              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                            ),
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

  Widget _buildScheduledDateTimeFields(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector
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
              setState(() {
                _scheduledDate = pickedDate;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date *',
              hintText: 'Tap to choose date',
              prefixIcon: Icon(Icons.calendar_today,
                  color: LottoRunnersColors.primaryYellow,
                  size: isMobile ? 20 : 24),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
              child: Text(
                _scheduledDate == null
                    ? 'Tap to choose date'
                    : DateFormat('EEE, MMM d, yyyy').format(_scheduledDate!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _scheduledDate == null
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : theme.colorScheme.onSurface,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: isMobile ? 10 : 12),

        // Time selector
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _scheduledTime ??
                  TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
              helpText: 'Select time',
            );
            if (pickedTime != null) {
              setState(() {
                _scheduledTime = pickedTime;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Time *',
              hintText: 'Tap to choose time',
              prefixIcon: Icon(Icons.access_time,
                  color: LottoRunnersColors.primaryYellow,
                  size: isMobile ? 20 : 24),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
              child: Text(
                _scheduledTime == null
                    ? 'Tap to choose time'
                    : _scheduledTime!.format(context),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _scheduledTime == null
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRequirementQuestion(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Does this request require a vehicle?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes'),
                value: true,
                groupValue: _needsVehicle,
                onChanged: (value) {
                  setState(() {
                    _needsVehicle = value ?? false;
                    if (!_needsVehicle) {
                      _vehicleType = null; // Clear vehicle type if not needed
                    }
                  });
                },
                activeColor: LottoRunnersColors.primaryBlue,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No'),
                value: false,
                groupValue: _needsVehicle,
                onChanged: (value) {
                  setState(() {
                    _needsVehicle = value ?? false;
                    if (!_needsVehicle) {
                      _vehicleType = null; // Clear vehicle type if not needed
                    }
                  });
                },
                activeColor: LottoRunnersColors.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleTypeField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _needsVehicle ? 'Vehicle Type (Required)' : 'Vehicle Type (Optional)',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _vehicleTypes.any((t) => t['name'] == _vehicleType)
              ? _vehicleType
              : null,
          decoration: InputDecoration(
            hintText: _isLoadingVehicleTypes
                ? 'Loading vehicle types...'
                : 'Select vehicle type (optional)',
            prefixIcon: const Icon(Icons.directions_car,
                color: LottoRunnersColors.primaryYellow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _vehicleTypes.map((t) {
            final name = (t['name'] ?? '').toString();
            final capacity = t['capacity'];
            return DropdownMenuItem<String>(
              value: name,
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 18),
                  const SizedBox(width: 8),
                  Text(capacity != null ? '$name (cap $capacity)' : name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _vehicleType = value),
          validator: (value) {
            // Vehicle type is now optional
            return null;
          },
        ),
      ],
    );
  }


  Widget _buildInstructionsField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Instructions (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Any special requirements, preferences, or notes...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
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
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos to help explain your service requirements',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildSubmitButton(ThemeData theme, bool isMobile, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 48 : 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: Icon(
          _isImmediateRequest ? Icons.flash_on : Icons.check,
          color: theme.colorScheme.onPrimary,
          size: isMobile ? 18 : 20,
        ),
        label: Text(
          widget.selectedService['category'] == 'special_orders'
              ? (_isImmediateRequest ? 'Submit Special Order Request' : 'Submit Special Order Request')
              : (_isImmediateRequest
                  ? 'Request Service Now - N\$${_calculateFinalPrice().toStringAsFixed(2)}'
                  : 'Submit Request - N\$${_calculateFinalPrice().toStringAsFixed(2)}'),
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 10 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
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

  double _calculateFinalPrice() {
    return _getBasePrice();
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

    // Additional validation for vehicle requirement
    if (_needsVehicle && (_vehicleType == null || _vehicleType!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a vehicle type since this request requires a vehicle'),
          backgroundColor: Colors.red,
        ),
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
          final imagePath = '$userId/custom_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Create errand
      // Build scheduled start time if not immediate
      DateTime? scheduledStart;
      if (!_isImmediateRequest) {
        if (_scheduledDate == null || _scheduledTime == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please select a date and time for schedule')),
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

      final finalPrice = _calculateFinalPrice();
      final errandData = {
        'customer_id': userId,
        'title': _titleController.text.trim(),
        'description': _buildDescription(),
        'category': widget.selectedService['category'] ?? 'general',
        'price_amount': finalPrice,
        'calculated_price': finalPrice,
        'location_address': _locationController.text.trim(),
        'location_latitude': _locationLat,
        'location_longitude': _locationLng,
        'pickup_address': _pickupLocationController.text.trim().isNotEmpty
            ? _pickupLocationController.text.trim()
            : null,
        'pickup_latitude': _pickupLat,
        'pickup_longitude': _pickupLng,
        'delivery_address': _deliveryLocationController.text.trim().isNotEmpty
            ? _deliveryLocationController.text.trim()
            : null,
        'delivery_latitude': _deliveryLat,
        'delivery_longitude': _deliveryLng,
        'vehicle_type': _needsVehicle ? _vehicleType : null,
        //'needs_delivery': _needsDelivery,
        //'is_flexible_timing': _isFlexibleTiming,
        'special_instructions': _buildSpecialInstructions(),
        'image_urls': imageUrls,
        'status': widget.selectedService['category'] == 'special_orders' 
            ? 'pending_price' 
            : 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time': scheduledStart?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'priority_surcharge': 0.0,
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
                      '✅ Runner found! Your service request has been accepted.'),
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
          final isSpecialOrder = widget.selectedService['category'] == 'special_orders';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isSpecialOrder 
                ? 'Special order submitted! Admin will contact you with a price quote.'
                : 'Service request posted successfully!'),
              backgroundColor: isSpecialOrder ? Colors.orange : null,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your service request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a service request.';
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
    final details = [
      'Custom Service Request',
      'Title: ${_titleController.text.trim()}',
      'Location: ${_locationController.text.trim()}',
      'Delivery Required: ${_needsDelivery ? 'Yes' : 'No'}',
      'Flexible Timing: ${_isFlexibleTiming ? 'Yes' : 'No'}',
    ];

    details.add('\nDescription:\n${_descriptionController.text.trim()}');

    return details.join('\n');
  }

  String _buildSpecialInstructions() {
    final instructions = <String>[];

    // Add schedule information if any
    if (!_isImmediateRequest &&
        _scheduledDate != null &&
        _scheduledTime != null) {
      final scheduled = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
      instructions.add(
          'Scheduled for: ${DateFormat('EEE, MMM d, yyyy – h:mm a').format(scheduled)}');
    }

    // Add vehicle type information
    if (_vehicleType != null && _vehicleType!.isNotEmpty) {
      instructions.add('Vehicle Type: $_vehicleType');
    }

    if (_instructionsController.text.trim().isNotEmpty) {
      instructions.add(_instructionsController.text.trim());
    }

    return instructions.join('\n\n');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
