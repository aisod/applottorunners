import 'dart:async';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// Service to handle scheduled transportation notifications with different reminder intervals
/// Uses booking_date and booking_time columns for precise timing
class ScheduledTransportationNotificationService {
  static ScheduledTransportationNotificationService? _instance;
  static ScheduledTransportationNotificationService get instance =>
      _instance ??= ScheduledTransportationNotificationService._();

  ScheduledTransportationNotificationService._();

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (!_isInitialized) {
      _startScheduledCheck();
      _isInitialized = true;
      print('🚗 Scheduled transportation notification service initialized');
    }
  }

  /// Start periodic checking for scheduled transportation bookings
  void _startScheduledCheck() {
    _checkTimer?.cancel();

    // Check every 5 minutes for scheduled transportation bookings
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkScheduledTransportationBookings();
    });

    print(
        '🚗 [Scheduled] Starting scheduled transportation checks every 5 minutes');
  }

  /// Check for scheduled transportation bookings and send appropriate notifications
  Future<void> _checkScheduledTransportationBookings() async {
    try {
      print('🔍 [Scheduled] Checking for scheduled transportation bookings...');

      // Get all scheduled transportation bookings that are confirmed or pending
      final bookings = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('''
            *,
            transportation_services!inner(
              name
            ),
            users!transportation_bookings_user_id_fkey(full_name, user_type)
          ''')
          .inFilter('status', ['pending', 'confirmed'])
          .order('booking_date', ascending: true)
          .order('booking_time', ascending: true);

      final now = DateTime.now();

      for (final booking in bookings) {
        await _checkTransportationReminders(booking, now);
      }
    } catch (e) {
      print(
          '❌ [Scheduled] Error checking scheduled transportation bookings: $e');
    }
  }

  /// Check and send reminders for a specific transportation booking
  /// Uses booking_date and booking_time for precise timing
  Future<void> _checkTransportationReminders(
      Map<String, dynamic> booking, DateTime now) async {
    try {
      final bookingDate = DateTime.parse(booking['booking_date']);
      final bookingTime = booking['booking_time'] as String;

      // Parse time (format: HH:MM:SS)
      final timeParts = bookingTime.split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Calculate time differences from booking datetime
      final timeUntilStart = bookingDateTime.difference(now);
      final minutesUntilStart = timeUntilStart.inMinutes;
      final hoursUntilStart = timeUntilStart.inHours;
      final daysUntilStart = timeUntilStart.inDays;

      // Send notifications based on time intervals
      await _sendTransportationReminderIfNeeded(
          booking, minutesUntilStart, hoursUntilStart, daysUntilStart);
    } catch (e) {
      print(
          '❌ [Scheduled] Error checking reminders for transportation booking ${booking['id']}: $e');
    }
  }

  /// Send reminder notification if needed
  Future<void> _sendTransportationReminderIfNeeded(
    Map<String, dynamic> booking,
    int minutesUntilStart,
    int hoursUntilStart,
    int daysUntilStart,
  ) async {
    final serviceName =
        booking['transportation_services']?['name'] ?? 'Transportation Service';
    final providerName = ''; // Provider relationship doesn't exist
    final vehicleType = ''; // Vehicle type relationship doesn't exist
    final status = booking['status'];
    final customerName = booking['users']?['full_name'] ?? 'Customer';
    final customerType = booking['users']?['user_type'] ?? 'individual';

    // Check if this is a bus service for admin notifications
    final isBusService = _isBusService(booking);

    // Check notification flags from database to prevent duplicates
    final notification5minSent = booking['notification_5min_sent'] ?? false;
    final notification10minSent = booking['notification_10min_sent'] ?? false;
    final notification1hourSent = booking['notification_1hour_sent'] ?? false;
    final notification1daySent = booking['notification_1day_sent'] ?? false;
    final notificationStartSent = booking['notification_start_sent'] ?? false;
    final notificationDailySent =
        List<String>.from(booking['notification_daily_sent'] ?? []);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Exact start time notification (when transportation starts)
    if (minutesUntilStart <= 0 &&
        minutesUntilStart > -5 &&
        !notificationStartSent) {
      await _sendTransportationReminderNotification(
        booking,
        'Your transportation has started!',
        '$serviceName is now active. Please be ready for pickup.',
        'notification_start_sent',
        true,
        ['customer', if (isBusService) 'admin', 'driver'],
      );
    }

    // 5 minutes before start
    if (minutesUntilStart <= 5 &&
        minutesUntilStart > 0 &&
        !notification5minSent) {
      await _sendTransportationReminderNotification(
        booking,
        'Transportation starts in 5 minutes!',
        '$serviceName pickup is in 5 minutes. Please be ready.',
        'notification_5min_sent',
        true,
        ['customer', if (isBusService) 'admin', 'driver'],
      );
    }

    // 10 minutes before start
    if (minutesUntilStart <= 10 &&
        minutesUntilStart > 5 &&
        !notification10minSent) {
      await _sendTransportationReminderNotification(
        booking,
        'Transportation starting soon!',
        '$serviceName pickup is in 10 minutes.',
        'notification_10min_sent',
        true,
        ['customer', if (isBusService) 'admin', 'driver'],
      );
    }

    // 1 hour before start
    if (hoursUntilStart <= 1 && hoursUntilStart > 0 && !notification1hourSent) {
      await _sendTransportationReminderNotification(
        booking,
        'Transportation reminder - 1 hour',
        '$serviceName pickup is in 1 hour. Please prepare.',
        'notification_1hour_sent',
        true,
        ['customer', if (isBusService) 'admin', 'driver'],
      );
    }

    // 1 day before start
    if (daysUntilStart <= 1 && daysUntilStart > 0 && !notification1daySent) {
      await _sendTransportationReminderNotification(
        booking,
        'Transportation reminder - 1 day',
        '$serviceName pickup is tomorrow. Please confirm your booking.',
        'notification_1day_sent',
        true,
        ['customer', if (isBusService) 'admin', 'driver'],
      );
    }

    // Daily reminders for bookings scheduled days in advance
    if (daysUntilStart > 1 && !notificationDailySent.contains(today)) {
      final dayText = daysUntilStart == 1 ? '1 day' : '$daysUntilStart days';
      await _sendTransportationReminderNotification(
        booking,
        'Scheduled transportation reminder',
        '$serviceName pickup is in $dayText. Status: ${status.toUpperCase()}',
        'notification_daily_sent',
        [...notificationDailySent, today],
        ['customer', if (isBusService) 'admin'],
      );
    }
  }

  /// Send a reminder notification for transportation
  Future<void> _sendTransportationReminderNotification(
    Map<String, dynamic> booking,
    String title,
    String body,
    String notificationField,
    dynamic notificationValue,
    List<String> recipientTypes,
  ) async {
    try {
      final bookingId = booking['id'];
      final customerId = booking['user_id'];
      final driverId = booking['driver_id'];
      final serviceName = booking['transportation_services']?['name'] ??
          'Transportation Service';

      // Send notifications to different user types
      for (final recipientType in recipientTypes) {
        String userId;
        String customTitle = title;
        String customBody = body;

        switch (recipientType) {
          case 'customer':
            userId = customerId;
            break;
          case 'driver':
            if (driverId != null) {
              userId = driverId;
              customTitle = 'Driver: $title';
              customBody = 'Customer: $body';
            } else {
              continue; // Skip if no driver assigned
            }
            break;
          case 'admin':
            // Get admin users
            final admins = await SupabaseConfig.client
                .from('users')
                .select('id')
                .eq('user_type', 'admin');

            for (final admin in admins) {
              await _sendNotificationToUser(
                admin['id'],
                'Admin: $title',
                'Booking ID: $bookingId - $body',
                'scheduled_transportation_reminder',
                bookingId,
              );
            }
            continue; // Skip the regular notification sending
          default:
            continue;
        }

        // Send notification to the specific user
        await _sendNotificationToUser(
          userId,
          customTitle,
          customBody,
          'scheduled_transportation_reminder',
          bookingId,
        );
      }

      // Send local notification for current user if they're the customer
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser?.id == customerId) {
        await NotificationService.showNotification(
          title: title,
          body: body,
          payload: 'scheduled_transportation:$bookingId',
        );
      }

      // Update notification flag in database
      await SupabaseConfig.client
          .from('transportation_bookings')
          .update({notificationField: notificationValue}).eq('id', bookingId);

      print(
          '📱 [Scheduled] Sent transportation reminder: $title for booking $bookingId');
    } catch (e) {
      print(
          '❌ [Scheduled] Error sending transportation reminder notification: $e');
    }
  }

  /// Send notification to a specific user
  Future<void> _sendNotificationToUser(
    String userId,
    String title,
    String body,
    String type,
    String bookingId,
  ) async {
    try {
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': body,
        'type': type,
        'booking_id': bookingId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ [Scheduled] Error sending notification to user $userId: $e');
    }
  }

  /// Check if a transportation booking is for a bus service
  bool _isBusService(Map<String, dynamic> booking) {
    try {
      // Check service name for bus-related keywords
      final serviceName = booking['transportation_services']?['name']
              ?.toString()
              .toLowerCase() ??
          '';

      // Check for bus-related keywords in service name
      final busKeywords = ['bus', 'coach', 'shuttle bus', 'intercity', 'route'];
      final hasBusKeyword =
          busKeywords.any((keyword) => serviceName.contains(keyword));

      return hasBusKeyword;
    } catch (e) {
      print('❌ Error checking if service is bus service: $e');
      return false;
    }
  }

  /// Cleanup the service
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isInitialized = false;
    print('🚗 Scheduled transportation notification service disposed');
  }
}
