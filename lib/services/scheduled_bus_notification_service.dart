import 'dart:async';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// Service to handle scheduled bus booking notifications with different reminder intervals
/// Uses booking_date and booking_time columns for precise timing
class ScheduledBusNotificationService {
  static ScheduledBusNotificationService? _instance;
  static ScheduledBusNotificationService get instance =>
      _instance ??= ScheduledBusNotificationService._();

  ScheduledBusNotificationService._();

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (!_isInitialized) {
      _startScheduledCheck();
      _isInitialized = true;
      print('⏰ Scheduled bus notification service initialized');
    }
  }

  /// Start periodic checking for scheduled bus bookings
  void _startScheduledCheck() {
    _checkTimer?.cancel();

    // Check every 5 minutes for scheduled bus bookings
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkScheduledBusBookings();
    });

    print(
        '⏰ [Scheduled] Starting scheduled bus booking checks every 5 minutes');
  }

  /// Check for scheduled bus bookings and send appropriate notifications
  Future<void> _checkScheduledBusBookings() async {
    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      print('🔍 [Scheduled] Checking for scheduled bus bookings...');

      // Get user's scheduled bus bookings using booking_date and booking_time
      final busBookings = await SupabaseConfig.client
          .from('bus_service_bookings')
          .select('*, transportation_services(*)')
          .eq('user_id', user.id)
          .inFilter('status', ['confirmed']) // Active bus bookings
          .order('booking_date', ascending: true);

      final now = DateTime.now();

      for (final booking in busBookings) {
        await _checkBusBookingReminders(booking, now);
      }
    } catch (e) {
      print('❌ [Scheduled] Error checking scheduled bus bookings: $e');
    }
  }

  /// Check and send reminders for a specific bus booking
  /// Uses booking_date and booking_time for precise timing
  Future<void> _checkBusBookingReminders(
      Map<String, dynamic> booking, DateTime now) async {
    try {
      // Combine date and time to create full datetime
      final bookingDate = DateTime.parse(booking['booking_date']);
      final bookingTime = booking['booking_time'] as String;
      final timeParts = bookingTime.split(':');
      final scheduledStartTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
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
          booking, minutesUntilStart, hoursUntilStart, daysUntilStart);
    } catch (e) {
      print(
          '❌ [Scheduled] Error checking reminders for bus booking ${booking['id']}: $e');
    }
  }

  /// Send reminder notification if needed
  Future<void> _sendReminderIfNeeded(
    Map<String, dynamic> booking,
    int minutesUntilStart,
    int hoursUntilStart,
    int daysUntilStart,
  ) async {
    final serviceName =
        booking['transportation_services']?['service_name'] ?? 'Bus Service';
    final pickupLocation = booking['pickup_location'] ?? 'Pickup Location';
    final dropoffLocation = booking['dropoff_location'] ?? 'Dropoff Location';
    final status = booking['status'];

    // Check notification flags from database to prevent duplicates
    final notification5minSent = booking['notification_5min_sent'] ?? false;
    final notification10minSent = booking['notification_10min_sent'] ?? false;
    final notification1hourSent = booking['notification_1hour_sent'] ?? false;
    final notificationStartSent = booking['notification_start_sent'] ?? false;
    final notificationDailySent =
        List<String>.from(booking['notification_daily_sent'] ?? []);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Exact start time notification (when bus service starts)
    if (minutesUntilStart <= 0 &&
        minutesUntilStart > -5 &&
        !notificationStartSent) {
      await _sendReminderNotification(
        booking,
        'Your bus service has started!',
        '$serviceName is now active. Please proceed to $pickupLocation.',
        'notification_start_sent',
        true,
      );
    }

    // 5 minutes before start
    if (minutesUntilStart <= 5 &&
        minutesUntilStart > 0 &&
        !notification5minSent) {
      await _sendReminderNotification(
        booking,
        'Bus service starts in 5 minutes!',
        '$serviceName is about to begin. Please head to $pickupLocation.',
        'notification_5min_sent',
        true,
      );
    }

    // 10 minutes before start
    if (minutesUntilStart <= 10 &&
        minutesUntilStart > 5 &&
        !notification10minSent) {
      await _sendReminderNotification(
        booking,
        'Bus service starting soon!',
        '$serviceName will begin in 10 minutes. Route: $pickupLocation to $dropoffLocation',
        'notification_10min_sent',
        true,
      );
    }

    // 1 hour before start
    if (hoursUntilStart <= 1 && hoursUntilStart > 0 && !notification1hourSent) {
      await _sendReminderNotification(
        booking,
        'Bus service reminder - 1 hour',
        '$serviceName will start in 1 hour. Route: $pickupLocation to $dropoffLocation',
        'notification_1hour_sent',
        true,
      );
    }

    // Daily reminders for bus bookings scheduled days in advance
    if (daysUntilStart > 0 && !notificationDailySent.contains(today)) {
      final dayText = daysUntilStart == 1 ? '1 day' : '$daysUntilStart days';
      await _sendReminderNotification(
        booking,
        'Bus booking reminder',
        '$serviceName will start in $dayText. Route: $pickupLocation to $dropoffLocation. Status: ${status.toUpperCase()}',
        'notification_daily_sent',
        [...notificationDailySent, today],
      );
    }
  }

  /// Send a reminder notification
  Future<void> _sendReminderNotification(
    Map<String, dynamic> booking,
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
        payload: 'scheduled_bus:${booking['id']}',
      );

      // Update notification flag in database
      await SupabaseConfig.client.from('bus_service_bookings').update(
          {notificationField: notificationValue}).eq('id', booking['id']);

      // Store notification in database for customer
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': booking['user_id'],
        'title': title,
        'message': body,
        'type': 'scheduled_bus_reminder',
        'bus_booking_id': booking['id'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Also notify admins for bus service management
      await _sendAdminNotificationForBusBooking(booking, title, body);

      print(
          '📱 [Scheduled] Sent reminder: $title for bus booking ${booking['id']}');
    } catch (e) {
      print('❌ [Scheduled] Error sending bus reminder notification: $e');
    }
  }

  /// Get upcoming scheduled bus bookings for a user
  Future<List<Map<String, dynamic>>> getUpcomingScheduledBusBookings(
      String userId) async {
    try {
      final now = DateTime.now();

      final busBookings = await SupabaseConfig.client
          .from('bus_service_bookings')
          .select('*, transportation_services(*)')
          .eq('user_id', userId)
          .inFilter('status', ['confirmed'])
          .gte('booking_date', now.toIso8601String().split('T')[0])
          .order('booking_date', ascending: true);

      final upcoming = <Map<String, dynamic>>[];

      for (final booking in busBookings) {
        final bookingDate = DateTime.parse(booking['booking_date']);
        final bookingTime = booking['booking_time'] as String;
        final timeParts = bookingTime.split(':');
        final scheduledStartTime = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        upcoming.add({
          ...booking,
          'minutes_until_start': scheduledStartTime.difference(now).inMinutes,
          'hours_until_start': scheduledStartTime.difference(now).inHours,
          'days_until_start': scheduledStartTime.difference(now).inDays,
        });
      }

      return upcoming;
    } catch (e) {
      print('❌ [Scheduled] Error fetching upcoming bus bookings: $e');
      return [];
    }
  }

  /// Send admin notification for bus bookings
  Future<void> _sendAdminNotificationForBusBooking(
    Map<String, dynamic> booking,
    String title,
    String body,
  ) async {
    try {
      // Get all admin users
      final admins = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('user_type', 'admin');

      for (final admin in admins) {
        await SupabaseConfig.client.from('notifications').insert({
          'user_id': admin['id'],
          'title': 'Admin: $title',
          'message': 'Bus Booking ID: ${booking['id']} - $body',
          'type': 'scheduled_bus_reminder',
          'bus_booking_id': booking['id'],
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      print(
          '📱 [Scheduled] Sent admin notification for bus booking ${booking['id']}');
    } catch (e) {
      print(
          '❌ [Scheduled] Error sending admin notification for bus booking: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
    print('⏰ [Scheduled] Scheduled bus notification service disposed');
  }
}
