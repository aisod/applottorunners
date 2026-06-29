import 'dart:html' as html;
import 'package:lotto_runners/utils/app_log.dart';

/// Web implementation for PDF saving
Future<void> savePdfPlatform(List<int> pdfBytes, String fileName) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Merge multiple PDF files into a single PDF (web implementation)
/// Note: Web implementation is limited - just returns the first file
Future<dynamic> mergePDFsPlatform(List<dynamic> pdfFiles) async {
  try {
    if (pdfFiles.isEmpty) return null;
    if (pdfFiles.length == 1) return pdfFiles.first;

    // Web merge is limited to the first selected file until a merge library is added.
    return pdfFiles.first;
  } catch (e) {
    appLog('Error merging PDFs: $e');
    return null;
  }
}

/// Download a PDF file to the device (web implementation)
Future<bool> downloadPDFPlatform(dynamic pdfFile, String fileName) async {
  try {
    // Create a download link and trigger it
    final file = pdfFile as html.File;
    final url = html.Url.createObjectUrlFromBlob(file);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    return true;
  } catch (e) {
    appLog('Error downloading PDF: $e');
    return false;
  }
}

/// Get file size in human readable format (web implementation)
String getFileSizePlatform(dynamic file) {
  try {
    final fileObj = file as html.File;
    final bytes = fileObj.size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  } catch (e) {
    return 'Unknown size';
  }
}

/// Validate if a file is a valid PDF (web implementation)
bool isValidPDFPlatform(dynamic file) {
  try {
    final fileObj = file as html.File;
    // For web, we can check the file type
    return fileObj.type == 'application/pdf' ||
        fileObj.name.toLowerCase().endsWith('.pdf');
  } catch (e) {
    return false;
  }
}

/// Download PDF bytes directly to device (web implementation)
Future<bool> downloadPDFBytesPlatform(
    List<int> pdfBytes, String fileName) async {
  try {
    // For web, use the existing save functionality
    await savePdfPlatform(pdfBytes, fileName);
    return true;
  } catch (e) {
    appLog('Error downloading PDF bytes: $e');
    return false;
  }
}
