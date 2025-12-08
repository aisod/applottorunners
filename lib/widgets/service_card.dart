import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/responsive.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color priceColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.iconBackgroundColor,
    required this.priceColor,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = Responsive.getServiceCardDimensions(context);
    final isSmallMobile = Responsive.isSmallMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(dimensions['cardPadding']!),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: dimensions['iconContainerSize']!,
                height: dimensions['iconContainerSize']!,
                decoration: BoxDecoration(
                  color: iconBackgroundColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconBackgroundColor,
                  size: dimensions['iconSize']!,
                ),
              ),
              SizedBox(width: dimensions['spacing']!),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: dimensions['titleFontSize']!,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallMobile ? 2 : 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: dimensions['descriptionFontSize']!,
                      ),
                      maxLines: isSmallMobile
                          ? 1
                          : 2, // Reduce lines for small mobile
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallMobile ? 4 : 6),
                    Text(
                      price,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: priceColor,
                        fontWeight: FontWeight.w600,
                        fontSize: dimensions['priceFontSize']!,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallMobile ? 12 : 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Predefined service cards for common services
class DocumentDeliveryCard extends StatelessWidget {
  final VoidCallback? onTap;

  const DocumentDeliveryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Document Delivery',
      description: 'Quick document delivery service',
      price: '₦75',
      icon: Icons.description,
      iconBackgroundColor: LottoRunnersColors.teal,
      priceColor: LottoRunnersColors.teal,
      onTap: onTap,
    );
  }
}

class FoodDeliveryCard extends StatelessWidget {
  final VoidCallback? onTap;

  const FoodDeliveryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Food Delivery',
      description: 'Delicious food delivered to you',
      price: '₦50',
      icon: Icons.restaurant,
      iconBackgroundColor: LottoRunnersColors.orange,
      priceColor: LottoRunnersColors.orange,
      onTap: onTap,
    );
  }
}

class PackageDeliveryCard extends StatelessWidget {
  final VoidCallback? onTap;

  const PackageDeliveryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Package Delivery',
      description: 'Secure package delivery service',
      price: '₦100',
      icon: Icons.local_shipping,
      iconBackgroundColor: LottoRunnersColors.accent,
      priceColor: LottoRunnersColors.accent,
      onTap: onTap,
    );
  }
}

class GroceryShoppingCard extends StatelessWidget {
  final VoidCallback? onTap;

  const GroceryShoppingCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Grocery Shopping',
      description: 'Personal grocery shopping service',
      price: '₦150',
      icon: Icons.shopping_cart,
      iconBackgroundColor: LottoRunnersColors.primaryPurple,
      priceColor: LottoRunnersColors.primaryPurple,
      onTap: onTap,
    );
  }
}

// Transportation service cards
class ShuttleServiceCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ShuttleServiceCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Shuttle Service',
      description: 'Quick point-to-point transport',
      price: 'From ₦150',
      icon: Icons.directions_car,
      iconBackgroundColor: LottoRunnersColors.shuttleBlue,
      priceColor: LottoRunnersColors.shuttleBlue,
      onTap: onTap,
    );
  }
}

class ContractServiceCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ContractServiceCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Contract Service',
      description: 'Long-term dedicated transport',
      price: 'From ₦300',
      icon: Icons.airport_shuttle,
      iconBackgroundColor: LottoRunnersColors.contractGreen,
      priceColor: LottoRunnersColors.contractGreen,
      onTap: onTap,
    );
  }
}

class BusServiceCard extends StatelessWidget {
  final VoidCallback? onTap;

  const BusServiceCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ServiceCard(
      title: 'Bus Service',
      description: 'Scheduled bus transportation',
      price: 'From ₦80',
      icon: Icons.directions_bus,
      iconBackgroundColor: LottoRunnersColors.busOrange,
      priceColor: LottoRunnersColors.busOrange,
      onTap: onTap,
    );
  }
}
