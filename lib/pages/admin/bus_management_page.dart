import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/pages/chat_page.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:lotto_runners/utils/page_transitions.dart';

/// Bus Management Services Page
///
/// This page provides admin interface for managing bus service bookings,
/// accepting bookings, and communicating with users through chat.
class BusManagementPage extends StatefulWidget {
  const BusManagementPage({super.key});

  @override
  State<BusManagementPage> createState() => _BusManagementPageState();
}

class _BusManagementPageState extends State<BusManagementPage> {
  List<Map<String, dynamic>> _busBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _searchQuery = '';

  // Filter options
  final List<String> _statusFilters = [
    'all',
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'cancelled',
    'no_show'
  ];

  @override
  void initState() {
    super.initState();
    _loadBusBookings();
  }

  /// Load all bus service bookings
  Future<void> _loadBusBookings() async {
    setState(() => _isLoading = true);

    try {
      final bookings = await SupabaseConfig.getBusServiceBookings();
      setState(() {
        _busBookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading bookings: $e');
    }
  }

  /// Filter bookings based on status and search query
  void _filterBookings() {
    setState(() {
      _filteredBookings = _busBookings.where((booking) {
        final matchesStatus =
            _selectedStatus == 'all' || booking['status'] == _selectedStatus;
        final matchesSearch = _searchQuery.isEmpty ||
            booking['user_name']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            booking['pickup_location']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            booking['dropoff_location']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  /// Accept a bus booking
  Future<void> _acceptBooking(String bookingId) async {
    try {
      print('🔄 Accepting bus booking: $bookingId');
      final success =
          await SupabaseConfig.updateBusBookingStatus(bookingId, 'accepted');
      if (success) {
        print('✅ Bus booking accepted successfully');

        // Create chat conversation for the accepted booking
        final booking = _busBookings.firstWhere((b) => b['id'] == bookingId);
        final conversationId = await ChatService.createBusBookingConversation(
          bookingId: bookingId,
          customerId: booking['user_id'],
          runnerId: SupabaseConfig.currentUser?.id ?? '',
          serviceName: booking['service']?['name'] ?? 'Bus Service',
        );

        if (conversationId != null) {
          print('✅ Chat conversation created: $conversationId');
        }

        _showSuccessSnackBar('Booking accepted successfully!');
        await _loadBusBookings(); // Reload to update status
        print('🔄 Bus bookings reloaded');
      } else {
        print('❌ Failed to accept bus booking');
        _showErrorSnackBar('Failed to accept booking. Please try again.');
      }
    } catch (e) {
      print('❌ Error accepting bus booking: $e');
      _showErrorSnackBar('Error accepting booking: $e');
    }
  }

  /// Update booking status
  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      print('🔄 Updating bus booking status: $bookingId to $status');
      final success =
          await SupabaseConfig.updateBusBookingStatus(bookingId, status);
      if (success) {
        print('✅ Bus booking status updated successfully');
        _showSuccessSnackBar('Booking status updated to $status!');
        await _loadBusBookings(); // Reload to update status
        print('🔄 Bus bookings reloaded');
      } else {
        print('❌ Failed to update bus booking status');
        _showErrorSnackBar(
            'Failed to update booking status. Please try again.');
      }
    } catch (e) {
      print('❌ Error updating bus booking status: $e');
      _showErrorSnackBar('Error updating status: $e');
    }
  }

  /// Open chat with user
  void _openChat(Map<String, dynamic> booking) async {
    try {
      // First try to get existing conversation
      final conversation =
          await ChatService.getConversationByBooking(booking['id'], 'bus');

      String conversationId;

      if (conversation != null) {
        conversationId = conversation['id'];
      } else {
        // Create new conversation if it doesn't exist
        final newConversationId =
            await ChatService.createBusBookingConversation(
          bookingId: booking['id'],
          customerId: booking['user_id'],
          runnerId: SupabaseConfig.currentUser?.id ?? '',
          serviceName: booking['service']?['name'] ?? 'Bus Service',
        );

        if (newConversationId != null) {
          conversationId = newConversationId;
        } else {
          _showErrorSnackBar('Failed to create chat conversation');
          return;
        }
      }

      Navigator.push(
        context,
        PageTransitions.slideFromBottom(
          ChatPage(
            conversationId: conversationId,
            conversationType: 'bus',
            bookingId: booking['id'],
            otherUserName: booking['user']?['full_name'] ?? 'User',
            serviceTitle: 'Bus Service Booking',
          ),
        ),
      );
    } catch (e) {
      print('❌ Error opening chat: $e');
      _showErrorSnackBar('Failed to open chat: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.yellow[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bus Management Services',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 22),
          ),
        ),
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
            icon: Icon(
              Icons.refresh,
              size: isSmallMobile ? 20 : 24,
            ),
            onPressed: _loadBusBookings,
            tooltip: 'Refresh Bookings',
          ),
          // const ThemeToggleButton( // Commented out dark mode for now
          //   foregroundColor: LottoRunnersColors.primaryYellow,
          //   backgroundColor: Colors.transparent,
          // ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: Responsive.getResponsivePadding(context),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterBookings();
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search by user name, pickup, or dropoff location...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: isSmallMobile ? 10 : 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedStatus = status);
                            _filterBookings();
                          },
                          selectedColor: Colors.blue[600],
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bookings list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_bus,
                              size: 64,
                              color: LottoRunnersColors.primaryYellow,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bus bookings found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Bookings will appear here when users make bus service requests',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: Responsive.getResponsivePadding(context),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _filteredBookings[index];
                          return _buildBookingCard(booking, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Build individual booking card
  Widget _buildBookingCard(Map<String, dynamic> booking, ThemeData theme) {
    final status = booking['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with user info and status
            Row(
              children: [
                // User type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: LottoRunnersColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getUserTypeIcon(booking['user_type'] ?? 'individual'),
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['user_name'] ?? 'Unknown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: LottoRunnersColors.gray700,
                        ),
                      ),
                      Text(
                        'Customer: ${booking['user_name'] ?? 'null null'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: LottoRunnersColors.gray600,
                        ),
                      ),
                      Text(
                        'Provider: ${booking['provider_name'] ?? 'Unknown Provider'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: LottoRunnersColors.gray600,
                        ),
                      ),
                      Text(
                        'Date: ${_formatDate(booking['booking_date'])} ${_formatTime(booking['booking_time'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: LottoRunnersColors.gray600,
                        ),
                      ),
                      if (booking['total_price'] != null)
                        Text(
                          'Price: NAD ${booking['total_price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.gray600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Trip details
            _buildInfoRow(
                'From', booking['pickup_location'] ?? 'N/A', Icons.location_on),
            _buildInfoRow(
                'To', booking['dropoff_location'] ?? 'N/A', Icons.location_on),
            _buildInfoRow('Date', _formatDate(booking['booking_date']),
                Icons.calendar_today),
            _buildInfoRow('Time', _formatTime(booking['booking_time']),
                Icons.access_time),
            _buildInfoRow('Passengers', '${booking['passenger_count'] ?? 1}',
                Icons.people),
            _buildInfoRow(
                'Price',
                'NAD ${booking['total_price']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money),

            if (booking['special_requests']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Special Requests', booking['special_requests'], Icons.note),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptBooking(booking['id']),
                      icon: const Icon(Icons.check),
                      label: Text(isSmallMobile ? 'Accept' : 'Accept Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LottoRunnersColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(booking),
                    icon: const Icon(Icons.chat),
                    label: Text(isSmallMobile ? 'Chat' : 'Open Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LottoRunnersColors.primaryBlue,
                      side: const BorderSide(
                          color: LottoRunnersColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _updateBookingStatus(booking['id'], value),
                  itemBuilder: (context) => [
                    if (status != 'accepted')
                      const PopupMenuItem(
                        value: 'accepted',
                        child: Text('Mark as Accepted'),
                      ),
                    if (status != 'in_progress')
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Text('Mark as In Progress'),
                      ),
                    if (status != 'completed')
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Mark as Completed'),
                      ),
                    if (status != 'cancelled')
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('Mark as Cancelled'),
                      ),
                    if (status != 'no_show')
                      const PopupMenuItem(
                        value: 'no_show',
                        child: Text('Mark as No Show'),
                      ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: LottoRunnersColors.primaryYellow),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: LottoRunnersColors.primaryYellow,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row for booking details
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: LottoRunnersColors.primaryYellow,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for booking status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  /// Format date for display
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      } else if (date is DateTime) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Invalid Date';
    }
    return 'N/A';
  }

  /// Format time for display
  String _formatTime(dynamic time) {
    if (time == null) return 'N/A';
    try {
      if (time is String) {
        return time;
      } else if (time is TimeOfDay) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Invalid Time';
    }
    return 'N/A';
  }

  // Helper method for user type icon
  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'runner':
        return Icons.directions_run;
      case 'business':
        return Icons.business;
      case 'individual':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}
