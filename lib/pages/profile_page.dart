import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/widgets/document_upload_widget.dart';
import 'package:lotto_runners/pages/terms_conditions_runner_page.dart';
import 'package:lotto_runners/pages/terms_conditions_individual_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _runnerApplication;
  bool _isLoading = true;
  bool _isSubmittingApplication = false;
  bool _isUploadingImage = false;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleDetailsController = TextEditingController();
  final _licenseController = TextEditingController();

  String? _selectedVehicleType;

  // Document upload state
  String? _driverLicensePdf;
  String? _codeOfConductPdf;
  List<String> _vehiclePhotos = [];
  List<String> _licenseDiscPhotos = [];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'Sedan',
      'name': 'Sedan',
      'icon': Icons.directions_car,
      'description': 'Comfortable sedan for city travel',
    },
    {
      'id': 'SUV',
      'name': 'SUV',
      'icon': Icons.directions_car_filled,
      'description': 'Spacious SUV for group travel',
    },
    {
      'id': 'Minibus',
      'name': 'Minibus',
      'icon': Icons.airport_shuttle,
      'description': 'Minibus for larger groups',
    },
    {
      'id': 'Motorcycle',
      'name': 'Motorcycle',
      'icon': Icons.motorcycle,
      'description': 'Fast motorcycle for single passenger',
    },
    {
      'id': 'Bicycle',
      'name': 'Bicycle',
      'icon': Icons.pedal_bike,
      'description': 'Eco-friendly bicycle option',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getUserProfile(userId);
        final application = await SupabaseConfig.getRunnerApplication(userId);

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _runnerApplication = application;
            _isLoading = false;

            // Populate controllers
            _fullNameController.text = profile?['full_name'] ?? '';
            _phoneController.text = profile?['phone'] ?? '';
            _selectedVehicleType = application?['vehicle_type'];

            // Populate document fields (will be null until migration is run)
            _driverLicensePdf = application?['driver_license_pdf'];
            _codeOfConductPdf = application?['code_of_conduct_pdf'];
            _vehiclePhotos = application?['vehicle_photos'] != null
                ? List<String>.from(application?['vehicle_photos'])
                : [];
            _licenseDiscPhotos = application?['license_disc_photos'] != null
                ? List<String>.from(application?['license_disc_photos'])
                : [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.isSmallMobile(context) ? 18 : 20,
          ),
        ),
        centerTitle: true,
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
        actions: [
          IconButton(
            onPressed: _showSignOutDialog,
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 32),
            _buildProfileForm(theme),
            const SizedBox(height: 32),
            if (_userProfile?['user_type'] == 'runner') ...[
              _buildRunnerSection(theme),
              const SizedBox(height: 32),
            ],
            _buildAccountActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final userType = _userProfile?['user_type'] ?? '';
    final isVerified = _userProfile?['is_verified'] == true;
    final avatarUrl = _userProfile?['avatar_url'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LottoRunnersColors.primaryBlue,
            LottoRunnersColors.primaryBlueDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(
                        _getUserTypeIcon(userType),
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: LottoRunnersColors.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingImage
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?['full_name'] ?? 'User Name',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.isSmallMobile(context) ? 18 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${userType.toUpperCase()} ${isVerified ? '• Verified' : '• Pending'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.isSmallMobile(context) ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outlined,
                color: LottoRunnersColors.primaryYellow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined,
                color: LottoRunnersColors.primaryYellow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Update Profile',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunnerSection(ThemeData theme) {
    final hasApplication = _runnerApplication != null;
    // Check both application status and user verification status
    final applicationStatus =
        _runnerApplication?['verification_status'] ?? 'pending';
    final isUserVerified = _userProfile?['is_verified'] == true;

    // Use the most current verification status
    final currentStatus = isUserVerified ? 'approved' : applicationStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Runner Verification',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
          ),
        ),
        const SizedBox(height: 16),
        if (hasApplication) ...[
          _buildApplicationStatus(theme, currentStatus),
        ] else ...[
          _buildApplicationForm(theme),
        ],
      ],
    );
  }

  Widget _buildApplicationStatus(ThemeData theme, String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Theme.of(context).colorScheme.tertiary;
        statusIcon = Icons.pending;
        statusText = 'Under Review';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Application $statusText',
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status == 'approved'
                ? 'You are now a verified runner!'
                : status == 'rejected'
                    ? 'Your application was not approved. Contact support for details.'
                    : 'Your runner application is being reviewed. This usually takes 1-2 business days.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_runnerApplication?['has_vehicle'] == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car,
                      color: LottoRunnersColors.primaryYellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle: ${_runnerApplication?['vehicle_type'] ?? 'Not specified'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: LottoRunnersColors.primaryYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: LottoRunnersColors.primaryYellow, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No vehicle registered',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      'You can accept errands that don\'t require transportation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LottoRunnersColors.primaryYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Add update application button for approved runners
          if (status == 'approved') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showUpdateApplicationDialog,
                icon: Icon(Icons.edit, size: 18),
                label: const Text('Update Application'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LottoRunnersColors.primaryBlue,
                  side: const BorderSide(color: LottoRunnersColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply for Runner Verification',
            style: theme.textTheme.titleMedium?.copyWith(
              color: LottoRunnersColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get verified to start accepting errands and earn money as a trusted runner.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'You can apply with or without a vehicle.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Vehicle option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car,
                    color: LottoRunnersColors.primaryYellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Do you have a vehicle?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Having a vehicle allows you to accept transportation bookings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _userProfile?['has_vehicle'] == true,
                  onChanged: (value) {
                    setState(() {
                      _userProfile?['has_vehicle'] = value;
                      // Clear vehicle fields when toggling off
                      if (!value) {
                        _selectedVehicleType = null;
                        _vehicleDetailsController.clear();
                        _licenseController.clear();
                      }
                    });
                  },
                  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.secondary;
                    }
                    return Theme.of(context).colorScheme.onSurface.withOpacity(0.54);
                  }),
                ),
              ],
            ),
          ),

          if (_userProfile?['has_vehicle'] == true) ...[
            const SizedBox(height: 16),
            // Vehicle Type Selection
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type *',
                prefixIcon: Icon(Icons.directions_car,
                    color: LottoRunnersColors.primaryYellow),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: LottoRunnersColors.primaryYellow, width: 2),
                ),
              ),
              items: _vehicleTypes.map((vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle['id'],
                  child: Row(
                    children: [
                      Icon(vehicle['icon'], size: 20),
                      const SizedBox(width: 12),
                      Text(vehicle['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value;
                });
              },
              validator: (value) {
                if (_userProfile?['has_vehicle'] == true &&
                    (value == null || value.isEmpty)) {
                  return 'Please select a vehicle type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehicleDetailsController,
              decoration: InputDecoration(
                labelText: 'Vehicle Details *',
                hintText: 'e.g., 2020 Honda Civic, Blue',
                prefixIcon: Icon(Icons.car_rental,
                    color: LottoRunnersColors.primaryYellow),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: LottoRunnersColors.primaryYellow, width: 2),
                ),
              ),
              validator: (value) {
                if (_userProfile?['has_vehicle'] == true &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please provide vehicle details';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              decoration: InputDecoration(
                labelText: 'License Number *',
                prefixIcon: Icon(Icons.badge,
                    color: LottoRunnersColors.primaryYellow),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: LottoRunnersColors.primaryYellow, width: 2),
                ),
              ),
              validator: (value) {
                if (_userProfile?['has_vehicle'] == true &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please provide your license number';
                }
                return null;
              },
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: LottoRunnersColors.primaryYellow
                        .withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: LottoRunnersColors.primaryYellow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You can still apply as a runner!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You\'ll be able to accept errands that don\'t require transportation.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.primaryYellow,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Document Upload Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: LottoRunnersColors.primaryYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Required Documents',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: LottoRunnersColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload the required documents to complete your runner application.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Code of Conduct (Required for all runners)
                DocumentUploadWidget(
                  title: 'Code of Conduct Agreement',
                  description:
                      'Please download, sign, and upload the code of conduct agreement',
                  documentType: 'code_of_conduct',
                  currentDocumentUrl: _codeOfConductPdf,
                  isRequired: true,
                  allowedExtensions: const ['pdf'],
                  maxFileSizeMB: 5,
                  onDocumentUploaded: (url) {
                    setState(() {
                      _codeOfConductPdf = url;
                    });
                  },
                ),

                // Driver License (Required for vehicle owners)
                if (_userProfile?['has_vehicle'] == true) ...[
                  DocumentUploadWidget(
                    title: 'Driver License',
                    description:
                        'Upload a clear photo or scan of your valid driver license',
                    documentType: 'driver_license',
                    currentDocumentUrl: _driverLicensePdf,
                    isRequired: true,
                    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
                    maxFileSizeMB: 10,
                    onDocumentUploaded: (url) {
                      setState(() {
                        _driverLicensePdf = url;
                      });
                    },
                  ),

                  // Vehicle Photos
                  DocumentUploadWidget(
                    title: 'Vehicle Photos',
                    description:
                        'Upload clear photos of your vehicle (front, back, and side views)',
                    documentType: 'vehicle_photos',
                    currentDocumentUrl:
                        _vehiclePhotos.isNotEmpty ? _vehiclePhotos.first : null,
                    isRequired: true,
                    allowedExtensions: const ['jpg', 'jpeg', 'png'],
                    maxFileSizeMB: 5,
                    onDocumentUploaded: (url) {
                      setState(() {
                        if (url != null && !_vehiclePhotos.contains(url)) {
                          _vehiclePhotos.add(url);
                        }
                      });
                    },
                  ),

                  // License Disc Photos
                  DocumentUploadWidget(
                    title: 'License Disc Photos',
                    description:
                        'Upload clear photos of your vehicle license disc (front and back)',
                    documentType: 'license_disc',
                    currentDocumentUrl: _licenseDiscPhotos.isNotEmpty
                        ? _licenseDiscPhotos.first
                        : null,
                    isRequired: true,
                    allowedExtensions: const ['jpg', 'jpeg', 'png'],
                    maxFileSizeMB: 5,
                    onDocumentUploaded: (url) {
                      setState(() {
                        if (url != null && !_licenseDiscPhotos.contains(url)) {
                          _licenseDiscPhotos.add(url);
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isSubmittingApplication ? null : _submitRunnerApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmittingApplication
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onSecondary),
                      ),
                    )
                  : Text(
                      'Submit Application',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.help_outline,
              color: LottoRunnersColors.primaryYellow),
          title: const Text('Help & Support'),
          trailing: Icon(Icons.chevron_right,
              color: LottoRunnersColors.primaryYellow),
          onTap: () => _showHelpPage(),
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip_outlined,
              color: LottoRunnersColors.primaryYellow),
          title: const Text('Privacy Policy'),
          trailing: Icon(Icons.chevron_right,
              color: LottoRunnersColors.primaryYellow),
          onTap: () => _showPrivacyPage(),
        ),
        ListTile(
          leading: Icon(Icons.article_outlined,
              color: LottoRunnersColors.primaryYellow),
          title: const Text('Terms of Service'),
          trailing: Icon(Icons.chevron_right,
              color: LottoRunnersColors.primaryYellow),
          onTap: () => _showTermsPage(),
        ),
        const Divider(height: 32),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text(
            'Sign Out',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: _showSignOutDialog,
        ),
      ],
    );
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'runner':
        return Icons.directions_run;
      case 'business':
        return Icons.business;
      case 'individual':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return;

      await SupabaseConfig.updateUserProfile({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadUserData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitRunnerApplication() async {
    setState(() => _isSubmittingApplication = true);

    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final hasVehicle = _userProfile?['has_vehicle'] == true;

      // Validate vehicle fields only if they have a vehicle
      if (hasVehicle) {
        if (_selectedVehicleType == null || _selectedVehicleType!.isEmpty) {
          throw Exception('Please select a vehicle type');
        }
        if (_vehicleDetailsController.text.trim().isEmpty) {
          throw Exception('Please provide vehicle details');
        }
        if (_licenseController.text.trim().isEmpty) {
          throw Exception('Please provide your license number');
        }
      }

      // Validate required documents
      if (_codeOfConductPdf == null || _codeOfConductPdf!.isEmpty) {
        throw Exception('Please upload the code of conduct agreement');
      }

      if (hasVehicle) {
        if (_driverLicensePdf == null || _driverLicensePdf!.isEmpty) {
          throw Exception('Please upload your driver license');
        }
        if (_vehiclePhotos.isEmpty) {
          throw Exception('Please upload at least one vehicle photo');
        }
        if (_licenseDiscPhotos.isEmpty) {
          throw Exception('Please upload at least one license disc photo');
        }
      }

      final applicationData = {
        'user_id': userId,
        'has_vehicle': hasVehicle,
        'vehicle_type': hasVehicle ? _selectedVehicleType : null,
        'vehicle_details':
            hasVehicle ? _vehicleDetailsController.text.trim() : null,
        'license_number': hasVehicle ? _licenseController.text.trim() : null,
        'driver_license_pdf': hasVehicle ? _driverLicensePdf : null,
        'code_of_conduct_pdf': _codeOfConductPdf,
        'vehicle_photos': hasVehicle ? _vehiclePhotos : null,
        'license_disc_photos': hasVehicle ? _licenseDiscPhotos : null,
        'verification_status': 'pending',
      };

      await SupabaseConfig.submitRunnerApplication(applicationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasVehicle
                ? 'Runner application submitted successfully! You can accept both errands and transportation bookings.'
                : 'Runner application submitted successfully! You can accept errands that don\'t require transportation.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadUserData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingApplication = false);
      }
    }
  }

  void _showUpdateApplicationDialog() {
    final theme = Theme.of(context);
    final TextEditingController vehicleDetailsController =
        TextEditingController(
      text: _runnerApplication?['vehicle_details'] ?? '',
    );
    final TextEditingController licenseController = TextEditingController(
      text: _runnerApplication?['license_number'] ?? '',
    );
    String? selectedVehicleType = _runnerApplication?['vehicle_type'];
    bool hasVehicle = _runnerApplication?['has_vehicle'] == true;

    // Check if runner is currently verified
    final isCurrentlyVerified = _userProfile?['is_verified'] == true;

    // Document state variables
    String? driverLicensePdf = _driverLicensePdf;
    String? codeOfConductPdf = _codeOfConductPdf;
    List<String> vehiclePhotos = List<String>.from(_vehiclePhotos);
    List<String> licenseDiscPhotos = List<String>.from(_licenseDiscPhotos);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Runner Application'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message for verified runners
                if (isCurrentlyVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verification Status Change',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Updating your application will change your verification status to "Pending" and you will not receive errand notifications until re-verified by an admin.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'Update your vehicle information and documents to accept transportation bookings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // Vehicle option
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car,
                          color: LottoRunnersColors.primaryYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Do you have a vehicle?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Having a vehicle allows you to accept transportation bookings',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: hasVehicle,
                        onChanged: (value) {
                          setDialogState(() {
                            hasVehicle = value;
                            if (!value) {
                              selectedVehicleType = null;
                              vehicleDetailsController.clear();
                              licenseController.clear();
                              driverLicensePdf = null;
                              vehiclePhotos.clear();
                              licenseDiscPhotos.clear();
                            }
                          });
                        },
                        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Theme.of(context).colorScheme.secondary;
                          }
                          return Theme.of(context).colorScheme.onSurface.withOpacity(0.54);
                        }),
                      ),
                    ],
                  ),
                ),

                if (hasVehicle) ...[
                  const SizedBox(height: 16),
                  // Vehicle Type Selection
                  DropdownButtonFormField<String>(
                    value: selectedVehicleType,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type *',
                      prefixIcon: Icon(Icons.directions_car,
                          color: LottoRunnersColors.primaryYellow),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: LottoRunnersColors.primaryYellow, width: 2),
                      ),
                    ),
                    items: _vehicleTypes.map((vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle['id'],
                        child: Row(
                          children: [
                            Icon(vehicle['icon'], size: 20),
                            const SizedBox(width: 12),
                            Text(vehicle['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVehicleType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: vehicleDetailsController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Details *',
                      hintText: 'e.g., 2020 Honda Civic, Blue',
                      prefixIcon: Icon(Icons.car_rental,
                          color: LottoRunnersColors.primaryYellow),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: LottoRunnersColors.primaryYellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: licenseController,
                    decoration: InputDecoration(
                      labelText: 'License Number *',
                      prefixIcon: Icon(Icons.badge,
                          color: LottoRunnersColors.primaryYellow),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: LottoRunnersColors.primaryYellow, width: 2),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Required Documents Section
                Text(
                  'Required Documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // Code of Conduct (Required for all)
                _buildDocumentUploadSection(
                  theme: theme,
                  title: 'Code of Conduct Agreement *',
                  subtitle: 'Required for all runners',
                  currentFile: codeOfConductPdf,
                  onFileSelected: (file) {
                    setDialogState(() {
                      codeOfConductPdf = file;
                    });
                  },
                  isRequired: true,
                ),

                if (hasVehicle) ...[
                  const SizedBox(height: 16),
                  // Driver License (Required if has vehicle)
                  _buildDocumentUploadSection(
                    theme: theme,
                    title: 'Driver License *',
                    subtitle: 'Required for vehicle owners',
                    currentFile: driverLicensePdf,
                    onFileSelected: (file) {
                      setDialogState(() {
                        driverLicensePdf = file;
                      });
                    },
                    isRequired: true,
                  ),

                  const SizedBox(height: 16),
                  // Vehicle Photos (Required if has vehicle)
                  _buildMultipleImageUploadSection(
                    theme: theme,
                    title: 'Vehicle Photos *',
                    subtitle: 'Upload at least 2 photos of your vehicle',
                    currentImages: vehiclePhotos,
                    onImagesSelected: (images) {
                      setDialogState(() {
                        vehiclePhotos = images;
                      });
                    },
                    isRequired: true,
                  ),

                  const SizedBox(height: 16),
                  // License Disc Photos (Required if has vehicle)
                  _buildMultipleImageUploadSection(
                    theme: theme,
                    title: 'License Disc Photos *',
                    subtitle: 'Upload photos of your vehicle license disc',
                    currentImages: licenseDiscPhotos,
                    onImagesSelected: (images) {
                      setDialogState(() {
                        licenseDiscPhotos = images;
                      });
                    },
                    isRequired: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate vehicle fields only if they have a vehicle
                if (hasVehicle) {
                  if (selectedVehicleType == null ||
                      selectedVehicleType!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a vehicle type')),
                    );
                    return;
                  }
                  if (vehicleDetailsController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please provide vehicle details')),
                    );
                    return;
                  }
                  if (licenseController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please provide your license number')),
                    );
                    return;
                  }
                }

                // Validate required documents
                if (codeOfConductPdf == null || codeOfConductPdf!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please upload the code of conduct agreement')),
                  );
                  return;
                }

                if (hasVehicle) {
                  if (driverLicensePdf == null || driverLicensePdf!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please upload your driver license')),
                    );
                    return;
                  }
                  if (vehiclePhotos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please upload at least one vehicle photo')),
                    );
                    return;
                  }
                  if (licenseDiscPhotos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please upload at least one license disc photo')),
                    );
                    return;
                  }
                }

                Navigator.pop(context);
                await _updateRunnerApplicationWithDocuments(
                  hasVehicle: hasVehicle,
                  vehicleType: selectedVehicleType,
                  vehicleDetails: vehicleDetailsController.text.trim(),
                  licenseNumber: licenseController.text.trim(),
                  driverLicensePdf: driverLicensePdf,
                  codeOfConductPdf: codeOfConductPdf,
                  vehiclePhotos: vehiclePhotos,
                  licenseDiscPhotos: licenseDiscPhotos,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Application'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection({
    required ThemeData theme,
    required String title,
    required String subtitle,
    String? currentFile,
    required Function(String?) onFileSelected,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color:
                    isRequired ? Colors.red : LottoRunnersColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isRequired
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentFile != null && currentFile.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document uploaded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onFileSelected(null),
                    child: const Text('Remove', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _uploadDocument(onFileSelected),
              icon: Icon(Icons.upload, size: 16),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipleImageUploadSection({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<String> currentImages,
    required Function(List<String>) onImagesSelected,
    bool isRequired = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color:
                    isRequired ? Colors.red : LottoRunnersColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isRequired
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (currentImages.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            final newImages = List<String>.from(currentImages);
                            newImages.removeAt(index);
                            onImagesSelected(newImages);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            onPressed: () => _uploadImages(onImagesSelected, currentImages),
            icon: Icon(Icons.add_photo_alternate, size: 16),
            label: Text('Add Photos (${currentImages.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(Function(String?) onFileSelected) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Pick PDF file using ImageUploadHelper (same as errand forms)
      final pdfBytes = await ImageUploadHelper.pickPDFFromFiles();
      if (pdfBytes == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate unique filename
      final userId = SupabaseConfig.currentUser?.id ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/documents/${timestamp}_document.pdf';

      // Upload to Supabase storage
      final documentUrl = await SupabaseConfig.uploadImage(
        'errand-images', // Using the same bucket as other documents
        storagePath,
        pdfBytes,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        onFileSelected(documentUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog if open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImages(Function(List<String>) onImagesSelected,
      List<String> currentImages) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Pick image from gallery
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate unique filename
      final userId = SupabaseConfig.currentUser?.id ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/images/${timestamp}_vehicle_photo.jpg';

      // Upload to Supabase storage
      final imageUrl = await SupabaseConfig.uploadImage(
        'errand-images', // Using the same bucket as other images
        storagePath,
        imageBytes,
      );

      // Add to current images list
      final newImages = [...currentImages, imageUrl];

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        onImagesSelected(newImages);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog if open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateRunnerApplicationWithDocuments({
    required bool hasVehicle,
    String? vehicleType,
    String? vehicleDetails,
    String? licenseNumber,
    String? driverLicensePdf,
    String? codeOfConductPdf,
    List<String>? vehiclePhotos,
    List<String>? licenseDiscPhotos,
  }) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if runner is currently verified
      final isCurrentlyVerified = _userProfile?['is_verified'] == true;

      // Update the runner application with new data and documents
      final applicationId = _runnerApplication?['id'];
      if (applicationId == null) throw Exception('Application not found');

      final updateData = {
        'has_vehicle': hasVehicle,
        'vehicle_type': hasVehicle ? vehicleType : null,
        'vehicle_details': hasVehicle ? vehicleDetails : null,
        'license_number': hasVehicle ? licenseNumber : null,
        'driver_license_pdf': hasVehicle ? driverLicensePdf : null,
        'code_of_conduct_pdf': codeOfConductPdf,
        'vehicle_photos': hasVehicle ? vehiclePhotos : null,
        'license_disc_photos': hasVehicle ? licenseDiscPhotos : null,
        'verification_status': 'pending', // Always set to pending when updating
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update runner application
      await SupabaseConfig.client
          .from('runner_applications')
          .update(updateData)
          .eq('id', applicationId);

      // Update user profile - set verification to false if they were verified
      await SupabaseConfig.client.from('users').update({
        'has_vehicle': hasVehicle,
        'is_verified': false, // Always set to false when updating
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyVerified
                  ? 'Application updated successfully! Your verification status has been changed to "Pending" and you will not receive errand notifications until re-verified by an admin.'
                  : 'Application updated successfully! You can now accept transportation bookings.',
            ),
            backgroundColor: isCurrentlyVerified
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
          ),
        );
        _loadUserData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating application: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Picture',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    theme: theme,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadProfileImage(fromCamera: false);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceButton(
                    theme: theme,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadProfileImage(fromCamera: true);
                    },
                  ),
                ),
              ],
            ),
            if (_userProfile?['avatar_url'] != null &&
                _userProfile!['avatar_url'].isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Remove Current Photo'),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage({required bool fromCamera}) async {
    try {
      setState(() => _isUploadingImage = true);
      print('🚀 Starting profile image upload...');

      final imageBytes = fromCamera
          ? await ImageUploadHelper.captureImage()
          : await ImageUploadHelper.pickImageFromGallery();

      if (imageBytes != null) {
        print('📷 Image selected, size: ${imageBytes.length} bytes');

        final userId = SupabaseConfig.currentUser?.id;
        if (userId == null) throw Exception('User not authenticated');

        print('👤 User ID: $userId');
        print('📤 Uploading to Supabase storage...');

        // Upload image to Supabase storage using the dedicated profile image function
        final imageUrl =
            await SupabaseConfig.uploadProfileImage(userId, imageBytes);
        print('✅ Image uploaded successfully: $imageUrl');

        // Update user profile with new avatar URL
        await SupabaseConfig.updateUserProfile({
          'avatar_url': imageUrl,
        });
        print('✅ Profile updated with avatar URL');

        // Refresh user data to show new image
        await _loadUserData();
        print('✅ Profile data refreshed');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Update user profile to remove avatar URL
      await SupabaseConfig.updateUserProfile({
        'avatar_url': null,
      });

      // Refresh user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await SupabaseConfig.signOut();
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehicleDetailsController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _showHelpPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How to use Lotto Runners:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Post an errand with clear details'),
              Text('2. Set a fair price for the task'),
              Text('3. Wait for a runner to accept'),
              Text('4. Track progress in real-time'),
              Text('5. Mark as completed when done'),
              SizedBox(height: 16),
              Text('For Runners:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Browse available errands'),
              Text('2. Accept tasks you can complete'),
              Text('3. Update status as you progress'),
              Text('4. Complete tasks on time'),
              SizedBox(height: 16),
              Text('Need more help?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Contact us at support@lottorunners.com'),
              Text('Phone: +264 81 123 4567'),
              Text('Available 24/7 for assistance'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Data Collection:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'We collect information necessary to provide our service including your name, email, phone number, and location when posting errands.'),
              SizedBox(height: 16),
              Text('Data Usage:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'Your data is used to connect you with runners, process payments, and improve our service. We do not sell your personal information.'),
              SizedBox(height: 16),
              Text('Data Protection:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'We use industry-standard security measures to protect your data. All payments are processed securely through encrypted channels.'),
              SizedBox(height: 16),
              Text('Your Rights:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'You can request access to, correction of, or deletion of your personal data at any time by contacting us.'),
              SizedBox(height: 16),
              Text('Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('For privacy concerns, email privacy@lottorunners.com'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsPage() {
    final userType = _userProfile?['user_type'] as String?;
    
    // Navigate to appropriate terms page based on user type
    if (userType == 'runner') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsConditionsRunnerPage(),
        ),
      );
    } else {
      // For individual, business, or admin users, show individual terms
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TermsConditionsIndividualPage(),
        ),
      );
    }
  }
}
