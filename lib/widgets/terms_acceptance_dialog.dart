import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';
import 'package:lotto_runners/pages/terms_conditions_runner_page.dart';
import 'package:lotto_runners/pages/terms_conditions_individual_page.dart';

/// Dialog that requires users to accept terms and conditions before using the app
/// This dialog is shown only once per user and cannot be dismissed without acceptance
class TermsAcceptanceDialog extends StatelessWidget {
  final String userType;
  final VoidCallback onAccepted;

  const TermsAcceptanceDialog({
    super.key,
    required this.userType,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunner = userType == 'runner';
    final isSmallScreen = Responsive.isSmallMobile(context);

    return PopScope(
      canPop: false, // Prevent dismissing without acceptance
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: isSmallScreen ? double.infinity : 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Terms & Conditions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Important Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.error,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Important',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You must read and accept our Terms & Conditions to continue using Lotto Runners. This is a one-time requirement.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms Summary
                      Text(
                        'By accepting, you agree to:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildAgreementPoint(
                        theme,
                        Icons.check_circle_outline,
                        'Comply with all platform rules and guidelines',
                      ),
                      _buildAgreementPoint(
                        theme,
                        Icons.check_circle_outline,
                        isRunner
                            ? 'Accept the 33.3% platform commission structure'
                            : 'Pay for services as agreed through the platform',
                      ),
                      _buildAgreementPoint(
                        theme,
                        Icons.check_circle_outline,
                        'Treat all users with respect and professionalism',
                      ),
                      _buildAgreementPoint(
                        theme,
                        Icons.check_circle_outline,
                        'Not engage in prohibited activities',
                      ),
                      _buildAgreementPoint(
                        theme,
                        Icons.check_circle_outline,
                        'Maintain accurate information on your account',
                      ),

                      const SizedBox(height: 24),

                      // View Full Terms Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog temporarily
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => isRunner
                                    ? const TermsConditionsRunnerPage()
                                    : const TermsConditionsIndividualPage(),
                              ),
                            ).then((_) {
                              // Re-show dialog after viewing terms
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => TermsAcceptanceDialog(
                                  userType: userType,
                                  onAccepted: onAccepted,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('View Full Terms & Conditions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              const Divider(height: 1),

              // Accept Button
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAccepted,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'I Accept Terms & Conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You must accept to continue using the app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementPoint(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

