import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/errand_card.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/pages/chat_page.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/page_transitions.dart';
import 'package:lotto_runners/pages/paytoday_payment_page.dart';
import 'package:lotto_runners/services/paytoday_config.dart';

class MyErrandsPage extends StatefulWidget {
  const MyErrandsPage({super.key});

  @override
  State<MyErrandsPage> createState() => _MyErrandsPageState();
}

class _MyErrandsPageState extends State<MyErrandsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _errands = [];
  bool _isLoading = true;
  late TabController _tabController;
  Timer? _refreshTimer;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMyErrands();
    _startAutoRefresh();
  }

  Future<void> _showCancelErrandDialog(Map<String, dynamic> errand) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text(
          'Are you sure you want to cancel "${errand['title'] ?? 'this request'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.cancelErrand(
          errand['id'],
          cancelledBy: SupabaseConfig.currentUser?.id,
          reason: 'Cancelled by customer',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadMyErrands();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling request: $e'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 5 minutes to reduce database load significantly
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadMyErrands();
      }
    });
  }

  Future<void> _loadMyErrands({bool forceRefresh = false}) async {
    // Aggressive cache: don't reload if data is less than 2 minutes old
    if (!forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inMinutes < 2) {
      return;
    }

    try {
      // Only show loading if we don't have cached data
      if (_errands.isEmpty) {
        setState(() {
          _isLoading = true;
        });
      }

      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final errands = await SupabaseConfig.getMyErrands(user.id);
        setState(() {
          _errands = errands;
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading errands: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Map<String, dynamic> _calculatePaymentStatus(Map<String, dynamic> errand) {
    final transactions = (errand['paytoday_transactions'] as List?) ?? [];
    double totalPaid = 0.0;
    
    for (var tx in transactions) {
      // Consider successful statuses
      final status = tx['status']?.toString().toLowerCase();
      if (status == 'paid' || status == 'captured' || status == 'verified' || status == 'completed') {
        totalPaid += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    
    final price = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'totalPaid': totalPaid,
      'hasFirstPayment': price > 0 && totalPaid >= (price / 2) - 1.0, // Small tolerance
      'hasFullPayment': price > 0 && totalPaid >= price - 1.0,
    };
  }

  Future<void> _handlePayment(Map<String, dynamic> errand, double amount, String paymentType) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayTodayPaymentPage(
          errandId: errand['id'],
          amount: amount,
          paymentType: paymentType,
          customerId: SupabaseConfig.currentUser?.id ?? '',
          runnerId: errand['runner_id'],
          onSuccess: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Updating status...'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Wait for DB trigger/edge function to process
            await Future.delayed(const Duration(seconds: 2));
            _loadMyErrands(forceRefresh: true);
          },
          onFailure: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        ),
      ),
    );

    if (success == true) {
      _loadMyErrands(forceRefresh: true);
    }
  }

  /// Public method to refresh errands from parent widget
  Future<void> refresh() async {
    await _loadMyErrands(forceRefresh: true);
  }

  void _showErrandDetails(Map<String, dynamic> errand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildErrandDetailsSheet(errand),
    );
  }

  void _updateErrandStatus(Map<String, dynamic> errand) {
    // Implementation for updating errand status
    print('Updating errand status: ${errand['id']}');
  }

  Future<void> _approvePrice(Map<String, dynamic> errand) async {
    try {
      print('🎯 Approving price for errand: ${errand['id']}');
      print('🎯 Current status: ${errand['status']}');
      
      await SupabaseConfig.approveSpecialOrderPrice(errand['id']);
      
      if (mounted) {
        Navigator.pop(context); // Close details sheet
        
        // Give database a moment to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh to get updated status
        await _loadMyErrands(forceRefresh: true);
        
        // Log the updated errands
        final approvedErrand = _errands.firstWhere(
          (e) => e['id'] == errand['id'],
          orElse: () => {},
        );
        print('🎯 After refresh - Errand status: ${approvedErrand['status']}');
        print('🎯 Total errands in list: ${_errands.length}');
        print('🎯 Posted errands: ${_errands.where((e) => e['status'] == 'posted').length}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Price approved! Your order is now available to runners.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error approving price: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to approve price. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectPrice(Map<String, dynamic> errand) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Price Quote?'),
        content: const Text('Are you sure you want to reject this price? This will cancel the order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.rejectSpecialOrderPrice(errand['id']);
        
        if (mounted) {
          Navigator.pop(context); // Close details sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadMyErrands(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to reject price. Please check your internet connection and try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending_price':
        return 'Awaiting Price Quote';
      case 'price_quoted':
        return 'Price Quote Received';
      case 'posted':
        return 'Waiting for Runner';
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

  /// Open chat with runner or customer
  void _openChat(Map<String, dynamic> errand) async {
    final isCustomer = errand['customer_id'] == SupabaseConfig.currentUser?.id;
    final runnerId = errand['runner_id'];
    final customerId = errand['customer_id'];

    if (isCustomer && runnerId != null) {
      // Customer chatting with runner
      try {
        // Get or create conversation
        final conversation =
            await ChatService.getConversationByErrand(errand['id']);

        if (conversation != null) {
          Navigator.push(
            context,
            PageTransitions.slideFromBottom(
              ChatPage(
                conversationId: conversation['id'],
                conversationType: 'errand',
                errandId: errand['id'],
                otherUserName: errand['runner_name'] ?? 'Runner',
                serviceTitle: errand['title'] ?? 'Errand',
              ),
            ),
          );
        } else {
          // Create new conversation if it doesn't exist
          final conversationId = await ChatService.createConversation(
            errandId: errand['id'],
            customerId: errand['customer_id'],
            runnerId: errand['runner_id'],
          );

          if (conversationId != null) {
            Navigator.push(
              context,
              PageTransitions.slideFromBottom(
                ChatPage(
                  conversationId: conversationId,
                  conversationType: 'errand',
                  errandId: errand['id'],
                  otherUserName: errand['runner_name'] ?? 'Runner',
                  serviceTitle: errand['title'] ?? 'Errand',
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error opening chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening chat: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else if (!isCustomer && customerId != null) {
      // Runner chatting with customer
      try {
        // Get or create conversation
        final conversation =
            await ChatService.getConversationByErrand(errand['id']);

        if (conversation != null) {
          Navigator.push(
            context,
            PageTransitions.slideFromBottom(
              ChatPage(
                conversationId: conversation['id'],
                conversationType: 'errand',
                errandId: errand['id'],
                otherUserName: errand['customer_name'] ?? 'Customer',
                serviceTitle: errand['title'] ?? 'Errand',
              ),
            ),
          );
        } else {
          // Create new conversation if it doesn't exist
          final conversationId = await ChatService.createConversation(
            errandId: errand['id'],
            customerId: errand['customer_id'],
            runnerId: errand['runner_id'],
          );

          if (conversationId != null) {
            Navigator.push(
              context,
              PageTransitions.slideFromBottom(
                ChatPage(
                  conversationId: conversationId,
                  conversationType: 'errand',
                  errandId: errand['id'],
                  otherUserName: errand['customer_name'] ?? 'Customer',
                  serviceTitle: errand['title'] ?? 'Errand',
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error opening chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening chat: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with refresh button
        // Container(
        //   padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         'Errands',
        //         style: TextStyle(
        //           color: theme.colorScheme.onSurface,
        //           fontWeight: FontWeight.bold,
        //           fontSize: isSmallMobile ? 16 : 18,
        //         ),
        //       ),
        //       IconButton(
        //         onPressed: _loadMyErrands,
        //         icon: Icon(
        //           Icons.refresh,
        //           color: theme.colorScheme.primary,
        //           size: isSmallMobile ? 20 : 24,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // Tab bar
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              // fontSize: isSmallMobile ? 11 : 12,
            ),
            isScrollable: true,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Accepted'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
              Tab(text: 'All'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildErrandsList(['posted', 'pending', 'pending_price', 'price_quoted'], 'active', theme),
                    _buildErrandsList(['accepted'], 'accepted', theme),
                    _buildErrandsList(['in_progress'], 'in_progress', theme),
                    _buildErrandsList(['completed'], 'completed', theme),
                    _buildErrandsList(
                        ['posted', 'pending', 'pending_price', 'price_quoted', 'accepted', 'in_progress', 'completed'], 'all', theme),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildErrandsList(
      List<String> statusFilter, String tabType, ThemeData theme) {
    print('📋 Building errands list for tab: $tabType');
    print('📋 Status filter: $statusFilter');
    print('📋 Total errands: ${_errands.length}');
    
    final filteredErrands = _errands.where((errand) {
      final matches = statusFilter.contains(errand['status']);
      if (errand['category'] == 'special_orders') {
        print('📋 Special order ${errand['id']}: status=${errand['status']}, matches=$matches');
      }
      return matches;
    }).toList();
    
    print('📋 Filtered errands for $tabType: ${filteredErrands.length}');

    if (filteredErrands.isEmpty) {
      return _buildEmptyState(tabType, theme);
    }

    return RefreshIndicator(
      onRefresh: _loadMyErrands,
      child: ListView.builder(
        padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 16 : 24),
        itemCount: filteredErrands.length,
        itemBuilder: (context, index) {
          final errand = filteredErrands[index];
          final isCustomer =
              errand['customer_id'] == SupabaseConfig.currentUser?.id;

          // Calculate payment status
          bool showPayButton = false;
          String? payButtonText;
          VoidCallback? onPay;

          if (isCustomer) {
            final paymentStatus = _calculatePaymentStatus(errand);
            final price = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;
            
            if (errand['status'] == 'accepted' && !(paymentStatus['hasFirstPayment'] as bool)) {
              showPayButton = true;
              payButtonText = 'Pay Deposit (50%)';
              onPay = () => _handlePayment(errand, price / 2, PayTodayConfig.paymentTypeFirstHalf);
            } else if (errand['status'] == 'completed' && !(paymentStatus['hasFullPayment'] as bool)) {
              showPayButton = true;
              payButtonText = 'Pay Balance (50%)';
              // Calculate remaining amount precisely: price - totalPaid
              final remaining = price - (paymentStatus['totalPaid'] as double);
              onPay = () => _handlePayment(errand, remaining > 0 ? remaining : price / 2, PayTodayConfig.paymentTypeSecondHalf);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.isSmallMobile(context) ? 16 : 16,
            ),
            child: ErrandCard(
              errand: errand,
              onTap: () => _showErrandDetails(errand),
              showStatusUpdate: !isCustomer &&
                  (errand['status'] == 'accepted' ||
                      errand['status'] == 'in_progress'),
              onStatusUpdate: () => _updateErrandStatus(errand),
              showChatButton: errand['status'] == 'accepted' ||
                  errand['status'] == 'in_progress',
              onChat: () => _openChat(errand),
              showCancelButton: isCustomer &&
                  (errand['status'] == 'posted' ||
                      errand['status'] == 'accepted'),
              onCancel: () => _showCancelErrandDialog(errand),
              showPayButton: showPayButton,
              onPay: onPay,
              payButtonText: payButtonText,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String tabType, ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    String title;
    String message;
    IconData icon;

    switch (tabType) {
      case 'active':
        title = 'No Active Errands';
        message = 'You don\'t have any open errands at the moment.';
        icon = Icons.assignment_outlined;
        break;
      case 'accepted':
        title = 'No Accepted Errands';
        message = 'You have no errands that have been accepted yet.';
        icon = Icons.assignment_turned_in_outlined;
        break;
      case 'in_progress':
        title = 'No Errands in Progress';
        message = 'No errands are currently being processed.';
        icon = Icons.pending_outlined;
        break;
      case 'completed':
        title = 'No Completed Errands';
        message = 'You haven\'t completed any errands yet.';
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'No Errands Found';
        message = 'You don\'t have any errands in your history.';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallMobile ? 48 : 64,
              color: LottoRunnersColors.primaryYellow,
            ),
            SizedBox(height: isSmallMobile ? 16 : 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: LottoRunnersColors.primaryYellow,
                fontSize: isSmallMobile ? 18 : 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallMobile ? 8 : 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: isSmallMobile ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrandDetailsSheet(Map<String, dynamic> errand) {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: isSmallMobile ? 8 : 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errand['title'] ?? 'Untitled Errand',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallMobile ? 18 : 20,
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 12 : 16),
                  Text(
                    errand['description'] ?? 'No description available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallMobile ? 13 : 14,
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 16 : 24),
                  _buildDetailRow(
                      'Status', _getStatusDisplayText(errand['status'] ?? 'Unknown'), theme),
                  _buildDetailRow(
                      'Category', errand['category'] ?? 'General', theme),
                  
                  // Show quoted price for special orders with price_quoted status
                  if (errand['status'] == 'price_quoted' && errand['price_amount'] != null) ...[
                    SizedBox(height: isSmallMobile ? 16 : 24),
                    Container(
                      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: LottoRunnersColors.primaryYellow,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.price_check,
                                color: LottoRunnersColors.primaryYellow,
                                size: isSmallMobile ? 20 : 24,
                              ),
                              SizedBox(width: isSmallMobile ? 8 : 12),
                              Text(
                                'Price Quote Received',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallMobile ? 14 : 16,
                                  color: LottoRunnersColors.primaryYellow,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallMobile ? 8 : 12),
                          Text(
                            'Admin has set a price for your special order:',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 12 : 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: isSmallMobile ? 4 : 8),
                          Text(
                            'N\$${errand['price_amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallMobile ? 24 : 28,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 16 : 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approvePrice(errand),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallMobile ? 12 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallMobile ? 8 : 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rejectPrice(errand),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallMobile ? 12 : 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildDetailRow(
                        'Budget', '₦${errand['budget'] ?? '0'}', theme),
                  ],
                  
                  if (errand['pickup_location'] != null)
                    _buildDetailRow('Pickup', errand['pickup_location'], theme),
                  if (errand['dropoff_location'] != null)
                    _buildDetailRow(
                        'Dropoff', errand['dropoff_location'], theme),

                  // Show waiting message for pending_price status
                  if (errand['status'] == 'pending_price') ...[
                    SizedBox(height: isSmallMobile ? 16 : 24),
                    Container(
                      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.blue,
                            size: isSmallMobile ? 20 : 24,
                          ),
                          SizedBox(width: isSmallMobile ? 8 : 12),
                          Expanded(
                            child: Text(
                              'Waiting for admin to set price for this special order',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 12 : 13,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Show approved message for special orders that customer approved
                  if ((errand['status'] == 'posted' || errand['status'] == 'pending') && errand['category'] == 'special_orders') ...[
                    SizedBox(height: isSmallMobile ? 16 : 24),
                    Container(
                      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: isSmallMobile ? 20 : 24,
                              ),
                              SizedBox(width: isSmallMobile ? 8 : 12),
                              Expanded(
                                child: Text(
                                  'Order Approved & Available to Runners',
                                  style: TextStyle(
                                    fontSize: isSmallMobile ? 14 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallMobile ? 8 : 12),
                          Text(
                            'You approved the price of N\$${errand['price_amount']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 12 : 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: isSmallMobile ? 4 : 6),
                          Text(
                            'Your order is now visible to runners. You will be notified when a runner accepts it.',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 12 : 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Chat button for accepted/in-progress errands
                  if (errand['status'] == 'accepted' ||
                      errand['status'] == 'in_progress') ...[
                    SizedBox(height: isSmallMobile ? 16 : 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details sheet
                          _openChat(errand);
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Open Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallMobile ? 12 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallMobile ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallMobile ? 80 : 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isSmallMobile ? 12 : 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallMobile ? 12 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
