import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final users = await SupabaseConfig.getAllUsers();

      print('📊 Loaded ${users.length} users from database');
      for (var user in users) {
        print(
            '👤 User: ${user['full_name']} - Verified: ${user['is_verified']}');
      }

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
        // Reapply current filters after loading
        _filterUsers(_searchQuery, _selectedFilter);
        print('🔄 Applied filters - showing ${_filteredUsers.length} users');
      }
    } catch (e) {
      print('❌ Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to load users. Please check your internet connection and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _filterUsers(String query, String filter) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query;
      _selectedFilter = filter;

      _filteredUsers = _users.where((user) {
        // Search filter
        final matchesSearch = query.isEmpty ||
            user['full_name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            user['email']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        // Type filter
        final matchesType = filter == 'all' || user['user_type'] == filter;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _deactivateUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Are you sure you want to deactivate $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.deactivateUser(userId);
        if (mounted) {
          _loadUsers();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$userName has been deactivated')),
            );
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to deactivate user. Please check your internet connection and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyUser(
      String userId, String userName, bool isCurrentlyVerified) async {
    final action = isCurrentlyVerified ? 'unverify' : 'verify';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'verify' ? 'Verify' : 'Unverify'} User'),
        content: Text(
          'Are you sure you want to $action $userName?\n\n'
          '${action == 'verify' ? 'This will mark the user as verified and allow them full access to the platform.' : 'This will mark the user as unverified and may restrict their access.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'verify' ? Colors.green : Colors.orange),
            child: Text(action == 'verify' ? 'Verify' : 'Unverify'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🔍 Verify User Debug:');
        print('  User ID: $userId');
        print('  User Name: $userName');
        print('  Currently Verified: $isCurrentlyVerified');
        print('  Action: $action');

        // Debug: Check if user exists in current data
        final userInList = _users.firstWhere(
          (u) => u['id'] == userId,
          orElse: () => {},
        );
        print(
            '🔍 User in current list: ${userInList.isNotEmpty ? "Found" : "NOT FOUND"}');
        if (userInList.isNotEmpty) {
          print('  User data: $userInList');
        }

        if (action == 'verify') {
          await SupabaseConfig.verifyUser(userId);
          print('✅ User verified successfully');
        } else {
          await SupabaseConfig.unverifyUser(userId);
          print('✅ User unverified successfully');
        }

        // Small delay to ensure database update is committed
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          print('🔄 Reloading users list...');
          // Force refresh by clearing current state
          setState(() {
            _users = [];
            _filteredUsers = [];
          });
          await _loadUsers();
          // Small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 200));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$userName has been ${action}d'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error ${action}ing user: $e');
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to ${action} user. Please check your internet connection and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete $userName?\n\n'
          '⚠️ This action cannot be undone and will remove all user data including:\n'
          '• User profile\n'
          '• All errands and bookings\n'
          '• Chat history\n'
          '• Any other associated data',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.deleteUser(userId);
        if (mounted) {
          _loadUsers();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$userName has been permanently deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to delete user. Please check your internet connection and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) async {
    // If user is a runner, get their application details
    Map<String, dynamic>? runnerApplication;
    if (user['user_type'] == 'runner') {
      try {
        final response = await SupabaseConfig.client
            .from('runner_applications')
            .select('*')
            .eq('user_id', user['id'])
            .maybeSingle();
        runnerApplication = response;
      } catch (e) {
        print('Error fetching runner application: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
              _buildDetailRow(
                  'Type', _formatUserType(user['user_type'] ?? 'N/A')),
              _buildDetailRow('Verified', user['is_verified'] ? 'Yes' : 'No'),
              if (user['user_type'] == 'runner') ...[
                _buildDetailRow(
                    'Has Vehicle', user['has_vehicle'] ? 'Yes' : 'No'),
                if (runnerApplication != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Runner Application Documents:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildDocumentStatusRow(
                    'Code of Conduct',
                    runnerApplication['code_of_conduct_pdf'] != null &&
                        runnerApplication['code_of_conduct_pdf']
                            .toString()
                            .isNotEmpty,
                    runnerApplication['code_of_conduct_pdf'],
                  ),
                  if (runnerApplication['has_vehicle'] == true) ...[
                    _buildDocumentStatusRow(
                      'Driver License',
                      runnerApplication['driver_license_pdf'] != null &&
                          runnerApplication['driver_license_pdf']
                              .toString()
                              .isNotEmpty,
                      runnerApplication['driver_license_pdf'],
                    ),
                    _buildDocumentStatusRow(
                      'Vehicle Photos',
                      runnerApplication['vehicle_photos'] != null &&
                          (runnerApplication['vehicle_photos'] as List)
                              .isNotEmpty,
                      runnerApplication['vehicle_photos'] != null
                          ? (runnerApplication['vehicle_photos'] as List).first
                          : null,
                      isMultiple: true,
                      count: runnerApplication['vehicle_photos'] != null
                          ? (runnerApplication['vehicle_photos'] as List).length
                          : 0,
                      allUrls: runnerApplication['vehicle_photos'] != null
                          ? List<String>.from(
                              runnerApplication['vehicle_photos'])
                          : null,
                    ),
                    _buildDocumentStatusRow(
                      'License Disc Photos',
                      runnerApplication['license_disc_photos'] != null &&
                          (runnerApplication['license_disc_photos'] as List)
                              .isNotEmpty,
                      runnerApplication['license_disc_photos'] != null
                          ? (runnerApplication['license_disc_photos'] as List)
                              .first
                          : null,
                      isMultiple: true,
                      count: runnerApplication['license_disc_photos'] != null
                          ? (runnerApplication['license_disc_photos'] as List)
                              .length
                          : 0,
                      allUrls: runnerApplication['license_disc_photos'] != null
                          ? List<String>.from(
                              runnerApplication['license_disc_photos'])
                          : null,
                    ),
                  ],
                ],
              ],
              _buildDetailRow('Location', user['location_address'] ?? 'N/A'),
              _buildDetailRow('Joined', _formatDate(user['created_at'])),
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

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatUserType(String type) {
    switch (type) {
      case 'runner':
        return 'Runner';
      case 'business':
        return 'Business';
      case 'individual':
        return 'Individual';
      case 'admin':
        return 'Admin';
      default:
        return type;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getUserTypeColor(String type) {
    final theme = Theme.of(context);
    switch (type) {
      case 'runner':
        return theme.colorScheme.primary;
      case 'business':
        return theme.colorScheme.secondary;
      case 'individual':
        return theme.colorScheme.tertiary;
      case 'admin':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
        iconTheme: const IconThemeData(color: LottoRunnersColors.primaryYellow),
        actionsIconTheme:
            const IconThemeData(color: LottoRunnersColors.primaryYellow),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            color: LottoRunnersColors.gray50,
            child: Column(
              children: [
                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: LottoRunnersColors.gray300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                    isDense: isMobile,
                  ),
                  onChanged: (value) => _filterUsers(value, _selectedFilter),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                // Make filter chips responsive
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', isMobile),
                      _buildFilterChip('Runners', 'runner', isMobile),
                      _buildFilterChip('Businesses', 'business', isMobile),
                      _buildFilterChip('Individuals', 'individual', isMobile),
                      _buildFilterChip('Admins', 'admin', isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user, isMobile);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 6 : 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check,
                size: isMobile ? 14 : 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            if (isSelected) SizedBox(width: isMobile ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          _filterUsers(_searchQuery, selected ? value : 'all');
        },
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        selectedColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        showCheckmark: false,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isMobile) {
    final theme = Theme.of(context);
    final userType = user['user_type'] ?? 'individual';
    final userName = user['full_name'] ?? 'Unknown User';
    final userEmail = user['email'] ?? 'No email';
    final isVerified = user['is_verified'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User Avatar
                Container(
                  width: isMobile ? 40 : 48,
                  height: isMobile ? 40 : 48,
                  decoration: BoxDecoration(
                    color: _getUserTypeColor(userType),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 14 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (isMobile) ...[
                            const SizedBox(width: 8),
                            Icon(
                              isVerified ? Icons.verified : Icons.pending,
                              size: 16,
                              color: isVerified ? Colors.green : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'Verified' : 'Unverified',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isVerified ? Colors.green : theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _verifyUser(user['id'], userName, isVerified),
                              icon: Icon(
                                isVerified
                                    ? Icons.verified_user
                                    : Icons.verified_user_outlined,
                                size: 14,
                              ),
                              label: Text(
                                isVerified ? 'Unverify' : 'Verify',
                                style: const TextStyle(fontSize: 10),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    isVerified ? Colors.orange : Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isMobile ? 11 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // User Type Badge (Desktop only)
                if (!isMobile) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(userType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _getUserTypeColor(userType).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _formatUserType(userType),
                      style: TextStyle(
                        color: _getUserTypeColor(userType),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),
            // Additional Info Row
            if (!isMobile) ...[
              Row(
                children: [
                  Icon(
                    isVerified ? Icons.verified : Icons.pending,
                    size: 18,
                    color: isVerified ? Colors.green : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVerified ? 'Verified' : 'Unverified',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isVerified ? Colors.green : theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Action Buttons for Desktop
                  TextButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text(
                      'Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _verifyUser(user['id'], userName, isVerified),
                    icon: Icon(
                      isVerified
                          ? Icons.verified_user
                          : Icons.verified_user_outlined,
                      size: 18,
                    ),
                    label: Text(
                      isVerified ? 'Unverify' : 'Verify',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isVerified ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deactivateUser(user['id'], userName),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text(
                      'Deactivate',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteUser(user['id'], userName),
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
            // Mobile Action Buttons
            if (isMobile) ...[
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text(
                      'Details',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _verifyUser(user['id'], userName, isVerified),
                    icon: Icon(
                      isVerified
                          ? Icons.verified_user
                          : Icons.verified_user_outlined,
                      size: 16,
                    ),
                    label: Text(
                      isVerified ? 'Unverify' : 'Verify',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isVerified ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deactivateUser(user['id'], userName),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text(
                      'Deactivate',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteUser(user['id'], userName),
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // User Role for Mobile
              Row(
                children: [
                  Icon(
                    _getUserTypeIcon(userType),
                    size: 16,
                    color: _getUserTypeColor(userType),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatUserType(userType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getUserTypeColor(userType),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for user type icon
  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'business':
        return Icons.business;
      case 'runner':
        return Icons.directions_run;
      case 'individual':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  Widget _buildDocumentStatusRow(
      String documentType, bool isUploaded, String? documentUrl,
      {bool isMultiple = false, int count = 0, List<String>? allUrls}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isUploaded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              documentType,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (isMultiple && count > 0)
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                color: LottoRunnersColors.gray600,
              ),
            ),
          if (isUploaded && documentUrl != null) ...[
            const SizedBox(width: 8),
            if (isMultiple && allUrls != null && allUrls.length > 1) ...[
              // Show dropdown for multiple documents
              PopupMenuButton<String>(
                onSelected: (url) => _downloadDocument(url, documentType),
                itemBuilder: (context) => allUrls.map((url) {
                  final index = allUrls.indexOf(url) + 1;
                  return PopupMenuItem<String>(
                    value: url,
                    child: Text('Download Photo $index'),
                  );
                }).toList(),
                child: const Text(
                  'Download All',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ] else ...[
              // Single document download
              TextButton(
                onPressed: () => _downloadDocument(documentUrl, documentType),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _downloadDocument(
      String documentUrl, String documentType) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final fileName = documentUrl.split('/').last;
      final extension =
          fileName.contains('.') ? fileName.split('.').last : 'pdf';
      final finalFileName =
          '${documentType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final response = await http.get(Uri.parse(documentUrl));
      if (response.statusCode == 200) {
        Navigator.pop(context);

        // Try to download to downloads directory first
        try {
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            final file = File('${directory.path}/$finalFileName');
            await file.writeAsBytes(response.bodyBytes);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document downloaded to ${file.path}'),
                backgroundColor: Colors.green,
              ),
            );
            if (await canLaunchUrl(Uri.file(file.path))) {
              await launchUrl(Uri.file(file.path));
            }
            return;
          }
        } catch (e) {
          print('Downloads directory not available: $e');
        }

        // Fallback: Try to open the document URL directly
        try {
          if (await canLaunchUrl(Uri.parse(documentUrl))) {
            await launchUrl(Uri.parse(documentUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document opened in browser'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not open document. Please copy the URL manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to download document: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
