import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile/Desktop implementation for PDF saving
Future<void> savePdfPlatform(List<int> pdfBytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(pdfBytes);
}

/// Merge multiple PDF files into a single PDF (mobile implementation)
Future<dynamic> mergePDFsPlatform(List<dynamic> pdfFiles) async {
  try {
    if (pdfFiles.isEmpty) return null;
    if (pdfFiles.length == 1) return pdfFiles.first;

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mergedPdfPath = path.join(tempDir.path, 'merged_$timestamp.pdf');

    // TODO: Implement actual PDF merging logic
    // For now, we'll just copy the first file as a placeholder
    // In a real implementation, you would use a PDF library to merge the files

    // Placeholder: copy first file
    final firstFile = pdfFiles.first as File;
    final mergedFile = await firstFile.copy(mergedPdfPath);

    return mergedFile;
  } catch (e) {
    print('Error merging PDFs: $e');
    return null;
  }
}

/// Download a PDF file to the device (mobile implementation)
Future<bool> downloadPDFPlatform(dynamic pdfFile, String fileName) async {
  try {
    // Request storage permission for Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try with manage external storage permission for Android 11+
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          print('Storage permission denied');
          // Continue with app documents directory as fallback
        }
      }
    }

    // Get downloads directory (Android) or documents directory (iOS)
    Directory? targetDir;

    if (Platform.isAndroid) {
      // For Android, try multiple download locations
      final possiblePaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads'
      ];

      for (final downloadPath in possiblePaths) {
        final dir = Directory(downloadPath);
        if (await dir.exists()) {
          targetDir = dir;
          break;
        }
      }

      // Fallback to app documents directory
      if (targetDir == null) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      // For iOS, use documents directory
      targetDir = await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use temporary directory
      targetDir = await getTemporaryDirectory();
    }

    final targetPath = path.join(targetDir.path, fileName);

    // Copy the file to the target location
    final file = pdfFile as File;
    await file.copy(targetPath);

    // Show a toast or notification about successful download
    print('PDF downloaded successfully to: $targetPath');

    return true;
  } catch (e) {
    print('Error downloading PDF: $e');
    return false;
  }
}

/// Download PDF bytes directly to device (enhanced mobile implementation)
/// Uses share_plus for reliable cross-platform file sharing/saving
Future<bool> downloadPDFBytesPlatform(List<int> pdfBytes, String fileName) async {
  try {
    // Get temporary directory to save the PDF file
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, fileName);
    final file = File(filePath);

    // Write PDF bytes to temporary file
    await file.writeAsBytes(pdfBytes);

    print('✅ PDF saved to temporary location: $filePath');

    // Use share_plus to share/save the file
    // This opens the system share dialog where users can:
    // - Save to Downloads (Android)
    // - Save to Files app (iOS)
    // - Share via other apps
    final xFile = XFile(filePath, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [xFile],
      subject: 'Invoice: $fileName',
      text: 'Invoice from Lotto Runners',
    );

    print('✅ PDF shared successfully via system share dialog');
    return true;
  } catch (e) {
    print('❌ Error downloading PDF bytes: $e');
    return false;
  }
}

/// Get file size in human readable format (mobile implementation)
String getFileSizePlatform(dynamic file) {
  try {
    final fileObj = file as File;
    final bytes = fileObj.lengthSync();
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

/// Validate if a file is a valid PDF (mobile implementation)
bool isValidPDFPlatform(dynamic file) {
  try {
    final fileObj = file as File;
    final bytes = fileObj.readAsBytesSync();
    // Check for PDF magic number
    if (bytes.length < 4) return false;

    // PDF files start with "%PDF"
    final header = String.fromCharCodes(bytes.take(4));
    return header == '%PDF';
  } catch (e) {
    return false;
  }
}
