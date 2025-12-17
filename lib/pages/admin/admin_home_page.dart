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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallMobile ? 16 : (isMobile ? 24 : 40)),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LottoRunnersColors.primaryBlue,
                  LottoRunnersColors.primaryBlueDark,
            LottoRunnersColors.primaryYellow,
                ],
              ),
            ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: isSmallMobile ? 32 : 40,
                ),
                SizedBox(width: isSmallMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isSmallMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallMobile ? 4 : 8),
                      Text(
                        'Manage your Lotto Runners platform',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: isSmallMobile ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isSmallMobile, bool isMobile, ThemeData theme) {
    final totalUsers = _analyticsData?['total_users'] ?? 0;
    final totalErrands = _analyticsData?['total_errands'] ?? 0;
    final totalRevenue = _analyticsData?['total_revenue'] ?? 0.0;
    final activeRunners = _analyticsData?['active_runners'] ?? 0;

    final gridConfig = Responsive.getMetricsGridConfig(context);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'Quick Stats',
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
          crossAxisCount: gridConfig['crossAxisCount'],
          crossAxisSpacing: gridConfig['spacing'],
          mainAxisSpacing: gridConfig['spacing'],
          childAspectRatio: gridConfig['childAspectRatio'],
          children: [
            _buildStatCard(
              'Total Users',
              totalUsers.toString(),
              Icons.people,
              LottoRunnersColors.primaryBlue,
              theme,
              isSmallMobile,
            ),
            _buildStatCard(
              'Total Errands',
              totalErrands.toString(),
              Icons.assignment,
              Colors.green,
              theme,
              isSmallMobile,
            ),
            _buildStatCard(
              'Revenue',
              'N\$${totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              LottoRunnersColors.primaryYellow,
              theme,
              isSmallMobile,
            ),
            _buildStatCard(
              'Active Runners',
              activeRunners.toString(),
              Icons.directions_run,
              LottoRunnersColors.accent,
              theme,
              isSmallMobile,
            ),
          ],
        ),
      ],
    );
  }

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
            style: TextStyle(
              fontSize: isSmallMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 4 : 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
              style: TextStyle(
                fontSize: isSmallMobile ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

