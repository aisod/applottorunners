import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'dart:typed_data';
import 'package:lotto_runners/theme.dart';

/// Document Services Form
/// Streamlined form for document processing and printing services
class DocumentServicesFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const DocumentServicesFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<DocumentServicesFormPage> createState() =>
      _DocumentServicesFormPageState();
}

class _DocumentServicesFormPageState extends State<DocumentServicesFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _documentDescriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String _serviceType =
      'application_submission'; // 'application_submission', 'certification'
  String _serviceOption =
      'collect_and_deliver'; // 'collect_and_deliver', 'drop_off_only'
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  double? _locationLat;
  double? _locationLng;
  double? _pickupLat;
  double? _pickupLng;
  final List<Uint8List> _images = [];
  final List<Uint8List> _pdfFiles = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Document Services',
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
              _buildDocumentDescriptionField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildServiceOptionField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRequestNowToggle(theme, isMobile, isTablet),
              if (!_isImmediateRequest) ...[
                SizedBox(height: isMobile ? 20 : 24),
                _buildScheduledDateTime(theme, isMobile, isTablet),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              if (_serviceOption == 'collect_and_deliver') ...[
                _buildPickupLocationField(theme, isMobile, isTablet),
                SizedBox(height: isMobile ? 20 : 24),
                _buildLocationField(theme, isMobile, isTablet),
              ] else if (_serviceOption == 'drop_off_only') ...[
                _buildLocationField(theme, isMobile, isTablet),
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
    final basePrice = _getServiceTypePrice();

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
          style: theme.textTheme.titleMedium?.copyWith(
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
            prefixIcon: Icon(Icons.business_center,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 20 : 24),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isMobile ? 10 : 12)),
          ),
          items: [
            DropdownMenuItem(value: 'application_submission', 
                child: Text('Application Submission', style: TextStyle(fontSize: isMobile ? 14 : 16))),
            DropdownMenuItem(value: 'certification', 
                child: Text('Certification of Documents', style: TextStyle(fontSize: isMobile ? 14 : 16))),
          ],
          onChanged: (value) => setState(() => _serviceType = value!),
        ),
      ],
    );
  }

  Widget _buildDocumentDescriptionField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Description *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _documentDescriptionController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Describe your documents and requirements...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isMobile ? 10 : 12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Document description is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildServiceOptionField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Option *',
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: Text(
                  'Collect & Deliver',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'We collect documents and deliver completed work',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                  ),
                ),
                value: 'collect_and_deliver',
                groupValue: _serviceOption,
                onChanged: (value) => setState(() => _serviceOption = value!),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 4 : 8,
                ),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: Text(
                  'Drop-off Only',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'You drop off documents, we deliver completed work',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                  ),
                ),
                value: 'drop_off_only',
                groupValue: _serviceOption,
                onChanged: (value) => setState(() => _serviceOption = value!),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 4 : 8,
                ),
              ),
            ],
          ),
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
              labelText: 'Date',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
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
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
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
              labelText: 'Time',
              labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
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
                    : _scheduledTime!.format(context),
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
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
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        const SizedBox(height: 8),
        SimpleLocationPicker(
          key: const ValueKey('pickup_location'),
          initialAddress: _pickupLocationController.text,
          labelText: 'Where should we collect the documents?',
          hintText: 'Enter your office, home, or document location',
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
            if (_serviceOption == 'collect_and_deliver' &&
                (value == null || value.trim().isEmpty)) {
              return 'Pickup location is required for collect & deliver service';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Location *',
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        const SizedBox(height: 8),
        SimpleLocationPicker(
          key: const ValueKey('delivery_location'),
          initialAddress: _locationController.text,
          labelText: 'Where should we deliver the completed documents?',
          hintText: 'Enter your delivery address',
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
              return 'Delivery location is required';
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
          'Special Instructions (Optional)',
          style: theme.textTheme.titleMedium
              ?.copyWith(
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
            hintText: 'Any special requirements or notes...',
            hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isMobile ? 10 : 12)),
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
          _serviceOption == 'drop_off_only'
              ? 'Attach Documents *'
              : 'Attach Documents (Required for some services)',
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload documents to be printed or processed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        // PDF Files Section
        if (_pdfFiles.isNotEmpty) ...[
          Text(
            'PDF Files:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pdfFiles.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            Text(
                              'PDF ${index + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _pdfFiles.removeAt(index)),
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

        // Images Section
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
                onPressed: () => _pickPDF(),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  ' PDF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.photo_library),
                label: const Text(
                  'Gallery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Camera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        // Multiple files instruction
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'If you have multiple documents, please merge them into one file or choose "Pick up documents" service option.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isMobile, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 48 : 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: isMobile ? 20 : 24,
                height: isMobile ? 20 : 24,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isImmediateRequest
                    ? 'Request Now - N\$${_getServiceTypePrice().toStringAsFixed(2)} + Costs'
                    : 'Submit Request - N\$${_getServiceTypePrice().toStringAsFixed(2)} + Costs',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
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

  /// Get the actual price based on selected service type
  double _getServiceTypePrice() {
    // Service type specific prices
    final Map<String, double> individualPrices = {
      'application_submission': 200.0,  // Application submission service
      'certification': 150.0,  // Document certification
    };

    final Map<String, double> businessPrices = {
      'application_submission': 350.0,  // Application submission (business)
      'certification': 220.0,  // Document certification (business)
    };

    final isBusiness = widget.userProfile?['user_type'] == 'business';
    final prices = isBusiness ? businessPrices : individualPrices;

    return prices[_serviceType] ?? _getBasePrice();
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

  Future<void> _pickPDF() async {
    try {
      Uint8List? pdfBytes = await ImageUploadHelper.pickPDFFromFiles();
      if (pdfBytes != null) {
        setState(() => _pdfFiles.add(pdfBytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to add PDF. Please try again or select a different file.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate file uploads for drop-off only
    if (_serviceOption == 'drop_off_only' &&
        _images.isEmpty &&
        _pdfFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please upload at least one document (image or PDF) for drop-off service'),
          backgroundColor: Colors.orange,
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
          final imagePath = '$userId/document_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Upload PDFs
      List<String> pdfUrls = [];
      for (int i = 0; i < _pdfFiles.length; i++) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final pdfPath = '$userId/document_${timestamp}_pdf_$i.pdf';
          final pdfUrl = await SupabaseConfig.uploadImage(
              'errand-images', pdfPath, _pdfFiles[i]);
          pdfUrls.add(pdfUrl);
        } catch (e) {
          print('Error uploading PDF $i: $e');
        }
      }

      // Build scheduled time for non-immediate
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
      final serviceTypePrice = _getServiceTypePrice();
      final errandData = {
        'customer_id': userId,
        'title': 'Document Services',
        'description': _buildDescription(),
        'category': 'document_services',
        'price_amount': serviceTypePrice,
        'calculated_price': serviceTypePrice,
        'location_address': _serviceOption == 'collect_and_deliver'
            ? _locationController.text.trim()
            : null,
        'location_latitude':
            _serviceOption == 'collect_and_deliver' ? _locationLat : null,
        'location_longitude':
            _serviceOption == 'collect_and_deliver' ? _locationLng : null,
        'pickup_address': _serviceOption == 'collect_and_deliver' &&
                _pickupLocationController.text.trim().isNotEmpty
            ? _pickupLocationController.text.trim()
            : 'Drop-off only - No pickup required',
        'pickup_latitude':
            _serviceOption == 'collect_and_deliver' ? _pickupLat : null,
        'pickup_longitude':
            _serviceOption == 'collect_and_deliver' ? _pickupLng : null,
        'service_type': _serviceType,
        'special_instructions': _buildSpecialInstructions(),
        'image_urls': imageUrls,
        'pdf_urls': pdfUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time': scheduledStart?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'service_type_price': serviceTypePrice,
          'service_type': _serviceType,
          'user_type': widget.userProfile?['user_type'] ?? 'individual',
          'service_option': _serviceOption,
        },
      };

      if (_isImmediateRequest) {
        // For immediate requests, store in database with pending status
        print(
            '🚀 IMMEDIATE REQUEST: Storing errand in database with pending status');

        // Add customer information for display
        errandData['customer'] = {
          'full_name': widget.userProfile?['full_name'] ?? 'Unknown Customer',
          'phone': widget.userProfile?['phone'] ?? '',
        };

        // Add created_at timestamp for display
        errandData['created_at'] = DateTime.now().toIso8601String();

        final createdErrand =
            await ImmediateErrandService.storePendingErrand(errandData);
        print(
            '✅ IMMEDIATE REQUEST: Errand stored in database with pending status');

        if (mounted) {
          // Show "Looking for Runner" popup for immediate requests
          RunnerSearchService.instance.showLookingForRunnerPopup(
            context: context,
            errandId: createdErrand['id'],
            errandTitle: errandData['title'].toString(),
            onRetry: () {
              // Retry the immediate request
              _submitForm();
            },
            onCancel: () {
              // Cancel the request and remove from pending, but keep user in form
              ImmediateErrandService.removePendingErrand(createdErrand['id']);
              // Don't navigate away - keep user in the form
            },
            onRunnerFound: () {
              // Runner found, show success and go back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✅ Runner found! Your document service request has been accepted.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
          );
        }
      } else {
        // For scheduled requests, create errand immediately
        print('📅 SCHEDULED REQUEST: Creating errand in database immediately');
        await SupabaseConfig.createErrand(errandData);
        print('✅ SCHEDULED REQUEST: Errand created in database');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Document service request posted successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your document service request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a document service request.';
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

    // Pickup location
    if (_pickupLocationController.text.trim().isNotEmpty) {
      instructions.add('PICKUP LOCATION:');
      instructions.add(_pickupLocationController.text.trim());
      instructions.add('');
    }

    // Document description
    if (_documentDescriptionController.text.trim().isNotEmpty) {
      instructions.add('DOCUMENT DESCRIPTION:');
      instructions.add(_documentDescriptionController.text.trim());
      instructions.add('');
    }

    // Service option
    instructions.add(
        'Service Option: ${_serviceOption == 'collect_and_deliver' ? 'Collect & Deliver' : 'Drop-off Only'}');
    instructions.add('');

    // File attachments
    if (_images.isNotEmpty || _pdfFiles.isNotEmpty) {
      instructions.add('ATTACHED FILES:');
      if (_images.isNotEmpty) {
        instructions.add('Images: ${_images.length} file(s)');
      }
      if (_pdfFiles.isNotEmpty) {
        instructions.add('PDFs: ${_pdfFiles.length} file(s)');
      }
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
      'copies': 'Copies',
      'certify': 'Certify',
      'printing': 'Printing',
      'scanning': 'Scanning',
      'photocopying': 'Photocopying',
      'binding': 'Binding',
      'laminating': 'Laminating',
      'copies & certify': 'Copies & Certify',
      'other': 'Other',
    };

    final details = [
      'Document Services Request',
      'Service Type: ${serviceTypeNames[_serviceType]}',
    ];

    if (_pickupLocationController.text.trim().isNotEmpty) {
      details.add('Pickup from: ${_pickupLocationController.text.trim()}');
    }

    if (_serviceOption == 'collect_and_deliver' &&
        _locationController.text.trim().isNotEmpty) {
      details.add('Delivery to: ${_locationController.text.trim()}');
    }

    return details.join('\n');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _pickupLocationController.dispose();
    _documentDescriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
