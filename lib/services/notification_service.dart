import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static RealtimeChannel? _errandsChannel;
  static RealtimeChannel? _updatesChannel;

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
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
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lotto_runners_channel',
      'Lotto Runners Notifications',
      channelDescription: 'Notifications for errand updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> setupRealtimeSubscriptions() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    // Clean up existing subscriptions
    await _errandsChannel?.unsubscribe();
    await _updatesChannel?.unsubscribe();

    // Subscribe to errands table changes
    _errandsChannel =
        SupabaseConfig.client.channel('errands_changes').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'errands',
              callback: (payload) => _handleErrandChange(payload, userId),
            );

    // Subscribe to errand updates table changes
    _updatesChannel = SupabaseConfig.client
        .channel('errand_updates_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'errand_updates',
          callback: (payload) => _handleErrandUpdate(payload, userId),
        );

    // Start listening
    _errandsChannel?.subscribe();
    _updatesChannel?.subscribe();
  }

  static void _handleErrandChange(
      PostgresChangePayload payload, String userId) {
    final record = payload.newRecord;
    final eventType = payload.eventType;

    if (record.isEmpty) return;

    switch (eventType) {
      case PostgresChangeEvent.insert:
        // New errand posted - notify runners
        _notifyRunnersOfNewErrand(record);
        break;

      case PostgresChangeEvent.update:
        // Errand status changed
        _notifyErrandStatusChange(record, userId);
        break;

      default:
        break;
    }
  }

  static void _handleErrandUpdate(
      PostgresChangePayload payload, String userId) {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    // Someone posted an update on an errand
    _notifyErrandMessage(record, userId);
  }

  static Future<void> _notifyRunnersOfNewErrand(
      Map<String, dynamic> errand) async {
    // Only notify if current user is not the customer
    final currentUserId = SupabaseConfig.currentUser?.id;
    if (currentUserId == errand['customer_id']) return;

    // Check if current user is a runner
    final userProfile = await SupabaseConfig.getUserProfile(currentUserId!);
    if (userProfile?['user_type'] != 'runner') return;

    // Check vehicle requirement
    if (errand['requires_vehicle'] == true &&
        userProfile?['has_vehicle'] != true) {
      return;
    }

    final category = errand['category'] ?? 'errand';
    final price = errand['price_amount']?.toString() ?? '0';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '💰 New $category available',
      body: '${errand['title']} - \$$price',
      payload: 'errand:${errand['id']}',
    );
  }

  static Future<void> _notifyErrandStatusChange(
      Map<String, dynamic> errand, String userId) async {
    final status = errand['status'];
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];

    String? title;
    String? body;

    // Notify customer of status changes
    if (userId == customerId) {
      switch (status) {
        case 'accepted':
          title = '✅ Errand Accepted';
          body = 'A runner has accepted your errand: ${errand['title']}';
          break;
        case 'in_progress':
          title = '🏃 Errand Started';
          body = 'Your runner has started working on: ${errand['title']}';
          break;
        case 'completed':
          title = '🎉 Errand Completed';
          body = 'Your errand has been completed: ${errand['title']}';
          break;
      }
    }

    // Notify runner of acceptance confirmation
    else if (userId == runnerId && status == 'accepted') {
      title = '🎯 Errand Confirmed';
      body = 'You have successfully accepted: ${errand['title']}';
    }

    if (title != null && body != null) {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'errand:${errand['id']}',
      );
    }
  }

  static Future<void> _notifyErrandMessage(
      Map<String, dynamic> update, String userId) async {
    try {
      // Get errand details
      final errandResponse = await SupabaseConfig.client
          .from('errands')
          .select(
              '*, customer:customer_id(full_name), runner:runner_id(full_name)')
          .eq('id', update['errand_id'])
          .single();

      final errand = errandResponse;
      final customerId = errand['customer_id'];
      final runnerId = errand['runner_id'];
      final messageUserId = update['user_id'];

      // Don't notify the person who sent the message
      if (userId == messageUserId) return;

      // Only notify if user is involved in this errand
      if (userId != customerId && userId != runnerId) return;

      final senderName = messageUserId == customerId
          ? errand['customer']['full_name'] ?? 'Customer'
          : errand['runner']['full_name'] ?? 'Runner';

      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '💬 Message from $senderName',
        body: update['message'] ?? 'New message received',
        payload: 'errand:${errand['id']}',
      );
    } catch (e) {
      print('Error handling errand message notification: $e');
    }
  }

  static Future<void> cleanup() async {
    await _errandsChannel?.unsubscribe();
    await _updatesChannel?.unsubscribe();
    _errandsChannel = null;
    _updatesChannel = null;
  }

  // Utility methods for specific notifications
  static Future<void> notifyErrandAccepted(String errandTitle) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '✅ Errand Accepted',
      body: 'You have successfully accepted: $errandTitle',
    );
  }

  static Future<void> notifyErrandCompleted(String errandTitle) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🎉 Errand Completed',
      body: 'You have completed: $errandTitle',
    );
  }

  static Future<void> notifyPaymentReceived(double amount) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '💰 Payment Received',
      body:
          'You received \$${amount.toStringAsFixed(2)} for completing an errand',
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
        NotificationService.cleanup();
      }
    });
  }
}
