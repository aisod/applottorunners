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
  final bool showApproveButton;
  final VoidCallback? onApprove;

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
    this.showApproveButton = false,
    this.onApprove,
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
                padding:
                    EdgeInsets.all(Responsive.isSmallMobile(context) ? 10 : 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person,
                        color: LottoRunnersColors.primaryYellow,
                        size: Responsive.isSmallMobile(context) ? 18 : 20),
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
                      color: LottoRunnersColors.primaryYellow,
                      size: Responsive.isSmallMobile(context) ? 18 : 20),
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
                  showChatButton ||
                  showPayButton ||
                  showApproveButton) ...[
                _buildActionButtons(theme, Responsive.isSmallMobile(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isMobile) {
    final buttons = <Widget>[];

    // Buttons that should always stay in a single row layout
    final primaryRowButtons = <Widget>[];

    if (showAcceptButton && onAccept != null) {
      primaryRowButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: Icon(
              Icons.check_circle,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
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

    if (showStatusUpdate && onStatusUpdate != null) {
      primaryRowButtons.add(
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

    if (showApproveButton && onApprove != null) {
      primaryRowButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: Icon(
              Icons.verified,
              color: theme.colorScheme.onPrimary,
              size: 18,
            ),
            label: Text(
              'Approve Work',
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Chat, Cancel and Pay are handled specially so that
    // Pay can be on top with Chat/Cancel beneath it.
    Widget? chatButton;
    if (showChatButton && onChat != null) {
      chatButton = Expanded(
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
      );
    }

    Widget? cancelButton;
    if (showCancelButton && onCancel != null) {
      cancelButton = Expanded(
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
      );
    }

    Widget? payButton;
    if (showPayButton && onPay != null) {
      payButton = Expanded(
        child: ElevatedButton.icon(
          onPressed: onPay,
          icon: Icon(
            Icons.payment,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
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
      );
    }

    // If we only have Pay + (Chat or Cancel), use the special stacked layout:
    // Pay on top, Chat/Cancel underneath.
    final hasStackedLayout =
        primaryRowButtons.isEmpty && payButton != null &&
            (chatButton != null || cancelButton != null);

    if (hasStackedLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              payButton!,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (chatButton != null) chatButton,
              if (chatButton != null && cancelButton != null)
                const SizedBox(width: 8),
              if (cancelButton != null) cancelButton,
            ],
          ),
        ],
      );
    }

    // Fallback to a single row layout (original behaviour) for
    // all other combinations of buttons.
    buttons.addAll(primaryRowButtons);
    if (chatButton != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(chatButton);
    }
    if (cancelButton != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(cancelButton);
    }
    if (payButton != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(payButton);
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons,
    );
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

  String _getPersonDisplayText() {
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];
    final status = errand['status'] ?? '';
    final isCustomer = customerId == SupabaseConfig.currentUser?.id;

    if (isCustomer) {
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['runner']?['full_name'] ?? 'Runner Assigned';
      } else {
        return 'Waiting for runner to accept';
      }
    } else {
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

  String? _getPersonPhone() {
    final customerId = errand['customer_id'];
    final runnerId = errand['runner_id'];
    final status = errand['status'] ?? '';
    final isCustomer = customerId == SupabaseConfig.currentUser?.id;

    if (isCustomer) {
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['runner']?['phone'];
      }
    } else {
      if (runnerId != null &&
          (status == 'accepted' ||
              status == 'in_progress' ||
              status == 'completed')) {
        return errand['customer']?['phone'];
      }
    }

    return null;
  }

  String _getDisplayLocation() {
    final category = errand['category']?.toString().toLowerCase() ?? '';

    switch (category) {
      case 'shopping':
        final deliveryAddress = errand['delivery_address'];
        if (deliveryAddress != null &&
            deliveryAddress.toString().trim().isNotEmpty) {
          return 'Deliver to: ${deliveryAddress.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Location TBD';

      case 'delivery':
        final pickupAddress =
            errand['pickup_address'] ?? errand['location_address'];
        final deliveryAddress = errand['delivery_address'];
        if (pickupAddress != null && deliveryAddress != null) {
          final pickup = pickupAddress.toString().trim();
          final delivery = deliveryAddress.toString().trim();
          final pickupShort =
              pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final deliveryShort = delivery.length > 20
              ? '${delivery.substring(0, 20)}...'
              : delivery;
          return '$pickupShort → $deliveryShort';
        } else if (pickupAddress != null) {
          return 'From: ${pickupAddress.toString().trim()}';
        } else if (deliveryAddress != null) {
          return 'To: ${deliveryAddress.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Location TBD';

      case 'document_services':
      case 'license_discs':
        final pickupLocation =
            errand['pickup_location'] ?? errand['pickup_address'];
        final dropoffLocation =
            errand['dropoff_location'] ?? errand['dropoff_address'];
        if (pickupLocation != null && dropoffLocation != null) {
          final pickup = pickupLocation.toString().trim();
          final dropoff = dropoffLocation.toString().trim();
          final pickupShort =
              pickup.length > 20 ? '${pickup.substring(0, 20)}...' : pickup;
          final dropoffShort =
              dropoff.length > 20 ? '${dropoff.substring(0, 20)}...' : dropoff;
          return '$pickupShort → $dropoffShort';
        } else if (pickupLocation != null) {
          return 'Pickup: ${pickupLocation.toString().trim()}';
        }
        return errand['location_address']?.toString() ?? 'Location TBD';

      default:
        return errand['location_address']?.toString() ?? 'Location TBD';
    }
  }
}
