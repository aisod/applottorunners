import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

class RunnerHistoryPage extends StatefulWidget {
  const RunnerHistoryPage({super.key});

  @override
  State<RunnerHistoryPage> createState() => _RunnerHistoryPageState();
}

class _RunnerHistoryPageState extends State<RunnerHistoryPage> {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _transportationBookings = [];
  List<Map<String, dynamic>> _contractBookings = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All History', 'icon': 'history'},
    {'value': 'errands', 'label': 'My Errands', 'icon': 'assignment'},
    {
      'value': 'transportation',
      'label': 'Transportation',
      'icon': 'directions_bus'
    },
    {'value': 'contracts', 'label': 'Contracts', 'icon': 'description'},
    {'value': 'grocery', 'label': 'Grocery', 'icon': 'shopping_cart'},
    {'value': 'delivery', 'label': 'Delivery', 'icon': 'local_shipping'},
    {'value': 'document', 'label': 'Documents', 'icon': 'description'},
    {'value': 'shopping', 'label': 'Shopping', 'icon': 'shopping_bag'},
    {'value': 'other', 'label': 'Other', 'icon': 'more_horiz'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = SupabaseConfig.currentUser;
      if (user != null) {
        // Load runner's completed errands and all bookings (transportation + contracts)
        final errands = await SupabaseConfig.getRunnerErrands(user.id);
        final allBookings = await SupabaseConfig.getRunnerAllBookings(user.id);

        // Filter for completed items only
        final completedErrands =
            errands.where((e) => e['status'] == 'completed').toList();
        final completedBookings =
            allBookings.where((b) => b['status'] == 'completed').toList();

        // Separate transportation and contract bookings
        final transportationBookings = completedBookings
            .where((b) => b['booking_type'] == 'transportation')
            .toList();
        final contractBookings = completedBookings
            .where((b) => b['booking_type'] == 'contract')
            .toList();

        setState(() {
          _errands = completedErrands;
          _transportationBookings = transportationBookings;
          _contractBookings = contractBookings;
          _allItems = [
            ...completedErrands.map((e) => {
                  ...e,
                  'item_type': 'errand',
                }),
            ...transportationBookings.map((b) => {
                  ...b,
                  'item_type': 'transportation',
                  'title': 'Shuttle Services',
                  'category': 'transportation',
                  'description':
                      '${b['pickup_location']} → ${b['dropoff_location']}',
                }),
            ...contractBookings.map((b) => {
                  ...b,
                  'item_type': 'contract',
                  'title': 'Contract Booking',
                  'category': 'contract',
                  'description':
                      '${b['pickup_location']} → ${b['dropoff_location']}',
                }),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading runner history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    List<Map<String, dynamic>> items = _allItems;

    // Apply category filter
    if (_selectedCategory != 'all') {
      if (_selectedCategory == 'errands') {
        items = items.where((item) => item['item_type'] == 'errand').toList();
      } else if (_selectedCategory == 'transportation') {
        items = items
            .where((item) => item['item_type'] == 'transportation')
            .toList();
      } else if (_selectedCategory == 'contracts') {
        items = items.where((item) => item['item_type'] == 'contract').toList();
      } else {
        items = items
            .where((item) => item['category'] == _selectedCategory)
            .toList();
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final title = item['title']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    return items;
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return 'Open';
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

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'posted':
        return Theme.of(context).colorScheme.primary;
      case 'accepted':
        return Theme.of(context).colorScheme.secondary;
      case 'in_progress':
        return Theme.of(context).colorScheme.tertiary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Header with stats
          SliverToBoxAdapter(
            child: _buildHeader(isSmallMobile, isMobile),
          ),
          // Search and filters
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(isSmallMobile, isMobile),
          ),
          // Content
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _buildContent(isSmallMobile, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallMobile, bool isMobile) {
    final theme = Theme.of(context);
    final totalItems = _allItems.length;
    final totalErrands = _errands.length;
    final totalTransportation = _transportationBookings.length;
    final totalContracts = _contractBookings.length;

    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallMobile ? 16.0 : 24.0),
          child: Column(
            children: [
              // Title row with refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.transparent,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'My History',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isSmallMobile ? 20.0 : 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadHistory,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              SizedBox(height: isSmallMobile ? 20.0 : 24.0),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.assignment,
                    count: totalErrands,
                    label: 'Errands',
                    isSmallMobile: isSmallMobile,
                  ),
                  _buildStatItem(
                    icon: Icons.directions_bus,
                    count: totalTransportation + totalContracts,
                    label: 'Transport',
                    isSmallMobile: isSmallMobile,
                  ),
                  _buildStatItem(
                    icon: Icons.history,
                    count: totalItems,
                    label: 'Total',
                    isSmallMobile: isSmallMobile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required bool isSmallMobile,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: LottoRunnersColors.primaryYellow,
          size: isSmallMobile ? 20.0 : 24.0,
        ),
        SizedBox(height: isSmallMobile ? 4.0 : 8.0),
        Text(
          '$count',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: isSmallMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
            fontSize: isSmallMobile ? 12.0 : 14.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isSmallMobile, bool isMobile) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search completed errands and bookings...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isSmallMobile ? 14.0 : 16.0,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: LottoRunnersColors.primaryYellow,
                  size: isSmallMobile ? 20.0 : 24.0,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 12.0 : 16.0,
                  vertical: isSmallMobile ? 12.0 : 16.0,
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallMobile ? 16.0 : 20.0),
          // Category buttons - horizontal scrollable
          SizedBox(
            height: isSmallMobile ? 40.0 : 48.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _categories.length - 1
                        ? (isSmallMobile ? 8.0 : 12.0)
                        : 0,
                  ),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['value']!),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 12.0 : 16.0,
                        vertical: isSmallMobile ? 8.0 : 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? LottoRunnersColors.primaryBlue
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? LottoRunnersColors.primaryBlue
                              : Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: isSmallMobile ? 16.0 : 18.0,
                            ),
                          if (isSelected)
                            SizedBox(width: isSmallMobile ? 4.0 : 8.0),
                          Text(
                            category['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: isSmallMobile ? 12.0 : 14.0,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallMobile, bool isMobile) {
    final filteredItems = _getFilteredItems();

    if (filteredItems.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(isSmallMobile),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredItems[index];
          return _buildHistoryItem(item, isSmallMobile, isMobile);
        },
        childCount: filteredItems.length,
      ),
    );
  }

  Widget _buildHistoryItem(
      Map<String, dynamic> item, bool isSmallMobile, bool isMobile) {
    final theme = Theme.of(context);
    final status = item['status'] ?? '';

    return Container(
      margin: EdgeInsets.only(
        left: Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        right: Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        bottom: Responsive.isSmallMobile(context) ? 6.0 : 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: LottoRunnersColors.gray900.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // No action needed for history items
          borderRadius: BorderRadius.circular(0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with service name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LottoRunnersColors.gray900,
                        ),
                      ),
                    ),
                    _buildStatusChip(status, theme),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer information
                if (item['customer'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            color: LottoRunnersColors.primaryYellow, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['customer']['full_name'] ?? 'Customer',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.isSmallMobile(context)
                                      ? 14
                                      : 16,
                                ),
                              ),
                              if (item['customer']['phone'] != null)
                                Text(
                                  item['customer']['phone'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: Responsive.isSmallMobile(context)
                                        ? 12
                                        : 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Service details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'Category',
                        item['category']?.toString().toUpperCase() ??
                            (item['item_type'] == 'contract'
                                ? 'CONTRACT'
                                : item['item_type'] == 'transportation'
                                    ? 'TRANSPORTATION'
                                    : 'ERRAND'),
                        theme,
                      ),
                    ),
                    if (item['price_amount'] != null ||
                        item['final_price'] != null)
                      Expanded(
                        child: _buildDetailRow(
                          'Earnings',
                          'N\$${item['price_amount']?.toString() ?? item['final_price']?.toString() ?? '0'}',
                          theme,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location and time details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (item['location_address'] != null ||
                          item['pickup_location'] != null)
                        _buildLocationRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          location: item['location_address'] ??
                              (item['pickup_location'] != null &&
                                      item['dropoff_location'] != null
                                  ? '${item['pickup_location']} → ${item['dropoff_location']}'
                                  : item['pickup_location'] ?? 'Location TBD'),
                          theme: theme,
                        ),
                      if (item['location_address'] != null ||
                          item['pickup_location'] != null)
                        const SizedBox(height: 8),
                      _buildLocationRow(
                        icon: Icons.schedule,
                        label: 'Completed',
                        location: _formatDate(item['completed_at'] ??
                            item['updated_at'] ??
                            item['created_at']),
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                // Description if available
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description,
                          size: 16,
                          color: LottoRunnersColors.primaryYellow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['description'],
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Service type indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed ${_formatDate(item['completed_at'] ?? item['updated_at'] ?? item['created_at'])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isSmallMobile(context) ? 6 : 8,
                        vertical: Responsive.isSmallMobile(context) ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getServiceTypeColor(item['item_type'])
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getServiceTypeColor(item['item_type'])
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getServiceTypeLabel(item['item_type']),
                        style: TextStyle(
                          fontSize: Responsive.isSmallMobile(context) ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: _getServiceTypeColor(item['item_type']),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallMobile) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 16.0 : 24.0),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: isSmallMobile ? 64.0 : 80.0,
            color: LottoRunnersColors.primaryYellow,
          ),
          SizedBox(height: isSmallMobile ? 16.0 : 24.0),
          Text(
            'No completed items yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: isSmallMobile ? 20.0 : 22.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8.0 : 12.0),
          Text(
            'Your completed errands and transportation bookings will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 14.0 : 16.0,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  IconData _getCategoryIcon(String? itemType) {
    switch (itemType) {
      case 'errand':
        return Icons.assignment;
      case 'transportation':
        return Icons.directions_bus;
      case 'contract':
        return Icons.description;
      default:
        return Icons.category;
    }
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'posted':
        backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.primary;
        displayStatus = 'Open';
        break;
      case 'accepted':
        backgroundColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.secondary;
        displayStatus = 'Accepted';
        break;
      case 'in_progress':
        backgroundColor = Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.tertiary;
        displayStatus = 'In Progress';
        break;
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        displayStatus = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.error;
        displayStatus = 'Cancelled';
        break;
      default:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
        displayStatus = status;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isSmallMobile(context) ? 8 : 12,
        vertical: Responsive.isSmallMobile(context) ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: Responsive.isSmallMobile(context) ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String location,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: LottoRunnersColors.primaryYellow,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Color _getServiceTypeColor(String? itemType) {
    switch (itemType) {
      case 'errand':
        return LottoRunnersColors.primaryBlue;
      case 'transportation':
        return LottoRunnersColors.primaryYellow;
      case 'contract':
        return Colors.purple;
      default:
        return LottoRunnersColors.primaryBlue;
    }
  }

  String _getServiceTypeLabel(String? itemType) {
    switch (itemType) {
      case 'errand':
        return 'Errand';
      case 'transportation':
        return 'Transport';
      case 'contract':
        return 'Contract';
      default:
        return 'Service';
    }
  }
}
