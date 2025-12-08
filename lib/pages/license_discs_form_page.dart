import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'dart:typed_data';

/// License Discs Service Form
/// Enhanced form for license disc renewals and applications with PDF support
class LicenseDiscsFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const LicenseDiscsFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<LicenseDiscsFormPage> createState() => _LicenseDiscsFormPageState();
}

class _LicenseDiscsFormPageState extends State<LicenseDiscsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String _serviceType = 'renewal'; // 'renewal' (N$250), 'registration' (N$1500)
  String _serviceOption =
      'collect_and_deliver'; // 'collect_and_deliver', 'drop_off_only'
  bool _isLoading = false;
  // Request type removed; license discs default to immediate processing
  DateTime? _preferredDate; // User-selected preferred processing date
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
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
          'License Disc Service',
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
              _buildServiceOptionField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildPreferredDateField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildLocationFields(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildInstructionsField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildDocumentSection(theme, isMobile, isTablet),
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
                  'Vehicle Disc Renewal',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'N\$250',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                value: 'renewal',
                groupValue: _serviceType,
                onChanged: (value) => setState(() => _serviceType = value!),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 4 : 8,
                ),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: Text(
                  'Vehicle Registration',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'N\$1500',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                value: 'registration',
                groupValue: _serviceType,
                onChanged: (value) => setState(() => _serviceType = value!),
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

  Widget _buildServiceOptionField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Option *',
          style: theme.textTheme.titleMedium?.copyWith(
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
                  'We collect documents and deliver completed disc',
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
                  'You drop off documents, we deliver completed disc',
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

  // Request Type removed

  // Scheduled datetime removed

  Widget _buildPreferredDateField(ThemeData theme, bool isMobile, bool isTablet) {
    return GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _preferredDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              helpText: 'Select preferred date',
            );
            if (pickedDate != null) {
              setState(() => _preferredDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                  ));
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Preferred Date',
              hintText: 'Tap to choose a date',
              prefixIcon: const Icon(Icons.calendar_today),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
              child: Text(
                _preferredDate == null
                    ? 'Tap to choose date'
                    : '${_preferredDate!.year}-${_preferredDate!.month.toString().padLeft(2, '0')}-${_preferredDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
    );
  }

  Widget _buildLocationFields(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_serviceOption == 'collect_and_deliver') ...[
          SimpleLocationPicker(
            key: const ValueKey('pickup_location'),
            initialAddress: _pickupLocationController.text,
            labelText: 'Pickup Location',
            hintText: 'Enter your address or preferred pickup location',
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
              // Pickup is optional
              return null;
            },
          ),
          SizedBox(height: isMobile ? 20 : 24),
        ],
        SimpleLocationPicker(
          key: const ValueKey('delivery_location'),
          initialAddress: _dropoffLocationController.text,
          labelText: 'Delivery Location *',
          hintText: 'Enter where we should deliver the completed disc',
          prefixIcon: Icons.local_shipping,
          iconColor: LottoRunnersColors.primaryYellow,
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _dropoffLocationController.text = address;
              _dropoffLat = lat;
              _dropoffLng = lng;
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
    return TextFormField(
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
    );
  }

  Widget _buildDocumentSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _serviceOption == 'drop_off_only'
              ? 'Attach Documents *'
              : 'Attach Documents',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          'Please attach copies of documents (ID, previous disc, etc.) - All documents are optional',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // PDF Files Section
        if (_pdfFiles.isNotEmpty) ...[
          Text(
            'PDF Files:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
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
          SizedBox(height: isMobile ? 12 : 16),
        ],

        // Images Section
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
          SizedBox(height: isMobile ? 12 : 16),
        ],

        // Upload Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  ' PDF',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.photo_library),
                label: const Text(
                  'Gallery',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Camera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

        // Show uploaded files count
        if (_images.isNotEmpty || _pdfFiles.isNotEmpty) ...[
          SizedBox(height: isMobile ? 12 : 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Documents ready: ${_images.length} image(s), ${_pdfFiles.length} PDF(s)',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_images.isNotEmpty || _pdfFiles.isNotEmpty)
                  IconButton(
                    onPressed: _clearAllFiles,
                    icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                    tooltip: 'Clear all files',
                  ),
              ],
            ),
          ),
        ],
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
          Icons.check, 
          color: theme.colorScheme.onPrimary, 
          size: isMobile ? 18 : 20
        ),
        label: Text(
          'Submit Request - N\$${_getServiceTypePrice().toStringAsFixed(2)}',
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

  /// Get the actual price based on selected service type
  double _getServiceTypePrice() {
    // Service type specific prices
    final Map<String, double> individualPrices = {
      'renewal': 250.0,  // License disc renewal
      'registration': 1500.0,  // Vehicle registration
    };

    final Map<String, double> businessPrices = {
      'renewal': 350.0,  // License disc renewal (business)
      'registration': 1900.0,  // Vehicle registration (business)
    };

    final isBusiness = widget.userProfile?['user_type'] == 'business';
    final prices = isBusiness ? businessPrices : individualPrices;

    return prices[_serviceType] ?? _getBasePrice();
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

  void _clearAllFiles() {
    setState(() {
      _images.clear();
      _pdfFiles.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All files cleared'),
        backgroundColor: Colors.orange,
      ),
    );
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
          final imagePath = '$userId/license_disc_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
          print('✅ Image $i uploaded successfully');
        } catch (e) {
          print('❌ Error uploading image $i: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to upload image ${i + 1}. Please check your internet connection and try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          throw Exception('Unable to upload image ${i + 1}');
        }
      }

      // Upload PDFs
      List<String> pdfUrls = [];
      for (int i = 0; i < _pdfFiles.length; i++) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final pdfPath = '$userId/license_disc_${timestamp}_pdf_$i.pdf';
          final pdfUrl = await SupabaseConfig.uploadImage(
              'errand-images', pdfPath, _pdfFiles[i]);
          pdfUrls.add(pdfUrl);
          print('✅ PDF $i uploaded successfully');
        } catch (e) {
          print('❌ Error uploading PDF $i: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to upload PDF ${i + 1}. Please check your internet connection and try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          throw Exception('Unable to upload PDF ${i + 1}');
        }
      }

      // Create errand
      final serviceTypePrice = _getServiceTypePrice();
      final errandData = {
        'customer_id': userId,
        'title': 'License Disc Service',
        'description': _buildDescription(),
        'category': 'license_discs',
        'price_amount': serviceTypePrice,
        'calculated_price': serviceTypePrice,
        'location_address': _serviceOption == 'collect_and_deliver'
            ? _pickupLocationController.text.trim()
            : _dropoffLocationController.text.trim(),
        'location_latitude':
            _serviceOption == 'collect_and_deliver' ? _pickupLat : _dropoffLat,
        'location_longitude':
            _serviceOption == 'collect_and_deliver' ? _pickupLng : _dropoffLng,
        'delivery_address': _dropoffLocationController.text.trim(),
        'delivery_latitude': _dropoffLat,
        'delivery_longitude': _dropoffLng,
        'service_type': _serviceType,
        'special_instructions': _instructionsController.text.trim(),
        'image_urls': imageUrls,
        'pdf_urls': pdfUrls,
        'status': 'posted',
        'is_immediate': false,
        'scheduled_start_time': _preferredDate?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'service_type_price': serviceTypePrice,
          'service_type': _serviceType,
          'user_type': widget.userProfile?['user_type'] ?? 'individual',
          'service_option': _serviceOption,
        },
      };

      await SupabaseConfig.createErrand(errandData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('License disc request posted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your license disc request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a license disc request.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('validation') || e.toString().contains('constraint')) {
          errorMessage = 'Please check that all required fields are filled correctly.';
        } else if (e.toString().contains('upload')) {
          errorMessage = 'Unable to upload files. Please check your internet connection and try again.';
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
    final serviceTypeNames = {
      'renewal': 'License Disc Renewal',
      'new_application': 'New License Disc Application',
      'duplicate': 'Duplicate License Disc',
    };

    final serviceOptionNames = {
      'collect_and_deliver': 'Collect & Deliver',
      'drop_off_only': 'Drop-off Only',
    };

    final details = [
      'License Disc Service Request',
      'Service Type: ${serviceTypeNames[_serviceType]}',
      'Service Option: ${serviceOptionNames[_serviceOption]}',
    ];

    if (_serviceOption == 'collect_and_deliver') {
      details.add('Pickup Location: ${_pickupLocationController.text.trim()}');
    }
    details.add('Delivery Location: ${_dropoffLocationController.text.trim()}');

    if (_instructionsController.text.trim().isNotEmpty) {
      details.add('Instructions: ${_instructionsController.text.trim()}');
    }

    details
        .add('Documents: ${_images.length} images, ${_pdfFiles.length} PDFs');

    return details.join('\n');
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
