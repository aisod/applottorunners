import 'dart:async';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// Service to handle scheduled contract booking notifications with different reminder intervals
/// Uses contract_start_date and contract_start_time columns for precise timing
class ScheduledContractNotificationService {
  static ScheduledContractNotificationService? _instance;
  static ScheduledContractNotificationService get instance =>
      _instance ??= ScheduledContractNotificationService._();

  ScheduledContractNotificationService._();

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (!_isInitialized) {
      _startScheduledCheck();
      _isInitialized = true;
      print('⏰ Scheduled contract notification service initialized');
    }
  }

  /// Start periodic checking for scheduled contract bookings
  void _startScheduledCheck() {
    _checkTimer?.cancel();

    // Check every 5 minutes for scheduled contract bookings
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkScheduledContracts();
    });

    print('⏰ [Scheduled] Starting scheduled contract checks every 5 minutes');
  }

  /// Check for scheduled contract bookings and send appropriate notifications
  Future<void> _checkScheduledContracts() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      print('🔍 [Scheduled] Checking for scheduled contract bookings...');

      // Get user's scheduled contract bookings using contract_start_date and contract_start_time
      // Include driver_id for notifications
      final contracts = await SupabaseConfig.client
          .from('contract_bookings')
          .select('*, driver_id')
          .eq('user_id', user.id)
          .inFilter('status', ['confirmed', 'active']) // Active contracts
          .order('contract_start_date', ascending: true);

      final now = DateTime.now();

      for (final contract in contracts) {
        await _checkContractReminders(contract, now);
      }
    } catch (e) {
      print('❌ [Scheduled] Error checking scheduled contracts: $e');
    }
  }

  /// Check and send reminders for a specific contract booking
  /// Uses contract_start_date and contract_start_time for precise timing
  Future<void> _checkContractReminders(
      Map<String, dynamic> contract, DateTime now) async {
    try {
      // Combine date and time to create full datetime
      final startDate = DateTime.parse(contract['contract_start_date']);
      final startTime = contract['contract_start_time'] as String;
      final timeParts = startTime.split(':');
      final scheduledStartTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Calculate time differences from scheduled_start_time
      final timeUntilStart = scheduledStartTime.difference(now);
      final minutesUntilStart = timeUntilStart.inMinutes;
      final hoursUntilStart = timeUntilStart.inHours;
      final daysUntilStart = timeUntilStart.inDays;

      // Send notifications based on time intervals
      await _sendReminderIfNeeded(
          contract, minutesUntilStart, hoursUntilStart, daysUntilStart);
    } catch (e) {
      print(
          '❌ [Scheduled] Error checking reminders for contract ${contract['id']}: $e');
    }
  }

  /// Send reminder notification if needed
  Future<void> _sendReminderIfNeeded(
    Map<String, dynamic> contract,
    int minutesUntilStart,
    int hoursUntilStart,
    int daysUntilStart,
  ) async {
    final contractDescription = contract['description'] ?? 'Contract Service';
    final status = contract['status'];
    final durationType = contract['contract_duration_type'];
    final durationValue = contract['contract_duration_value'];

    // Check notification flags from database to prevent duplicates
    final notification5minSent = contract['notification_5min_sent'] ?? false;
    final notification10minSent = contract['notification_10min_sent'] ?? false;
    final notification1hourSent = contract['notification_1hour_sent'] ?? false;
    final notificationStartSent = contract['notification_start_sent'] ?? false;
    final notificationDailySent =
        List<String>.from(contract['notification_daily_sent'] ?? []);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Exact start time notification (when contract starts)
    if (minutesUntilStart <= 0 &&
        minutesUntilStart > -5 &&
        !notificationStartSent) {
      await _sendReminderNotification(
        contract,
        'Your contract service has started!',
        '$contractDescription is now active. Your transportation service is beginning.',
        'notification_start_sent',
        true,
      );
    }

    // 5 minutes before start
    if (minutesUntilStart <= 5 &&
        minutesUntilStart > 0 &&
        !notification5minSent) {
      await _sendReminderNotification(
        contract,
        'Contract service starts in 5 minutes!',
        '$contractDescription is about to begin. Please be ready.',
        'notification_5min_sent',
        true,
      );
    }

    // 10 minutes before start
    if (minutesUntilStart <= 10 &&
        minutesUntilStart > 5 &&
        !notification10minSent) {
      await _sendReminderNotification(
        contract,
        'Contract service starting soon!',
        '$contractDescription will begin in 10 minutes.',
        'notification_10min_sent',
        true,
      );
    }

    // 1 hour before start
    if (hoursUntilStart <= 1 && hoursUntilStart > 0 && !notification1hourSent) {
      await _sendReminderNotification(
        contract,
        'Contract reminder - 1 hour',
        '$contractDescription will start in 1 hour. Please prepare.',
        'notification_1hour_sent',
        true,
      );
    }

    // Daily reminders for contracts scheduled days in advance
    if (daysUntilStart > 0 && !notificationDailySent.contains(today)) {
      final dayText = daysUntilStart == 1 ? '1 day' : '$daysUntilStart days';
      final durationText = _getDurationText(durationType, durationValue);
      await _sendReminderNotification(
        contract,
        'Contract booking reminder',
        '$contractDescription will start in $dayText. Duration: $durationText. Status: ${status.toUpperCase()}',
        'notification_daily_sent',
        [...notificationDailySent, today],
      );
    }
  }

  /// Send a reminder notification
  Future<void> _sendReminderNotification(
    Map<String, dynamic> contract,
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
        payload: 'scheduled_contract:${contract['id']}',
      );

      // Update notification flag in database
      await SupabaseConfig.client.from('contract_bookings').update(
          {notificationField: notificationValue}).eq('id', contract['id']);

      // Store notification in database for customer
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': contract['user_id'],
        'title': title,
        'message': body,
        'type': 'scheduled_contract_reminder',
        'contract_booking_id': contract['id'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Also notify the assigned driver if there is one
      if (contract['driver_id'] != null) {
        await SupabaseConfig.client.from('notifications').insert({
          'user_id': contract['driver_id'],
          'title': 'Driver: $title',
          'message': 'Contract ID: ${contract['id']} - $body',
          'type': 'scheduled_contract_reminder',
          'contract_booking_id': contract['id'],
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      print(
          '📱 [Scheduled] Sent reminder: $title for contract ${contract['id']}');
    } catch (e) {
      print('❌ [Scheduled] Error sending contract reminder notification: $e');
    }
  }

  /// Get upcoming scheduled contract bookings for a user
  Future<List<Map<String, dynamic>>> getUpcomingScheduledContracts(
      String userId) async {
    try {
      final now = DateTime.now();

      final contracts = await SupabaseConfig.client
          .from('contract_bookings')
          .select('*, driver_id')
          .eq('user_id', userId)
          .inFilter('status', ['confirmed', 'active'])
          .gte('contract_start_date', now.toIso8601String().split('T')[0])
          .order('contract_start_date', ascending: true);

      final upcoming = <Map<String, dynamic>>[];

      for (final contract in contracts) {
        final startDate = DateTime.parse(contract['contract_start_date']);
        final startTime = contract['contract_start_time'] as String;
        final timeParts = startTime.split(':');
        final scheduledStartTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        upcoming.add({
          ...contract,
          'minutes_until_start': scheduledStartTime.difference(now).inMinutes,
          'hours_until_start': scheduledStartTime.difference(now).inHours,
          'days_until_start': scheduledStartTime.difference(now).inDays,
        });
      }

      return upcoming;
    } catch (e) {
      print('❌ [Scheduled] Error fetching upcoming contracts: $e');
      return [];
    }
  }

  /// Helper method to format duration text
  String _getDurationText(String durationType, int durationValue) {
    switch (durationType) {
      case 'weekly':
        return durationValue == 1 ? '1 week' : '$durationValue weeks';
      case 'monthly':
        return durationValue == 1 ? '1 month' : '$durationValue months';
      case 'yearly':
        return durationValue == 1 ? '1 year' : '$durationValue years';
      default:
        return '$durationValue $durationType';
    }
  }

  /// Dispose of the service
  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
    print('⏰ [Scheduled] Scheduled contract notification service disposed');
  }
}
