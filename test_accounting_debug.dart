// Quick debug script to test accounting queries
// Run with: dart run test_accounting_debug.dart

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🔍 Testing Provider Accounting Queries\n');

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://fhqxzchuwlqetrhbqlhw.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZocXh6Y2h1d2xxZXRyaGJxbGh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1MDM0NTYsImV4cCI6MjA2MDA3OTQ1Nn0.FWDRlFLN1Zd1wNR9s_OUIhVlH2sFh7KPFNwHZ2kNMCY',
    );

    final supabase = Supabase.instance.client;

    // Test 1: Check users table
    print('Test 1: Checking users table...');
    final allUsers = await supabase
        .from('users')
        .select('id, full_name, user_type, is_verified')
        .limit(10);
    print('   Total users found: ${allUsers.length}');
    for (var user in allUsers) {
      print(
          '   - ${user['full_name']}: type=${user['user_type']}, verified=${user['is_verified']}');
    }

    // Test 2: Check runners specifically
    print('\nTest 2: Checking runners/verified users...');
    final runners = await supabase
        .from('users')
        .select('id, full_name, user_type, is_verified')
        .or('user_type.eq.runner,is_verified.eq.true');
    print('   Runners/verified found: ${runners.length}');

    // Test 3: Check transportation bookings
    print('\nTest 3: Checking transportation_bookings...');
    final transportBookings = await supabase
        .from('transportation_bookings')
        .select('id, driver_id, runner_id, status, estimated_price')
        .limit(5);
    print('   Transportation bookings found: ${transportBookings.length}');
    for (var booking in transportBookings) {
      print('   - ID: ${booking['id']}');
      print('     driver_id: ${booking['driver_id']}');
      print('     runner_id: ${booking['runner_id']}');
      print('     status: ${booking['status']}');
      print('     price: ${booking['estimated_price']}');
    }

    // Test 4: Check bus service bookings
    print('\nTest 4: Checking bus_service_bookings...');
    final busBookings = await supabase
        .from('bus_service_bookings')
        .select('id, runner_id, status, estimated_price')
        .limit(5);
    print('   Bus bookings found: ${busBookings.length}');
    for (var booking in busBookings) {
      print('   - ID: ${booking['id']}');
      print('     runner_id: ${booking['runner_id']}');
      print('     status: ${booking['status']}');
      print('     price: ${booking['estimated_price']}');
    }

    // Test 5: Check contract bookings
    print('\nTest 5: Checking contract_bookings...');
    final contractBookings = await supabase
        .from('contract_bookings')
        .select('id, driver_id, status, estimated_price')
        .limit(5);
    print('   Contract bookings found: ${contractBookings.length}');

    // Test 6: Check payments
    print('\nTest 6: Checking payments...');
    final payments = await supabase
        .from('payments')
        .select('id, runner_id, status, amount')
        .limit(5);
    print('   Payments found: ${payments.length}');
    for (var payment in payments) {
      print('   - ID: ${payment['id']}');
      print('     runner_id: ${payment['runner_id']}');
      print('     status: ${payment['status']}');
      print('     amount: ${payment['amount']}');
    }

    // Test 7: Match a runner with their bookings
    if (runners.isNotEmpty && transportBookings.isNotEmpty) {
      print('\nTest 7: Finding matching runner-booking pairs...');

      for (var booking in transportBookings) {
        final driverId = booking['driver_id'];
        if (driverId != null) {
          final runner = runners.firstWhere(
            (r) => r['id'] == driverId,
            orElse: () => {},
          );
          if (runner.isNotEmpty) {
            print(
                '   ✅ MATCH: ${runner['full_name']} has transportation booking ${booking['id']}');
          } else {
            print('   ❌ NO MATCH: driver_id $driverId not in runners list');
          }
        }
      }

      for (var booking in busBookings) {
        final runnerId = booking['runner_id'];
        if (runnerId != null) {
          final runner = runners.firstWhere(
            (r) => r['id'] == runnerId,
            orElse: () => {},
          );
          if (runner.isNotEmpty) {
            print(
                '   ✅ MATCH: ${runner['full_name']} has bus booking ${booking['id']}');
          } else {
            print('   ❌ NO MATCH: runner_id $runnerId not in runners list');
          }
        }
      }
    }

    print('\n✅ Debug complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
