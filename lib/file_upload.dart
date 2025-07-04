import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

/// Helper class for handling file uploads
class FileUploadHelper {
  static final _uuid = Uuid();

  /// Upload a file and return its path
  /// Returns null if the operation was cancelled or failed
  static Future<String?> uploadFile() async {
    try {
      // Create file picker instance
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        // Get the temporary directory
        final tempDir = await getTemporaryDirectory();

        // Generate unique filename
        final filename = '${_uuid.v4()}_${result.files.first.name}';
        final filePath = '${tempDir.path}/$filename';

        // Copy file to app's temporary directory
        final file = File(result.files.first.path!);
        await file.copy(filePath);

        return filePath;
      }
      return null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Example usage in a widget
  static Future<void> handleFileUpload(BuildContext context) async {
    final filePath = await uploadFile();
    if (filePath != null) {
      // Do something with the file
      print('File uploaded: $filePath');
    }
  }
}
