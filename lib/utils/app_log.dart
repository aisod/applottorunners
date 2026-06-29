import 'package:flutter/foundation.dart';

/// Development-only logging. No output in release builds (e.g. Google Play).
void appLog(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}
