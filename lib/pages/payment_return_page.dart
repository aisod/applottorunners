import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/services/paytoday_config.dart';
import 'package:lotto_runners/services/paytoday_backend_service.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

/// Standalone page shown when the user is redirected to /payment-return
/// (e.g. after completing PayToday payment in a new tab on web).
/// Displays success/cancelled message and instructs to close the tab.
class PaymentReturnPage extends StatefulWidget {
  const PaymentReturnPage({super.key});

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  bool _isLoading = true;
  String? _message;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleReturnUrl();
  }

  /// Parse invoice_number in form: errandId_first_half_timestamp or errandId_second_half_timestamp
  static ({String errandId, String paymentType})? _parseInvoiceNumber(
      String? invoiceNumber) {
    if (invoiceNumber == null || invoiceNumber.isEmpty) return null;
    final parts = invoiceNumber.split('_');
    if (parts.length < 3) return null;
    final errandId = parts[0];
    final paymentType = '${parts[1]}_${parts[2]}';
    if (paymentType != PayTodayConfig.paymentTypeFirstHalf &&
        paymentType != PayTodayConfig.paymentTypeSecondHalf) {
      return null;
    }
    return (errandId: errandId, paymentType: paymentType);
  }

  /// Wait for auth to be ready then call complete-return Edge Function (service role update + logs).
  Future<bool> _completeReturnWithRetry({
    required String errandId,
    required String paymentType,
    required String status,
    String? transactionId,
  }) async {
    const maxAttempts = 5;
    const delay = Duration(milliseconds: 600);

    for (var i = 0; i < maxAttempts; i++) {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        try {
          final result = await PayTodayBackendService.completePaymentReturn(
            errandId: errandId,
            paymentType: paymentType,
            status: status,
            transactionId: transactionId,
          );
          return result['updated'] == true;
        } catch (e) {
          PayTodayConfig.logError('Complete return failed', e);
          return false;
        }
      }
      await Future.delayed(delay);
    }
    PayTodayConfig.logError('Auth not ready after ${maxAttempts} attempts');
    return false;
  }

  Future<void> _handleReturnUrl() async {
    if (!kIsWeb) {
      setState(() {
        _isLoading = false;
        _message = 'This page is only used for web payment return.';
        _success = false;
      });
      return;
    }

    // Uri.base is the current browser URL on web
    final uri = Uri.base;
    if (!uri.path.endsWith('payment-return')) {
      setState(() {
        _isLoading = false;
        _message = 'Invalid return path.';
        _success = false;
      });
      return;
    }

    final status = uri.queryParameters['status']?.toLowerCase();
    final reference = uri.queryParameters['reference'];
    final invoiceNumber = uri.queryParameters['invoice_number'];

    PayTodayConfig.log(
        'Payment return: status=$status, reference=$reference, invoice_number=$invoiceNumber');

    if (status == 'success' || status == 'completed') {
      final parsed = _parseInvoiceNumber(invoiceNumber);
      if (parsed != null) {
        final updated = await _completeReturnWithRetry(
          errandId: parsed.errandId,
          paymentType: parsed.paymentType,
          status: PayTodayConfig.statusCompleted,
          transactionId: reference,
        );
        if (!updated && mounted) {
          setState(() => _error = 'Status could not be saved. Check My Orders in the app.');
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
          _message = 'Payment completed successfully. You can close this tab and return to the app.';
        });
      }
    } else if (status == 'cancelled' || status == 'canceled') {
      final parsed = _parseInvoiceNumber(invoiceNumber);
      if (parsed != null) {
        await _completeReturnWithRetry(
          errandId: parsed.errandId,
          paymentType: parsed.paymentType,
          status: PayTodayConfig.statusFailed,
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = false;
          _message = 'Payment was cancelled. You can close this tab and return to the app.';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = false;
          _message = status != null && status.isNotEmpty
              ? 'Payment status: $status. You can close this tab and return to the app.'
              : 'You can close this tab and return to the app.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LottoRunnersColors.gray50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing payment return...'),
                    ],
                  )
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _success ? Icons.check_circle : Icons.info_outline,
                            size: 64,
                            color: _success
                                ? LottoRunnersColors.accent
                                : LottoRunnersColors.primaryBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _success ? 'Payment successful' : 'Payment return',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _message ?? 'You can close this tab and return to the app.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
