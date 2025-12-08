import 'package:flutter/material.dart';

/// Centralized mapping from database `icon_name` values to Material [IconData].
///
/// Keeping the icon mapping in one place prevents drift between pages and
/// ensures that newly added icons in the admin panel render correctly across
/// the app.
class ServiceIcons {
  static const Map<String, IconData> _iconByName = {
    // General
    'task_alt': Icons.task_alt,

    // Shopping & groceries
    'local_grocery_store': Icons.local_grocery_store,
    'shopping_cart': Icons.shopping_cart,
    // Backward-compat alias used in older records
    'shopping_bag': Icons.shopping_bag,

    // Documents
    'description': Icons.description,
    'content_copy': Icons.content_copy,
    'verified': Icons.verified,

    // Delivery & transport
    'local_shipping': Icons.local_shipping,
    'directions_car': Icons.directions_car,

    // People/services
    'people_alt': Icons.people_alt,
    'elderly': Icons.elderly,
    'how_to_reg': Icons.how_to_reg,

    // Home & maintenance
    'cleaning_services': Icons.cleaning_services,
    'local_car_wash': Icons.local_car_wash,
    'build': Icons.build,
    'home': Icons.home,

    // Misc categories
    'pets': Icons.pets,
    'grass': Icons.grass,
    'restaurant': Icons.restaurant,
    'local_pharmacy': Icons.local_pharmacy,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'work': Icons.work,
  };

  /// Returns the [IconData] for a given database `icon_name`.
  /// Falls back to [Icons.task_alt] if the name is null or unknown.
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.task_alt;
    return _iconByName[iconName] ?? Icons.task_alt;
  }
}
