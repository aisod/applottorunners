import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/post_errand_page.dart';
import 'package:lotto_runners/pages/browse_errands_page.dart';
import 'package:lotto_runners/pages/my_errands_page.dart';
import 'package:lotto_runners/pages/profile_page.dart';
import 'package:lotto_runners/pages/admin/admin_home_page.dart';
import 'package:lotto_runners/pages/admin/service_management_page.dart';
import 'package:lotto_runners/pages/admin/user_management_page.dart';
import 'package:lotto_runners/pages/admin/transportation_management_page.dart';
import 'package:lotto_runners/widgets/service_selector.dart';
import 'package:lotto_runners/utils/responsive.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _totalErrands = 0;
  int _completedErrands = 0;
  int _inProgressErrands = 0;
  double _totalSavings = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
          _animationController.forward();
          _loadDashboardStats();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final errands = await SupabaseConfig.getMyErrands(userId);

        int total = errands.length;
        int completed = errands.where((e) => e['status'] == 'completed').length;
        int inProgress = errands
            .where((e) =>
                e['status'] == 'in_progress' || e['status'] == 'accepted')
            .length;

        double savings = 0.0;
        for (var errand in errands) {
          if (errand['status'] == 'completed') {
            savings += (errand['price_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        if (mounted) {
          setState(() {
            _totalErrands = total;
            _completedErrands = completed;
            _inProgressErrands = inProgress;
            _totalSavings = savings;
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive.isDesktop(context)
          ? _buildDesktopLayout()
          : Responsive.isTablet(context)
              ? _buildTabletLayout()
              : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userType = _userProfile?['user_type'] ?? 'individual';

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: LottoRunnersColors.gray200,
                  width: 1,
                ),
              ),
            ),
            child: _buildSidebar(userType),
          ),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _getPages(userType),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Use mobile layout for tablet
  }

  Widget _buildMobileLayout() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userType = _userProfile?['user_type'] ?? 'individual';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getPages(userType),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, userType),
    );
  }

  Widget _buildSidebar(String userType) {
    final userName = _userProfile?['full_name'] ?? 'User';

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LottoRunnersColors.primaryBlue,
                LottoRunnersColors.primaryBlueDark,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'web/icons/lotto runners icon 192.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.directions_run,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lotto Runners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, $userName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Navigation
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._buildNavigationItems(userType),
                const Spacer(),
                _buildSidebarItem(
                  icon: Icons.logout_outlined,
                  activeIcon: Icons.logout,
                  label: 'Sign Out',
                  isActive: false,
                  onTap: () async => await SupabaseConfig.signOut(),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? LottoRunnersColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isDestructive
                  ? Colors.red
                  : isActive
                      ? LottoRunnersColors.primaryBlue
                      : LottoRunnersColors.gray600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive
                    ? Colors.red
                    : isActive
                        ? LottoRunnersColors.primaryBlue
                        : LottoRunnersColors.gray700,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems(String userType) {
    if (userType == 'runner') {
      return [
        _buildSidebarItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search,
          label: 'Browse Errands',
          isActive: _currentIndex == 0,
          onTap: () => setState(() => _currentIndex = 0),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: 'My Errands',
          isActive: _currentIndex == 1,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
      ];
    } else if (userType == 'admin' || userType == 'super_admin') {
      return [
        _buildSidebarItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: 'Admin Dashboard',
          isActive: _currentIndex == 0,
          onTap: () => setState(() => _currentIndex = 0),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.build_outlined,
          activeIcon: Icons.build,
          label: 'Service Management',
          isActive: _currentIndex == 1,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
          label: 'Transportation',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'User Management',
          isActive: _currentIndex == 3,
          onTap: () => setState(() => _currentIndex = 3),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: _currentIndex == 4,
          onTap: () => setState(() => _currentIndex = 4),
        ),
      ];
    } else {
      return [
        _buildSidebarItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'Dashboard',
          isActive: _currentIndex == 0,
          onTap: () => setState(() => _currentIndex = 0),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: 'My Errands',
          isActive: _currentIndex == 1,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
      ];
    }
  }

  List<Widget> _getPages(String userType) {
    switch (userType) {
      case 'runner':
        return [
          const BrowseErrandsPage(),
          const MyErrandsPage(),
          const ProfilePage(),
        ];
      case 'admin':
      case 'super_admin':
        return [
          _buildAdminDashboard(),
          _buildAdminServiceManagement(),
          _buildTransportationManagement(),
          _buildAdminUserManagement(),
          const ProfilePage(),
        ];
      case 'business':
      case 'individual':
      default:
        return [
          _buildDashboard(),
          const MyErrandsPage(),
          const ProfilePage(),
        ];
    }
  }

  Widget _buildBottomNavBar(BuildContext context, String userType) {
    List<BottomNavigationBarItem> items;

    if (userType == 'runner') {
      items = [
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Errands',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (userType == 'admin' || userType == 'super_admin') {
      items = [
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build_outlined),
          activeIcon: Icon(Icons.build),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: 'Transport',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      items = [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Errands',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: LottoRunnersColors.primaryBlue,
      unselectedItemColor: LottoRunnersColors.gray600,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      elevation: 0,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildDashboard() {
    final userType = _userProfile?['user_type'] ?? 'individual';
    final userName = _userProfile?['full_name'] ?? 'User';
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(userName, userType),

              // Main Content
              Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1200 : double.infinity,
                ),
                padding: EdgeInsets.all(isDesktop ? 40 : 24),
                child: Column(
                  children: [
                    // Stats Section
                    if (isDesktop) _buildStatsSection(),
                    if (isDesktop) const SizedBox(height: 40),

                    // Quick Actions
                    _buildQuickActions(userType, isDesktop),
                    const SizedBox(height: 40),

                    // Recent Activity
                    _buildRecentActivity(isDesktop),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostErrandPage()),
              ),
              backgroundColor: LottoRunnersColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post Errand'),
            )
          : null,
    );
  }

  Widget _buildHeroSection(String userName, String userType) {
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LottoRunnersColors.primaryBlue,
            LottoRunnersColors.primaryBlueDark,
          ],
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1200 : double.infinity,
        ),
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDesktop) const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: isDesktop ? 80 : 60,
                  height: isDesktop ? 80 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _userProfile?['avatar_url'] != null
                        ? Image.network(
                            _userProfile!['avatar_url'],
                            width: isDesktop ? 76 : 56,
                            height: isDesktop ? 76 : 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(userType, isDesktop),
                          )
                        : _buildDefaultAvatar(userType, isDesktop),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getWelcomeMessage(userType),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isDesktop ? 18 : 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDesktop)
                  IconButton(
                    onPressed: () async => await SupabaseConfig.signOut(),
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),

            SizedBox(height: isDesktop ? 40 : 24),

            // CTA Section
            if (isDesktop) _buildHeroCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCTA() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to get started?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post your first errand and connect with trusted runners in your area.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PostErrandPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryYellow,
                    foregroundColor: LottoRunnersColors.gray900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Post New Errand',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildStatCard('Total Errands', '$_totalErrands',
                  Icons.assignment, LottoRunnersColors.primaryBlue)),
          const SizedBox(width: 32),
          Expanded(
              child: _buildStatCard('Completed', '$_completedErrands',
                  Icons.check_circle, LottoRunnersColors.accent)),
          const SizedBox(width: 32),
          Expanded(
              child: _buildStatCard('In Progress', '$_inProgressErrands',
                  Icons.schedule, LottoRunnersColors.primaryYellow)),
          const SizedBox(width: 32),
          Expanded(
              child: _buildStatCard(
                  'Savings',
                  'N\$' + _totalSavings.toStringAsFixed(2),
                  Icons.savings,
                  LottoRunnersColors.primaryBlue)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: LottoRunnersColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: LottoRunnersColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(String userType, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.gray900,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: isDesktop ? 24 : 16,
            mainAxisSpacing: isDesktop ? 24 : 16,
            childAspectRatio: isDesktop ? 1.0 : 1.1,
            children: [
              _buildActionCard(
                'Post New Errand',
                'Create a new task',
                Icons.add_task,
                LottoRunnersColors.primaryBlue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PostErrandPage()),
                ),
                isDesktop,
              ),
              _buildActionCard(
                'Transportation',
                'Book bus & shuttle services',
                Icons.directions_bus,
                LottoRunnersColors.accent,
                () => _showTransportationServices(),
                isDesktop,
              ),
              _buildActionCard(
                'Browse Runners',
                'Find verified runners',
                Icons.people_alt,
                LottoRunnersColors.primaryYellow,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BrowseErrandsPage()),
                ),
                isDesktop,
              ),
              _buildActionCard(
                'Track Errands',
                'Monitor your tasks',
                Icons.location_on,
                LottoRunnersColors.primaryBlue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyErrandsPage()),
                ),
                isDesktop,
              ),
              _buildActionCard(
                'Profile Settings',
                'Manage your account',
                Icons.settings,
                LottoRunnersColors.gray700,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ),
                isDesktop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransportationServices() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LottoRunnersColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: LottoRunnersColors.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Transportation Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LottoRunnersColors.gray900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Service Selector
              Expanded(
                child: ServiceSelector(
                  showTransportationOnly: true,
                  onServiceSelected: (service) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Transportation service selected: ${service['name']}'),
                        backgroundColor: LottoRunnersColors.accent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          color: LottoRunnersColors.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LottoRunnersColors.gray200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 60 : 48,
              height: isDesktop ? 60 : 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: isDesktop ? 28 : 24,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: LottoRunnersColors.gray900,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  color: LottoRunnersColors.gray600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.gray900,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(isDesktop ? 40 : 32),
            decoration: BoxDecoration(
              color: LottoRunnersColors.gray50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: isDesktop ? 64 : 48,
                  color: LottoRunnersColors.gray400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: LottoRunnersColors.gray700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent errands and updates will appear here once you start using the platform.',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: LottoRunnersColors.gray600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String userType, bool isDesktop) {
    return Container(
      width: isDesktop ? 76 : 56,
      height: isDesktop ? 76 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        userType == 'business'
            ? Icons.business_center
            : userType == 'runner'
                ? Icons.directions_run
                : Icons.person,
        color: Colors.white,
        size: isDesktop ? 40 : 28,
      ),
    );
  }

  String _getWelcomeMessage(String userType) {
    switch (userType) {
      case 'business':
        return 'Streamline your business operations with trusted runners.';
      case 'runner':
        return 'Ready to help others and earn money running errands?';
      case 'admin':
      case 'super_admin':
        return 'Manage your platform and services here.';
      default:
        return 'What can we help you with today?';
    }
  }

  // Admin Dashboard Methods
  Widget _buildAdminDashboard() {
    return const AdminHomePage();
  }

  Widget _buildAdminServiceManagement() {
    return const ServiceManagementPage();
  }

  Widget _buildAdminUserManagement() {
    return const UserManagementPage();
  }

  Widget _buildTransportationManagement() {
    return const TransportationManagementPage();
  }
}
