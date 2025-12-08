import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/pages/runner_messages_page.dart';
import 'package:lotto_runners/pages/runner_wallet_page.dart';
import 'package:lotto_runners/utils/page_transitions.dart';

class RunnerHomePage extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const RunnerHomePage({super.key, this.onNavigateToTab});

  @override
  State<RunnerHomePage> createState() => _RunnerHomePageState();
}

class _RunnerHomePageState extends State<RunnerHomePage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  int _unreadMessagesCount = 0;
  Map<String, dynamic> _stats = {
    'total_errands': 0,
    'completed_errands': 0,
    'total_earnings': 0.0,
    'active_jobs': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = SupabaseConfig.currentUser?.id;
      if (userId != null) {
        final profile = await SupabaseConfig.getUserProfile(userId);
        final errands = await SupabaseConfig.getRunnerErrands(userId);
        final bookings = await SupabaseConfig.getRunnerAllBookings(userId);
        final unreadCount = await SupabaseConfig.getUnreadAdminMessagesCount();
        
        // Calculate stats
        final completedErrands = errands.where((e) => e['status'] == 'completed').length;
        final activeJobs = errands.where((e) => 
          e['status'] == 'accepted' || e['status'] == 'in_progress'
        ).length + bookings.where((b) => 
          b['status'] == 'accepted' || b['status'] == 'in_progress'
        ).length;
        
        final totalEarnings = errands
          .where((e) => e['status'] == 'completed')
          .fold<double>(0.0, (sum, e) => sum + ((e['price_amount'] as num?)?.toDouble() ?? 0.0));
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _unreadMessagesCount = unreadCount;
            _stats = {
              'total_errands': errands.length,
              'completed_errands': completedErrands,
              'total_earnings': totalEarnings,
              'active_jobs': activeJobs,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading runner home data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _userProfile?['full_name'] ?? 'Runner';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Greeting and Messages Icon
            _buildHeroSection(userName, isSmallMobile, isMobile, isDesktop),
            
            // Stats Section
            Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : double.infinity,
              ),
              padding: EdgeInsets.all(isSmallMobile ? 16 : (isDesktop ? 40 : 24)),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  _buildQuickActions(isSmallMobile, isMobile, theme),
                  SizedBox(height: isSmallMobile ? 24 : 32),
                  _buildAnalytics(isSmallMobile, isMobile, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(String userName, bool isSmallMobile, bool isMobile, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1200 : double.infinity,
        ),
        padding: EdgeInsets.all(isSmallMobile ? 16 : (isDesktop ? 40 : 24)),
        child: Column(
          children: [
            // Main card container
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 20 : (isDesktop ? 32 : 24)),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).colorScheme.surfaceContainerHighest 
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with messages icon and greeting
                  Row(
                    children: [
                      // Avatar and greeting
                      Container(
                        width: isSmallMobile ? 50 : (isDesktop ? 60 : 55),
                        height: isSmallMobile ? 50 : (isDesktop ? 60 : 55),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _userProfile?['avatar_url'] != null
                              ? Image.network(
                                  _userProfile!['avatar_url'],
                                  width: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
                                  height: isSmallMobile ? 48 : (isDesktop ? 58 : 53),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(isSmallMobile, isDesktop),
                                )
                              : _buildDefaultAvatar(isSmallMobile, isDesktop),
                        ),
                      ),
                      SizedBox(width: isSmallMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  LottoRunnersColors.primaryBlue,
                                  LottoRunnersColors.primaryYellow,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: Text(
                                'Hello $userName!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallMobile ? 20 : (isDesktop ? 28 : 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallMobile ? 4 : 6),
                            Text(
                              'Ready to help others and earn money running errands?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: isSmallMobile ? 12 : (isDesktop ? 16 : 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Messages Icon Button (Top Right)
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RunnerMessagesPage(),
                                ),
                              ).then((_) => _loadData()); // Refresh on return
                            },
                            icon: Icon(
                              Icons.mail_outline,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 28,
                            ),
                            tooltip: 'Messages from Admin',
                          ),
                          if (_unreadMessagesCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unreadMessagesCount > 9 ? '9+' : _unreadMessagesCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isSmallMobile, bool isDesktop) {
    return Icon(
      Icons.person,
      size: isSmallMobile ? 30 : (isDesktop ? 40 : 35),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

Widget _buildQuickActions(bool isSmallMobile, bool isMobile, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'My Wallet',
            Icons.account_balance_wallet,
            LottoRunnersColors.primaryYellow,
            () {
              Navigator.push(
                context,
                PageTransitions.slideAndFade(const RunnerWalletPage()),
              );
            },
            isSmallMobile,
            theme,
          ),
        ),
        SizedBox(width: isSmallMobile ? 10 : 12),
        Expanded(
          child: _buildActionCard(
            'Browse Errands',
            Icons.search,
            LottoRunnersColors.primaryBlue,
            () {
              // Navigate to Available Errands (index 1)
              widget.onNavigateToTab?.call(1);
            },
            isSmallMobile,
            theme,
          ),
        ),
        SizedBox(width: isSmallMobile ? 10 : 12),
        Expanded(
          child: _buildActionCard(
            'My Orders',
            Icons.assignment,
            LottoRunnersColors.primaryBlue,
            () {
              // Navigate to My Orders (index 2)
              widget.onNavigateToTab?.call(2);
            },
            isSmallMobile,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isSmallMobile,
    ThemeData theme, {
    bool isHorizontal = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(isSmallMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).colorScheme.surface 
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: isSmallMobile ? 22 : 26,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: isSmallMobile ? 22 : 26,
                  ),
                  SizedBox(height: isSmallMobile ? 4 : 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnalytics(bool isSmallMobile, bool isMobile, ThemeData theme) {
    final completedErrands = _stats['completed_errands'] as int;
    final totalErrands = _stats['total_errands'] as int;
    final successRate = totalErrands > 0 
        ? ((completedErrands / totalErrands) * 100).toStringAsFixed(1) 
        : '0.0';
    
    final avgEarnings = completedErrands > 0
        ? ((_stats['total_earnings'] as double) / completedErrands).toStringAsFixed(2)
        : '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isSmallMobile ? 10 : 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: isSmallMobile ? 8 : 12,
          mainAxisSpacing: isSmallMobile ? 8 : 12,
          childAspectRatio: isSmallMobile ? 1.15 : (isMobile ? 1.25 : 1.4),
          children: [
            _buildAnalyticsCard(
              'Success Rate',
              '$successRate%',
              Icons.trending_up,
              Colors.green,
              theme,
              isSmallMobile,
            ),
            _buildAnalyticsCard(
              'Avg Earnings',
              'N\$$avgEarnings',
              Icons.attach_money,
              LottoRunnersColors.primaryYellow,
              theme,
              isSmallMobile,
            ),
            _buildAnalyticsCard(
              'Active Jobs',
              _stats['active_jobs'].toString(),
              Icons.work,
              LottoRunnersColors.primaryBlue,
              theme,
              isSmallMobile,
            ),
            _buildAnalyticsCard(
              'Total Earned',
              'N\$${(_stats['total_earnings'] as double).toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              LottoRunnersColors.accent,
              theme,
              isSmallMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isSmallMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).colorScheme.surface 
            : Colors.white,
        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
          border: Border.all(
            color: LottoRunnersColors.primaryBlue.withOpacity(0.5),
            width: 2,
          ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallMobile ? 20 : 26,
          ),
          SizedBox(height: isSmallMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallMobile ? 2 : 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallMobile ? 9 : 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

