import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Provider Accounting Page
///
/// This page displays all runners/providers with their bookings and earnings.
/// Company takes 33.3% commission, runners receive 66.7% of booking amounts.
class ProviderAccountingPage extends StatefulWidget {
  const ProviderAccountingPage({super.key});

  @override
  State<ProviderAccountingPage> createState() => _ProviderAccountingPageState();
}

class _ProviderAccountingPageState extends State<ProviderAccountingPage> {
  List<Map<String, dynamic>> _runnerEarnings = [];
  Map<String, dynamic> _companyTotals = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy =
      'total_revenue'; // total_revenue, runner_name, total_bookings

  @override
  void initState() {
    super.initState();
    _loadAccountingData();
  }

  Future<void> _loadAccountingData() async {
    setState(() => _isLoading = true);

    try {
      // Use proper database view method
      final earnings = await SupabaseConfig.getRunnerEarningsSummary();
      final totals = await SupabaseConfig.getCompanyCommissionTotals();

      // DEBUG: Print detailed information
      print('\n🔍 DEBUG: Provider Accounting Data');
      print('   Runners loaded: ${earnings.length}');
      print('   Total bookings (from totals): ${totals['total_bookings']}');
      print('   Total revenue: ${totals['total_revenue']}');

      if (earnings.isNotEmpty) {
        print('\n   📊 Sample runner data:');
        for (int i = 0; i < (earnings.length > 3 ? 3 : earnings.length); i++) {
          final runner = earnings[i];
          print('   Runner ${i + 1}:');
          print('      Name: ${runner['runner_name']}');
          print('      Email: ${runner['runner_email']}');
          print('      Total Bookings: ${runner['total_bookings']}');
          print('      Total Revenue: ${runner['total_revenue']}');
          print(
              '      Company Commission: ${runner['total_company_commission']}');
          print('      Runner Earnings: ${runner['total_runner_earnings']}');
          print(
              '      Transportation Count: ${runner['transportation_count']}');
          print('      Bus Count: ${runner['bus_count']}');
        }
      } else {
        print('   ⚠️  No runners found in earnings summary!');
      }

      setState(() {
        _runnerEarnings = earnings;
        _companyTotals = totals;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR loading accounting data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading accounting data: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedRunners {
    var filtered = _runnerEarnings;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((runner) {
        final name = (runner['runner_name'] ?? '').toString().toLowerCase();
        final email = (runner['runner_email'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'runner_name':
          return (a['runner_name'] ?? '')
              .toString()
              .compareTo((b['runner_name'] ?? '').toString());
        case 'total_bookings':
          return ((b['total_bookings'] ?? 0) as num)
              .compareTo((a['total_bookings'] ?? 0) as num);
        case 'total_revenue':
        default:
          return ((b['total_revenue'] ?? 0) as num)
              .compareTo((a['total_revenue'] ?? 0) as num);
      }
    });

    return filtered;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAccountingData,
      child: SingleChildScrollView(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompanyTotalsSection(theme, isMobile, isSmallMobile),
            SizedBox(height: isMobile ? 16 : 24),
            _buildSearchAndFilterSection(theme, isMobile, isSmallMobile),
            SizedBox(height: isMobile ? 12 : 16),
            _buildRunnersListSection(theme, isMobile, isSmallMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyTotalsSection(
      ThemeData theme, bool isMobile, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            LottoRunnersColors.primaryBlue,
            LottoRunnersColors.primaryPurple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Icon(Icons.account_balance,
                  color: Theme.of(context).colorScheme.onPrimary, size: isMobile ? 24 : 28),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Company Overview',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: isMobile ? 1.8 : 2.5,
            children: [
              _buildTotalCard(
                  'Total Revenue',
                  'N\$${(_companyTotals['total_revenue'] ?? 0).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.white,
                  isSmallMobile,
                  isMobile),
              _buildTotalCard(
                  'Company Commission (33.3%)',
                  'N\$${(_companyTotals['total_commission'] ?? 0).toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  LottoRunnersColors.primaryYellow,
                  isSmallMobile,
                  isMobile),
              _buildTotalCard(
                  'Runner Earnings (66.7%)',
                  'N\$${(_companyTotals['total_runner_earnings'] ?? 0).toStringAsFixed(2)}',
                  Icons.people,
                  Colors.greenAccent,
                  isSmallMobile,
                  isMobile),
              _buildTotalCard(
                  'Total Bookings',
                  '${_companyTotals['total_bookings'] ?? 0}',
                  Icons.assignment,
                  Colors.white70,
                  isSmallMobile,
                  isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, String value, IconData icon, Color color,
      bool isSmallMobile, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 6 : (isMobile ? 8 : 12)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: color, size: isSmallMobile ? 20 : (isMobile ? 24 : 28)),
          SizedBox(height: isSmallMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              fontSize: isSmallMobile ? 9 : (isMobile ? 10 : 12),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(
      ThemeData theme, bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search runners...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        DropdownButton<String>(
          value: _sortBy,
          icon: const Icon(Icons.sort),
          underline: Container(),
          items: const [
            DropdownMenuItem(value: 'total_revenue', child: Text('Revenue')),
            DropdownMenuItem(value: 'runner_name', child: Text('Name')),
            DropdownMenuItem(value: 'total_bookings', child: Text('Bookings')),
          ],
          onChanged: (value) =>
              setState(() => _sortBy = value ?? 'total_revenue'),
        ),
      ],
    );
  }

  Widget _buildRunnersListSection(
      ThemeData theme, bool isMobile, bool isSmallMobile) {
    final filteredRunners = _filteredAndSortedRunners;

    if (filteredRunners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.people_outline,
                  size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No runners found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRunners.length,
      itemBuilder: (context, index) {
        final runner = filteredRunners[index];
        return _buildRunnerCard(runner, theme, isMobile, isSmallMobile);
      },
    );
  }

  Widget _buildRunnerCard(Map<String, dynamic> runner, ThemeData theme,
      bool isMobile, bool isSmallMobile) {
    final runnerName = runner['runner_name'] ?? 'Unknown Runner';
    final runnerEmail = runner['runner_email'] ?? '';
    final totalRevenue = (runner['total_revenue'] as num?)?.toDouble() ?? 0;
    final companyCommission =
        (runner['total_company_commission'] as num?)?.toDouble() ?? 0;
    final runnerEarnings =
        (runner['total_runner_earnings'] as num?)?.toDouble() ?? 0;
    final totalBookings = runner['total_bookings'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRunnerDetails(runner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: LottoRunnersColors.primaryBlue,
                    child: Text(
                      runnerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          runnerName,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          runnerEmail,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 14),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Divider(
                  height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              SizedBox(height: isMobile ? 12 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Bookings', '$totalBookings',
                      Icons.assignment, theme, isSmallMobile, isMobile),
                  _buildStatColumn(
                      'Revenue',
                      'N\$${totalRevenue.toStringAsFixed(2)}',
                      Icons.attach_money,
                      theme,
                      isSmallMobile,
                      isMobile),
                  _buildStatColumn(
                      'Commission',
                      'N\$${companyCommission.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      theme,
                      isSmallMobile,
                      isMobile),
                  _buildStatColumn(
                      'Earnings',
                      'N\$${runnerEarnings.toStringAsFixed(2)}',
                      Icons.money,
                      theme,
                      isSmallMobile,
                      isMobile),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon,
      ThemeData theme, bool isSmallMobile, bool isMobile) {
    return Column(
      children: [
        Icon(icon,
            size: isSmallMobile ? 16 : (isMobile ? 18 : 20),
            color: LottoRunnersColors.primaryBlue),
        SizedBox(height: isSmallMobile ? 4 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallMobile ? 12 : (isMobile ? 13 : 14),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallMobile ? 9 : (isMobile ? 10 : 11),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showRunnerDetails(Map<String, dynamic> runner) async {
    final runnerId = runner['runner_id'];

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookings = await SupabaseConfig.getRunnerDetailedBookings(runnerId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return _buildRunnerDetailsSheet(runner, bookings, scrollController);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Error loading runner details: $e');
    }
  }

  Widget _buildRunnerDetailsSheet(Map<String, dynamic> runner,
      List<Map<String, dynamic>> bookings, ScrollController scrollController) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${runner['runner_name']} - Bookings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookings.isEmpty
                ? const Center(child: Text('No bookings found'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildBookingTile(booking, theme, isMobile);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTile(
      Map<String, dynamic> booking, ThemeData theme, bool isMobile) {
    final bookingType = booking['booking_type'] ?? 'Unknown';
    final customerName = booking['customer_name'] ?? 'Unknown Customer';
    final description = booking['description'] ?? '';
    final status = booking['status'] ?? '';
    final amount = (booking['amount'] as num?)?.toDouble() ?? 0;
    final commission = (booking['company_commission'] as num?)?.toDouble() ?? 0;
    final earnings = (booking['runner_earnings'] as num?)?.toDouble() ?? 0;
    
    // Extract service type information
    final serviceType = booking['service_type'] as String?;
    final pricingModifiers = booking['pricing_modifiers'] as Map?;
    final serviceTypeFromModifiers = pricingModifiers?['service_type'] as String?;
    final finalServiceType = serviceType ?? serviceTypeFromModifiers;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label:
                      Text(bookingType, style: TextStyle(fontSize: 11)),
                  backgroundColor:
                      LottoRunnersColors.primaryBlue.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(status, style: TextStyle(fontSize: 11)),
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                ),
                if (finalServiceType != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      _getServiceTypeName(finalServiceType),
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: LottoRunnersColors.primaryYellow.withOpacity(0.2),
                    padding: EdgeInsets.zero,
                  ),
                ],
                const Spacer(),
                Text(
                  'N\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              customerName,
              style: theme.textTheme.titleSmall,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Commission',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('N\$${commission.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Runner Earnings',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('N\$${earnings.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'confirmed':
      case 'accepted':
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeName(String serviceType) {
    // Convert service type codes to human-readable names
    final Map<String, String> serviceTypeNames = {
      // License Discs
      'renewal': 'Disc Renewal',
      'registration': 'Vehicle Registration',
      // Document Services
      'application_submission': 'Application Submission',
      'certification': 'Document Certification',
      // Queue Sitting
      'now': 'Queue Now',
      'scheduled': 'Queue Scheduled',
      // Shopping
      'personal': 'Personal Shopping',
      'grocery': 'Grocery Shopping',
      // Delivery Vehicles
      'Motorcycle': 'Motorcycle',
      'Sedan': 'Sedan',
      'Mini Truck': 'Mini Truck',
      'Truck': 'Truck',
      // Shopping Types
      'groceries': 'Groceries',
      'pharmacy': 'Pharmacy',
      'general': 'General Shopping',
      'specific_items': 'Specific Items',
    };

    return serviceTypeNames[serviceType] ?? serviceType.replaceAll('_', ' ').toUpperCase();
  }
}
