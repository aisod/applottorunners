import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'dart:async';
// import 'payment_tracking_page.dart';
import 'analytics_page.dart';
import 'bus_management_page.dart';
import 'provider_accounting_page.dart';
import 'runner_messaging_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _systemStatus;
  Timer? _refreshTimer;

  final List<Tab> _tabs = [
    const Tab(
      icon: Icon(Icons.dashboard),
      text: 'Dashboard',
    ),
    const Tab(
      icon: Icon(Icons.account_balance_wallet,
          color: LottoRunnersColors.primaryYellow),
      text: 'Provider Accounting',
    ),
    const Tab(
      icon: Icon(Icons.message,
          color: LottoRunnersColors.primaryYellow),
      text: 'Messenger',
    ),
    const Tab(
      icon: Icon(Icons.analytics),
      text: 'Analytics',
    ),
    const Tab(
      icon: Icon(Icons.directions_bus),
      text: 'Bus Management',
    ),
  ];

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
      final status = await _getSystemStatus();

      if (mounted) {
        setState(() {
          _analyticsData = analytics;
          _systemStatus = status;
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

  Future<Map<String, dynamic>> _getSystemStatus() async {
    // Simulate system health check
    return {
      'database': {'status': 'healthy', 'latency': '12ms'},
      'api_service': {'status': 'healthy', 'uptime': '99.9%'},
      'storage': {'status': 'healthy', 'usage': '67%'},
      'active_users': 42,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
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
          iconTheme:
              const IconThemeData(color: LottoRunnersColors.primaryYellow),
          actionsIconTheme:
              const IconThemeData(color: LottoRunnersColors.primaryYellow),
          bottom: TabBar(
            tabs: _tabs
                .map((tab) => Tab(
                      icon: Icon(
                        (tab.icon as Icon).icon,
                        size: isSmallMobile ? 20 : 24,
                      ),
                      text: isSmallMobile
                          ? null
                          : tab.text, // Hide text on very small screens
                      height: isSmallMobile ? 48 : 56,
                    ))
                .toList(),
            indicatorColor: Colors.white,
            labelColor: LottoRunnersColors.primaryYellow,
            unselectedLabelColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: isSmallMobile ? 11 : 13,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: isSmallMobile ? 20 : 24,
              ),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh Data',
              padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
            ),
            const SizedBox(width: 4),
            // ThemeToggleButton(
            //   foregroundColor: LottoRunnersColors.primaryYellow,
            //   backgroundColor: Colors.transparent,
            // ),
            IconButton(
              icon: Icon(
                Icons.logout,
                size: isSmallMobile ? 20 : 24,
              ),
              onPressed: () => SupabaseConfig.signOut(),
              tooltip: 'Sign Out',
              padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildDashboard(),
            const ProviderAccountingPage(),
            const RunnerMessagingPage(),
            const AnalyticsPage(),
            const BusManagementPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      padding: Responsive.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid(),
          SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
          // Make the layout responsive
          Responsive.isMobile(context)
              ? Column(
                  children: [
                    _buildRevenueChart(),
                    SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
                    _buildSystemStatus(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildRevenueChart(),
                    ),
                    SizedBox(width: Responsive.getResponsiveSpacing(context)),
                    Expanded(
                      child: _buildSystemStatus(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final analytics = _analyticsData ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the new responsive utilities
        final gridConfig = Responsive.getMetricsGridConfig(context);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: gridConfig['crossAxisCount'],
          crossAxisSpacing: gridConfig['spacing'],
          mainAxisSpacing: gridConfig['spacing'],
          childAspectRatio: gridConfig['childAspectRatio'],
          children: [
            _buildMetricCard(
              title: 'Total Users',
              value: '${analytics['total_users'] ?? 0}',
              icon: Icons.people,
              color: LottoRunnersColors.primaryBlue,
              change: '+12.5%',
              isPositive: true,
            ),
            _buildMetricCard(
              title: 'Active Errands',
              value: '${analytics['active_errands'] ?? 0}',
              icon: Icons.assignment,
              color: LottoRunnersColors.accent,
              change: '+8.2%',
              isPositive: true,
            ),
            _buildMetricCard(
              title: 'Monthly Revenue',
              value:
                  'N\$${(analytics['monthly_revenue'] ?? 0).toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: LottoRunnersColors.primaryPurple,
              change: '+15.3%',
              isPositive: true,
            ),
            _buildMetricCard(
              title: 'Success Rate',
              value:
                  '${((analytics['completion_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.green,
              change: '+2.1%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 12 : 16)),
      margin: EdgeInsets.only(bottom: isSmallMobile ? 4 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.all(isSmallMobile ? 4 : (isMobile ? 6 : 12)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallMobile ? 14 : (isMobile ? 18 : 24),
                ),
              ),
              const Spacer(),
              // Make the change indicator responsive
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 3 : 6,
                    vertical: isSmallMobile ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? theme.colorScheme.tertiary.withOpacity(0.1)
                        : theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPositive
                          ? Colors.blue[600]
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallMobile ? 8 : (isMobile ? 10 : 12),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 20)),
          Text(
            value,
            style: (isSmallMobile
                    ? theme.textTheme.titleSmall
                    : (isMobile
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.headlineMedium))
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.primaryYellow,
              fontSize: isSmallMobile ? 14 : (isMobile ? 16 : null),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: isSmallMobile ? 3 : 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallMobile ? 10 : (isMobile ? 11 : 14),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      padding: Responsive.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
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
            style: (isSmallMobile
                    ? theme.textTheme.titleSmall
                    : (isMobile
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge))
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
          Container(
            height: isSmallMobile ? 120 : (isMobile ? 150 : 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Chart Placeholder',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: isSmallMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    final theme = Theme.of(context);
    final status = _systemStatus ?? {};
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      padding: Responsive.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: (isSmallMobile
                    ? theme.textTheme.titleSmall
                    : (isMobile
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge))
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
          _buildStatusItem(
            'Database',
            status['database']?['status'] ?? 'Unknown',
            status['database']?['status'] == 'healthy'
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error,
            theme,
            isMobile,
            isSmallMobile,
          ),
          _buildStatusItem(
            'API Service',
            status['api_service']?['status'] ?? 'Unknown',
            status['api_service']?['status'] == 'healthy'
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error,
            theme,
            isMobile,
            isSmallMobile,
          ),
          _buildStatusItem(
            'Storage',
            status['storage']?['status'] ?? 'Unknown',
            status['storage']?['status'] == 'healthy'
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error,
            theme,
            isMobile,
            isSmallMobile,
          ),
          SizedBox(height: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
          Container(
            padding: Responsive.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: theme.colorScheme.primary,
                  size: isSmallMobile ? 14 : (isMobile ? 16 : 20),
                ),
                SizedBox(width: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
                Expanded(
                  child: Text(
                    'Active Users: ${status['active_users'] ?? 0}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: LottoRunnersColors.primaryYellow,
                      fontWeight: FontWeight.w500,
                      fontSize: isSmallMobile ? 12 : (isMobile ? 13 : 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String name, String status, Color color,
      ThemeData theme, bool isMobile, bool isSmallMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 5 : (isMobile ? 6 : 8),
            height: isSmallMobile ? 5 : (isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallMobile ? 6 : (isMobile ? 8 : 12)),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: isSmallMobile ? 12 : (isMobile ? 13 : 14),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            status,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: isSmallMobile ? 12 : (isMobile ? 13 : 14),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
