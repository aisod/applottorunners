import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/widgets/simple_location_picker.dart';
import 'package:lotto_runners/services/runner_search_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:lotto_runners/theme.dart';

/// Enhanced Shopping Service Form
/// Supports multiple stores and location type selection
class EnhancedShoppingFormPage extends StatefulWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const EnhancedShoppingFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  State<EnhancedShoppingFormPage> createState() =>
      _EnhancedShoppingFormPageState();
}

class _EnhancedShoppingFormPageState extends State<EnhancedShoppingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryLocationController = TextEditingController();
  final _shoppingListController = TextEditingController();
  final _budgetController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form state
  String _shoppingType = 'groceries';
  final bool _needsDelivery = true; // Delivery is always required
  bool _needsVehicle = false; // Does this request need a vehicle?
  String? _vehicleType; // required when _needsVehicle is true
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoadingVehicleTypes = false;
  bool _isLoading = false;
  bool _isImmediateRequest = false; // For immediate errand requests
  DateTime? _scheduledDate; // Selected date when scheduled
  TimeOfDay? _scheduledTime; // Selected time when scheduled
  double? _deliveryLat;
  double? _deliveryLng;
  final List<Uint8List> _images = [];

  // Multiple stores support
  final List<StoreLocation> _stores = [];

  @override
  void initState() {
    super.initState();
    // Add initial store
    _addStore();
    _loadVehicleTypes();
    // Initialize vehicle requirement based on delivery need
    _needsVehicle = _needsDelivery;
  }

  void _addStore() {
    setState(() {
      _stores.add(StoreLocation());
    });
  }

  void _removeStore(int index) {
    if (_stores.length > 1) {
      setState(() {
        _stores.removeAt(index);
      });
    }
  }

  void _updateStore(int index, StoreLocation store) {
    setState(() {
      _stores[index] = store;
    });
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
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Service',
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
              _buildServiceHeader(theme, isMobile),
              SizedBox(height: isMobile ? 20 : 24),
              _buildShoppingTypeField(theme, isMobile),
              SizedBox(height: isMobile ? 20 : 24),
              _buildStoresSection(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 10 : 12),
              _buildShoppingListField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildBudgetField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildRequestNowToggle(theme, isMobile),
              if (!_isImmediateRequest) ...[
                SizedBox(height: isMobile ? 12 : 16),
                _buildScheduledDateTimeFields(theme, isMobile),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              _buildDeliveryLocationField(theme, isMobile),
              SizedBox(height: isMobile ? 20 : 24),
              _buildVehicleRequirementQuestion(theme, isMobile),
              if (_needsVehicle) ...[
                SizedBox(height: isMobile ? 12 : 16),
                _buildVehicleTypeField(theme, isMobile),
              ],
              SizedBox(height: isMobile ? 20 : 24),
              _buildInstructionsField(theme, isMobile, isTablet),
              SizedBox(height: isMobile ? 20 : 24),
              _buildImageSection(theme, isMobile),
              SizedBox(height: isMobile ? 28 : 32),
              _buildSubmitButton(theme, isMobile),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader(ThemeData theme, bool isMobile) {
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
              fontSize: isMobile ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTypeField(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopping Type *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          value: _shoppingType,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 20 : 24),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(
                value: 'groceries', child: Text('Groceries & Food')),
            DropdownMenuItem(
                value: 'pharmacy', child: Text('Pharmacy & Health')),
            DropdownMenuItem(value: 'general', child: Text('General Shopping')),
          
          ],
          onChanged: (value) => setState(() => _shoppingType = value!),
        ),
      ],
    );
  }

  Widget _buildStoresSection(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Store Locations *',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 16 : isTablet ? 17 : 18,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addStore,
              icon: const Icon(Icons.add),
              label: const Text('Add Store'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_stores.asMap().entries.map((entry) {
          final index = entry.key;
          final store = entry.value;
          return _buildStoreField(theme, index, store, isMobile, isTablet);
        })),
      ],
    );
  }

  Widget _buildStoreField(ThemeData theme, int index, StoreLocation store, bool isMobile, bool isTablet) {
    final textSize = isMobile ? 14.0 : isTablet ? 15.0 : 16.0;
    final subtitleSize = isMobile ? 12.0 : isTablet ? 13.0 : 14.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 18 : 20,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Store ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontSize: textSize,
                ),
              ),
              const Spacer(),
              if (_stores.length > 1)
                IconButton(
                  onPressed: () => _removeStore(index),
                  icon: Icon(Icons.remove_circle_outline, size: isMobile ? 20 : 24),
                  color: theme.colorScheme.error,
                  tooltip: 'Remove Store',
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Location type selection
          Column(
            children: [
              RadioListTile<String>(
                title: Text('Store Name', style: TextStyle(fontSize: textSize)),
                subtitle: Text('Just enter store name', style: TextStyle(fontSize: subtitleSize)),
                value: 'name',
                groupValue: store.locationType,
                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                onChanged: (value) {
                  final updatedStore = store.copyWith(locationType: value!);
                  _updateStore(index, updatedStore);
                },
              ),
              RadioListTile<String>(
                title: Text('Map Location', style: TextStyle(fontSize: textSize)),
                subtitle: Text('Select exact location', style: TextStyle(fontSize: subtitleSize)),
                value: 'map',
                groupValue: store.locationType,
                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                onChanged: (value) {
                  final updatedStore = store.copyWith(locationType: value!);
                  _updateStore(index, updatedStore);
                },
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Location input based on type
          if (store.locationType == 'name')
            _buildStoreNameField(theme, index, store, isMobile, isTablet)
          else
            _buildStoreMapField(theme, index, store),
        ],
      ),
    );
  }

  Widget _buildStoreNameField(ThemeData theme, int index, StoreLocation store, bool isMobile, bool isTablet) {
    return TextFormField(
      initialValue: store.name,
      style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
      decoration: InputDecoration(
        labelText: 'Store Name *',
        labelStyle: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
        hintText: 'e.g., Shoprite, Spar, Pharmacy, etc.',
        hintStyle: TextStyle(fontSize: isMobile ? 13 : isTablet ? 14 : 15),
        prefixIcon: Icon(Icons.store, 
            color: LottoRunnersColors.primaryYellow,
            size: isMobile ? 20 : 24),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
      ),
      onChanged: (value) {
        final updatedStore = store.copyWith(name: value);
        _updateStore(index, updatedStore);
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Store name is required';
        }
        return null;
      },
    );
  }

  Widget _buildStoreMapField(ThemeData theme, int index, StoreLocation store) {
    return SimpleLocationPicker(
      initialAddress: store.address,
      labelText: 'Store Location *',
      hintText: 'Where should we shop?',
      prefixIcon: Icons.store,
      iconColor: LottoRunnersColors.primaryYellow,
      onLocationSelected: (address, lat, lng) {
        final updatedStore = store.copyWith(
          address: address,
          latitude: lat,
          longitude: lng,
        );
        _updateStore(index, updatedStore);
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Store location is required';
        }
        return null;
      },
    );
  }

  Widget _buildShoppingListField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopping List *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _shoppingListController,
          maxLines: 6,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'List all items you need:\n\n• Milk - 2L\n• Bread - 1 loaf\n• Apples - 1kg\n• etc...',
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
              return 'Shopping list is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBudgetField(ThemeData theme, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : isTablet ? 17 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.attach_money,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 20 : 24),
            hintText: 'e.g., 5000',
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

  Widget _buildRequestNowToggle(ThemeData theme, bool isMobile) {
    // Match EnhancedPostErrand toggle style (two pill buttons)
    return Container(
      padding: const EdgeInsets.all(16),
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
                            fontSize: isMobile ? 13 : 15,
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
                            fontSize: isMobile ? 13 : 15,
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

  Widget _buildScheduledDateTimeFields(ThemeData theme, bool isMobile) {
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
              hintText: 'Tap to choose date',
              prefixIcon: const Icon(Icons.calendar_today,
                  color: LottoRunnersColors.primaryYellow),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _scheduledDate == null
                    ? 'Tap to choose date'
                    : DateFormat('EEE, MMM d, yyyy').format(_scheduledDate!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
              setState(() => _scheduledTime = pickedTime);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Time',
              hintText: 'Tap to choose time',
              prefixIcon: const Icon(Icons.access_time,
                  color: LottoRunnersColors.primaryYellow),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _scheduledTime == null
                    ? 'Tap to choose time'
                    : _scheduledTime!.format(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRequirementQuestion(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Does this request require a vehicle? *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
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

  Widget _buildVehicleTypeField(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _needsVehicle ? 'Vehicle Type *' : 'Vehicle Type (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        DropdownButtonFormField<String>(
          value: _vehicleTypes.any((t) => t['name'] == _vehicleType)
              ? _vehicleType
              : null,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: _isLoadingVehicleTypes
                ? 'Loading vehicle types...'
                : _needsVehicle
                    ? 'Select vehicle type'
                    : 'Select vehicle type (optional)',
            prefixIcon: Icon(Icons.directions_car,
                color: LottoRunnersColors.primaryYellow,
                size: isMobile ? 20 : 24),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _vehicleTypes.map((t) {
            final name = (t['name'] ?? '').toString();
            return DropdownMenuItem<String>(
              value: name,
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: isMobile ? 16 : 18),
                  SizedBox(width: isMobile ? 6 : 8),
                  Text(name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _vehicleType = value),
          validator: (value) {
            if (_needsVehicle && (value == null || value.isEmpty)) {
              return 'Please select a vehicle type';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryLocationField(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SimpleLocationPicker(
          key: const ValueKey('delivery_location'),
          initialAddress: _deliveryLocationController.text,
          labelText: 'Delivery Location *',
          hintText: 'Enter your address or preferred delivery location',
          prefixIcon: Icons.home,
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
        SizedBox(height: isMobile ? 8 : 10),
        TextFormField(
          controller: _instructionsController,
          maxLines: 3,
          style: TextStyle(fontSize: isMobile ? 14 : isTablet ? 15 : 16),
          decoration: InputDecoration(
            hintText: 'Brand preferences, substitutions, delivery notes...',
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

  Widget _buildImageSection(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reference Images (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        const SizedBox(height: 8),
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
                          onTap: () {
                            setState(() => _images.removeAt(index));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
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
                    ? 'Request Now - N\$${_getBasePrice().toStringAsFixed(2)} + Shopping'
                    : 'Submit Request - N\$${_getBasePrice().toStringAsFixed(2)} + Shopping',
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
          final imagePath = '$userId/shopping_${timestamp}_$i.jpg';
          final imageUrl = await SupabaseConfig.uploadImage(
              'errand-images', imagePath, _images[i]);
          imageUrls.add(imageUrl);
        } catch (e) {
          print('Error uploading image $i: $e');
        }
      }

      // Create errand
      DateTime? scheduledStart;
      if (!_isImmediateRequest) {
        if (_scheduledDate == null || _scheduledTime == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a date and time')),
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
        'title': 'Shopping Service',
        'description': _buildDescription(),
        'category': 'shopping',
        'price_amount': _getBasePrice(),
        'calculated_price': _getBasePrice(),
        'location_address': _buildStoresDescription(),
        'location_latitude': _stores.isNotEmpty ? _stores.first.latitude : null,
        'location_longitude':
            _stores.isNotEmpty ? _stores.first.longitude : null,
        'delivery_address': _deliveryLocationController.text.trim(),
        'delivery_latitude': _deliveryLat,
        'delivery_longitude': _deliveryLng,
        'vehicle_type': _needsVehicle ? _vehicleType : null,
        'service_type': _shoppingType, // Store shopping type as service_type for consistency
        'special_instructions': _instructionsController.text.trim(),
        'image_urls': imageUrls,
        'status': 'posted',
        'is_immediate': _isImmediateRequest,
        'scheduled_start_time': scheduledStart?.toIso8601String(),
        'pricing_modifiers': {
          'base_price': _getBasePrice(),
          'service_type': _shoppingType,
          'service_type_price': _getBasePrice(),
          'user_type': widget.userProfile?['user_type'] ?? 'individual',
          'shopping_type': _shoppingType,
          'shopping_list': _shoppingListController.text.trim(),
          'shopping_budget': _budgetController.text.isNotEmpty
              ? double.parse(_budgetController.text)
              : null,
        },
        'stores': _stores.map((store) => store.toMap()).toList(),
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
                      '✅ Runner found! Your shopping request has been accepted.'),
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
                content: Text('Shopping request posted successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to post your shopping request. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('not authenticated') || e.toString().contains('sign in')) {
          errorMessage = 'Please sign in to post a shopping request.';
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
    final shoppingTypeNames = {
      'groceries': 'Groceries & Food',
      'pharmacy': 'Pharmacy & Health',
      'general': 'General Shopping',
      'specific_items': 'Specific Items',
    };

    final details = [
      'Shopping Service Request',
      'Type: ${shoppingTypeNames[_shoppingType]}',
      'Stores: ${_buildStoresDescription()}',
      if (_budgetController.text.isNotEmpty)
        'Budget: N\$${_budgetController.text}',
      'Delivery: Yes',
      'Vehicle Required: ${_needsVehicle ? 'Yes' : 'No'}',
      'Delivery to: ${_deliveryLocationController.text.trim()}',
    ];

    if (_needsVehicle && _vehicleType != null) {
      details.add('Vehicle Type: $_vehicleType');
    }

    details.add('\nShopping List:\n${_shoppingListController.text.trim()}');

    if (_instructionsController.text.trim().isNotEmpty) {
      details.add('\nInstructions: ${_instructionsController.text.trim()}');
    }

    return details.join('\n');
  }

  String _buildStoresDescription() {
    return _stores.map((store) {
      if (store.locationType == 'name') {
        return store.name ?? 'Unnamed Store';
      } else {
        return store.address ?? 'Unknown Location';
      }
    }).join(', ');
  }

  @override
  void dispose() {
    _deliveryLocationController.dispose();
    _shoppingListController.dispose();
    _budgetController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

/// Model class for store locations
class StoreLocation {
  final String locationType; // 'name' or 'map'
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;

  StoreLocation({
    this.locationType = 'name',
    this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  StoreLocation copyWith({
    String? locationType,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return StoreLocation(
      locationType: locationType ?? this.locationType,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationType': locationType,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory StoreLocation.fromMap(Map<String, dynamic> map) {
    return StoreLocation(
      locationType: map['locationType'] ?? 'name',
      name: map['name'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }
}

// Shimmer animation widget for cards
class _AnimatedShimmerCard extends StatefulWidget {
  final Widget child;
  final ThemeData theme;

  const _AnimatedShimmerCard({
    required this.child,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Content
            widget.child,
            // Shimmer effect overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
          ],
        );
      },
      child: widget.child,
    );
  }
}
