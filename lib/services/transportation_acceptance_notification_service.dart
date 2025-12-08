import 'package:flutter/material.dart';
import 'package:lotto_runners/widgets/transportation_accepted_popup.dart';

/// Service to manage transportation acceptance notifications for customers
class TransportationAcceptanceNotificationService {
  static TransportationAcceptanceNotificationService? _instance;
  static TransportationAcceptanceNotificationService get instance =>
      _instance ??= TransportationAcceptanceNotificationService._();

  TransportationAcceptanceNotificationService._();

  OverlayEntry? _currentNotification;
  BuildContext? _currentContext;
  final Set<String> _shownNotifications =
      {}; // Track shown notifications to prevent duplicates

  /// Start monitoring for transportation acceptances
  void startMonitoring(BuildContext context) {
    _currentContext = context;
    print(
        '🔔 [Transportation] Started monitoring for transportation acceptances');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _currentContext = null;
    _hideNotification();
    print(
        '🔔 [Transportation] Stopped monitoring for transportation acceptances');
  }

  /// Show acceptance notification
  void showAcceptanceNotification({
    required String bookingId,
    required String serviceName,
    required String driverName,
  }) {
    print(
        '🔔 [Transportation] Attempting to show notification for booking: $bookingId');
    print('🔔 [Transportation] Service: $serviceName');
    print('🔔 [Transportation] Driver: $driverName');

    // Check if we've already shown this notification
    if (_shownNotifications.contains(bookingId)) {
      print(
          '🔔 [Transportation] Notification already shown for booking: $bookingId, skipping');
      return;
    }

    // Hide any existing notification
    _hideNotification();

    if (_currentContext == null) {
      print('❌ [Transportation] No context available for notification');
      return;
    }

    // Create overlay entry
    _currentNotification = OverlayEntry(
      builder: (context) => TransportationAcceptedPopup(
        bookingId: bookingId,
        serviceName: serviceName,
        driverName: driverName,
        onDismiss: _hideNotification,
      ),
    );

    // Insert into overlay
    Overlay.of(_currentContext!).insert(_currentNotification!);

    // Mark this notification as shown
    _shownNotifications.add(bookingId);

    print(
        '🔔 [Transportation] Showed acceptance notification for booking: $bookingId');
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
    print('🔔 [Transportation] Cleared shown notifications');
  }

  /// Dispose resources
  void dispose() {
    _hideNotification();
    _currentContext = null;
    _shownNotifications.clear();
  }
}
