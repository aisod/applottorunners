import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/responsive.dart';

/// Terms and Conditions page specifically for Runners
/// This page outlines the terms, responsibilities, and commission structure for service providers
class TermsConditionsRunnerPage extends StatelessWidget {
  const TermsConditionsRunnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = Responsive.isSmallMobile(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions for Runners',
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
                        Icons.verified_user,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Runner Service Agreement',
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
                'By registering as a Runner on Lotto Runners, you agree to provide errand and transportation services to customers through our platform.',
                'You acknowledge that Lotto Runners acts as an intermediary platform connecting you with customers seeking services.',
                'You must be at least 18 years old and legally eligible to work in your jurisdiction.',
                'You agree to comply with all local, state, and federal laws and regulations applicable to your services.',
              ],
            ),

            // Section 2: Runner Responsibilities
            _buildSection(
              context,
              theme,
              '2. Runner Responsibilities',
              Icons.checklist,
              [
                'Provide accurate and truthful information during registration and verification.',
                'Maintain valid licenses, insurance, and documentation required for your services.',
                'Accept and complete errands in a timely and professional manner.',
                'Communicate clearly and promptly with customers through the platform.',
                'Treat all customers with respect and professionalism.',
                'Maintain the confidentiality of customer information.',
                'Report any issues, accidents, or incidents immediately to Lotto Runners support.',
                'Ensure your vehicle (if applicable) is in safe and legal operating condition.',
                'Follow all traffic laws and safety regulations while performing services.',
                'Complete accepted errands within the agreed timeframes.',
              ],
            ),

            // Section 3: Commission and Payment Terms
            _buildSection(
              context,
              theme,
              '3. Commission and Payment Terms',
              Icons.payments,
              [
                'Lotto Runners retains a 33.3% service fee on all completed bookings.',
                'Runners receive 66.7% of each completed booking amount.',
                'This commission structure applies to all service types (errands, transportation, bus services, contracts).',
                'Earnings are calculated automatically per transaction upon completion.',
                'The platform fee covers maintenance, customer support, insurance, and platform infrastructure.',
                'Payments are processed securely and transferred to your registered payment method.',
                'Payment processing times may vary based on your payment provider.',
                'You are responsible for any taxes applicable to your earnings.',
                'Lotto Runners reserves the right to adjust commission rates with 30 days notice.',
              ],
            ),

            // Section 4: Service Limits and Restrictions
            _buildSection(
              context,
              theme,
              '4. Service Limits and Restrictions',
              Icons.lock,
              [
                'You may accept a maximum of 3 active errands at any given time.',
                'You may accept a maximum of 3 active transportation bookings at any given time.',
                'You cannot accept errands requiring vehicles if you have not verified vehicle ownership.',
                'You must be verified by an admin before accessing all platform features.',
                'Cancellation of accepted errands is restricted and may result in penalties.',
                'Repeated cancellations may result in account suspension or termination.',
              ],
            ),

            // Section 5: Verification Requirements
            _buildSection(
              context,
              theme,
              '5. Verification Requirements',
              Icons.verified,
              [
                'You must submit a complete application with accurate personal information.',
                'You must upload required verification documents (driver\'s license, code of conduct, etc.).',
                'If providing vehicle-based services, you must submit vehicle documentation and photos.',
                'All documents must be valid, current, and clearly legible.',
                'Verification is subject to admin approval and may take several business days.',
                'You must maintain valid documentation throughout your use of the platform.',
                'Lotto Runners reserves the right to request updated documentation at any time.',
              ],
            ),

            // Section 6: Prohibited Activities
            _buildSection(
              context,
              theme,
              '6. Prohibited Activities',
              Icons.block,
              [
                'Engaging in illegal activities while using the platform.',
                'Harassment, discrimination, or inappropriate behavior toward customers.',
                'Providing false or misleading information.',
                'Circumventing the platform to arrange services outside of Lotto Runners.',
                'Accepting payments directly from customers (all payments must go through the platform).',
                'Sharing customer contact information or personal details outside the platform.',
                'Using the platform for purposes other than legitimate service provision.',
                'Operating under the influence of alcohol or drugs.',
                'Violating traffic laws or safety regulations.',
                'Failing to complete accepted errands without valid justification.',
              ],
            ),

            // Section 7: Insurance and Liability
            _buildSection(
              context,
              theme,
              '7. Insurance and Liability',
              Icons.shield,
              [
                'You are responsible for maintaining appropriate insurance coverage for your services.',
                'Lotto Runners provides platform-level insurance, but you must have your own coverage.',
                'You are liable for any damages or injuries resulting from your negligence.',
                'You must report any accidents or incidents to Lotto Runners immediately.',
                'Lotto Runners is not liable for damages arising from your service provision.',
                'You agree to indemnify Lotto Runners against claims arising from your services.',
              ],
            ),

            // Section 8: Account Termination
            _buildSection(
              context,
              theme,
              '8. Account Termination',
              Icons.cancel,
              [
                'Lotto Runners reserves the right to suspend or terminate accounts for violations.',
                'Violations of these terms may result in immediate account suspension.',
                'Repeated violations or serious misconduct may result in permanent termination.',
                'Upon termination, you will lose access to the platform and any pending earnings.',
                'You may appeal termination decisions by contacting support.',
              ],
            ),

            // Section 9: Dispute Resolution
            _buildSection(
              context,
              theme,
              '9. Dispute Resolution',
              Icons.gavel,
              [
                'Disputes between runners and customers should be reported through the platform.',
                'Lotto Runners will investigate disputes and make determinations in good faith.',
                'You agree to cooperate with dispute resolution processes.',
                'Decisions made by Lotto Runners are final and binding.',
                'For legal disputes, you agree to binding arbitration as specified in the agreement.',
              ],
            ),

            // Section 10: Contact Information
            _buildSection(
              context,
              theme,
              '10. Contact Information',
              Icons.contact_support,
              [
                'For questions about these terms, email: legal@lottorunners.com',
                'For runner support, use the in-app help feature or contact support@lottorunners.com',
                'For payment or commission inquiries, contact: payments@lottorunners.com',
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
                    'By using Lotto Runners as a Runner, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, you must discontinue use of the platform immediately.',
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

