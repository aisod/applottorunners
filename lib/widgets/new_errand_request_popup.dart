import 'package:flutter/material.dart';

class NewErrandRequestPopup extends StatefulWidget {
  final Map<String, dynamic> errand;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDismiss;

  const NewErrandRequestPopup({
    super.key,
    required this.errand,
    required this.onAccept,
    required this.onDecline,
    required this.onDismiss,
  });

  @override
  State<NewErrandRequestPopup> createState() => _NewErrandRequestPopupState();
}

class _NewErrandRequestPopupState extends State<NewErrandRequestPopup>
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
    final errand = widget.errand;
    final user = errand['user'];

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
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.assignment,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Errand Request!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Immediate assistance needed',
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

                      // Errand details
                      _buildDetailRow(
                        icon: Icons.person,
                        label: 'Customer',
                        value: user?['full_name'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.assignment,
                        label: 'Errand',
                        value: errand['title'] ?? 'No title',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: _getCategoryName(errand['category'] ?? 'other'),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: _getDisplayLocation(errand),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        icon: Icons.attach_money,
                        label: 'Price',
                        value:
                            'N\$${errand['price_amount']?.toStringAsFixed(2) ?? '0.00'}',
                      ),

                      if (errand['time_limit_hours'] != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.timer,
                          label: 'Time Limit',
                          value: '${errand['time_limit_hours']} hours',
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onAccept,
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text('Accept Errand'),
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

  String _getCategoryName(String category) {
    switch (category) {
      case 'grocery':
        return 'Grocery Shopping';
      case 'delivery':
        return 'Delivery';
      case 'document':
        return 'Document Services';
      case 'shopping':
        return 'General Shopping';
      default:
        return 'Other';
    }
  }

  /// Intelligently determines which location field to display based on errand category
  String _getDisplayLocation(Map<String, dynamic> errand) {
    final category = errand['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'shopping':
        // For shopping, show delivery address (where items go), not store locations
        final deliveryAddress = errand['delivery_address'];
        if (deliveryAddress != null && deliveryAddress.toString().trim().isNotEmpty) {
          return 'Deliver to: ${deliveryAddress.toString().trim()}';
        }
        // Fallback to location_address (store names)
        return errand['location_address']?.toString() ?? 'Not specified';
      
      case 'delivery':
        // For delivery, show pickup → delivery
        final pickupAddress = errand['pickup_address'] ?? errand['location_address'];
        final deliveryAddress = errand['delivery_address'];
        
        if (pickupAddress != null && deliveryAddress != null) {
          final pickup = pickupAddress.toString().trim();
          final delivery = deliveryAddress.toString().trim();
          // Truncate if too long for popup
          final pickupShort = pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final deliveryShort = delivery.length > 20 ? '${delivery.substring(0, 20)}...' : delivery;
          return '$pickupShort → $deliveryShort';
        } else if (pickupAddress != null) {
          return 'From: ${pickupAddress.toString().trim()}';
        } else if (deliveryAddress != null) {
          return 'To: ${deliveryAddress.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Not specified';
      
      case 'document_services':
      case 'license_discs':
        // These forms may have pickup or just location
        final pickupLocation = errand['pickup_location'] ?? errand['pickup_address'];
        final dropoffLocation = errand['dropoff_location'] ?? errand['dropoff_address'];
        
        if (pickupLocation != null && dropoffLocation != null) {
          final pickup = pickupLocation.toString().trim();
          final dropoff = dropoffLocation.toString().trim();
          final pickupShort = pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final dropoffShort = dropoff.length > 20 ? '${dropoff.substring(0, 20)}...' : dropoff;
          return '$pickupShort → $dropoffShort';
        } else if (pickupLocation != null) {
          return 'Pickup: ${pickupLocation.toString().trim()}';
        }
        // Fallback to location_address
        return errand['location_address']?.toString() ?? 'Not specified';
      
      case 'elderly_services':
      case 'queue_sitting':
      default:
        // For these services, location_address is the primary location
        return errand['location_address']?.toString() ?? 'Not specified';
    }
  }
}

// Helper class to manage popup overlay
class ErrandRequestOverlay {
  static OverlayEntry? _currentOverlay;

  static void show({
    required BuildContext context,
    required Map<String, dynamic> errand,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    required VoidCallback onDismiss,
  }) {
    // Remove any existing overlay
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => NewErrandRequestPopup(
        errand: errand,
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

