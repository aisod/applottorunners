import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/widgets/new_ride_request_popup.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:lotto_runners/services/immediate_transportation_service.dart';
import 'package:lotto_runners/utils/app_log.dart';

/// Global service to manage transportation request popups across the entire app
class GlobalTransportationPopupService {
  static GlobalTransportationPopupService? _instance;
  static GlobalTransportationPopupService get instance =>
      _instance ??= GlobalTransportationPopupService._();

  GlobalTransportationPopupService._();

  Timer? _checkTimer;
  BuildContext? _currentContext;
  OverlayEntry? _currentPopup;
  Map<String, dynamic>? _currentRequest;
  bool _isInitialized = false;

  /// Track dismissed transportation requests to prevent re-showing them
  final Set<String> _dismissedBookings = {};
  final Set<String> _declinedBookings = {};

  /// Initialize the service with the current context
  void initialize(BuildContext context) {
    _currentContext = context;
    if (!_isInitialized) {
      _startPolling();
      _isInitialized = true;
      appLog('🌍 Global transportation popup service initialized');
    }
  }

  /// Update context when navigating between pages
  void updateContext(BuildContext context) {
    _currentContext = context;
  }

  /// Start polling for new transportation requests
  void _startPolling() {
    _checkTimer?.cancel();

    appLog(
        '⏱️ [Global] Starting transportation request polling every 30 seconds');
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentContext != null) {
        _checkForNewTransportationRequests();
      } else {
        appLog('❌ [Global] No context available, stopping timer');
        timer.cancel();
      }
    });
  }

  /// Check for new transportation requests
  Future<void> _checkForNewTransportationRequests() async {
    try {
      // Clean up expired immediate transportation bookings first (less frequent)
      // Only cleanup every 3rd check to avoid conflicts
      if (DateTime.now().second % 15 == 0) {
        await ImmediateTransportationService.cleanupExpiredBookings();
      }

      // Skip if popup is already showing
      if (_currentPopup != null) {
        appLog('⏭️ [Global] Skipping check - popup already visible');
        return;
      }

      appLog('🔍 [Global] Checking for new transportation requests...');

      final user = SupabaseConfig.currentUser;
      if (user == null) {
        appLog(
            '❌ [Global] No current user - skipping transportation request check');
        return;
      }

      appLog('👤 [Global] Current user ID: ${user.id}');

      // Check if user has a runner application (approved or pending)
      final runnerApp = await SupabaseConfig.client
          .from('runner_applications')
          .select('verification_status, vehicle_type')
          .eq('user_id', user.id)
          .maybeSingle();

      if (runnerApp == null) {
        appLog(
            '❌ [Global] User has no runner application - skipping global transportation popup service');
        return;
      }

      appLog(
          '👤 [Global] Runner application status: ${runnerApp['verification_status']}');

      // Additional check: Get complete user profile to ensure they're actually a runner
      final userProfile = await SupabaseConfig.getCompleteUserProfile(user.id);
      if (userProfile == null) {
        appLog(
            '❌ [Global] Could not get user profile - skipping global transportation popup service');
        return;
      }

      if (userProfile['user_type'] != 'runner') {
        appLog(
            '❌ [Global] User is not a runner type (${userProfile['user_type']}) - skipping global transportation popup service');
        return;
      }

      appLog(
          '✅ [Global] User is a runner - proceeding with transportation popup service');

      // Get runner's vehicle type for filtering
      final runnerVehicleType = runnerApp['vehicle_type']?.toString() ?? '';
      final hasVehicle = userProfile['has_vehicle'] ?? false;

      appLog(
          '🚗 [Global] Runner vehicle info - has_vehicle: $hasVehicle, vehicle_type: "$runnerVehicleType"');

      // Get pending immediate transportation bookings
      appLog(
          '🔍 [Global] Querying database for immediate transportation bookings...');
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

      appLog(
          '📋 [Global] Found ${bookings.length} pending immediate transportation bookings');

      // Debug: Print details of each booking
      for (var booking in bookings) {
        appLog(
            '📋 [Global] Booking: ${booking['id']} - ${booking['pickup_location']} to ${booking['dropoff_location']} - vehicle_type: "${booking['vehicle_type']?['name']}"');
      }

      // Filter bookings based on vehicle type matching
      final filteredBookings = bookings.where((booking) {
        final bookingVehicleType =
            booking['vehicle_type']?['name']?.toString() ?? '';

        appLog(
            '🔍 [Global] Checking booking: ${booking['pickup_location']} to ${booking['dropoff_location']} - booking vehicle: "$bookingVehicleType"');

        // If booking has no vehicle type, any driver can do it
        if (bookingVehicleType.isEmpty) {
          appLog(
              '✅ [Global] Booking has no vehicle type - showing to all drivers');
          return true;
        }

        // If booking has a vehicle type, only show to drivers with matching vehicle type
        if (runnerVehicleType.isEmpty) {
          appLog(
              '❌ [Global] Driver has no vehicle type, can\'t do vehicle bookings');
          return false; // Driver has no vehicle type, can't do vehicle bookings
        }

        final matches =
            bookingVehicleType.toLowerCase() == runnerVehicleType.toLowerCase();
        appLog(
            '${matches ? "✅" : "❌"} [Global] Vehicle type match: "$bookingVehicleType" vs "$runnerVehicleType"');
        return matches;
      }).toList();

      appLog(
          '🚗 [Global] After vehicle filtering: ${filteredBookings.length} bookings match driver vehicle type: $runnerVehicleType');

      for (final booking in filteredBookings) {
        // Check if this booking was dismissed or declined recently
        final bookingId = booking['id'];
        if (_dismissedBookings.contains(bookingId)) {
          appLog('⏭️ [Global] Skipping dismissed booking: $bookingId');
          continue;
        }
        if (_declinedBookings.contains(bookingId)) {
          appLog('⏭️ [Global] Skipping declined booking: $bookingId');
          continue;
        }

        // Check if this is a new booking (not the current one)
        if (_currentRequest?['id'] != booking['id']) {
          appLog(
              '🎉 [Global] New matching transportation booking found! Showing popup...');
          appLog(
              '🎉 [Global] Booking details: ${booking['pickup_location']} to ${booking['dropoff_location']} - ${booking['vehicle_type']?['name']}');
          _showTransportationRequestPopup(booking);
          break;
        } else {
          appLog(
              '⏭️ [Global] Booking ${booking['id']} is already being shown as popup');
        }
      }
    } catch (e) {
      appLog('❌ [Global] Error checking for transportation requests: $e');
    }
  }

  /// Show transportation request popup globally
  void _showTransportationRequestPopup(Map<String, dynamic> booking) {
    if (_currentContext == null) {
      appLog('❌ [Global] Cannot show popup - no context available');
      return;
    }

    appLog(
        '🚨 [Global] Showing transportation request popup for booking: ${booking['id']}');
    appLog(
        '🚨 [Global] Booking: ${booking['pickup_location']} to ${booking['dropoff_location']}');
    appLog('🚨 [Global] Vehicle type: ${booking['vehicle_type']?['name']}');
    appLog('🚨 [Global] Current context: ${_currentContext.runtimeType}');

    // Hide any existing popup
    hidePopup();

    _currentRequest = booking;

    // Create overlay entry
    _currentPopup = OverlayEntry(
      builder: (context) => NewRideRequestPopup(
        booking: booking,
        onAccept: () => _acceptTransportationRequest(booking),
        onDecline: () => _declineTransportationRequest(),
        onDismiss: () => _dismissTransportationRequest(),
      ),
    );

    // Insert into overlay
    try {
      Overlay.of(_currentContext!).insert(_currentPopup!);
      appLog('✅ [Global] Popup inserted into overlay successfully');
    } catch (e) {
      appLog('❌ [Global] Error inserting popup into overlay: $e');
    }

    // Auto-dismiss after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (_currentPopup != null && _currentRequest?['id'] == booking['id']) {
        hidePopup();
      }
    });
  }

  /// Accept transportation request
  Future<void> _acceptTransportationRequest(
      Map<String, dynamic> booking) async {
    try {
      appLog('✅ [Global] Accepting transportation request: ${booking['id']}');

      await SupabaseConfig.client.from('transportation_bookings').update({
        'driver_id': SupabaseConfig.currentUser!.id,
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', booking['id']);

      // Show success notification
      await NotificationService.showNotification(
        title: 'Ride Accepted!',
        body:
            'You have accepted the ride from ${booking['pickup_location']} to ${booking['dropoff_location']}',
      );

      // Show success snackbar
      if (_currentContext != null) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          const SnackBar(
            content: Text('✅ Transportation request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      hidePopup();
    } catch (e) {
      appLog('❌ [Global] Error accepting transportation request: $e');

      // Show error snackbar
      if (_currentContext != null) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to accept transportation request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Decline transportation request
  void _declineTransportationRequest() {
    appLog('❌ [Global] Transportation request declined');

    // Add to declined bookings to prevent re-showing
    if (_currentRequest != null) {
      final bookingId = _currentRequest!['id'];
      _declinedBookings.add(bookingId);
      appLog('🚫 [Global] Added booking $bookingId to declined list');
    }

    hidePopup();
  }

  /// Dismiss transportation request
  void _dismissTransportationRequest() {
    appLog('👋 [Global] Transportation request dismissed');

    // Add to dismissed bookings to prevent re-showing
    if (_currentRequest != null) {
      final bookingId = _currentRequest!['id'];
      _dismissedBookings.add(bookingId);
      appLog('⏸️ [Global] Added booking $bookingId to dismissed list');
    }

    hidePopup();
  }

  /// Dismiss a specific transportation request by ID (public method)
  void dismissBookingById(String bookingId) {
    appLog('👋 [Global] Dismissing transportation request by ID: $bookingId');
    _dismissedBookings.add(bookingId);
    appLog('⏸️ [Global] Added booking $bookingId to dismissed list');
  }

  /// Hide the current popup
  void hidePopup() {
    _currentPopup?.remove();
    _currentPopup = null;
    _currentRequest = null;
  }

  /// Manual check for new transportation requests (for debug purposes)
  Future<void> manualCheck() async {
    appLog('🔍 [Global] Manual check triggered');
    await _checkForNewTransportationRequests();
  }

  /// Get status information about dismissed/declined bookings (for debug)
  Map<String, dynamic> getDismissedBookingsStatus() {
    return {
      'dismissed_count': _dismissedBookings.length,
      'declined_count': _declinedBookings.length,
      'dismissed_bookings': _dismissedBookings.toList(),
      'declined_bookings': _declinedBookings.toList(),
    };
  }

  /// Clear all dismissed and declined booking tracking
  void clearDismissedBookings() {
    _dismissedBookings.clear();
    _declinedBookings.clear();
    appLog('🧹 [Global] Cleared dismissed and declined booking tracking');
  }

  /// Dispose resources
  void dispose() {
    _checkTimer?.cancel();
    hidePopup();
    clearDismissedBookings();
    _currentContext = null;
    _isInitialized = false;
    appLog('🌍 Global transportation popup service disposed');
  }
}

/// Widget to integrate global transportation popup service into any page
class GlobalTransportationPopupWrapper extends StatefulWidget {
  final Widget child;

  const GlobalTransportationPopupWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalTransportationPopupWrapper> createState() =>
      _GlobalTransportationPopupWrapperState();
}

class _GlobalTransportationPopupWrapperState
    extends State<GlobalTransportationPopupWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalTransportationPopupService.instance.initialize(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GlobalTransportationPopupService.instance.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
