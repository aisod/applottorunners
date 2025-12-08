import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/errand_card.dart';
import 'package:lotto_runners/utils/responsive.dart';

class BrowseErrandsPage extends StatefulWidget {
  const BrowseErrandsPage({super.key});

  @override
  State<BrowseErrandsPage> createState() => _BrowseErrandsPageState();
}

class _BrowseErrandsPageState extends State<BrowseErrandsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _allItems = []; // Combined errands and bookings
  List<Map<String, dynamic>> _errands = [];
  List<Map<String, dynamic>> _transportationBookings = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  Map<String, dynamic>? _userProfile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All History', 'icon': 'history'},
    {'value': 'errands', 'label': 'My Errands', 'icon': 'assignment'},
    {'value': 'grocery', 'label': 'Grocery', 'icon': 'shopping_cart'},
    {'value': 'delivery', 'label': 'Delivery', 'icon': 'local_shipping'},
    {'value': 'document', 'label': 'Documents', 'icon': 'description'},
    {'value': 'shopping', 'label': 'Shopping', 'icon': 'shopping_bag'},
    {'value': 'other', 'label': 'Other', 'icon': 'more_horiz'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserProfile();
    _loadErrands();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final profile = await SupabaseConfig.getUserProfile(user.id);
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadErrands() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final errands = await SupabaseConfig.getMyErrands(user.id);
        final bookings = await SupabaseConfig.getUserBookings(user.id);

        setState(() {
          _errands = errands;
          _transportationBookings = bookings;
          _allItems = [
            ...errands.map((e) => {
                  ...e,
                  'item_type': 'errand',
                }),
            ...bookings.map((b) => {
                  ...b,
                  'item_type': 'transportation',
                  'title': 'Transportation Booking',
                  'category': 'transportation',
                  'description':
                      '${b['pickup_location']} → ${b['dropoff_location']}',
                }),
          ];
          _isLoading = false;
        });

        // Start the animation after loading
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading errands: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _combineAndPrepareItems(
      List<Map<String, dynamic>> errands, List<Map<String, dynamic>> bookings) {
    List<Map<String, dynamic>> combinedItems = [];

    // Add errands with type identifier
    for (var errand in errands) {
      combinedItems.add({
        ...errand,
        'item_type': 'errand',
        'sort_date': errand['created_at'] ?? DateTime.now().toIso8601String(),
      });
    }

    // Add transportation bookings with type identifier
    for (var booking in bookings) {
      combinedItems.add({
        ...booking,
        'item_type': 'transportation',
        'title': 'Transportation Booking',
        'category': 'transportation',
        'description':
            '${booking['pickup_location']} → ${booking['dropoff_location']}',
        'sort_date': booking['created_at'] ?? DateTime.now().toIso8601String(),
      });
    }

    // Sort by creation date (newest first)
    combinedItems.sort((a, b) {
      final dateA = DateTime.tryParse(a['sort_date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['sort_date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    _allItems = combinedItems;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onError),
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

  List<Map<String, dynamic>> get _filteredItems {
    return _allItems.where((item) {
      // Filter by category
      if (_selectedCategory != 'all') {
        if (_selectedCategory == 'errands' && item['item_type'] != 'errand') {
          return false;
        }
        if (_selectedCategory == 'transportation' &&
            item['item_type'] != 'transportation') {
          return false;
        }
        if (_selectedCategory != 'errands' &&
            _selectedCategory != 'transportation' &&
            item['category'] != _selectedCategory) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = item['title']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        final pickupLocation =
            item['pickup_location']?.toString().toLowerCase() ?? '';
        final dropoffLocation =
            item['dropoff_location']?.toString().toLowerCase() ?? '';

        if (!title.contains(query) &&
            !description.contains(query) &&
            !pickupLocation.contains(query) &&
            !dropoffLocation.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          slivers: [
            _buildAppBar(theme),
            SliverToBoxAdapter(child: _buildSearchAndFilters(theme)),
            _isLoading
                ? SliverFillRemaining(child: _buildLoadingState(theme))
                : _buildHistoryList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return SliverAppBar(
      expandedHeight: isSmallMobile ? 100 : 120,
      floating: false,
      pinned: true,
      backgroundColor: LottoRunnersColors.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My History',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: AppBarPatternPainter(),
                ),
              ),
              // Stats overlay
              Positioned(
                bottom: isSmallMobile ? 40 : 60,
                left: isSmallMobile ? 12 : 20,
                right: isSmallMobile ? 12 : 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        '${_errands.length}', 'Errands', Icons.assignment),
                    _buildStatItem('${_transportationBookings.length}',
                        'Bookings', Icons.directions_bus),
                    _buildStatItem(
                        '${_allItems.length}', 'Total', Icons.history),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadErrands,
          icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
          tooltip: 'Refresh errands',
        ),
        IconButton(
          onPressed: () => _showFilterDialog(theme),
          icon: Icon(Icons.tune, color: theme.colorScheme.onPrimary),
          tooltip: 'Advanced filters',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 12 : 16),
      padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search errands and bookings...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 12 : 16,
                vertical: isSmallMobile ? 12 : 16,
              ),
              isDense: isSmallMobile,
            ),
          ),
          SizedBox(height: isSmallMobile ? 12 : 16),
          // Category filter
          Text(
            'Filter by Category',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallMobile ? 13 : 14,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8 : 12),
          // Category chips
          Wrap(
            spacing: isSmallMobile ? 6 : 8,
            runSpacing: isSmallMobile ? 6 : 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category['value'];
              return FilterChip(
                label: Text(
                  category['label']!,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 11 : 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _onCategoryChanged(category['value']);
                  }
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: LottoRunnersColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: LottoRunnersColors.primaryBlue,
                side: BorderSide(
                  color: isSelected
                      ? LottoRunnersColors.primaryBlue
                      : theme.colorScheme.outline,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 8 : 12,
                  vertical: isSmallMobile ? 6 : 8,
                ),
              );
            }).toList(),
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
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
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

  Widget _buildHistoryList(ThemeData theme) {
    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filteredItems[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1 + 0.5).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: item['item_type'] == 'transportation'
                      ? _buildTransportationCard(item)
                      : ErrandCard(
                          errand: item,
                          onTap: () => _showItemDetails(item),
                          showAcceptButton:
                              false, // No accept button in history
                          onAccept: () {}, // Not used in history
                        ),
                ),
              ),
            );
          },
          childCount: filteredItems.length,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _selectedCategory != 'all'
                    ? Icons.search_off
                    : Icons.assignment_outlined,
                size: 60,
                color: LottoRunnersColors.primaryBlue,
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
                _loadErrands();
              },
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              label: const Text(
                'Refresh Errands',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
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

  void _showFilterDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Vehicle Required Only'),
              subtitle: const Text('Show only errands that require a vehicle'),
              value: false, // You can add this as a state variable
              onChanged: (value) {
                // Implement vehicle filter logic
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    if (item['item_type'] == 'transportation') {
      _showTransportationDetails(item);
    } else {
      _showErrandDetails(item);
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

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title and category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          errand['title'] ?? '',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: LottoRunnersColors.gray900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: LottoRunnersColors.primaryBlue
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (errand['category'] ?? '').toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: LottoRunnersColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LottoRunnersColors.primaryPurple
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: LottoRunnersColors.primaryPurple
                              .withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'N\$${errand['price_amount']?.toString() ?? '0'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: LottoRunnersColors.gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              LottoRunnersColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.timer,
                          color: LottoRunnersColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${errand['time_limit_hours']}h limit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: LottoRunnersColors.gray700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
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
                    child: Text(
                      errand['description'] ?? 'No description provided',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: LottoRunnersColors.gray700,
                        height: 1.6,
                      ),
                    ),
                  ),

                  // Location if available
                  if (errand['location_address'] != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Location',
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
                          const Icon(
                            Icons.location_on,
                            color: LottoRunnersColors.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errand['location_address'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: LottoRunnersColors.gray700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Accept button for runners
                  if (_userProfile?['user_type'] == 'runner') ...[
                    Container(
                      width: double.infinity,
                      height: 56,
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
                            const Icon(Icons.check_circle,
                                color: theme.colorScheme.onPrimary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Accept Errand',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You have reached the maximum limit of 2 active jobs. Please complete all jobs before accepting new ones.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
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
              color: theme.colorScheme.onPrimary,
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

      await SupabaseConfig.acceptErrand(errand['id'], userId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Errand accepted successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: LottoRunnersColors.accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _loadErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to accept errand. Please try again.');
      }
    }
  }

  void _onCategoryChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedCategory = value;
      });
    }
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimary,
          size: isSmallMobile ? 20 : 24,
        ),
        SizedBox(height: isSmallMobile ? 4 : 8),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: isSmallMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isSmallMobile ? 10 : 12,
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  String _formatHistoryDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildTransportationCard(Map<String, dynamic> booking) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: LottoRunnersColors.gray900.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransportationDetails(booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with transportation icon and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: LottoRunnersColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transportation Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: LottoRunnersColors.gray900,
                            ),
                          ),
                          Text(
                            _formatHistoryDate(booking['created_at']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: LottoRunnersColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(booking['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(booking['status'])
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        booking['status']?.toString().toUpperCase() ??
                            'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(booking['status']),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              color: LottoRunnersColors.gray600,
                            ),
                          ),
                          Text(
                            booking['pickup_location'] ?? 'Not specified',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: LottoRunnersColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: LottoRunnersColors.gray400,
                      size: 20,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              color: LottoRunnersColors.gray600,
                            ),
                          ),
                          Text(
                            booking['dropoff_location'] ?? 'Not specified',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: LottoRunnersColors.gray900,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom row with price and passengers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (booking['passenger_count'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: LottoRunnersColors.gray600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${booking['passenger_count']} passenger${booking['passenger_count'] == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: LottoRunnersColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    if (booking['final_price'] != null)
                      Text(
                        '\$${booking['final_price'].toString()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LottoRunnersColors.accent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransportationDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LottoRunnersColors.gray300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Header
                  const Text(
                    'Transportation Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: LottoRunnersColors.gray900,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Status',
                      booking['status']?.toString().toUpperCase() ?? 'PENDING'),
                  _buildDetailRow(
                      'From', booking['pickup_location'] ?? 'Not specified'),
                  _buildDetailRow(
                      'To', booking['dropoff_location'] ?? 'Not specified'),
                  if (booking['booking_date'] != null)
                    _buildDetailRow(
                        'Date', _formatHistoryDate(booking['booking_date'])),
                  if (booking['booking_time'] != null)
                    _buildDetailRow('Time', booking['booking_time']),
                  if (booking['passenger_count'] != null)
                    _buildDetailRow(
                        'Passengers', booking['passenger_count'].toString()),
                  if (booking['final_price'] != null)
                    _buildDetailRow('Price', '\$${booking['final_price']}'),
                  if (booking['special_requests'] != null &&
                      booking['special_requests'].toString().isNotEmpty)
                    _buildDetailRow(
                        'Special Requests', booking['special_requests']),
                  if (booking['notes'] != null &&
                      booking['notes'].toString().isNotEmpty)
                    _buildDetailRow('Notes', booking['notes']),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: LottoRunnersColors.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LottoRunnersColors.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return LottoRunnersColors.accent;
      case 'confirmed':
        return LottoRunnersColors.primaryBlue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return LottoRunnersColors.primaryPurple;
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
