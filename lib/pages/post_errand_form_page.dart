import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/service_icons.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class PostErrandFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const PostErrandFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<PostErrandFormPage> createState() => _PostErrandFormPageState();
}

class _PostErrandFormPageState extends State<PostErrandFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dueDateTime;

  String? _selectedVehicleType;
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  final List<Uint8List> _selectedImages = [];

  // Location coordinates
  double? _locationLat;
  double? _locationLng;
  double? _pickupLat;
  double? _pickupLng;
  double? _deliveryLat;
  double? _deliveryLng;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'bicycle',
      'name': 'Bicycle',
      'icon': Icons.pedal_bike,
      'description': 'For small items and short distances',
    },
    {
      'id': 'motorcycle',
      'name': 'Motorcycle',
      'icon': Icons.motorcycle,
      'description': 'For medium items and quick delivery',
    },
    {
      'id': 'car',
      'name': 'Car',
      'icon': Icons.directions_car,
      'description': 'For multiple items and comfortable transport',
    },
    {
      'id': 'pickup_truck',
      'name': 'Pickup Truck',
      'icon': Icons.local_shipping,
      'description': 'For large items and bulk deliveries',
    },
    {
      'id': 'van',
      'name': 'Van',
      'icon': Icons.airport_shuttle,
      'description': 'For very large items and moving services',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  // Get the appropriate price for a service based on user type
  double _getServicePrice() {
    if (widget.userProfile != null &&
        widget.userProfile!['user_type'] == 'business') {
      return (widget.selectedService['business_price'] ??
              widget.selectedService['base_price'] ??
              0.0)
          .toDouble();
    }
    return (widget.selectedService['base_price'] ?? 0.0).toDouble();
  }

  // Icon mapping moved to ServiceIcons utility for consistency across app.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post Errand',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                  minHeight: constraints.maxHeight,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSelectedServiceHeader(theme),
                      SizedBox(height: isMobile ? 16 : 24),
                      if (widget.selectedService['requires_vehicle'])
                        _buildVehicleSelection(theme),
                      if (widget.selectedService['requires_vehicle'])
                        SizedBox(height: isMobile ? 16 : 24),
                      _buildLocationInfo(theme),
                      SizedBox(height: isMobile ? 16 : 24),
                      if (!_isImmediateRequest) ...[
                        _buildTimeCustomization(theme),
                        SizedBox(height: isMobile ? 16 : 24),
                      ],
                      _buildRequestNowToggle(theme),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildImageSection(theme),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildSpecialInstructions(theme),
                      SizedBox(height: isMobile ? 24 : 32),
                      _buildSubmitButton(theme),
                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedServiceHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LottoRunnersColors.primaryBlue,
            LottoRunnersColors.primaryBlueDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ServiceIcons.getIcon(widget.selectedService['icon_name']),
                color: LottoRunnersColors.primaryYellow,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.selectedService['name'] ?? 'Unknown Service',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.selectedService['description'],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                theme,
                Icons.attach_money,
                'N\$${_getServicePrice().toStringAsFixed(2)}',
                theme.colorScheme.secondary,
              ),
              _buildInfoChip(
                theme,
                Icons.timer,
                '24hrs',
                theme.colorScheme.tertiary,
              ),
              if (widget.selectedService['requires_vehicle'])
                _buildInfoChip(
                  theme,
                  Icons.directions_car,
                  'Vehicle Required',
                  theme.colorScheme.error,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Vehicle Type',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedVehicleType != null
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline.withOpacity(0.5),
              width: _selectedVehicleType != null ? 2 : 1,
            ),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedVehicleType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: 'Choose a vehicle type...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: _selectedVehicleType != null
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _vehicleTypes.firstWhere(
                          (v) => v['id'] == _selectedVehicleType,
                        )['icon'],
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                    )
                  : Icon(
                      Icons.directions_car_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            isExpanded: true,
            itemHeight: 56,
            items: _vehicleTypes.map((vehicle) {
              return DropdownMenuItem<String>(
                value: vehicle['id'],
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          vehicle['icon'],
                          color: theme.colorScheme.secondary,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vehicle['name'],
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              vehicle['description'],
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedVehicleType = value;
                });
              }
            },
            validator: (value) {
              if (widget.selectedService['requires_vehicle'] && value == null) {
                return 'Please select a vehicle type';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SimpleLocationPicker(
          key: const ValueKey('pickup_location'),
          initialAddress: _locationController.text,
          labelText: 'Pickup Location',
          hintText: 'Enter where to pick up items',
          prefixIcon: Icons.my_location,
          iconColor: theme.colorScheme.primary,
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _locationController.text = address;
              _locationLat = lat;
              _locationLng = lng;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pickup location is required';
            }
            if (value.trim().length < 5) {
              return 'Please provide a detailed location';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SimpleLocationPicker(
          key: const ValueKey('delivery_location'),
          initialAddress: _deliveryController.text,
          labelText: 'Delivery Location',
          hintText: 'Enter where to deliver items',
          prefixIcon: Icons.local_shipping,
          iconColor: theme.colorScheme.tertiary,
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _deliveryController.text = address;
              _deliveryLat = lat;
              _deliveryLng = lng;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Delivery location is required';
            }
            if (value.trim().length < 5) {
              return 'Please provide a detailed location';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeCustomization(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Schedule',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _pickupDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              helpText: 'Select pickup date',
            );
            if (pickedDate != null) {
              setState(() {
                _pickupDate = pickedDate;
                _updateDueDateTime();
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Pickup Date',
              hintText: 'Select the date for pickup',
              prefixIcon: Icon(Icons.calendar_today,
                  color: theme.colorScheme.secondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.secondary,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _pickupDate == null
                    ? 'Tap to choose pickup date'
                    : DateFormat('EEE, MMM d, yyyy').format(_pickupDate!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _pickupDate == null
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _pickupTime ??
                  TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
              helpText: 'Select pickup time',
            );
            if (pickedTime != null) {
              setState(() {
                _pickupTime = pickedTime;
                _updateDueDateTime();
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Pickup Time',
              hintText: 'Select the time for pickup',
              prefixIcon: const Icon(Icons.access_time,
                  color: LottoRunnersColors.primaryYellow),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.tertiary,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _pickupTime == null
                    ? 'Tap to choose pickup time'
                    : _pickupTime!.format(context),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _pickupTime == null
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Select both date and time for when you need the errand to be completed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestNowToggle(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 12 : 16),
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
            ),
          ),
          const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduled',
                          style: TextStyle(
                            color: !_isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isImmediateRequest = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Request Now',
                          style: TextStyle(
                            color: _isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
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

  // Helper method to update _dueDateTime when either date or time changes
  void _updateDueDateTime() {
    if (_pickupDate != null && _pickupTime != null) {
      _dueDateTime = DateTime(
        _pickupDate!.year,
        _pickupDate!.month,
        _pickupDate!.day,
        _pickupTime!.hour,
        _pickupTime!.minute,
      );
    } else {
      _dueDateTime = null;
    }
  }

  Widget _buildImageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Images (Optional)',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: theme.colorScheme.onError,
                              size: 20,
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
                icon: Icon(
                  Icons.photo_library,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'From Gallery',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: Icon(
                  Icons.camera_alt,
                  color: theme.colorScheme.onSecondary,
                ),
                label: Text(
                  'Take Photo',
                  style: TextStyle(color: theme.colorScheme.onSecondary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialInstructions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Instructions (Optional)',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Any additional notes for the runner...',
            hintText: 'e.g., "Please bring change for the meter."',
            prefixIcon: Icon(Icons.note, color: theme.colorScheme.tertiary),
            prefixIconColor: LottoRunnersColors.primaryYellow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.tertiary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _confirmAndSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.6),
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Posting Errand...',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isImmediateRequest ? Icons.flash_on : Icons.send,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isImmediateRequest
                      ? 'Request Service Now - N\${_getServicePrice().toStringAsFixed(2)}'
                      : 'Post Errand - N\${_getServicePrice().toStringAsFixed(2)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    if (_formKey.currentState?.validate() != true) return;

    // Check if location is provided
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide your location'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_isImmediateRequest && _pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pickup date'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_isImmediateRequest && _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pickup time'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_isImmediateRequest && _dueDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pickup date and time must be in the future'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (widget.selectedService['requires_vehicle'] &&
        _selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a vehicle type'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Errand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to post this errand?'),
            const SizedBox(height: 16),
            Container(
              padding:
                  EdgeInsets.all(Responsive.isSmallMobile(context) ? 8 : 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedService['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      'Price: N\${_getServicePrice().toStringAsFixed(2)}'),
                  if (!_isImmediateRequest && _dueDateTime != null)
                    Text(
                        'Pickup: ${DateFormat('EEE, MMM d, yyyy • HH:mm').format(_dueDateTime!.toLocal())}')
                  else
                    const Text('Pickup: Request Now'),
                  if (_selectedImages.isNotEmpty)
                    Text('Images: ${_selectedImages.length} attached'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Post Errand'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitErrand();
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      // Show loading feedback for camera
      if (fromCamera && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening camera...'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      print(
          'Attempting to ${fromCamera ? 'capture from camera' : 'pick from gallery'}');

      Uint8List? imageBytes;

      if (fromCamera) {
        // Try primary camera method first
        try {
          imageBytes = await ImageUploadHelper.captureImage();
        } catch (e) {
          print('Primary camera method failed: $e');
          // Fallback to alternative camera method
          try {
            print('Trying alternative camera method...');
            imageBytes = await ImageUploadHelper.captureImageAlternative();
          } catch (e2) {
            print('Alternative camera method also failed: $e2');
            rethrow; // Let the outer catch handle the error
          }
        }
      } else {
        imageBytes = await ImageUploadHelper.pickImageFromGallery();
      }

      if (imageBytes != null) {
        print(
            'Image ${fromCamera ? 'captured' : 'selected'} successfully. Size: ${imageBytes.length} bytes');

        setState(() {
          _selectedImages.add(imageBytes!);
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fromCamera
                  ? 'Photo captured successfully!'
                  : 'Image selected from gallery'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print(
            'No image ${fromCamera ? 'captured' : 'selected'} - user cancelled or error occurred');
      }
    } catch (e) {
      print('Error in _pickImage (fromCamera: $fromCamera): $e');

      if (mounted) {
        String errorMessage = fromCamera
            ? 'Failed to access camera. Please check camera permissions and try again.'
            : 'Failed to access gallery. Please check permissions and try again.';

        if (e.toString().contains('permission')) {
          errorMessage = fromCamera
              ? 'Camera permission denied. Please enable camera access in your device settings.'
              : 'Storage permission denied. Please enable storage access in your device settings.';
        } else if (e.toString().contains('camera')) {
          errorMessage =
              'Camera is not available on this device or is being used by another app.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _pickImage(fromCamera),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitErrand() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) {
        throw Exception('Please sign in to post an errand');
      }

      // Debug: Print the errand data being sent
      print('🔍 Submitting errand with data:');
      print('  - User ID: $userId');
      print('  - Selected Service: ${widget.selectedService}');
      print('  - Service Category: ${widget.selectedService['category']}');
      print('  - Service Name: ${widget.selectedService['name']}');
      print('  - Location: ${_locationController.text.trim()}');
      print('  - Pickup: ${_pickupController.text.trim()}');
      print('  - Delivery: ${_deliveryController.text.trim()}');
      print('  - Instructions: ${_instructionsController.text.trim()}');
      print('  - Pickup Date: $_pickupDate');
      print('  - Pickup Time: $_pickupTime');
      print('  - Due DateTime: $_dueDateTime');

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading ${_selectedImages.length} image(s)...'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final imagePath = '$userId/errand_${timestamp}_$i.jpg';
            final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images',
              imagePath,
              _selectedImages[i],
            );
            imageUrls.add(imageUrl);
          } catch (imageError) {
            print('Error uploading image $i: $imageError');
            // Continue with other images even if one fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to upload image ${i + 1}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }

      // Create errand data matching the database schema exactly
      final errandData = {
        'customer_id': userId,
        'title': widget.selectedService[
            'name'], // Use 'name' instead of 'title' from services table
        'description': _instructionsController.text.trim().isEmpty
            ? widget.selectedService['description']
            : '${widget.selectedService['description']}\n\nSpecial Instructions: ${_instructionsController.text.trim()}',
        'category': widget.selectedService['category'],
        'price_amount': _getServicePrice(),
        'time_limit_hours': () {
          if (_dueDateTime == null) {
            return 24; // Default to 24 hours if no specific time
          }
          final diff = _dueDateTime!.toUtc().difference(DateTime.now().toUtc());
          final hours = (diff.inMinutes / 60).ceil();
          return hours < 1 ? 1 : hours;
        }(),
        'location_address': _locationController.text.trim(),
        'location_latitude': _locationLat,
        'location_longitude': _locationLng,
        'pickup_address': _pickupController.text.trim().isEmpty
            ? null
            : _pickupController.text.trim(),
        'pickup_latitude': _pickupLat,
        'pickup_longitude': _pickupLng,
        'delivery_address': _deliveryController.text.trim().isEmpty
            ? null
            : _deliveryController.text.trim(),
        'delivery_latitude': _deliveryLat,
        'delivery_longitude': _deliveryLng,
        'special_instructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        'requires_vehicle': widget.selectedService['requires_vehicle'],
        'image_urls': imageUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time':
            !_isImmediateRequest ? _dueDateTime?.toIso8601String() : null,
      };

      // Debug: Print the final errand data
      print('🔍 Final errand data to be sent:');
      errandData.forEach((key, value) {
        print('  - $key: $value');
      });

      // Add vehicle type information to special instructions if selected
      if (_selectedVehicleType != null) {
        final vehicleInfo = _vehicleTypes.firstWhere(
          (v) => v['id'] == _selectedVehicleType,
        );
        final currentInstructions =
            errandData['special_instructions'] as String?;
        final vehicleNote =
            'Required Vehicle: ${vehicleInfo['name']} - ${vehicleInfo['description']}';

        if (currentInstructions == null || currentInstructions.isEmpty) {
          errandData['special_instructions'] = vehicleNote;
        } else {
          errandData['special_instructions'] =
              '$currentInstructions\n\n$vehicleNote';
        }
      }

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
            errandTitle: errandData['title'],
            onRetry: () {
              // Retry the immediate request
              _submitErrand();
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
                  content:
                      Text('✅ Runner found! Your errand has been accepted.'),
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
            SnackBar(
              content: const Text('Errand posted successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to post errand';

        // Provide more specific error messages
        if (e.toString().contains('not authenticated')) {
          errorMessage = 'Please sign in to post an errand';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again';
        } else if (e.toString().contains('validation') ||
            e.toString().contains('constraint')) {
          // Check for specific constraint violations
          if (e.toString().contains('errands_category_check')) {
            errorMessage =
                'Invalid service category. Please try selecting a different service.';
          } else if (e.toString().contains('constraint')) {
            errorMessage =
                'Data validation error. Please check all fields and try again.';
          } else {
            errorMessage =
                'Please check that all required fields are filled correctly';
          }
        } else if (e.toString().contains('storage') ||
            e.toString().contains('upload')) {
          errorMessage =
              'Failed to upload images. Please try again or post without images';
        } else {
          errorMessage = 'An unexpected error occurred. Please try again';
        }

        print('Error posting errand: $e'); // For debugging

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _submitErrand(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
