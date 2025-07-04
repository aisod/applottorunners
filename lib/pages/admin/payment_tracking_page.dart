import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

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

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);
      final payments = await SupabaseConfig.getAllPayments();
      setState(() {
        _payments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    }
  }

  void _filterPayments(String query, String status) {
    setState(() {
      _searchQuery = query;
      _selectedStatus = status;

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

        return matchesSearch && matchesStatus;
      }).toList();
    });
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
                _buildDetailRow('Errand',
                    '${payment['errand']['title']} (${payment['errand']['category']})'),
              ],
              if (payment['customer'] != null)
                _buildDetailRow('Customer',
                    '${payment['customer']['full_name']} (${payment['customer']['email']})'),
              if (payment['runner'] != null)
                _buildDetailRow('Runner',
                    '${payment['runner']['full_name']} (${payment['runner']['email']})'),
              _buildDetailRow('Created', _formatDate(payment['created_at'])),
              if (payment['completed_at'] != null)
                _buildDetailRow(
                    'Completed', _formatDate(payment['completed_at'])),
              if (payment['refunded_at'] != null) ...[
                _buildDetailRow(
                    'Refunded', _formatDate(payment['refunded_at'])),
                _buildDetailRow('Refund Amount',
                    'N\$${payment['refund_amount'] ?? '0.00'}'),
              ],
            ],
          ),
        ),
        actions: [
          if (payment['status'] == 'completed' &&
              payment['refunded_at'] == null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRefundDialog(payment);
              },
              icon: const Icon(Icons.undo, color: Colors.red),
              label: const Text('Issue Refund',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(Map<String, dynamic> payment) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Original Amount: N\$${payment['amount']}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                prefixText: 'N\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Refund',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(
                  payment, amountController.text, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Issue Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(
      Map<String, dynamic> payment, String amount, String reason) async {
    try {
      // This would integrate with Stripe API for actual refund processing
      // For now, we'll just update the database record

      final refundAmount = double.tryParse(amount) ?? 0.0;
      if (refundAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid refund amount')),
        );
        return;
      }

      // In a real implementation, you would call Stripe API here
      // await StripeService.processRefund(payment['stripe_payment_intent_id'], refundAmount);

      // Update the payment record
      await SupabaseConfig.client.from('payments').update({
        'status': 'refunded',
        'refunded_at': DateTime.now().toIso8601String(),
        'refund_amount': refundAmount,
      }).eq('id', payment['id']);

      _loadPayments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Refund of \$${refundAmount.toStringAsFixed(2)} processed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing refund: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
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
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.undo;
      default:
        return Icons.help_outline;
    }
  }

  double _calculateTotalRevenue() {
    return _filteredPayments
        .where((payment) => payment['status'] == 'completed')
        .fold(
            0.0, (sum, payment) => sum + (payment['amount'] as num).toDouble());
  }

  double _calculateTotalRefunds() {
    return _filteredPayments
        .where((payment) => payment['status'] == 'refunded')
        .fold(
            0.0,
            (sum, payment) =>
                sum + (payment['refund_amount'] as num? ?? 0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _calculateTotalRevenue();
    final totalRefunds = _calculateTotalRefunds();

    return Scaffold(
      body: Column(
        children: [
          // Stats Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Revenue',
                        'N\$${totalRevenue.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Refunds',
                        'N\$${totalRefunds.toStringAsFixed(2)}',
                        Icons.undo,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search by errand, customer, runner, or transaction ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => _filterPayments(value, _selectedStatus),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Pending', 'pending'),
                      _buildFilterChip('Completed', 'completed'),
                      _buildFilterChip('Failed', 'failed'),
                      _buildFilterChip('Refunded', 'refunded'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No payments found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPayments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterPayments(_searchQuery, selected ? value : 'all');
        },
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final amount = payment['amount'] as num? ?? 0;

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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'N\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (payment['errand'] != null)
                        Text(
                          payment['errand']['title'] ?? 'Unknown Errand',
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
                if (payment['customer'] != null) ...[
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    payment['customer']['full_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                if (payment['runner'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.directions_run, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    payment['runner']['full_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(payment['created_at']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (payment['transaction_id'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Transaction ID: ${payment['transaction_id']}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPaymentDetails(payment),
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
