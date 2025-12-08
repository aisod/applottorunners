import 'dart:async';
import 'package:lotto_runners/supabase/supabase_config.dart';

class TransportationNotificationService {
  static StreamSubscription? _bookingsSubscription;

  /// Setup realtime subscription for transportation bookings
  static void setupTransportationNotifications() {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    // Clean up existing subscription
    _bookingsSubscription?.cancel();

    // Listen for new transportation bookings
    _bookingsSubscription = SupabaseConfig.client
        .from('transportation_bookings')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      _handleNewTransportationBookings(data, user.id);
    });

    print('🚗 Transportation notifications setup for user: ${user.id}');
  }

  /// Handle new transportation bookings and notify relevant runners
  static void _handleNewTransportationBookings(
      List<Map<String, dynamic>> bookings, String userId) async {
    try {
      // Get the user's runner profile to check if they're a runner
      final profile = await SupabaseConfig.getCurrentUserProfile();
      if (profile?['user_type'] != 'runner') return;

      // Check if user has an approved runner application
      final runnerApp = await _getRunnerApplication(userId);
      if (runnerApp == null || runnerApp['verification_status'] != 'approved') {
        return;
      }

      final runnerVehicleType = runnerApp['vehicle_type'] ?? '';

      for (final booking in bookings) {
        if (booking['status'] == 'pending' &&
            booking['driver_id'] == null &&
            booking['is_immediate'] == true) {
          final bookingVehicleType = booking['vehicle_type']?['name'] ?? '';

          // Check if vehicle types match (or if runner can accept any vehicle)
          if (_vehicleTypesMatch(bookingVehicleType, runnerVehicleType)) {
            // This runner can accept this booking - the dashboard will handle the popup
            print(
                '🎯 New ride request available for runner: $bookingVehicleType');
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error handling transportation bookings: $e');
    }
  }

  /// Get runner application for a user
  static Future<Map<String, dynamic>?> _getRunnerApplication(
      String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('runner_applications')
          .select('*')
          .eq('user_id', userId)
          .eq('verification_status', 'approved')
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Check if vehicle types match for booking assignment
  static bool _vehicleTypesMatch(
      String bookingVehicleType, String runnerVehicleType) {
    if (bookingVehicleType.isEmpty || runnerVehicleType.isEmpty) {
      return true; // Accept if either is unspecified
    }

    // Case-insensitive matching
    return bookingVehicleType.toLowerCase() == runnerVehicleType.toLowerCase();
  }

  /// Send notification when a runner accepts a transportation booking
  static Future<void> notifyBookingAccepted(
      Map<String, dynamic> booking, String runnerId) async {
    try {
      final customerId = booking['user_id'];

      // Notify the customer
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': customerId,
        'title': 'Ride Request Accepted',
        'message': 'A runner has accepted your transportation request',
        'type': 'transportation_booking',
        'booking_id': booking['id'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update booking status
      await SupabaseConfig.client.from('transportation_bookings').update({
        'status': 'accepted',
        'driver_id': runnerId,
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', booking['id']);

      print('✅ Booking accepted notification sent');
    } catch (e) {
      print('❌ Error sending booking accepted notification: $e');
    }
  }

  /// Cleanup subscriptions
  static void dispose() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
  }
}
