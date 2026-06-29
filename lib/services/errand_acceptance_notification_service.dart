import 'package:flutter/material.dart';
import 'package:lotto_runners/widgets/errand_accepted_popup.dart';
import 'package:lotto_runners/utils/app_log.dart';

/// Service to manage errand acceptance notifications for customers
class ErrandAcceptanceNotificationService {
  static ErrandAcceptanceNotificationService? _instance;
  static ErrandAcceptanceNotificationService get instance =>
      _instance ??= ErrandAcceptanceNotificationService._();

  ErrandAcceptanceNotificationService._();

  OverlayEntry? _currentNotification;
  BuildContext? _currentContext;
  final Set<String> _shownNotifications =
      {}; // Track shown notifications to prevent duplicates

  /// Start monitoring for errand acceptances
  void startMonitoring(BuildContext context) {
    _currentContext = context;
    appLog('🔔 [Acceptance] Started monitoring for errand acceptances');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _currentContext = null;
    _hideNotification();
    appLog('🔔 [Acceptance] Stopped monitoring for errand acceptances');
  }

  /// Show acceptance notification
  void showAcceptanceNotification({
    required String errandId,
    required String errandTitle,
    required String runnerName,
  }) {
    appLog(
        '🔔 [Acceptance] Attempting to show notification for errand: $errandId');
    appLog('🔔 [Acceptance] Errand title: $errandTitle');
    appLog('🔔 [Acceptance] Runner name: $runnerName');

    // Check if we've already shown this notification
    if (_shownNotifications.contains(errandId)) {
      appLog(
          '🔔 [Acceptance] Notification already shown for errand: $errandId, skipping');
      return;
    }

    // Hide any existing notification
    _hideNotification();

    if (_currentContext == null) {
      appLog('❌ [Acceptance] No context available for notification');
      return;
    }

    // Create overlay entry
    _currentNotification = OverlayEntry(
      builder: (context) => ErrandAcceptedPopup(
        errandId: errandId,
        errandTitle: errandTitle,
        runnerName: runnerName,
        onDismiss: _hideNotification,
      ),
    );

    // Insert into overlay
    Overlay.of(_currentContext!).insert(_currentNotification!);

    // Mark this notification as shown
    _shownNotifications.add(errandId);

    appLog(
        '🔔 [Acceptance] Showed acceptance notification for errand: $errandId');
  }

  /// Hide current notification
  void _hideNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
  }

  /// Check if notification is currently showing
  bool get isShowing => _currentNotification != null;

  /// Clear shown notifications (for testing or cleanup)
  void clearShownNotifications() {
    _shownNotifications.clear();
    appLog('🔔 [Acceptance] Cleared shown notifications');
  }

  /// Dispose resources
  void dispose() {
    _hideNotification();
    _currentContext = null;
    _shownNotifications.clear();
  }
}
