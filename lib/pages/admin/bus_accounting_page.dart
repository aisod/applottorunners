import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Bus Accounting Page
///
/// This page displays all bus bookings and total revenue.
/// Bus bookings go 100% to the company (no commission split).
class BusAccountingPage extends StatefulWidget {
  const BusAccountingPage({super.key});

  @override
  State<BusAccountingPage> createState() => _BusAccountingPageState();
}

class _BusAccountingPageState extends State<BusAccountingPage> {
  List<Map<String, dynamic>> _busBookings = [];
  Map<String, dynamic> _totals = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'booking_date'; // booking_date, customer_name, amount

  @override
  void initState() {
    super.initState();
    _loadBusBookings();
  }

  Future<void> _loadBusBookings() async {
    setState(() => _isLoading = true);

    try {
      // Get all bus bookings
      final bookings = await SupabaseConfig.client
          .from('bus_service_bookings')
          .select('''
            *,
            customer:user_id(full_name, email)
          ''')
          .order('booking_date', ascending: false);

      // Calculate totals
      double totalRevenue = 0;
      int totalBookings = bookings.length;
      int completedBookings = 0;
      int pendingBookings = 0;

      for (var booking in bookings) {
        // Use final_price if available, otherwise use estimated_price
        final amount = (booking['final_price'] as num?)?.toDouble() ?? 
                       (booking['estimated_price'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
        
        if (booking['status'] == 'completed') {
          completedBookings++;
        } else if (booking['status'] == 'pending' || booking['status'] == 'confirmed') {
          pendingBookings++;
        }
      }

      setState(() {
        _busBookings = List<Map<String, dynamic>>.from(bookings);
        _totals = {
          'total_revenue': totalRevenue,
          'total_bookings': totalBookings,
          'completed_bookings': completedBookings,
          'pending_bookings': pendingBookings,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR loading bus bookings: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading bus bookings: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedBookings {
    var filtered = _busBookings;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        final customerName = (booking['customer']?['full_name'] ?? '').toString().toLowerCase();
        final customerEmail = (booking['customer']?['email'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return customerName.contains(query) || customerEmail.contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'customer_name':
          return (a['customer']?['full_name'] ?? '')
              .toString()
              .compareTo((b['customer']?['full_name'] ?? '').toString());
        case 'amount':
          final bAmount = (b['final_price'] as num?)?.toDouble() ?? 
                         (b['estimated_price'] as num?)?.toDouble() ?? 0.0;
          final aAmount = (a['final_price'] as num?)?.toDouble() ?? 
                         (a['estimated_price'] as num?)?.toDouble() ?? 0.0;
          return bAmount.compareTo(aAmount);
        case 'booking_date':
        default:
          return (b['booking_date'] ?? '')
              .toString()
              .compareTo((a['booking_date'] ?? '').toString());
      }
    });

    return filtered;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Summary Cards
        _buildSummaryCards(theme, isSmallMobile, isMobile),
        
        // Search and Sort
        _buildSearchAndSort(theme, isSmallMobile),
        
        // Bookings List
        Expanded(
          child: _filteredAndSortedBookings.isEmpty
              ? _buildEmptyState(theme)
              : _buildBookingsList(theme, isSmallMobile, isMobile),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ThemeData theme, bool isSmallMobile, bool isMobile) {
    final totalRevenue = (_totals['total_revenue'] ?? 0.0) as double;
    final totalBookings = (_totals['total_bookings'] ?? 0) as int;
    final completedBookings = (_totals['completed_bookings'] ?? 0) as int;
    final pendingBookings = (_totals['pending_bookings'] ?? 0) as int;

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: isSmallMobile ? 8 : 12,
        mainAxisSpacing: isSmallMobile ? 8 : 12,
        childAspectRatio: isMobile ? 1.3 : 1.5,
        children: [
          _buildSummaryCard(
            'Total Revenue',
            'N\$${totalRevenue.toStringAsFixed(2)}',
            Icons.attach_money,
            LottoRunnersColors.primaryYellow,
            theme,
            isSmallMobile,
          ),
          _buildSummaryCard(
            'Total Bookings',
            totalBookings.toString(),
            Icons.confirmation_number,
            LottoRunnersColors.primaryBlue,
            theme,
            isSmallMobile,
          ),
          _buildSummaryCard(
            'Completed',
            completedBookings.toString(),
            Icons.check_circle,
            Colors.green,
            theme,
            isSmallMobile,
          ),
          _buildSummaryCard(
            'Pending',
            pendingBookings.toString(),
            Icons.pending,
            Colors.orange,
            theme,
            isSmallMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isSmallMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isSmallMobile ? 24 : 28),
          SizedBox(height: isSmallMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallMobile ? 10 : 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort(ThemeData theme, bool isSmallMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 12 : 16,
        vertical: isSmallMobile ? 8 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 12 : 16,
                  vertical: isSmallMobile ? 8 : 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(width: isSmallMobile ? 8 : 12),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'booking_date', child: Text('Date')),
              DropdownMenuItem(value: 'customer_name', child: Text('Customer')),
              DropdownMenuItem(value: 'amount', child: Text('Amount')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No bus bookings found',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(ThemeData theme, bool isSmallMobile, bool isMobile) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      itemCount: _filteredAndSortedBookings.length,
      itemBuilder: (context, index) {
        final booking = _filteredAndSortedBookings[index];
        return _buildBookingCard(booking, theme, isSmallMobile, isMobile);
      },
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    ThemeData theme,
    bool isSmallMobile,
    bool isMobile,
  ) {
    final customerName = booking['customer']?['full_name'] ?? 'Unknown';
    final customerEmail = booking['customer']?['email'] ?? '';
    // Use final_price if available, otherwise use estimated_price
    final amount = (booking['final_price'] as num?)?.toDouble() ?? 
                   (booking['estimated_price'] as num?)?.toDouble() ?? 0.0;
    final bookingDate = booking['booking_date'] ?? '';
    final status = booking['status'] ?? 'unknown';
    final passengers = booking['passenger_count'] ?? 1;
    final route = booking['route'] ?? 'N/A';

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 8 : 12),
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: isSmallMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customerEmail.isNotEmpty)
                        Text(
                          customerEmail,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 11 : 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: isSmallMobile ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.route, size: isSmallMobile ? 16 : 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Route: $route',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 13 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: isSmallMobile ? 14 : 16),
                    const SizedBox(width: 4),
                    Text(
                      bookingDate,
                      style: TextStyle(fontSize: isSmallMobile ? 11 : 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.people, size: isSmallMobile ? 14 : 16),
                    const SizedBox(width: 4),
                    Text(
                      '$passengers passenger${passengers > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: isSmallMobile ? 11 : 12),
                    ),
                  ],
                ),
                Text(
                  'N\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: LottoRunnersColors.primaryYellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

