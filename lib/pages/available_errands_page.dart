import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:lotto_runners/widgets/errand_card.dart';
import 'package:lotto_runners/services/global_ride_popup_service.dart';
import 'package:lotto_runners/widgets/new_ride_request_popup.dart';
import 'package:lotto_runners/services/global_errand_popup_service.dart';
import 'package:lotto_runners/services/immediate_errand_service.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lotto_runners/pages/profile_page.dart';
import 'package:lotto_runners/utils/page_transitions.dart';

class AvailableErrandsPage extends StatefulWidget {
  const AvailableErrandsPage({super.key});

  @override
  State<AvailableErrandsPage> createState() => _AvailableErrandsPageState();
}

class _AvailableErrandsPageState extends State<AvailableErrandsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _transportationBookings = [];
  bool _isLoading = true;
  bool _isLoadingBookings = true;
  bool _isRefreshingErrands = false;
  bool _isRefreshingBookings = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _selectedTransportType = 'all';
  Map<String, dynamic>? _userProfile;
  late TabController _tabController;
  final GlobalRidePopupService _rideService = GlobalRidePopupService.instance;
  Timer? _autoRefreshTimer;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All Errands', 'icon': 'grid_view'},
    {'value': 'grocery', 'label': 'Grocery', 'icon': 'shopping_cart'},
    {'value': 'delivery', 'label': 'Delivery', 'icon': 'local_shipping'},
    {'value': 'document', 'label': 'Documents', 'icon': 'description'},
    {'value': 'shopping', 'label': 'Shopping', 'icon': 'shopping_bag'},
    {
      'value': 'license_discs',
      'label': 'License Discs',
      'icon': 'directions_car'
    },
    {'value': 'other', 'label': 'Other', 'icon': 'more_horiz'},
  ];

  final List<Map<String, String>> _transportTypeFilters = [
    {'value': 'all', 'label': 'All', 'icon': 'all_inclusive'},
    {'value': 'shuttle', 'label': 'Shuttle', 'icon': 'directions_bus'},
    {'value': 'contract', 'label': 'Contract', 'icon': 'assignment'},
  ];

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _refreshCurrentTab();
      }
    });
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      _refreshErrands();
    } else {
      _refreshTransportationBookings();
    }
  }

  Future<void> _refreshErrands() async {
    if (_isRefreshingErrands) return;

    setState(() => _isRefreshingErrands = true);
    try {
      await _loadAvailableErrands();
    } finally {
      if (mounted) {
        setState(() => _isRefreshingErrands = false);
      }
    }
  }

  Future<void> _refreshTransportationBookings() async {
    if (_isRefreshingBookings) return;

    setState(() => _isRefreshingBookings = true);
    try {
      await _loadAvailableTransportationBookings();
    } finally {
      if (mounted) {
        setState(() => _isRefreshingBookings = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadAvailableErrands();
    _loadAvailableTransportationBookings();
    // Start in-page ride request listener for this page only and listen for changes
    _rideService.initialize(context);
    _rideService.addListener(_onRideServiceChanged);
    // Start auto-refresh timer (refresh every 30 seconds)
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rideService.updateContext(context);
  }

  @override
  void dispose() {
    _rideService.removeListener(_onRideServiceChanged);
    _rideService.disposeService();
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _onRideServiceChanged() {
    if (mounted) setState(() {});
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

  Future<void> _loadAvailableErrands() async {
    try {
      setState(() => _isLoading = true);

      // Get available errands based on filters (exclude immediate errands - they are handled by popup service)
      final errands = await SupabaseConfig.getAvailableErrands(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        vehicleType: null,
        runnerVehicleType: _userProfile?['vehicle_type'],
      );
      print(
          '📊 Loaded ${errands.length} regular errands from database (excluding immediate errands)');

      // Clean up expired immediate errands (but don't display them in the list)
      await ImmediateErrandService.cleanupExpiredErrands();

      // Use only regular errands (immediate errands are handled by GlobalErrandPopupService)
      final allErrands = errands;
      print(
          '🔄 Total errands available: ${allErrands.length} (regular errands only)');

      // Filter errands based on runner's vehicle type
      final filteredErrands = allErrands.where((errand) {
        // Special handling for license_discs category - visible to all runners
        if (errand['category'] == 'license_discs') {
          // License discs orders can be done by any runner
          return true;
        }

        // Default filtering based on runner's vehicle type
        final errandVehicleType = errand['vehicle_type'];

        // If errand has no vehicle type requirement (null or empty), show to all runners
        if (errandVehicleType == null || errandVehicleType.toString().isEmpty) {
          return true; // Errands without vehicle type can be done by anyone
        }

        // If errand requires a specific vehicle type, only show to runners with matching vehicle type
        final runnerVehicleType = _userProfile?['vehicle_type'];
        if (runnerVehicleType == null || runnerVehicleType.toString().isEmpty) {
          return false; // Runner doesn't have a vehicle type, can't do vehicle errands
        }

        return errandVehicleType.toString().toLowerCase() ==
            runnerVehicleType.toString().toLowerCase();
      }).toList();

      print(
          '🔍 After filtering: ${filteredErrands.length} errands (${errands.where((e) => !e['id'].toString().startsWith('pending_')).length} from DB + ${filteredErrands.where((e) => e['id'].toString().startsWith('pending_')).length} pending)');

      if (mounted) {
        setState(() {
          _errands = filteredErrands;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading available errands: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(
            'Failed to load available errands. Please try again.');
      }
    }
  }

  Future<void> _loadAvailableTransportationBookings() async {
    try {
      setState(() => _isLoadingBookings = true);

      print('🚌 Loading available transportation bookings...');

      // Get runner's vehicle type to filter available bookings
      final userId = SupabaseConfig.currentUser?.id;
      String? runnerVehicleType;

      if (userId != null) {
        runnerVehicleType = await SupabaseConfig.getRunnerVehicleType(userId);
        print('🚗 Runner vehicle type: $runnerVehicleType');
      }

      // Get all available bookings (transportation + contracts) filtered by runner's vehicle type
      final availableBookings = await SupabaseConfig.getAvailableAllBookings(
          vehicleTypeId: runnerVehicleType);
      print(
          '📋 Available transportation bookings: ${availableBookings.length}');

      // Filter bookings to match runner's vehicle type
      final filteredBookings = availableBookings.where((booking) {
        // For contract bookings, apply vehicle type filtering
        if (booking['booking_type'] == 'contract') {
          final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';
          print(
              '🔍 Checking contract booking: ${booking['pickup_location']} → ${booking['dropoff_location']}');
          print('   Contract vehicle type: "$bookingVehicleType"');
          print('   Runner vehicle type: "$runnerVehicleType"');

          // If contract booking has no vehicle type requirement (null or empty), show to all runners
          if (bookingVehicleType.isEmpty) {
            print('✅ Contract booking with no vehicle requirement included');
            return true; // Contract bookings without vehicle type can be done by anyone
          }

          // If contract booking requires a specific vehicle type, only show to runners with matching vehicle type
          if (runnerVehicleType == null || runnerVehicleType.isEmpty) {
            print('❌ Runner has no vehicle type, excluding contract booking');
            return false; // Runner doesn't have a vehicle type, can't do vehicle contract bookings
          }

          final matches = bookingVehicleType.toLowerCase() ==
              runnerVehicleType.toLowerCase();
          print('   Vehicle type match: $matches');
          if (matches) {
            print('✅ Matching contract booking included');
          } else {
            print('❌ Non-matching contract booking excluded');
          }

          return matches;
        }

        // For transportation bookings, apply vehicle type filtering
        final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';
        print(
            '🔍 Checking transportation booking: ${booking['pickup_location']} → ${booking['dropoff_location']}');
        print('   Booking vehicle type: "$bookingVehicleType"');
        print('   Runner vehicle type: "$runnerVehicleType"');

        // If transportation booking has no vehicle type requirement (null or empty), show to all runners
        if (bookingVehicleType.isEmpty) {
          print(
              '✅ Transportation booking with no vehicle requirement included');
          return true; // Transportation bookings without vehicle type can be done by anyone
        }

        // If transportation booking requires a specific vehicle type, only show to runners with matching vehicle type
        if (runnerVehicleType == null || runnerVehicleType.isEmpty) {
          print(
              '❌ Runner has no vehicle type, excluding transportation booking');
          return false; // Runner doesn't have a vehicle type, can't do vehicle transportation bookings
        }

        final matches =
            bookingVehicleType.toLowerCase() == runnerVehicleType.toLowerCase();
        print('   Vehicle type match: $matches');
        if (matches) {
          print('✅ Matching transportation booking included');
        } else {
          print('❌ Non-matching transportation booking excluded');
        }

        return matches;
      }).toList();

      print(
          '✅ Available bookings for vehicle type $runnerVehicleType: ${filteredBookings.length}');

      if (mounted) {
        setState(() {
          _transportationBookings = filteredBookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      print('❌ Error loading available bookings: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
        _showErrorSnackBar(
            'Failed to load available bookings. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: LottoRunnersColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredErrands {
    return _errands.where((errand) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = errand['title']?.toString().toLowerCase() ?? '';
        final description =
            errand['description']?.toString().toLowerCase() ?? '';
        final location =
            errand['location_address']?.toString().toLowerCase() ?? '';

        if (!title.contains(query) &&
            !description.contains(query) &&
            !location.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredTransportationBookings {
    return _transportationBookings.where((booking) {
      // Filter by transport type
      if (_selectedTransportType == 'all') {
        return true;
      } else if (_selectedTransportType == 'contract') {
        return booking['booking_type'] == 'contract';
      } else if (_selectedTransportType == 'shuttle') {
        return booking['booking_type'] != 'contract';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rideService = _rideService;

    return GlobalErrandPopupWrapper(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: LottoRunnersColors.gray50,
            body: SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildAppBar(theme),
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
          if (rideService.currentRequest != null)
            NewRideRequestPopup(
              booking: rideService.currentRequest!,
              onAccept: () => rideService.acceptCurrent(context),
              onDecline: rideService.declineCurrent,
              onDismiss: rideService.dismissCurrent,
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);
    
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        'Available Errands',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 22),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _isRefreshingErrands || _isRefreshingBookings
              ? null
              : _refreshCurrentTab,
          icon: _isRefreshingErrands || _isRefreshingBookings
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          tooltip: 'Refresh',
        ),
      ],
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 16 : 24,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 13 : 14,
            ),
            tabs: const [
              Tab(text: 'Errands'),
              Tab(text: 'Transport'),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused _buildStatItem after header cleanup

  Widget _buildSearchAndFilters(ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 12 : 16),
      padding: EdgeInsets.all(isSmallMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isSmallMobile ? 15 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category filters
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 45),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];

                return Container(
                  margin: EdgeInsets.only(right: Responsive.isSmallMobile(context) ? 8 : 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconData(category['icon']!),
                          size: Responsive.isSmallMobile(context) ? 14 : 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : LottoRunnersColors.primaryBlue,
                        ),
                        SizedBox(width: Responsive.isSmallMobile(context) ? 4 : 6),
                        Text(
                          category['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      final value = category['value']!;
                      setState(() => _selectedCategory = value);
                      _loadAvailableErrands();
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
      case 'grid_view':
        return Icons.grid_view;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'description':
        return Icons.description;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.more_horiz;
    }
  }

  IconData _getVehicleIcon(String vehicleName) {
    switch (vehicleName.toLowerCase()) {
      case 'bicycle':
        return Icons.pedal_bike;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'car':
        return Icons.directions_car;
      case 'pickup truck':
        return Icons.local_shipping;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      case 'suv':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
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
              color: LottoRunnersColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation(LottoRunnersColors.primaryBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading errands...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: LottoRunnersColors.gray600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best errands for you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: LottoRunnersColors.gray400,
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

    final isSmallMobile = Responsive.isSmallMobile(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(isSmallMobile ? 12 : 16, 0, isSmallMobile ? 12 : 16, isSmallMobile ? 12 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final errand = filteredErrands[index];
            return Container(
              margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
              child: ErrandCard(
                errand: {
                  ...errand,
                  'current_user_type': _userProfile?['user_type'],
                },
                onTap: () => _showErrandDetails(errand),
                showAcceptButton: true,
                onAccept: () => _acceptErrand(errand),
              ),
            );
          },
          childCount: filteredErrands.length,
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
                _searchQuery.isNotEmpty || _selectedCategory != 'all'
                    ? Icons.search_off
                    : Icons.assignment_outlined,
                size: 60,
                color: LottoRunnersColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'all'
                  ? 'No matching errands'
                  : 'No errands available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: LottoRunnersColors.gray900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'all'
                  ? 'Try adjusting your search or filters to find more errands'
                  : 'Check back later for new errands to run',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: LottoRunnersColors.gray600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'all';
                });
                _loadAvailableErrands();
              },
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
              label: const Text(
                'Refresh Errands',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
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
              child: const Icon(
                Icons.verified_user_outlined,
                size: 60,
                color: LottoRunnersColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: LottoRunnersColors.gray900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account is currently under review. Once verified, you\'ll be able to view and accept available errands.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: LottoRunnersColors.gray600,
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
                  const Icon(
                    Icons.info_outline,
                    color: LottoRunnersColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll notify you once your verification is complete. This usually takes 24-48 hours.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LottoRunnersColors.gray700,
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
                  PageTransitions.slideFromBottom(const ProfilePage()),
                );
              },
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text(
                'Check Profile Status',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
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

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding:
                EdgeInsets.all(Responsive.isSmallMobile(context) ? 16 : 24),
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
                        color: LottoRunnersColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 16 : 24),

                  // Title and category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          errand['title'] ?? '',
                          style: TextStyle(
                            fontSize:
                                Responsive.isSmallMobile(context) ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: LottoRunnersColors.gray900,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                Responsive.isSmallMobile(context) ? 12 : 16,
                            vertical:
                                Responsive.isSmallMobile(context) ? 6 : 8),
                        decoration: BoxDecoration(
                          color: LottoRunnersColors.primaryYellow
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (errand['category'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 16 : 20),

                  // Price and time
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                            Responsive.isSmallMobile(context) ? 10 : 12),
                        decoration: BoxDecoration(
                          color: LottoRunnersColors.primaryBlue
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: LottoRunnersColors.primaryYellow
                              .withValues(alpha: 0.8),
                          size: Responsive.isSmallMobile(context) ? 20 : 24,
                        ),
                      ),
                      SizedBox(
                          width: Responsive.isSmallMobile(context) ? 10 : 12),
                      Text(
                        'N\$${errand['price_amount']?.toString() ?? '0'}',
                        style: TextStyle(
                          fontSize: Responsive.isSmallMobile(context) ? 18 : 22,
                          color: LottoRunnersColors.gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.all(
                            Responsive.isSmallMobile(context) ? 10 : 12),
                        decoration: BoxDecoration(
                          color: LottoRunnersColors.primaryBlue
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.timer,
                          color: LottoRunnersColors.primaryBlue,
                          size: Responsive.isSmallMobile(context) ? 20 : 24,
                        ),
                      ),
                      SizedBox(
                          width: Responsive.isSmallMobile(context) ? 10 : 12),
                      Text(
                        '${errand['time_limit_hours']}h limit',
                        style: TextStyle(
                          fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                          color: LottoRunnersColors.gray700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Vehicle requirement indicator
                  if (errand['needs_vehicle'] == true) ...[
                    SizedBox(
                        height: Responsive.isSmallMobile(context) ? 12 : 16),
                    Container(
                      padding: EdgeInsets.all(
                          Responsive.isSmallMobile(context) ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car,
                              color: Colors.orange,
                              size:
                                  Responsive.isSmallMobile(context) ? 18 : 20),
                          SizedBox(
                              width: Responsive.isSmallMobile(context) ? 6 : 8),
                          Text(
                            'Vehicle Required',
                            style: TextStyle(
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 12 : 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: Responsive.isSmallMobile(context) ? 20 : 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: Responsive.isSmallMobile(context) ? 16 : 18,
                      color: LottoRunnersColors.gray900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.isSmallMobile(context) ? 10 : 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                        Responsive.isSmallMobile(context) ? 12 : 16),
                    decoration: BoxDecoration(
                      color: LottoRunnersColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errand['description'] ?? 'No description provided',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 13 : 15,
                        color: LottoRunnersColors.gray700,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Location
                  if (errand['location_address'] != null) ...[
                    SizedBox(
                        height: Responsive.isSmallMobile(context) ? 20 : 24),
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 16 : 18,
                        color: LottoRunnersColors.gray900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                        height: Responsive.isSmallMobile(context) ? 10 : 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                          Responsive.isSmallMobile(context) ? 12 : 16),
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: LottoRunnersColors.primaryYellow,
                            size: Responsive.isSmallMobile(context) ? 20 : 24,
                          ),
                          SizedBox(
                              width:
                                  Responsive.isSmallMobile(context) ? 10 : 12),
                          Expanded(
                            child: Text(
                              _getDisplayLocation(errand),
                              style: TextStyle(
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 13 : 15,
                                color: LottoRunnersColors.gray700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Customer info - Only show if not a runner or if runner has accepted
                  if (errand['customer'] != null &&
                      (_userProfile?['user_type'] != 'runner' ||
                          errand['runner_id'] != null)) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Customer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: LottoRunnersColors.gray900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: LottoRunnersColors.primaryBlue
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: LottoRunnersColors.primaryYellow,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  errand['customer']['full_name'] ?? 'Customer',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: LottoRunnersColors.gray900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (errand['customer']['phone'] != null)
                                  Text(
                                    errand['customer']['phone'],
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: LottoRunnersColors.gray600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Documents section for license discs and document services - only show to accepted runners
                  if ((errand['category'] == 'license_discs' ||
                          errand['category'] == 'document_services') &&
                      errand['runner_id'] != null &&
                      ((errand['image_urls'] != null &&
                              errand['image_urls'].isNotEmpty) ||
                          (errand['pdf_urls'] != null &&
                              errand['pdf_urls'].isNotEmpty))) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Attached Documents',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: LottoRunnersColors.gray900,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.isSmallMobile(context) ? 16 : 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentsSection(errand, theme),
                  ],

                  // Show restricted info message for runners
                  if (_userProfile?['user_type'] == 'runner' &&
                      errand['runner_id'] == null) ...[
                    SizedBox(
                        height: Responsive.isSmallMobile(context) ? 20 : 24),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                          Responsive.isSmallMobile(context) ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: Responsive.isSmallMobile(context) ? 20 : 24,
                          ),
                          SizedBox(
                              width:
                                  Responsive.isSmallMobile(context) ? 10 : 12),
                          Expanded(
                            child: Text(
                              'Customer information will be available after accepting this errand.',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: Responsive.isSmallMobile(context) ? 24 : 32),

                  // Accept button
                  Container(
                    width: double.infinity,
                    height: Responsive.isSmallMobile(context) ? 48 : 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          LottoRunnersColors.primaryBlue,
                          LottoRunnersColors.primaryBlueDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LottoRunnersColors.primaryBlue
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _acceptErrand(errand);
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
                              color: Colors.white,
                              size:
                                  Responsive.isSmallMobile(context) ? 20 : 24),
                          SizedBox(
                              width:
                                  Responsive.isSmallMobile(context) ? 10 : 12),
                          Text(
                            'Accept Errand',
                            style: TextStyle(
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 14 : 16,
                              color: Colors.white,
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

  Future<void> _acceptErrand(Map<String, dynamic> errand) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return;

      // Check runner limits first
      final runnerLimits = await SupabaseConfig.checkRunnerLimits(userId);
      if (!(runnerLimits['can_accept_errands'] ?? false)) {
        _showErrorSnackBar(
          '🚫 You have reached your maximum of 2 active jobs.\n\nPlease complete at least one job before accepting new ones.\n\nGo to "My Orders" to see your current jobs.',
        );
        return;
      }

      // Check if errand requires vehicle and runner doesn't have one
      if (errand['needs_vehicle'] == true &&
          _userProfile?['has_vehicle'] != true) {
        _showErrorSnackBar(
            'This errand requires a vehicle. Please update your profile if you have one.');
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(LottoRunnersColors.primaryBlue),
                ),
                SizedBox(height: 16),
                Text('Accepting errand...'),
              ],
            ),
          ),
        ),
      );

      // Accept the errand (works for both pending and regular errands)
      print(
          '🎯 ACCEPTING ERRAND: ${errand['id']} (Status: ${errand['status']})');

      try {
        await SupabaseConfig.acceptErrand(errand['id'], userId);
        print('✅ ERRAND: Status updated to accepted');
      } catch (dbError) {
        print('❌ DATABASE ERROR: $dbError');
        throw Exception('Database update failed: $dbError');
      }

      // Remove from pending tracking if it was a pending errand
      if (errand['status'] == 'pending') {
        await ImmediateErrandService.removePendingErrand(errand['id']);
        print('🗑️ PENDING ERRAND: Removed from pending tracking');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessSnackBar(
            'Errand accepted successfully! Check your dashboard for accepted contracts.');
        _loadAvailableErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        print('❌ Contract acceptance error: $e');

        // Show more detailed error message
        String errorMessage = 'Failed to accept errand. Please try again.';
        if (e.toString().contains('Database update failed')) {
          errorMessage =
              'Database error occurred. Please check your connection and try again.';
        } else if (e.toString().contains('Cannot accept errand with status')) {
          errorMessage = 'This errand cannot be accepted in its current state.';
        } else if (e.toString().contains('RLS')) {
          errorMessage = 'Permission denied. Please contact support.';
        }

        _showErrorSnackBar(_getUserFriendlyErrorMessage(errorMessage));
      }
    }
  }

  Widget _buildTransportationBookingsList(ThemeData theme) {
    final availableBookings = _filteredTransportationBookings;

    // Check if user is verified - show verification message if not
    if (_userProfile?['is_verified'] != true) {
      return SliverFillRemaining(
        child: _buildVerificationRequiredState(theme),
      );
    }

    if (availableBookings.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyTransportationState(theme));
    }

    final isSmallMobile = Responsive.isSmallMobile(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(isSmallMobile ? 12 : 16, 0, isSmallMobile ? 12 : 16, isSmallMobile ? 12 : 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final booking = availableBookings[index];
            return Container(
              margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
              child: _buildTransportationBookingCard(booking, theme),
            );
          },
          childCount: availableBookings.length,
        ),
      ),
    );
  }

  Widget _buildTransportationBookingCard(
      Map<String, dynamic> booking, ThemeData theme) {
    final service = booking['service'];
    final user = booking['user'];
    final provider = service?['provider'];
    final vehicleType = service?['vehicle_type'];
    final createdAt = booking['created_at'];

    // Extract pickup and dropoff locations from booking
    String pickupLocation = booking['pickup_location'] ?? 'Pickup Location';
    String dropoffLocation = booking['dropoff_location'] ?? 'Dropoff Location';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: LottoRunnersColors.gray200),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with service name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['title'] ??
                            service?['name'] ??
                            'Transportation Service',
                        style: TextStyle(
                          fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: LottoRunnersColors.gray900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (provider?['name'] != null)
                        Text(
                          'by ${provider['name']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.gray600,
                            fontStyle: FontStyle.italic,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 12 : 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isSmallMobile(context) ? 10 : 12,
                      vertical: Responsive.isSmallMobile(context) ? 4 : 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.isSmallMobile(context) ? 16 : 20),
                  ),
                  child: Text(
                    'AVAILABLE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isSmallMobile(context) ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer information - Only show if not a runner or if runner has accepted
            if (_userProfile?['user_type'] != 'runner' ||
                booking['driver_id'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LottoRunnersColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person,
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
                                color: LottoRunnersColors.gray600,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                          if (user?['email'] != null)
                            Text(
                              user!['email'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: LottoRunnersColors.gray600,
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
            ],
            const SizedBox(height: 12),

            // Route information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route,
                      color: LottoRunnersColors.primaryYellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pickupLocation → $dropoffLocation',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vehicle and schedule info
            Row(
              children: [
                if (vehicleType != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LottoRunnersColors.primaryYellow
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car,
                            color: LottoRunnersColors.primaryYellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicleType['name'] ?? 'Vehicle'} (${vehicleType['capacity'] ?? 0} seats)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LottoRunnersColors.primaryYellow,
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),

            // Booking details
            if (booking['pickup_location'] != null ||
                booking['dropoff_location'] != null) ...[
              SizedBox(height: Responsive.isSmallMobile(context) ? 10 : 12),
              Container(
                padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 10 : 12),
                decoration: BoxDecoration(
                  color: LottoRunnersColors.gray50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (booking['pickup_location'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: LottoRunnersColors.primaryYellow,
                              size: Responsive.isSmallMobile(context) ? 14 : 16),
                          SizedBox(width: Responsive.isSmallMobile(context) ? 3 : 4),
                          Expanded(
                            child: Text(
                              'Pickup: ${booking['pickup_location']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (booking['dropoff_location'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.flag,
                              color: LottoRunnersColors.primaryYellow,
                              size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Dropoff: ${booking['dropoff_location']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (booking['passenger_count'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people,
                              color: LottoRunnersColors.gray600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${booking['passenger_count']} passenger(s)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: LottoRunnersColors.gray600,
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Booking date/time
            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: LottoRunnersColors.gray600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Booked: ${DateTime.parse(createdAt).toString().substring(0, 16)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: LottoRunnersColors.gray600,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
                  const Spacer(),
                  if (booking['estimated_price'] != null) ...[
                    const Icon(Icons.attach_money,
                        color: LottoRunnersColors.primaryYellow, size: 16),
                    Text(
                      'N\$${booking['estimated_price']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LottoRunnersColors.primaryYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Footer with customer info (similar to ErrandCard)
            Row(
              children: [
                // Customer info
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (_userProfile?['user_type'] != 'runner' ||
                                  booking['driver_id'] != null)
                              ? 'By: ${user?['full_name'] ?? 'Customer'}'
                              : 'Customer info available after acceptance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 12 : 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time ago
                if (createdAt != null)
                  Text(
                    _getTimeAgo(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Check booking type and call appropriate acceptance function
                  print(
                      '🔍 DEBUG: [AVAILABLE TRANSPORT] Booking type check - booking_type: ${booking['booking_type']}');

                  if (booking['booking_type'] == 'contract') {
                    print(
                        '✅ DEBUG: [AVAILABLE TRANSPORT] Routing to contract acceptance');
                    _acceptContractBooking(booking);
                  } else {
                    print(
                        '✅ DEBUG: [AVAILABLE TRANSPORT] Routing to transportation acceptance');
                    _acceptTransportationBooking(booking);
                  }
                },
                icon: const Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
                label: const Text(
                  'Accept',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LottoRunnersColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      return 'Unknown';
    }
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
                color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 60,
                color: LottoRunnersColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Available Services',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: LottoRunnersColors.gray900,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You may need to:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LottoRunnersColors.gray600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadAvailableTransportationBookings,
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptContractBooking(Map<String, dynamic> booking) async {
    try {
      print(
          '🚀 DEBUG: [AVAILABLE TRANSPORT] Starting contract booking acceptance...');
      print(
          '📋 DEBUG: [AVAILABLE TRANSPORT] Booking data: ${booking.toString()}');
      print('🆔 DEBUG: [AVAILABLE TRANSPORT] Booking ID: ${booking['id']}');

      final userId = SupabaseConfig.currentUser?.id;
      print('👤 DEBUG: [AVAILABLE TRANSPORT] Current user ID: $userId');

      if (userId == null) {
        print('❌ DEBUG: [AVAILABLE TRANSPORT] No user ID found');
        _showErrorSnackBar('Please sign in to accept bookings.');
        return;
      }

      // Accept contract booking directly without confirmation
      final customerName = booking['user']?['full_name'] ?? 'Unknown Customer';
      final description = booking['description'] ?? 'Contract booking';

      {
        print(
            '✅ DEBUG: [AVAILABLE TRANSPORT] User confirmed contract acceptance');

        // Accept the contract booking
        try {
          await SupabaseConfig.acceptContractBooking(booking['id'], userId);

          print(
              '✅ DEBUG: [AVAILABLE TRANSPORT] Contract booking accepted successfully');
          _showSuccessSnackBar('Contract booking accepted successfully!');

          // Refresh the list
          _loadAvailableTransportationBookings();
        } catch (e) {
          print('❌ DEBUG: [AVAILABLE TRANSPORT] Contract acceptance error: $e');
          _showErrorSnackBar(_getUserFriendlyErrorMessage(
              'Failed to accept contract booking: $e'));
        }
      }
    } catch (e, stackTrace) {
      print(
          '💥 DEBUG: [AVAILABLE TRANSPORT] Exception caught in _acceptContractBooking');
      print('💥 DEBUG: [AVAILABLE TRANSPORT] Error: $e');
      print('💥 DEBUG: [AVAILABLE TRANSPORT] Stack trace: $stackTrace');

      _showErrorSnackBar(
          _getUserFriendlyErrorMessage('Error accepting contract booking: $e'));
    }
  }

  Future<void> _acceptTransportationBooking(
      Map<String, dynamic> booking) async {
    try {
      print('🚀 DEBUG: Starting transportation booking acceptance...');
      print('📋 DEBUG: Booking data: ${booking.toString()}');

      // Accept shuttle service directly without confirmation
      final serviceName =
          booking['service']?['name'] ?? 'Transportation Service';

      print('✅ DEBUG: User confirmed acceptance');

      final userId = SupabaseConfig.currentUser?.id;
      print('👤 DEBUG: Current user ID: $userId');

      if (userId == null) {
        print('❌ DEBUG: No user ID found');
        _showErrorSnackBar('Please sign in to accept bookings.');
        return;
      }

      // Check if this is a bus service (runners cannot accept bus services)
      final subcategoryName = booking['service']?['subcategory']?['name'] ?? '';
      final isBusService = subcategoryName.toLowerCase().contains('bus');

      print('🚌 DEBUG: Service name: $serviceName');
      print('🚌 DEBUG: Subcategory name: $subcategoryName');
      print('🚌 DEBUG: Is bus service: $isBusService');

      if (isBusService) {
        print('❌ DEBUG: Blocked - this is a bus service');
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

      print('📝 DEBUG: Update data: $updateData');
      print('🆔 DEBUG: Booking ID: ${booking['id']}');

      // Try to update the booking
      print('🔄 DEBUG: Calling updateTransportationBooking...');
      final success = await SupabaseConfig.updateTransportationBooking(
        booking['id'],
        updateData,
      );

      print('📊 DEBUG: Update result: $success');

      if (success) {
        print('✅ DEBUG: Booking update successful');

        // Create chat conversation between runner and customer
        print('💬 DEBUG: Creating chat conversation...');
        final conversationId =
            await ChatService.createTransportationConversation(
          bookingId: booking['id'],
          customerId: booking['user_id'],
          runnerId: userId,
          serviceName: serviceName,
        );

        print('💬 DEBUG: Conversation ID: $conversationId');

        if (conversationId != null) {
          // Notify runner that they successfully accepted the booking
          print('🔔 DEBUG: Sending notification...');
          await NotificationService.notifyRunnerTransportationAccepted(
              serviceName);

          _showSuccessSnackBar(
              'Shuttle service accepted successfully! Chat conversation created.');
        } else {
          _showSuccessSnackBar('Shuttle service accepted successfully!');
        }

        print('🔄 DEBUG: Refreshing booking list...');
        _loadAvailableTransportationBookings(); // Refresh the list
      } else {
        print('❌ DEBUG: Booking update failed');
        _showErrorSnackBar(_getUserFriendlyErrorMessage(
            'Failed to accept booking. Please try again.'));
      }
    } catch (e, stackTrace) {
      print('💥 DEBUG: Exception caught in _acceptTransportationBooking');
      print('💥 DEBUG: Error: $e');
      print('💥 DEBUG: Stack trace: $stackTrace');

      // Show detailed error to user for debugging
      _showErrorSnackBar(
          _getUserFriendlyErrorMessage('Error accepting booking: $e'));
    }
  }

  Widget _buildErrandsTab(ThemeData theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildSearchAndFilters(theme)),
        _isLoading
            ? SliverFillRemaining(child: _buildLoadingState(theme))
            : _buildErrandsList(theme),
      ],
    );
  }

  Widget _buildTransportationFilters(ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 12 : 16),
      padding: EdgeInsets.all(isSmallMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: isSmallMobile ? 15 : 20,
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
              itemCount: _transportTypeFilters.length,
              itemBuilder: (context, index) {
                final transportType = _transportTypeFilters[index];
                final isSelected =
                    _selectedTransportType == transportType['value'];

                return Container(
                  margin: EdgeInsets.only(right: Responsive.isSmallMobile(context) ? 8 : 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconData(transportType['icon']!),
                          size: Responsive.isSmallMobile(context) ? 14 : 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : LottoRunnersColors.primaryBlue,
                        ),
                        SizedBox(width: Responsive.isSmallMobile(context) ? 4 : 6),
                        Text(
                          transportType['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize:
                                Responsive.isSmallMobile(context) ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      final value = transportType['value']!;
                      setState(() => _selectedTransportType = value);
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

  Widget _buildTransportationBookingsTab(ThemeData theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildTransportationFilters(theme)),
        _isLoadingBookings
            ? SliverFillRemaining(child: _buildLoadingState(theme))
            : _buildTransportationBookingsList(theme),
      ],
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic> errand, ThemeData theme) {
    final imageUrls = errand['image_urls'] as List<dynamic>? ?? [];
    final pdfUrls = errand['pdf_urls'] as List<dynamic>? ?? [];
    final totalDocuments = imageUrls.length + pdfUrls.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LottoRunnersColors.gray50,
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
                  const Icon(
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
                color: LottoRunnersColors.gray900,
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
                color: LottoRunnersColors.gray900,
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
          color: Colors.white,
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
                      color: LottoRunnersColors.gray900,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 14,
                    ),
                  ),
                  Text(
                    'View or download document',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: LottoRunnersColors.gray600,
                      fontSize: Responsive.isSmallMobile(context) ? 10 : 12,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not download $fileName'),
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
          final pickupShort = pickup.length > 25 ? '${pickup.substring(0, 25)}...' : pickup;
          final deliveryShort = delivery.length > 25 ? '${delivery.substring(0, 25)}...' : delivery;
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
          final pickupShort = pickup.length > 25 ? '${pickup.substring(0, 25)}...' : pickup;
          final dropoffShort = dropoff.length > 25 ? '${dropoff.substring(0, 25)}...' : dropoff;
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
}

class AppBarPatternPainter extends CustomPainter {
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
