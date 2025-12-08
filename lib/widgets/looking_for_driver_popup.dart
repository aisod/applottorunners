import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/global_transportation_popup_service.dart';
import 'package:lotto_runners/services/immediate_transportation_service.dart';
import 'package:lotto_runners/services/transportation_acceptance_notification_service.dart';

/// Popup widget that shows "Looking for a driver" when customer requests immediate transportation
class LookingForDriverPopup extends StatefulWidget {
  final String bookingId;
  final String pickupLocation;
  final String dropoffLocation;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onDriverFound;

  const LookingForDriverPopup({
    super.key,
    required this.bookingId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.onRetry,
    this.onCancel,
    this.onDriverFound,
  });

  @override
  State<LookingForDriverPopup> createState() => _LookingForDriverPopupState();
}

class _LookingForDriverPopupState extends State<LookingForDriverPopup>
    with TickerProviderStateMixin {
  Timer? _timeoutTimer;
  Timer? _checkTimer;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  int _timeRemaining =
      35; // 35 seconds timeout (5 second buffer for auto-cleanup)
  bool _isChecking = true;
  bool _hasTimedOut = false;
  bool _hasShownAcceptanceNotification =
      false; // Prevent duplicate notifications

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Start checking for driver
    _startDriverSearch();
  }

  void _startDriverSearch() {
    // Start timeout timer
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeRemaining--;
        });

        if (_timeRemaining <= 0) {
          _handleTimeout();
          timer.cancel();
        }
      }
    });

    // Start checking for driver acceptance
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForDriverAcceptance();
    });

    // Start cleanup timer to delete expired bookings (less frequent to avoid conflicts)
    Timer.periodic(const Duration(seconds: 15), (timer) {
      ImmediateTransportationService.cleanupExpiredBookings();
    });
  }

  Future<void> _checkForDriverAcceptance() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) {
      print('🔍 [Acceptance] Widget unmounted, skipping check');
      return;
    }

    // Don't check if we've already shown the acceptance notification
    if (_hasShownAcceptanceNotification) {
      print(
          '🔍 [Acceptance] Acceptance notification already shown, skipping check');
      return;
    }

    try {
      // Check if this is a pending ID (starts with "pending_transportation_")
      if (widget.bookingId.startsWith('pending_transportation_')) {
        // For pending IDs, we need to check both pending bookings AND accepted bookings
        // because once accepted, the booking might be removed from pending list

        // First check pending bookings
        final pendingBookings =
            await ImmediateTransportationService.getPendingBookings();

        // Check if still mounted after async operation
        if (!mounted) {
          print(
              '🔍 [Acceptance] Widget unmounted during pending bookings query, aborting');
          return;
        }
        print(
            '🔍 [Acceptance] Looking for booking with pickup: ${widget.pickupLocation}');
        print(
            '🔍 [Acceptance] Available pending bookings: ${pendingBookings.map((b) => '${b['id']} - ${b['pickup_location']} to ${b['dropoff_location']} - ${b['status']}').toList()}');

        var matchingBooking = pendingBookings.firstWhere(
          (booking) =>
              booking['pickup_location'] == widget.pickupLocation &&
              booking['dropoff_location'] == widget.dropoffLocation,
          orElse: () => <String, dynamic>{},
        );

        // If not found in pending, check accepted bookings for this customer
        if (matchingBooking.isEmpty) {
          print(
              '🔍 [Acceptance] Not found in pending, checking accepted bookings...');
          final userId = SupabaseConfig.currentUser?.id;
          if (userId != null) {
            final myBookings = await SupabaseConfig.client
                .from('transportation_bookings')
                .select('*')
                .eq('user_id', userId)
                .eq('is_immediate', true)
                .order('created_at', ascending: false);

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during async operation, aborting');
              return;
            }
            final acceptedBookings = myBookings
                .where((booking) =>
                    booking['pickup_location'] == widget.pickupLocation &&
                    booking['dropoff_location'] == widget.dropoffLocation &&
                    booking['status'] == 'accepted' &&
                    booking['is_immediate'] == true)
                .toList();

            print(
                '🔍 [Acceptance] Accepted immediate bookings: ${acceptedBookings.map((b) => '${b['id']} - ${b['pickup_location']} to ${b['dropoff_location']} - ${b['status']} - ${b['driver_id']}').toList()}');

            if (acceptedBookings.isNotEmpty) {
              matchingBooking = acceptedBookings.first;
              print(
                  '🔍 [Acceptance] Found accepted booking: ${matchingBooking['id']}');
            }
          }
        }

        print(
            '🔍 [Acceptance] Matching booking found: ${matchingBooking.isNotEmpty ? 'YES' : 'NO'}');
        if (matchingBooking.isNotEmpty) {
          print(
              '🔍 [Acceptance] Booking status: ${matchingBooking['status']}, Driver ID: ${matchingBooking['driver_id']}');
        }

        if (matchingBooking.isNotEmpty &&
            matchingBooking['status'] == 'accepted' &&
            matchingBooking['driver_id'] != null &&
            !_hasShownAcceptanceNotification) {
          // Driver found! Stop the timer and show notification
          _checkTimer?.cancel();
          _timeoutTimer?.cancel();
          _hasShownAcceptanceNotification = true; // Mark as shown

          if (mounted) {
            setState(() {
              _isChecking = false;
              _hasTimedOut = false; // Show success state
            });

            // Stop animations immediately
            _pulseController.stop();
            _rotationController.stop();

            // Get driver information
            final driverId = matchingBooking['driver_id'];
            final driverInfo = await SupabaseConfig.client
                .from('users')
                .select('full_name')
                .eq('id', driverId)
                .single();

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during driver info fetch, aborting');
              return;
            }

            final driverName = driverInfo['full_name'] ?? 'Unknown Driver';

            // Show acceptance notification
            TransportationAcceptanceNotificationService.instance
                .showAcceptanceNotification(
              bookingId: matchingBooking['id'],
              serviceName: 'Transportation Service',
              driverName: driverName,
            );

            // Show success message briefly
            await Future.delayed(const Duration(milliseconds: 1000));

            if (mounted) {
              widget.onDriverFound?.call();
            }
          }
        } else if (matchingBooking.isEmpty) {
          // Booking was deleted from database (expired)
          // Only treat as timeout if we're close to the end of our timer
          if (_timeRemaining <= 5) {
            if (mounted) {
              setState(() {
                _isChecking = false;
                _hasTimedOut = true;
              });

              // Stop animations
              _pulseController.stop();
              _rotationController.stop();
            }
          }
          // If we still have time left, continue checking (booking might be recreated)
        }
      } else {
        // For regular UUIDs, query directly
        final booking = await SupabaseConfig.client
            .from('transportation_bookings')
            .select('status, driver_id')
            .eq('id', widget.bookingId)
            .maybeSingle();

        // Check if still mounted after async operation
        if (!mounted) {
          print(
              '🔍 [Acceptance] Widget unmounted during booking query, aborting');
          return;
        }

        // Check if booking exists (might have been auto-deleted)
        if (booking == null) {
          // Booking was deleted, only treat as timeout if close to end
          if (_timeRemaining <= 5 && mounted) {
            setState(() {
              _isChecking = false;
              _hasTimedOut = true;
            });
            _pulseController.stop();
            _rotationController.stop();
          }
          return;
        }

        if (booking['status'] == 'accepted' &&
            booking['driver_id'] != null &&
            !_hasShownAcceptanceNotification) {
          // Driver found! Stop the timer and show notification
          _checkTimer?.cancel();
          _timeoutTimer?.cancel();
          _hasShownAcceptanceNotification = true; // Mark as shown

          if (mounted) {
            setState(() {
              _isChecking = false;
              _hasTimedOut = false; // Show success state
            });

            // Stop animations immediately
            _pulseController.stop();
            _rotationController.stop();

            // Get driver information
            final driverId = booking['driver_id'];
            final driverInfo = await SupabaseConfig.client
                .from('users')
                .select('full_name')
                .eq('id', driverId)
                .single();

            // Check if still mounted after async operation
            if (!mounted) {
              print(
                  '🔍 [Acceptance] Widget unmounted during driver info fetch, aborting');
              return;
            }

            final driverName = driverInfo['full_name'] ?? 'Unknown Driver';

            // Show acceptance notification
            TransportationAcceptanceNotificationService.instance
                .showAcceptanceNotification(
              bookingId: widget.bookingId,
              serviceName: 'Transportation Service',
              driverName: driverName,
            );

            // Show success message briefly
            await Future.delayed(const Duration(milliseconds: 1000));

            if (mounted) {
              widget.onDriverFound?.call();
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for driver acceptance: $e');

      // Only handle errors if widget is still mounted
      if (!mounted) {
        print(
            '🔍 [Acceptance] Widget unmounted during error handling, aborting');
        return;
      }

      // If booking doesn't exist (deleted), only treat as timeout if close to end
      if (e.toString().contains('No rows found') ||
          e.toString().contains('PGRST116') ||
          e.toString().contains('multiple (or no) rows returned')) {
        print(
            '🔍 [Acceptance] Booking not found (likely auto-deleted): ${e.toString()}');
        if (_timeRemaining <= 5 && mounted) {
          setState(() {
            _isChecking = false;
            _hasTimedOut = true;
          });

          // Stop animations
          _pulseController.stop();
          _rotationController.stop();
        }
      } else {
        // Log other errors for debugging
        print('🔍 [Acceptance] Unexpected error: ${e.toString()}');
      }
    }
  }

  void _handleTimeout() {
    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasTimedOut = true;
      });

      // Stop animations
      _pulseController.stop();
      _rotationController.stop();

      // Auto-dismiss this booking after timeout to prevent it from showing again
      // This ensures that if user doesn't retry, the booking won't keep appearing
      Timer(const Duration(seconds: 5), () {
        if (mounted && _hasTimedOut) {
          GlobalTransportationPopupService.instance
              .dismissBookingById(widget.bookingId);
        }
      });
    }
  }

  void _handleRetry() {
    if (mounted) {
      setState(() {
        _isChecking = true;
        _hasTimedOut = false;
        _timeRemaining = 35;
      });

      // Restart animations
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();

      // Restart search
      _startDriverSearch();

      widget.onRetry?.call();
    }
  }

  void _handleCancel() {
    // If the timer has timed out and user cancels, mark this booking as dismissed
    // to prevent it from showing again in the global popup service
    if (_hasTimedOut) {
      GlobalTransportationPopupService.instance
          .dismissBookingById(widget.bookingId);
    }
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _checkTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Looking for a Driver',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Animated search icon
              if (_isChecking) ...[
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_pulseAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Status text
                Text(
                  'Searching for available drivers...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Time remaining
                Text(
                  'Time remaining: $_timeRemaining seconds',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              // Timeout state
              if (_hasTimedOut) ...[
                const Icon(
                  Icons.access_time,
                  size: 60,
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),

                Text(
                  'No driver found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Would you like to retry or cancel your request?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success state (briefly shown)
              if (!_isChecking && !_hasTimedOut) ...[
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'Driver Found!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A driver has accepted your request.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
