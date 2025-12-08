import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lotto_runners/utils/pdf_utils.dart';

class MyHistoryPage extends StatefulWidget {
  const MyHistoryPage({super.key});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _transportationBookings = [];
  List<Map<String, dynamic>> _contractBookings = [];
  List<Map<String, dynamic>> _busBookings = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All History', 'icon': 'history'},
    {'value': 'errands', 'label': 'My Errands', 'icon': 'assignment'},
    {'value': 'transportation', 'label': 'Transport', 'icon': 'directions_bus'},
    {'value': 'grocery', 'label': 'Grocery', 'icon': 'shopping_cart'},
    {'value': 'delivery', 'label': 'Delivery', 'icon': 'local_shipping'},
    {'value': 'document', 'label': 'Documents', 'icon': 'description'},
    {'value': 'shopping', 'label': 'Shopping', 'icon': 'shopping_bag'},
    {'value': 'other', 'label': 'Other', 'icon': 'more_horiz'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final errands = await SupabaseConfig.getMyErrands(user.id);
        final bookings = await SupabaseConfig.getUserBookings(user.id);

        // Filter for completed items only
        final completedErrands =
            errands.where((e) => e['status'] == 'completed').toList();
        final completedBookings =
            bookings.where((b) => b['status'] == 'completed').toList();

        // Separate transportation, contract, and bus bookings
        final transportationBookings = completedBookings
            .where((b) => b['booking_type'] == 'transportation')
            .toList();
        final contractBookings = completedBookings
            .where((b) => b['booking_type'] == 'contract')
            .toList();
        final busBookings =
            completedBookings.where((b) => b['booking_type'] == 'bus').toList();

        setState(() {
          _errands = completedErrands;
          _transportationBookings = transportationBookings;
          _contractBookings = contractBookings;
          _busBookings = busBookings;
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
            ...busBookings.map((b) => {
                  ...b,
                  'item_type': 'bus',
                  'title': 'Bus Service',
                  'category': 'bus',
                  'description':
                      '${b['pickup_location']} → ${b['dropoff_location']}',
                }),
          ];
          _isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      print('Error loading history: $e');
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
            .where((item) =>
                item['item_type'] == 'transportation' ||
                item['item_type'] == 'contract' ||
                item['item_type'] == 'bus')
            .toList();
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
        return theme.colorScheme.primary;
      case 'accepted':
        return theme.colorScheme.secondary;
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
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
      ),
    );
  }

  Widget _buildHeader(bool isSmallMobile, bool isMobile) {
    final theme = Theme.of(context);
    final totalItems = _allItems.length;
    final totalErrands = _errands.length;
    final totalTransportation = _transportationBookings.length;
    final totalContracts = _contractBookings.length;
    final totalBus = _busBookings.length;

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
              // Title row with refresh button - centered
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
                        color: Colors.white,
                        fontSize: isSmallMobile ? 20.0 : 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadHistory,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
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
                    count: totalTransportation + totalContracts + totalBus,
                    label: 'Transport',
                    isSmallMobile: isSmallMobile,
                    subStats: [
                      'Shuttle: $totalTransportation',
                      'Bus: $totalBus',
                      'Contract: $totalContracts',
                    ],
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
    List<String>? subStats,
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
            color: Colors.white,
            fontSize: isSmallMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isSmallMobile ? 12.0 : 14.0,
          ),
        ),
        // Add sub-stats for transport (bus breakdown)
        if (subStats != null && subStats.isNotEmpty) ...[
          SizedBox(height: isSmallMobile ? 2.0 : 4.0),
          ...subStats.map((stat) => Text(
                stat,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: isSmallMobile ? 9.0 : 10.0,
                ),
              )),
        ],
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
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search errands and bookings...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
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
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? LottoRunnersColors.primaryBlue
                              : theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallMobile ? 16.0 : 18.0,
                            ),
                          if (isSelected)
                            SizedBox(width: isSmallMobile ? 4.0 : 8.0),
                          Text(
                            category['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
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
        color: Colors.white,
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
                        item['title'] ?? '',
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

                // Runner information (for completed services)
                if (item['runner'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            color: LottoRunnersColors.primaryYellow, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['runner']['full_name'] ?? 'Runner',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.isSmallMobile(context)
                                      ? 14
                                      : 16,
                                ),
                              ),
                              if (item['runner']['phone'] != null)
                                Text(
                                  item['runner']['phone'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
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
                          'Amount Paid',
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
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
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

                // Service type indicator and completion info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed ${_formatDate(item['completed_at'] ?? item['updated_at'] ?? item['created_at'])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                const SizedBox(height: 12),

                // Download Invoice Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadInvoice(item),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LottoRunnersColors.primaryYellow,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallMobile ? 10 : 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadInvoice(Map<String, dynamic> item) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating invoice...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Generate invoice PDF
      final pdfBytes = await _generateInvoicePdf(item);
      
      // Download the PDF
      final fileName = 'invoice_${item['id']}.pdf';
      await _savePdf(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Invoice downloaded successfully!\nCheck your Downloads folder for $fileName'
                  : 'Invoice ready! Use the share dialog to save it to your device.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error downloading invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to download invoice. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<int>> _generateInvoicePdf(Map<String, dynamic> item) async {
    // Import pdf package at the top of the file
    final pdf = pw.Document();

    // Load logo
    pw.ImageProvider? logo;
    try {
      final logoBytes = await rootBundle.load('web/icons/logolotto.png');
      logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Could not load logo: $e');
    }

    // Get user profile for invoice
    final user = SupabaseConfig.currentUser;
    final userProfile = user != null ? await SupabaseConfig.getUserProfile(user.id) : null;

    final itemType = item['item_type'] ?? 'service';
    final title = item['title'] ?? 'Service';
    final amount = item['price_amount'] ?? item['final_price'] ?? item['estimated_price'] ?? 0;
    final date = item['completed_at'] ?? item['updated_at'] ?? item['created_at'];
    final description = item['description'] ?? '';
    final category = item['category']?.toString().toUpperCase() ?? itemType.toUpperCase();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with Logo
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOTTO RUNNERS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  if (logo != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(logo),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Invoice Details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(userProfile?['full_name'] ?? 'Customer'),
                    pw.Text(userProfile?['email'] ?? ''),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Invoice #: ${item['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                    pw.Text('Date: ${_formatExactDate(date)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Service Details Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Service', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(title),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(category),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('N\$${amount.toString()}'),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Description
            if (description.isNotEmpty) ...[
              pw.Text('Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(description),
              pw.SizedBox(height: 20),
            ],

            // Total
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text('N\$${amount.toString()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.blue)),
              ],
            ),
            pw.SizedBox(height: 30),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Thank you for using Lotto Runners!',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _savePdf(List<int> pdfBytes, String fileName) async {
    // Use downloadPDFBytes for proper mobile download with permissions
    final success = await PdfUtils.downloadPDFBytes(pdfBytes, fileName);
    if (!success) {
      throw Exception('Unable to download PDF to device storage. Please check your device permissions and try again.');
    }
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
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8.0 : 12.0),
          Text(
            'Your completed errands and shuttle services will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 14.0 : 16.0,
              color: theme.colorScheme.onSurfaceVariant,
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

  String _formatExactDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
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
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.primary;
        displayStatus = 'Open';
        break;
      case 'accepted':
        backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.secondary;
        displayStatus = 'Accepted';
        break;
      case 'in_progress':
        backgroundColor = theme.colorScheme.tertiary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.tertiary;
        displayStatus = 'In Progress';
        break;
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        displayStatus = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = theme.colorScheme.error.withValues(alpha: 0.1);
        textColor = theme.colorScheme.error;
        displayStatus = 'Cancelled';
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
      case 'bus':
        return Colors.orange;
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
        return 'Shuttle';
      case 'bus':
        return 'Bus';
      case 'contract':
        return 'Contract';
      default:
        return 'Service';
    }
  }
}
