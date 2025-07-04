import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

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
    try {
      setState(() => _isLoading = true);
      final users = await SupabaseConfig.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers(String query, String filter) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.deactivateUser(userId);
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$userName has been deactivated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deactivating user: $e')),
          );
        }
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
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
              if (user['user_type'] == 'runner')
                _buildDetailRow(
                    'Has Vehicle', user['has_vehicle'] ? 'Yes' : 'No'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
    switch (type) {
      case 'runner':
        return Colors.blue;
      case 'business':
        return Colors.purple;
      case 'individual':
        return Colors.green;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _filterUsers(value, _selectedFilter),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Runners', 'runner'),
                      _buildFilterChip('Businesses', 'business'),
                      _buildFilterChip('Individuals', 'individual'),
                      _buildFilterChip('Admins', 'admin'),
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
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterUsers(_searchQuery, selected ? value : 'all');
        },
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userType = user['user_type'] ?? 'unknown';
    final typeColor = _getUserTypeColor(userType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.1),
                  child: Icon(
                    _getUserTypeIcon(userType),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatUserType(userType),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  user['is_verified'] ? Icons.verified : Icons.pending,
                  size: 16,
                  color: user['is_verified'] ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user['is_verified'] ? 'Verified' : 'Unverified',
                  style: TextStyle(
                    color: user['is_verified'] ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
                if (user['user_type'] == 'runner') ...[
                  const SizedBox(width: 16),
                  Icon(
                    user['has_vehicle']
                        ? Icons.directions_car
                        : Icons.directions_walk,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user['has_vehicle'] ? 'With Vehicle' : 'On Foot',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Joined ${_formatDate(user['created_at'])}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                if (user['user_type'] != 'admin')
                  TextButton.icon(
                    onPressed: () => _deactivateUser(
                      user['id'],
                      user['full_name'] ?? 'User',
                    ),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Deactivate'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getUserTypeIcon(String type) {
    switch (type) {
      case 'runner':
        return Icons.directions_run;
      case 'business':
        return Icons.business;
      case 'individual':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.help_outline;
    }
  }
}
