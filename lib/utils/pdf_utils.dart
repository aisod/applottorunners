import 'package:flutter/foundation.dart' show kIsWeb;
import 'pdf_utils_web.dart' if (dart.library.io) 'pdf_utils_mobile.dart' as platform;
import 'package:lotto_runners/utils/app_log.dart';

/// PDF helpers: merge, download, and minimal receipt-style PDF output.
class PdfUtils {
  /// Merge multiple PDF files into a single PDF (uses first file when merge is not supported).
  static Future<dynamic> mergePDFs(List<dynamic> pdfFiles) async {
    try {
      if (pdfFiles.isEmpty) return null;
      if (pdfFiles.length == 1) return pdfFiles.first;

      // Delegate to platform-specific implementation
      return await platform.mergePDFsPlatform(pdfFiles);
    } catch (e) {
      appLog('Error merging PDFs: $e');
      return null;
    }
  }

  /// Download a PDF file to the device
  static Future<bool> downloadPDF(dynamic pdfFile, String fileName) async {
    try {
      // Delegate to platform-specific implementation
      return await platform.downloadPDFPlatform(pdfFile, fileName);
    } catch (e) {
      appLog('Error downloading PDF: $e');
      return false;
    }
  }

  /// Get file size in human readable format
  static String getFileSize(dynamic file) {
    try {
      // Delegate to platform-specific implementation
      return platform.getFileSizePlatform(file);
    } catch (e) {
      return 'Unknown size';
    }
  }

  /// Validate if a file is a valid PDF
  static bool isValidPDF(dynamic file) {
    try {
      // Delegate to platform-specific implementation
      return platform.isValidPDFPlatform(file);
    } catch (e) {
      return false;
    }
  }

  /// Generate a unique filename for merged PDF
  static String generateMergedFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'merged_documents_$timestamp.pdf';
  }

  /// Save PDF bytes to file (web and mobile compatible)
  static Future<void> savePdf(List<int> pdfBytes, String fileName) async {
    await platform.savePdfPlatform(pdfBytes, fileName);
  }

  /// Download PDF bytes directly to device (enhanced mobile functionality)
  static Future<bool> downloadPDFBytes(List<int> pdfBytes, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, use the existing save functionality
        await savePdf(pdfBytes, fileName);
        return true;
      } else {
        // For mobile, use the enhanced download functionality
        return await platform.downloadPDFBytesPlatform(pdfBytes, fileName);
      }
    } catch (e) {
      appLog('Error downloading PDF bytes: $e');
      return false;
    }
  }

  /// Generate PDF from data and download it
  static Future<bool> generateAndDownloadPDF(Map<String, dynamic> data, String fileName) async {
    try {
      final pdfBytes = _generateSimplePDF(data);
      return await downloadPDFBytes(pdfBytes, fileName);
    } catch (e) {
      appLog('Error generating and downloading PDF: $e');
      return false;
    }
  }

  /// Minimal PDF bytes for a simple text summary (suitable for lightweight receipts).
  static List<int> _generateSimplePDF(Map<String, dynamic> data) {
    // Minimal PDF structure; extend with the `pdf` package for richer layouts if needed.
    final pdfContent = '''
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
72 720 Td
(${data.toString()}) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000204 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
297
%%EOF
''';
    
    return pdfContent.codeUnits;
  }
}
