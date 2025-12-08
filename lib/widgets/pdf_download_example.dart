import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/pdf_utils.dart';
import '../image_upload.dart';

/// Example widget demonstrating mobile PDF download functionality
/// This widget shows how to use the enhanced PDF download features
class PdfDownloadExample extends StatefulWidget {
  const PdfDownloadExample({super.key});

  @override
  State<PdfDownloadExample> createState() => _PdfDownloadExampleState();
}

class _PdfDownloadExampleState extends State<PdfDownloadExample> {
  bool _isDownloading = false;
  String _downloadStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Download Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            if (_downloadStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _downloadStatus.contains('Error') 
                      ? Colors.red[100] 
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _downloadStatus.contains('Error') 
                        ? Colors.red 
                        : Colors.green,
                  ),
                ),
                child: Text(
                  _downloadStatus,
                  style: TextStyle(
                    color: _downloadStatus.contains('Error') 
                        ? Colors.red[800] 
                        : Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Download from existing PDF file
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Existing PDF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pick a PDF file from your device and download it to the downloads folder.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadExistingPDF,
                      icon: _isDownloading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isDownloading ? 'Downloading...' : 'Pick & Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate and download PDF
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate & Download PDF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate a PDF with sample data and download it to your device.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _generateAndDownloadPDF,
                      icon: _isDownloading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(_isDownloading ? 'Generating...' : 'Generate & Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Platform information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Platform: ${kIsWeb ? 'Web' : defaultTargetPlatform.name}'),
                    Text('PDF Downloads: ${kIsWeb ? 'Browser download' : 'Device storage'}'),
                    if (!kIsWeb)
                      const Text(
                        'Files will be saved to Downloads folder on Android or Documents folder on iOS.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Mobile: Files are saved to Downloads folder (Android) or Documents folder (iOS)\n'
                    '• Web: Files are downloaded through the browser\n'
                    '• Storage permissions are automatically requested on Android\n'
                    '• Multiple download locations are tried for maximum compatibility',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Download an existing PDF file from device
  Future<void> _downloadExistingPDF() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = '';
    });

    try {
      // Pick a PDF file from device
      final pdfBytes = await ImageUploadHelper.pickPDFFromFiles();
      
      if (pdfBytes == null) {
        setState(() {
          _downloadStatus = 'No PDF file selected';
          _isDownloading = false;
        });
        return;
      }

      // Generate a filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'downloaded_pdf_$timestamp.pdf';

      // Download the PDF
      final success = await PdfUtils.downloadPDFBytes(pdfBytes, fileName);

      setState(() {
        _downloadStatus = success 
            ? 'PDF downloaded successfully as $fileName'
            : 'Error: Failed to download PDF';
        _isDownloading = false;
      });

    } catch (e) {
      setState(() {
        _downloadStatus = 'Error: $e';
        _isDownloading = false;
      });
    }
  }

  /// Generate a PDF with sample data and download it
  Future<void> _generateAndDownloadPDF() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = '';
    });

    try {
      // Sample data to include in PDF
      final sampleData = {
        'title': 'Sample Document',
        'date': DateTime.now().toIso8601String(),
        'content': 'This is a sample PDF generated by the Lotto Runners app.',
        'features': ['PDF Generation', 'Mobile Download', 'Cross-platform Support'],
        'user': 'Demo User',
      };

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'generated_document_$timestamp.pdf';

      // Generate and download PDF
      final success = await PdfUtils.generateAndDownloadPDF(sampleData, fileName);

      setState(() {
        _downloadStatus = success 
            ? 'PDF generated and downloaded successfully as $fileName'
            : 'Error: Failed to generate and download PDF';
        _isDownloading = false;
      });

    } catch (e) {
      setState(() {
        _downloadStatus = 'Error: $e';
        _isDownloading = false;
      });
    }
  }
}

