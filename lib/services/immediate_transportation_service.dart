import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

/// Service to manage immediate transportation requests that are waiting for driver acceptance
/// These bookings are stored temporarily until a driver accepts them
class ImmediateTransportationService {
  /// Store an immediate transportation request temporarily in database with pending status
  static Future<Map<String, dynamic>> storePendingBooking(
      Map<String, dynamic> bookingData) async {
    try {
      // Remove fields that shouldn't be stored in database
      final cleanData = Map<String, dynamic>.from(bookingData);
      cleanData.remove('id'); // Remove pending ID, let database generate UUID
      cleanData.remove('user'); // Remove user object, only store user_id

      final pendingData = {
        ...cleanData,
        'status':
            'pending', // Use 'pending' status so drivers can see immediate requests
        'is_immediate': true, // Mark as immediate booking
        'passenger_count': 1, // Static passenger count for immediate requests
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Store in database with pending status
      final response = await SupabaseConfig.client
          .from('transportation_bookings')
          .insert(pendingData)
          .select()
          .single();

      print(
          '📝 Stored pending immediate transportation booking in database: ${bookingData['pickup_location']} to ${bookingData['dropoff_location']} with ID: ${response['id']}');

      // Store the database ID in SharedPreferences for tracking
      final prefs = await SharedPreferences.getInstance();
      final pendingIds =
          prefs.getStringList('pending_transportation_booking_ids') ?? [];
      pendingIds.add(response['id']);
      await prefs.setStringList(
          'pending_transportation_booking_ids', pendingIds);

      return response;
    } catch (e) {
      print('❌ Error storing pending transportation booking: $e');
      throw Exception('Failed to store pending transportation booking: $e');
    }
  }

  /// Get all pending immediate transportation bookings from database
  static Future<List<Map<String, dynamic>>> getPendingBookings() async {
    try {
      final response = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
            vehicle_type:vehicle_types(name, description)
          ''')
          .eq('status', 'pending')
          .eq('is_immediate', true)
          .filter('driver_id', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching pending transportation bookings: $e');
      return [];
    }
  }

  /// Get pending bookings from SharedPreferences (for tracking)
  static Future<List<String>> getPendingBookingIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('pending_transportation_booking_ids') ?? [];
    } catch (e) {
      print('❌ Error getting pending transportation booking IDs: $e');
      return [];
    }
  }

  /// Remove a booking ID from pending list
  static Future<void> removePendingBookingId(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingIds =
          prefs.getStringList('pending_transportation_booking_ids') ?? [];
      pendingIds.remove(bookingId);
      await prefs.setStringList(
          'pending_transportation_booking_ids', pendingIds);
    } catch (e) {
      print('❌ Error removing pending transportation booking ID: $e');
    }
  }

  /// Clean up expired immediate transportation bookings (older than 40 seconds)
  /// This function actually deletes expired bookings from the database
  static Future<void> cleanupExpiredBookings() async {
    try {
      final now = DateTime.now();
      final expiredCutoff = now.subtract(const Duration(seconds: 40));

      // Delete expired immediate transportation bookings from database
      await SupabaseConfig.client
          .from('transportation_bookings')
          .delete()
          .eq('status', 'pending')
          .eq('is_immediate', true)
          .filter('driver_id', 'is', null)
          .lt('created_at', expiredCutoff.toIso8601String());

      print(
          '🧹 Deleted expired immediate transportation bookings from database');
    } catch (e) {
      print('❌ Error cleaning up expired transportation bookings: $e');
    }
  }

  /// Generate a unique ID for pending bookings
  static String generatePendingBookingId() {
    return 'pending_transportation_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}
