import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/image_upload.dart';

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
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSignOutDialog,
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.error,
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
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
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
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(
                        _getUserTypeIcon(userType),
                        size: 40,
                        color: theme.colorScheme.onPrimary,
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.onPrimary,
                        width: 2,
                      ),
                    ),
                    child: _isUploadingImage
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
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
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${userType.toUpperCase()} ${isVerified ? '• Verified' : '• Pending'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
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
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon:
                Icon(Icons.person_outlined, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon:
                Icon(Icons.phone_outlined, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _userProfile?['email'] ?? '',
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon:
                Icon(Icons.email_outlined, color: theme.colorScheme.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            fillColor: theme.colorScheme.outline.withOpacity(0.1),
            filled: true,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Update Profile',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
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
    final applicationStatus =
        _runnerApplication?['verification_status'] ?? 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Runner Verification',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (hasApplication) ...[
          _buildApplicationStatus(theme, applicationStatus),
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
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.pending;
        statusText = 'Under Review';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_runnerApplication?['has_vehicle'] == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car,
                      color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle: ${_runnerApplication?['vehicle_type'] ?? 'Not specified'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply for Runner Verification',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get verified to start accepting errands and earn money as a trusted runner.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Do you have a vehicle?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _userProfile?['has_vehicle'] == true,
                  onChanged: (value) {
                    setState(() {
                      _userProfile?['has_vehicle'] = value;
                    });
                  },
                  activeColor: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),

          if (_userProfile?['has_vehicle'] == true) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehicleDetailsController,
              decoration: InputDecoration(
                labelText: 'Vehicle Details',
                hintText: 'e.g., 2020 Honda Civic, Blue',
                prefixIcon:
                    Icon(Icons.car_rental, color: theme.colorScheme.secondary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.secondary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              decoration: InputDecoration(
                labelText: 'License Number',
                prefixIcon:
                    Icon(Icons.badge, color: theme.colorScheme.tertiary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.tertiary, width: 2),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isSubmittingApplication ? null : _submitRunnerApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
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
                            theme.colorScheme.onSecondary),
                      ),
                    )
                  : Text(
                      'Submit Application',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondary,
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
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
          title: const Text('Help & Support'),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          onTap: () {
            // TODO: Navigate to help page
          },
        ),
        ListTile(
          leading: Icon(Icons.privacy_tip_outlined,
              color: theme.colorScheme.primary),
          title: const Text('Privacy Policy'),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          onTap: () {
            // TODO: Navigate to privacy page
          },
        ),
        ListTile(
          leading:
              Icon(Icons.article_outlined, color: theme.colorScheme.primary),
          title: const Text('Terms of Service'),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          onTap: () {
            // TODO: Navigate to terms page
          },
        ),
        const Divider(height: 32),
        ListTile(
          leading: Icon(Icons.logout, color: theme.colorScheme.error),
          title: Text(
            'Sign Out',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          onTap: _showSignOutDialog,
        ),
      ],
    );
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case 'runner':
        return Icons.directions_run;
      case 'business':
        return Icons.business;
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

      final applicationData = {
        'user_id': userId,
        'has_vehicle': hasVehicle,
        'vehicle_type': hasVehicle ? 'car' : null,
        'vehicle_details':
            hasVehicle ? _vehicleDetailsController.text.trim() : null,
        'license_number': hasVehicle ? _licenseController.text.trim() : null,
        'verification_status': 'pending',
      };

      await SupabaseConfig.submitRunnerApplication(applicationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Runner application submitted successfully!'),
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

  void _showImagePickerDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
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
                    foregroundColor: theme.colorScheme.error,
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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
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
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await SupabaseConfig.signOut();
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: theme.colorScheme.error),
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
}
