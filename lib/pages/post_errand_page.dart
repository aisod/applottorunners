import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'dart:typed_data';

class PostErrandPage extends StatefulWidget {
  const PostErrandPage({super.key});

  @override
  State<PostErrandPage> createState() => _PostErrandPageState();
}

class _PostErrandPageState extends State<PostErrandPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();

  String _selectedCategory = 'grocery';
  bool _requiresVehicle = false;
  bool _isLoading = false;
  List<Uint8List> _selectedImages = [];

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'grocery',
      'label': 'Grocery Shopping',
      'icon': Icons.shopping_cart
    },
    {'value': 'delivery', 'label': 'Delivery', 'icon': Icons.local_shipping},
    {
      'value': 'document',
      'label': 'Document Handling',
      'icon': Icons.description
    },
    {'value': 'shopping', 'label': 'Shopping', 'icon': Icons.shopping_bag},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post New Errand',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicInfo(theme),
              const SizedBox(height: 24),
              _buildCategorySelection(theme),
              const SizedBox(height: 24),
              _buildLocationInfo(theme),
              const SizedBox(height: 24),
              _buildPricingAndTime(theme),
              const SizedBox(height: 24),
              _buildImageSection(theme),
              const SizedBox(height: 24),
              _buildAdditionalOptions(theme),
              const SizedBox(height: 32),
              _buildSubmitButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Errand Title',
            hintText: 'e.g., Grocery shopping at Walmart',
            prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Provide detailed instructions about what you need...',
            prefixIcon:
                Icon(Icons.description, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['value'];
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['label'],
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category['value']);
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
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
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Your Location',
            hintText: 'Your address or meeting point',
            prefixIcon:
                Icon(Icons.location_on, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pickupController,
          decoration: InputDecoration(
            labelText: 'Pickup Location (Optional)',
            hintText: 'Where to pick up items',
            prefixIcon: Icon(Icons.store, color: theme.colorScheme.secondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.secondary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _deliveryController,
          decoration: InputDecoration(
            labelText: 'Delivery Location (Optional)',
            hintText: 'Where to deliver items',
            prefixIcon:
                Icon(Icons.local_shipping, color: theme.colorScheme.tertiary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.tertiary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingAndTime(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing & Timeline',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (N\$)',
                  hintText: '25.00',
                  prefixIcon: Icon(Icons.attach_money,
                      color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Time Limit (hours)',
                  hintText: '3',
                  prefixIcon:
                      Icon(Icons.timer, color: theme.colorScheme.secondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.secondary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Time limit required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Enter valid hours';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
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
                icon:
                    Icon(Icons.photo_library, color: theme.colorScheme.primary),
                label: Text(
                  'Gallery',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(true),
                icon:
                    Icon(Icons.camera_alt, color: theme.colorScheme.secondary),
                label: Text(
                  'Camera',
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.secondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Options',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_car, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requires Vehicle',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _requiresVehicle,
                onChanged: (value) => setState(() => _requiresVehicle = value),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Special Instructions (Optional)',
            hintText: 'Any additional notes for the runner...',
            prefixIcon: Icon(Icons.note, color: theme.colorScheme.tertiary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.tertiary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitErrand,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
              ),
            )
          : Text(
              'Post Errand',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _pickImage(bool fromCamera) async {
    final imageBytes = fromCamera
        ? await ImageUploadHelper.captureImage()
        : await ImageUploadHelper.pickImageFromGallery();

    if (imageBytes != null) {
      setState(() {
        _selectedImages.add(imageBytes);
      });
    }
  }

  Future<void> _submitErrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Upload images if any
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final imagePath =
            '$userId/errand_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final imageUrl = await SupabaseConfig.uploadImage(
          'errand-images',
          imagePath,
          _selectedImages[i],
        );
        imageUrls.add(imageUrl);
      }

      // Create errand data
      final errandData = {
        'customer_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'price_amount': double.parse(_priceController.text),
        'time_limit_hours': int.parse(_timeController.text),
        'location_address': _locationController.text.trim(),
        'pickup_address': _pickupController.text.trim().isEmpty
            ? null
            : _pickupController.text.trim(),
        'delivery_address': _deliveryController.text.trim().isEmpty
            ? null
            : _deliveryController.text.trim(),
        'special_instructions': _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        'requires_vehicle': _requiresVehicle,
        'image_urls': imageUrls,
        'status': 'posted',
      };

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting errand: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _instructionsController.dispose();
    _priceController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
