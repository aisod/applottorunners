import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String title;
  final String description;
  final String? documentType;
  final String? currentDocumentUrl;
  final Function(String?) onDocumentUploaded;
  final bool isRequired;
  final List<String> allowedExtensions;
  final int? maxFileSizeMB;

  const DocumentUploadWidget({
    super.key,
    required this.title,
    required this.description,
    this.documentType,
    this.currentDocumentUrl,
    required this.onDocumentUploaded,
    this.isRequired = false,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    this.maxFileSizeMB = 10,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _isUploading = false;
  String? _uploadedDocumentUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uploadedDocumentUrl = widget.currentDocumentUrl;
  }

  Future<void> _uploadDocument() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size
        if (widget.maxFileSizeMB != null &&
            file.size > widget.maxFileSizeMB! * 1024 * 1024) {
          throw Exception(
              'File size must be less than ${widget.maxFileSizeMB}MB');
        }

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = file.extension ?? 'pdf';
        final filename =
            '${widget.documentType ?? 'document'}_$timestamp.$extension';

        // Upload to Supabase storage
        final bytes = file.bytes!;
        final url = await SupabaseConfig.uploadImage(
          'verification-docs',
          filename,
          bytes,
        );

        setState(() {
          _uploadedDocumentUrl = url;
          _isUploading = false;
        });

        widget.onDocumentUploaded(url);
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _removeDocument() async {
    if (_uploadedDocumentUrl != null) {
      try {
        // Extract filename from URL
        final filename = _uploadedDocumentUrl!.split('/').last;
        await SupabaseConfig.client.storage
            .from('verification-docs')
            .remove([filename]);

        setState(() {
          _uploadedDocumentUrl = null;
        });

        widget.onDocumentUploaded(null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing document: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildDocumentPreview() {
    if (_uploadedDocumentUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _uploadedDocumentUrl!.toLowerCase().contains('.pdf')
                ? Icons.picture_as_pdf
                : Icons.image,
            color: Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document uploaded successfully',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Tap to view or remove',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeDocument,
            icon: Icon(
              Icons.close,
              color: Colors.red[600],
              size: 16,
            ),
            tooltip: 'Remove document',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Upload button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: _uploadedDocumentUrl != null
                    ? Colors.green[300]!
                    : theme.colorScheme.outline,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isUploading ? null : _uploadDocument,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isUploading
                            ? Icons.upload_file
                            : Icons.cloud_upload_outlined,
                        color: _uploadedDocumentUrl != null
                            ? Colors.green[600]
                            : LottoRunnersColors.primaryYellow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isUploading
                                  ? 'Uploading...'
                                  : _uploadedDocumentUrl != null
                                      ? 'Document uploaded'
                                      : 'Tap to upload document',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _uploadedDocumentUrl != null
                                    ? Colors.green[700]
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (!_isUploading && _uploadedDocumentUrl == null)
                              Text(
                                'Supported formats: ${widget.allowedExtensions.join(', ').toUpperCase()} (max ${widget.maxFileSizeMB}MB)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              LottoRunnersColors.primaryYellow,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Document preview
          _buildDocumentPreview(),
        ],
      ),
    );
  }
}
