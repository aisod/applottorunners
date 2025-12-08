import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:lotto_runners/utils/responsive.dart';

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
      // Use the enhanced view with document information
      final response = await SupabaseConfig.client
          .from('runner_verification_view')
          .select('*')
          .eq('verification_status', 'pending')
          .order('applied_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load applications. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
          SnackBar(
            content: Text('Unable to update application. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> application) {
    final theme = Theme.of(context);
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
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary),
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
              // Document Status Section
              const SizedBox(height: 12),
              const Text(
                'Document Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Code of Conduct
              _buildDocumentStatusRow(
                'Code of Conduct',
                application['code_of_conduct_pdf'] != null &&
                    application['code_of_conduct_pdf'].toString().isNotEmpty,
                application['code_of_conduct_pdf'],
              ),

              // Driver License (if has vehicle)
              if (application['has_vehicle'] == true) ...[
                _buildDocumentStatusRow(
                  'Driver License',
                  application['driver_license_pdf'] != null &&
                      application['driver_license_pdf'].toString().isNotEmpty,
                  application['driver_license_pdf'],
                ),

                // Vehicle Photos
                _buildDocumentStatusRow(
                  'Vehicle Photos',
                  application['vehicle_photos'] != null &&
                      (application['vehicle_photos'] as List).isNotEmpty,
                  application['vehicle_photos'] != null
                      ? (application['vehicle_photos'] as List).first
                      : null,
                  isMultiple: true,
                  count: application['vehicle_photos'] != null
                      ? (application['vehicle_photos'] as List).length
                      : 0,
                  allUrls: application['vehicle_photos'] != null
                      ? List<String>.from(application['vehicle_photos'])
                      : null,
                ),

                // License Disc Photos
                _buildDocumentStatusRow(
                  'License Disc Photos',
                  application['license_disc_photos'] != null &&
                      (application['license_disc_photos'] as List).isNotEmpty,
                  application['license_disc_photos'] != null
                      ? (application['license_disc_photos'] as List).first
                      : null,
                  isMultiple: true,
                  count: application['license_disc_photos'] != null
                      ? (application['license_disc_photos'] as List).length
                      : 0,
                  allUrls: application['license_disc_photos'] != null
                      ? List<String>.from(application['license_disc_photos'])
                      : null,
                ),
              ],

              // Legacy verification documents (if any)
              if (application['verification_documents'] != null &&
                  (application['verification_documents'] as List)
                      .isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Legacy Documents:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
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
                                onPressed: () => _downloadDocument(
                                    doc.toString(), 'Legacy Document'),
                                child: const Text('Download'),
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

  Widget _buildDocumentStatusRow(
      String documentType, bool isUploaded, String? documentUrl,
      {bool isMultiple = false, int count = 0, List<String>? allUrls}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isUploaded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              documentType,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (isMultiple && count > 0)
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.outline[600],
              ),
            ),
          if (isUploaded && documentUrl != null) ...[
            const SizedBox(width: 8),
            if (isMultiple && allUrls != null && allUrls.length > 1) ...[
              // Show dropdown for multiple documents
              PopupMenuButton<String>(
                onSelected: (url) => _downloadDocument(url, documentType),
                itemBuilder: (context) => allUrls.map((url) {
                  final index = allUrls.indexOf(url) + 1;
                  return PopupMenuItem<String>(
                    value: url,
                    child: Text('Download Photo $index'),
                  );
                }).toList(),
                child: const Text(
                  'Download All',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ] else ...[
              // Single document download
              TextButton(
                onPressed: () => _downloadDocument(documentUrl, documentType),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
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

  Future<void> _downloadDocument(
      String documentUrl, String documentType) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get the file name from URL or create one
      final fileName = documentUrl.split('/').last;
      final extension =
          fileName.contains('.') ? fileName.split('.').last : 'pdf';
      final finalFileName =
          '${documentType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Download the file
      final response = await http.get(Uri.parse(documentUrl));

      if (response.statusCode == 200) {
        // Close loading dialog
        Navigator.pop(context);

        // Try to download to downloads directory first
        try {
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            final file = File('${directory.path}/$finalFileName');
            await file.writeAsBytes(response.bodyBytes);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document downloaded to ${file.path}'),
                backgroundColor: Colors.green,
              ),
            );

            // Try to open the file
            if (await canLaunchUrl(Uri.file(file.path))) {
              await launchUrl(Uri.file(file.path));
            }
            return;
          }
        } catch (e) {
          print('Downloads directory not available: $e');
        }

        // Fallback: Try to open the document URL directly
        try {
          if (await canLaunchUrl(Uri.parse(documentUrl))) {
            await launchUrl(Uri.parse(documentUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document opened in browser'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not open document. Please copy the URL manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to download document: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Runner Verification Queue',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_applications.length} pending application${_applications.length != 1 ? 's' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(
                              'No pending applications',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All runner applications have been processed',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                  backgroundColor:
                      theme.colorScheme.outline[200], // Placeholder for theme-aware color
                  child: Icon(
                    hasVehicle ? Icons.directions_car : Icons.directions_walk,
                    color:
                        theme.colorScheme.outline[600], // Placeholder for theme-aware color
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
                          color: theme.colorScheme.outline[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user['phone'] != null)
                        Text(
                          user['phone'],
                          style: TextStyle(
                            color: theme.colorScheme.outline[600],
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
                    color:
                        Colors.orange[100], // Placeholder for theme-aware color
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
                  color: theme.colorScheme.outline[600],
                ),
                const SizedBox(width: 4),
                Text(
                  hasVehicle ? 'With Vehicle' : 'On Foot',
                  style: TextStyle(
                    color: theme.colorScheme.outline[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.description, size: 16, color: theme.colorScheme.outline[600]),
                const SizedBox(width: 4),
                Text(
                  '$documentsCount document${documentsCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: theme.colorScheme.outline[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Applied ${_calculateWaitingTime(application['applied_at'])}',
                  style: TextStyle(
                    color: theme.colorScheme.outline[500],
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
                  color: Colors.blue[50], // Placeholder for theme-aware color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors
                          .blue[100]!), // Placeholder for theme-aware color
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue[700]!),
                    const SizedBox(width: 8),
                    Text(
                      'Vehicle: ${application['vehicle_type']}',
                      style: TextStyle(
                        color: Colors.blue[700]!,
                        fontSize: 12,
                      ),
                    ),
                    if (application['license_number'] != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'License: ${application['license_number']}',
                        style: TextStyle(
                          color: Colors.blue[700]!,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons - Responsive Layout
            Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blue, width: 1), // Debug border
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildResponsiveActionButtons(application),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveActionButtons(Map<String, dynamic> application) {
    final screenWidth = Responsive.screenWidth(context);
    final isMobile = screenWidth < 768;

    // Debug: Print screen size info
    print('Screen width: $screenWidth');
    print('Is Mobile: $isMobile');

    if (isMobile) {
      // On mobile devices, stack buttons vertically
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showApplicationDetails(application),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showRejectionDialog(application),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApprovalDialog(application),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // On desktop/tablet, use horizontal layout with better spacing
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showApplicationDetails(application),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showRejectionDialog(application),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showApprovalDialog(application),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
