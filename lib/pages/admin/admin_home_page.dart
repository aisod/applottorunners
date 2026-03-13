import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:async';
import 'analytics_page.dart';
import 'bus_management_page.dart';
import 'accounting_page.dart';
import 'runner_messaging_page.dart';
import 'service_management_page.dart';
import 'special_orders_management_page.dart';
import 'transportation_management_page.dart';
import 'user_management_page.dart';
import 'feedback_management_page.dart';
import 'payment_tracking_page.dart';
import 'all_bookings_page.dart';
import 'errand_oversight_page.dart';
import 'package:lotto_runners/widgets/theme_toggle_button.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final analytics = await SupabaseConfig.getAnalyticsData();

      if (mounted) {
        setState(() {
          _analyticsData = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(isSmallMobile, isMobile),
            
            // Management Cards
            Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : double.infinity,
              ),
              padding: EdgeInsets.all(isSmallMobile ? 16 : (isDesktop ? 40 : 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildManagementCards(isSmallMobile, isMobile, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isSmallMobile, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 16 : (isMobile ? 24 : 40)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: isSmallMobile ? 24 : 32,
                  ),
                ),
                SizedBox(width: isSmallMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: isSmallMobile ? 4 : 8),
                      Text(
                        'Manage your Lotto Runners platform',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const ThemeToggleButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildQuickStats(bool isSmallMobile, bool isMobile, ThemeData theme) {
  //   final totalUsers = _analyticsData?['total_users'] ?? 0;
  //   final totalErrands = _analyticsData?['total_errands'] ?? 0;
  //   final totalRevenue = _analyticsData?['total_revenue'] ?? 0.0;
  //   final activeRunners = _analyticsData?['active_runners'] ?? 0;
  //
  //   final gridConfig = Responsive.getMetricsGridConfig(context);
  //
  //   return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //       Text(
  //         'Quick Stats',
  //         style: TextStyle(
  //           fontSize: isSmallMobile ? 18 : 22,
  //           fontWeight: FontWeight.bold,
  //           color: Theme.of(context).colorScheme.onSurface,
  //         ),
  //       ),
  //       SizedBox(height: isSmallMobile ? 12 : 16),
  //       GridView.count(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         crossAxisCount: gridConfig['crossAxisCount'],
  //         crossAxisSpacing: gridConfig['spacing'],
  //         mainAxisSpacing: gridConfig['spacing'],
  //         childAspectRatio: gridConfig['childAspectRatio'],
  //         children: [
  //           _buildStatCard(
  //             'Total Users',
  //             totalUsers.toString(),
  //             Icons.people,
  //             LottoRunnersColors.primaryBlue,
  //             theme,
  //             isSmallMobile,
  //           ),
  //           _buildStatCard(
  //             'Total Errands',
  //             totalErrands.toString(),
  //             Icons.assignment,
  //             Colors.green,
  //             theme,
  //             isSmallMobile,
  //           ),
  //           _buildStatCard(
  //             'Revenue',
  //             'N\$${totalRevenue.toStringAsFixed(2)}',
  //             Icons.attach_money,
  //             LottoRunnersColors.primaryYellow,
  //             theme,
  //             isSmallMobile,
  //           ),
  //           _buildStatCard(
  //             'Active Runners',
  //             activeRunners.toString(),
  //             Icons.directions_run,
  //             LottoRunnersColors.accent,
  //             theme,
  //             isSmallMobile,
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isSmallMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallMobile ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallMobile ? 12 : 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: isSmallMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 4 : 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: isSmallMobile ? 12 : 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCards(bool isSmallMobile, bool isMobile, ThemeData theme) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          'Management',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        SizedBox(height: isSmallMobile ? 12 : 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 3,
          crossAxisSpacing: isSmallMobile ? 12 : 16,
          mainAxisSpacing: isSmallMobile ? 12 : 16,
          childAspectRatio: isMobile ? 1.2 : 1.5,
          children: [
            _buildManagementCard(
              'Service Management',
              Icons.build,
              LottoRunnersColors.primaryBlue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServiceManagementPage()),
              ),
            theme,
            isSmallMobile,
          ),
            _buildManagementCard(
              'Transportation',
              Icons.directions_bus,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransportationManagementPage()),
              ),
            theme,
            isSmallMobile,
          ),
            _buildManagementCard(
              'User Management',
              Icons.people,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementPage()),
              ),
            theme,
            isSmallMobile,
          ),
            _buildManagementCard(
              'Accounting',
              Icons.account_balance_wallet,
              LottoRunnersColors.primaryYellow,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountingPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Messenger',
              Icons.message,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RunnerMessagingPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Analytics',
              Icons.analytics,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Bus Management',
              Icons.airport_shuttle,
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusManagementPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Special Orders',
              Icons.star,
              Colors.deepOrange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpecialOrdersManagementPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Feedback',
              Icons.feedback,
              Colors.pink,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackManagementPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Payments',
              Icons.payments_outlined,
              Colors.greenAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentTrackingPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'All Bookings',
              Icons.list_alt,
              Colors.deepPurple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllBookingsPage()),
              ),
              theme,
              isSmallMobile,
            ),
            _buildManagementCard(
              'Errand Oversight',
              Icons.assignment,
              Colors.brown,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ErrandOversightPage()),
              ),
              theme,
              isSmallMobile,
            ),
        ],
      ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme,
    bool isSmallMobile,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmallMobile ? 28 : 32,
              ),
            ),
            SizedBox(height: isSmallMobile ? 8 : 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: isSmallMobile ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

