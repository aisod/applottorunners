import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

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
          SnackBar(
            content: const Text(
                'Unable to load errands. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    final theme = Theme.of(context);
    final isShopping = errand['category']?.toString() == 'shopping';
    final mod = errand['pricing_modifiers'] as Map<String, dynamic>?;
    final shoppingBudget = (mod?['shopping_budget'] as num?)?.toDouble();
    final shoppingFg = theme.colorScheme.onSecondaryContainer;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            if (isShopping)
              Icon(Icons.shopping_basket,
                  color: theme.colorScheme.secondary, size: 28),
            if (isShopping) const SizedBox(width: 8),
            Expanded(
                child: Text(errand['title'] ?? 'Errand Details',
                    style: TextStyle(color: theme.colorScheme.onSurface))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isShopping && shoppingBudget != null && shoppingBudget > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments, color: shoppingFg, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget to send to runner for shopping',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: shoppingFg,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'N\$${shoppingBudget.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: shoppingFg,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildDetailRow('Description', errand['description'] ?? 'N/A'),
              _buildDetailRow(
                  'Category', _formatCategory(errand['category'] ?? 'N/A')),
              _buildDetailRow(
                  'Status', _formatStatus(errand['status'] ?? 'N/A')),
              _buildDetailRow('Price', 'N\$${errand['price_amount'] ?? '0.00'}'),
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
            child: Text('Close',
                style: TextStyle(color: theme.colorScheme.primary)),
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
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: theme.colorScheme.onSurface)),
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

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'posted':
        return scheme.primary;
      case 'accepted':
        return scheme.secondary;
      case 'in_progress':
        return scheme.tertiary;
      case 'completed':
        return scheme.tertiary;
      case 'cancelled':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  Color _getCategoryColor(String category, ColorScheme scheme) {
    switch (category) {
      case 'grocery':
        return scheme.tertiary;
      case 'delivery':
        return scheme.primary;
      case 'document':
        return scheme.secondary;
      case 'shopping':
        return scheme.secondary;
      case 'other':
        return scheme.outline;
      default:
        return scheme.outline;
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Errand Oversight',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search errands by title or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (value) =>
                      _filterErrands(value, _selectedStatus, _selectedCategory),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Status: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      _buildFilterChip(
                          'All',
                          'all',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory),
                          context),
                      _buildFilterChip(
                          'Posted',
                          'posted',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory),
                          context),
                      _buildFilterChip(
                          'Accepted',
                          'accepted',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory),
                          context),
                      _buildFilterChip(
                          'In Progress',
                          'in_progress',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory),
                          context),
                      _buildFilterChip(
                          'Completed',
                          'completed',
                          _selectedStatus,
                          (value) => _filterErrands(
                              _searchQuery, value, _selectedCategory),
                          context),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Category: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      _buildFilterChip(
                          'All',
                          'all',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value),
                          context),
                      _buildFilterChip(
                          'Grocery',
                          'grocery',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value),
                          context),
                      _buildFilterChip(
                          'Delivery',
                          'delivery',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value),
                          context),
                      _buildFilterChip(
                          'Document',
                          'document',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value),
                          context),
                      _buildFilterChip(
                          'Shopping',
                          'shopping',
                          _selectedCategory,
                          (value) => _filterErrands(
                              _searchQuery, _selectedStatus, value),
                          context),
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No errands found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                color: theme.colorScheme.onSurfaceVariant,
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
      Function(String) onSelected, BuildContext context) {
    final isSelected = currentValue == value;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          onSelected(selected ? value : 'all');
        },
        selectedColor: theme.colorScheme.primaryContainer,
        backgroundColor: theme.colorScheme.surface,
        checkmarkColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.6)
              : theme.colorScheme.outline.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildErrandCard(Map<String, dynamic> errand) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = errand['status'] ?? 'unknown';
    final category = errand['category'] ?? 'other';
    final isShopping = category == 'shopping';
    final statusColor = _getStatusColor(status, scheme);
    final categoryColor = _getCategoryColor(category, scheme);
    final mod = errand['pricing_modifiers'] as Map<String, dynamic>?;
    final shoppingBudget = (mod?['shopping_budget'] as num?)?.toDouble() ?? 0.0;
    final shoppingBorder = scheme.secondary;
    final shoppingBg = scheme.secondaryContainer.withOpacity(0.5);
    final shoppingFg = scheme.onSecondaryContainer;
    final shoppingIconBg = scheme.secondary.withOpacity(0.25);

    return Card(
      margin:
          EdgeInsets.only(bottom: Responsive.isSmallMobile(context) ? 8 : 12),
      elevation: isShopping ? 4 : 1,
      color: isShopping ? shoppingBg : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isShopping
              ? shoppingBorder
              : scheme.outline.withOpacity(0.3),
          width: isShopping ? 2.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.all(Responsive.isSmallMobile(context) ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isShopping
                        ? shoppingIconBg
                        : categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isShopping ? Icons.shopping_basket : _getCategoryIcon(category),
                    color: isShopping ? shoppingFg : categoryColor,
                    size: Responsive.isSmallMobile(context) ? 16 : 20,
                  ),
                ),
                SizedBox(width: Responsive.isSmallMobile(context) ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isShopping)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'SHOPPING ORDER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: shoppingFg,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      Text(
                        errand['title'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        errand['description'] ?? 'No description',
                        style: TextStyle(
                          color: scheme.outline,
                          fontSize: Responsive.isSmallMobile(context) ? 12 : 14,
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
            if (isShopping && shoppingBudget > 0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 8 : 10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.secondary),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, color: shoppingFg, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Budget to send to runner: N\$${shoppingBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                          color: shoppingFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: scheme.tertiary),
                Text(
                  'N\$${errand['price_amount'] ?? '0.00'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '${errand['time_limit_hours'] ?? 0}h',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                if (errand['requires_vehicle']) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.directions_car,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Vehicle',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(errand['created_at']),
                  style: TextStyle(
                    color: theme.colorScheme.outline,
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
                    Icon(Icons.person,
                        size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Customer: ${errand['customer']['full_name']}',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (errand['runner'] != null) ...[
                    if (errand['customer'] != null) const SizedBox(width: 16),
                    Icon(Icons.directions_run,
                        size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Runner: ${errand['runner']['full_name']}',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
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
