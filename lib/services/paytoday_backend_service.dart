import 'dart:convert';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/paytoday_config.dart';

/// Service to interact with PayToday backend (Supabase Edge Functions)
/// This service handles all server-side payment operations
class PayTodayBackendService {
  /// Create a payment intent for PayToday
  /// Returns a data URI containing HTML/JS to load in WebView
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String errandId,
    required double amount,
    required String paymentType,
    required String customerId,
    String? runnerId,
  }) async {
    try {
      PayTodayConfig.log(
          'Creating payment intent: errand=$errandId, amount=$amount, type=$paymentType');

      // Validate amount
      if (amount <= 0) {
        throw Exception('Payment amount must be greater than 0');
      }

      // Prepare request data
      final requestData = {
        'errand_id': errandId,
        'amount': amount,
        'currency': PayTodayConfig.currency,
        'payment_type': paymentType,
        'customer_id': customerId,
        'runner_id': runnerId,
        'return_url': PayTodayConfig.getSuccessUrl(errandId, paymentType),
        'cancel_url': PayTodayConfig.getCancelUrl(errandId, paymentType),
        'failure_url': PayTodayConfig.getFailureUrl(errandId, paymentType),
      };

      PayTodayConfig.log('Request data: $requestData');

      // Call Supabase Edge Function
      final response = await SupabaseConfig.client.functions
          .invoke(PayTodayConfig.createIntentFunction, body: requestData);

      PayTodayConfig.log('Response status: ${response.status}');

      if (response.status != 200) {
        throw Exception(
            'Failed to create payment intent: ${response.status} - ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      PayTodayConfig.log('Payment intent created successfully');

      // Create transaction record in database
      await _createTransactionRecord(
        errandId: errandId,
        customerId: customerId,
        runnerId: runnerId,
        amount: amount,
        paymentType: paymentType,
        intentData: responseData,
      );

      return responseData;
    } catch (e) {
      PayTodayConfig.logError('Failed to create payment intent', e);
      rethrow;
    }
  }

  /// Create a transaction record in the database
  static Future<void> _createTransactionRecord({
    required String errandId,
    required String customerId,
    String? runnerId,
    required double amount,
    required String paymentType,
    required Map<String, dynamic> intentData,
  }) async {
    try {
      await SupabaseConfig.client.from('paytoday_transactions').upsert({
        'errand_id': errandId,
        'customer_id': customerId,
        'runner_id': runnerId,
        'amount': amount,
        'currency': PayTodayConfig.currency,
        'payment_type': paymentType,
        'status': PayTodayConfig.statusPending,
        'payment_intent_data': intentData,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'errand_id,payment_type');

      PayTodayConfig.log('Transaction record created');
    } catch (e) {
      PayTodayConfig.logError('Failed to create transaction record', e);
      // Don't throw - this is a secondary operation
    }
  }

  /// Update transaction status
  static Future<void> updateTransactionStatus({
    required String errandId,
    required String paymentType,
    required String status,
    String? transactionId,
    String? errorMessage,
  }) async {
    try {
      PayTodayConfig.log(
          'Updating transaction status: errand=$errandId, type=$paymentType, status=$status');

      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      if (status == PayTodayConfig.statusCompleted) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await SupabaseConfig.client
          .from('paytoday_transactions')
          .update(updateData)
          .eq('errand_id', errandId)
          .eq('payment_type', paymentType);

      PayTodayConfig.log('Transaction status updated');
    } catch (e) {
      PayTodayConfig.logError('Failed to update transaction status', e);
      rethrow;
    }
  }

  /// Verify payment with PayToday server
  static Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
    required String errandId,
  }) async {
    try {
      PayTodayConfig.log(
          'Verifying payment: transaction=$transactionId, errand=$errandId');

      final requestData = {
        'transaction_id': transactionId,
        'errand_id': errandId,
      };

      final response = await SupabaseConfig.client.functions
          .invoke(PayTodayConfig.verifyPaymentFunction, body: requestData);

      if (response.status != 200) {
        throw Exception(
            'Failed to verify payment: ${response.status} - ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      PayTodayConfig.log('Payment verification result: $responseData');

      return responseData;
    } catch (e) {
      PayTodayConfig.logError('Failed to verify payment', e);
      rethrow;
    }
  }

  /// Report WebView failure to backend for logging
  static Future<void> reportFailure({
    required String errandId,
    required String paymentType,
    required String errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      PayTodayConfig.log('Reporting failure: $errorMessage');

      final requestData = {
        'errand_id': errandId,
        'payment_type': paymentType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
        'additional_data': additionalData,
      };

      await SupabaseConfig.client.functions
          .invoke(PayTodayConfig.reportFailureFunction, body: requestData);

      PayTodayConfig.log('Failure reported successfully');
    } catch (e) {
      PayTodayConfig.logError('Failed to report failure', e);
      // Don't throw - this is a logging operation
    }
  }

  /// Get transaction details
  static Future<Map<String, dynamic>?> getTransaction({
    required String errandId,
    required String paymentType,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('paytoday_transactions')
          .select()
          .eq('errand_id', errandId)
          .eq('payment_type', paymentType)
          .maybeSingle();

      return response;
    } catch (e) {
      PayTodayConfig.logError('Failed to get transaction', e);
      return null;
    }
  }

  /// Get all transactions for an errand
  static Future<List<Map<String, dynamic>>> getErrandTransactions(
      String errandId) async {
    try {
      final response = await SupabaseConfig.client
          .from('paytoday_transactions')
          .select()
          .eq('errand_id', errandId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      PayTodayConfig.logError('Failed to get errand transactions', e);
      return [];
    }
  }

  /// Calculate payment amount (50% for split payments)
  static double calculatePaymentAmount(
      double totalAmount, String paymentType) {
    if (paymentType == PayTodayConfig.paymentTypeFirstHalf ||
        paymentType == PayTodayConfig.paymentTypeSecondHalf) {
      return totalAmount / 2;
    }
    return totalAmount;
  }

  /// Check if errand has pending payments
  static Future<bool> hasPendingPayments(String errandId) async {
    try {
      final response = await SupabaseConfig.client
          .rpc('has_pending_payments', params: {'p_errand_id': errandId});

      return response == true;
    } catch (e) {
      PayTodayConfig.logError('Failed to check pending payments', e);
      return false;
    }
  }

  /// Get total paid amount for errand
  static Future<double> getTotalPaidAmount(String errandId) async {
    try {
      final response = await SupabaseConfig.client
          .rpc('get_errand_total_paid', params: {'p_errand_id': errandId});

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      PayTodayConfig.logError('Failed to get total paid amount', e);
      return 0.0;
    }
  }

  /// Get pending payment amount for errand
  static Future<double> getPendingAmount(String errandId) async {
    try {
      final response = await SupabaseConfig.client.rpc(
          'get_errand_pending_amount',
          params: {'p_errand_id': errandId});

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      PayTodayConfig.logError('Failed to get pending amount', e);
      return 0.0;
    }
  }
}
