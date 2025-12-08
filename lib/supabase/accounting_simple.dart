// Simple accounting test - copy this into supabase_config.dart if needed
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleAccounting {
  static final client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getSimpleEarningsSummary() async {
    try {
      print('\n🔍 === SIMPLE ACCOUNTING TEST ===\n');

      // TEST 1: Get ALL users
      final allUsers =
          await client.from('users').select('id, full_name, email');
      print('TEST 1: Total users in database: ${allUsers.length}');
      if (allUsers.isEmpty) {
        print('   ❌ NO USERS FOUND AT ALL!');
        return [];
      }

      // TEST 2: Get ALL transportation bookings
      final allTransport = await client
          .from('transportation_bookings')
          .select('id, driver_id, estimated_price');
      print('TEST 2: Total transportation bookings: ${allTransport.length}');
      if (allTransport.isNotEmpty) {
        print('   Sample driver_id: ${allTransport[0]['driver_id']}');
        print('   Sample price: ${allTransport[0]['estimated_price']}');
      }

      // TEST 3: Get ALL bus bookings
      final allBus = await client
          .from('bus_service_bookings')
          .select('id, runner_id, estimated_price');
      print('TEST 3: Total bus bookings: ${allBus.length}');
      if (allBus.isNotEmpty) {
        print('   Sample runner_id: ${allBus[0]['runner_id']}');
        print('   Sample price: ${allBus[0]['estimated_price']}');
      }

      // TEST 4: Match users to bookings
      Map<String, Map<String, dynamic>> userBookings = {};

      // Match transportation bookings
      for (var booking in allTransport) {
        final driverId = booking['driver_id'];
        if (driverId != null) {
          if (!userBookings.containsKey(driverId)) {
            userBookings[driverId] = {
              'bookings': [],
              'total': 0.0,
            };
          }
          final price = ((booking['estimated_price'] ?? 0) as num).toDouble();
          userBookings[driverId]!['bookings'].add(booking);
          userBookings[driverId]!['total'] =
              (userBookings[driverId]!['total'] as double) + price;
        }
      }

      // Match bus bookings
      for (var booking in allBus) {
        final runnerId = booking['runner_id'];
        if (runnerId != null) {
          if (!userBookings.containsKey(runnerId)) {
            userBookings[runnerId] = {
              'bookings': [],
              'total': 0.0,
            };
          }
          final price = ((booking['estimated_price'] ?? 0) as num).toDouble();
          userBookings[runnerId]!['bookings'].add(booking);
          userBookings[runnerId]!['total'] =
              (userBookings[runnerId]!['total'] as double) + price;
        }
      }

      print('\nTEST 4: Users with bookings: ${userBookings.length}');

      // Build result
      List<Map<String, dynamic>> result = [];

      for (var userId in userBookings.keys) {
        // Find user details
        final userDetail = allUsers.firstWhere(
          (u) => u['id'] == userId,
          orElse: () => {'id': userId, 'full_name': 'Unknown', 'email': ''},
        );

        final bookingData = userBookings[userId]!;
        final total = (bookingData['total'] as double);
        final count = (bookingData['bookings'] as List).length;

        result.add({
          'runner_id': userId,
          'runner_name': userDetail['full_name'],
          'runner_email': userDetail['email'],
          'runner_phone': '',
          'total_bookings': count,
          'completed_bookings': count,
          'total_revenue': total,
          'total_company_commission': total * 0.3333,
          'total_runner_earnings': total * 0.6667,
          'transportation_count': 0,
          'transportation_revenue': 0.0,
          'transportation_earnings': 0.0,
          'bus_count': 0,
          'bus_revenue': 0.0,
          'bus_earnings': 0.0,
          'contract_count': 0,
          'contract_revenue': 0.0,
          'contract_earnings': 0.0,
          'errand_count': 0,
          'errand_revenue': 0.0,
          'errand_earnings': 0.0,
        });

        print('   ✅ ${userDetail['full_name']}: $count bookings, N\$$total');
      }

      print('\n✅ RESULT: ${result.length} runners with data\n');
      return result;
    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }
}
