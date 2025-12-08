import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:intl/intl.dart';
import 'package:lotto_runners/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lotto_runners/pages/chat_page.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:lotto_runners/widgets/theme_toggle_button.dart';
import 'package:lotto_runners/widgets/errand_card.dart';
import 'package:lotto_runners/widgets/service_card.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/utils/breakpoints.dart';
import 'package:lotto_runners/widgets/new_ride_request_popup.dart';
import 'package:lotto_runners/services/global_ride_popup_service.dart';
import 'package:lotto_runners/services/global_errand_popup_service.dart';
import 'package:lotto_runners/services/global_transportation_popup_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_runners/pages/profile_page.dart';
import 'package:lotto_runners/pages/runner_wallet_page.dart';
import 'package:lotto_runners/utils/page_transitions.dart';

class RunnerDashboardPage extends StatefulWidget {
  const RunnerDashboardPage({super.key});

  @override
  State<RunnerDashboardPage> createState() => _RunnerDashboardPageState();
}

class _RunnerDashboardPageState extends State<RunnerDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _transportationBookings = [];
  bool _isLoading = true;
  bool _isLoadingBookings = true;
  Map<String, dynamic> _runnerLimits = {};
  bool _isLoadingLimits = true;
  Map<String, dynamic>? _userProfile;

  // Debug information
  String _debugInfo = '';
  bool _showDebugInfo = false;
  String _selectedStatus = 'all';
  bool _isRefreshing = false;

  // Notifications
  // ignore: unused_field
  int _unreadNotificationCount = 0;

  // Note: Ride request popups now handled by GlobalRidePopupService

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All', 'icon': 'all_inclusive'},
    {'value': 'accepted', 'label': 'Accepted', 'icon': 'check_circle'},
    {'value': 'in_progress', 'label': 'In Progress', 'icon': 'play_circle'},
    {'value': 'completed', 'label': 'Completed', 'icon': 'done_all'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    // Start automatic refresh every 30 seconds
    _startAutoRefresh();

    // Initialize popup services for ride, errand, and transportation requests
    // Note: Global ride popup service handles ride notifications now
    // Global errand popup service handles errand notifications
    // Global transportation popup service handles transportation notifications
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    try {
      await Future.wait([
        _loadUserProfile(),
        _loadRunnerErrands(),
        _loadTransportationBookings(),
        _loadRunnerLimits(),
        _loadNotifications(),
      ]);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getCompleteUserProfile(userId);
        setState(() => _userProfile = profile);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadRunnerErrands() async {
    try {
      setState(() => _isLoading = true);
      final userId = SupabaseConfig.currentUser?.id;
      print('🔄 Loading runner errands for user: $userId');

      if (userId != null) {
        final errands = await SupabaseConfig.getRunnerErrands(userId);
        print(
            '📋 Loaded ${errands.length} errands: ${errands.map((e) => '${e['title']} (${e['status']})').toList()}');

        if (mounted) {
          setState(() {
            _errands = errands;
            _isLoading = false;
          });
          print('✅ Updated state with ${_errands.length} errands');
        }
      } else {
        print('❌ No user ID found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading runner errands: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTransportationBookings() async {
    try {
      setState(() => _isLoadingBookings = true);

      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingBookings = false);
        return;
      }

      // Get all bookings assigned to this runner (transportation + contracts)
      final runnerBookings = await SupabaseConfig.getRunnerAllBookings(userId);

      // Get runner's vehicle type to filter available bookings
      final runnerVehicleType =
          await SupabaseConfig.getRunnerVehicleType(userId);
      print('🚗 Runner vehicle type: $runnerVehicleType');

      // Get all available bookings (transportation + contracts)
      final availableBookings = await SupabaseConfig.getAvailableAllBookings();

      // Filter to only show bookings that match the runner's vehicle type
      final pendingBookings = availableBookings.where((booking) {
        if (booking['status'] != 'pending' || booking['driver_id'] != null) {
          return false;
        }

        // Contract bookings don't have vehicle types, so include them all
        if (booking['booking_type'] == 'contract') {
          return true;
        }

        // For transportation bookings, apply vehicle type filtering
        final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';

        // If transportation booking has no vehicle type requirement (null or empty), show to all runners
        if (bookingVehicleType.isEmpty) {
          return true; // Transportation bookings without vehicle type can be done by anyone
        }

        // If transportation booking requires a specific vehicle type, only show to runners with matching vehicle type
        if (runnerVehicleType == null || runnerVehicleType.isEmpty) {
          return false; // Runner doesn't have a vehicle type, can't do vehicle transportation bookings
        }

        return bookingVehicleType.toLowerCase() ==
            runnerVehicleType.toLowerCase();
      }).toList();

      print(
          '🎯 Available bookings for vehicle type $runnerVehicleType: ${pendingBookings.length}');

      // Combine runner bookings and available bookings
      final allBookings = [...runnerBookings, ...pendingBookings];

      if (mounted) {
        setState(() {
          _transportationBookings = allBookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
        _showErrorSnackBar('Failed to load bookings. Please try again.');
      }
    }
  }

  Future<void> _loadRunnerLimits() async {
    try {
      setState(() => _isLoadingLimits = true);
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final limits = await SupabaseConfig.checkRunnerLimits(userId);
        if (mounted) {
          setState(() {
            _runnerLimits = limits;
            _isLoadingLimits = false;
          });
        }
      }
    } catch (e) {
      print('Error loading runner limits: $e');
      if (mounted) {
        setState(() => _isLoadingLimits = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final unreadCount =
            await SupabaseConfig.getUnreadNotificationCount(userId);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = unreadCount;
          });
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  /// Start automatic refresh timer
  void _startAutoRefresh() {
    // Refresh data every 60 seconds (reduced from 30 seconds)
    Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadData();
        print('🔄 Auto-refreshing runner dashboard data...');
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Note: Transportation booking polling moved to GlobalRidePopupService

  Future<void> _checkForNewTransportationBookings() async {
    try {
      print('🔍 Checking for new transportation bookings...');

      // Get current user and check if they're a runner
      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      // Check if user is an approved runner
      final runnerApp = await SupabaseConfig.client
          .from('runner_applications')
          .select('vehicle_type, verification_status')
          .eq('user_id', user.id)
          .eq('verification_status', 'approved')
          .maybeSingle();

      if (runnerApp == null) {
        print('❌ User is not an approved runner');
        return;
      }

      final runnerVehicleType = runnerApp['vehicle_type'] ?? '';
      print('🚗 Runner vehicle type: $runnerVehicleType');

      // Get all pending immediate bookings
      final bookings = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
            vehicle_type:vehicle_types(name, description)
          ''')
          .eq('status', 'pending')
          .eq('is_immediate', true)
          .filter('driver_id', 'is', null)
          .order('created_at', ascending: false);

      print('📋 Found ${bookings.length} pending immediate bookings');

      for (final booking in bookings) {
        final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';
        print('🎯 Booking vehicle type: $bookingVehicleType');

        // Check if vehicle types match (case insensitive)
        final matches = runnerVehicleType.isEmpty ||
            bookingVehicleType.isEmpty ||
            bookingVehicleType.toLowerCase() == runnerVehicleType.toLowerCase();

        if (matches) {
          // Check if we already have this booking in our current list
          final existsInList =
              _transportationBookings.any((b) => b['id'] == booking['id']);

          // Note: Popup handling moved to GlobalRidePopupService

          if (!existsInList) {
            print(
                '🎉 New matching booking found - but GlobalRidePopupService handles popups now');
            // Just refresh the local list
            await _loadTransportationBookings();
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error checking for new bookings: $e');
    }
  }

  Future<String> _getRunnerVehicleType() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return '';

      // Fetch the runner's approved application to get their vehicle type
      final response = await SupabaseConfig.client
          .from('runner_applications')
          .select('vehicle_type')
          .eq('user_id', user.id)
          .eq('verification_status', 'approved')
          .single();

      return response['vehicle_type'] ?? '';
    } catch (e) {
      print('Error fetching runner vehicle type: $e');
      return '';
    }
  }

  // Note: All popup-related methods moved to GlobalRidePopupService

  void _showSuccessSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Debug section removed

  // Note: Test popup method removed - use GlobalRidePopupService.instance.testPopup() instead

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _addDebugInfo(String message) {
    setState(() {
      _debugInfo +=
          '${DateTime.now().toString().substring(11, 19)}: $message\n';
      _showDebugInfo = true;
    });
    print('🐛 DEBUG UI: $message');
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              _debugInfo.isEmpty
                  ? 'No debug information available'
                  : _debugInfo,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _debugInfo = '';
              });
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredErrands {
    final filtered = _errands.where((errand) {
      if (_selectedStatus == 'all') {
        return ['accepted', 'completed', 'in_progress', 'cancelled']
            .contains(errand['status']);
      }
      return errand['status'] == _selectedStatus;
    }).toList();

    print(
        '🔍 Filtering errands: ${_errands.length} total, ${filtered.length} filtered by status "$_selectedStatus"');
    if (filtered.isNotEmpty) {
      print(
          '📋 Filtered errands: ${filtered.map((e) => '${e['title']} (${e['status']})').toList()}');
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _filteredTransportationBookings {
    final filtered = _transportationBookings.where((booking) {
      if (_selectedStatus == 'all') {
        // Only show accepted, completed, and pending errands in "All" filter
        return ['accepted', 'completed', 'in_progress', 'cancelled']
            .contains(booking['status']);
      }
      return booking['status'] == _selectedStatus;
    }).toList();

    print(
        '🔍 Filtering transportation bookings: ${_transportationBookings.length} total, ${filtered.length} filtered by status "$_selectedStatus"');
    if (filtered.isNotEmpty) {
      print(
          '📋 Filtered transportation bookings: ${filtered.map((b) => '${b['pickup_location']} → ${b['dropoff_location']} (${b['status']})').toList()}');
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debug information
    print(
        '🏗️ Building RunnerDashboardPage - Errands: ${_errands.length}, Status: $_selectedStatus, Loading: $_isLoading');

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAppBar(theme),
                  SliverToBoxAdapter(
                    child: Container(
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              Responsive.isSmallMobile(context) ? 16 : 24,
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(context).colorScheme.onPrimary,
                          indicatorWeight: 3,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 13 : 14,
                          ),
                          tabs: const [
                            Tab(text: 'Errands'),
                            Tab(text: 'Transport'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Runner limits UI removed per design feedback; logic preserved elsewhere
                  if (!_isLoadingLimits)
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                  // Debug button for testing popup
                  // Debug section removed from production UI
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildErrandsTab(theme),
                  _buildTransportationBookingsTab(theme),
                ],
              ),
            ),
          ),
        ),

        // Note: Global popup service handles ride requests now
      ],
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    // Combine errands and transportation/contract services for analytics
    final allServices = [..._errands, ..._transportationBookings];

    final acceptedCount =
        allServices.where((service) => service['status'] == 'accepted').length;
    final inProgressCount = allServices
        .where((service) => service['status'] == 'in_progress')
        .length;
    final completedCount =
        allServices.where((service) => service['status'] == 'completed').length;

    // Debug: Log analytics breakdown
    print('📊 ANALYTICS BREAKDOWN:');
    print(
        '   Errands: ${_errands.length} (Accepted: ${_errands.where((e) => e['status'] == 'accepted').length}, In Progress: ${_errands.where((e) => e['status'] == 'in_progress').length}, Completed: ${_errands.where((e) => e['status'] == 'completed').length})');
    print(
        '   Transportation/Contracts: ${_transportationBookings.length} (Accepted: ${_transportationBookings.where((t) => t['status'] == 'accepted').length}, In Progress: ${_transportationBookings.where((t) => t['status'] == 'in_progress').length}, Completed: ${_transportationBookings.where((t) => t['status'] == 'completed').length})');
    print(
        '   TOTAL: ${allServices.length} (Accepted: $acceptedCount, In Progress: $inProgressCount, Completed: $completedCount)');

    return SliverAppBar(
      expandedHeight: Responsive.isSmallMobile(context) ? 180 : 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              PageTransitions.slideAndFade(const RunnerWalletPage()),
            );
          },
          icon: Icon(
            Icons.account_balance_wallet,
            color: LottoRunnersColors.primaryYellow,
          ),
          tooltip: 'My Wallet',
        ),
        IconButton(
          onPressed: _loadData,
          icon: Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          tooltip: 'Refresh',
        ),
        // ThemeToggleButton(
        //   backgroundColor: Colors.white.withValues(alpha: 0.2),
        //   foregroundColor: Colors.white,
        // ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
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
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(
                  Responsive.isSmallMobile(context) ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My Orders',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize:
                              Responsive.isSmallMobile(context) ? 20.0 : 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(
                      height: Responsive.isSmallMobile(context) ? 16.0 : 20.0),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: _buildStatCard(
                            'Accepted',
                            acceptedCount.toString(),
                            Icons.check_circle,
                            LottoRunnersColors.primaryYellow,
                          ),
                        ),
                        Flexible(
                          child: _buildStatCard(
                            'In Progress',
                            inProgressCount.toString(),
                            Icons.pending,
                            LottoRunnersColors.primaryYellow,
                          ),
                        ),
                        Flexible(
                          child: _buildStatCard(
                            'Completed',
                            completedCount.toString(),
                            Icons.done_all,
                            LottoRunnersColors.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final bool isSmallMobile = Responsive.isSmallMobile(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: isSmallMobile ? 20.0 : 24.0,
        ),
        SizedBox(height: isSmallMobile ? 2.0 : 4.0),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isSmallMobile ? 18.0 : 20.0,
          ),
        ),
        SizedBox(height: isSmallMobile ? 1.0 : 2.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isSmallMobile ? 12.0 : 14.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Removed UI-only limits card and item builders; functional limit checks remain elsewhere.

  Widget _buildStatusFilters(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 45),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status['value'];

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconData(status['icon']!),
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : LottoRunnersColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status['value']!;
                        print(
                            '🔄 Errands status filter changed to: $_selectedStatus');
                      });
                    },
                    backgroundColor: LottoRunnersColors.gray50,
                    selectedColor: LottoRunnersColors.primaryBlue,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    side: BorderSide(
                      color: isSelected
                          ? LottoRunnersColors.primaryBlue
                          : LottoRunnersColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'check_circle':
        return Icons.check_circle;
      case 'play_circle':
        return Icons.play_circle;
      case 'done_all':
        return Icons.done_all;
      case 'schedule':
        return Icons.schedule;
      default:
        return Icons.circle;
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your errands...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrandsList(ThemeData theme) {
    final filteredErrands = _filteredErrands;

    // Check if user is verified - show verification message if not
    if (_userProfile?['is_verified'] != true) {
      return SliverFillRemaining(
        child: _buildVerificationRequiredState(theme),
      );
    }

    if (filteredErrands.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        0,
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final errand = filteredErrands[index];
            return Container(
              margin: EdgeInsets.only(
                  bottom: Responsive.isSmallMobile(context) ? 16.0 : 16.0),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      Responsive.isDesktop(context) ? 800 : double.infinity,
                ),
                child: _buildErrandCard(errand, theme),
              ),
            );
          },
          childCount: filteredErrands.length,
        ),
      ),
    );
  }

  Widget _buildErrandCard(Map<String, dynamic> errand, ThemeData theme) {
    final status = errand['status'];
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: () => _showErrandDetails(errand),
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      errand['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LottoRunnersColors.gray900,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isSmallMobile(context) ? 8 : 12,
                        vertical: Responsive.isSmallMobile(context) ? 4 : 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getStatusText(status).toUpperCase(),
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: LottoRunnersColors.primaryYellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            errand['customer']?['full_name'] ?? 'Customer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 14 : 16,
                            ),
                          ),
                          if (errand['customer']?['phone'] != null)
                            Text(
                              errand['customer']!['phone'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category information
              Row(
                children: [
                  Icon(Icons.category,
                      color: LottoRunnersColors.primaryYellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errand['category']?.toString().toUpperCase() ?? 'ERRAND',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location and time info
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getDisplayLocation(errand),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${errand['time_limit_hours']}h limit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
                ],
              ),

              // Price information
              if (errand['price_amount'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        color: LottoRunnersColors.primaryYellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'N\$${errand['price_amount']?.toString() ?? '0'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              if (status == 'accepted' ||
                  status == 'pending' ||
                  status == 'in_progress') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (status == 'accepted') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startErrand(errand),
                          icon: Icon(Icons.play_arrow,
                              color: LottoRunnersColors.primaryBlue, size: 18),
                          label: Text(
                            'Start Errand',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: LottoRunnersColors.primaryBlue,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                                color: LottoRunnersColors.primaryBlue,
                                width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openChat(errand),
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary, size: 18),
                        label: Text(
                          'Chat',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'pending')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _beginWork(errand),
                          icon: Icon(Icons.work,
                              color: Theme.of(context).colorScheme.onSurface, size: 18),
                          label: Text(
                            'Begin Work',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (status == 'in_progress') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completeErrand(errand),
                          icon: Icon(Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary, size: 18),
                          label: Text(
                            'Complete Errand',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openChat(errand),
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary, size: 18),
                        label: Text(
                          'Chat',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Cancel button for accepted errands only (not in-progress)
                if (status == 'accepted') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(errand),
                      icon: Icon(Icons.cancel,
                          color: Theme.of(context).colorScheme.error, size: 18),
                      label: Text(
                        'Cancel Errand',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 60,
                color: LottoRunnersColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus == 'all'
                  ? 'No errands yet'
                  : 'No $_selectedStatus errands',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedStatus == 'all'
                  ? 'Accept errands from the available list to get started'
                  : 'Try changing the filter to see more errands',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRunnerErrands,
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(
                'Refresh',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRequiredState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 60,
                color: LottoRunnersColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account is currently under review. Once verified, you\'ll be able to view and accept available errands.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: LottoRunnersColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll notify you once your verification is complete. This usually takes 24-48 hours.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to profile page to check verification status
                Navigator.push(
                  context,
                  PageTransitions.slideAndFade(const ProfilePage()),
                );
              },
              icon: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(
                'Check Profile Status',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'accepted':
        return Theme.of(context).colorScheme.secondary;
      case 'pending':
        return Theme.of(context).colorScheme.tertiary;
      case 'in_progress':
        return Theme.of(context).colorScheme.primary;
      case 'completed':
        return Theme.of(context).colorScheme.primaryContainer;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'accepted':
        return 'ACCEPTED';
      case 'pending':
        return 'PENDING';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'UNKNOWN';
    }
  }

  /// Intelligently determines which location field to display based on errand category
  String _getDisplayLocation(Map<String, dynamic> errand) {
    final category = errand['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'shopping':
        // For shopping, show delivery address (where items go), not store locations
        final deliveryAddress = errand['delivery_address'];
        if (deliveryAddress != null && deliveryAddress.toString().trim().isNotEmpty) {
          return 'Deliver to: ${deliveryAddress.toString().trim()}';
        }
        // Fallback to location_address (store names)
        return errand['location_address']?.toString() ?? 'Location TBD';
      
      case 'delivery':
        // For delivery, show pickup → delivery
        final pickupAddress = errand['pickup_address'] ?? errand['location_address'];
        final deliveryAddress = errand['delivery_address'];
        
        if (pickupAddress != null && deliveryAddress != null) {
          final pickup = pickupAddress.toString().trim();
          final delivery = deliveryAddress.toString().trim();
          // Truncate if too long
          final pickupShort = pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final deliveryShort = delivery.length > 20 ? '${delivery.substring(0, 20)}...' : delivery;
          return '$pickupShort → $deliveryShort';
        } else if (pickupAddress != null) {
          return 'From: ${pickupAddress.toString().trim()}';
        } else if (deliveryAddress != null) {
          return 'To: ${deliveryAddress.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Location TBD';
      
      case 'document_services':
      case 'license_discs':
        // These forms may have pickup or just location
        final pickupLocation = errand['pickup_location'] ?? errand['pickup_address'];
        final dropoffLocation = errand['dropoff_location'] ?? errand['dropoff_address'];
        
        if (pickupLocation != null && dropoffLocation != null) {
          final pickup = pickupLocation.toString().trim();
          final dropoff = dropoffLocation.toString().trim();
          final pickupShort = pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final dropoffShort = dropoff.length > 20 ? '${dropoff.substring(0, 20)}...' : dropoff;
          return '$pickupShort → $dropoffShort';
        } else if (pickupLocation != null) {
          return 'Pickup: ${pickupLocation.toString().trim()}';
        }
        // Fallback to location_address
        return errand['location_address']?.toString() ?? 'Location TBD';
      
      case 'elderly_services':
      case 'queue_sitting':
      default:
        // For these services, location_address is the primary location
        return errand['location_address']?.toString() ?? 'Location TBD';
    }
  }

  void _showErrandDetails(Map<String, dynamic> errand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildErrandDetailsSheet(errand),
    );
  }

  Widget _buildErrandDetailsSheet(Map<String, dynamic> errand) {
    final theme = Theme.of(context);
    final status = errand['status'];

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          final isSmallMobile = Responsive.isSmallMobile(context);
          final isMobile = Responsive.isMobile(context);

          return Container(
            padding: EdgeInsets.all(isSmallMobile
                ? 16
                : isMobile
                    ? 20
                    : 24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: isSmallMobile ? 40 : 50,
                      height: isSmallMobile ? 3 : 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 20 : 24),

                  // Title and status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          errand['title'] ?? '',
                          style: TextStyle(
                            fontSize: isSmallMobile
                                ? 18
                                : isMobile
                                    ? 20
                                    : 24,
                            fontWeight: FontWeight.bold,
                            color: LottoRunnersColors.gray900,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallMobile ? 8 : 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallMobile ? 10 : 14,
                            vertical: isSmallMobile ? 5 : 7),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(isSmallMobile ? 16 : 20),
                          border: Border.all(
                              color: _getStatusColor(status)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: isSmallMobile ? 12 : 14),
                            SizedBox(width: isSmallMobile ? 3 : 5),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 9 : 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallMobile ? 20 : 24),

                  // Details sections with icons and better styling
                  _buildDetailRow(
                      'Price',
                      'N\$${errand['price_amount']?.toString() ?? '0'}',
                      Icons.attach_money,
                      theme),
                  _buildDetailRow(
                      'Category',
                      (errand['category'] ?? '').toUpperCase(),
                      Icons.category,
                      theme),
                  _buildDetailRow('Time Limit',
                      '${errand['time_limit_hours']}h', Icons.timer, theme),
                  _buildDetailRow('Location', _getDisplayLocation(errand),
                      Icons.location_on, theme),
                  if (errand['customer'] != null)
                    _buildDetailRow(
                        'Customer',
                        errand['customer']['full_name'] ?? 'Customer',
                        Icons.person,
                        theme),
                  if (errand['customer']?['phone'] != null)
                    _buildDetailRow('Phone', errand['customer']['phone'],
                        Icons.phone, theme),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errand['description'] ?? 'No description provided',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.6,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ),

                  // Documents section for license discs
                  if ((errand['category'] == 'license_discs' ||
                          errand['category'] == 'document_services') &&
                      ((errand['image_urls'] != null &&
                              errand['image_urls'].isNotEmpty) ||
                          (errand['pdf_urls'] != null &&
                              errand['pdf_urls'].isNotEmpty))) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Attached Documents',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentsSection(errand, theme),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  if (status == 'accepted')
                    Container(
                      width: double.infinity,
                      height: isSmallMobile ? 48 : 56,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(isSmallMobile ? 12 : 16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: isSmallMobile ? 15 : 20,
                            offset: Offset(0, isSmallMobile ? 7 : 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startErrand(errand);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isSmallMobile ? 12 : 16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: isSmallMobile ? 20 : 24),
                            SizedBox(width: isSmallMobile ? 8 : 12),
                            Text(
                              'Start Errand',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (status == 'pending')
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.deepOrange,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _beginWork(errand);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work,
                                color: Theme.of(context).colorScheme.onPrimary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Begin Work',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (status == 'in_progress')
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeErrand(errand);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isSmallMobile ? 12 : 16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: isSmallMobile ? 20 : 24),
                            SizedBox(width: isSmallMobile ? 8 : 12),
                            Text(
                              'Complete Errand',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isSmallMobile ? 36 : 40,
            height: isSmallMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
            ),
            child: Icon(icon,
                color: LottoRunnersColors.primaryYellow,
                size: isSmallMobile ? 18 : 20),
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmallMobile ? 2 : 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                            ? 14
                            : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startErrand(Map<String, dynamic> errand) async {
    final theme = Theme.of(context);
    try {
      print(' Starting errand with ID: ${errand['id']}');

      // Start errand directly without confirmation

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Starting errand...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      print('📡 Calling SupabaseConfig.startErrand...');
      await SupabaseConfig.startErrand(errand['id']);
      print(' SupabaseConfig.startErrand completed successfully');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar('Errand started successfully!');
        print('🔄 Refreshing errands list...');
        _loadRunnerErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to start errand. Please try again.');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        String errorMsg = _getUserFriendlyErrorMessage(e.toString());
        _showErrorSnackBar(errorMsg);
      }
    }
  }

  Future<void> _completeErrand(Map<String, dynamic> errand) async {
    final theme = Theme.of(context);
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Errand'),
          content: Text(
              'Are you sure you want to mark "${errand['title']}" as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text('Complete',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Completing errand...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      await SupabaseConfig.completeErrand(errand['id']);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Delete the chat conversation completely since the errand is completed
        final conversation =
            await ChatService.getConversationByErrand(errand['id']);
        if (conversation != null) {
          await ChatService.deleteConversation(conversation['id']);
        }

        _showSuccessSnackBar('Errand completed successfully!');
        _loadRunnerErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to complete errand. Please try again.');
      }
    }
  }

  Widget _buildErrandsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRunnerErrands();
        _showSuccessSnackBar('Errands refreshed!');
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildStatusFilters(theme)),
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingState(theme))
              : _buildErrandsList(theme),
        ],
      ),
    );
  }

  Widget _buildTransportationBookingsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadTransportationBookings();
        _showSuccessSnackBar('Bookings refreshed!');
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildBookingFilters(theme)),
          _isLoadingBookings
              ? SliverFillRemaining(child: _buildLoadingState(theme))
              : _buildTransportationBookingsList(theme),
        ],
      ),
    );
  }

  Widget _buildBookingFilters(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 45),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status['value'];

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconData(status['icon']!),
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : LottoRunnersColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status['value']!;
                        print(
                            '🔄 Transportation status filter changed to: $_selectedStatus');
                      });
                    },
                    backgroundColor: LottoRunnersColors.gray50,
                    selectedColor: LottoRunnersColors.primaryBlue,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    side: BorderSide(
                      color: isSelected
                          ? LottoRunnersColors.primaryBlue
                          : LottoRunnersColors.gray300,
                      width: isSelected ? 2 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportationBookingsList(ThemeData theme) {
    final filteredBookings = _filteredTransportationBookings;

    if (filteredBookings.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyTransportationState(theme));
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        0,
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
        Responsive.isSmallMobile(context) ? 16.0 : 24.0,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final booking = filteredBookings[index];
            return Container(
              margin: EdgeInsets.only(
                  bottom: Responsive.isSmallMobile(context) ? 16.0 : 16.0),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      Responsive.isDesktop(context) ? 800 : double.infinity,
                ),
                child: _buildTransportationBookingCard(booking, theme),
              ),
            );
          },
          childCount: filteredBookings.length,
        ),
      ),
    );
  }

  Widget _buildEmptyTransportationState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.directions_bus,
                size: 60,
                color: LottoRunnersColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus == 'all'
                  ? 'No bookings yet'
                  : 'No $_selectedStatus bookings',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedStatus == 'all'
                  ? 'Accept service requests from customers to get started'
                  : 'Try changing the filter to see more bookings',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadTransportationBookings,
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(
                'Refresh',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationBookingCard(
      Map<String, dynamic> booking, ThemeData theme) {
    final service = booking['service'];
    final schedule = booking['schedule'];
    final user = booking['user'];
    final route = service?['route'];
    final vehicleType = service?['vehicle_type'];

    // Extract service info from special_requests if service is null
    final specialRequests = booking['special_requests'] ?? '';
    String serviceName = service?['name'] ?? 'Transportation Service';
    String vehicleInfo = vehicleType?['name'] ?? 'Vehicle';

    // Parse special_requests for service and vehicle info
    if (service == null && specialRequests.isNotEmpty) {
      final serviceMatch =
          RegExp(r'Service:\s*([^,]+)').firstMatch(specialRequests);
      final vehicleMatch =
          RegExp(r'Vehicle Type:\s*([^,]+)').firstMatch(specialRequests);

      if (serviceMatch != null) {
        serviceName = serviceMatch.group(1)?.trim() ?? serviceName;
      }
      if (vehicleMatch != null) {
        vehicleInfo = vehicleMatch.group(1)?.trim() ?? vehicleInfo;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: () => _showTransportationBookingDetails(booking),
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: Responsive.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking['title'] ?? serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LottoRunnersColors.gray900,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isSmallMobile(context) ? 8 : 12,
                        vertical: Responsive.isSmallMobile(context) ? 4 : 6),
                    decoration: BoxDecoration(
                      color: _getBookingStatusColor(booking['status'])
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _getBookingStatusColor(booking['status'])
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      booking['status']?.toString().toUpperCase() ?? 'PENDING',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: _getBookingStatusColor(booking['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: LottoRunnersColors.primaryYellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['full_name'] ?? 'Customer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 14 : 16,
                            ),
                          ),
                          if (user?['phone'] != null)
                            Text(
                              user!['phone'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Route information - use pickup/dropoff locations from booking
              Row(
                children: [
                  Icon(Icons.route,
                      color: LottoRunnersColors.primaryYellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${booking['pickup_location'] ?? 'Pickup'} → ${booking['dropoff_location'] ?? 'Dropoff'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehicle and schedule info
              Row(
                children: [
                  Icon(Icons.directions_car,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    vehicleInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${booking['booking_date'] ?? 'TBD'} ${booking['booking_time'] ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
                ],
              ),

              // Price information
              if (booking['final_price'] != null ||
                  booking['estimated_price'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        color: LottoRunnersColors.primaryYellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'N\$${booking['final_price'] ?? booking['estimated_price'] ?? '0'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              if (booking['status'] == 'pending' ||
                  booking['status'] == 'accepted' ||
                  booking['status'] == 'in_progress') ...[
                const SizedBox(height: 16),
                if (booking['status'] == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Check booking type and call appropriate acceptance function
                        print(
                            '🔍 DEBUG: Booking type check - booking_type: ${booking['booking_type']}');
                        print(
                            '🔍 DEBUG: Booking type check - booking data: ${booking.toString()}');

                        if (booking['booking_type'] == 'contract') {
                          print('✅ DEBUG: Routing to contract acceptance');
                          _acceptContractBooking(booking);
                        } else {
                          print(
                              '✅ DEBUG: Routing to transportation acceptance');
                          _acceptTransportationBooking(booking);
                        }
                      },
                      icon: Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.onSurface, size: 18),
                      label: Text(
                        'Accept',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (booking['status'] == 'accepted') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startTransportationBooking(booking),
                          icon: Icon(Icons.play_arrow,
                              color: LottoRunnersColors.primaryBlue, size: 18),
                          label: Text(
                            'Start Trip',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: LottoRunnersColors.primaryBlue,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                                color: LottoRunnersColors.primaryBlue,
                                width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openChatWithCustomer(booking),
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary, size: 18),
                        label: Text(
                          'Chat',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Cancel button for accepted bookings only
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelTransportationBooking(booking),
                      icon: Icon(Icons.cancel,
                          color: Theme.of(context).colorScheme.error, size: 18),
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                if (booking['status'] == 'in_progress') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _completeTransportationBooking(booking),
                          icon: Icon(Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary, size: 18),
                          label: Text(
                            'Complete Trip',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openChatWithCustomer(booking),
                        icon: Icon(Icons.chat,
                            color: Theme.of(context).colorScheme.onPrimary, size: 18),
                        label: Text(
                          'Chat',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBookingStatusColor(String? status) {
    final theme = Theme.of(context);
    switch (status?.toLowerCase()) {
      case 'pending':
        return Theme.of(context).colorScheme.tertiary;
      case 'accepted':
        return Theme.of(context).colorScheme.primary;
      case 'completed':
        return Theme.of(context).colorScheme.primary;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  /// Open chat with customer for accepted bookings (transportation or contract)
  Future<void> _openChatWithCustomer(Map<String, dynamic> booking) async {
    try {
      print(
          '🔍 DEBUG: [CHAT] Booking type check - booking_type: ${booking['booking_type']}');

      final isContract = booking['booking_type'] == 'contract';
      final conversationType = isContract ? 'contract' : 'transportation';
      final serviceTitle =
          isContract ? 'Contract Service' : 'Transportation Service';

      print('✅ DEBUG: [CHAT] Using conversation type: $conversationType');

      // Get existing conversation based on booking type
      final conversation = isContract
          ? await ChatService.getConversationByBooking(
              booking['id'], 'contract')
          : await ChatService.getTransportationConversationByBooking(
              booking['id']);

      if (conversation != null) {
        // Navigate to chat page
        if (mounted) {
          final customerName = booking['user']?['full_name'] ?? 'Customer';
          Navigator.push(
            context,
            PageTransitions.slideFromBottom(
              ChatPage(
                conversationId: conversation['id'],
                conversationType: conversationType,
                bookingId: booking['id'],
                otherUserName: customerName,
                serviceTitle: serviceTitle,
              ),
            ),
          );
        }
      } else {
        // Create new conversation if it doesn't exist
        final currentUserId = SupabaseConfig.currentUser?.id;
        if (currentUserId != null) {
          final conversationId = isContract
              ? await ChatService.createContractBookingConversation(
                  bookingId: booking['id'],
                  customerId: booking['user_id'],
                  runnerId: currentUserId,
                  serviceName: serviceTitle,
                )
              : await ChatService.createTransportationConversation(
                  bookingId: booking['id'],
                  customerId: booking['user_id'],
                  runnerId: currentUserId,
                  serviceName: serviceTitle,
                );

          if (conversationId != null && mounted) {
            final customerName = booking['user']?['full_name'] ?? 'Customer';
            Navigator.push(
              context,
              PageTransitions.slideFromBottom(
                ChatPage(
                  conversationId: conversationId,
                  conversationType: conversationType,
                  bookingId: booking['id'],
                  otherUserName: customerName,
                  serviceTitle: serviceTitle,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (mounted) {
        _showErrorSnackBar('Unable to open chat. Please check your internet connection and try again.');
      }
    }
  }

  Future<void> _acceptContractBooking(Map<String, dynamic> booking) async {
    try {
      print('🚀 DEBUG: [CONTRACT] Starting contract booking acceptance...');
      print('🚀 DEBUG: [CONTRACT] Booking type: ${booking['booking_type']}');
      print('🚀 DEBUG: [CONTRACT] Booking ID: ${booking['id']}');
      _addDebugInfo('🚀 Starting contract booking acceptance...');
      _addDebugInfo('📋 Booking data: ${booking.toString()}');
      _addDebugInfo('🆔 Booking ID: ${booking['id']}');

      final userId = SupabaseConfig.currentUser?.id;
      print('👤 DEBUG: [RUNNER DASHBOARD] Current user ID: $userId');

      if (userId == null) {
        print('❌ DEBUG: [RUNNER DASHBOARD] No user ID found');
        _showErrorSnackBar('Please sign in to accept bookings.');
        return;
      }

      // Check if runner can accept more transportation bookings
      print('🚦 DEBUG: [RUNNER DASHBOARD] Runner limits: $_runnerLimits');
      final canAccept = _runnerLimits['can_accept_transportation'] ?? false;
      print(
          '🚦 DEBUG: [RUNNER DASHBOARD] Can accept transportation: $canAccept');

      if (!canAccept) {
        print('❌ DEBUG: [RUNNER DASHBOARD] Runner limit reached');
        _showErrorSnackBar(
          'You have reached the maximum limit of 2 active jobs. Please complete all jobs before accepting new ones.',
        );
        return;
      }

      // Accept contract booking directly without confirmation
      final customerName = booking['user']?['full_name'] ?? 'Unknown Customer';
      final description = booking['description'] ?? 'Contract booking';

      print('✅ DEBUG: [RUNNER DASHBOARD] User confirmed contract acceptance');

      // Accept the contract booking
      try {
        await SupabaseConfig.acceptContractBooking(booking['id'], userId);

        _addDebugInfo('✅ Contract booking accepted successfully');
        _showSuccessSnackBar('Contract booking accepted successfully!');

        // Refresh data
        await _loadData();
      } catch (e) {
        print('❌ DEBUG: [RUNNER DASHBOARD] Contract acceptance error: $e');
        _addDebugInfo('❌ Contract acceptance error: $e');
        String errorMsg = _getUserFriendlyErrorMessage(e.toString());
        _showErrorSnackBar(errorMsg);
        _showDebugDialog();
      }
    } catch (e, stackTrace) {
      print(
          '💥 DEBUG: [RUNNER DASHBOARD] Exception caught in _acceptContractBooking');
      print('💥 DEBUG: [RUNNER DASHBOARD] Error: $e');
      print('💥 DEBUG: [RUNNER DASHBOARD] Stack trace: $stackTrace');

      _addDebugInfo('💥 Exception caught: $e');

      // Check if this is a limit-related error and show user-friendly message
      String errorMessage = _getUserFriendlyErrorMessage(e.toString());
      _showErrorSnackBar(errorMessage);

      // Only show debug dialog for non-limit errors
      if (!e.toString().contains('limit') &&
          !e.toString().contains('maximum')) {
        _showDebugDialog();
      }
    }
  }

  Future<void> _acceptTransportationBooking(
      Map<String, dynamic> booking) async {
    try {
      _addDebugInfo('🚀 Starting transportation booking acceptance...');
      _addDebugInfo('📋 Booking data: ${booking.toString()}');
      _addDebugInfo('🆔 Booking ID: ${booking['id']}');
      _addDebugInfo('🆔 Booking ID type: ${booking['id'].runtimeType}');
      print(
          '🚀 DEBUG: [RUNNER DASHBOARD] Starting transportation booking acceptance...');
      print('📋 DEBUG: [RUNNER DASHBOARD] Booking data: ${booking.toString()}');
      print('🆔 DEBUG: [RUNNER DASHBOARD] Booking ID: ${booking['id']}');
      print(
          '🆔 DEBUG: [RUNNER DASHBOARD] Booking ID type: ${booking['id'].runtimeType}');

      // Check runner limits first
      final userId = SupabaseConfig.currentUser?.id;
      print('👤 DEBUG: [RUNNER DASHBOARD] Current user ID: $userId');

      if (userId == null) {
        print('❌ DEBUG: [RUNNER DASHBOARD] No user ID found');
        _showErrorSnackBar('Please sign in to accept bookings.');
        return;
      }

      // Check if runner can accept more transportation bookings
      print('🚦 DEBUG: [RUNNER DASHBOARD] Runner limits: $_runnerLimits');
      final canAccept = _runnerLimits['can_accept_transportation'] ?? false;
      print(
          '🚦 DEBUG: [RUNNER DASHBOARD] Can accept transportation: $canAccept');

      if (!canAccept) {
        print('❌ DEBUG: [RUNNER DASHBOARD] Runner limit reached');
        _showErrorSnackBar(
          'You have reached the maximum limit of 2 active jobs. Please complete all jobs before accepting new ones.',
        );
        return;
      }

      // Show confirmation dialog
      print('💬 DEBUG: [RUNNER DASHBOARD] Showing confirmation dialog...');

      // Get customer name and booking details
      final customerName = booking['user']?['full_name'] ??
          booking['customer_name'] ??
          'Unknown Customer';
      final pickupLocation = booking['pickup_location'] ?? 'Unknown pickup';
      final dropoffLocation =
          booking['dropoff_location'] ?? 'Unknown destination';

      print('💬 DEBUG: [RUNNER DASHBOARD] Customer name: $customerName');
      print('💬 DEBUG: [RUNNER DASHBOARD] Pickup: $pickupLocation');
      print('💬 DEBUG: [RUNNER DASHBOARD] Dropoff: $dropoffLocation');

      // Accept shuttle service directly without confirmation
      print('💬 DEBUG: [RUNNER DASHBOARD] Accepting shuttle service directly');

      print('✅ DEBUG: [RUNNER DASHBOARD] User confirmed acceptance');

      // Check if this is a bus service (runners cannot accept bus services)
      final serviceName =
          booking['service']?['name'] ?? 'Transportation Service';
      final subcategoryName = booking['service']?['subcategory']?['name'] ?? '';
      final isBusService = subcategoryName.toLowerCase().contains('bus');

      print('🚌 DEBUG: [RUNNER DASHBOARD] Service name: $serviceName');
      print('🚌 DEBUG: [RUNNER DASHBOARD] Subcategory name: $subcategoryName');
      print('🚌 DEBUG: [RUNNER DASHBOARD] Is bus service: $isBusService');

      if (isBusService) {
        print('❌ DEBUG: [RUNNER DASHBOARD] Blocked - this is a bus service');
        _showErrorSnackBar(
            'Runners cannot accept bus service bookings. Bus services are scheduled routes.');
        return;
      }

      // Prepare update data
      final updateData = {
        'status': 'accepted',
        'driver_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 DEBUG: [RUNNER DASHBOARD] Update data: $updateData');
      print('🆔 DEBUG: [RUNNER DASHBOARD] Booking ID: ${booking['id']}');

      // Try to update the booking
      print(
          '🔄 DEBUG: [RUNNER DASHBOARD] Calling updateTransportationBooking...');
      _addDebugInfo('🔄 Calling updateTransportationBooking...');
      _addDebugInfo('🆔 With booking ID: ${booking['id']}');
      _addDebugInfo('📝 With update data: $updateData');

      final success = await SupabaseConfig.updateTransportationBooking(
        booking['id'],
        updateData,
      );

      print('📊 DEBUG: [RUNNER DASHBOARD] Update result: $success');
      _addDebugInfo('📊 Update result: $success');

      if (success) {
        print('✅ DEBUG: [RUNNER DASHBOARD] Booking update successful');
        _addDebugInfo('✅ Booking update successful');

        // Create chat conversation between runner and customer
        print('💬 DEBUG: [RUNNER DASHBOARD] Creating chat conversation...');
        final conversationId =
            await ChatService.createTransportationConversation(
          bookingId: booking['id'],
          customerId: booking['user_id'],
          runnerId: userId,
          serviceName: serviceName,
        );

        print('💬 DEBUG: [RUNNER DASHBOARD] Conversation ID: $conversationId');

        if (conversationId != null) {
          // Notify runner that they successfully accepted the booking
          print('🔔 DEBUG: [RUNNER DASHBOARD] Sending notification...');
          await NotificationService.notifyRunnerTransportationAccepted(
              serviceName);

          _showSuccessSnackBar(
              'Shuttle service accepted successfully! Chat conversation created.');
        } else {
          _showSuccessSnackBar('Shuttle service accepted successfully!');
        }

        // Refresh data to update limits
        print('🔄 DEBUG: [RUNNER DASHBOARD] Refreshing data...');
        await _loadData();
      } else {
        print('❌ DEBUG: [RUNNER DASHBOARD] Booking update failed');
        _addDebugInfo('❌ Booking update failed');
        _addDebugInfo(
            '💡 This might be due to stale data - try refreshing the page');
        _showErrorSnackBar(
            'Failed to accept booking. The booking may have expired or been taken by another runner. Please refresh the page and try again.');
        // Show debug dialog to help diagnose the issue
        _showDebugDialog();
      }
    } catch (e, stackTrace) {
      print(
          '💥 DEBUG: [RUNNER DASHBOARD] Exception caught in _acceptTransportationBooking');
      print('💥 DEBUG: [RUNNER DASHBOARD] Error: $e');
      print('💥 DEBUG: [RUNNER DASHBOARD] Stack trace: $stackTrace');

      _addDebugInfo('💥 Exception caught: $e');
      _addDebugInfo('💥 Stack trace: $stackTrace');

      // Check if this is a limit-related error and show user-friendly message
      String errorMessage = _getUserFriendlyErrorMessage(e.toString());
      _showErrorSnackBar(errorMessage);

      // Only show debug dialog for non-limit errors
      if (!e.toString().contains('limit') &&
          !e.toString().contains('maximum')) {
        _showDebugDialog();
      }
    }
  }

  void _startTransportationBooking(Map<String, dynamic> booking) async {
    final theme = Theme.of(context);
    try {
      // Start transportation service directly without confirmation

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                    'Starting ${booking['booking_type'] == 'contract' ? 'contract service' : 'shuttle service'}...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      // Check booking type and call appropriate start function
      print(
          '🔍 DEBUG: [START TRIP] Booking type check - booking_type: ${booking['booking_type']}');

      if (booking['booking_type'] == 'contract') {
        print('✅ DEBUG: [START TRIP] Starting contract booking');
        await SupabaseConfig.startContractBooking(booking['id']);
      } else {
        print('✅ DEBUG: [START TRIP] Starting transportation booking');
        await SupabaseConfig.startTransportationBooking(booking['id']);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Send notifications
        final serviceName =
            booking['service']?['name'] ?? 'Transportation Service';
        await NotificationService.notifyRunnerTransportationStarted(
            serviceName);
        await NotificationService.notifyTransportationStarted(serviceName);

        _showSuccessSnackBar(
            '${booking['booking_type'] == 'contract' ? 'Contract service' : 'Shuttle service'} started successfully!');
        _loadTransportationBookings(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar(
            'Failed to start ${booking['booking_type'] == 'contract' ? 'contract service' : 'shuttle service'}. Please try again.');
      }
    }
  }

  void _completeTransportationBooking(Map<String, dynamic> booking) async {
    final theme = Theme.of(context);
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(booking['booking_type'] == 'contract'
              ? 'Complete Contract Service'
              : 'Complete Shuttle Service'),
          content: Text(
              'Are you sure you want to mark "${booking['service']?['name'] ?? 'this booking'}" as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text('Complete',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                    'Completing ${booking['booking_type'] == 'contract' ? 'contract service' : 'shuttle service'}...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      // Check booking type and call appropriate completion function
      print(
          '🔍 DEBUG: [COMPLETE TRIP] Booking type check - booking_type: ${booking['booking_type']}');

      if (booking['booking_type'] == 'contract') {
        print('✅ DEBUG: [COMPLETE TRIP] Completing contract booking');
        await SupabaseConfig.completeContractBooking(booking['id']);
      } else {
        print('✅ DEBUG: [COMPLETE TRIP] Completing transportation booking');
        await SupabaseConfig.completeTransportationBooking(booking['id']);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Send notifications
        final serviceName =
            booking['service']?['name'] ?? 'Transportation Service';
        await NotificationService.notifyRunnerTransportationCompleted(
            serviceName);
        await NotificationService.notifyTransportationCompleted(serviceName);

        // Delete the chat conversation completely since the service is completed
        final conversation = booking['booking_type'] == 'contract'
            ? await ChatService.getConversationByBooking(
                booking['id'], 'contract')
            : await ChatService.getTransportationConversationByBooking(
                booking['id']);
        if (conversation != null) {
          await ChatService.deleteConversation(conversation['id']);
        }

        _showSuccessSnackBar(
            '${booking['booking_type'] == 'contract' ? 'Contract service' : 'Shuttle service'} completed successfully!');
        _loadTransportationBookings(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar(
            'Failed to complete ${booking['booking_type'] == 'contract' ? 'contract service' : 'shuttle service'}. Please try again.');
      }
    }
  }

  void _beginWork(Map<String, dynamic> errand) async {
    final theme = Theme.of(context);
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Begin Work'),
          content: Text(
              'Are you sure you want to begin work on "${errand['title']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: Text('Begin Work',
                  style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Starting work...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      await SupabaseConfig.beginWork(errand['id']);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar('Work begun successfully!');
        _loadRunnerErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to begin work. Please try again.');
      }
    }
  }

  void _showDeleteAllConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
            'Are you sure you want to delete all your data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('Deleting data...',
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              );

              await SupabaseConfig.deleteAllUserData(
                  SupabaseConfig.currentUser?.id ?? '');

              if (mounted) {
                Navigator.of(context).pop(); // Close loading dialog
                _showSuccessSnackBar('All data deleted successfully!');
                _loadRunnerErrands();
                _loadTransportationBookings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          ),
        ],
      ),
    );
  }

  void _showTransportationBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransportationBookingDetailsSheet(booking),
    );
  }

  Widget _buildTransportationBookingDetailsSheet(Map<String, dynamic> booking) {
    final theme = Theme.of(context);
    final service = booking['service'];
    final schedule = booking['schedule'];
    final user = booking['user'];
    final route = service?['route'];
    final vehicleType = service?['vehicle_type'];

    // Extract service info from special_requests if service is null
    final specialRequests = booking['special_requests'] ?? '';
    String serviceName = service?['name'] ?? 'Transportation Service';
    String vehicleInfo = vehicleType?['name'] ?? 'Vehicle';

    // Parse special_requests for service and vehicle info
    if (service == null && specialRequests.isNotEmpty) {
      final serviceMatch =
          RegExp(r'Service:\s*([^,]+)').firstMatch(specialRequests);
      final vehicleMatch =
          RegExp(r'Vehicle Type:\s*([^,]+)').firstMatch(specialRequests);

      if (serviceMatch != null) {
        serviceName = serviceMatch.group(1)?.trim() ?? serviceName;
      }
      if (vehicleMatch != null) {
        vehicleInfo = vehicleMatch.group(1)?.trim() ?? vehicleInfo;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: Responsive.isSmallMobile(context) ? 40 : 50,
                      height: Responsive.isSmallMobile(context) ? 3 : 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 20 : 24),

                  // Title and status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          serviceName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.isSmallMobile(context)
                                ? 18
                                : Responsive.isMobile(context)
                                    ? 20
                                    : 24,
                          ),
                        ),
                      ),
                      SizedBox(
                          width: Responsive.isSmallMobile(context) ? 8 : 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                Responsive.isSmallMobile(context) ? 10 : 14,
                            vertical:
                                Responsive.isSmallMobile(context) ? 5 : 7),
                        decoration: BoxDecoration(
                          color: _getBookingStatusColor(booking['status'])
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              Responsive.isSmallMobile(context) ? 16 : 20),
                          border: Border.all(
                              color: _getBookingStatusColor(booking['status'])
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getBookingStatusIcon(booking['status']),
                                color:
                                    _getBookingStatusColor(booking['status']),
                                size: Responsive.isSmallMobile(context)
                                    ? 12
                                    : 14),
                            SizedBox(
                                width:
                                    Responsive.isSmallMobile(context) ? 3 : 5),
                            Text(
                              _getBookingStatusText(booking['status']),
                              style: TextStyle(
                                color:
                                    _getBookingStatusColor(booking['status']),
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 9 : 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 20 : 24),

                  // Details sections with icons and better styling
                  _buildDetailRow(
                      'Price',
                      'N\$${booking['final_price'] ?? booking['estimated_price'] ?? '0'}',
                      Icons.attach_money,
                      theme),
                  _buildDetailRow(
                      'Service', serviceName, Icons.directions_bus, theme),
                  _buildDetailRow(
                      'Date & Time',
                      '${booking['booking_date'] ?? 'TBD'} ${booking['booking_time'] ?? ''}',
                      Icons.schedule,
                      theme),
                  _buildDetailRow(
                      'Route',
                      '${booking['pickup_location'] ?? 'Pickup'} → ${booking['dropoff_location'] ?? 'Dropoff'}',
                      Icons.route,
                      theme),
                  if (user != null)
                    _buildDetailRow('Customer', user['full_name'] ?? 'Customer',
                        Icons.person, theme),
                  if (user?['phone'] != null)
                    _buildDetailRow(
                        'Phone', user!['phone'], Icons.phone, theme),
                  _buildDetailRow(
                      'Vehicle', vehicleInfo, Icons.directions_car, theme),
                  if (booking['passenger_count'] != null)
                    _buildDetailRow(
                        'Passengers',
                        booking['passenger_count'].toString(),
                        Icons.people,
                        theme),

                  // Show runner information if booking is accepted or in progress
                  if (booking['status'] == 'confirmed' ||
                      booking['status'] == 'in_progress') ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.tertiary
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_pin,
                                  color: Theme.of(context).colorScheme.tertiary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Assigned Runner',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have been assigned to this booking',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (booking['updated_at'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Accepted on ${_formatDate(booking['updated_at'])}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking['special_requests']?.isNotEmpty == true
                          ? booking['special_requests']
                          : booking['notes'] ?? 'No description provided',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.6,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  if (booking['status'] == 'pending')
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.secondary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _acceptTransportationBooking(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.onSecondary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Accept',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (booking['status'] == 'accepted')
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.onPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startTransportationBooking(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow,
                                color: LottoRunnersColors.primaryBlue,
                                size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Start Trip',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: LottoRunnersColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (booking['status'] == 'in_progress')
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeTransportationBooking(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check,
                                color: Theme.of(context).colorScheme.onPrimary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Complete Trip',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getBookingStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getBookingStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'confirmed':
      case 'accepted':
        return 'ACCEPTED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Open chat for an errand
  void _openChat(Map<String, dynamic> errand) async {
    final customerName = errand['customer']?['full_name'] ?? 'Customer';
    final errandTitle = errand['title'] ?? 'Errand';

    try {
      // Get or create conversation
      final conversation =
          await ChatService.getConversationByErrand(errand['id']);

      if (conversation != null) {
        Navigator.push(
          context,
          PageTransitions.slideFromBottom(
            ChatPage(
              conversationId: conversation['id'],
              conversationType: 'errand',
              errandId: errand['id'],
              otherUserName: customerName,
              serviceTitle: errandTitle,
            ),
          ),
        );
      } else {
        // Create new conversation if it doesn't exist
        final conversationId = await ChatService.createConversation(
          errandId: errand['id'],
          customerId: errand['customer_id'],
          runnerId: errand['runner_id'],
        );

        if (conversationId != null) {
          Navigator.push(
            context,
            PageTransitions.slideFromBottom(
              ChatPage(
                conversationId: conversationId,
                conversationType: 'errand',
                errandId: errand['id'],
                otherUserName: customerName,
                serviceTitle: errandTitle,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Show cancel dialog for an errand
  void _showCancelDialog(Map<String, dynamic> errand) {
    final theme = Theme.of(context);
    final errandTitle = errand['title'] ?? 'Errand';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Errand'),
        content: Text(
          'Are you sure you want to cancel "$errandTitle"?\n\n'
          'This will return the errand to the available list and close the chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Errand'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelErrand(errand);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Cancel Errand',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }

  // Cancel an errand
  Future<void> _cancelErrand(Map<String, dynamic> errand) async {
    final theme = Theme.of(context);
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Cancelling errand...',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      );

      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Cancel the errand
      await SupabaseConfig.cancelErrand(
        errand['id'],
        cancelledBy: currentUserId,
        reason: 'Cancelled by runner',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar('Errand cancelled successfully');
        _loadRunnerErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to cancel errand. Please try again.');
      }
    }
  }

  void _cancelTransportationBooking(Map<String, dynamic> booking) async {
    final theme = Theme.of(context);
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Shuttle Service'),
          content: const Text(
              'Are you sure you want to cancel this shuttle service?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Check if this is a bus service (runners cannot accept bus services)
        final serviceName =
            booking['service']?['name'] ?? 'Transportation Service';
        final subcategoryName =
            booking['service']?['subcategory']?['name'] ?? '';
        final isBusService = subcategoryName.toLowerCase().contains('bus');

        if (isBusService) {
          _showErrorSnackBar(
              'Runners cannot cancel bus service bookings. Bus services are scheduled routes.');
          return;
        }

        final success = await SupabaseConfig.cancelTransportationBooking(
          booking['id'],
        );

        if (success) {
          // Send notifications
          await NotificationService.notifyRunnerTransportationCancelled(
              serviceName);
          await NotificationService.notifyTransportationCancelled(
              serviceName, 'Cancelled by runner');

          // Close the chat conversation if it exists
          final conversation =
              await ChatService.getTransportationConversationByBooking(
                  booking['id']);
          if (conversation != null) {
            await ChatService.closeTransportationConversation(
                conversation['id']);
          }

          _showSuccessSnackBar('Shuttle service cancelled successfully!');
          // Refresh data to update limits
          await _loadData();
        } else {
          _showErrorSnackBar(
              'Failed to cancel shuttle service. Please try again.');
        }
      }
    } catch (e) {
      print('Error cancelling shuttle service: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  // ignore: unused_element
  void _showNotificationsDialog() async {
    final theme = Theme.of(context);
    final userId = SupabaseConfig.currentUser?.id;

    if (userId == null) return;

    try {
      final notifications = await SupabaseConfig.getUserNotifications(userId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Notifications'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['is_read'] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.1),
                        child: ListTile(
                          leading: Icon(
                            notification['type'] == 'transportation_request'
                                ? Icons.local_taxi
                                : Icons.notifications,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                _formatNotificationTime(
                                    notification['created_at']),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'mark_read' && !isRead) {
                                await SupabaseConfig.markNotificationAsRead(
                                    notification['id']);
                                Navigator.pop(context);
                                _showNotificationsDialog(); // Refresh dialog
                              } else if (value == 'delete') {
                                await SupabaseConfig.deleteNotification(
                                    notification['id']);
                                Navigator.pop(context);
                                _showNotificationsDialog(); // Refresh dialog
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isRead)
                                const PopupMenuItem(
                                  value: 'mark_read',
                                  child: Row(
                                    children: [
                                      Icon(Icons.mark_email_read),
                                      SizedBox(width: 8),
                                      Text('Mark as Read'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await SupabaseConfig.markAllNotificationsAsRead(userId);
                  Navigator.pop(context);
                  _showNotificationsDialog(); // Refresh dialog
                },
                child: const Text('Mark All Read'),
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error loading notifications: $e');
      _showErrorSnackBar('Failed to load notifications');
    }
  }

  String _formatNotificationTime(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildDocumentsSection(Map<String, dynamic> errand, ThemeData theme) {
    final imageUrls = errand['image_urls'] as List<dynamic>? ?? [];
    final pdfUrls = errand['pdf_urls'] as List<dynamic>? ?? [];
    final totalDocuments = imageUrls.length + pdfUrls.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merge message if multiple documents
          if (totalDocuments > 1) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Multiple documents attached. Please merge them before processing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // PDF Documents
          if (pdfUrls.isNotEmpty) ...[
            Text(
              'PDF Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...pdfUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final pdfUrl = entry.value.toString();
              return _buildDocumentItem(
                'PDF Document ${index + 1}',
                pdfUrl,
                Icons.picture_as_pdf,
                Colors.red,
                theme,
              );
            }),
            const SizedBox(height: 16),
          ],

          // Image Documents
          if (imageUrls.isNotEmpty) ...[
            Text(
              'Image Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...imageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value.toString();
              return _buildDocumentItem(
                'Image Document ${index + 1}',
                imageUrl,
                Icons.image,
                Colors.green,
                theme,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      String title, String url, IconData icon, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'View or download document',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // View button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _viewDocument(url, title),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: color,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Download button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _downloadDocument(url, title),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.download,
                    color: color,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Downloading $fileName...'),
            ],
          ),
        ),
      );

      // Use url_launcher to open the document in browser/download
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileName downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not download $fileName'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(String url, String fileName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Opening $fileName...'),
            ],
          ),
        ),
      );

      // Use url_launcher to open the document in browser for viewing
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fileName opened for viewing'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $fileName'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'document':
        return Icons.description;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.task_alt;
    }
  }

  String _getTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }

  String _getUserFriendlyErrorMessage(String errorMessage) {
    // Handle job limit errors
    if (errorMessage.contains('limit') || errorMessage.contains('maximum')) {
      if (errorMessage.contains('2 active jobs')) {
        return '🚫 You have reached your maximum of 2 active jobs.\n\nPlease complete at least one job before accepting new ones.\n\nGo to "My Orders" to see your current jobs.';
      } else if (errorMessage.contains('active jobs')) {
        return '🚫 You have reached your job limit.\n\nPlease complete some of your current jobs before accepting new ones.\n\nGo to "My Orders" to manage your jobs.';
      }
    }

    // Handle stale data errors
    if (errorMessage.contains('stale') ||
        errorMessage.contains('already accepted')) {
      return '⚠️ This job is no longer available.\n\nIt may have been accepted by another runner or cancelled.\n\nPlease refresh and try again.';
    }

    // Handle permission errors
    if (errorMessage.contains('RLS') || errorMessage.contains('permission')) {
      return '🔒 Permission denied.\n\nPlease make sure you are signed in correctly.\n\nIf the problem persists, contact support.';
    }

    // Handle network errors
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return '🌐 Network error.\n\nPlease check your internet connection and try again.';
    }

    // Default error message
    return '❌ Something went wrong.\n\nPlease try again or contact support if the problem persists.';
  }
}

class AppBarPatternPainter extends CustomPainter {
  final ThemeData theme;

  AppBarPatternPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw subtle pattern
    for (int i = 0; i < 15; i++) {
      final x = (i * 80.0) % size.width;
      final y = (i * 40.0) % size.height;
      final radius = 15.0 + (i % 2) * 10.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
