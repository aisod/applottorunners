import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Vehicle Discount Management Page
/// 
/// Allows admins to manage discount percentages for ride services (vehicles)
class VehicleDiscountManagementPage extends StatefulWidget {
  const VehicleDiscountManagementPage({super.key});

  @override
  State<VehicleDiscountManagementPage> createState() =>
      _VehicleDiscountManagementPageState();
}

class _VehicleDiscountManagementPageState
    extends State<VehicleDiscountManagementPage> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoading = true);
      final vehicles = await SupabaseConfig.getAllVehicleTypes();

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Ride Discount Management',
          style: (isSmallMobile
                  ? theme.textTheme.titleMedium
                  : (isMobile
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleLarge))
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
        iconTheme: const IconThemeData(color: LottoRunnersColors.primaryYellow),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Container(
                color: theme.colorScheme.surface,
                padding: Responsive.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(theme, isSmallMobile),
                    SizedBox(
                        height: Responsive.getResponsiveSpacing(context) * 2),
                    _buildVehicleStats(theme),
                    SizedBox(
                        height: Responsive.getResponsiveSpacing(context) * 2),
                    _buildVehiclesGrid(theme, isDesktop),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: LottoRunnersColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LottoRunnersColors.primaryYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: LottoRunnersColors.primaryYellow,
            size: isSmallMobile ? 24 : 28,
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Ride Discounts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: isSmallMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isSmallMobile ? 4 : 6),
                Text(
                  'Set percentage discounts for transportation services (rides). This applies to all "Request a Ride" bookings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isSmallMobile ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStats(ThemeData theme) {
    final totalVehicles = _vehicles.length;
    final discountedVehicles = _vehicles
        .where((v) =>
            v['discount_percentage'] != null && v['discount_percentage'] > 0)
        .length;
    final noDiscountVehicles = totalVehicles - discountedVehicles;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total Rides', totalVehicles.toString(),
              Icons.directions_car, theme.colorScheme.primary),
          SizedBox(width: Responsive.getResponsiveSpacing(context)),
          _buildStatCard('With Discount', discountedVehicles.toString(),
              Icons.local_offer, Colors.orange),
          SizedBox(width: Responsive.getResponsiveSpacing(context)),
          _buildStatCard('No Discount', noDiscountVehicles.toString(),
              Icons.money_off, theme.colorScheme.outline),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: 160,
      padding: Responsive.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallMobile ? 24 : (isMobile ? 28 : 32),
          ),
          SizedBox(height: isSmallMobile ? 8 : 12),
          Text(
            value,
            style: (isSmallMobile
                    ? theme.textTheme.titleMedium
                    : (isMobile
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleLarge))
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isSmallMobile ? 11 : (isMobile ? 12 : 13),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesGrid(ThemeData theme, bool isDesktop) {
    if (_vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No vehicles available',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : (Responsive.isTablet(context) ? 2 : 1),
        childAspectRatio: isDesktop ? 1.5 : 2.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(theme, _vehicles[index]);
      },
    );
  }

  Widget _buildVehicleCard(ThemeData theme, Map<String, dynamic> vehicle) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final discountPercentage = vehicle['discount_percentage'] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: LottoRunnersColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['name'] ?? 'Unnamed Vehicle',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: isSmallMobile ? 14 : 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Capacity: ${vehicle['capacity'] ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Discount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: isSmallMobile ? 10 : 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: discountPercentage > 0
                              ? Colors.orange.withOpacity(0.1)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          discountPercentage > 0
                              ? '${discountPercentage.toStringAsFixed(0)}% OFF'
                              : 'No Discount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: discountPercentage > 0
                                ? Colors.orange
                                : theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallMobile ? 11 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEditDiscountDialog(vehicle),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 12 : 16,
                      vertical: isSmallMobile ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  void _showEditDiscountDialog(Map<String, dynamic> vehicle) {
    final theme = Theme.of(context);
    _discountController.text =
        vehicle['discount_percentage']?.toString() ?? '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Edit Discount',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle['name'] ?? 'Unnamed Vehicle',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: 'Discount Percentage (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.percent,
                  color: theme.colorScheme.primary,
                ),
                hintText: 'Enter discount (0-100)',
                helperText: 'Enter 0 to remove discount',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveDiscount(vehicle),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDiscount(Map<String, dynamic> vehicle) async {
    try {
      final discountPercentage =
          double.tryParse(_discountController.text) ?? 0.0;

      if (discountPercentage < 0 || discountPercentage > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount percentage must be between 0 and 100'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await SupabaseConfig.updateVehicleTypeDiscount(
        vehicle['id'],
        discountPercentage,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              discountPercentage > 0
                  ? 'Discount of ${discountPercentage.toStringAsFixed(0)}% applied!'
                  : 'Discount removed successfully!',
            ),
            backgroundColor: LottoRunnersColors.accent,
          ),
        );
        _loadVehicles();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update discount'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving discount: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

