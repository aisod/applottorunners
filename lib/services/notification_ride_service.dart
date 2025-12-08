import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// Service to handle ride acceptance from notifications
class NotificationRideService {
  /// Accept a ride from a notification
  static Future<bool> acceptRideFromNotification(String bookingId) async {
    try {
      print('📱 Accepting ride from notification: $bookingId');

      final user = SupabaseConfig.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return false;
      }

      // First, check if the booking is still available
      final bookingResponse = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email),
            vehicle_type:vehicle_types(name, description)
          ''')
          .eq('id', bookingId)
          .eq('status', 'pending')
          .filter('driver_id', 'is', null)
          .maybeSingle();

      if (bookingResponse == null) {
        print('❌ Booking not available or already taken');
        await NotificationService.showNotification(
          title: 'Ride No Longer Available',
          body: 'This ride request has already been taken by another runner.',
        );
        return false;
      }

      // Accept the booking
      await SupabaseConfig.client.from('transportation_bookings').update({
        'driver_id': user.id,
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      // Show success notification
      await NotificationService.showNotification(
        title: 'Ride Accepted Successfully!',
        body:
            'From ${bookingResponse['pickup_location']} to ${bookingResponse['dropoff_location']}',
      );

      // Notify the customer
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': bookingResponse['user_id'],
        'title': 'Ride Request Accepted',
        'message': 'A runner has accepted your transportation request',
        'type': 'transportation_booking',
        'booking_id': bookingId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Ride accepted successfully from notification');
      return true;
    } catch (e) {
      print('❌ Error accepting ride from notification: $e');

      await NotificationService.showNotification(
        title: 'Failed to Accept Ride',
        body: 'There was an error accepting the ride. Please try again.',
      );

      return false;
    }
  }

  /// Decline a ride from a notification (just dismiss the notification)
  static Future<void> declineRideFromNotification(String bookingId) async {
    print('❌ Ride declined from notification: $bookingId');

    await NotificationService.showNotification(
      title: 'Ride Declined',
      body: 'You have declined the ride request.',
    );
  }

  /// Show ride details from notification
  static Future<Map<String, dynamic>?> getRideDetails(String bookingId) async {
    try {
      final response =
          await SupabaseConfig.client.from('transportation_bookings').select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
            vehicle_type:vehicle_types(name, description)
          ''').eq('id', bookingId).single();

      return response;
    } catch (e) {
      print('❌ Error fetching ride details: $e');
      return null;
    }
  }
}

/// Widget for notification action buttons
class NotificationRideActions extends StatelessWidget {
  final String bookingId;
  final VoidCallback? onAccepted;
  final VoidCallback? onDeclined;

  const NotificationRideActions({
    super.key,
    required this.bookingId,
    this.onAccepted,
    this.onDeclined,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final success =
                await NotificationRideService.acceptRideFromNotification(
                    bookingId);
            if (success && onAccepted != null) {
              onAccepted!();
            }
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await NotificationRideService.declineRideFromNotification(
                bookingId);
            if (onDeclined != null) {
              onDeclined!();
            }
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Decline'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(100, 36),
          ),
        ),
      ],
    );
  }
}
