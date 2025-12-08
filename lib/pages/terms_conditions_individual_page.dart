import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Terms and Conditions page specifically for Individual and Business customers
/// This page outlines the terms, responsibilities, and service usage for customers
class TermsConditionsIndividualPage extends StatelessWidget {
  const TermsConditionsIndividualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = Responsive.isSmallMobile(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions for Customers',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Customer Service Agreement',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Last Updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Service Agreement
            _buildSection(
              context,
              theme,
              '1. Service Agreement',
              Icons.handshake,
              [
                'By using Lotto Runners, you agree to connect with verified runners for errand and transportation services.',
                'You acknowledge that Lotto Runners acts as an intermediary platform connecting you with service providers.',
                'You must be at least 18 years old to use the platform.',
                'You agree to use the platform in accordance with these terms and all applicable laws.',
              ],
            ),

            // Section 2: Customer Responsibilities
            _buildSection(
              context,
              theme,
              '2. Customer Responsibilities',
              Icons.checklist,
              [
                'Provide accurate and complete information when posting errands or booking services.',
                'Clearly describe your service requirements, including location, time, and special instructions.',
                'Respond promptly to runner communications through the platform.',
                'Treat all runners with respect and professionalism.',
                'Pay for services as agreed upon through the platform.',
                'Be available or provide clear instructions for service completion.',
                'Verify service completion before confirming payment.',
                'Report any issues or concerns through the platform immediately.',
                'Provide accurate pickup and delivery addresses.',
                'Ensure items for delivery are properly packaged and ready for pickup.',
              ],
            ),

            // Section 3: Payment Terms
            _buildSection(
              context,
              theme,
              '3. Payment Terms',
              Icons.payments,
              [
                'All payments are processed securely through the platform.',
                'Service fees are included in the total price displayed.',
                'Payment is required before or upon service completion, as specified in the service agreement.',
                'You authorize Lotto Runners to charge your payment method for services rendered.',
                'Refunds are available for valid claims within 24 hours of service completion.',
                'Refund requests must be submitted through the platform with supporting documentation.',
                'Lotto Runners reserves the right to investigate refund requests before processing.',
                'Cancellation fees may apply if you cancel after a runner has accepted your request.',
                'Prices are displayed in your local currency and are subject to change.',
              ],
            ),

            // Section 4: Service Posting Guidelines
            _buildSection(
              context,
              theme,
              '4. Service Posting Guidelines',
              Icons.description,
              [
                'Post clear, accurate descriptions of the services you need.',
                'Set reasonable time limits for service completion.',
                'Specify any special requirements, vehicle needs, or accessibility considerations.',
                'Provide accurate location information with clear pickup and delivery addresses.',
                'Include relevant photos or documents when necessary.',
                'Do not post requests for illegal activities or prohibited items.',
                'Do not request services that violate local laws or regulations.',
                'You may post multiple errands, but each must be clearly defined.',
              ],
            ),

            // Section 5: Cancellation Policy
            _buildSection(
              context,
              theme,
              '5. Cancellation Policy',
              Icons.cancel,
              [
                'You may cancel errands before a runner accepts without penalty.',
                'Cancellation after acceptance may result in fees or penalties.',
                'Cancellation fees help compensate runners for their time and commitment.',
                'Repeated cancellations may result in restrictions on your account.',
                'If a runner cancels, you will receive a full refund and can repost your request.',
                'Cancellation policies may vary by service type.',
              ],
            ),

            // Section 6: Prohibited Activities
            _buildSection(
              context,
              theme,
              '6. Prohibited Activities',
              Icons.block,
              [
                'Requesting services for illegal activities or prohibited items.',
                'Harassment, discrimination, or inappropriate behavior toward runners.',
                'Providing false or misleading information.',
                'Circumventing the platform to arrange services directly with runners.',
                'Attempting to avoid platform fees by arranging off-platform transactions.',
                'Sharing runner contact information outside the platform.',
                'Requesting services that violate safety regulations or local laws.',
                'Using the platform for fraudulent purposes.',
                'Posting duplicate or spam requests.',
              ],
            ),

            // Section 7: Service Quality and Disputes
            _buildSection(
              context,
              theme,
              '7. Service Quality and Disputes',
              Icons.star_outline,
              [
                'Lotto Runners strives to connect you with verified, professional runners.',
                'If service quality does not meet expectations, report the issue immediately.',
                'Disputes should be reported through the platform within 24 hours of service completion.',
                'Lotto Runners will investigate disputes and work to resolve them fairly.',
                'You agree to cooperate with dispute resolution processes.',
                'Decisions made by Lotto Runners are final and binding.',
                'You may rate and review runners after service completion.',
                'Honest and constructive feedback helps maintain platform quality.',
              ],
            ),

            // Section 8: Privacy and Data Protection
            _buildSection(
              context,
              theme,
              '8. Privacy and Data Protection',
              Icons.privacy_tip,
              [
                'Your personal information is protected according to our Privacy Policy.',
                'Location data is used only for service matching and is not shared with third parties.',
                'Communication with runners occurs through the platform for your protection.',
                'You should not share personal contact information outside the platform.',
                'Lotto Runners uses industry-standard security measures to protect your data.',
                'You can request access to, correction of, or deletion of your personal data at any time.',
              ],
            ),

            // Section 9: Limitation of Liability
            _buildSection(
              context,
              theme,
              '9. Limitation of Liability',
              Icons.warning_amber,
              [
                'Lotto Runners is not liable for damages to items during service delivery.',
                'You are responsible for ensuring items are properly insured if valuable.',
                'Lotto Runners is not responsible for delays caused by factors beyond our control.',
                'The platform provides a connection service and is not the service provider.',
                'You agree to use the platform at your own risk.',
                'Lotto Runners\' liability is limited to the amount you paid for the specific service.',
              ],
            ),

            // Section 10: Account Termination
            _buildSection(
              context,
              theme,
              '10. Account Termination',
              Icons.account_circle,
              [
                'You may deactivate your account at any time through account settings.',
                'Lotto Runners reserves the right to suspend or terminate accounts for violations.',
                'Violations of these terms may result in immediate account suspension.',
                'Repeated violations or serious misconduct may result in permanent termination.',
                'Upon termination, you will lose access to the platform and any pending services.',
              ],
            ),

            // Section 11: Contact Information
            _buildSection(
              context,
              theme,
              '11. Contact Information',
              Icons.contact_support,
              [
                'For questions about these terms, email: legal@lottorunners.com',
                'For customer support, use the in-app help feature or contact: support@lottorunners.com',
                'For payment or billing inquiries, contact: payments@lottorunners.com',
                'For privacy concerns, email: privacy@lottorunners.com',
              ],
            ),

            const SizedBox(height: 32),

            // Acknowledgment Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Acknowledgment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By using Lotto Runners as a customer, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, you must discontinue use of the platform immediately.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

