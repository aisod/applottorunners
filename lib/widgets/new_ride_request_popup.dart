import 'package:flutter/material.dart';

class NewRideRequestPopup extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDismiss;

  const NewRideRequestPopup({
    super.key,
    required this.booking,
    required this.onAccept,
    required this.onDecline,
    required this.onDismiss,
  });

  @override
  State<NewRideRequestPopup> createState() => _NewRideRequestPopupState();
}

class _NewRideRequestPopupState extends State<NewRideRequestPopup>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation from top
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Scale animation for content
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final user = booking['user'];
    final vehicleType = booking['vehicle_type'];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent background
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Popup content
          SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                      // Header with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Ride Request!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Immediate pickup needed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Booking details
                      _buildDetailRow(
                        icon: Icons.person,
                        label: 'Customer',
                        value: user?['full_name'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Pickup',
                        value: booking['pickup_location'] ?? 'Not specified',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.flag,
                        label: 'Destination',
                        value: booking['dropoff_location'] ?? 'Not specified',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.people,
                        label: 'Passengers',
                        value:
                            '${booking['passenger_count'] ?? 1} passenger(s)',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.directions_car,
                        label: 'Vehicle Type',
                        value: vehicleType?['name'] ?? 'Any vehicle',
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onAccept,
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text('Accept Ride'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onDecline,
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Dismiss button
                      TextButton(
                        onPressed: widget.onDismiss,
                        child: const Text(
                          'View Later',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper class to manage popup overlay
class RideRequestOverlay {
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required Map<String, dynamic> booking,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    required VoidCallback onDismiss,
  }) {
    // Remove any existing overlay
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => NewRideRequestPopup(
        booking: booking,
        onAccept: () {
          hide();
          onAccept();
        },
        onDecline: () {
          hide();
          onDecline();
        },
        onDismiss: () {
          hide();
          onDismiss();
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static bool get isShowing => _currentOverlay != null;
}
