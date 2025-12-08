import 'package:flutter/material.dart';
import 'package:lotto_runners/widgets/new_ride_request_popup.dart';

/// Test widget to demonstrate the ride request popup
class TestRidePopup extends StatelessWidget {
  const TestRidePopup({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample booking data for testing
    final testBooking = {
      'id': 'test-booking-123',
      'user': {
        'full_name': 'John Doe',
        'email': 'john@example.com',
      },
      'vehicle_type': {
        'name': 'SUV',
        'description': 'Sport Utility Vehicle',
      },
      'pickup_location': 'Windhoek Central Business District',
      'dropoff_location': 'Hosea Kutako International Airport',
      'passenger_count': 3,
      'booking_date': null,
      'booking_time': null,
      'special_requests': 'Need assistance with luggage',
      'is_immediate': true,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Ride Request Popup'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Show the popup
            RideRequestOverlay.show(
              context: context,
              booking: testBooking,
              onAccept: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride accepted!')),
                );
              },
              onDecline: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride declined')),
                );
              },
              onDismiss: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride request dismissed')),
                );
              },
            );
          },
          child: const Text('Show Ride Request Popup'),
        ),
      ),
    );
  }
}

/// Test widget to show multiple popup scenarios
class TestRidePopupScenarios extends StatelessWidget {
  const TestRidePopupScenarios({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Ride Popup Scenarios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestButton(
            context,
            'SUV Ride Request',
            _createSUVBooking(),
          ),
          const SizedBox(height: 16),
          _buildTestButton(
            context,
            'Sedan Ride Request',
            _createSedanBooking(),
          ),
          const SizedBox(height: 16),
          _buildTestButton(
            context,
            'Minivan Ride Request',
            _createMinivanBooking(),
          ),
          const SizedBox(height: 16),
          _buildTestButton(
            context,
            'Pickup Truck Ride Request',
            _createPickupBooking(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, String title, Map<String, dynamic> booking) {
    return ElevatedButton(
      onPressed: () {
        RideRequestOverlay.show(
          context: context,
          booking: booking,
          onAccept: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title accepted!')),
            );
          },
          onDecline: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title declined')),
            );
          },
          onDismiss: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title dismissed')),
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(title),
    );
  }

  Map<String, dynamic> _createSUVBooking() {
    return {
      'id': 'suv-booking-001',
      'user': {'full_name': 'Alice Johnson', 'email': 'alice@example.com'},
      'vehicle_type': {'name': 'SUV', 'description': 'Sport Utility Vehicle'},
      'pickup_location': 'Katutura Shopping Centre',
      'dropoff_location': 'Grocery Supermarket',
      'passenger_count': 4,
      'is_immediate': true,
      'status': 'pending',
    };
  }

  Map<String, dynamic> _createSedanBooking() {
    return {
      'id': 'sedan-booking-002',
      'user': {'full_name': 'Bob Smith', 'email': 'bob@example.com'},
      'vehicle_type': {'name': 'Sedan', 'description': 'Comfortable sedan'},
      'pickup_location': 'Windhoek Central',
      'dropoff_location': 'Klein Windhoek',
      'passenger_count': 2,
      'is_immediate': true,
      'status': 'pending',
    };
  }

  Map<String, dynamic> _createMinivanBooking() {
    return {
      'id': 'minivan-booking-003',
      'user': {'full_name': 'Carol Williams', 'email': 'carol@example.com'},
      'vehicle_type': {'name': 'Minivan', 'description': 'Family minivan'},
      'pickup_location': 'Eros Airport',
      'dropoff_location': 'Swakopmund',
      'passenger_count': 6,
      'is_immediate': true,
      'status': 'pending',
    };
  }

  Map<String, dynamic> _createPickupBooking() {
    return {
      'id': 'pickup-booking-004',
      'user': {'full_name': 'David Brown', 'email': 'david@example.com'},
      'vehicle_type': {'name': 'Pickup Truck', 'description': 'Utility pickup'},
      'pickup_location': 'Industrial Area',
      'dropoff_location': 'Construction Site',
      'passenger_count': 2,
      'is_immediate': true,
      'status': 'pending',
    };
  }
}
