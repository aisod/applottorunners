import 'package:flutter/material.dart';
import '../widgets/route_provider_selector.dart';

/// Example page demonstrating the Route Provider Selector
///
/// This page shows how to use the RouteProviderSelector widget
/// to create a route-based provider selection interface.
class RouteProviderExamplePage extends StatefulWidget {
  const RouteProviderExamplePage({super.key});

  @override
  State<RouteProviderExamplePage> createState() =>
      _RouteProviderExamplePageState();
}

class _RouteProviderExamplePageState extends State<RouteProviderExamplePage> {
  Map<String, dynamic>? _selectedProvider;

  void _onProviderSelected(Map<String, dynamic> provider) {
    setState(() {
      _selectedProvider = provider;
    });

    // Show a snackbar with the selected provider info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Selected: ${provider['provider_name']} - KSH ${provider['price']?.toStringAsFixed(2)}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Provider Selector Example'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Route Provider Selector',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This example demonstrates how to use the new provider functions to create a dropdown that shows available providers for a selected route. The provider names are stored directly in the transportation_services table for faster access.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Route Provider Selector
            RouteProviderSelector(
              onProviderSelected: _onProviderSelected,
            ),

            const SizedBox(height: 32),

            // Selected Provider Summary
            if (_selectedProvider != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Booking Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                        'Provider', _selectedProvider!['provider_name']),
                    _buildSummaryRow(
                        'Service', _selectedProvider!['service_name']),
                    _buildSummaryRow('Price',
                        'KSH ${_selectedProvider!['price']?.toStringAsFixed(2)}'),
                    _buildSummaryRow(
                        'Departure Time', _selectedProvider!['departure_time']),
                    if (_selectedProvider!['check_in_time'] != null)
                      _buildSummaryRow(
                          'Check-in Time', _selectedProvider!['check_in_time']),
                    if (_selectedProvider!['operating_days'] != null &&
                        (_selectedProvider!['operating_days'] as List)
                            .isNotEmpty)
                      _buildSummaryRow(
                          'Operating Days',
                          (_selectedProvider!['operating_days'] as List)
                              .join(', ')),
                    _buildSummaryRow('Advance Booking',
                        '${_selectedProvider!['advance_booking_hours']} hours'),
                    _buildSummaryRow('Cancellation Policy',
                        '${_selectedProvider!['cancellation_hours']} hours notice'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Here you would typically navigate to a booking page
                        // or show a booking confirmation dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proceeding to booking...'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.book_online),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedProvider = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Selection'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Use',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                      1, 'Select a route from the dropdown above'),
                  _buildInstructionStep(2,
                      'The system will automatically load available providers for that route'),
                  _buildInstructionStep(
                      3, 'Choose a provider from the second dropdown'),
                  _buildInstructionStep(
                      4, 'View the provider details and proceed with booking'),
                  const SizedBox(height: 12),
                  Text(
                    'Note: This example uses the new provider_names array stored directly in the transportation_services table for faster access.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
