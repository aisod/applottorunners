import 'package:flutter/material.dart';

class ErrandCard extends StatelessWidget {
  final Map<String, dynamic> errand;
  final VoidCallback? onTap;
  final bool showAcceptButton;
  final VoidCallback? onAccept;
  final bool showStatusUpdate;
  final VoidCallback? onStatusUpdate;

  const ErrandCard({
    super.key,
    required this.errand,
    this.onTap,
    this.showAcceptButton = false,
    this.onAccept,
    this.showStatusUpdate = false,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 12),
              _buildContent(theme),
              const SizedBox(height: 12),
              _buildFooter(theme),
              if (showAcceptButton || showStatusUpdate) ...[
                const SizedBox(height: 16),
                _buildActionButtons(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final status = errand['status'] ?? '';
    final category = errand['category'] ?? '';

    return Row(
      children: [
        // Category icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category, theme).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category, theme),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Title and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errand['title'] ?? '',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildStatusChip(theme, status),
                  const SizedBox(width: 8),
                  if (errand['requires_vehicle'] == true)
                    Icon(
                      Icons.directions_car,
                      size: 16,
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
          children: [
            Text(
              '\$${errand['price_amount']?.toString() ?? '0'}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${errand['time_limit_hours']}h',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          errand['description'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // Location
        if (errand['location_address'] != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errand['location_address'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final customerName = errand['customer']?['full_name'] ?? 'Unknown Customer';
    final runnerName = errand['runner']?['full_name'];
    final createdAt = errand['created_at'];

    return Row(
      children: [
        // Customer info
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  runnerName != null
                      ? 'Runner: $runnerName'
                      : 'By: $customerName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (showAcceptButton && onAccept != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Accept',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (showStatusUpdate && onStatusUpdate != null)
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
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayStatus,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
}
