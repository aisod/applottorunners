import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:lotto_runners/pages/chat_page.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/utils/page_transitions.dart';
import 'package:lotto_runners/pages/paytoday_payment_page.dart';
import 'package:lotto_runners/services/paytoday_config.dart';

class MyTransportationRequestsPage extends StatefulWidget {
  const MyTransportationRequestsPage({super.key});

  @override
  State<MyTransportationRequestsPage> createState() =>
      _MyTransportationRequestsPageState();
}

class _MyTransportationRequestsPageState
    extends State<MyTransportationRequestsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMyBookings();
    _startAutoRefresh();
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
        _loadMyBookings();
      }
    });
  }

  Future<void> _loadMyBookings({bool forceRefresh = false}) async {
    print('🚀 DEBUG: [MY TRANSPORTATION REQUESTS] _loadMyBookings called');
    print(
        '🔄 DEBUG: [MY TRANSPORTATION REQUESTS] Force refresh: $forceRefresh');

    // Aggressive cache: don't reload if data is less than 2 minutes old
    if (!forceRefresh &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inMinutes < 2) {
      print(
          '⏭️ DEBUG: [MY TRANSPORTATION REQUESTS] Skipping reload - data is fresh (${DateTime.now().difference(_lastLoadTime!).inMinutes} minutes old)');
      return;
    }

    try {
      // Only show loading if we don't have cached data
      if (_bookings.isEmpty) {
        print(
            '⏳ DEBUG: [MY TRANSPORTATION REQUESTS] Showing loading indicator');
        setState(() => _isLoading = true);
      }

      final userId = SupabaseConfig.currentUser?.id;
      print('👤 DEBUG: [MY TRANSPORTATION REQUESTS] Current user ID: $userId');

      if (userId != null) {
        print(
            '📡 DEBUG: [MY TRANSPORTATION REQUESTS] Calling getUserBookings...');
        // Driver profiles are now fetched in the getUserBookings method
        final bookings = await SupabaseConfig.getUserBookings(userId);

        print(
            '✅ DEBUG: [MY TRANSPORTATION REQUESTS] Received ${bookings.length} bookings from getUserBookings');

        // Log detailed information about each booking
        for (var i = 0; i < bookings.length; i++) {
          final booking = bookings[i];
          print('📋 DEBUG: [MY TRANSPORTATION REQUESTS] Booking #${i + 1}:');
          print('   - ID: ${booking['id']}');
          print('   - Type: ${booking['booking_type']}');
          print('   - Status: ${booking['status']}');
          print('   - Title: ${booking['title']}');
          print('   - Pickup: ${booking['pickup_location']}');
          print('   - Dropoff: ${booking['dropoff_location']}');
          print(
              '   - Vehicle type: ${booking['vehicle_type']?['name'] ?? booking['vehicle_name'] ?? 'N/A'}');
          print('   - Service: ${booking['service']?['name'] ?? 'N/A'}');
          print(
              '   - Driver: ${booking['driver']?['full_name'] ?? 'No driver'}');
          print('   - Created: ${booking['created_at']}');
        }

        if (mounted) {
          print(
              '✅ DEBUG: [MY TRANSPORTATION REQUESTS] Updating state with ${bookings.length} bookings');
          setState(() {
            _bookings = bookings;
            _isLoading = false;
            _lastLoadTime = DateTime.now();
          });
          print(
              '✅ DEBUG: [MY TRANSPORTATION REQUESTS] State updated successfully');
        } else {
          print(
              '⚠️ DEBUG: [MY TRANSPORTATION REQUESTS] Widget not mounted - skipping state update');
        }
      } else {
        print(
            '❌ DEBUG: [MY TRANSPORTATION REQUESTS] No user ID - cannot load bookings');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: [MY TRANSPORTATION REQUESTS] Error loading bookings');
      print(
          '❌ DEBUG: [MY TRANSPORTATION REQUESTS] Error type: ${e.runtimeType}');
      print('❌ DEBUG: [MY TRANSPORTATION REQUESTS] Error message: $e');
      print('❌ DEBUG: [MY TRANSPORTATION REQUESTS] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transportation requests: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Public method to refresh bookings from parent widget
  Future<void> refresh() async {
    await _loadMyBookings(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with refresh button
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         'Transport',
        //         style: TextStyle(
        //           color: theme.colorScheme.onSurface,
        //           fontWeight: FontWeight.bold,
        //           fontSize: 18,
        //         ),
        //       ),
        //       IconButton(
        //         onPressed: _loadMyBookings,
        //         icon: Icon(
        //           Icons.refresh,
        //           color: theme.colorScheme.primary,
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
                    _buildBookingsList(
                        ['pending', 'accepted', 'confirmed'], 'active', theme),
                    _buildBookingsList(
                        ['accepted', 'confirmed'], 'accepted', theme),
                    _buildBookingsList(['in_progress'], 'in_progress', theme),
                    _buildBookingsList(['completed'], 'completed', theme),
                    _buildBookingsList([
                      'pending',
                      'accepted',
                      'confirmed',
                      'in_progress',
                      'completed'
                    ], 'all', theme),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(
      List<String> statuses, String tabType, ThemeData theme) {
    final filteredBookings = _bookings
        .where((booking) => statuses.contains(booking['status']))
        .toList();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(tabType, theme);
    }

    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        padding:
            EdgeInsets.all(Responsive.isSmallMobile(context) ? 16.0 : 24.0),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(booking, theme);
        },
      ),
    );
  }

  Widget _buildEmptyState(String tabType, ThemeData theme) {
    String title;
    String message;
    IconData icon;

    switch (tabType) {
      case 'active':
        title = 'No Active Requests';
        message =
            'You don\'t have any active transportation requests (pending, accepted, or confirmed).';
        icon = Icons.directions_car;
        break;
      case 'accepted':
        title = 'No Accepted Requests';
        message =
            'You have no transportation requests that have been accepted or confirmed yet.';
        icon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        title = 'No Requests in Progress';
        message = 'No transportation requests are currently in progress.';
        icon = Icons.schedule;
        break;
      case 'completed':
        title = 'No Completed Requests';
        message = 'You haven\'t completed any transportation requests yet.';
        icon = Icons.check_circle;
        break;
      case 'all':
      default:
        title = 'No Requests Yet';
        message = 'You don\'t have any transportation requests yet.';
        icon = Icons.directions_bus;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: LottoRunnersColors.primaryYellow,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: LottoRunnersColors.primaryYellow,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, ThemeData theme) {
    final status = booking['status'] ?? 'pending';
    final paymentStatus = booking['payment_status'] ?? 'pending';
    final pickupLocation = booking['pickup_location'] ?? 'Not specified';
    final dropoffLocation = booking['dropoff_location'] ?? 'Not specified';
    final passengerCount = booking['passenger_count'] ?? 1;
    final bookingDate = booking['booking_date'] ?? '';
    final bookingTime = booking['booking_time'] ?? '';
    final estimatedPrice = booking['estimated_price'] ?? 0.0;
    final finalPrice = booking['final_price'] ?? estimatedPrice;
    final specialRequests = booking['special_requests'] ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.isSmallMobile(context) ? 16 : 16,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        color: theme.cardColor,
        child: InkWell(
          onTap: () {}, // No action needed for transportation cards
          borderRadius: BorderRadius.circular(0),
          child: Padding(
            padding:
                EdgeInsets.all(Responsive.isSmallMobile(context) ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking['title'] ?? 'Transportation Request',
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

                // Location details
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
                      _buildLocationRow(
                        icon: Icons.my_location,
                        label: 'Pickup',
                        location: pickupLocation,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _buildLocationRow(
                        icon: Icons.location_on,
                        label: 'Dropoff',
                        location: dropoffLocation,
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Booking details
                if (booking['booking_type'] == 'contract') ...[
                  // Contract-specific details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Start Date',
                          booking['contract_start_date'] ?? 'Not set',
                          theme,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Start Time',
                          booking['contract_start_time'] != null
                              ? booking['contract_start_time']
                                  .toString()
                                  .substring(0, 5)
                              : 'Not set',
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Duration',
                          '${booking['contract_duration_value']} ${booking['contract_duration_type']}',
                          theme,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'End Date',
                          booking['contract_end_date'] ?? 'Not set',
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Passengers',
                          passengerCount.toString(),
                          theme,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Price',
                          '\$${finalPrice.toStringAsFixed(2)}',
                          theme,
                        ),
                      ),
                    ],
                  ),
                  if (booking['description'] != null &&
                      booking['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Description', booking['description'], theme),
                  ],
                ] else ...[
                  // Transportation booking details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Date',
                          bookingDate.isNotEmpty ? bookingDate : 'Not set',
                          theme,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Time',
                          bookingTime.isNotEmpty
                              ? bookingTime.substring(0, 5)
                              : 'Not set',
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          'Passengers',
                          passengerCount.toString(),
                          theme,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          'Price',
                          '\$${finalPrice.toStringAsFixed(2)}',
                          theme,
                        ),
                      ),
                    ],
                  ),
                  // Display vehicle information
                  if (booking['vehicle_name'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Vehicle Type', booking['vehicle_name'], theme),
                  ],
                  if (booking['vehicle_description'] != null &&
                      booking['vehicle_description'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow('Vehicle Description',
                        booking['vehicle_description'], theme),
                  ],
                  if (specialRequests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Special Requests', specialRequests, theme),
                  ],
                ],

                // Driver information for accepted/in-progress requests
                if ((status == 'accepted' ||
                        status == 'in_progress' ||
                        status == 'confirmed') &&
                    booking['driver_id'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LottoRunnersColors.primaryYellow
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: LottoRunnersColors.primaryYellow
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: LottoRunnersColors.primaryYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Assigned',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: LottoRunnersColors.primaryYellow,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                booking['driver']?['full_name'] ??
                                    'Unknown Driver',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: LottoRunnersColors.primaryYellow,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Payment status and actions

                // Payment and Approval Actions
                if (status == 'accepted' ||
                    status == 'confirmed' ||
                    status == 'completed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if ((status == 'accepted' || status == 'confirmed') &&
                          paymentStatus == 'unpaid')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _handlePayment(booking, finalPrice),
                            icon: const Icon(Icons.payment, size: 18),
                            label: Text(
                                'Pay Upfront (N\$${finalPrice.toStringAsFixed(2)})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (status == 'completed' && paymentStatus == 'in_escrow')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleApprovePayment(booking),
                            icon: const Icon(Icons.verified, size: 18),
                            label: const Text('Approve & Release'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LottoRunnersColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ),
                ],

                // Chat functionality for accepted and in-progress requests
                if ((status == 'accepted' ||
                        status == 'in_progress' ||
                        status == 'confirmed') &&
                    (booking['driver_id'] != null ||
                        booking['booking_type'] == 'bus')) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChatWithDriver(booking),
                          icon: Icon(
                            Icons.chat,
                            size: Responsive.isSmallMobile(context) ? 16 : 18,
                          ),
                          label: Text(
                            'Chat',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 14 : 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LottoRunnersColors.primaryBlue,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Only show cancel button for accepted bookings (not in-progress)
                      if (status == 'accepted') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cancelBooking(booking['id']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        displayStatus = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        displayStatus = 'Confirmed';
        break;
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        displayStatus = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        displayStatus = 'Cancelled';
        break;
      case 'no_show':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        displayStatus = 'No Show';
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

  /// Open chat with driver/admin for accepted transportation/bus requests
  Future<void> _openChatWithDriver(Map<String, dynamic> booking) async {
    try {
      if (booking['booking_type'] == 'bus') {
        // Handle bus booking chat
        final conversation =
            await ChatService.getConversationByBooking(booking['id'], 'bus');

        if (conversation != null) {
          // Navigate to chat page
          if (mounted) {
            Navigator.push(
              context,
              PageTransitions.slideFromBottom(
                ChatPage(
                  conversationId: conversation['id'],
                  conversationType: 'bus',
                  bookingId: booking['id'],
                  otherUserName: 'Admin',
                  serviceTitle: 'Bus Service Booking',
                ),
              ),
            );
          }
        } else {
          // Show message that admin needs to start the conversation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin will start the conversation when ready'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Handle transportation booking chat (existing logic)
        final conversation =
            await ChatService.getTransportationConversationByBooking(
                booking['id']);

        if (conversation != null) {
          // Navigate to chat page
          if (mounted) {
            final driverName = booking['driver']?['full_name'] ?? 'Driver';
            Navigator.push(
              context,
              PageTransitions.slideFromBottom(
                ChatPage(
                  conversationId: conversation['id'],
                  conversationType: 'transportation',
                  bookingId: booking['id'],
                  otherUserName: driverName,
                  serviceTitle: 'Transportation Request',
                ),
              ),
            );
          }
        } else {
          // Create new conversation if it doesn't exist
          final currentUserId = SupabaseConfig.currentUser?.id;
          if (currentUserId != null) {
            final conversationId =
                await ChatService.createTransportationConversation(
              bookingId: booking['id'],
              customerId: currentUserId,
              runnerId: booking['driver_id'],
              serviceName: 'Transportation Service',
            );

            if (conversationId != null && mounted) {
              final driverName = booking['driver']?['full_name'] ?? 'Driver';
              Navigator.push(
                context,
                PageTransitions.slideFromBottom(
                  ChatPage(
                    conversationId: conversationId,
                    conversationType: 'transportation',
                    bookingId: booking['id'],
                    otherUserName: driverName,
                    serviceTitle: 'Transportation Request',
                  ),
                ),
              );
            }
          }
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

  Future<void> _handlePayment(
      Map<String, dynamic> booking, double amount) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayTodayPaymentPage(
          errandId: booking['id'],
          amount: amount,
          paymentType: PayTodayConfig.paymentTypeFull,
          bookingType: booking['booking_type'] ?? 'transportation',
          customerId: SupabaseConfig.currentUser?.id ?? '',
          runnerId: booking['driver_id'],
          onSuccess: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Updating status...'),
                backgroundColor: Colors.green,
              ),
            );

            // Wait for DB trigger/edge function to process
            await Future.delayed(const Duration(seconds: 2));
            _loadMyBookings(forceRefresh: true);
          },
          onFailure: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment failed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        ),
      ),
    );

    if (success == true) {
      _loadMyBookings(forceRefresh: true);
    }
  }

  Future<void> _handleApprovePayment(Map<String, dynamic> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Completion?'),
        content: const Text(
          'By approving, you confirm the trip/service is completed and the funds will be released to the driver. This action cannot be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Yes, Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.approvePayment(
            booking['id'], booking['booking_type'] ?? 'transportation');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment released! Thank you.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMyBookings(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error approving payment: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
              'Are you sure you want to cancel this transportation request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await SupabaseConfig.updateTransportationBooking(
          bookingId,
          {'status': 'cancelled'},
        );

        if (success) {
          // Send notifications
          final booking = _bookings.firstWhere((b) => b['id'] == bookingId);
          final serviceName =
              booking['service']?['name'] ?? 'Transportation Service';
          await NotificationService.notifyTransportationCancelled(
              serviceName, 'Cancelled by customer');

          // Close the chat conversation if it exists
          final conversation =
              await ChatService.getTransportationConversationByBooking(
                  bookingId);
          if (conversation != null) {
            await ChatService.closeTransportationConversation(
                conversation['id']);
          }

          _loadMyBookings(); // Refresh the list
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transportation request cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to cancel booking');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Unable to cancel request. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
