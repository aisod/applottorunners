import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/new_ride_request_popup.dart';
import 'package:lotto_runners/services/notification_service.dart';

/// In-page ride request manager that shows popups within the current page
/// and guarantees a booking is shown only once per session.
class GlobalRidePopupService extends ChangeNotifier {
  static GlobalRidePopupService? _instance;
  static GlobalRidePopupService get instance =>
      _instance ??= GlobalRidePopupService._();

  GlobalRidePopupService._();

  Timer? _checkTimer;
  bool _isInitialized = false;

  Map<String, dynamic>? _currentRequest;
  Map<String, dynamic>? get currentRequest => _currentRequest;

  /// Track bookings to avoid repeating
  final Set<String> _dismissedBookings = {};
  final Set<String> _declinedBookings = {};
  final Map<String, DateTime> _handledBookings = {};
  final Duration _handledCooldown = const Duration(hours: 6);

  void start() {
    if (_isInitialized) return;
    _isInitialized = true;
    _startPolling();
    print('🌍 Ride request service started');
  }

  /// Initialize the service with context (for compatibility)
  void initialize(BuildContext context) {
    start();
  }

  /// Update context (for compatibility)
  void updateContext(BuildContext context) {
    // Context is not needed for this service, but keeping for compatibility
  }

  void _startPolling() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      _cleanupHandled();
      await _checkForNewRideRequests();
    });
  }

  void _cleanupHandled() {
    if (_handledBookings.isEmpty) return;
    final now = DateTime.now();
    _handledBookings.removeWhere(
        (key, timestamp) => now.difference(timestamp) > _handledCooldown);
  }

  Future<void> _checkForNewRideRequests() async {
    try {
      if (_currentRequest != null) return; // already showing

      final user = SupabaseConfig.currentUser;
      if (user == null) return;

      // Ensure the user is an approved runner
      final runnerApp = await SupabaseConfig.client
          .from('runner_applications')
          .select('vehicle_type, verification_status')
          .eq('user_id', user.id)
          .eq('verification_status', 'approved')
          .maybeSingle();
      if (runnerApp == null) return;

      final runnerVehicleType = (runnerApp['vehicle_type'] ?? '').toString();

      final bookings = await SupabaseConfig.client
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

      for (final booking in bookings) {
        final bookingId = (booking['id'] ?? '').toString();
        final bookingVehicleType =
            (booking['vehicle_type']?['name'] ?? '').toString().toLowerCase();

        final matchesVehicle = runnerVehicleType.isEmpty ||
            bookingVehicleType.isEmpty ||
            bookingVehicleType == runnerVehicleType.toLowerCase();
        if (!matchesVehicle) continue;

        if (_dismissedBookings.contains(bookingId) ||
            _declinedBookings.contains(bookingId)) {
          continue;
        }

        final lastHandled = _handledBookings[bookingId];
        if (lastHandled != null &&
            DateTime.now().difference(lastHandled) <= _handledCooldown) {
          continue;
        }

        // show this booking
        _currentRequest = booking;
        notifyListeners();
        break;
      }
    } catch (e) {
      print('❌ [Ride] Error checking for ride requests: $e');
    }
  }

  Future<void> acceptCurrent(BuildContext context) async {
    final booking = _currentRequest;
    if (booking == null) return;
    try {
      await SupabaseConfig.client.from('transportation_bookings').update({
        'driver_id': SupabaseConfig.currentUser?.id,
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', booking['id']);

      await NotificationService.showNotification(
        title: 'Ride Accepted!',
        body:
            'You have accepted the ride from ${booking['pickup_location']} to ${booking['dropoff_location']}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride request accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _markHandled((booking['id'] ?? '').toString());
      _currentRequest = null;
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to accept ride: $e')),
      );
    }
  }

  void declineCurrent() {
    final booking = _currentRequest;
    if (booking == null) return;
    final id = (booking['id'] ?? '').toString();
    _declinedBookings.add(id);
    _markHandled(id);
    _currentRequest = null;
    notifyListeners();
  }

  void dismissCurrent() {
    final booking = _currentRequest;
    if (booking == null) return;
    final id = (booking['id'] ?? '').toString();
    _dismissedBookings.add(id);
    _markHandled(id);
    _currentRequest = null;
    notifyListeners();
  }

  void _markHandled(String id) {
    _handledBookings[id] = DateTime.now();
  }

  Future<void> manualCheck() => _checkForNewRideRequests();

  void testPopup() {
    _currentRequest = {
      'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
      'user': {'full_name': 'Test Customer'},
      'pickup_location': 'Test Pickup',
      'dropoff_location': 'Test Dropoff',
      'passenger_count': 1,
      'vehicle_type': {'name': 'SUV'},
      'is_immediate': true,
    };
    notifyListeners();
  }

  void disposeService() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isInitialized = false;
    _currentRequest = null;
  }
}

/// Widget host that overlays the popup within the current page only
class GlobalRidePopupWrapper extends StatefulWidget {
  final Widget child;

  const GlobalRidePopupWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalRidePopupWrapper> createState() => _GlobalRidePopupWrapperState();
}

class _GlobalRidePopupWrapperState extends State<GlobalRidePopupWrapper> {
  final GlobalRidePopupService _service = GlobalRidePopupService.instance;

  @override
  void initState() {
    super.initState();
    _service.start();
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.disposeService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _service.currentRequest;
    return Stack(
      children: [
        widget.child,
        if (booking != null)
          NewRideRequestPopup(
            booking: booking,
            onAccept: () => _service.acceptCurrent(context),
            onDecline: _service.declineCurrent,
            onDismiss: _service.dismissCurrent,
          ),
      ],
    );
  }
}
