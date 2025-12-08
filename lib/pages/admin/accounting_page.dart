import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'provider_accounting_page.dart';
import 'bus_accounting_page.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
          ],
          indicatorColor: LottoRunnersColors.primaryYellow,
          labelColor: LottoRunnersColors.primaryYellow,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProviderAccountingPage(),
          BusAccountingPage(),
        ],
      ),
    );
  }
}

