import 'package:flutter/material.dart';
import 'package:lotto_runners/pages/my_errands_page.dart';
import 'package:lotto_runners/pages/my_transportation_requests_page.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/theme.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _errandsPageKey = GlobalKey();
  final GlobalKey _transportPageKey = GlobalKey();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to implement lazy loading
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      return;
    }

    // Only refresh the current tab when user switches tabs
    if (_tabController.indexIsChanging) {
      _refreshCurrentTab();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    // Trigger refresh by calling setState to rebuild the current tab
    setState(() {
      // This will cause the current tab to rebuild and refresh its data
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme not used here since AppBar uses fixed gradient colors
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isSmallMobile ? 18 : 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
        actions: [
          IconButton(
            onPressed: _refreshCurrentTab,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 16 : 24,
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: Colors.white,
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Errands tab - shows the current MyErrandsPage content
          MyErrandsPage(key: _errandsPageKey),
          // Transport tab - shows the current MyTransportationRequestsPage content
          MyTransportationRequestsPage(key: _transportPageKey),
        ],
      ),
    );
  }
}
