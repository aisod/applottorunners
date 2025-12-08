import 'package:flutter/material.dart';
import 'package:lotto_runners/pages/enhanced_shopping_form_page.dart';

/// Compatibility wrapper for the old ShoppingFormPage.
/// Delegates to EnhancedShoppingFormPage to avoid code duplication.
class ShoppingFormPage extends StatelessWidget {
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic>? userProfile;

  const ShoppingFormPage({
    super.key,
    required this.selectedService,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedShoppingFormPage(
      selectedService: selectedService,
      userProfile: userProfile,
    );
  }
}


