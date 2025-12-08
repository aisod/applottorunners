import 'dart:async';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// Service to handle scheduled errand notifications with different reminder intervals
/// Uses scheduled_start_time and scheduled_end_time columns for precise timing
class ScheduledErrandNotificationService {
  static ScheduledErrandNotificationService? _instance;
  static ScheduledErrandNotificationService get instance =>
      _instance ??= ScheduledErrandNotificationService._();

  ScheduledErrandNotificationService._();

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (!_isInitialized) {
      _startScheduledCheck();
      _isInitialized = true;
      print('⏰ Scheduled errand notification service initialized');
    }
  }

  /// Start periodic checking for scheduled errands
  void _startScheduledCheck() {
    _checkTimer?.cancel();

    // Check every 5 minutes for scheduled errands
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkScheduledErrands();
    });

    print('⏰ [Scheduled] Starting scheduled errand checks every 5 minutes');
  }

  /// Check for scheduled errands and send appropriate notifications
  Future<void> _checkScheduledErrands() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      print('🔍 [Scheduled] Checking for scheduled errands...');

      // Get user's scheduled errands using scheduled_start_time
      final errands = await SupabaseConfig.client
          .from('errands')
          .select('*')
          .eq('customer_id', user.id)
          .eq('is_immediate', false) // Only scheduled errands
          .inFilter(
              'status', ['posted', 'accepted', 'in_progress']) // Active errands
          .order('scheduled_start_time', ascending: true);

      final now = DateTime.now();

      for (final errand in errands) {
        await _checkErrandReminders(errand, now);
      }
    } catch (e) {
      print('❌ [Scheduled] Error checking scheduled errands: $e');
    }
  }

  /// Check and send reminders for a specific errand
  /// Uses scheduled_start_time for precise timing
  Future<void> _checkErrandReminders(
      Map<String, dynamic> errand, DateTime now) async {
    try {
      final scheduledStartTime = DateTime.parse(errand['scheduled_start_time']);

      // Calculate time differences from scheduled_start_time
      final timeUntilStart = scheduledStartTime.difference(now);
      final minutesUntilStart = timeUntilStart.inMinutes;
      final hoursUntilStart = timeUntilStart.inHours;
      final daysUntilStart = timeUntilStart.inDays;

      // Send notifications based on time intervals
      await _sendReminderIfNeeded(
          errand, minutesUntilStart, hoursUntilStart, daysUntilStart);
    } catch (e) {
      print(
          '❌ [Scheduled] Error checking reminders for errand ${errand['id']}: $e');
    }
  }

  /// Send reminder notification if needed
  Future<void> _sendReminderIfNeeded(
    Map<String, dynamic> errand,
    int minutesUntilStart,
    int hoursUntilStart,
    int daysUntilStart,
  ) async {
    final errandTitle = errand['title'] ?? 'Errand';
    final status = errand['status'];

    // Check notification flags from database to prevent duplicates
    final notification5minSent = errand['notification_5min_sent'] ?? false;
    final notification10minSent = errand['notification_10min_sent'] ?? false;
    final notification1hourSent = errand['notification_1hour_sent'] ?? false;
    final notificationStartSent = errand['notification_start_sent'] ?? false;
    final notificationDailySent =
        List<String>.from(errand['notification_daily_sent'] ?? []);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Exact start time notification (when errand starts)
    if (minutesUntilStart <= 0 &&
        minutesUntilStart > -5 &&
        !notificationStartSent) {
      await _sendReminderNotification(
        errand,
        'Your errand has started!',
        '$errandTitle is now active. Please be ready for your runner.',
        'notification_start_sent',
        true,
      );
    }

    // 5 minutes before start
    if (minutesUntilStart <= 5 &&
        minutesUntilStart > 0 &&
        !notification5minSent) {
      await _sendReminderNotification(
        errand,
        'Your errand starts in 5 minutes!',
        '$errandTitle is about to begin. Please be ready.',
        'notification_5min_sent',
        true,
      );
    }

    // 10 minutes before start
    if (minutesUntilStart <= 10 &&
        minutesUntilStart > 5 &&
        !notification10minSent) {
      await _sendReminderNotification(
        errand,
        'Errand starting soon!',
        '$errandTitle will begin in 10 minutes.',
        'notification_10min_sent',
        true,
      );
    }

    // 1 hour before start
    if (hoursUntilStart <= 1 && hoursUntilStart > 0 && !notification1hourSent) {
      await _sendReminderNotification(
        errand,
        'Errand reminder - 1 hour',
        '$errandTitle will start in 1 hour. Please prepare.',
        'notification_1hour_sent',
        true,
      );
    }

    // Daily reminders for errands scheduled days in advance
    if (daysUntilStart > 0 && !notificationDailySent.contains(today)) {
      final dayText = daysUntilStart == 1 ? '1 day' : '$daysUntilStart days';
      await _sendReminderNotification(
        errand,
        'Scheduled errand reminder',
        '$errandTitle will start in $dayText. Status: ${status.toUpperCase()}',
        'notification_daily_sent',
        [...notificationDailySent, today],
      );
    }
  }

  /// Send a reminder notification
  Future<void> _sendReminderNotification(
    Map<String, dynamic> errand,
    String title,
    String body,
    String notificationField,
    dynamic notificationValue,
  ) async {
    try {
      // Send local notification
      await NotificationService.showNotification(
        title: title,
        body: body,
        payload: 'scheduled_errand:${errand['id']}',
      );

      // Update notification flag in database
      await SupabaseConfig.client.from('errands').update(
          {notificationField: notificationValue}).eq('id', errand['id']);

      // Store notification in database for customer
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': errand['customer_id'],
        'title': title,
        'message': body,
        'type': 'scheduled_errand_reminder',
        'errand_id': errand['id'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('📱 [Scheduled] Sent reminder: $title for errand ${errand['id']}');
    } catch (e) {
      print('❌ [Scheduled] Error sending reminder notification: $e');
    }
  }

  /// Get upcoming scheduled errands for a user
  Future<List<Map<String, dynamic>>> getUpcomingScheduledErrands(
      String userId) async {
    try {
      final now = DateTime.now();

      final errands = await SupabaseConfig.client
          .from('errands')
          .select('*')
          .eq('customer_id', userId)
          .eq('is_immediate', false)
          .inFilter('status', ['posted', 'accepted', 'in_progress'])
          .gt('scheduled_start_time', now.toIso8601String())
          .order('scheduled_start_time', ascending: true);

      final upcoming = <Map<String, dynamic>>[];

      for (final errand in errands) {
        final startTime = DateTime.parse(errand['scheduled_start_time']);
        upcoming.add({
          ...errand,
          'minutes_until_start': startTime.difference(now).inMinutes,
          'hours_until_start': startTime.difference(now).inHours,
          'days_until_start': startTime.difference(now).inDays,
        });
      }

      return upcoming;
    } catch (e) {
      print('❌ [Scheduled] Error fetching upcoming errands: $e');
      return [];
    }
  }

  /// Dispose of the service
  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
    print('⏰ [Scheduled] Scheduled errand notification service disposed');
  }
}
