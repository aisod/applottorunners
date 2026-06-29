import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lotto_runners/utils/app_log.dart';

/// Helper class for handling image uploads.
/// Gallery and file picking use the system picker (no broad storage permission).
/// Camera permission is requested only when capturing a photo.
class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Pick an image from the gallery
  /// Returns the Uint8List of the selected image, or null if cancelled
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      appLog('Opening gallery...');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        appLog('Gallery image selected. Size: ${bytes.length} bytes');
        return bytes;
      }
      appLog('No gallery image selected');
      return null;
    } catch (e) {
      appLog('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Capture an image using the camera
  static Future<Uint8List?> captureImage() async {
    try {
      appLog('Opening camera...');

      if (!kIsWeb && !await _ensureCameraPermission()) {
        throw Exception('Camera permission is required to take photos');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        appLog('Camera photo captured. Size: ${bytes.length} bytes');
        return bytes;
      }
      appLog('Camera cancelled or returned no image');
      return null;
    } catch (e) {
      appLog('Camera error: $e');
      if (e.toString().contains('permission')) {
        throw Exception(
            'Camera permission denied. Please enable camera access in settings.');
      }
      throw Exception('Failed to access camera. Please try again.');
    }
  }

  /// Alternative camera capture method
  static Future<Uint8List?> captureImageAlternative() async {
    return captureImage();
  }

  /// Test if camera is available
  static Future<bool> isCameraAvailable() async {
    try {
      if (kIsWeb) return true;

      final status = await Permission.camera.status;
      return status.isGranted || status.isPermanentlyDenied == false;
    } catch (e) {
      appLog('Error checking camera availability: $e');
      return false;
    }
  }

  /// Pick a PDF file from device storage (system file picker; no storage permission)
  static Future<Uint8List?> pickPDFFromFiles() async {
    try {
      appLog('Opening file picker for PDF...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          appLog('PDF file selected. Size: ${file.bytes!.length} bytes');
          return file.bytes!;
        } else if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          appLog('PDF file selected. Size: ${bytes.length} bytes');
          return bytes;
        }
      }
      appLog('No PDF selected');
      return null;
    } catch (e) {
      appLog('Error picking PDF: $e');
      return null;
    }
  }
}
