import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/profile_page.dart';
import 'package:lotto_runners/pages/transportation_page.dart';
import 'package:lotto_runners/pages/my_orders_page.dart';
import 'package:lotto_runners/pages/my_history_page.dart';
import 'package:lotto_runners/pages/runner_history_page.dart';
import 'package:lotto_runners/pages/admin/admin_home_page.dart';
import 'package:lotto_runners/pages/admin/service_management_page.dart';
import 'package:lotto_runners/pages/admin/user_management_page.dart';
import 'package:lotto_runners/pages/admin/transportation_management_page.dart';
import 'package:lotto_runners/pages/admin/vehicle_discount_management_page.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/pages/available_errands_page.dart';
import 'package:lotto_runners/pages/runner_dashboard_page.dart';
import 'package:lotto_runners/pages/runner_messages_page.dart';
import 'package:lotto_runners/pages/runner_home_page.dart';
import 'package:lotto_runners/pages/service_selection_page.dart';
import 'bus_booking_page.dart';
import 'contract_booking_page.dart';
import 'package:lotto_runners/services/errand_acceptance_notification_service.dart';
import 'package:lotto_runners/services/transportation_acceptance_notification_service.dart';
// Import page transitions for fun customer animations
import 'package:lotto_runners/utils/page_transitions.dart';
// Import custom icons
import 'package:lotto_runners/widgets/custom_icons.dart';
import 'package:lotto_runners/widgets/terms_acceptance_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Initialize errand acceptance notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrandAcceptanceNotificationService.instance.startMonitoring(context);
      TransportationAcceptanceNotificationService.instance.startMonitoring(
        context,
      );
    });
  }

  @override
  void dispose() {
    ErrandAcceptanceNotificationService.instance.stopMonitoring();
    TransportationAcceptanceNotificationService.instance.stopMonitoring();
    super.dispose();
  }

  /// Public method to set the current tab index (for external navigation)
  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
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
          _loadDashboardStats();
          
          // Check if terms have been accepted
          _checkTermsAcceptance(profile);
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

  /// Check if user has accepted terms and show dialog if not
  void _checkTermsAcceptance(Map<String, dynamic>? profile) {
    if (profile == null) return;
    
    final termsAccepted = profile['terms_accepted'] as bool? ?? false;
    final userType = profile['user_type'] as String? ?? 'individual';
    
    if (!termsAccepted && mounted) {
      // Show terms acceptance dialog after a short delay to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTermsAcceptanceDialog(userType);
        }
      });
    }
  }

  /// Show the terms acceptance dialog
  void _showTermsAcceptanceDialog(String userType) {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss without accepting
      builder: (context) => TermsAcceptanceDialog(
        userType: userType,
        onAccepted: () async {
          // Mark terms as accepted
          final success = await SupabaseConfig.acceptTermsAndConditions();
          
          if (success && mounted) {
            // Update local profile state
            setState(() {
              if (_userProfile != null) {
                _userProfile!['terms_accepted'] = true;
                _userProfile!['terms_accepted_at'] = DateTime.now().toIso8601String();
              }
            });
            
            // Close dialog
            Navigator.of(context).pop();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Terms & Conditions accepted'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to accept terms. Please try again.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _loadDashboardStats() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final errands = await SupabaseConfig.getMyErrands(userId);

        int total = errands.length;
        int completed = errands.where((e) => e['status'] == 'completed').length;
        int inProgress = errands
            .where(
              (e) => e['status'] == 'in_progress' || e['status'] == 'accepted',
            )
            .length;

        double savings = 0.0;
        for (var errand in errands) {
          if (errand['status'] == 'completed') {
            savings += (errand['price_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Statistics calculated but not displayed
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
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
              ),
            ),
            child: _buildSidebar(userType),
          ),
          // Main content with animated transitions (matching PageTransitions.slideAndFade)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _getPages(userType)[_currentIndex],
              ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userType = _userProfile?['user_type'] ?? 'individual';

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _getPages(userType)[_currentIndex],
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lotto Runners',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, $userName',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
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
              ? LottoRunnersColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isDestructive
                  ? Theme.of(context).colorScheme.error
                  : isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
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
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          isActive: _currentIndex == 0,
          onTap: () => setState(() => _currentIndex = 0),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: 'Available',
          isActive: _currentIndex == 1,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'My Orders',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.history_outlined,
          activeIcon: Icons.history,
          label: 'My History',
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
          icon: Icons.local_offer_outlined,
          activeIcon: Icons.local_offer,
          label: 'Ride Discounts',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
          label: 'Transportation',
          isActive: _currentIndex == 3,
          onTap: () => setState(() => _currentIndex = 3),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'User Management',
          isActive: _currentIndex == 4,
          onTap: () => setState(() => _currentIndex = 4),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: _currentIndex == 5,
          onTap: () => setState(() => _currentIndex = 5),
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
          label: 'My Orders',
          isActive: _currentIndex == 1,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
          label: 'History',
          isActive: _currentIndex == 2,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        const SizedBox(height: 8),
        _buildSidebarItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
          isActive: _currentIndex == 3,
          onTap: () => setState(() => _currentIndex = 3),
        ),
      ];
    }
  }

  List<Widget> _getPages(String userType) {
    switch (userType) {
      case 'runner':
        return [
          RunnerHomePage(
            onNavigateToTab: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ), // Home page with greeting, stats, and analytics
          const AvailableErrandsPage(), // Browse available errands to accept
          const RunnerDashboardPage(), // Manage accepted errands
          const RunnerHistoryPage(), // View completed errands and transportation bookings
          const ProfilePage(),
        ];
      case 'admin':
      case 'super_admin':
        return [
          _buildAdminDashboard(),
          _buildAdminServiceManagement(),
          _buildVehicleDiscountManagement(),
          _buildTransportationManagement(),
          _buildAdminUserManagement(),
          const ProfilePage(),
        ];
      case 'business':
      case 'individual':
      default:
        return [
          _buildDashboard(),
          const MyOrdersPage(),
          const MyHistoryPage(),
          const ProfilePage(),
        ];
    }
  }

  Widget _buildBottomNavBar(BuildContext context, String userType) {
    List<BottomNavigationBarItem> items;

    if (userType == 'runner') {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Available',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'History',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (userType == 'admin' || userType == 'super_admin') {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.build_outlined),
          activeIcon: Icon(Icons.build),
          label: 'Services',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.local_offer_outlined),
          activeIcon: Icon(Icons.local_offer),
          label: 'Discounts',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: 'Transport',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Users',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      items = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          activeIcon: Icon(Icons.history),
          label: 'My History',
        ),
        const BottomNavigationBarItem(
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
      selectedItemColor: LottoRunnersColors.primaryYellow,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  //Dashboard the one with the
  Widget _buildDashboard() {
    final userType = _userProfile?['user_type'] ?? 'individual';
    final userName = _userProfile?['full_name'] ?? 'User';
    final isDesktop = Responsive.isDesktop(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

      return Scaffold(
        backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(userName, userType),

            // Main Content - Now empty since everything is in the hero section card
            const SizedBox.shrink(),
          ],
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                PageTransitions.scale(const ServiceSelectionPage()),
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
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isTablet = Responsive.isTablet(context);

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1200 : double.infinity,
        ),
        padding: EdgeInsets.all(isSmallMobile ? 16 : (isDesktop ? 40 : 24)),
        child: Column(
          children: [
             // Main card container - combined with recent activity
             Container(
               padding: EdgeInsets.all(isSmallMobile ? 20 : (isDesktop ? 32 : 24)),
               decoration: BoxDecoration(
                 color: Theme.of(context).brightness == Brightness.dark 
                     ? Theme.of(context).colorScheme.surfaceContainerHighest 
                     : Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(
                     color: Theme.of(context).brightness == Brightness.dark
                         ? Colors.black.withOpacity(0.3)
                         : Colors.black.withOpacity(0.05),
                     blurRadius: 20,
                     offset: const Offset(0, 10),
                   ),
                 ],
               ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with profile and greeting
                  Row(
                    children: [
                      Container(
                        width: isSmallMobile ? 50 : (isDesktop ? 60 : 55),
                        height: isSmallMobile ? 50 : (isDesktop ? 60 : 55),
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(25),
                           border: Border.all(
                             color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                             width: 1,
                           ),
                         ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _userProfile?['avatar_url'] != null
                              ? Image.network(
                                  _userProfile!['avatar_url'],
                                  width: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
                                  height: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(userType, isDesktop),
                                )
                              : _buildDefaultAvatar(userType, isDesktop),
                        ),
                      ),
                      SizedBox(width: isSmallMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  LottoRunnersColors.primaryBlue,
                                  LottoRunnersColors.primaryYellow,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: Text(
                                'Hello $userName!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallMobile ? 20 : (isDesktop ? 28 : 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                             SizedBox(height: isSmallMobile ? 4 : 6),
                             Text(
                               'What are you looking for?',
                               style: TextStyle(
                                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                 fontSize: isSmallMobile ? 12 : (isDesktop ? 16 : 14),
                               ),
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallMobile ? 24 : 32),

                  // Action buttons layout: 1 on top, 3 below
                  Column(
                    children: [
                      // Top button - Request an Errand (full width, horizontal layout)
                      _buildHorizontalActionButton(
                        icon: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'web/icons/lotto runners icon 192.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.directions_run,
                              size: 32,
                              color: LottoRunnersColors.primaryBlue,
                            ),
                          ),
                        ),
                        title: 'Request an Errand',
                        subtitle: 'Best way to move items',
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.rotateAndScale(
                            const ServiceSelectionPage(),
                          ),
                        ),
                        isSmallMobile: isSmallMobile,
                      ),
                      SizedBox(height: isSmallMobile ? 12 : 16),
                      
                      // Bottom row - Three buttons side by side
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Image.network(
                                'https://irfbqpruvkkbylwwikwx.supabase.co/storage/v1/object/public/icons/contract.jpg',
                                width: 90,
                                height: 90,
                                fit: BoxFit.contain,
                                cacheWidth: 180,
                                cacheHeight: 180,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryYellow.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading contract.png: $error');
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryYellow.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_seat,
                                      size: 50,
                                      color: LottoRunnersColors.primaryYellow,
                                    ),
                                  );
                                },
                              ),
                              label: 'Contract Rides',
                              onTap: () => Navigator.push(
                                context,
                                PageTransitions.scale(const ContractBookingPage()),
                              ),
                              isSmallMobile: isSmallMobile,
                            ),
                          ),
                          SizedBox(width: isSmallMobile ? 8 : 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Image.network(
                                'https://irfbqpruvkkbylwwikwx.supabase.co/storage/v1/object/public/icons/bus1.png',
                                width: 90,
                                height: 90,
                                fit: BoxFit.contain,
                                cacheWidth: 180,
                                cacheHeight: 180,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading bus1.png: $error');
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.directions_bus,
                                      size: 50,
                                      color: LottoRunnersColors.primaryBlue,
                                    ),
                                  );
                                },
                              ),
                              label: 'Bus Services',
                              onTap: () => Navigator.push(
                                context,
                                PageTransitions.rotateAndScale(const BusBookingPage()),
                              ),
                              isSmallMobile: isSmallMobile,
                            ),
                          ),
                          SizedBox(width: isSmallMobile ? 8 : 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Image.network(
                                'https://irfbqpruvkkbylwwikwx.supabase.co/storage/v1/object/public/icons/car.png',
                                width: 90,
                                height: 90,
                                fit: BoxFit.contain,
                                cacheWidth: 180,
                                cacheHeight: 180,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading car.png: $error');
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      size: 50,
                                      color: LottoRunnersColors.primaryBlue,
                                    ),
                                  );
                                },
                              ),
                              label: 'Request a Ride',
                              onTap: () => Navigator.push(
                                context,
                                PageTransitions.scale(const TransportationPage()),
                              ),
                              isSmallMobile: isSmallMobile,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Add divider before Recent Activity
                  SizedBox(height: isSmallMobile ? 24 : 32),
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: isSmallMobile ? 24 : 32),
                  // Recent Activity section (now inside main card)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: isSmallMobile ? 18.0 : 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _currentIndex = 1; // Navigate to My Orders tab
                        }),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallMobile ? 12.0 : 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallMobile ? 16 : 24),
                  _buildRecentActivityContent(isDesktop, isSmallMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalActionButton({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSmallMobile,
  }) {
    return _AnimatedShimmerButton(
      onTap: onTap,
      isSmallMobile: isSmallMobile,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: isSmallMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallMobile ? 4 : 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isSmallMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Container(
            width: isSmallMobile ? 48 : 56,
            height: isSmallMobile ? 48 : 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          SizedBox(width: isSmallMobile ? 8 : 12),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            size: isSmallMobile ? 16 : 18,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmallMobile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
       child: Container(
         height: isSmallMobile ? 160 : 180,
         decoration: BoxDecoration(
           color: Theme.of(context).brightness == Brightness.dark 
               ? Theme.of(context).colorScheme.surface 
               : Colors.white,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(
             color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
             width: 1,
           ),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02),
               blurRadius: 8,
               offset: const Offset(0, 2),
             ),
           ],
         ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallMobile ? 90 : 100,
              height: isSmallMobile ? 90 : 100,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: icon),
            ),
            SizedBox(height: isSmallMobile ? 8 : 12),
             Text(
               label,
               style: TextStyle(
                 color: Theme.of(context).colorScheme.onSurface,
                 fontSize: isSmallMobile ? 12 : 14,
                 fontWeight: FontWeight.w600,
               ),
               textAlign: TextAlign.center,
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
             ),
          ],
        ),
      ),
    );
  }

  // _buildRecentActivity is now integrated into the main card
  // Keeping this method for backward compatibility but it's no longer used
  Widget _buildRecentActivity(bool isDesktop) {
    // This method is deprecated - content is now in the main card
    return const SizedBox.shrink();
  }

  Widget _buildRecentActivityContent(bool isDesktop, bool isSmallMobile) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRecentTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: isSmallMobile ? 150 : 200,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(
              isSmallMobile ? 24 : (isDesktop ? 40 : 32),
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: isSmallMobile ? 36 : (isDesktop ? 48 : 36),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: isSmallMobile ? 12 : 16),
                Text(
                  'Failed to load recent activity',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final recentItems = snapshot.data ?? [];

        if (recentItems.isEmpty) {
          return Container(
            padding: EdgeInsets.all(
              isSmallMobile ? 24 : (isDesktop ? 40 : 32),
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: isSmallMobile ? 64 : 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent errands and bookings will appear here once you start using the platform.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: recentItems
              .take(3)
              .map((item) => _buildRecentActivityItem(item, isDesktop))
              .toList(),
        );
      },
    );
  }

  // Widget _buildPopularServicesSection(bool isDesktop) {
  //   final gridConfig = Responsive.getHomeServiceGridConfig(context);

  //   return Container(
  //     padding: EdgeInsets.all(gridConfig['sectionPadding']),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
  //           blurRadius: 20,
  //           offset: const Offset(0, 10),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Popular Services',
  //           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //         ),
  //         SizedBox(height: gridConfig['sectionPadding'] * 0.75),
  //         // Use responsive grid configuration to prevent overflow
  //         GridView.builder(
  //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: gridConfig['crossAxisCount'],
  //             crossAxisSpacing: gridConfig['crossAxisSpacing'],
  //             mainAxisSpacing: gridConfig['mainAxisSpacing'],
  //             childAspectRatio: gridConfig['childAspectRatio'],
  //           ),
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           itemCount: 4,
  //           itemBuilder: (context, index) {
  //             switch (index) {
  //               case 0:
  //                 return DocumentDeliveryCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => const PostErrandPage()),
  //                   ),
  //                 );
  //               case 1:
  //                 return FoodDeliveryCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => const PostErrandPage()),
  //                   ),
  //                 );
  //               case 2:
  //                 return PackageDeliveryCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => const PostErrandPage()),
  //                   ),
  //                 );
  //               case 3:
  //                 return GroceryShoppingCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                         builder: (context) => const PostErrandPage()),
  //                   ),
  //                 );
  //               default:
  //                 return const SizedBox.shrink();
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTransportServicesSection(bool isDesktop) {
  //   final gridConfig = Responsive.getTransportServiceGridConfig(context);

  //   return Container(
  //     padding: EdgeInsets.all(gridConfig['sectionPadding']),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
  //           blurRadius: 20,
  //           offset: const Offset(0, 10),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 'Transport Services',
  //                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => const TransportationPage(),
  //                 ),
  //               ),
  //               child: Text(
  //                 'View All',
  //                 style: TextStyle(
  //                   color: Theme.of(context).colorScheme.primary,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: gridConfig['sectionPadding'] * 0.75),
  //         GridView.builder(
  //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: gridConfig['crossAxisCount'],
  //             crossAxisSpacing: gridConfig['crossAxisSpacing'],
  //             mainAxisSpacing: gridConfig['mainAxisSpacing'],
  //             childAspectRatio: gridConfig['childAspectRatio'],
  //           ),
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           itemCount: 2,
  //           itemBuilder: (context, index) {
  //             switch (index) {
  //               case 0:
  //                 return ShuttleServiceCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => const TransportationPage(),
  //                     ),
  //                   ),
  //                 );
  //               case 1:
  //                 return BusServiceCard(
  //                   onTap: () => Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => const TransportationPage(),
  //                     ),
  //                   ),
  //                 );
  //               default:
  //                 return const SizedBox.shrink();
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<List<Map<String, dynamic>>> _getRecentTransactions() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      // Load recent errands and transportation bookings
      final errands = await SupabaseConfig.getMyErrands(userId);
      final bookings = await SupabaseConfig.getUserBookings(userId);

      List<Map<String, dynamic>> recentItems = [];

      // Add errands with type identifier
      for (var errand in errands) {
        recentItems.add({
          ...errand,
          'item_type': 'errand',
          'sort_date': errand['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // Add all bookings with appropriate type identifiers
      for (var booking in bookings) {
        String itemType = 'transportation';
        String title = 'Shuttle Services';

        // Determine type and title based on booking_type
        if (booking['booking_type'] == 'bus') {
          itemType = 'bus';
          title = 'Bus Service';
        } else if (booking['booking_type'] == 'contract') {
          itemType = 'contract';
          title = 'Contract Booking';
        } else if (booking['booking_type'] == 'transportation') {
          itemType = 'transportation';
          title = 'Shuttle Services';
        }

        recentItems.add({
          ...booking,
          'item_type': itemType,
          'title': title,
          'category': itemType,
          'description':
              '${booking['pickup_location']} → ${booking['dropoff_location']}',
          'sort_date':
              booking['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // Sort by creation date (newest first) and return only the most recent 5
      recentItems.sort((a, b) {
        final dateA = DateTime.tryParse(a['sort_date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['sort_date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return recentItems.take(5).toList();
    } catch (e) {
      print('Error loading recent transactions: $e');
      return [];
    }
  }

  Widget _buildRecentActivityItem(Map<String, dynamic> item, bool isDesktop) {
    final isErrand = item['item_type'] == 'errand';
    final title = item['title'] ?? (isErrand ? 'Errand' : 'Service');
    final subtitle = isErrand
        ? item['description'] ?? ''
        : '${item['pickup_location'] ?? ''} → ${item['dropoff_location'] ?? ''}';
    final status = item['status']?.toString().toUpperCase() ?? 'PENDING';
    final createdAt = item['created_at'] ?? item['sort_date'];
    final isSmallMobile = Responsive.isSmallMobile(context);

      Color statusColor;
      switch (status.toLowerCase()) {
        case 'completed':
          statusColor = LottoRunnersColors.accent; // Green color for success
          break;
        case 'in_progress':
        case 'accepted':
          statusColor = LottoRunnersColors.primaryBlue;
          break;
        case 'cancelled':
          statusColor = Theme.of(context).colorScheme.error; // Red color for error
          break;
        default:
          statusColor = LottoRunnersColors.orange; // Orange for pending
      }

    return Container(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
      padding: EdgeInsets.all(isSmallMobile ? 16 : (isDesktop ? 20 : 18)),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1), 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 40 : (isDesktop ? 48 : 44),
            height: isSmallMobile ? 40 : (isDesktop ? 48 : 44),
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isErrand ? Icons.description_outlined : Icons.directions_bus_outlined,
              color: LottoRunnersColors.primaryBlue,
              size: isSmallMobile ? 20 : (isDesktop ? 24 : 22),
            ),
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallMobile ? 14 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: isSmallMobile ? 2 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: isSmallMobile ? 11 : 12,
                      height: 1.2,
                    ),
                    maxLines: isSmallMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isSmallMobile ? 8 : 10),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 8 : 10,
                        vertical: isSmallMobile ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: isSmallMobile ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                      Text(
                        _formatRecentDate(createdAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: isSmallMobile ? 10 : 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRecentDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildDefaultAvatar(String userType, bool isDesktop) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      width: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
      height: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LottoRunnersColors.primaryBlue.withOpacity(0.1),
            LottoRunnersColors.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        _getUserTypeIcon(userType),
        color: LottoRunnersColors.primaryBlue.withOpacity(0.7),
        size: isSmallMobile ? 20 : (isDesktop ? 28 : 24),
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

  Widget _buildVehicleDiscountManagement() {
    return const VehicleDiscountManagementPage();
  }
}

// Animated shimmer button widget
class _AnimatedShimmerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSmallMobile;

  const _AnimatedShimmerButton({
    required this.child,
    required this.onTap,
    required this.isSmallMobile,
  });

  @override
  State<_AnimatedShimmerButton> createState() => _AnimatedShimmerButtonState();
}

class _AnimatedShimmerButtonState extends State<_AnimatedShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(widget.isSmallMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.2
                          : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer effect overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Transform.translate(
                      offset: Offset(_animation.value * 200, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              LottoRunnersColors.primaryYellow.withOpacity(0.1),
                              LottoRunnersColors.primaryYellow.withOpacity(0.3),
                              LottoRunnersColors.primaryYellow.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                child!,
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
