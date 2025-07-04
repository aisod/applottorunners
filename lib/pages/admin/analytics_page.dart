import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _recentErrands = [];
  List<Map<String, dynamic>> _topRunners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);

      // Load basic analytics
      final analyticsData = await SupabaseConfig.getAnalyticsData();

      // Load recent errands for trend analysis
      final errands = await SupabaseConfig.getAllErrands();
      final recentErrands = errands.take(10).toList();

      // Calculate top runners (mock data for now)
      final topRunners = await _calculateTopRunners(errands);

      setState(() {
        _analyticsData = analyticsData;
        _recentErrands = recentErrands;
        _topRunners = topRunners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _calculateTopRunners(
      List<Map<String, dynamic>> errands) async {
    final runnerStats = <String, Map<String, dynamic>>{};

    for (final errand in errands) {
      if (errand['runner_id'] != null && errand['status'] == 'completed') {
        final runnerId = errand['runner_id'];
        final runnerName = errand['runner']?['full_name'] ?? 'Unknown';
        final amount = (errand['price_amount'] as num?)?.toDouble() ?? 0.0;

        if (!runnerStats.containsKey(runnerId)) {
          runnerStats[runnerId] = {
            'id': runnerId,
            'name': runnerName,
            'completed_errands': 0,
            'total_earnings': 0.0,
          };
        }

        runnerStats[runnerId]!['completed_errands']++;
        runnerStats[runnerId]!['total_earnings'] += amount;
      }
    }

    final sortedRunners = runnerStats.values.toList();
    sortedRunners.sort(
        (a, b) => b['completed_errands'].compareTo(a['completed_errands']));

    return sortedRunners.take(5).toList();
  }

  Map<String, int> _getErrandsByCategory() {
    final categories = <String, int>{};

    for (final errand in _recentErrands) {
      final category = errand['category'] ?? 'other';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }

  Map<String, int> _getErrandsByStatus() {
    final statuses = <String, int>{};

    for (final errand in _recentErrands) {
      final status = errand['status'] ?? 'unknown';
      statuses[status] = (statuses[status] ?? 0) + 1;
    }

    return statuses;
  }

  double _getCompletionRate() {
    if (_recentErrands.isEmpty) return 0.0;

    final completed =
        _recentErrands.where((e) => e['status'] == 'completed').length;
    return (completed / _recentErrands.length) * 100;
  }

  double _getAverageErrandValue() {
    if (_recentErrands.isEmpty) return 0.0;

    final total = _recentErrands.fold(0.0, (sum, errand) {
      return sum + ((errand['price_amount'] as num?)?.toDouble() ?? 0.0);
    });

    return total / _recentErrands.length;
  }

  String _formatCurrency(double amount) {
    return 'N\$${amount.toStringAsFixed(2)}';
  }

  String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'grocery':
        return 'Grocery';
      case 'delivery':
        return 'Delivery';
      case 'document':
        return 'Document';
      case 'shopping':
        return 'Shopping';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'grocery':
        return Colors.green;
      case 'delivery':
        return Colors.blue;
      case 'document':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final errandsByCategory = _getErrandsByCategory();
    final errandsByStatus = _getErrandsByStatus();
    final completionRate = _getCompletionRate();
    final averageValue = _getAverageErrandValue();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Platform Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Key Metrics
              if (_analyticsData != null) ...[
                const Text(
                  'Key Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildMetricCard(
                      'Total Users',
                      _analyticsData!['total_users'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Total Errands',
                      _analyticsData!['total_errands'].toString(),
                      Icons.assignment,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'Completed',
                      _analyticsData!['completed_errands'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Revenue',
                      _formatCurrency(_analyticsData!['total_revenue']),
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Performance Metrics
              const Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Completion Rate',
                      _formatPercentage(completionRate),
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Avg. Errand Value',
                      _formatCurrency(averageValue),
                      Icons.bar_chart,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Errands by Category
              if (errandsByCategory.isNotEmpty) ...[
                const Text(
                  'Errands by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: errandsByCategory.entries.map((entry) {
                        final category = entry.key;
                        final count = entry.value;
                        final total =
                            errandsByCategory.values.fold(0, (a, b) => a + b);
                        final percentage = (count / total) * 100;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_formatCategoryName(category)),
                              ),
                              Text(
                                '$count (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Top Runners
              if (_topRunners.isNotEmpty) ...[
                const Text(
                  'Top Performers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: _topRunners.asMap().entries.map((entry) {
                      final index = entry.key;
                      final runner = entry.value;
                      final isLast = index == _topRunners.length - 1;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getRankColor(index).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: _getRankColor(index),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    runner['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${runner['completed_errands']} errands completed',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(runner['total_earnings']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: _recentErrands.take(5).map((errand) {
                    final isLast = errand == _recentErrands.take(5).last;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                      errand['category'] ?? 'other')
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(errand['category'] ?? 'other'),
                              size: 16,
                              color: _getCategoryColor(
                                  errand['category'] ?? 'other'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  errand['title'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatStatus(errand['status'] ?? 'unknown'),
                                  style: TextStyle(
                                    color: _getStatusColor(
                                        errand['status'] ?? 'unknown'),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(
                                (errand['price_amount'] as num?)?.toDouble() ??
                                    0.0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'grocery':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'document':
        return Icons.description;
      case 'shopping':
        return Icons.shopping_bag;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.assignment;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'posted':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
