import 'package:flutter/foundation.dart';

/// Configuration class for PayToday payment gateway integration
class PayTodayConfig {
  // PayToday Credentials (stored in Supabase Vault, not exposed to client)
  // These are only used for reference - actual values are in Supabase Edge Functions
  
  /// Supabase configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  /// Edge Function endpoints
  static const String createIntentFunction = 'paytoday-create-intent';
  static const String reportFailureFunction = 'paytoday-report-failure';
  static const String verifyPaymentFunction = 'paytoday-verify-payment';
  /// Called from /payment-return page; uses service role so DB update always runs.
  static const String completeReturnFunction = 'paytoday-complete-return';
  
  /// Payment configuration
  static const String currency = 'NAD'; // Namibian Dollar
  static const String countryCode = 'NA'; // Namibia
  
  /// Payment types
  static const String paymentTypeFirstHalf = 'first_half';
  static const String paymentTypeSecondHalf = 'second_half';
  static const String paymentTypeAdminPayout = 'admin_payout';
  
  /// Return URLs for payment flow
  /// Return URLs for payment flow
  static String getReturnUrl(String errandId, String paymentType) {
    if (kIsWeb) {
      return 'https://app.lottoerunners.com/payment-return';
    }
    return 'lottorunners://payment-return';
  }
  
  /// Payment status codes
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';
  static const String statusRefunded = 'refunded';
  
  /// Debug mode
  static const bool debugMode = kDebugMode;
  
  /// Log helper
  static void log(String message) {
    if (debugMode) {
      print('💳 PayToday: $message');
    }
  }
  
  /// Error log helper
  static void logError(String message, [dynamic error]) {
    print('❌ PayToday Error: $message');
    if (error != null) {
      print('   Details: $error');
    }
  }
}
