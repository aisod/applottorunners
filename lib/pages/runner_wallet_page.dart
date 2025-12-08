import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:intl/intl.dart';

/// Runner Wallet Page
/// Shows runner's earnings, commission breakdown, and booking history
class RunnerWalletPage extends StatefulWidget {
  const RunnerWalletPage({super.key});

  @override
  State<RunnerWalletPage> createState() => _RunnerWalletPageState();
}

class _RunnerWalletPageState extends State<RunnerWalletPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _earningsSummary;
  List<Map<String, dynamic>> _detailedBookings = [];
  String _selectedFilter = 'all'; // all, completed, in_progress

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Get runner earnings summary from the view
      final response = await SupabaseConfig.client
          .from('runner_earnings_summary')
          .select()
          .eq('runner_id', userId)
          .maybeSingle();

      // Get detailed bookings
      final detailedResponse = await SupabaseConfig.client
          .rpc('get_runner_detailed_bookings', params: {'p_runner_id': userId});

      if (mounted) {
        setState(() {
          _earningsSummary = response ?? {
            'total_revenue': 0.0,
            'total_runner_earnings': 0.0,
            'total_company_commission': 0.0,
            'total_bookings': 0,
            'completed_bookings': 0,
            'errand_count': 0,
            'errand_revenue': 0.0,
            'errand_earnings': 0.0,
            'transportation_count': 0,
            'transportation_revenue': 0.0,
            'transportation_earnings': 0.0,
            'contract_count': 0,
            'contract_revenue': 0.0,
            'contract_earnings': 0.0,
          };
          _detailedBookings = (detailedResponse as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading earnings data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load earnings. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: LottoRunnersColors.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEarningsData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 800 : 1200,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEarningsSummaryCard(theme, isMobile),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildBreakdownCard(theme, isMobile),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildCommissionInfoCard(theme, isMobile),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildBookingsHistorySection(theme, isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEarningsSummaryCard(ThemeData theme, bool isMobile) {
    final totalRevenue = (_earningsSummary?['total_revenue'] ?? 0.0).toDouble();
    final runnerEarnings = (_earningsSummary?['total_runner_earnings'] ?? 0.0).toDouble();
    final companyCommission = (_earningsSummary?['total_company_commission'] ?? 0.0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LottoRunnersColors.primaryBlue,
              LottoRunnersColors.primaryBlue.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: isMobile ? 48 : 56,
              color: LottoRunnersColors.primaryYellow,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Your Earnings',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 18 : 22,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'N\$${runnerEarnings.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: LottoRunnersColors.primaryYellow,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 36 : 48,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              'From N\$${totalRevenue.toStringAsFixed(2)} total bookings',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: isMobile ? 13 : 15,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Divider(color: Colors.white.withOpacity(0.3)),
            SizedBox(height: isMobile ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  'Completed',
                  '${_earningsSummary?['completed_bookings'] ?? 0}',
                  Icons.check_circle,
                  isMobile,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatColumn(
                  'Platform Fee',
                  'N\$${companyCommission.toStringAsFixed(2)}',
                  Icons.business,
                  isMobile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: LottoRunnersColors.primaryYellow, size: isMobile ? 20 : 24),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isMobile ? 11 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(ThemeData theme, bool isMobile) {
    final errandEarnings = (_earningsSummary?['errand_earnings'] ?? 0.0).toDouble();
    final errandCount = (_earningsSummary?['errand_count'] ?? 0);
    final transportEarnings = (_earningsSummary?['transportation_earnings'] ?? 0.0).toDouble();
    final transportCount = (_earningsSummary?['transportation_count'] ?? 0);
    final contractEarnings = (_earningsSummary?['contract_earnings'] ?? 0.0).toDouble();
    final contractCount = (_earningsSummary?['contract_count'] ?? 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _buildBreakdownItem(
              'Errands',
              errandCount,
              errandEarnings,
              Icons.assignment,
              LottoRunnersColors.primaryBlue,
              isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildBreakdownItem(
              'Transportation',
              transportCount,
              transportEarnings,
              Icons.directions_car,
              Colors.green,
              isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildBreakdownItem(
              'Contracts',
              contractCount,
              contractEarnings,
              Icons.description,
              Colors.orange,
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    int count,
    double earnings,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  '$count booking${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'N\$${earnings.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionInfoCard(ThemeData theme, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: LottoRunnersColors.primaryBlue,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Text(
                  'Commission Structure',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                    color: LottoRunnersColors.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildCommissionRow(
              'Your Earnings',
              '66.7%',
              'You receive two-thirds of every booking',
              Colors.green,
              isMobile,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            _buildCommissionRow(
              'Platform Fee',
              '33.3%',
              'Company retains one-third for platform services',
              Colors.orange,
              isMobile,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: isMobile ? 16 : 18,
                  ),
                  SizedBox(width: isMobile ? 8 : 10),
                  Expanded(
                    child: Text(
                      'Platform fee covers app maintenance, customer support, marketing, and payment processing',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionRow(
    String label,
    String percentage,
    String description,
    Color color,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 60 : 70,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            percentage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
              color: color,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 15,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsHistorySection(ThemeData theme, bool isMobile) {
    final filteredBookings = _selectedFilter == 'all'
        ? _detailedBookings
        : _detailedBookings.where((b) {
            if (_selectedFilter == 'completed') {
              return b['status'] == 'completed';
            } else if (_selectedFilter == 'in_progress') {
              return ['accepted', 'in_progress'].contains(b['status']);
            }
            return true;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Booking History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            DropdownButton<String>(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'in_progress', child: Text('Active')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedFilter = value);
              },
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (filteredBookings.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 32 : 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: isMobile ? 48 : 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      'Start accepting errands to see your earnings here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...filteredBookings.map((booking) => _buildBookingCard(booking, theme, isMobile)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, ThemeData theme, bool isMobile) {
    final bookingType = booking['booking_type'] ?? 'Booking';
    final customerName = booking['customer_name'] ?? 'Unknown';
    final amount = (booking['amount'] ?? 0.0).toDouble();
    final runnerEarnings = (booking['runner_earnings'] ?? 0.0).toDouble();
    final commission = (booking['company_commission'] ?? 0.0).toDouble();
    final status = booking['status'] ?? 'unknown';
    final date = booking['booking_date'] != null
        ? DateTime.parse(booking['booking_date'])
        : DateTime.now();
    final description = booking['description'] ?? '';
    
    // Extract service type information from pricing_modifiers
    final serviceType = booking['service_type'] as String?;
    final pricingModifiers = booking['pricing_modifiers'] as Map?;
    final serviceTypeFromModifiers = pricingModifiers?['service_type'] as String?;
    final finalServiceType = serviceType ?? serviceTypeFromModifiers;

    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                        bookingType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 15 : 17,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      // Show service type if available
                      if (finalServiceType != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8,
                            vertical: isMobile ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: LottoRunnersColors.primaryYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: LottoRunnersColors.primaryYellow.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _getServiceTypeName(finalServiceType),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                      ],
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 12,
                    vertical: isMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: isMobile ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Booking:',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'N\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Fee (33.3%):',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '-N\$${commission.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: isMobile ? 16 : 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Earnings (66.7%):',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'N\$${runnerEarnings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: isMobile ? 12 : 14, color: Colors.grey[500]),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(date),
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeName(String serviceType) {
    // Convert service type codes to human-readable names
    final Map<String, String> serviceTypeNames = {
      // License Discs
      'renewal': 'Disc Renewal',
      'registration': 'Vehicle Registration',
      // Document Services
      'application_submission': 'Application Submission',
      'certification': 'Document Certification',
      // Queue Sitting
      'now': 'Queue Now',
      'scheduled': 'Queue Scheduled',
      // Shopping
      'personal': 'Personal Shopping',
      'grocery': 'Grocery Shopping',
      // Delivery Vehicles
      'Motorcycle': 'Motorcycle',
      'Sedan': 'Sedan',
      'Mini Truck': 'Mini Truck',
      'Truck': 'Truck',
      // Shopping Types
      'groceries': 'Groceries',
      'pharmacy': 'Pharmacy',
      'general': 'General Shopping',
      'specific_items': 'Specific Items',
    };

    return serviceTypeNames[serviceType] ?? serviceType.replaceAll('_', ' ').toUpperCase();
  }
}

