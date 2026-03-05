import 'package:flutter/material.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'provider_accounting_page.dart';
import 'bus_accounting_page.dart';
import 'withdrawal_requests_page.dart';

/// Accounting Page with tabs for Provider Accounting and Bus Bookings
class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accounting',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 22),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: isSmallMobile ? null : 'Provider Accounting',
              height: isSmallMobile ? 48 : 56,
            ),
            Tab(
              icon: const Icon(Icons.directions_bus),
              text: isSmallMobile ? null : 'Bus Bookings',
              height: isSmallMobile ? 48 : 56,
            ),
            Tab(
              icon: const Icon(Icons.wallet_outlined),
              text: isSmallMobile ? null : 'Withdrawal Requests',
              height: isSmallMobile ? 48 : 56,
            ),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProviderAccountingPage(),
          BusAccountingPage(),
          WithdrawalRequestsPage(),
        ],
      ),
    );
  }
}

