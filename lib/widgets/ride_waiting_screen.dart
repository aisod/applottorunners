import 'package:flutter/material.dart';
import 'dart:async';
import '../supabase/supabase_config.dart';

class RideWaitingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback? onBookingAccepted;
  final VoidCallback? onBookingCancelled;

  const RideWaitingScreen({
    super.key,
    required this.bookingData,
    this.onBookingAccepted,
    this.onBookingCancelled,
  });

  @override
  State<RideWaitingScreen> createState() => _RideWaitingScreenState();
}

class _RideWaitingScreenState extends State<RideWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _searchController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _searchAnimation;

  Timer? _statusCheckTimer;
  String _currentStatus = 'pending';
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  Timer? _timeoutTimer;
  bool _isCancelling = false;
  static const int _timeoutMinutes = 5; // 5 minute timeout

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStatusChecking();
    _startElapsedTimer();
    _startTimeoutTimer();
  }

  void _initializeAnimations() {
    // Pulse animation for the main icon
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Search animation for the searching indicator
    _searchController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
    );
    _searchController.repeat();
  }

  void _startStatusChecking() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkBookingStatus();
    });
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(minutes: _timeoutMinutes), () {
      if (_currentStatus == 'pending') {
        _handleTimeout();
      }
    });
  }

  Future<void> _checkBookingStatus() async {
    try {
      final bookingId = widget.bookingData['id'];
      if (bookingId == null) return;

      final response = await SupabaseConfig.client
          .from('transportation_bookings')
          .select('status, driver_id')
          .eq('id', bookingId)
          .single();

      final newStatus = response['status'];
      final driverId = response['driver_id'];

      if (newStatus != _currentStatus) {
        setState(() {
          _currentStatus = newStatus;
        });

        if (newStatus == 'accepted' && driverId != null) {
          _stopTimers();
          widget.onBookingAccepted?.call();
        } else if (newStatus == 'cancelled') {
          _stopTimers();
          widget.onBookingCancelled?.call();
        }
      }
    } catch (e) {
      print('Error checking booking status: $e');
    }
  }

  void _stopTimers() {
    _statusCheckTimer?.cancel();
    _elapsedTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.stop();
    _searchController.stop();
  }

  Future<void> _handleTimeout() async {
    _stopTimers();

    try {
      final bookingId = widget.bookingData['id'];
      if (bookingId != null) {
        await SupabaseConfig.updateTransportationBooking(bookingId, {
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      widget.onBookingCancelled?.call();
    } catch (e) {
      print('Error handling timeout: $e');
      widget.onBookingCancelled?.call();
    }
  }

  Future<void> _cancelBooking() async {
    if (_isCancelling) return;

    setState(() => _isCancelling = true);

    try {
      final bookingId = widget.bookingData['id'];
      if (bookingId != null) {
        await SupabaseConfig.updateTransportationBooking(bookingId, {
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _stopTimers();
      widget.onBookingCancelled?.call();
    } catch (e) {
      setState(() => _isCancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopTimers();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatElapsedTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRemainingTime() {
    final remainingSeconds = (_timeoutMinutes * 60) - _elapsedSeconds;
    if (remainingSeconds <= 0) return '00:00';
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getRemainingTimeColor(ThemeData theme) {
    final remainingSeconds = (_timeoutMinutes * 60) - _elapsedSeconds;
    if (remainingSeconds <= 60) {
      // Last minute
      return theme.colorScheme.error;
    } else if (remainingSeconds <= 180) {
      // Last 3 minutes
      return theme.colorScheme.tertiary;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText() {
    final remainingSeconds = (_timeoutMinutes * 60) - _elapsedSeconds;
    if (remainingSeconds <= 60) {
      return 'Hurry! Time is running out...';
    } else if (remainingSeconds <= 180) {
      return 'Still looking for drivers...';
    } else {
      return 'Looking for available drivers...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isCancelling ? null : _cancelBooking,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Finding Your Ride',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_taxi,
                            size: 60,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Status text
                  Text(
                    _getStatusText(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Time information
                  Column(
                    children: [
                      Text(
                        'Time elapsed: ${_formatElapsedTime()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time remaining: ${_formatRemainingTime()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getRemainingTimeColor(theme),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Searching animation
                  AnimatedBuilder(
                    animation: _searchAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSearchDot(0),
                          const SizedBox(width: 8),
                          _buildSearchDot(1),
                          const SizedBox(width: 8),
                          _buildSearchDot(2),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Booking details card
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 16 : 24),
                    padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTripDetail(
                          Icons.location_on,
                          'From',
                          widget.bookingData['pickup_location'] ?? 'Unknown',
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildTripDetail(
                          Icons.location_on_outlined,
                          'To',
                          widget.bookingData['dropoff_location'] ?? 'Unknown',
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildTripDetail(
                          Icons.people,
                          'Passengers',
                          '${widget.bookingData['passenger_count'] ?? 1}',
                          theme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Cancel button
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 16 : 24),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : _cancelBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Cancel Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchDot(int index) {
    final theme = Theme.of(context);
    final delay = index * 0.2;
    final animationValue = (_searchAnimation.value + delay) % 1.0;

    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: animationValue < 0.5 ? 1.0 : 1.5,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(
                animationValue < 0.5 ? 0.6 : 1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetail(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
