import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/admin/user_management_page.dart';
import 'package:lotto_runners/pages/admin/errand_oversight_page.dart';
import 'package:lotto_runners/pages/admin/payment_tracking_page.dart';
import 'package:lotto_runners/pages/admin/runner_verification_page.dart';
import 'package:lotto_runners/pages/admin/analytics_page.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _analyticsData;
  bool _isLoadingAnalytics = true;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const UserManagementPage(),
    const ErrandOversightPage(),
    const PaymentTrackingPage(),
    const RunnerVerificationPage(),
    const AnalyticsPage(),
  ];

  final List<String> _titles = [
    'Admin Dashboard',
    'User Management',
    'Errand Oversight',
    'Payment Tracking',
    'Runner Verification',
    'Analytics',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await SupabaseConfig.getAnalyticsData();
      setState(() {
        _analyticsData = data;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseConfig.signOut();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? AdminDashboard(
              analyticsData: _analyticsData, isLoading: _isLoadingAnalytics)
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Errands',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  final Map<String, dynamic>? analyticsData;
  final bool isLoading;

  const AdminDashboard({
    super.key,
    this.analyticsData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your Lotto Runners platform',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
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

          const SizedBox(height: 24),

          // Quick Stats
          if (analyticsData != null) ...[
            const Text(
              'Quick Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Total Users',
                  analyticsData!['total_users'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Errands',
                  analyticsData!['total_errands'].toString(),
                  Icons.assignment,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed',
                  analyticsData!['completed_errands'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Revenue',
                  '\$${analyticsData!['total_revenue'].toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildActionCard(
                context,
                'Manage Users',
                Icons.people_alt,
                Colors.blue,
                () => _navigateToPage(context, 1),
              ),
              _buildActionCard(
                context,
                'View Errands',
                Icons.assignment_turned_in,
                Colors.orange,
                () => _navigateToPage(context, 2),
              ),
              _buildActionCard(
                context,
                'Track Payments',
                Icons.payment,
                Colors.green,
                () => _navigateToPage(context, 3),
              ),
              _buildActionCard(
                context,
                'Verify Runners',
                Icons.verified_user,
                Colors.purple,
                () => _navigateToPage(context, 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    if (context.mounted) {
      final scaffold = Scaffold.of(context);
      // This would navigate to the specific page - for now we'll show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigating to page $index')),
      );
    }
  }
}
