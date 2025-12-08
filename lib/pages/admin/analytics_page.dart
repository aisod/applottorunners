import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:async';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _recentErrands = [];
  List<Map<String, dynamic>> _topRunners = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _revenueData = [];
  Map<String, dynamic> _companyEarnings = {};
  bool _isLoading = true;
  String _selectedTimeRange = 'month';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted) {
        _loadAnalytics();
      }
    });
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);

      // Load basic analytics
      final analyticsData = await SupabaseConfig.getAnalyticsData();

      // Load recent errands for trend analysis
      final errands = await SupabaseConfig.getAllErrands();
      final recentErrands = errands.take(20).toList();

      // Calculate top runners
      final topRunners = await _calculateTopRunners(errands);

      // Calculate top customers
      final topCustomers = await _calculateTopCustomers(errands);

      // Calculate revenue data for charts
      final revenueData = await _calculateRevenueData(errands);

      // Calculate company earnings from both sources
      final companyEarnings = await _calculateCompanyEarnings();

      setState(() {
        _analyticsData = analyticsData;
        _recentErrands = recentErrands;
        _topRunners = topRunners;
        _topCustomers = topCustomers;
        _revenueData = revenueData;
        _companyEarnings = companyEarnings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load analytics. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _calculateCompanyEarnings() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      // Get provider commissions (33.3% of transportation bookings)
      final providerCommissions = await SupabaseConfig.getCompanyCommissionTotals();
      final totalProviderCommission = (providerCommissions['total_commission'] ?? 0.0) as double;

      // Get bus bookings (100% to company)
      final busBookings = await SupabaseConfig.client
          .from('bus_service_bookings')
          .select('estimated_price, final_price, booking_date, status');

      double totalBusRevenue = 0;
      double dailyBusRevenue = 0;
      double weeklyBusRevenue = 0;
      double monthlyBusRevenue = 0;

      for (var booking in busBookings) {
        // Use final_price if available, otherwise use estimated_price
        final amount = (booking['final_price'] as num?)?.toDouble() ?? 
                       (booking['estimated_price'] as num?)?.toDouble() ?? 0.0;
        totalBusRevenue += amount;

        final bookingDate = DateTime.tryParse(booking['booking_date'] ?? '');
        if (bookingDate != null) {
          if (bookingDate.isAfter(today) || bookingDate.isAtSameMomentAs(today)) {
            dailyBusRevenue += amount;
          }
          if (bookingDate.isAfter(weekAgo)) {
            weeklyBusRevenue += amount;
          }
          if (bookingDate.isAfter(monthAgo)) {
            monthlyBusRevenue += amount;
          }
        }
      }

      // Get transportation bookings for time-based calculations
      final transportationBookings = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('estimated_price, final_price, company_commission, created_at, status');

      double dailyProviderCommission = 0;
      double weeklyProviderCommission = 0;
      double monthlyProviderCommission = 0;

      for (var booking in transportationBookings) {
        // Use company_commission if available, otherwise calculate 33.3%
        final commission = (booking['company_commission'] as num?)?.toDouble() ?? 
                          ((booking['final_price'] as num?)?.toDouble() ?? 
                           (booking['estimated_price'] as num?)?.toDouble() ?? 0.0) * 0.333;

        final createdAt = DateTime.tryParse(booking['created_at'] ?? '');
        if (createdAt != null) {
          if (createdAt.isAfter(today) || createdAt.isAtSameMomentAs(today)) {
            dailyProviderCommission += commission;
          }
          if (createdAt.isAfter(weekAgo)) {
            weeklyProviderCommission += commission;
          }
          if (createdAt.isAfter(monthAgo)) {
            monthlyProviderCommission += commission;
          }
        }
      }

      print('🔍 Company Earnings Debug:');
      print('   Provider Commission Total: N\$${totalProviderCommission.toStringAsFixed(2)}');
      print('   Bus Revenue Total: N\$${totalBusRevenue.toStringAsFixed(2)}');
      print('   Total Earnings: N\$${(totalProviderCommission + totalBusRevenue).toStringAsFixed(2)}');
      print('   Daily: N\$${(dailyProviderCommission + dailyBusRevenue).toStringAsFixed(2)}');
      print('   Weekly: N\$${(weeklyProviderCommission + weeklyBusRevenue).toStringAsFixed(2)}');
      print('   Monthly: N\$${(monthlyProviderCommission + monthlyBusRevenue).toStringAsFixed(2)}');
      print('   Bus Bookings Count: ${busBookings.length}');
      print('   Transportation Bookings Count: ${transportationBookings.length}');

      return {
        'total_earnings': totalProviderCommission + totalBusRevenue,
        'provider_commission_total': totalProviderCommission,
        'bus_revenue_total': totalBusRevenue,
        'daily_total': dailyProviderCommission + dailyBusRevenue,
        'daily_provider': dailyProviderCommission,
        'daily_bus': dailyBusRevenue,
        'weekly_total': weeklyProviderCommission + weeklyBusRevenue,
        'weekly_provider': weeklyProviderCommission,
        'weekly_bus': weeklyBusRevenue,
        'monthly_total': monthlyProviderCommission + monthlyBusRevenue,
        'monthly_provider': monthlyProviderCommission,
        'monthly_bus': monthlyBusRevenue,
      };
    } catch (e) {
      print('❌ Error calculating company earnings: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _calculateTopRunners(
      List<Map<String, dynamic>> errands) async {
    final runnerStats = <String, Map<String, dynamic>>{};

    for (final errand in errands) {
      if (errand['runner_id'] != null && errand['status'] == 'completed') {
        final runnerId = errand['runner_id'];
        final runnerName = errand['runner']?['full_name'] ?? 'Unknown';
        final amount = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;

        if (!runnerStats.containsKey(runnerId)) {
          runnerStats[runnerId] = {
            'id': runnerId,
            'name': runnerName,
            'completed_errands': 0,
            'total_earnings': 0.0,
            'avg_rating': 0.0,
            'total_ratings': 0,
          };
        }

        runnerStats[runnerId]!['completed_errands']++;
        runnerStats[runnerId]!['total_earnings'] += amount;

        // Calculate average rating
        final rating = (errand['rating'] as num?)?.toDouble() ?? 0.0;
        if (rating > 0) {
          final currentTotal = runnerStats[runnerId]!['avg_rating'] *
              runnerStats[runnerId]!['total_ratings'];
          runnerStats[runnerId]!['total_ratings']++;
          runnerStats[runnerId]!['avg_rating'] =
              (currentTotal + rating) / runnerStats[runnerId]!['total_ratings'];
        }
      }
    }

    final sortedRunners = runnerStats.values.toList();
    sortedRunners
        .sort((a, b) => b['total_earnings'].compareTo(a['total_earnings']));

    return sortedRunners.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> _calculateTopCustomers(
      List<Map<String, dynamic>> errands) async {
    final customerStats = <String, Map<String, dynamic>>{};

    for (final errand in errands) {
      if (errand['customer_id'] != null) {
        final customerId = errand['customer_id'];
        final customerName = errand['customer']?['full_name'] ?? 'Unknown';
        final amount = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;

        if (!customerStats.containsKey(customerId)) {
          customerStats[customerId] = {
            'id': customerId,
            'name': customerName,
            'total_errands': 0,
            'total_spent': 0.0,
            'avg_errand_value': 0.0,
          };
        }

        customerStats[customerId]!['total_errands']++;
        customerStats[customerId]!['total_spent'] += amount;
        customerStats[customerId]!['avg_errand_value'] =
            customerStats[customerId]!['total_spent'] /
                customerStats[customerId]!['total_errands'];
      }
    }

    final sortedCustomers = customerStats.values.toList();
    sortedCustomers
        .sort((a, b) => b['total_spent'].compareTo(a['total_spent']));

    return sortedCustomers.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> _calculateRevenueData(
      List<Map<String, dynamic>> errands) async {
    final revenueByMonth = <String, double>{};

    for (final errand in errands) {
      if (errand['status'] == 'completed' && errand['created_at'] != null) {
        try {
          final date = DateTime.parse(errand['created_at']);
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          final amount = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;

          revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0.0) + amount;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    final sortedMonths = revenueByMonth.keys.toList()..sort();
    return sortedMonths
        .map((month) => {
              'month': month,
              'revenue': revenueByMonth[month] ?? 0.0,
            })
        .toList();
  }

  Map<String, int> _getErrandsByCategory() {
    final categories = <String, int>{};

    for (final errand in _recentErrands) {
      final category = errand['category'] ?? 'other';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }

  Map<String, int> _getErrandsByStatus() {
    final statuses = <String, int>{};

    for (final errand in _recentErrands) {
      final status = errand['status'] ?? 'unknown';
      statuses[status] = (statuses[status] ?? 0) + 1;
    }

    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
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
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRangeSelector(),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildKeyMetrics(),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildEarningsBreakdown(),
                  SizedBox(height: isMobile ? 16 : 24),
                  // Make layout responsive
                  isMobile
                      ? Column(
                          children: [
                            _buildRevenueTrend(),
                            const SizedBox(height: 16),
                            _buildErrandsByCategory(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildRevenueTrend(),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildErrandsByCategory(),
                            ),
                          ],
                        ),
                  SizedBox(height: isMobile ? 16 : 24),
                  // Make bottom section responsive
                  isMobile
                      ? Column(
                          children: [
                            _buildTopRunners(),
                            const SizedBox(height: 16),
                            _buildTopCustomers(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTopRunners()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTopCustomers()),
                          ],
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final isMobile = Responsive.isMobile(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text(
        //   'Analytics Dashboard',
        //   style: (isMobile
        //           ? Theme.of(context).textTheme.titleMedium
        //           : Theme.of(context).textTheme.headlineSmall)
        //       ?.copyWith(
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedTimeRange,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'week', child: Text('This Week')),
              DropdownMenuItem(value: 'month', child: Text('This Month')),
              DropdownMenuItem(value: 'quarter', child: Text('This Quarter')),
              DropdownMenuItem(value: 'year', child: Text('This Year')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTimeRange = value);
                _loadAnalytics();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsBreakdown() {
    final earnings = _companyEarnings;
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);

    final providerTotal = (earnings['provider_commission_total'] ?? 0.0) as double;
    final busTotal = (earnings['bus_revenue_total'] ?? 0.0) as double;
    final totalEarnings = (earnings['total_earnings'] ?? 0.0) as double;

    final providerPercentage = totalEarnings > 0 ? (providerTotal / totalEarnings * 100) : 0.0;
    final busPercentage = totalEarnings > 0 ? (busTotal / totalEarnings * 100) : 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
        children: [
          Text(
            'Earnings Breakdown',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownCard(
                  'Provider Commissions',
                  'N\$${providerTotal.toStringAsFixed(2)}',
                  '${providerPercentage.toStringAsFixed(1)}%',
                  Icons.people,
                  LottoRunnersColors.primaryBlue,
                  theme,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildBreakdownCard(
                  'Bus Bookings',
                  'N\$${busTotal.toStringAsFixed(2)}',
                  '${busPercentage.toStringAsFixed(1)}%',
                  Icons.directions_bus,
                  LottoRunnersColors.primaryYellow,
                  theme,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    String title,
    String amount,
    String percentage,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isMobile ? 20 : 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final analytics = _analyticsData ?? {};
    final earnings = _companyEarnings;
    final isMobile = Responsive.isMobile(context);

    final dailyTotal = (earnings['daily_total'] ?? 0.0) as double;
    final weeklyTotal = (earnings['weekly_total'] ?? 0.0) as double;
    final monthlyTotal = (earnings['monthly_total'] ?? 0.0) as double;
    final totalEarnings = (earnings['total_earnings'] ?? 0.0) as double;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 1.1 : 1.05;
        final spacing = isMobile ? 12.0 : 16.0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              'Total Earnings',
              'N\$${totalEarnings.toStringAsFixed(2)}',
              Icons.account_balance,
              LottoRunnersColors.primaryYellow,
              'All Time',
              true,
            ),
            _buildMetricCard(
              'Daily Earnings',
              'N\$${dailyTotal.toStringAsFixed(2)}',
              Icons.today,
              Colors.green,
              'Today',
              true,
            ),
            _buildMetricCard(
              'Weekly Earnings',
              'N\$${weeklyTotal.toStringAsFixed(2)}',
              Icons.date_range,
              Colors.blue,
              'Last 7 Days',
              true,
            ),
            _buildMetricCard(
              'Monthly Earnings',
              'N\$${monthlyTotal.toStringAsFixed(2)}',
              Icons.calendar_month,
              LottoRunnersColors.primaryBlue,
              'Last 30 Days',
              true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      Color color, String change, bool isPositive) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      margin: const EdgeInsets.only(bottom: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isMobile ? 18 : 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.blue.withOpacity(0.1)
                      : Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isPositive
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 8 : 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Flexible(
            child: Text(
              value,
              style: (isMobile
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isMobile ? 18 : 22,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: isMobile ? 10 : 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRevenueTrend() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Text(
            'Revenue Trend',
            style: (isMobile
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Container(
            height: isMobile ? 150 : 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: isMobile ? 32 : 48,
                    color: LottoRunnersColors.primaryYellow,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revenue Chart',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrandsByCategory() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Text(
            'Errands by Category',
            style: (isMobile
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildCategoryItem('GROCERY', 9, 0.8, theme),
          const SizedBox(height: 8),
          _buildCategoryItem('DELIVERY', 5, 0.6, theme),
          const SizedBox(height: 8),
          _buildCategoryItem('DOCUMENT', 3, 0.4, theme),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      String category, int count, double percentage, ThemeData theme) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            category,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: isMobile ? 16 : 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: isMobile ? 40 : 50,
          child: Text(
            '$count',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTopRunners() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Text(
            'Top Runners',
            style: (isMobile
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildTopRunnerItem('luis', 2, 75.00, theme),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Text(
            'Top Customers',
            style: (isMobile
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildTopCustomerItem('Edna', 12, 26.42, theme),
        ],
      ),
    );
  }

  Widget _buildTopRunnerItem(
      String name, int errands, double earnings, ThemeData theme) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      children: [
        Container(
          width: isMobile ? 32 : 40,
          height: isMobile ? 32 : 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$errands errands',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isMobile ? 11 : 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          'N\$${earnings.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            fontSize: isMobile ? 13 : 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTopCustomerItem(
      String name, int errands, double spent, ThemeData theme) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      children: [
        Container(
          width: isMobile ? 32 : 40,
          height: isMobile ? 32 : 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$errands errands',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isMobile ? 11 : 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          'N\$${spent.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: isMobile ? 13 : 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._recentErrands
                .take(10)
                .map((errand) => _buildActivityItem(errand)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> errand) {
    final status = errand['status'] ?? 'unknown';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = LottoRunnersColors.gray600;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errand['title'] ?? 'Unknown Errand',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${errand['category'] ?? 'Unknown'} • N\$${(errand['price_amount'] ?? 0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LottoRunnersColors.gray600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(errand['created_at']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LottoRunnersColors.gray600,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
