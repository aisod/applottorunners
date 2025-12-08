import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Navigate to password reset page
  static void navigateToPasswordReset() {
    navigator?.pushNamed('/password-reset');
  }

  /// Navigate to auth page
  static void navigateToAuth() {
    navigator?.pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  /// Show success message
  static void showSuccessMessage(String message) {
    final context = navigator?.overlay?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show error message
  static void showErrorMessage(String message) {
    final context = navigator?.overlay?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
