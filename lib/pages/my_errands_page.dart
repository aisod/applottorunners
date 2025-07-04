import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/errand_card.dart';

class MyErrandsPage extends StatefulWidget {
  const MyErrandsPage({super.key});

  @override
  State<MyErrandsPage> createState() => _MyErrandsPageState();
}

class _MyErrandsPageState extends State<MyErrandsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _errands = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
    _loadMyErrands();
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

  Future<void> _loadMyErrands() async {
    try {
      setState(() => _isLoading = true);
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final errands = await SupabaseConfig.getMyErrands(userId);
        if (mounted) {
          setState(() {
            _errands = errands;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading errands: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getErrandsByStatus(String status) {
    return _errands.where((errand) => errand['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Errands',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadMyErrands,
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildErrandsList(['posted', 'accepted'], 'active', theme),
                _buildErrandsList(['in_progress'], 'in_progress', theme),
                _buildErrandsList(['completed'], 'completed', theme),
                _buildErrandsList([
                  'posted',
                  'accepted',
                  'in_progress',
                  'completed',
                  'cancelled'
                ], 'all', theme),
              ],
            ),
    );
  }

  Widget _buildErrandsList(
      List<String> statusFilter, String tabType, ThemeData theme) {
    final filteredErrands = _errands.where((errand) {
      return statusFilter.contains(errand['status']);
    }).toList();

    if (filteredErrands.isEmpty) {
      return _buildEmptyState(tabType, theme);
    }

    return RefreshIndicator(
      onRefresh: _loadMyErrands,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredErrands.length,
        itemBuilder: (context, index) {
          final errand = filteredErrands[index];
          final isCustomer =
              errand['customer_id'] == SupabaseConfig.currentUser?.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ErrandCard(
              errand: errand,
              onTap: () => _showErrandDetails(errand),
              showStatusUpdate: !isCustomer &&
                  (errand['status'] == 'accepted' ||
                      errand['status'] == 'in_progress'),
              onStatusUpdate: () => _updateErrandStatus(errand),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String tabType, ThemeData theme) {
    String title;
    String message;
    IconData icon;

    switch (tabType) {
      case 'active':
        title = 'No Active Errands';
        message = 'Your active errands will appear here.';
        icon = Icons.assignment;
        break;
      case 'in_progress':
        title = 'No Errands In Progress';
        message = 'Errands currently being worked on will appear here.';
        icon = Icons.work;
        break;
      case 'completed':
        title = 'No Completed Errands';
        message = 'Your completed errands will appear here.';
        icon = Icons.check_circle;
        break;
      default:
        title = 'No Errands Yet';
        message = 'Start by posting an errand or accepting one as a runner.';
        icon = Icons.assignment_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrandDetails(Map<String, dynamic> errand) {
    final theme = Theme.of(context);
    final isCustomer = errand['customer_id'] == SupabaseConfig.currentUser?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    _buildDetailHeader(errand, theme),
                    const SizedBox(height: 24),

                    // Description
                    _buildDetailSection(
                        'Description', errand['description'] ?? '', theme),

                    // Location details
                    if (errand['location_address'] != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection(
                          'Location', errand['location_address'], theme),
                    ],

                    // Pickup/Delivery addresses
                    if (errand['pickup_address'] != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                          'Pickup', errand['pickup_address'], theme),
                    ],

                    if (errand['delivery_address'] != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                          'Delivery', errand['delivery_address'], theme),
                    ],

                    // Special instructions
                    if (errand['special_instructions'] != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Special Instructions',
                          errand['special_instructions'], theme),
                    ],

                    // Images
                    if (errand['image_urls'] != null &&
                        (errand['image_urls'] as List).isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildImagesSection(errand['image_urls'], theme),
                    ],

                    // People involved
                    const SizedBox(height: 20),
                    _buildPeopleSection(errand, isCustomer, theme),

                    // Action buttons
                    if (!isCustomer &&
                        (errand['status'] == 'accepted' ||
                            errand['status'] == 'in_progress')) ...[
                      const SizedBox(height: 32),
                      _buildActionButtons(errand, theme),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> errand, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                errand['title'] ?? '',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (errand['category'] ?? '').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price, time, and status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'N\$${errand['price_amount']?.toString() ?? '0'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${errand['time_limit_hours']}h limit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(List<dynamic> imageUrls, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Images',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        color: theme.colorScheme.outline,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleSection(
      Map<String, dynamic> errand, bool isCustomer, ThemeData theme) {
    final customer = errand['customer'];
    final runner = errand['runner'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People Involved',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Customer
        _buildPersonTile(
          'Customer',
          customer?['full_name'] ?? 'Unknown',
          customer?['phone'],
          Icons.person,
          theme.colorScheme.primary,
          theme,
        ),

        if (runner != null) ...[
          const SizedBox(height: 8),
          _buildPersonTile(
            'Runner',
            runner['full_name'] ?? 'Unknown',
            runner['phone'],
            Icons.directions_run,
            theme.colorScheme.secondary,
            theme,
          ),
        ],
      ],
    );
  }

  Widget _buildPersonTile(String role, String name, String? phone,
      IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$role: $name',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> errand, ThemeData theme) {
    final status = errand['status'];

    return Column(
      children: [
        if (status == 'accepted') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(errand, 'in_progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Errand',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (status == 'in_progress') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus(errand, 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mark as Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _updateErrandStatus(Map<String, dynamic> errand) {
    final status = errand['status'];

    if (status == 'accepted') {
      _updateStatus(errand, 'in_progress');
    } else if (status == 'in_progress') {
      _updateStatus(errand, 'completed');
    }
  }

  Future<void> _updateStatus(
      Map<String, dynamic> errand, String newStatus) async {
    try {
      await SupabaseConfig.updateErrandStatus(errand['id'], newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Status updated to ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context); // Close the details modal
        _loadMyErrands(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
