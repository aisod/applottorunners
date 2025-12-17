import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/theme.dart';

/// Admin page to view and manage user feedback
class FeedbackManagementPage extends StatefulWidget {
  const FeedbackManagementPage({super.key});

  @override
  State<FeedbackManagementPage> createState() => _FeedbackManagementPageState();
}

class _FeedbackManagementPageState extends State<FeedbackManagementPage> {
  List<Map<String, dynamic>> _feedbackList = [];
  List<Map<String, dynamic>> _filteredFeedback = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';
  String _selectedTypeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // Fetch all feedback with user information
      final response = await SupabaseConfig.client
          .from('feedback')
          .select('''
            *,
            users!feedback_user_id_fkey (
              id,
              full_name,
              email,
              user_type
            )
          ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _feedbackList = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        _filterFeedback();
      }
    } catch (e) {
      print('❌ Error loading feedback: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading feedback: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _filterFeedback() {
    if (!mounted) return;

    setState(() {
      _filteredFeedback = _feedbackList.where((feedback) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            (feedback['subject']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (feedback['message']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (feedback['users']?['full_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (feedback['users']?['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Status filter
        final matchesStatus = _selectedStatusFilter == 'all' || 
            feedback['status'] == _selectedStatusFilter;

        // Type filter
        final matchesType = _selectedTypeFilter == 'all' || 
            feedback['feedback_type'] == _selectedTypeFilter;

        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });
  }

  Future<void> _updateFeedbackStatus(String feedbackId, String newStatus) async {
    try {
      await SupabaseConfig.client
          .from('feedback')
          .update({'status': newStatus})
          .eq('id', feedbackId);

      if (mounted) {
        _loadFeedback();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Feedback status updated to ${newStatus.replaceAll('_', ' ')}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _respondToFeedback(String feedbackId) async {
    final responseController = TextEditingController();
    final statusController = TextEditingController(text: 'in_review');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Feedback'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Response:'),
              const SizedBox(height: 8),
              TextField(
                controller: responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter your response...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Update Status:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: statusController.text,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New')),
                  DropdownMenuItem(value: 'in_review', child: Text('In Review')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    statusController.text = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'response': responseController.text,
                'status': statusController.text,
              });
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final userId = SupabaseConfig.currentUser?.id;
        await SupabaseConfig.client
            .from('feedback')
            .update({
              'admin_response': result['response'],
              'status': result['status'],
              'responded_at': DateTime.now().toIso8601String(),
              'responded_by': userId,
            })
            .eq('id', feedbackId);

        if (mounted) {
          _loadFeedback();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Response submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting response: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    final user = feedback['users'] as Map<String, dynamic>?;
    final userName = user?['full_name'] ?? 'Unknown User';
    final userEmail = user?['email'] ?? 'N/A';
    final userType = feedback['user_type'] ?? 'customer';
    final feedbackType = feedback['feedback_type'] ?? 'general_feedback';
    final rating = feedback['rating'];
    final status = feedback['status'] ?? 'new';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', userName),
              _buildDetailRow('Email', userEmail),
              _buildDetailRow('User Type', userType.toUpperCase()),
              _buildDetailRow('Feedback Type', _formatFeedbackType(feedbackType)),
              _buildDetailRow('Status', _formatStatus(status)),
              if (rating != null) _buildDetailRow('Rating', '⭐ ' * rating),
              const SizedBox(height: 16),
              const Text(
                'Subject:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(feedback['subject'] ?? 'N/A'),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(feedback['message'] ?? 'N/A'),
              if (feedback['admin_response'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Admin Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LottoRunnersColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(feedback['admin_response']),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Submitted: ${_formatDate(feedback['created_at'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (feedback['admin_response'] == null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _respondToFeedback(feedback['id']);
              },
              child: const Text('Respond'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFeedbackType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'in_review':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getFeedbackTypeIcon(String type) {
    switch (type) {
      case 'bug_report':
        return Icons.bug_report;
      case 'feature_request':
        return Icons.lightbulb;
      case 'complaint':
        return Icons.report_problem;
      case 'compliment':
        return Icons.favorite;
      default:
        return Icons.feedback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = Responsive.isSmallMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Management'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search feedback...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              _filterFeedback();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterFeedback();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'new', child: Text('New')),
                          DropdownMenuItem(value: 'in_review', child: Text('In Review')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatusFilter = value;
                            });
                            _filterFeedback();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTypeFilter,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'general_feedback', child: Text('General')),
                          DropdownMenuItem(value: 'bug_report', child: Text('Bug Report')),
                          DropdownMenuItem(value: 'feature_request', child: Text('Feature')),
                          DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                          DropdownMenuItem(value: 'compliment', child: Text('Compliment')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTypeFilter = value;
                            });
                            _filterFeedback();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Feedback List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFeedback.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No feedback found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                        itemCount: _filteredFeedback.length,
                        itemBuilder: (context, index) {
                          final feedback = _filteredFeedback[index];
                          final user = feedback['users'] as Map<String, dynamic>?;
                          final userName = user?['full_name'] ?? 'Unknown User';
                          final status = feedback['status'] ?? 'new';
                          final feedbackType = feedback['feedback_type'] ?? 'general_feedback';
                          final rating = feedback['rating'];
                          final hasResponse = feedback['admin_response'] != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showFeedbackDetails(feedback),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status)
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _getFeedbackTypeIcon(feedbackType),
                                            color: _getStatusColor(status),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                feedback['subject'] ?? 'No Subject',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'By: $userName',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _formatStatus(status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      feedback['message'] ?? '',
                                      style: theme.textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (rating != null) ...[
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 16,
                                                color: LottoRunnersColors.primaryYellow,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating.toString(),
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                        ],
                                        Text(
                                          _formatFeedbackType(feedbackType),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (hasResponse)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 14,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Responded',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Text(
                                          _formatDate(feedback['created_at']),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

