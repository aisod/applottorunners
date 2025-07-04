import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/errand_card.dart';

class BrowseErrandsPage extends StatefulWidget {
  const BrowseErrandsPage({super.key});

  @override
  State<BrowseErrandsPage> createState() => _BrowseErrandsPageState();
}

class _BrowseErrandsPageState extends State<BrowseErrandsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _errands = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  Map<String, dynamic>? _userProfile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All', 'icon': 'grid_view'},
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
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getUserProfile(userId);
        setState(() => _userProfile = profile);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadErrands() async {
    try {
      setState(() => _isLoading = true);
      final errands = await SupabaseConfig.getErrands(status: 'posted');
      print('Loaded ${errands.length} errands'); // Debug info
      if (mounted) {
        setState(() {
          _errands = errands;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading errands: $e'); // Debug info
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load errands. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
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

  List<Map<String, dynamic>> get _filteredErrands {
    return _errands.where((errand) {
      // Filter by category
      if (_selectedCategory != 'all' &&
          errand['category'] != _selectedCategory) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = errand['title']?.toString().toLowerCase() ?? '';
        final description =
            errand['description']?.toString().toLowerCase() ?? '';
        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Don't filter by vehicle requirement - let runners see all errands
      // They can decide if they want to take jobs that require vehicles

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(child: _buildSearchAndFilters(theme)),
          _isLoading
              ? SliverFillRemaining(child: _buildLoadingState(theme))
              : _buildErrandsList(theme),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: LottoRunnersColors.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Browse Errands',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
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
                bottom: 60,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        '${_errands.length}', 'Total', Icons.assignment),
                    _buildStatItem('${_filteredErrands.length}', 'Available',
                        Icons.visibility),
                    _buildStatItem(
                        '${_userProfile?['user_type'] == 'runner' ? 'Runner' : 'Customer'}',
                        'Mode',
                        Icons.person),
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
          icon: Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh errands',
        ),
        IconButton(
          onPressed: () => _showFilterDialog(theme),
          icon: Icon(Icons.tune, color: Colors.white),
          tooltip: 'Advanced filters',
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search errands by title or description...',
              hintStyle: TextStyle(color: LottoRunnersColors.gray400),
              prefixIcon:
                  Icon(Icons.search, color: LottoRunnersColors.primaryBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon:
                          Icon(Icons.clear, color: LottoRunnersColors.gray400),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: LottoRunnersColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: TextStyle(
              color: LottoRunnersColors.gray900,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          // Category filters
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconData(category['icon']!),
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : LottoRunnersColors.primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : LottoRunnersColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category['value']!);
                      },
                      backgroundColor: LottoRunnersColors.gray50,
                      selectedColor: LottoRunnersColors.primaryBlue,
                      checkmarkColor: Colors.white,
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
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
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

    if (filteredErrands.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(theme));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final errand = filteredErrands[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.5),
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
                  child: ErrandCard(
                    errand: errand,
                    onTap: () => _showErrandDetails(errand),
                    showAcceptButton: _userProfile?['user_type'] == 'runner',
                    onAccept: () => _acceptErrand(errand),
                  ),
                ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
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
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
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

  void _showFilterDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advanced Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Vehicle Required Only'),
              subtitle: Text('Show only errands that require a vehicle'),
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
            child: Text('Close'),
          ),
        ],
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
      decoration: BoxDecoration(
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
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
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
                          color:
                              LottoRunnersColors.primaryBlue.withOpacity(0.1),
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
                          color:
                              LottoRunnersColors.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color:
                              LottoRunnersColors.primaryYellow.withOpacity(0.8),
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
                          color: LottoRunnersColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
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
                          Icon(
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
                        gradient: LinearGradient(
                          colors: [
                            LottoRunnersColors.primaryBlue,
                            LottoRunnersColors.primaryBlueDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                LottoRunnersColors.primaryBlue.withOpacity(0.3),
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
                                color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Accept Errand',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(LottoRunnersColors.primaryBlue),
                ),
                const SizedBox(height: 16),
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
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
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
}

class AppBarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
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
