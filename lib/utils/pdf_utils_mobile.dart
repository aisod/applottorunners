import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as path;

import 'package:share_plus/share_plus.dart';

import 'package:lotto_runners/utils/app_log.dart';



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



    final tempDir = await getTemporaryDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final mergedPdfPath = path.join(tempDir.path, 'merged_$timestamp.pdf');



    final firstFile = pdfFiles.first as File;

    final mergedFile = await firstFile.copy(mergedPdfPath);



    return mergedFile;

  } catch (e) {

    appLog('Error merging PDFs: $e');

    return null;

  }

}



/// Save a PDF via the system share sheet (no broad storage permission).

Future<bool> downloadPDFPlatform(dynamic pdfFile, String fileName) async {

  try {

    final file = pdfFile as File;

    final xFile = XFile(file.path, mimeType: 'application/pdf');

    await Share.shareXFiles(

      [xFile],

      subject: 'Invoice: $fileName',

      text: 'Invoice from Lotto Runners',

    );

    appLog('PDF shared via system dialog: ${file.path}');

    return true;

  } catch (e) {

    appLog('Error sharing PDF: $e');

    return false;

  }

}



/// Download PDF bytes via share sheet (no MANAGE_EXTERNAL_STORAGE).

Future<bool> downloadPDFBytesPlatform(

    List<int> pdfBytes, String fileName) async {

  try {

    final tempDir = await getTemporaryDirectory();

    final filePath = path.join(tempDir.path, fileName);

    final file = File(filePath);



    await file.writeAsBytes(pdfBytes);



    appLog('PDF saved to temporary location: $filePath');



    final xFile = XFile(filePath, mimeType: 'application/pdf');

    await Share.shareXFiles(

      [xFile],

      subject: 'Invoice: $fileName',

      text: 'Invoice from Lotto Runners',

    );



    appLog('PDF shared successfully via system share dialog');

    return true;

  } catch (e) {

    appLog('Error downloading PDF bytes: $e');

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

    if (bytes.length < 4) return false;



    final header = String.fromCharCodes(bytes.take(4));

    return header == '%PDF';

  } catch (e) {

    return false;

  }

}

