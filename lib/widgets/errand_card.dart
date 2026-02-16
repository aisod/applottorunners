import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

class ErrandCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  final VoidCallback? onTap;
  final bool showAcceptButton;
  final VoidCallback? onAccept;
  final bool showStatusUpdate;
  final VoidCallback? onStatusUpdate;
  final bool showCancelButton;
  final VoidCallback? onCancel;
  final bool showChatButton;
  final VoidCallback? onChat;
  final bool showPayButton;
  final VoidCallback? onPay;
  final String? payButtonText;

  const ErrandCard({
    super.key,
    required this.errand,
    this.onTap,
    this.showAcceptButton = false,
    this.onAccept,
    this.showStatusUpdate = false,
    this.onStatusUpdate,
    this.showCancelButton = false,
    this.onCancel,
    this.showChatButton = false,
    this.onChat,
    this.showPayButton = false,
    this.onPay,
    this.payButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = errand['status'] ?? '';
    final statusColor = _getStatusColor(status, theme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding:
              EdgeInsets.all(Responsive.isSmallMobile(context) ? 10.0 : 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      errand['title'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isSmallMobile(context) ? 8 : 12,
                        vertical: Responsive.isSmallMobile(context) ? 4 : 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getStatusText(status).toUpperCase(),
                      style: TextStyle(
                        fontSize: Responsive.isSmallMobile(context) ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer/Runner information
              Container(
                padding: EdgeInsets.all(Responsive.isSmallMobile(context) ? 10 : 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: LottoRunnersColors.primaryYellow, size: Responsive.isSmallMobile(context) ? 18 : 20),
                    SizedBox(width: Responsive.isSmallMobile(context) ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Determine what to display based on user type and errand status
                          Text(
                            _getPersonDisplayText(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  Responsive.isSmallMobile(context) ? 14 : 16,
                            ),
                          ),
                          if (_getPersonPhone() != null)
                            Text(
                              _getPersonPhone()!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize:
                                    Responsive.isSmallMobile(context) ? 12 : 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category information
              Row(
                children: [
                  Icon(Icons.category,
                      color: LottoRunnersColors.primaryYellow, size: Responsive.isSmallMobile(context) ? 18 : 20),
                  SizedBox(width: Responsive.isSmallMobile(context) ? 6 : 8),
                  Expanded(
                    child: Text(
                      errand['category']?.toString().toUpperCase() ?? 'ERRAND',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location and time info
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getDisplayLocation(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule,
                      color: LottoRunnersColors.primaryYellow, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${errand['time_limit_hours']}h limit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: Responsive.isSmallMobile(context) ? 12 : 13,
                    ),
                  ),
                ],
              ),

              // Price information
              if (errand['price_amount'] != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: LottoRunnersColors.primaryYellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'N\$${errand['price_amount']?.toString() ?? '0'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: Responsive.isSmallMobile(context) ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              if (showAcceptButton ||
                  showStatusUpdate ||
                  showCancelButton ||
                  showChatButton) ...[
                _buildActionButtons(theme, Responsive.isSmallMobile(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    final status = errand['status'] ?? '';
    final category = errand['category'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category icon
        Container(
          width: isMobile ? 36 : 40,
          height: isMobile ? 36 : 40,
          decoration: BoxDecoration(
            color: LottoRunnersColors.primaryYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: LottoRunnersColors.primaryYellow,
            size: isMobile ? 18 : 20,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),

        // Title and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errand['title'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildStatusChip(theme, status, isMobile),
                  if (errand['requires_vehicle'] == true)
                    Icon(
                      Icons.directions_car,
                      size: isMobile ? 14 : 16,
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'N\$${errand['price_amount']?.toString() ?? '0'}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: LottoRunnersColors.primaryYellow,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            Text(
              '${errand['time_limit_hours']}h',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          errand['description'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.4,
            fontSize: isMobile ? 14 : 16,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // Location
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: isMobile ? 14 : 16,
              color: LottoRunnersColors.primaryYellow,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _getDisplayLocation(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: isMobile ? 12 : 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile) {
    final customerName = errand['customer']?['full_name'] ?? 'Unknown Customer';
    final runnerName = errand['runner']?['full_name'];
    final createdAt = errand['created_at'];

    // Check if current user is a runner and errand is not accepted
    final isRunner = errand['current_user_type'] == 'runner';
    final isAccepted = errand['runner_id'] != null;
    final showCustomerInfo = !isRunner || isAccepted;

    return Row(
      children: [
        // Customer/Runner info
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: isMobile ? 12 : 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  runnerName != null
                      ? 'Runner: $runnerName'
                      : showCustomerInfo
                          ? 'By: $customerName'
                          : 'Customer info available after acceptance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 12 : 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Time ago
        if (createdAt != null)
          Text(
            _getTimeAgo(createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isMobile ? 12 : 13,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isMobile) {
    final buttons = <Widget>[];

    if (showAcceptButton && onAccept != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: Icon(Icons.check_circle, color: theme.colorScheme.onPrimary, size: 18),
            label: Text(
              'Accept',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (showChatButton && onChat != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onChat,
            icon: Icon(Icons.chat, size: isMobile ? 16 : 18),
            label: Text(
              'Chat',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LottoRunnersColors.primaryBlue,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    if (showStatusUpdate && onStatusUpdate != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onStatusUpdate,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update Status',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ),
      );
    }

    if (showCancelButton && onCancel != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ),
      );
    }

    if (showPayButton && onPay != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPay,
            icon: Icon(Icons.payment, color: theme.colorScheme.onPrimary, size: 18),
            label: Text(
              payButtonText ?? 'Pay Now',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons,
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status, bool isMobile) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'posted':
        color = theme.colorScheme.primary;
        displayStatus = 'Open';
        break;
      case 'accepted':
        color = theme.colorScheme.secondary;
        displayStatus = 'Accepted';
        break;
      case 'in_progress':
        color = theme.colorScheme.tertiary;
        displayStatus = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        displayStatus = 'Completed';
        break;
      case 'cancelled':
        color = theme.colorScheme.error;
        displayStatus = 'Cancelled';
        break;
      default:
        color = theme.colorScheme.outline;
        displayStatus = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 10 : 11,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'document':
        return Icons.description;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.task_alt;
    }
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'grocery':
        return theme.colorScheme.primary;
      case 'delivery':
        return theme.colorScheme.secondary;
      case 'document':
        return theme.colorScheme.tertiary;
      case 'shopping':
        return Colors.purple;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _getTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'posted':
        return theme.colorScheme.primary;
      case 'accepted':
        return theme.colorScheme.secondary;
      case 'in_progress':
        return theme.colorScheme.tertiary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return 'Open';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Determines what person information to display based on user type and errand status
  String _getPersonDisplayText() {
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];
    final status = errand['status'] ?? '';

    // Check if current user is the customer (same logic as MyErrandsPage)
    final isCustomer = customerId == SupabaseConfig.currentUser?.id;

    if (isCustomer) {
      // Customer view: show runner name if accepted, otherwise show pending message
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['runner']?['full_name'] ?? 'Runner Assigned';
      } else {
        return 'Waiting for runner to accept';
      }
    } else {
      // Runner view: show customer name if accepted, otherwise show pending message
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['customer']?['full_name'] ?? 'Customer';
      } else {
        return 'Customer info available after acceptance';
      }
    }
  }

  /// Determines what phone number to display based on user type and errand status
  String? _getPersonPhone() {
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];
    final status = errand['status'] ?? '';

    // Check if current user is the customer (same logic as MyErrandsPage)
    final isCustomer = customerId == SupabaseConfig.currentUser?.id;

    if (isCustomer) {
      // Customer view: show runner phone if accepted
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['runner']?['phone'];
      }
    } else {
      // Runner view: show customer phone if accepted
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['customer']?['phone'];
      }
    }

    return null;
  }

  /// Intelligently determines which location field to display based on errand category
  String _getDisplayLocation() {
    final category = errand['category']?.toString().toLowerCase() ?? '';
    
    switch (category) {
      case 'shopping':
        // For shopping, show delivery address (where items go), not store locations
        final deliveryAddress = errand['delivery_address'];
        if (deliveryAddress != null && deliveryAddress.toString().trim().isNotEmpty) {
          return 'Deliver to: ${deliveryAddress.toString().trim()}';
        }
        // Fallback to location_address (store names)
        return errand['location_address']?.toString() ?? 'Location TBD';
      
      case 'delivery':
        // For delivery, show pickup → delivery
        final pickupAddress = errand['pickup_address'] ?? errand['location_address'];
        final deliveryAddress = errand['delivery_address'];
        
        if (pickupAddress != null && deliveryAddress != null) {
          final pickup = pickupAddress.toString().trim();
          final delivery = deliveryAddress.toString().trim();
          // Truncate if too long
          final pickupShort = pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final deliveryShort = delivery.length > 20 ? '${delivery.substring(0, 20)}...' : delivery;
          return '$pickupShort → $deliveryShort';
        } else if (pickupAddress != null) {
          return 'From: ${pickupAddress.toString().trim()}';
        } else if (deliveryAddress != null) {
          return 'To: ${deliveryAddress.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Location TBD';
      
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
        return errand['location_address']?.toString() ?? 'Location TBD';
      
      case 'elderly_services':
      case 'queue_sitting':
      default:
        // For these services, location_address is the primary location
        return errand['location_address']?.toString() ?? 'Location TBD';
    }
  }
}
