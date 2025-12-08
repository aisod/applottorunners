import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'dart:typed_data';
import 'package:lotto_runners/theme.dart';

/// Elderly Services Form
/// Streamlined form for elderly care and assistance services
class ElderlyServicesFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const ElderlyServicesFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<ElderlyServicesFormPage> createState() =>
      _ElderlyServicesFormPageState();
}

class _ElderlyServicesFormPageState extends State<ElderlyServicesFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _servicesNeededController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String _serviceType =
      'companionship'; // 'companionship', 'personal_care', 'meal_prep', 'medication_reminder', 'transportation'
  bool _hasMedicalNeeds = false;
  final bool _needsSpecialAssistance = false;
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  double? _locationLat;
  double? _locationLng;
  double? _pickupLat;
  double? _pickupLng;
  final List<Uint8List> _images = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Elderly Services',
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
              _buildServiceHeader(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildServiceTypeField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRequestNowToggle(theme, isMobile, isTablet),
              if (!_isImmediateRequest) ...[
                SizedBox(height: isMobile ? 16 : 20),
                _buildScheduledDateTime(theme, isMobile, isTablet),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              _buildLocationField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildServicesNeededField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildMedicalInfoField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildEmergencyContactField(theme, isMobile, isTablet),
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
    final basePrice = _getBasePrice();

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

  Widget _buildServiceTypeField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Type *',
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          value: _serviceType,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.medical_services,
              color: LottoRunnersColors.primaryYellow,
              size: isMobile ? 20 : 24,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'companionship',
              child: Text(
                'Companionship',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
            DropdownMenuItem(
              value: 'personal_care',
              child: Text(
                'Personal Care',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
            DropdownMenuItem(
              value: 'meal_prep',
              child: Text(
                'Meal Preparation',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
            DropdownMenuItem(
              value: 'medication_reminder',
              child: Text(
                'Medication Reminders',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text(
                'Other',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _serviceType = value!),
        ),
      ],
    );
  }

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

  Widget _buildScheduledDateTime(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Field
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
            if (pickedDate != null) setState(() => _scheduledDate = pickedDate);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date *',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              prefixIcon: Icon(
                Icons.calendar_today,
                size: isMobile ? 20 : 24,
                color: LottoRunnersColors.primaryYellow,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
              child: Text(
                _scheduledDate == null
                    ? 'Tap to choose date'
                    : '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        // Time Field
        GestureDetector(
          onTap: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _scheduledTime ?? TimeOfDay.now(),
              helpText: 'Select time',
            );
            if (pickedTime != null) setState(() => _scheduledTime = pickedTime);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Time *',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              prefixIcon: Icon(
                Icons.access_time,
                size: isMobile ? 20 : 24,
                color: LottoRunnersColors.primaryYellow,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
              child: Text(
                _scheduledTime == null
                    ? 'Tap to choose time'
                    : '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleLocationPicker(
          key: const ValueKey('service_location'),
          initialAddress: _locationController.text,
          labelText: 'Service Location *',
          hintText: 'Enter client\'s address or care facility location',
          prefixIcon: Icons.home,
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
        ),
        SizedBox(height: isMobile ? 20 : 24),
        SimpleLocationPicker(
          key: const ValueKey('pickup_location'),
          initialAddress: _pickupLocationController.text,
          labelText: 'Pickup Location',
          hintText: 'Enter pickup address if client needs transportation',
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
            // Pickup location is optional
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildServicesNeededField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specific Services Needed *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _servicesNeededController,
          maxLines: 4,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Please describe the specific care and assistance needed...',
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
              return 'Please describe the services needed';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMedicalInfoField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasMedicalNeeds,
              onChanged: (value) =>
                  setState(() => _hasMedicalNeeds = value ?? false),
            ),
            Expanded(
              child: Text(
                'Client has medical conditions or special needs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                ),
              ),
            ),
          ],
        ),
        if (_hasMedicalNeeds) ...[
          SizedBox(height: isMobile ? 12 : 16),
          TextFormField(
            controller: _medicalInfoController,
            maxLines: 3,
            style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
            decoration: InputDecoration(
              labelText: 'Medical Information',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
              hintText: 'Please describe any medical conditions, medications, or special care requirements...',
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
              if (_hasMedicalNeeds && (value == null || value.trim().isEmpty)) {
                return 'Please provide medical information';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEmergencyContactField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contact *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _emergencyContactController,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Name and phone number of emergency contact',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            prefixIcon: Icon(
              Icons.emergency,
              color: theme.colorScheme.error,
              size: isMobile ? 20 : 24,
            ),
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
              return 'Emergency contact is required';
            }
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
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Any additional care instructions or preferences...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
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
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photos that may help the caregiver (home layout, medical equipment, etc.)',
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
          _isImmediateRequest
              ? 'Request Service Now - N\$${_getBasePrice().toStringAsFixed(2)}'
              : 'Submit Request - N\$${_getBasePrice().toStringAsFixed(2)}',
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

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Please sign in to continue');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imagePath = '$userId/elderly_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Create errand
      // Build scheduled time if not immediate
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

      final errandData = {
        'customer_id': userId,
        'title': 'Elderly Services',
        'description': _buildDescription(),
        'category': 'elderly_services',
        'price_amount': _getBasePrice(),
        'calculated_price': _getBasePrice(),
        'location_address': _locationController.text.trim(),
        'location_latitude': _locationLat,
        'location_longitude': _locationLng,
        'pickup_address': _pickupLocationController.text.trim().isNotEmpty
            ? _pickupLocationController.text.trim()
            : null,
        'pickup_latitude': _pickupLat,
        'pickup_longitude': _pickupLng,
        'service_type': _serviceType,
        'special_instructions': _buildSpecialInstructions(),
        'image_urls': imageUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time': scheduledStart?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'user_type': widget.userProfile?['user_type'] ?? 'individual',
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
                      '✅ Runner found! Your elderly services request has been accepted.'),
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
                content: Text('Elderly services request posted successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your elderly services request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post an elderly services request.';
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

  String _buildSpecialInstructions() {
    final instructions = <String>[];

    // Services needed
    if (_servicesNeededController.text.trim().isNotEmpty) {
      instructions.add('SERVICES NEEDED:');
      instructions.add(_servicesNeededController.text.trim());
      instructions.add('');
    }

    // Medical information
    if (_hasMedicalNeeds && _medicalInfoController.text.trim().isNotEmpty) {
      instructions.add('MEDICAL INFORMATION:');
      instructions.add(_medicalInfoController.text.trim());
      instructions.add('');
    }

    // Emergency contact
    if (_emergencyContactController.text.trim().isNotEmpty) {
      instructions.add('EMERGENCY CONTACT:');
      instructions.add(_emergencyContactController.text.trim());
      instructions.add('');
    }

    // Special assistance
    if (_needsSpecialAssistance) {
      instructions.add('SPECIAL ASSISTANCE REQUIRED: Yes');
      instructions.add('');
    }

    // Additional instructions
    if (_instructionsController.text.trim().isNotEmpty) {
      instructions.add('ADDITIONAL INSTRUCTIONS:');
      instructions.add(_instructionsController.text.trim());
    }

    return instructions.join('\n');
  }

  String _buildDescription() {
    final serviceTypeNames = {
      'companionship': 'Companionship',
      'personal_care': 'Personal Care',
      'meal_prep': 'Meal Preparation',
      'medication_reminder': 'Medication Reminders',
      'transportation': 'Transportation Assistance',
    };

    final details = [
      'Elderly Services Request',
      'Service Type: ${serviceTypeNames[_serviceType]}',
      'Service Location: ${_locationController.text.trim()}',
      if (_pickupLocationController.text.trim().isNotEmpty)
        'Pickup Location: ${_pickupLocationController.text.trim()}',
    ];

    return details.join('\n');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _pickupLocationController.dispose();
    _servicesNeededController.dispose();
    _medicalInfoController.dispose();
    _emergencyContactController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
