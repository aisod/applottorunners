import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:lotto_runners/theme.dart';

/// Queue Sitting Service Form
/// Streamlined form for queue sitting services with essential fields
class QueueSittingFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const QueueSittingFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<QueueSittingFormPage> createState() => _QueueSittingFormPageState();
}

class _QueueSittingFormPageState extends State<QueueSittingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  DateTime? _arrivalTime;
  String _serviceType = 'scheduled'; // 'now' or 'scheduled'
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  double? _locationLat;
  double? _locationLng;
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
          'Queue Sitting Service',
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
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16.0 : 24.0,
                isMobile ? 0.0 : 16.0,
                isMobile ? 16.0 : 24.0,
                isMobile ? 16.0 : 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Transform.translate(
                offset: Offset(0, isMobile ? -8.0 : 0),
                child: _buildServiceHeader(theme, isMobile, isTablet),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              _buildLocationField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRequestNowToggle(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildArrivalTimeField(theme, isMobile, isTablet),
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
    final finalPrice = _calculateFinalPrice();

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
            'Price: N\$${finalPrice.toStringAsFixed(2)}',
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

  Widget _buildLocationField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Queue Location *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        SimpleLocationPicker(
          key: const ValueKey('queue_location'),
          initialAddress: _locationController.text,
          labelText: 'Queue Location',
          hintText: 'Enter location (e.g., Bank, Government Office, Shop)',
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
              return 'Queue location is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRequestNowToggle(ThemeData theme, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
              fontSize: isMobile ? 15 : isTablet ? 16 : 17,
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
                      _serviceType = 'scheduled';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12, 
                        horizontal: isMobile ? 12 : 16),
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
                        Text(
                          'Scheduled',
                          style: TextStyle(
                            color: !_isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 13 : isTablet ? 14 : 15,
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
                      _serviceType = 'now';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12, 
                        horizontal: isMobile ? 12 : 16),
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
                        Text(
                          'Request Now',
                          style: TextStyle(
                            color: _isImmediateRequest
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 13 : isTablet ? 14 : 15,
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

  Widget _buildArrivalTimeField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Arrival Time *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        GestureDetector(
          onTap: _selectDateTime,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _arrivalTime != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _arrivalTime != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    _arrivalTime == null
                        ? 'When will you arrive?'
                        : DateFormat('EEE, MMM d, yyyy • HH:mm')
                            .format(_arrivalTime!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _arrivalTime == null
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                      fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: isMobile ? 20 : 24),
              ],
            ),
          ),
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
            hintText: 'Any specific instructions for the queue sitter...',
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
          'Attach Images (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
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
                icon: Icon(Icons.photo_library, size: isMobile ? 18 : 20),
                label: Text('Gallery', style: TextStyle(fontSize: isMobile ? 13 : 15)),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: Icon(Icons.camera_alt, size: isMobile ? 18 : 20),
                label: Text('Camera', style: TextStyle(fontSize: isMobile ? 13 : 15)),
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
      height: isMobile ? 46 : 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: Icon(
          _isImmediateRequest ? Icons.flash_on : Icons.check,
          color: theme.colorScheme.onPrimary,
          size: isMobile ? 18 : 20,
        ),
        label: Text(
          _isImmediateRequest
              ? 'Request Service Now - N\$${_calculateFinalPrice().toStringAsFixed(2)}'
              : 'Submit Request - N\$${_calculateFinalPrice().toStringAsFixed(2)}',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: isMobile ? 14 : isTablet ? 15 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
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
    double price = _getBasePrice();
    if (_serviceType == 'now') price += 30.0;
    return price;
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _arrivalTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _arrivalTime != null
            ? TimeOfDay.fromDateTime(_arrivalTime!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _arrivalTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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

    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide the queue location')),
      );
      return;
    }

    if (_arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your arrival time')),
      );
      return;
    }

    if (_arrivalTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival time must be in the future')),
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
          final imagePath = '$userId/queue_sitting_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Create errand
      final finalPrice = _calculateFinalPrice();
      final errandData = {
        'customer_id': userId,
        'title': 'Queue Sitting Service',
        'description': _buildDescription(),
        'category': 'queue_sitting',
        'price_amount': finalPrice,
        'calculated_price': finalPrice,
        'location_address': _locationController.text.trim(),
        'location_latitude': _locationLat,
        'location_longitude': _locationLng,
        'queue_type': _serviceType,
        'service_type': _serviceType, // Store queue type as service_type for consistency
        'customer_arrival_time': _arrivalTime?.toIso8601String(),
        'special_instructions': _instructionsController.text.trim(),
        'image_urls': imageUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'service_type': _serviceType,
          'service_type_price': finalPrice,
          'queue_type_surcharge': _serviceType == 'now' ? 30.0 : 0.0,
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
                      '✅ Runner found! Your queue sitting request has been accepted.'),
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
                content: Text('Queue sitting request posted successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your queue sitting request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a queue sitting request.';
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
      'Queue Sitting Service Request',
      'Service Type: ${_serviceType == 'now' ? 'Rush Service (+N\$30)' : 'Scheduled Service'}',
      'Location: ${_locationController.text.trim()}',
      'Customer Arrival: ${DateFormat('EEE, MMM d, yyyy • HH:mm').format(_arrivalTime!)}',
    ];

    if (_instructionsController.text.trim().isNotEmpty) {
      details.add('Instructions: ${_instructionsController.text.trim()}');
    }

    return details.join('\n');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
