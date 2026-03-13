import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Admin page showing all bookings in one place: errands (including shopping),
/// transportation, and bus. Shopping errands are shown with a very distinct style
/// and display the budget to send to the runner.
class AllBookingsPage extends StatefulWidget {
  const AllBookingsPage({super.key});

  @override
  State<AllBookingsPage> createState() => _AllBookingsPageState();
}

class _AllBookingsPageState extends State<AllBookingsPage> {
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, errand, transportation, bus, contract
  String _filterErrandCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadAllBookings();
  }

  Future<void> _loadAllBookings() async {
    setState(() => _isLoading = true);
    try {
      final errands = await SupabaseConfig.getAllErrands();
      final transportAndBus = await SupabaseConfig.getAllBookings();

      final items = <Map<String, dynamic>>[];

      for (final e in errands) {
        items.add({
          ...e,
          'booking_type': 'errand',
          'display_date': e['created_at'],
          'sort_date': DateTime.tryParse(e['created_at']?.toString() ?? ''),
        });
      }
      for (final b in transportAndBus) {
        items.add({
          ...b,
          'display_date': b['created_at'] ?? b['booking_date'],
          'sort_date': DateTime.tryParse(
              (b['created_at'] ?? b['booking_date'] ?? '')?.toString() ?? ''),
        });
      }

      items.sort((a, b) {
        final da = a['sort_date'] as DateTime? ?? DateTime(1970);
        final db = b['sort_date'] as DateTime? ?? DateTime(1970);
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var list = _allItems;
    if (_filterType != 'all') {
      list = list.where((i) => (i['booking_type'] ?? 'errand') == _filterType).toList();
    }
    if (_filterType == 'all' || _filterType == 'errand') {
      if (_filterErrandCategory == 'shopping') {
        list = list.where((i) => i['booking_type'] != 'errand' || i['category'] == 'shopping').toList();
      } else if (_filterErrandCategory == 'other') {
        list = list.where((i) => i['booking_type'] != 'errand' || i['category'] != 'shopping').toList();
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Bookings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
            fontSize: isSmallMobile ? 16 : 18,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        actions: [
          IconButton(
            onPressed: _loadAllBookings,
            icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(theme, isSmallMobile),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllBookings,
                        child: ListView.builder(
                          padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildBookingCard(item, theme, isSmallMobile);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type',
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('All', 'all', _filterType, (v) => setState(() => _filterType = v)),
              _chip('Errands', 'errand', _filterType, (v) => setState(() => _filterType = v)),
              _chip('Transport', 'transportation', _filterType, (v) => setState(() => _filterType = v)),
              _chip('Bus', 'bus', _filterType, (v) => setState(() => _filterType = v)),
              _chip('Contracts', 'contract', _filterType, (v) => setState(() => _filterType = v)),
            ],
          ),
          if (_filterType == 'all' || _filterType == 'errand') ...[
            const SizedBox(height: 12),
            Text('Errand category',
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('All', 'all', _filterErrandCategory,
                    (v) => setState(() => _filterErrandCategory = v)),
                _chip('Shopping', 'shopping', _filterErrandCategory,
                    (v) => setState(() => _filterErrandCategory = v)),
                _chip('Other', 'other', _filterErrandCategory,
                    (v) => setState(() => _filterErrandCategory = v)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String current, void Function(String) onTap) {
    final theme = Theme.of(context);
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: theme.colorScheme.onSurface)),
      selected: selected,
      onSelected: (_) => onTap(value),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> item, ThemeData theme, bool isSmallMobile) {
    final type = item['booking_type'] ?? 'errand';
    final isShopping =
        type == 'errand' && (item['category']?.toString() == 'shopping');
    final shoppingBudget = isShopping
        ? (item['pricing_modifiers'] is Map
            ? (item['pricing_modifiers'] as Map)['shopping_budget'] as num?
            : null)
        : null;
    final budgetAmount = shoppingBudget != null ? shoppingBudget.toDouble() : 0.0;

    if (type == 'errand') {
      return _buildErrandCard(item, theme, isSmallMobile,
          isShopping: isShopping, shoppingBudgetAmount: budgetAmount);
    }
    return _buildTransportOrBusCard(item, theme, isSmallMobile);
  }

  /// Shopping errands: very distinct card (amber/orange, shopping icon, prominent budget).
  Widget _buildErrandCard(
    Map<String, dynamic> errand,
    ThemeData theme,
    bool isSmallMobile, {
    required bool isShopping,
    required double shoppingBudgetAmount,
  }) {
    final status = errand['status'] ?? 'unknown';
    final statusColor = _statusColor(status);
    final isSmall = isSmallMobile;
    final shoppingBorder = theme.colorScheme.secondary;
    final shoppingBg = theme.colorScheme.secondaryContainer.withOpacity(0.5);
    final shoppingFg = theme.colorScheme.onSecondaryContainer;
    final shoppingIconBg = theme.colorScheme.secondary.withOpacity(0.25);

    return Card(
      margin: EdgeInsets.only(bottom: isSmall ? 10 : 14),
      elevation: isShopping ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isShopping
              ? shoppingBorder
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isShopping ? 2.5 : 1,
        ),
      ),
      color: isShopping ? shoppingBg : theme.cardColor,
      child: InkWell(
        onTap: () => _showErrandDetails(errand, isShopping, shoppingBudgetAmount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 8 : 10),
                    decoration: BoxDecoration(
                      color: isShopping
                          ? shoppingIconBg
                          : theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isShopping ? Icons.shopping_basket : Icons.assignment,
                      color: isShopping
                          ? shoppingFg
                          : theme.colorScheme.primary,
                      size: isSmall ? 22 : 26,
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isShopping)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'SHOPPING ORDER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: shoppingFg,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        Text(
                          errand['title'] ?? 'Errand',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmall ? 14 : 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          errand['description']?.toString().split('\n').first ?? 'No description',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: isSmall ? 12 : 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (isShopping && shoppingBudgetAmount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmall ? 10 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments,
                          color: shoppingFg, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Budget to send to runner for shopping: N\$${shoppingBudgetAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmall ? 13 : 14,
                            color: shoppingFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.attach_money,
                      size: 16, color: theme.colorScheme.tertiary),
                  Text(
                    'Total: N\$${errand['price_amount'] ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 12 : 13,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(errand['created_at']),
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (errand['runner'] != null)
                    Text(
                      'Runner: ${errand['runner']['full_name']}',
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportOrBusCard(
      Map<String, dynamic> booking, ThemeData theme, bool isSmallMobile) {
    final type = booking['booking_type'] ?? 'transportation';
    final isBus = type == 'bus';
    final isContract = type == 'contract';
    final title = isBus
        ? (booking['service']?['name'] ?? 'Bus Booking')
        : isContract
            ? (booking['title'] ?? 'Contract Booking')
            : (booking['booking_reference'] ?? 'Transport');
    final amount = (booking['final_price'] ?? booking['estimated_price'] ?? booking['total_price'] ?? 0).toDouble();
    final date = booking['created_at'] ?? booking['booking_date'];
    final status = booking['status'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 10 : 14),
      color: theme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBus
              ? theme.colorScheme.primaryContainer.withOpacity(0.6)
              : theme.colorScheme.secondaryContainer.withOpacity(0.6),
          child: Icon(
            isBus ? Icons.directions_bus : Icons.directions_car,
            color: isBus
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_formatDate(date)} • N\$${amount.toStringAsFixed(2)} • ${status.toUpperCase()}',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTransportBusDetails(booking),
      ),
    );
  }

  void _showErrandDetails(Map<String, dynamic> errand, bool isShopping, double shoppingBudget) {
    final theme = Theme.of(context);
    final shoppingFg = theme.colorScheme.onSecondaryContainer;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            if (isShopping)
              Icon(Icons.shopping_basket,
                  color: theme.colorScheme.secondary, size: 28),
            if (isShopping) const SizedBox(width: 8),
            Expanded(
                child: Text(errand['title'] ?? 'Errand Details',
                    style: TextStyle(color: theme.colorScheme.onSurface))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isShopping) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments,
                          color: shoppingFg, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget to send to runner for shopping',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: shoppingFg,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'N\$${shoppingBudget.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: shoppingFg,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _row('Description', errand['description'] ?? 'N/A'),
              _row('Category', errand['category']?.toString().toUpperCase() ?? 'N/A'),
              _row('Status', _formatStatus(errand['status'] ?? '')),
              _row('Total price', 'N\$${errand['price_amount'] ?? '0.00'}'),
              if (errand['delivery_address'] != null)
                _row('Delivery', errand['delivery_address']),
              if (errand['customer'] != null)
                _row('Customer',
                    '${errand['customer']['full_name']} (${errand['customer']['email']})'),
              if (errand['runner'] != null)
                _row('Runner',
                    '${errand['runner']['full_name']} (${errand['runner']['email']})'),
              _row('Created', _formatDate(errand['created_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showTransportBusDetails(Map<String, dynamic> booking) {
    final theme = Theme.of(context);
    final isBus = (booking['booking_type'] ?? '') == 'bus';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(isBus ? 'Bus Booking' : 'Transportation Booking',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Status', (booking['status'] ?? '').toString().toUpperCase()),
              _row('Amount',
                  'N\$${((booking['final_price'] ?? booking['estimated_price'] ?? 0) as num).toStringAsFixed(2)}'),
              _row('Date', _formatDate(booking['booking_date'] ?? booking['created_at'])),
              if (booking['user'] != null)
                _row('Customer', booking['user']['full_name'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(color: theme.colorScheme.onSurface))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'posted':
        return theme.colorScheme.primary;
      case 'accepted':
        return theme.colorScheme.secondary;
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'completed':
        return theme.colorScheme.tertiary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'posted':
        return 'Posted';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }
}
