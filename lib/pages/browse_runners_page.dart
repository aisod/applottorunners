import 'package:flutter/material.dart';
import '../theme.dart';
import '../supabase/supabase_config.dart';
import '../utils/responsive.dart';

/// Browse Runners Page
///
/// This page allows users to browse and view profiles of all verified runners
/// in the system, helping them find trusted runners for their errands.
class BrowseRunnersPage extends StatefulWidget {
  const BrowseRunnersPage({super.key});

  @override
  State<BrowseRunnersPage> createState() => _BrowseRunnersPageState();
}

class _BrowseRunnersPageState extends State<BrowseRunnersPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _runners = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, verified, has_vehicle
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadRunners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRunners() async {
    setState(() => _isLoading = true);
    try {
      final runners = await SupabaseConfig.getRunners();
      setState(() {
        _runners = runners;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading runners: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRunners {
    return _runners.where((runner) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = runner['full_name']?.toString().toLowerCase() ?? '';
        final location =
            runner['location_address']?.toString().toLowerCase() ?? '';
        if (!name.contains(query) && !location.contains(query)) {
          return false;
        }
      }

      // Filter by type
      switch (_filterType) {
        case 'verified':
          return runner['is_verified'] == true;
        case 'has_vehicle':
          return runner['has_vehicle'] == true;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSearchAndFilters()),
            _isLoading
                ? SliverFillRemaining(child: _buildLoadingState())
                : _buildRunnersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: LottoRunnersColors.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Browse Runners',
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
                bottom: 60,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        '${_runners.length}', 'Total Runners', Icons.people),
                    _buildStatItem(
                        '${_runners.where((r) => r['is_verified'] == true).length}',
                        'Verified',
                        Icons.verified),
                    _buildStatItem(
                        '${_runners.where((r) => r['has_vehicle'] == true).length}',
                        'With Vehicle',
                        Icons.directions_car),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onPrimary.withOpacity(0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: LottoRunnersColors.gray900.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search runners by name or location...',
                prefixIcon:
                    const Icon(Icons.search, color: LottoRunnersColors.gray600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter chips
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', 'verified'),
              const SizedBox(width: 8),
              _buildFilterChip('Has Vehicle', 'has_vehicle'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = value);
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: LottoRunnersColors.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? LottoRunnersColors.primaryBlue
            : LottoRunnersColors.gray700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? LottoRunnersColors.primaryBlue
            : LottoRunnersColors.gray300,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: LottoRunnersColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Loading runners...',
            style: TextStyle(
              color: LottoRunnersColors.gray600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnersList() {
    final filteredRunners = _filteredRunners;

    if (filteredRunners.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.isMobile(context)
              ? 1
              : Responsive.isTablet(context)
                  ? 2
                  : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: Responsive.isMobile(context) ? 2.5 : 2.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final runner = filteredRunners[index];
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
                child: _buildRunnerCard(runner),
              ),
            );
          },
          childCount: filteredRunners.length,
        ),
      ),
    );
  }

  Widget _buildRunnerCard(Map<String, dynamic> runner) {
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
          onTap: () => _showRunnerProfile(runner),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar and verification badge
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            LottoRunnersColors.primaryBlue,
                            LottoRunnersColors.accent
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.transparent,
                        backgroundImage: runner['avatar_url'] != null
                            ? NetworkImage(runner['avatar_url'])
                            : null,
                        child: runner['avatar_url'] == null
                            ? Text(
                                runner['full_name']
                                        ?.toString()
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'R',
                                style: const TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Name and verification status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  runner['full_name'] ?? 'Unknown Runner',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: LottoRunnersColors.gray900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (runner['is_verified'] == true)
                                const Icon(
                                  Icons.verified,
                                  color: LottoRunnersColors.accent,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: LottoRunnersColors.gray600,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  runner['location_address'] ??
                                      'Location not specified',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: LottoRunnersColors.gray600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Features/badges row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Features
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (runner['is_verified'] == true)
                            _buildFeatureBadge('Verified', Icons.verified,
                                LottoRunnersColors.accent),
                          if (runner['has_vehicle'] == true)
                            _buildFeatureBadge(
                                'Has Vehicle',
                                Icons.directions_car,
                                LottoRunnersColors.primaryBlue),
                        ],
                      ),

                      const Spacer(),

                      // Join date
                      Text(
                        'Joined ${_formatDate(runner['created_at'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: LottoRunnersColors.gray600,
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
    );
  }

  Widget _buildFeatureBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: LottoRunnersColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterType != 'all'
                ? 'No runners found'
                : 'No runners available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: LottoRunnersColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterType != 'all'
                ? 'Try adjusting your search or filters'
                : 'There are no registered runners yet',
            style: const TextStyle(
              fontSize: 14,
              color: LottoRunnersColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRunnerProfile(Map<String, dynamic> runner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: _buildRunnerProfileContent(runner),
          ),
        ),
      ),
    );
  }

  Widget _buildRunnerProfileContent(Map<String, dynamic> runner) {
    return Padding(
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

          // Profile header
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      LottoRunnersColors.primaryBlue,
                      LottoRunnersColors.accent
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.transparent,
                  backgroundImage: runner['avatar_url'] != null
                      ? NetworkImage(runner['avatar_url'])
                      : null,
                  child: runner['avatar_url'] == null
                      ? Text(
                          runner['full_name']
                                  ?.toString()
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'R',
                          style: const TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            runner['full_name'] ?? 'Unknown Runner',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: LottoRunnersColors.gray900,
                            ),
                          ),
                        ),
                        if (runner['is_verified'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: LottoRunnersColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: LottoRunnersColors.accent
                                      .withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 16, color: LottoRunnersColors.accent),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LottoRunnersColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Runner since ${_formatDate(runner['created_at'])}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: LottoRunnersColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Contact information
          if (runner['phone'] != null)
            _buildInfoRow('Phone', runner['phone'], Icons.phone),
          if (runner['email'] != null)
            _buildInfoRow('Email', runner['email'], Icons.email),
          if (runner['location_address'] != null)
            _buildInfoRow(
                'Location', runner['location_address'], Icons.location_on),

          const SizedBox(height: 24),

          // Features section
          const Text(
            'Capabilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LottoRunnersColors.gray900,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (runner['is_verified'] == true)
                _buildCapabilityChip('Verified Runner', Icons.verified,
                    LottoRunnersColors.accent),
              if (runner['has_vehicle'] == true)
                _buildCapabilityChip('Has Vehicle', Icons.directions_car,
                    LottoRunnersColors.primaryBlue),
              _buildCapabilityChip('Active Runner', Icons.flash_on,
                  LottoRunnersColors.primaryPurple),
            ],
          ),

          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // You can add logic here to contact the runner or create an errand for them
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Contact ${runner['full_name']} feature coming soon!'),
                    backgroundColor: LottoRunnersColors.accent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.message),
              label: const Text(
                'Contact Runner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LottoRunnersColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: LottoRunnersColors.gray600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LottoRunnersColors.gray600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: LottoRunnersColors.gray900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference < 30) {
        return '$difference days ago';
      } else if (difference < 365) {
        final months = (difference / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

/// Custom painter for the app bar background pattern
class AppBarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8 + i * 20, size.height * 0.3 - i * 5),
        20 + i * 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
