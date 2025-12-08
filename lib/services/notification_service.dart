import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static RealtimeChannel? _errandsChannel;
  static RealtimeChannel? _updatesChannel;

  static Future<void> initialize() async {
    // Initialize local notifications
    // Use launcher_icon which is the Lotto Runners logo
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Use launcher_icon for the small notification icon (Lotto Runners logo)
    // Use largeIcon to show the colored logo in expanded notifications
    final androidDetails = AndroidNotificationDetails(
      'lotto_runners_channel',
      'Lotto Runners Notifications',
      channelDescription: 'Notifications for errand updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Setup realtime subscriptions for current user
  static void setupRealtimeSubscriptions() {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    _cleanup(); // Clean up existing subscriptions

    // For now, we'll implement basic notification system without real-time subscriptions
    // TODO: Implement proper real-time subscriptions when Supabase API is updated
    print('Real-time notifications initialized for user: ${user.id}');
  }

  static void _handleErrandChange(Map<String, dynamic> payload, String userId) {
    // Placeholder for future implementation
    print('Errand change detected: $payload');
  }

  static void _handleErrandUpdate(Map<String, dynamic> payload, String userId) {
    // Placeholder for future implementation
    print('Errand update detected: $payload');
  }

  static Future<void> _notifyRunnersOfNewErrand(
      Map<String, dynamic> errand) async {
    // Only notify if current user is not the customer
    final currentUserId = SupabaseConfig.currentUser?.id;
    if (currentUserId == errand['customer_id']) return;

    // Check if current user is a runner
    final profile = await SupabaseConfig.getCurrentUserProfile();
    if (profile?['user_type'] != 'runner') return;

    // Check if errand requires vehicle and runner has one
    final requiresVehicle = errand['requires_vehicle'] as bool? ?? false;
    final hasVehicle = profile?['has_vehicle'] as bool? ?? false;

    if (requiresVehicle && !hasVehicle) return;

    await showNotification(
      title: 'New Errand Available',
      body: 'N\$${errand['price_amount']} - ${errand['title']}',
      payload: 'errand:${errand['id']}',
    );
  }

  static Future<void> _notifyErrandStatusChange(
      Map<String, dynamic> errand, String userId) async {
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];
    final status = errand['status'];

    String? title;
    String? body;

    // Notify customer
    if (userId == customerId) {
      switch (status) {
        case 'accepted':
          title = 'Errand Accepted';
          body = 'A runner has accepted your errand: ${errand['title']}';
          break;
        case 'in_progress':
          title = 'Errand In Progress';
          body = 'Your errand is now in progress: ${errand['title']}';
          break;
        case 'completed':
          title = 'Errand Completed';
          body = 'Your errand has been completed: ${errand['title']}';
          break;
      }
    }
    // Notify runner
    else if (userId == runnerId) {
      switch (status) {
        case 'cancelled':
          title = 'Errand Cancelled';
          body = 'The errand has been cancelled: ${errand['title']}';
          break;
      }
    }

    if (title != null && body != null) {
      await showNotification(
        title: title,
        body: body,
        payload: 'errand:${errand['id']}',
      );
    }
  }

  static Future<void> _notifyErrandMessage(
      Map<String, dynamic> update, String userId) async {
    // Don't notify if current user posted the update
    if (userId == update['posted_by']) return;

    final errandId = update['errand_id'];
    final message = update['message'];

    await showNotification(
      title: 'New Errand Update',
      body: message,
      payload: 'errand:$errandId',
    );
  }

  // Cleanup subscriptions
  static void _cleanup() {
    _errandsChannel?.unsubscribe();
    _updatesChannel?.unsubscribe();
    _errandsChannel = null;
    _updatesChannel = null;
  }

  static void dispose() {
    _cleanup();
  }

  // Manual notification methods for specific events
  static Future<void> notifyErrandAccepted(String errandTitle) async {
    await showNotification(
      title: 'Errand Accepted Successfully',
      body: 'You have accepted: $errandTitle',
    );
  }

  static Future<void> notifyErrandCompleted(String errandTitle) async {
    await showNotification(
      title: 'Errand Marked Complete',
      body: 'You completed: $errandTitle',
    );
  }

  static Future<void> notifyNewErrandPosted(
      String errandTitle, double price) async {
    await showNotification(
      title: 'Your Errand is Live',
      body: '$errandTitle - N\$$price posted successfully',
    );
  }

  static Future<void> notifyPaymentReceived(double amount) async {
    await showNotification(
      title: 'Payment Received',
      body: 'You received N\$$amount for completing an errand',
    );
  }

  static Future<void> notifyRunnerVerified() async {
    await showNotification(
      title: 'Verification Complete',
      body: 'Your runner application has been approved!',
    );
  }

  static Future<void> notifyRunnerRejected(String reason) async {
    await showNotification(
      title: 'Application Update',
      body: 'Your runner application needs attention: $reason',
    );
  }

  // Transportation-specific notifications
  static Future<void> notifyTransportationAccepted(String serviceName) async {
    await showNotification(
      title: 'Transportation Accepted',
      body: 'A runner has accepted your transportation request: $serviceName',
    );
  }

  static Future<void> notifyTransportationStarted(String serviceName) async {
    await showNotification(
      title: 'Transportation Started',
      body: 'Your transportation service has started: $serviceName',
    );
  }

  static Future<void> notifyTransportationCompleted(String serviceName) async {
    await showNotification(
      title: 'Transportation Completed',
      body: 'Your transportation service has been completed: $serviceName',
    );
  }

  static Future<void> notifyTransportationCancelled(
      String serviceName, String reason) async {
    await showNotification(
      title: 'Transportation Cancelled',
      body:
          'Your transportation service was cancelled: $serviceName\nReason: $reason',
    );
  }

  static Future<void> notifyRunnerTransportationAccepted(
      String serviceName) async {
    await showNotification(
      title: 'Transportation Accepted Successfully',
      body: 'You have accepted: $serviceName',
    );
  }

  static Future<void> notifyRunnerTransportationStarted(
      String serviceName) async {
    await showNotification(
      title: 'Transportation Started',
      body: 'You have started: $serviceName',
    );
  }

  static Future<void> notifyRunnerTransportationCompleted(
      String serviceName) async {
    await showNotification(
      title: 'Transportation Completed',
      body: 'You have completed: $serviceName',
    );
  }

  static Future<void> notifyRunnerTransportationCancelled(
      String serviceName) async {
    await showNotification(
      title: 'Transportation Cancelled',
      body: 'The transportation service was cancelled: $serviceName',
    );
  }

  static Future<void> notifyErrandOverdue(
      String errandTitle, String status) async {
    String body;
    if (status == 'posted') {
      body =
          '$errandTitle is overdue and still waiting for a runner. Consider re-posting or contacting support.';
    } else {
      body =
          '$errandTitle is overdue. Please contact your assigned runner for updates.';
    }

    await showNotification(
      title: 'Errand Overdue',
      body: body,
    );
  }

  // Scheduled errand start notification
  static Future<void> notifyErrandStarted(String errandTitle) async {
    await showNotification(
      title: 'Your errand has started!',
      body: '$errandTitle is now active. Please be ready for your runner.',
    );
  }

  // Cancellation notification methods
  static Future<void> notifyErrandCancelledByCustomer(
      String errandTitle, String customerName) async {
    await showNotification(
      title: 'Errand Cancelled by Customer',
      body: 'Customer cancelled: $errandTitle',
    );
  }

  static Future<void> notifyErrandCancelledByRunner(
      String errandTitle, String runnerName) async {
    await showNotification(
      title: 'Errand Cancelled by Runner',
      body: 'Runner cancelled: $errandTitle',
    );
  }

  static Future<void> notifyTransportationCancelledByCustomer(
      String serviceName, String customerName) async {
    await showNotification(
      title: 'Transportation Cancelled by Customer',
      body: 'Customer cancelled: $serviceName',
    );
  }

  static Future<void> notifyTransportationCancelledByRunner(
      String serviceName, String runnerName) async {
    await showNotification(
      title: 'Transportation Cancelled by Runner',
      body: 'Runner cancelled: $serviceName',
    );
  }

  // Contract booking notification methods
  static Future<void> notifyContractBookingConfirmed(
      String contractDescription) async {
    await showNotification(
      title: 'Contract Booking Confirmed',
      body: 'Your contract booking has been confirmed: $contractDescription',
    );
  }

  static Future<void> notifyContractBookingStarted(
      String contractDescription) async {
    await showNotification(
      title: 'Contract Service Started',
      body: 'Your contract service has started: $contractDescription',
    );
  }

  static Future<void> notifyContractBookingCompleted(
      String contractDescription) async {
    await showNotification(
      title: 'Contract Service Completed',
      body: 'Your contract service has been completed: $contractDescription',
    );
  }

  static Future<void> notifyContractBookingCancelled(
      String contractDescription, String reason) async {
    await showNotification(
      title: 'Contract Booking Cancelled',
      body:
          'Your contract booking was cancelled: $contractDescription\nReason: $reason',
    );
  }

  // Bus booking notification methods
  static Future<void> notifyBusBookingConfirmed(String serviceName) async {
    await showNotification(
      title: 'Bus Booking Confirmed',
      body: 'Your bus booking has been confirmed: $serviceName',
    );
  }

  static Future<void> notifyBusBookingStarted(String serviceName) async {
    await showNotification(
      title: 'Bus Service Started',
      body: 'Your bus service has started: $serviceName',
    );
  }

  static Future<void> notifyBusBookingCompleted(String serviceName) async {
    await showNotification(
      title: 'Bus Service Completed',
      body: 'Your bus service has been completed: $serviceName',
    );
  }

  static Future<void> notifyBusBookingCancelled(
      String serviceName, String reason) async {
    await showNotification(
      title: 'Bus Booking Cancelled',
      body: 'Your bus booking was cancelled: $serviceName\nReason: $reason',
    );
  }

  static Future<void> notifyBusBookingNoShow(String serviceName) async {
    await showNotification(
      title: 'Bus Service No Show',
      body:
          'You missed your bus service: $serviceName. Please contact support if this was an error.',
    );
  }

  // Admin acceptance notification methods
  static Future<void> notifyCustomerBusBookingAcceptedByAdmin(
      String serviceName) async {
    await showNotification(
      title: 'Bus Booking Accepted',
      body: 'Your bus booking has been accepted: $serviceName',
    );
  }

}

// Extension to help integrate notifications with the app lifecycle
extension NotificationIntegration on WidgetsBinding {
  static Future<void> initializeNotifications() async {
    await NotificationService.initialize();

    // Setup subscriptions when user is authenticated
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        NotificationService.setupRealtimeSubscriptions();
      } else if (event == AuthChangeEvent.signedOut) {
        NotificationService.dispose();
      }
    });
  }
}
