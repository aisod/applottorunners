import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

/// Helper class for handling image uploads
class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  /// Returns the Uint8List of the selected image, or null if cancelled
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      print('📷 Opening gallery...');

      // Check storage permission for gallery access on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            print('Storage permission denied');
            return null;
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce size
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        print('✅ Gallery image selected! Size: ${bytes.length} bytes');
        return bytes;
      } else {
        print('❌ No gallery image selected');
        return null;
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      return null;
    }
  }

  /// Capture an image using the camera - FORCES camera to open
  /// Returns the Uint8List of the captured image, or null if cancelled
  static Future<Uint8List?> captureImage() async {
    try {
      print('📷 FORCING CAMERA TO OPEN...');
      print('📷 Using ImageSource.camera explicitly');

      // Check camera permission FIRST
      if (!kIsWeb) {
        print('📷 Checking camera permission...');
        final status = await Permission.camera.status;
        print('📷 Camera permission status: $status');

        if (!status.isGranted) {
          print('📷 Requesting camera permission...');
          final result = await Permission.camera.request();
          print('📷 Permission request result: $result');

          if (!result.isGranted) {
            print('❌ Camera permission DENIED');
            throw Exception('Camera permission is required to take photos');
          }
        }
        print('✅ Camera permission GRANTED');
      }

      print('📷 Calling _picker.pickImage with ImageSource.camera...');

      // FORCE camera with explicit parameters
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, // This MUST open camera, not gallery
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      print('📷 _picker.pickImage returned: ${image?.path ?? 'null'}');

      if (image != null) {
        final bytes = await image.readAsBytes();
        print('✅ CAMERA PHOTO CAPTURED! Size: ${bytes.length} bytes');
        print('✅ Image path: ${image.path}');
        return bytes;
      } else {
        print('❌ Camera returned null - user cancelled or error');
        return null;
      }
    } catch (e) {
      print('❌ CAMERA ERROR: $e');
      print('❌ Error type: ${e.runtimeType}');

      if (e.toString().contains('permission')) {
        throw Exception(
            'Camera permission denied. Please enable camera access in settings.');
      }
      throw Exception('Failed to access camera. Please try again.');
    }
  }

  /// Alternative camera capture method that ONLY shows camera
  static Future<Uint8List?> captureImageAlternative() async {
    try {
      print('📷 ALTERNATIVE CAMERA METHOD...');

      // Force camera permission first
      if (!kIsWeb) {
        final status = await Permission.camera.status;
        if (!status.isGranted) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            throw Exception('Camera permission required');
          }
        }
      }

      // Try to use the ImagePicker with camera source
      final ImagePicker picker = ImagePicker();

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        print('✅ ALTERNATIVE CAMERA SUCCESS! Size: ${bytes.length} bytes');
        return bytes;
      } else {
        print('❌ Alternative camera failed - no image captured');
        return null;
      }
    } catch (e) {
      print('❌ Alternative camera error: $e');
      throw Exception('Camera access failed: $e');
    }
  }

  /// Test if camera is available
  static Future<bool> isCameraAvailable() async {
    try {
      if (kIsWeb) {
        return true; // Assume camera available on web
      }

      final status = await Permission.camera.status;
      return status.isGranted || status.isPermanentlyDenied == false;
    } catch (e) {
      print('Error checking camera availability: $e');
      return false;
    }
  }

  /// Pick a PDF file from device storage
  /// Returns the Uint8List of the selected PDF, or null if cancelled
  static Future<Uint8List?> pickPDFFromFiles() async {
    try {
      print('📄 Opening file picker for PDF...');

      // Check storage permission for file access on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            print('Storage permission denied');
            return null;
          }
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          print('✅ PDF file selected! Size: ${file.bytes!.length} bytes');
          return file.bytes!;
        } else if (file.path != null) {
          // For platforms where bytes might be null, read from path
          final bytes = await File(file.path!).readAsBytes();
          print('✅ PDF file selected! Size: ${bytes.length} bytes');
          return bytes;
        }
      } else {
        print('❌ No PDF file selected');
        return null;
      }
    } catch (e) {
      print('❌ Error picking PDF file: $e');
      return null;
    }
    return null;
  }

  /// Example usage of how to handle the returned File
  static Future<void> handleImageSelection({required bool fromCamera}) async {
    Uint8List? imageFile =
        fromCamera ? await captureImage() : await pickImageFromGallery();

    if (imageFile != null) {
      // Do something with the image file
      // For example, upload to server or display in UI
      print('Image selected');
    }
  }
}
