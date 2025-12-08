import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/theme.dart';
import 'dart:async';

class PaymentTrackingPage extends StatefulWidget {
  const PaymentTrackingPage({super.key});

  @override
  State<PaymentTrackingPage> createState() => _PaymentTrackingPageState();
}

class _PaymentTrackingPageState extends State<PaymentTrackingPage> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedTimeRange = 'all';
  Timer? _refreshTimer;

  // Payment statistics
  Map<String, dynamic> _paymentStats = {};

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadPayments();
      }
    });
  }

  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);
      final payments = await SupabaseConfig.getAllPayments();

      // Calculate payment statistics
      _calculatePaymentStats(payments);

      setState(() {
        _payments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load payments. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _calculatePaymentStats(List<Map<String, dynamic>> payments) {
    double totalRevenue = 0;
    double pendingAmount = 0;
    double completedAmount = 0;
    double failedAmount = 0;
    int totalPayments = payments.length;
    int pendingCount = 0;
    int completedCount = 0;
    int failedCount = 0;

    for (final payment in payments) {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
      final status = payment['status'] ?? 'pending';

      totalRevenue += amount;

      switch (status) {
        case 'pending':
          pendingAmount += amount;
          pendingCount++;
          break;
        case 'completed':
          completedAmount += amount;
          completedCount++;
          break;
        case 'failed':
          failedAmount += amount;
          failedCount++;
          break;
      }
    }

    _paymentStats = {
      'total_revenue': totalRevenue,
      'pending_amount': pendingAmount,
      'completed_amount': completedAmount,
      'failed_amount': failedAmount,
      'total_payments': totalPayments,
      'pending_count': pendingCount,
      'completed_count': completedCount,
      'failed_count': failedCount,
    };
  }

  void _filterPayments(String query, String status, String timeRange) {
    setState(() {
      _searchQuery = query;
      _selectedStatus = status;
      _selectedTimeRange = timeRange;

      _filteredPayments = _payments.where((payment) {
        // Search filter
        final matchesSearch = query.isEmpty ||
            (payment['errand']?['title'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (payment['customer']?['full_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (payment['runner']?['full_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (payment['transaction_id'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        // Status filter
        final matchesStatus = status == 'all' || payment['status'] == status;

        // Time range filter
        final matchesTimeRange = _matchesTimeRange(payment, timeRange);

        return matchesSearch && matchesStatus && matchesTimeRange;
      }).toList();
    });
  }

  bool _matchesTimeRange(Map<String, dynamic> payment, String timeRange) {
    if (timeRange == 'all') return true;

    final createdAt = payment['created_at'];
    if (createdAt == null) return false;

    final paymentDate = DateTime.tryParse(createdAt);
    if (paymentDate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(paymentDate);

    switch (timeRange) {
      case 'today':
        return difference.inDays == 0;
      case 'week':
        return difference.inDays <= 7;
      case 'month':
        return difference.inDays <= 30;
      case 'year':
        return difference.inDays <= 365;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Tracking'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Refresh Payments',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPaymentStats(),
                    _buildFilters(),
                    _buildPaymentsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentStats() {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24), // Reduced mobile padding
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
              children: [
                // First row: Total Revenue and Completed
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Revenue',
                        'N\$${_paymentStats['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.attach_money,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced spacing between columns
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        'N\$${_paymentStats['completed_amount']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.check_circle,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced spacing between rows
                // Second row: Pending and Failed
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        'N\$${_paymentStats['pending_amount']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.pending,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced spacing between columns
                    Expanded(
                      child: _buildStatCard(
                        'Failed',
                        'N\$${_paymentStats['failed_amount']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.error,
                        Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    'N\$${_paymentStats['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.attach_money,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    'N\$${_paymentStats['completed_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.check_circle,
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    'N\$${_paymentStats['pending_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.pending,
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Failed',
                    'N\$${_paymentStats['failed_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.error,
                    Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
          isMobile ? 16 : 32), // Reduced mobile padding from 28 to 16
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ensure minimum size
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                    isMobile ? 4 : 8), // Reduced mobile padding from 6 to 4
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: color,
                    size: isMobile
                        ? 14
                        : 20), // Reduced mobile icon size from 16 to 14
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isMobile
                            ? 10
                            : 12, // Reduced mobile font size from 11 to 10
                      ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(
              height:
                  isMobile ? 10 : 18), // Reduced mobile spacing from 14 to 10
          Flexible(
            child: Text(
              value,
              style: (isMobile
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isMobile
                    ? 18
                    : 22, // Reduced mobile font size from 20 to 18
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
          isMobile ? 12 : 24), // Reduced mobile padding from 16 to 12
      child: isMobile
          ? Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8), // Reduced spacing from 12 to 8
                Row(
                  children: [
                    Expanded(child: _buildStatusFilter()),
                    const SizedBox(width: 8), // Reduced spacing from 12 to 8
                    Expanded(child: _buildTimeFilter()),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 16),
                _buildStatusFilter(),
                const SizedBox(width: 16),
                _buildTimeFilter(),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    final isMobile = Responsive.isMobile(context);

    return TextField(
      onChanged: (value) =>
          _filterPayments(value, _selectedStatus, _selectedTimeRange),
      decoration: InputDecoration(
        hintText: 'Search payments...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile
              ? 10
              : 16, // Reduced mobile horizontal padding from 12 to 10
          vertical:
              isMobile ? 8 : 16, // Reduced mobile vertical padding from 12 to 8
        ),
        isDense: true, // Always use dense mode for better space efficiency
      ),
    );
  }

  Widget _buildStatusFilter() {
    final isMobile = Responsive.isMobile(context);

    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile
              ? 10
              : 16, // Reduced mobile horizontal padding from 12 to 10
          vertical:
              isMobile ? 8 : 16, // Reduced mobile vertical padding from 12 to 8
        ),
        isDense: true, // Always use dense mode for better space efficiency
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Status')),
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
        DropdownMenuItem(value: 'failed', child: Text('Failed')),
      ],
      onChanged: (value) {
        if (value != null) {
          _filterPayments(_searchQuery, value, _selectedTimeRange);
        }
      },
    );
  }

  Widget _buildTimeFilter() {
    final isMobile = Responsive.isMobile(context);

    return DropdownButtonFormField<String>(
      initialValue: _selectedTimeRange,
      decoration: InputDecoration(
        labelText: 'Time Range',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile
              ? 10
              : 16, // Reduced mobile horizontal padding from 12 to 10
          vertical:
              isMobile ? 8 : 16, // Reduced mobile vertical padding from 12 to 8
        ),
        isDense: true, // Always use dense mode for better space efficiency
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Time')),
        DropdownMenuItem(value: 'today', child: Text('Today')),
        DropdownMenuItem(value: 'week', child: Text('This Week')),
        DropdownMenuItem(value: 'month', child: Text('This Month')),
        DropdownMenuItem(value: 'year', child: Text('This Year')),
      ],
      onChanged: (value) {
        if (value != null) {
          _filterPayments(_searchQuery, _selectedStatus, value);
        }
      },
    );
  }

  Widget _buildPaymentsList() {
    final theme = Theme.of(context);
    if (_filteredPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 24),
      child: Column(
        children: _filteredPayments
            .map((payment) => _buildPaymentCard(payment))
            .toList(),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'pending';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = theme.colorScheme.secondary;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(
          bottom: Responsive.isMobile(context)
              ? 12
              : 16), // Reduced mobile margin from 16 to 12
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPaymentDetails(payment),
        child: Padding(
          padding: EdgeInsets.all(Responsive.isMobile(context)
              ? 16
              : 20), // Reduced mobile padding from 20 to 16
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.isMobile(context)
                    ? 8
                    : 12), // Reduced mobile padding from 12 to 8
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon,
                    color: statusColor,
                    size: Responsive.isMobile(context)
                        ? 20
                        : 24), // Reduced mobile icon size from 24 to 20
              ),
              SizedBox(
                  width: Responsive.isMobile(context)
                      ? 12
                      : 16), // Reduced mobile spacing from 16 to 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['errand']?['title'] ?? 'Unknown Errand',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                        height: Responsive.isMobile(context)
                            ? 2
                            : 4), // Reduced mobile spacing from 4 to 2
                    Text(
                      'Customer: ${payment['customer']?['full_name'] ?? 'Unknown'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (payment['runner'] != null) ...[
                      SizedBox(
                          height: Responsive.isMobile(context)
                              ? 2
                              : 4), // Reduced mobile spacing from 4 to 2
                      Text(
                        'Runner: ${payment['runner']?['full_name'] ?? 'Unknown'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'N\$${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(
                      height: Responsive.isMobile(context)
                          ? 2
                          : 4), // Reduced mobile spacing from 4 to 2
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isMobile(context)
                          ? 6
                          : 8, // Reduced mobile horizontal padding from 8 to 6
                      vertical: Responsive.isMobile(context)
                          ? 2
                          : 4, // Reduced mobile vertical padding from 4 to 2
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Payment ID', payment['id'] ?? 'N/A'),
              _buildDetailRow('Amount', 'N\$${payment['amount'] ?? '0.00'}'),
              _buildDetailRow(
                  'Status', _formatStatus(payment['status'] ?? 'N/A')),
              _buildDetailRow(
                  'Payment Method', payment['payment_method'] ?? 'N/A'),
              if (payment['transaction_id'] != null)
                _buildDetailRow('Transaction ID', payment['transaction_id']),
              if (payment['stripe_payment_intent_id'] != null)
                _buildDetailRow(
                    'Stripe Intent ID', payment['stripe_payment_intent_id']),
              if (payment['errand'] != null) ...[
                const Divider(),
                _buildDetailRow(
                    'Errand Title', payment['errand']['title'] ?? 'N/A'),
                _buildDetailRow(
                    'Errand Category', payment['errand']['category'] ?? 'N/A'),
              ],
              if (payment['customer'] != null) ...[
                const Divider(),
                _buildDetailRow(
                    'Customer Name', payment['customer']['full_name'] ?? 'N/A'),
                _buildDetailRow(
                    'Customer Email', payment['customer']['email'] ?? 'N/A'),
              ],
              if (payment['runner'] != null) ...[
                const Divider(),
                _buildDetailRow(
                    'Runner Name', payment['runner']['full_name'] ?? 'N/A'),
                _buildDetailRow(
                    'Runner Email', payment['runner']['email'] ?? 'N/A'),
              ],
              if (payment['created_at'] != null)
                _buildDetailRow(
                    'Created At', _formatDate(payment['created_at'])),
              if (payment['updated_at'] != null)
                _buildDetailRow(
                    'Updated At', _formatDate(payment['updated_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            width: 120,
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

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'completed':
        return '✅ Completed';
      case 'failed':
        return '❌ Failed';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }
}
