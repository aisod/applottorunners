import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

// Define primary color constant
const Color primaryColor = Color(0xFF2E7D32);

class RunnerVerificationPage extends StatefulWidget {
  const RunnerVerificationPage({super.key});

  @override
  State<RunnerVerificationPage> createState() => _RunnerVerificationPageState();
}

class _RunnerVerificationPageState extends State<RunnerVerificationPage> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() => _isLoading = true);
      final applications = await SupabaseConfig.getPendingRunnerApplications();
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(
      String applicationId, String status, String? notes) async {
    try {
      await SupabaseConfig.updateRunnerApplicationStatus(
          applicationId, status, notes);
      _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Application ${status.toLowerCase()} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating application: $e')),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> application) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Approve runner application for ${application['user']['full_name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Approval Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateApplicationStatus(
                  application['id'], 'approved', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> application) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Reject runner application for ${application['user']['full_name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason*',
                border: OutlineInputBorder(),
                helperText: 'Please provide a reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context);
              _updateApplicationStatus(
                  application['id'], 'rejected', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Application Details - ${application['user']['full_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Applicant', application['user']['full_name'] ?? 'N/A'),
              _buildDetailRow('Email', application['user']['email'] ?? 'N/A'),
              _buildDetailRow('Phone', application['user']['phone'] ?? 'N/A'),
              _buildDetailRow(
                  'Has Vehicle', application['has_vehicle'] ? 'Yes' : 'No'),
              if (application['has_vehicle']) ...[
                _buildDetailRow(
                    'Vehicle Type', application['vehicle_type'] ?? 'N/A'),
                _buildDetailRow(
                    'Vehicle Details', application['vehicle_details'] ?? 'N/A'),
                _buildDetailRow(
                    'License Number', application['license_number'] ?? 'N/A'),
              ],
              _buildDetailRow(
                  'Applied', _formatDate(application['applied_at'])),
              if (application['verification_documents'] != null &&
                  (application['verification_documents'] as List)
                      .isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Verification Documents:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(application['verification_documents'] as List)
                    .map((doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.description, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // In a real app, this would open the document viewer
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Document viewer would open here')),
                                  );
                                },
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRejectionDialog(application);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showApprovalDialog(application);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculateWaitingTime(String? appliedAt) {
    if (appliedAt == null) return 'N/A';
    try {
      final appliedDate = DateTime.parse(appliedAt);
      final now = DateTime.now();
      final difference = now.difference(appliedDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Runner Verification Queue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_applications.length} pending application${_applications.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadApplications,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No pending applications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All runner applications have been processed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _applications.length,
                          itemBuilder: (context, index) {
                            final application = _applications[index];
                            return _buildApplicationCard(application);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final user = application['user'];
    final hasVehicle = application['has_vehicle'] ?? false;
    final documentsCount =
        (application['verification_documents'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(
                    hasVehicle ? Icons.directions_car : Icons.directions_walk,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user['phone'] != null)
                        Text(
                          user['phone'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Application Details
            Row(
              children: [
                Icon(
                  hasVehicle ? Icons.directions_car : Icons.directions_walk,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  hasVehicle ? 'With Vehicle' : 'On Foot',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$documentsCount document${documentsCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Applied ${_calculateWaitingTime(application['applied_at'])}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            if (hasVehicle && application['vehicle_type'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Vehicle: ${application['vehicle_type']}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                    if (application['license_number'] != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'License: ${application['license_number']}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showApplicationDetails(application),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showRejectionDialog(application),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showApprovalDialog(application),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
