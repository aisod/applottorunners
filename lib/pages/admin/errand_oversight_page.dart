import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

class ErrandOversightPage extends StatefulWidget {
  const ErrandOversightPage({super.key});

  @override
  State<ErrandOversightPage> createState() => _ErrandOversightPageState();
}

class _ErrandOversightPageState extends State<ErrandOversightPage> {
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _filteredErrands = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadErrands();
  }

  Future<void> _loadErrands() async {
    try {
      setState(() => _isLoading = true);
      final errands = await SupabaseConfig.getAllErrands();
      setState(() {
        _errands = errands;
        _filteredErrands = errands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading errands: $e')),
        );
      }
    }
  }

  void _filterErrands(String query, String status, String category) {
    setState(() {
      _searchQuery = query;
      _selectedStatus = status;
      _selectedCategory = category;

      _filteredErrands = _errands.where((errand) {
        // Search filter
        final matchesSearch = query.isEmpty ||
            errand['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            errand['description']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        // Status filter
        final matchesStatus = status == 'all' || errand['status'] == status;

        // Category filter
        final matchesCategory =
            category == 'all' || errand['category'] == category;

        return matchesSearch && matchesStatus && matchesCategory;
      }).toList();
    });
  }

  void _showErrandDetails(Map<String, dynamic> errand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(errand['title'] ?? 'Errand Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', errand['description'] ?? 'N/A'),
              _buildDetailRow(
                  'Category', _formatCategory(errand['category'] ?? 'N/A')),
              _buildDetailRow(
                  'Status', _formatStatus(errand['status'] ?? 'N/A')),
              _buildDetailRow('Price', '\$${errand['price_amount'] ?? '0.00'}'),
              _buildDetailRow(
                  'Time Limit', '${errand['time_limit_hours'] ?? 0} hours'),
              _buildDetailRow('Location', errand['location_address'] ?? 'N/A'),
              if (errand['pickup_address'] != null)
                _buildDetailRow('Pickup', errand['pickup_address']),
              if (errand['delivery_address'] != null)
                _buildDetailRow('Delivery', errand['delivery_address']),
              _buildDetailRow('Vehicle Required',
                  errand['requires_vehicle'] ? 'Yes' : 'No'),
              if (errand['customer'] != null)
                _buildDetailRow('Customer',
                    '${errand['customer']['full_name']} (${errand['customer']['email']})'),
              if (errand['runner'] != null)
                _buildDetailRow('Runner',
                    '${errand['runner']['full_name']} (${errand['runner']['email']})'),
              _buildDetailRow('Created', _formatDate(errand['created_at'])),
              if (errand['accepted_at'] != null)
                _buildDetailRow('Accepted', _formatDate(errand['accepted_at'])),
              if (errand['completed_at'] != null)
                _buildDetailRow(
                    'Completed', _formatDate(errand['completed_at'])),
              if (errand['special_instructions'] != null &&
                  errand['special_instructions'].isNotEmpty)
                _buildDetailRow('Instructions', errand['special_instructions']),
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

  String _formatCategory(String category) {
    switch (category) {
      case 'grocery':
        return 'Grocery';
      case 'delivery':
        return 'Delivery';
      case 'document':
        return 'Document';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'posted':
        return 'Posted';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'posted':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'grocery':
        return Colors.green;
      case 'delivery':
        return Colors.blue;
      case 'document':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'grocery':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'document':
        return Icons.description;
      case 'shopping':
        return Icons.shopping_bag;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.assignment;
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
                    hintText: 'Search errands by title or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) =>
                      _filterErrands(value, _selectedStatus, _selectedCategory),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Status: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _buildFilterChip(
                          'All',
                          'all',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory)),
                      _buildFilterChip(
                          'Posted',
                          'posted',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory)),
                      _buildFilterChip(
                          'Accepted',
                          'accepted',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory)),
                      _buildFilterChip(
                          'In Progress',
                          'in_progress',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory)),
                      _buildFilterChip(
                          'Completed',
                          'completed',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Category: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _buildFilterChip(
                          'All',
                          'all',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value)),
                      _buildFilterChip(
                          'Grocery',
                          'grocery',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value)),
                      _buildFilterChip(
                          'Delivery',
                          'delivery',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value)),
                      _buildFilterChip(
                          'Document',
                          'document',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value)),
                      _buildFilterChip(
                          'Shopping',
                          'shopping',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Errands List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredErrands.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No errands found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadErrands,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredErrands.length,
                          itemBuilder: (context, index) {
                            final errand = _filteredErrands[index];
                            return _buildErrandCard(errand);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue,
      Function(String) onSelected) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          onSelected(selected ? value : 'all');
        },
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
      ),
    );
  }

  Widget _buildErrandCard(Map<String, dynamic> errand) {
    final status = errand['status'] ?? 'unknown';
    final category = errand['category'] ?? 'other';
    final statusColor = _getStatusColor(status);
    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        errand['title'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        errand['description'] ?? 'No description',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      color: statusColor,
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
                Icon(Icons.attach_money, size: 16, color: Colors.green),
                Text(
                  'N\$${errand['price_amount'] ?? '0.00'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${errand['time_limit_hours'] ?? 0}h',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (errand['requires_vehicle']) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Vehicle',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(errand['created_at']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (errand['customer'] != null || errand['runner'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (errand['customer'] != null) ...[
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Customer: ${errand['customer']['full_name']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (errand['runner'] != null) ...[
                    if (errand['customer'] != null) const SizedBox(width: 16),
                    Icon(Icons.directions_run,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Runner: ${errand['runner']['full_name']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showErrandDetails(errand),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
