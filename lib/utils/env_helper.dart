import 'package:flutter/foundation.dart';
import 'env_helper_stub.dart'
    if (dart.library.io) 'dart:io';

/// Helper to get system environment variables
/// Works on mobile/desktop, returns null on web
String? getSystemEnv(String key) {
  if (kIsWeb) {
    // On web, system environment variables are not available at runtime
    // They are baked into the build via flutter_dotenv or --dart-define
    return null;
  }
  
  try {
    return Platform.environment[key]?.trim();
  } catch (e) {
    return null;
  }
}

/// Check if system environment variable exists
bool hasSystemEnv(String key) {
  if (kIsWeb) return false;
  
  try {
    return Platform.environment.containsKey(key);
  } catch (e) {
    return false;
  }
}
