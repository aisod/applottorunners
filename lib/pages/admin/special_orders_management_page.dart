import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Admin Special Orders Management Page
/// Allows admins to view special order requests, set prices, and send quotes to customers
class SpecialOrdersManagementPage extends StatefulWidget {
  const SpecialOrdersManagementPage({super.key});

  @override
  State<SpecialOrdersManagementPage> createState() => _SpecialOrdersManagementPageState();
}

class _SpecialOrdersManagementPageState extends State<SpecialOrdersManagementPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _quotedOrders = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: _selectedTab);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseConfig.getSpecialOrdersForAdmin();
      
      setState(() {
        _pendingOrders = orders.where((order) => 
          order['status'] == 'pending_price').toList();
        _quotedOrders = orders.where((order) => 
          order['status'] == 'price_quoted').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load orders. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPriceDialog(Map<String, dynamic> order) {
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Price for Special Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order: ${order['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (N\$)',
                  hintText: 'Enter price amount',
                  prefixText: 'N\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
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
              final priceText = priceController.text.trim();
              if (priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a price')),
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price')),
                );
                return;
              }

              Navigator.pop(context);
              await _setPrice(order, price);
            },
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );
  }

  Future<void> _setPrice(Map<String, dynamic> order, double price) async {
    try {
      await SupabaseConfig.setSpecialOrderPrice(
        order['id'], 
        price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price quote sent to customer!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to set price. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      order['title'] ?? 'Special Order',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Info
                    _buildDetailSection(
                      'Customer Information',
                      [
                        _buildDetailRow('Name', order['customer']?['full_name'] ?? 'N/A'),
                        _buildDetailRow('Phone', order['customer']?['phone'] ?? 'N/A'),
                        _buildDetailRow('Email', order['customer']?['email'] ?? 'N/A'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Order Details
                    _buildDetailSection(
                      'Order Details',
                      [
                        _buildDetailRow('Description', order['description'] ?? 'No description'),
                        if (order['location_address'] != null)
                          _buildDetailRow('Location', order['location_address']),
                        if (order['pickup_address'] != null)
                          _buildDetailRow('Pickup', order['pickup_address']),
                        if (order['delivery_address'] != null)
                          _buildDetailRow('Delivery', order['delivery_address']),
                        if (order['special_instructions'] != null)
                          _buildDetailRow('Instructions', order['special_instructions']),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Current Status
                    _buildDetailSection(
                      'Status',
                      [
                        _buildDetailRow('Current Status', _getStatusText(order['status'])),
                        if (order['price_amount'] != null)
                          _buildDetailRow('Quoted Price', 'N\$${order['price_amount'].toStringAsFixed(2)}'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    if (order['status'] == 'pending_price')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPriceDialog(order);
                          },
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Set Price'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: LottoRunnersColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending_price':
        return 'Pending Price Quote';
      case 'price_quoted':
        return 'Price Quoted - Awaiting Customer Approval';
      case 'pending':
        return 'Approved - Available for Runners';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Special Orders Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallMobile ? 16 : 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: LottoRunnersColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pending (${_pendingOrders.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Quoted (${_quotedOrders.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_pendingOrders, isPending: true),
                _buildOrdersList(_quotedOrders, isPending: false),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {required bool isPending}) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPending ? Icons.inbox : Icons.check_circle,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isPending
                    ? 'No pending special orders'
                    : 'No quoted orders awaiting approval',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPending ? Colors.orange : Colors.green,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => _showOrderDetails(order),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPending ? Icons.pending_actions : Icons.check_circle,
                          color: isPending ? Colors.orange : Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['title'] ?? 'Special Order',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: ${order['customer']?['full_name'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPending)
                        IconButton(
                          onPressed: () => _showPriceDialog(order),
                          icon: const Icon(Icons.attach_money),
                          color: LottoRunnersColors.primaryBlue,
                          tooltip: 'Set Price',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (order['description'] != null)
                    Text(
                      order['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (!isPending && order['price_amount'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Quoted: N\$${order['price_amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



