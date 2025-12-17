import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:lotto_runners/services/notification_service.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://irfbqpruvkkbylwwikwx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyZmJxcHJ1dmtrYnlsd3dpa3d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMTk2NzEsImV4cCI6MjA2NjY5NTY3MX0.56qf3WDEWSlWH1iq5dBHNgsq1QFA82eGtgBeCBcxCdo';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Enable debug mode to see more details
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // Use PKCE flow for better security
        autoRefreshToken: true, // Automatically refresh tokens
      ),
    );
    
    print('✅ Supabase initialized successfully');
    print('🔗 Deep link scheme: io.supabase.lottorunners');
  }

  // Authentication helpers
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Test connection method for debugging
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to Supabase...');

      // Try a simple database query
      await client.from('users').select('count').limit(1);

      print('✅ Database connection successful!');
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    try {
      print('🔑 Attempting to sign in with: $email');
      print('🌐 Supabase URL: $supabaseUrl');

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ Sign in successful!');
      return response;
    } catch (e) {
      print('❌ Sign in error details: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Check if it's a network error and provide helpful message
      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('ClientException')) {
        throw Exception('Network connection error. Please check:\n'
            '1. Your internet connection\n'
            '2. If you\'re behind a corporate firewall\n'
            '3. Try refreshing the page\n'
            'Technical details: $e');
      }

      throw Exception('Sign in failed: $e');
    }
  }

  static Future<AuthResponse> signUpWithEmail(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      print('📧 Signing up user: $email');
      
      // Use different redirect URLs based on platform
      final redirectUrl = kIsWeb
          ? 'https://app.lottoerunners.com/confirm-email'
          : 'io.supabase.lottorunners://confirm-email';
      
      print('🔗 Email confirmation redirect URL: $redirectUrl');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
        emailRedirectTo: redirectUrl,
      );

      print('✅ Sign up successful! Email confirmation sent to: $email');
      return response;
    } on AuthApiException catch (e) {
      print('❌ Sign up AuthApiException: $e');
      print('❌ Error code: ${e.code}');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.statusCode}');
      
      // Handle specific error cases
      if (e.message.toLowerCase().contains('error sending confirmation email') ||
          e.message.toLowerCase().contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. This could be due to:\n1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n2. Email rate limits exceeded\n3. Email template configuration issue\n4. SMTP provider authentication failed\n\nPlease check your Supabase SMTP settings or try again later.');
      } else if (e.code == 'email_address_invalid' || 
                 e.message.toLowerCase().contains('invalid email')) {
        throw Exception('INVALID_EMAIL');
      } else if (e.statusCode == 429 || e.message.toLowerCase().contains('rate limit')) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('AUTH_ERROR: ${e.message}');
      }
    } on AuthRetryableFetchException catch (e) {
      print('❌ Sign up AuthRetryableFetchException: $e');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.statusCode}');
      
      // Parse the error message
      if (e.message.contains('Error sending confirmation email') ||
          e.message.contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. This is usually due to:\n1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n2. SMTP authentication failed (wrong credentials)\n3. Email rate limits exceeded\n4. Invalid email template configuration\n\nPlease check your Supabase SMTP settings or try again later.');
      } else {
        throw Exception('NETWORK_ERROR: ${e.message}');
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Check for email sending errors in the error string
      final errorString = e.toString();
      if (errorString.contains('Error sending confirmation email') ||
          errorString.contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. Please check your Supabase SMTP configuration.');
      }
      
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email to user
  static Future<void> resetPasswordForEmail(String email) async {
    try {
      print('📧 Sending password reset email to: $email');

      // Use different redirect URLs based on platform
      final redirectUrl = kIsWeb
          ? 'https://app.lottoerunners.com/password-reset'
          : 'io.supabase.lottorunners://reset-password';
      
      print('🔗 Redirect URL: $redirectUrl');

      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      print('✅ Password reset email sent successfully');
    } on AuthApiException catch (e) {
      print('❌ Password reset AuthApiException: $e');

      // Check for specific error codes
      if (e.code == 'email_address_invalid' ||
          e.message.toLowerCase().contains('invalid')) {
        throw Exception('INVALID_EMAIL');
      } else if (e.statusCode == 429 ||
          e.message.toLowerCase().contains('rate limit')) {
        throw Exception('RATE_LIMIT');
      } else if (e.message
              .toLowerCase()
              .contains('error sending confirmation email') ||
          e.message.toLowerCase().contains('unexpected_failure')) {
        // Mirror the detailed messaging we use elsewhere
        throw Exception(
            'EMAIL_SEND_FAILED: Unable to send password reset email. This is usually due to:\n'
            '1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n'
            '2. SMTP authentication failed (wrong credentials)\n'
            '3. Email rate limits exceeded\n'
            '4. Invalid email template configuration\n\n'
            'Please check your Supabase SMTP settings or try again later.');
      } else {
        throw Exception('AUTH_ERROR: ${e.message}');
      }
    } on AuthRetryableFetchException catch (e) {
      print('❌ Password reset AuthRetryableFetchException: $e');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.statusCode}');

      final lowerMessage = e.message.toLowerCase();

      // Check for email sending failures (500 status with "Error sending recovery email" or "unexpected_failure")
      // The error message is often JSON: {"code":"unexpected_failure","message":"Error sending recovery email"}
      final isEmailSendFailure = e.statusCode == 500 && 
          (lowerMessage.contains('error sending recovery email') ||
           lowerMessage.contains('error sending') ||
           lowerMessage.contains('unexpected_failure'));
      
      if (isEmailSendFailure) {
        print('📧 Detected email sending failure - providing user guidance');
        throw Exception(
            'EMAIL_SEND_FAILED: Unable to send password reset email. This is usually due to:\n'
            '1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n'
            '2. SMTP authentication failed (wrong credentials)\n'
            '3. Email rate limits exceeded\n'
            '4. Invalid email template configuration\n\n'
            'Please check your Supabase SMTP settings or try again later.');
      }
      
      // Check for network timeouts (504)
      if (lowerMessage.contains('upstream request timeout') ||
          lowerMessage.contains('504') ||
          e.statusCode == 504) {
        throw Exception(
            'NETWORK_ERROR: The password reset service timed out while contacting the authentication server.\n'
            'This is usually temporary and caused by network issues or email provider timeouts.\n'
            'Please wait a minute and try again. If this keeps happening, contact support so we can check Supabase/SMTP status.');
      }

      // Generic network error for other cases
      throw Exception('NETWORK_ERROR: ${e.message}');
    } catch (e) {
      print('❌ Password reset error: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Resend email confirmation for unverified users
  static Future<void> resendEmailConfirmation(String email) async {
    try {
      print('📧 Resending email confirmation to: $email');

      // Use different redirect URLs based on platform
      final redirectUrl = kIsWeb
          ? 'https://app.lottoerunners.com/confirm-email'
          : 'io.supabase.lottorunners://confirm-email';
      
      print('🔗 Email confirmation redirect URL: $redirectUrl');

      await client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: redirectUrl,
      );

      print('✅ Email confirmation resent successfully');
    } on AuthApiException catch (e) {
      print('❌ Resend confirmation AuthApiException: $e');
      print('❌ Error code: ${e.code}');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.statusCode}');
      
      // Handle specific error cases
      if (e.message.toLowerCase().contains('error sending confirmation email') ||
          e.message.toLowerCase().contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. This could be due to:\n1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n2. Email rate limits exceeded\n3. Email template configuration issue\n4. SMTP provider authentication failed\n\nPlease check your Supabase SMTP settings or try again later.');
      } else if (e.code == 'email_address_invalid' || 
                 e.message.toLowerCase().contains('invalid email')) {
        throw Exception('INVALID_EMAIL');
      } else if (e.statusCode == 429 || e.message.toLowerCase().contains('rate limit')) {
        throw Exception('RATE_LIMIT');
      } else {
        throw Exception('AUTH_ERROR: ${e.message}');
      }
    } on AuthRetryableFetchException catch (e) {
      print('❌ Resend confirmation AuthRetryableFetchException: $e');
      print('❌ Error message: ${e.message}');
      print('❌ Status code: ${e.statusCode}');
      
      // Parse the error message
      if (e.message.contains('Error sending confirmation email') ||
          e.message.contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. This is usually due to:\n1. SMTP configuration issue (check Settings → Authentication → SMTP Settings)\n2. SMTP authentication failed (wrong credentials)\n3. Email rate limits exceeded\n4. Invalid email template configuration\n\nPlease check your Supabase SMTP settings or try again later.');
      } else {
        throw Exception('NETWORK_ERROR: ${e.message}');
      }
    } catch (e) {
      print('❌ Resend confirmation error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Check for email sending errors in the error string
      final errorString = e.toString();
      if (errorString.contains('Error sending confirmation email') ||
          errorString.contains('unexpected_failure')) {
        throw Exception('EMAIL_SEND_FAILED: Unable to send confirmation email. Check SMTP configuration in Supabase dashboard (Settings → Authentication → SMTP Settings).');
      }
      
      throw Exception('Failed to resend email confirmation: $e');
    }
  }

  /// Check if current user's email is verified
  static bool get isEmailVerified {
    final user = currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// Get current user's email verification status
  static Map<String, dynamic> getEmailVerificationStatus() {
    final user = currentUser;
    if (user == null) {
      return {
        'isVerified': false,
        'email': null,
        'verifiedAt': null,
        'message': 'No user logged in'
      };
    }

    return {
      'isVerified': user.emailConfirmedAt != null,
      'email': user.email,
      'verifiedAt': user.emailConfirmedAt,
      'message': user.emailConfirmedAt != null
          ? 'Email is verified'
          : 'Email verification required'
    };
  }

  // Database helpers
  static Future<List<Map<String, dynamic>>> getErrands({String? status}) async {
    try {
      var query = client.from('errands').select('''
        *,
        customer:customer_id(full_name, phone),
        runner:runner_id(full_name, phone)
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to fetch errands: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getMyErrands(String userId) async {
    try {
      final result = await client
          .from('errands')
          .select('''
        *,
        customer:customer_id(full_name, phone),
        runner:runner_id(full_name, phone)
      ''')
          .or('customer_id.eq.$userId,runner_id.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to fetch my errands: $e');
    }
  }

  static Future<Map<String, dynamic>> createErrand(
      Map<String, dynamic> errandData) async {
    try {
      // Check authentication
      final user = currentUser;
      if (user == null) {
        print('❌ [DEBUG] createErrand - User not authenticated');
        throw Exception('User must be authenticated to create errands');
      }
      print('✅ [DEBUG] createErrand - User authenticated: ${user.id}');
      
      // Remove customer_id if present - trigger will set it
      final cleanData = Map<String, dynamic>.from(errandData);
      if (cleanData.containsKey('customer_id')) {
        print('⚠️ [DEBUG] createErrand - Removing customer_id from payload (trigger will set it)');
        cleanData.remove('customer_id');
      }
      
      print('📤 [DEBUG] createErrand - Inserting errand with category: ${cleanData['category']}');
      final response =
          await client.from('errands').insert(cleanData).select().single();
      print('✅ [DEBUG] createErrand - Errand created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ [DEBUG] createErrand - Error: $e');
      if (e.toString().contains('RLS') || e.toString().contains('row-level security')) {
        print('❌ [DEBUG] createErrand - RLS policy violation detected');
        print('❌ [DEBUG] createErrand - Current user: ${currentUser?.id}');
        print('❌ [DEBUG] createErrand - Run fix_errand_insert_rls_for_trigger.sql to fix RLS policy');
      }
      throw Exception('Failed to create errand: $e');
    }
  }

  /// Creates an errand only when it's accepted by a runner (for immediate requests)
  static Future<Map<String, dynamic>> createAcceptedErrand(
      Map<String, dynamic> errandData, String runnerId) async {
    try {
      // Remove the pending ID and other fields that shouldn't be in database
      final cleanData = Map<String, dynamic>.from(errandData);
      cleanData.remove('id'); // Remove pending ID, let database generate UUID
      cleanData.remove('pending_since'); // Remove pending timestamp

      final acceptedData = {
        ...cleanData,
        'status': 'accepted',
        'runner_id': runnerId,
        'accepted_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response =
          await client.from('errands').insert(acceptedData).select().single();

      // Create chat conversation
      await _createErrandChat(response['id'], errandData['customer_id'],
          runnerId, errandData['title']);

      return response;
    } catch (e) {
      throw Exception('Failed to create accepted errand: $e');
    }
  }

  static Future<void> updateErrandStatus(String errandId, String status) async {
    try {
      print('🔄 Updating errand status: $errandId to $status');

      // Get errand details before updating
      final errandResponse = await client
          .from('errands')
          .select('customer_id, title, category')
          .eq('id', errandId)
          .single();

      final customerId = errandResponse['customer_id'];
      final errandTitle = errandResponse['title'];
      final category = errandResponse['category'];

      final response = await client.from('errands').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);

      print('✅ Errand status updated successfully: $response');
    } catch (e) {
      print('❌ Error updating errand status: $e');
      throw Exception('Failed to update errand status: $e');
    }
  }

  static Future<void> cancelErrand(String errandId,
      {String? cancelledBy, String? reason}) async {
    try {
      // Get errand details first
      final errandResponse = await client
          .from('errands')
          .select('customer_id, runner_id, title, status')
          .eq('id', errandId)
          .single();

      final customerId = errandResponse['customer_id'];
      final runnerId = errandResponse['runner_id'];
      final errandTitle = errandResponse['title'];
      final currentStatus = errandResponse['status'];

      // Check if cancellation is allowed - only allow cancellation of accepted errands
      if (currentStatus == 'completed' || currentStatus == 'cancelled') {
        throw Exception('Cannot cancel $currentStatus errand');
      }

      if (currentStatus == 'in_progress') {
        throw Exception('Cannot cancel errand that is in progress');
      }

      // Update errand status
      await client.from('errands').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);

      // Send cancellation message to chat if there's a runner
      if (runnerId != null) {
        await _sendStatusUpdateMessage(errandId, runnerId, 'cancelled', reason);
        await _closeErrandChat(errandId);
      }

      // Notify the other party about cancellation if we know who cancelled
      if (cancelledBy != null) {
        if (cancelledBy == customerId && runnerId != null) {
          await _notifyRunnerErrandCancelled(runnerId, customerId, errandTitle);
        } else if (cancelledBy == runnerId) {
          await _notifyCustomerRunnerCancelled(
              customerId, runnerId, errandTitle);
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel errand: $e');
    }
  }

  static Future<void> acceptErrand(String errandId, String runnerId) async {
    try {
      print('🔄 Starting errand acceptance process...');
      print('🔄 Errand ID: $errandId');
      print('🔄 Runner ID: $runnerId');

      // Check if runner is verified first
      final canAccept = await canRunnerAcceptErrands(runnerId);
      if (!canAccept) {
        throw Exception(
            'Cannot accept errand. You must be verified to accept errands. Please complete your verification process first.');
      }

      // Check runner limits first
      print('🚦 DEBUG: [ERRAND] Checking runner limits before acceptance...');
      final limits = await checkRunnerLimits(runnerId);
      print('🚦 DEBUG: [ERRAND] Runner limits: $limits');

      if (!limits['can_accept_errands']) {
        final totalCount = limits['total_active_count'] ?? 0;
        final totalLimit = limits['total_limit'] ?? 2;
        throw Exception(
            'Cannot accept errand. You have reached your limit of $totalLimit active jobs (currently have $totalCount). Please complete existing jobs before accepting new ones.');
      }

      // Get errand details first
      final errandResponse = await client
          .from('errands')
          .select('customer_id, title, status, runner_id')
          .eq('id', errandId)
          .single();

      print('📋 Current errand details: $errandResponse');

      final customerId = errandResponse['customer_id'];
      final errandTitle = errandResponse['title'];
      final currentStatus = errandResponse['status'];
      final currentRunnerId = errandResponse['runner_id'];

      // Check if errand is already accepted
      if (currentStatus == 'accepted' && currentRunnerId == runnerId) {
        print('⚠️ Errand already accepted by this runner');
        return;
      }

      // Check if errand is in a valid state for acceptance
      if (currentStatus != 'posted' && currentStatus != 'pending') {
        throw Exception('Cannot accept errand with status: $currentStatus');
      }

      print('🔄 Updating errand status to accepted...');

      // Update errand status
      final updateResult = await client.from('errands').update({
        'runner_id': runnerId,
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);

      print('✅ Errand acceptance update result: $updateResult');

      // Verify the update was successful
      final verifyResponse = await client
          .from('errands')
          .select('status, runner_id, accepted_at')
          .eq('id', errandId)
          .single();

      print('🔍 Verification - Updated errand: $verifyResponse');

      // Create chat conversation
      await _createErrandChat(errandId, customerId, runnerId, errandTitle);

      print('✅ Errand acceptance process completed successfully');
    } catch (e) {
      print('❌ Error in acceptErrand: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to accept errand: $e');
    }
  }

  // Helper method to create chat conversation when errand is accepted
  static Future<void> _createErrandChat(String errandId, String customerId,
      String runnerId, String errandTitle) async {
    try {
      // Create conversation
      final conversationResponse = await client
          .from('chat_conversations')
          .insert({
            'errand_id': errandId,
            'customer_id': customerId,
            'runner_id': runnerId,
            'status': 'active',
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'];

      // Send initial welcome message
      await client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': runnerId,
        'message':
            'Hi! I\'ve accepted your errand "$errandTitle". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      print('✅ Chat conversation created for errand: $errandId');
    } catch (e) {
      print('❌ Error creating chat conversation: $e');
      // Don't throw here as the errand was accepted successfully
    }
  }

  // Get available errands for runners (posted and no runner assigned)
  static Future<List<Map<String, dynamic>>> getAvailableErrands(
      {String? category,
      bool? requiresVehicle,
      String? vehicleType,
      String? runnerVehicleType}) async {
    try {
      var query = client.from('errands').select('''
        *,
        customer:customer_id(full_name, phone)
      ''').inFilter('status', ['posted', 'pending']).filter('runner_id', 'is', null);

      // Exclude immediate errands from available errands list (they are handled by popup service)
      query = query.neq('is_immediate', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      // Note: needs_vehicle field removed from database, filtering now based on vehicle_type only

      if (vehicleType != null) {
        query = query.eq('vehicle_type', vehicleType);
      }

      // Filter by runner's vehicle type: show errands with matching vehicle type OR errands with no vehicle requirement
      if (runnerVehicleType != null && runnerVehicleType.isNotEmpty) {
        // Show errands that either:
        // 1. Have no vehicle type requirement (null or empty vehicle_type)
        // 2. Match the runner's vehicle type
        query =
            query.or('vehicle_type.is.null,vehicle_type.eq.$runnerVehicleType');
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw Exception('Failed to fetch available errands: $e');
    }
  }

  // Get errands assigned to a specific runner
  static Future<List<Map<String, dynamic>>> getRunnerErrands(String runnerId,
      {String? status}) async {
    try {
      print('🔍 getRunnerErrands called with runnerId: $runnerId');
      print('🔍 Current user: ${currentUser?.id}');
      print('🔍 Current user email: ${currentUser?.email}');

      var query = client.from('errands').select('''
        *,
        customer:customer_id(full_name, phone)
      ''').eq('runner_id', runnerId);

      // Only return errands that have been properly accepted (not just posted)
      // This prevents errands from showing as "available" when they shouldn't
      query =
          query.inFilter('status', ['accepted', 'in_progress', 'completed']);

      if (status != null) {
        query = query.eq('status', status);
        print('🔍 Filtering by status: $status');
      }

      print('🔍 Executing query...');
      final result = await query.order('updated_at', ascending: false);
      print('🔍 Query result: $result');
      print('🔍 Result length: ${result.length}');

      final errands = List<Map<String, dynamic>>.from(result);
      print('🔍 Converted errands: $errands');

      return errands;
    } catch (e) {
      print('❌ Error in getRunnerErrands: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to fetch runner errands: $e');
    }
  }

  // Start an errand (change status from accepted to in_progress)
  static Future<void> startErrand(String errandId) async {
    try {
      print('🔧 startErrand called with ID: $errandId');

      // Get errand details first
      final errandResponse = await client
          .from('errands')
          .select('customer_id, runner_id, title')
          .eq('id', errandId)
          .single();

      final customerId = errandResponse['customer_id'];
      final runnerId = errandResponse['runner_id'];
      final errandTitle = errandResponse['title'];

      final updateData = {
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 Update data: $updateData');

      final result =
          await client.from('errands').update(updateData).eq('id', errandId);

      print('✅ Database update result: $result');
      print('✅ Errand status updated successfully to in_progress');

      // Send status update message to chat
      await _sendStatusUpdateMessage(errandId, runnerId, 'started');

      // Notify customer that runner has started
      await _notifyCustomerRunnerStarted(customerId, runnerId, errandTitle);
    } catch (e) {
      print('❌ Database error in startErrand: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to start errand: $e');
    }
  }

  // Begin work on an errand (change status from pending to in_progress)
  static Future<void> beginWork(String errandId) async {
    try {
      await client.from('errands').update({
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
    } catch (e) {
      throw Exception('Failed to begin work on errand: $e');
    }
  }

  // Complete an errand (change status from in_progress to completed)
  static Future<void> completeErrand(String errandId) async {
    try {
      // Get errand details first
      final errandResponse = await client
          .from('errands')
          .select('customer_id, runner_id, title')
          .eq('id', errandId)
          .single();

      final customerId = errandResponse['customer_id'];
      final runnerId = errandResponse['runner_id'];
      final errandTitle = errandResponse['title'];

      await client.from('errands').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);

      // Send status update message to chat
      await _sendStatusUpdateMessage(errandId, runnerId, 'completed');

      // Close the chat conversation
      await _closeErrandChat(errandId);

      // Notify customer that errand is completed
      await _notifyCustomerErrandCompleted(customerId, runnerId, errandTitle);
    } catch (e) {
      throw Exception('Failed to complete errand: $e');
    }
  }

  // Helper method to send status update messages to chat
  static Future<void> _sendStatusUpdateMessage(
      String errandId, String? runnerId, String status,
      [String? reason]) async {
    try {
      if (runnerId == null) return;

      // Get conversation for this errand
      final conversationResponse = await client
          .from('chat_conversations')
          .select('id')
          .eq('errand_id', errandId)
          .maybeSingle();

      if (conversationResponse != null) {
        String message = '';
        switch (status) {
          case 'started':
            message = '🚀 I\'ve started working on your errand!';
            break;
          case 'completed':
            message = '✅ Your errand has been completed successfully!';
            break;
          case 'cancelled':
            message = reason != null
                ? '❌ Errand cancelled: $reason'
                : '❌ Errand has been cancelled';
            break;
        }

        if (message.isNotEmpty) {
          await client.from('chat_messages').insert({
            'conversation_id': conversationResponse['id'],
            'sender_id': runnerId,
            'message': message,
            'message_type': 'status_update',
          });
        }
      }
    } catch (e) {
      print('❌ Error sending status update message: $e');
    }
  }

  // Helper method to close errand chat
  static Future<void> _closeErrandChat(String errandId) async {
    try {
      await client.from('chat_conversations').update({
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('errand_id', errandId);
    } catch (e) {
      print('❌ Error closing errand chat: $e');
    }
  }

  // Helper method to notify customer that runner has started
  static Future<void> _notifyCustomerRunnerStarted(
      String customerId, String runnerId, String errandTitle) async {
    try {
      // Import notification service dynamically to avoid circular dependencies
      // This will be handled by the notification service when called
      print(
          '📱 Notifying customer $customerId that runner $runnerId started errand: $errandTitle');
    } catch (e) {
      print('❌ Error notifying customer: $e');
    }
  }

  // Helper method to notify customer that errand is completed
  static Future<void> _notifyCustomerErrandCompleted(
      String customerId, String runnerId, String errandTitle) async {
    try {
      print(
          '📱 Notifying customer $customerId that errand is completed: $errandTitle');
    } catch (e) {
      print('❌ Error notifying customer: $e');
    }
  }

  // Helper method to notify runner that errand was cancelled by customer
  static Future<void> _notifyRunnerErrandCancelled(
      String runnerId, String customerId, String errandTitle) async {
    try {
      print(
          '📱 Notifying runner $runnerId that customer $customerId cancelled errand: $errandTitle');

      // Get customer name for notification
      final customerResponse = await client
          .from('profiles')
          .select('full_name')
          .eq('id', customerId)
          .single();

      final customerName = customerResponse['full_name'] ?? 'Customer';

      // Only notify if current user is the runner
      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == runnerId) {
        await NotificationService.notifyErrandCancelledByCustomer(
            errandTitle, customerName);
      }
    } catch (e) {
      print('❌ Error notifying runner: $e');
    }
  }

  // Helper method to notify customer that runner cancelled
  static Future<void> _notifyCustomerRunnerCancelled(
      String customerId, String runnerId, String errandTitle) async {
    try {
      print(
          '📱 Notifying customer $customerId that runner $runnerId cancelled errand: $errandTitle');

      // Get runner name for notification
      final runnerResponse = await client
          .from('profiles')
          .select('full_name')
          .eq('id', runnerId)
          .single();

      final runnerName = runnerResponse['full_name'] ?? 'Runner';

      // Only notify if current user is the customer
      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == customerId) {
        await NotificationService.notifyErrandCancelledByRunner(
            errandTitle, runnerName);
      }
    } catch (e) {
      print('❌ Error notifying customer: $e');
    }
  }

  // Helper method to notify runner that transportation was cancelled by customer
  static Future<void> _notifyRunnerTransportationCancelled(
      String runnerId, String customerId, String serviceName) async {
    try {
      print(
          '📱 Notifying runner $runnerId that customer $customerId cancelled transportation: $serviceName');

      // Get customer name for notification
      final customerResponse = await client
          .from('profiles')
          .select('full_name')
          .eq('id', customerId)
          .single();

      final customerName = customerResponse['full_name'] ?? 'Customer';

      // Only notify if current user is the runner
      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == runnerId) {
        await NotificationService.notifyTransportationCancelledByCustomer(
            serviceName, customerName);
      }
    } catch (e) {
      print('❌ Error notifying runner: $e');
    }
  }

  // Helper method to notify customer that runner cancelled transportation
  static Future<void> _notifyCustomerTransportationCancelled(
      String customerId, String runnerId, String serviceName) async {
    try {
      print(
          '📱 Notifying customer $customerId that runner $runnerId cancelled transportation: $serviceName');

      // Get runner name for notification
      final runnerResponse = await client
          .from('profiles')
          .select('full_name')
          .eq('id', runnerId)
          .single();

      final runnerName = runnerResponse['full_name'] ?? 'Runner';

      // Only notify if current user is the customer
      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == customerId) {
        await NotificationService.notifyTransportationCancelledByRunner(
            serviceName, runnerName);
      }
    } catch (e) {
      print('❌ Error notifying customer: $e');
    }
  }

  // Get chat conversation for an errand
  static Future<Map<String, dynamic>?> getErrandChat(String errandId) async {
    try {
      final response = await client.from('chat_conversations').select('''
            *,
            errand:errands(title, status),
            customer:users!chat_conversations_customer_id_fkey(full_name, avatar_url),
            runner:users!chat_conversations_runner_id_fkey(full_name, avatar_url)
          ''').eq('errand_id', errandId).maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching errand chat: $e');
      return null;
    }
  }

  // Get chat messages for a conversation
  static Future<List<Map<String, dynamic>>> getChatMessages(
      String conversationId) async {
    try {
      final response = await client
          .from('chat_messages')
          .select('''
            *,
            sender:users!chat_messages_sender_id_fkey(full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching chat messages: $e');
      return [];
    }
  }

  // User profile helpers
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Get complete user profile including runner application data
  static Future<Map<String, dynamic>?> getCompleteUserProfile(
      String userId) async {
    try {
      // Get user profile
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) return null;

      // Get runner application if user is a runner
      if (userProfile['user_type'] == 'runner') {
        final runnerApp = await getRunnerApplication(userId);
        if (runnerApp != null) {
          // Merge runner application data into user profile
          userProfile['has_vehicle'] = runnerApp['has_vehicle'] ?? false;
          userProfile['vehicle_type'] =
              runnerApp['vehicle_type']?.toString() ?? '';
          userProfile['vehicle_details'] = runnerApp['vehicle_details'];
          userProfile['license_number'] = runnerApp['license_number'];
          userProfile['verification_status'] = runnerApp['verification_status'];
        } else {
          // If no runner application, set default values for runners
          userProfile['has_vehicle'] = false;
          userProfile['vehicle_type'] = '';
        }
      }

      return userProfile;
    } catch (e) {
      throw Exception('Failed to fetch complete user profile: $e');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (currentUser == null) return null;

    try {
      final profile = await getUserProfile(currentUser!.id);

      // If profile doesn't exist, create a default one
      if (profile == null) {
        print('User profile not found, creating default profile...');
        final defaultProfile = {
          'id': currentUser!.id,
          'email': currentUser!.email ?? '',
          'full_name': currentUser!.userMetadata?['full_name'] ??
              currentUser!.email ??
              'Unknown User',
          'user_type': currentUser!.userMetadata?['user_type'] ?? 'individual',
          'is_verified': false,
          'has_vehicle': false,
        };

        await createUserProfile(defaultProfile);
        return defaultProfile;
      }

      return profile;
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  static Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      // First check if profile already exists
      final existingProfile = await client
          .from('users')
          .select('id')
          .eq('id', userData['id'])
          .maybeSingle();

      if (existingProfile != null) {
        // Profile exists, update it instead
        await client.from('users').update(userData).eq('id', userData['id']);
      } else {
        // Profile doesn't exist, create it
        await client.from('users').insert(userData);
      }
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Mark terms and conditions as accepted for the current user
  static Future<bool> acceptTermsAndConditions() async {
    if (currentUser == null) return false;

    try {
      await client.from('users').update({
        'terms_accepted': true,
        'terms_accepted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser!.id);
      return true;
    } catch (e) {
      print('Error accepting terms: $e');
      return false;
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) return false;

    try {
      await client.from('users').update(updates).eq('id', currentUser!.id);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Runner application helpers
  static Future<void> submitRunnerApplication(
      Map<String, dynamic> applicationData) async {
    try {
      // Insert into runner_applications table
      await client.from('runner_applications').insert(applicationData);

      // Update the users table to sync has_vehicle (only if the column exists)
      final userId = applicationData['user_id'];
      if (userId != null) {
        // Only update has_vehicle field, don't try to update vehicle_type in users table
        await client.from('users').update({
          'has_vehicle': applicationData['has_vehicle'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      throw Exception('Failed to submit runner application: $e');
    }
  }

  static Future<Map<String, dynamic>?> getRunnerApplication(
      String userId) async {
    try {
      // Get the most recent application for this user
      final response = await client
          .from('runner_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch runner application: $e');
    }
  }

  // Enhanced runner application with documents
  static Future<Map<String, dynamic>?> getRunnerApplicationWithDocuments(
      String userId) async {
    try {
      final response = await client.rpc(
        'get_runner_application_with_documents',
        params: {'user_uuid': userId},
      );

      if (response != null && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch runner application with documents: $e');
    }
  }

  // Update runner application documents
  static Future<void> updateRunnerApplicationDocuments(String userId,
      {String? driverLicensePdf,
      String? codeOfConductPdf,
      List<String>? vehiclePhotos,
      List<String>? licenseDiscPhotos}) async {
    try {
      await client.rpc(
        'update_runner_application_documents',
        params: {
          'user_uuid': userId,
          'driver_license_pdf_param': driverLicensePdf,
          'code_of_conduct_pdf_param': codeOfConductPdf,
          'vehicle_photos_param': vehiclePhotos,
          'license_disc_photos_param': licenseDiscPhotos,
        },
      );
    } catch (e) {
      throw Exception('Failed to update runner application documents: $e');
    }
  }

  // Storage helpers
  static Future<String> uploadImage(
      String bucket, String path, Uint8List bytes) async {
    try {
      // Check if file already exists and remove it
      try {
        await client.storage.from(bucket).remove([path]);
      } catch (e) {
        // File doesn't exist, which is fine
      }

      // Upload the new file
      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL
      final url = client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<String?> uploadProfileImage(
      String filePath, List<int> fileBytes) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '${user.id}.$fileExt';

      await client.storage.from('profiles').uploadBinary(
            fileName,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrl = client.storage.from('profiles').getPublicUrl(fileName);

      await updateUserProfile({'avatar_url': imageUrl});

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Admin helpers
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get all runners for browse runners page
  static Future<List<Map<String, dynamic>>> getRunners() async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('user_type', 'runner')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch runners: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllErrands() async {
    try {
      final response = await client.from('errands').select('''
          *,
          customer:customer_id(full_name, email),
          runner:runner_id(full_name, email)
        ''').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch errands: $e');
    }
  }

  static Future<List<Map<String, dynamic>>>
      getPendingRunnerApplications() async {
    try {
      final response = await client
          .from('runner_applications')
          .select('''
          *,
          user:user_id(full_name, email, phone)
        ''')
          .eq('verification_status', 'pending')
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending applications: $e');
    }
  }

  static Future<void> updateRunnerApplicationStatus(
      String applicationId, String status, String? notes) async {
    try {
      // Try using RPC function first for comprehensive update
      try {
        final rpcResponse =
            await client.rpc('update_runner_application_status', params: {
          'application_id': applicationId,
          'status': status,
          'notes': notes,
        });

        if (rpcResponse == true) {
          print(
              '✅ Runner application $status and user verification status synced via RPC');
          return;
        }
      } catch (rpcError) {
        print('⚠️ RPC failed, trying direct update: $rpcError');
      }

      // Fallback to direct update
      // First get the application data to sync with users table
      final application = await client
          .from('runner_applications')
          .select('user_id, has_vehicle, vehicle_type')
          .eq('id', applicationId)
          .single();

      // Update the runner_applications table
      await client.from('runner_applications').update({
        'verification_status': status,
        'notes': notes,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': currentUser?.id,
      }).eq('id', applicationId);

      // Sync with users table for both approved and rejected applications
      if (application['user_id'] != null) {
        final isVerified = status == 'approved';

        await client.from('users').update({
          'is_verified': isVerified,
          'has_vehicle': application['has_vehicle'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', application['user_id']);

        print(
            '✅ Runner application $status and user verification status synced');
      }
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Check if a runner can accept errands (must be verified)
  static Future<bool> canRunnerAcceptErrands(String userId) async {
    try {
      final user = await client
          .from('users')
          .select('is_verified, user_type')
          .eq('id', userId)
          .single();

      return user['user_type'] == 'runner' && user['is_verified'] == true;
    } catch (e) {
      print('❌ SupabaseConfig: Error checking runner verification: $e');
      return false;
    }
  }

  /// Get verified runners for errand notifications
  static Future<List<Map<String, dynamic>>> getVerifiedRunners() async {
    try {
      final response = await client
          .from('users')
          .select('id, full_name, email, phone, has_vehicle, vehicle_type')
          .eq('user_type', 'runner')
          .eq('is_verified', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ SupabaseConfig: Error getting verified runners: $e');
      return [];
    }
  }

  /// Update vehicle information for verified runners
  static Future<bool> updateVerifiedRunnerVehicle({
    required String userId,
    required bool hasVehicle,
    String? vehicleType,
    String? vehicleDetails,
    String? licenseNumber,
  }) async {
    try {
      print(
          '🔄 SupabaseConfig: Updating vehicle info for verified runner $userId');

      // Try using RPC function first
      try {
        final rpcResponse =
            await client.rpc('update_verified_runner_vehicle', params: {
          'p_user_id': userId,
          'p_has_vehicle': hasVehicle,
          'p_vehicle_type': vehicleType,
          'p_vehicle_details': vehicleDetails,
          'p_license_number': licenseNumber,
        });

        if (rpcResponse == true) {
          print('✅ SupabaseConfig: Vehicle info updated successfully via RPC');
          return true;
        }
      } catch (rpcError) {
        print('⚠️ SupabaseConfig: RPC failed, trying direct update: $rpcError');
      }

      // Fallback to direct update
      final application = await client
          .from('runner_applications')
          .select('id')
          .eq('user_id', userId)
          .eq('verification_status', 'approved')
          .single();

      // Update runner application
      await client.from('runner_applications').update({
        'has_vehicle': hasVehicle,
        'vehicle_type': hasVehicle ? vehicleType : null,
        'vehicle_details': hasVehicle ? vehicleDetails : null,
        'license_number': hasVehicle ? licenseNumber : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', application['id']);

      // Update users table
      await client.from('users').update({
        'has_vehicle': hasVehicle,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print(
          '✅ SupabaseConfig: Vehicle info updated successfully via direct update');
      return true;
    } catch (e) {
      print('❌ SupabaseConfig: Failed to update vehicle info: $e');
      throw Exception('Failed to update vehicle information: $e');
    }
  }

  /// Get current vehicle information for verified runners
  static Future<Map<String, dynamic>?> getVerifiedRunnerVehicleInfo(
      String userId) async {
    try {
      print(
          '🔄 SupabaseConfig: Getting vehicle info for verified runner $userId');

      // Try using RPC function first
      try {
        final rpcResponse =
            await client.rpc('get_verified_runner_vehicle_info', params: {
          'p_user_id': userId,
        });

        if (rpcResponse != null && rpcResponse.isNotEmpty) {
          print(
              '✅ SupabaseConfig: Vehicle info retrieved successfully via RPC');
          return Map<String, dynamic>.from(rpcResponse.first);
        }
      } catch (rpcError) {
        print('⚠️ SupabaseConfig: RPC failed, trying direct query: $rpcError');
      }

      // Fallback to direct query
      final response = await client
          .from('runner_applications')
          .select('has_vehicle, vehicle_type, vehicle_details, license_number')
          .eq('user_id', userId)
          .eq('verification_status', 'approved')
          .maybeSingle();

      if (response != null) {
        print(
            '✅ SupabaseConfig: Vehicle info retrieved successfully via direct query');
        return Map<String, dynamic>.from(response);
      }

      return null;
    } catch (e) {
      print('❌ SupabaseConfig: Failed to get vehicle info: $e');
      throw Exception('Failed to get vehicle information: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final response = await client.from('payments').select('''
          *,
          errand:errand_id(title, category),
          customer:customer_id(full_name, email),
          runner:runner_id(full_name, email)
        ''').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  static Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      // Get user counts by type
      final usersResponse = await client
          .from('users')
          .select('id, user_type, created_at, is_verified');
      final errandsResponse = await client
          .from('errands')
          .select('id, status, created_at, price_amount, category');
      final paymentsResponse =
          await client.from('payments').select('amount, status, created_at');
      final reviewsResponse =
          await client.from('reviews').select('rating, created_at');

      // Process user data
      final totalUsers = usersResponse.length;
      final verifiedUsers =
          usersResponse.where((u) => u['is_verified'] == true).length;
      final runnerCount =
          usersResponse.where((u) => u['user_type'] == 'runner').length;
      final customerCount = usersResponse
          .where((u) =>
              u['user_type'] == 'individual' || u['user_type'] == 'business')
          .length;

      // Process errand data
      final totalErrands = errandsResponse.length;
      final completedErrands =
          errandsResponse.where((e) => e['status'] == 'completed').length;
      final activeErrands = errandsResponse
          .where((e) =>
              ['posted', 'accepted', 'in_progress'].contains(e['status']))
          .length;
      final completionRate =
          totalErrands > 0 ? (completedErrands / totalErrands) * 100 : 0.0;

      // Calculate revenue
      double totalRevenue = 0;
      double monthlyRevenue = 0;
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      for (var payment in paymentsResponse) {
        if (payment['status'] == 'completed') {
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += amount;

          // Check if payment is from current month
          final createdAt = DateTime.parse(payment['created_at']);
          if (createdAt.isAfter(currentMonth)) {
            monthlyRevenue += amount;
          }
        }
      }

      // Calculate average rating
      double averageRating = 0;
      if (reviewsResponse.isNotEmpty) {
        final totalRating = reviewsResponse.fold<double>(
            0, (sum, review) => sum + (review['rating'] as num).toDouble());
        averageRating = totalRating / reviewsResponse.length;
      }

      // Category breakdown
      final categoryBreakdown = <String, int>{};
      for (var errand in errandsResponse) {
        final category = errand['category'] ?? 'other';
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }

      // Weekly trend data (last 7 days)
      final weeklyErrands = <String, int>{};
      final weeklyRevenue = <String, double>{};
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = '${date.day}/${date.month}';
        weeklyErrands[dateKey] = 0;
        weeklyRevenue[dateKey] = 0.0;
      }

      // Populate weekly data
      for (var errand in errandsResponse) {
        final createdAt = DateTime.parse(errand['created_at']);
        final dateKey = '${createdAt.day}/${createdAt.month}';
        if (weeklyErrands.containsKey(dateKey)) {
          weeklyErrands[dateKey] = weeklyErrands[dateKey]! + 1;
        }
      }

      for (var payment in paymentsResponse) {
        if (payment['status'] == 'completed') {
          final createdAt = DateTime.parse(payment['created_at']);
          final dateKey = '${createdAt.day}/${createdAt.month}';
          if (weeklyRevenue.containsKey(dateKey)) {
            weeklyRevenue[dateKey] = weeklyRevenue[dateKey]! +
                ((payment['amount'] as num?)?.toDouble() ?? 0.0);
          }
        }
      }

      return {
        'total_users': totalUsers,
        'verified_users': verifiedUsers,
        'runner_count': runnerCount,
        'customer_count': customerCount,
        'total_errands': totalErrands,
        'completed_errands': completedErrands,
        'active_errands': activeErrands,
        'completion_rate': completionRate,
        'total_revenue': totalRevenue,
        'monthly_revenue': monthlyRevenue,
        'average_rating': averageRating,
        'category_breakdown': categoryBreakdown,
        'weekly_errands': weeklyErrands,
        'weekly_revenue': weeklyRevenue,
        'growth_metrics': {
          'user_growth': _calculateGrowthRate(usersResponse, 'created_at'),
          'revenue_growth': _calculateRevenueGrowth(paymentsResponse),
          'errand_growth': _calculateGrowthRate(errandsResponse, 'created_at'),
        }
      };
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  static double _calculateGrowthRate(List<dynamic> data, String dateField) {
    if (data.length < 2) return 0.0;

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final currentMonth = DateTime(now.year, now.month);

    final lastMonthCount = data.where((item) {
      final createdAt = DateTime.parse(item[dateField]);
      return createdAt.isAfter(lastMonth) && createdAt.isBefore(currentMonth);
    }).length;

    final currentMonthCount = data.where((item) {
      final createdAt = DateTime.parse(item[dateField]);
      return createdAt.isAfter(currentMonth);
    }).length;

    if (lastMonthCount == 0) return currentMonthCount > 0 ? 100.0 : 0.0;
    return ((currentMonthCount - lastMonthCount) / lastMonthCount) * 100;
  }

  static double _calculateRevenueGrowth(List<dynamic> payments) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final currentMonth = DateTime(now.year, now.month);

    double lastMonthRevenue = 0;
    double currentMonthRevenue = 0;

    for (var payment in payments) {
      if (payment['status'] == 'completed') {
        final createdAt = DateTime.parse(payment['created_at']);
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

        if (createdAt.isAfter(lastMonth) && createdAt.isBefore(currentMonth)) {
          lastMonthRevenue += amount;
        } else if (createdAt.isAfter(currentMonth)) {
          currentMonthRevenue += amount;
        }
      }
    }

    if (lastMonthRevenue == 0) return currentMonthRevenue > 0 ? 100.0 : 0.0;
    return ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
  }

  static Future<void> deactivateUser(String userId) async {
    try {
      await client.from('users').update({
        'is_verified': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  static Future<void> createAdminUser(Map<String, dynamic> adminData) async {
    try {
      // Create the user in Supabase Auth using signUp
      // The handle_new_user trigger will automatically create the user profile
      final redirectUrl = kIsWeb
          ? 'https://app.lottoerunners.com/confirm-email'
          : 'io.supabase.lottorunners://confirm-email';
      
      print('📧 Creating admin user: ${adminData['email']}');
      print('🔗 Email confirmation redirect URL: $redirectUrl');

      final authResponse = await client.auth.signUp(
        email: adminData['email'],
        password: adminData['password'],
        data: {
          'full_name': adminData['full_name'],
          'user_type': 'admin',
        },
        emailRedirectTo: redirectUrl,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in authentication system');
      }

      final userId = authResponse.user!.id;

      // Update the user profile to set admin-specific fields
      // The trigger should have created the basic profile, now we update it
      try {
        await client.from('users').update({
          'phone': adminData['phone'],
          'is_verified': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (updateError) {
        print('⚠️  Warning: Could not update user profile: $updateError');
        print('ℹ️  User profile may have been created with default values');
      }

      // Sign out the newly created user to prevent session conflicts
      await client.auth.signOut();

      print('✅ Admin user created successfully: ${adminData['email']}');
      print('ℹ️  User ID: $userId');
      print(
          'ℹ️  User will receive a confirmation email and can sign in after confirming their email');
    } catch (e) {
      print('❌ Error creating admin user: $e');

      // Check if it's a duplicate email error
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('already registered')) {
        throw Exception(
            'A user with this email address already exists. Please use a different email address.');
      }

      throw Exception('Failed to create admin user: $e');
    }
  }

  /// Delete a user completely from the system
  /// This will remove the user from both the database and authentication system
  static Future<void> deleteUser(String userId) async {
    try {
      // First, delete all user-related data
      await deleteAllUserData(userId);

      // Then delete the user profile
      await client.from('users').delete().eq('id', userId);

      print('✅ User deleted successfully: $userId');
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Create a user of any type (admin, runner, business, individual)
  /// This function is designed for admin use and doesn't log in the created user
  static Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      // Create the user in Supabase Auth using signUp
      final redirectUrl = kIsWeb
          ? 'https://app.lottoerunners.com/confirm-email'
          : 'io.supabase.lottorunners://confirm-email';
      
      print('📧 Creating user: ${userData['email']}');
      print('🔗 Email confirmation redirect URL: $redirectUrl');

      final authResponse = await client.auth.signUp(
        email: userData['email'],
        password: userData['password'],
        data: {
          'full_name': userData['full_name'],
          'user_type': userData['user_type'],
        },
        emailRedirectTo: redirectUrl,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in authentication system');
      }

      final userId = authResponse.user!.id;

      // Update the user profile with additional fields
      try {
        await client.from('users').update({
          'phone': userData['phone'],
          'is_verified': userData['is_verified'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (updateError) {
        print('⚠️  Warning: Could not update user profile: $updateError');
        print('ℹ️  User profile may have been created with default values');
      }

      // Sign out the newly created user to prevent session conflicts
      await client.auth.signOut();

      print('✅ User created successfully: ${userData['email']}');
      print('ℹ️  User ID: $userId');
      print('ℹ️  User type: ${userData['user_type']}');
      print(
          'ℹ️  User will receive a confirmation email and can sign in after confirming their email');
    } catch (e) {
      print('❌ Error creating user: $e');

      // Check if it's a duplicate email error
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('already registered')) {
        throw Exception(
            'A user with this email address already exists. Please use a different email address.');
      }

      throw Exception('Failed to create user: $e');
    }
  }

  // ==========================================
  // ADMIN SERVICE MANAGEMENT FUNCTIONS
  // ==========================================

  // Services management
  static Future<List<Map<String, dynamic>>> getAllServices() async {
    try {
      final response = await client.from('services').select('*').order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveServices() async {
    try {
      final response = await client
          .from('services')
          .select('*')
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch active services: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final response = await client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('name');

      List<Map<String, dynamic>> services =
          List<Map<String, dynamic>>.from(response);

      // Define service order as requested by user
      final serviceOrder = [
        'delivery', // Delivery
        'shopping', // Personal Shopping
        'queue_sitting', // Queue sitting
        'document_services', // Document services
        'license_discs', // License disc renewal
        'elderly_services', // Elderly & disabled assistance
        'special_runs', // Special runs
      ];

      // Sort services by the defined order
      services.sort((a, b) {
        final aIndex = serviceOrder.indexOf(a['category'] ?? '');
        final bIndex = serviceOrder.indexOf(b['category'] ?? '');

        // If both services are in the order list, sort by their position
        if (aIndex != -1 && bIndex != -1) {
          return aIndex.compareTo(bIndex);
        }
        // If only one is in the order list, prioritize it
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        // If neither is in the order list, sort alphabetically
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      });

      return services;
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  // static Future<List<Map<String, dynamic>>> getServicesByCategory(
  //     String category) async {
  //   try {
  //     final response = await client
  //         .from('services')
  //         .select()
  //         .eq('category', category)
  //         .eq('is_active', true)
  //         .order('name');
  //     return List<Map<String, dynamic>>.from(response);
  //   } catch (e) {
  //     throw Exception('Failed to fetch services by category: $e');
  //   }
  // }

  static Future<Map<String, dynamic>> createService(
      Map<String, dynamic> serviceData) async {
    try {
      final response = await client
          .from('services')
          .insert({
            ...serviceData,
            'created_by': currentUser?.id,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  static Future<bool> updateService(
      String serviceId, Map<String, dynamic> updates) async {
    try {
      await client.from('services').update(updates).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  static Future<bool> deleteService(String serviceId) async {
    try {
      print('🗑️ Starting deletion of service: $serviceId');

      // Delete the service completely
      print('🗑️ Deleting service: $serviceId');
      final serviceResult =
          await client.from('services').delete().eq('id', serviceId);
      print('🗑️ Service deletion result: $serviceResult');

      print('✅ Service deleted successfully: $serviceId');
      return true;
    } catch (e) {
      print('❌ Error deleting service $serviceId: $e');
      print('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  static Future<bool> deactivateService(String serviceId) async {
    try {
      await client
          .from('services')
          .update({'is_active': false}).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error deactivating service: $e');
      return false;
    }
  }

  /// Update discount percentage for a service (errands)
  static Future<bool> updateServiceDiscount(
      String serviceId, double discountPercentage) async {
    try {
      if (discountPercentage < 0 || discountPercentage > 100) {
        throw Exception('Discount percentage must be between 0 and 100');
      }
      await client
          .from('services')
          .update({'discount_percentage': discountPercentage})
          .eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating service discount: $e');
      return false;
    }
  }

  /// Update discount percentage for a vehicle type (rides)
  static Future<bool> updateVehicleTypeDiscount(
      String vehicleTypeId, double discountPercentage) async {
    try {
      if (discountPercentage < 0 || discountPercentage > 100) {
        throw Exception('Discount percentage must be between 0 and 100');
      }
      await client
          .from('vehicle_types')
          .update({'discount_percentage': discountPercentage})
          .eq('id', vehicleTypeId);
      return true;
    } catch (e) {
      print('Error updating vehicle type discount: $e');
      return false;
    }
  }

  /// Calculate discounted price based on discount percentage
  static double calculateDiscountedPrice(
      double originalPrice, double discountPercentage) {
    if (discountPercentage <= 0) return originalPrice;
    final discount = (originalPrice * discountPercentage) / 100;
    return originalPrice - discount;
  }

  // Admin settings management
  static Future<List<Map<String, dynamic>>> getAdminSettings() async {
    try {
      final response =
          await client.from('admin_settings').select().order('setting_key');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch admin settings: $e');
    }
  }

  static Future<Map<String, dynamic>?> getAdminSetting(String key) async {
    try {
      final response = await client
          .from('admin_settings')
          .select()
          .eq('setting_key', key)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch admin setting: $e');
    }
  }

  static Future<void> updateAdminSetting(String key, String value) async {
    try {
      await client.from('admin_settings').upsert({
        'setting_key': key,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update admin setting: $e');
    }
  }

  // User role management
  static Future<bool> isAdmin(String? userId) async {
    if (userId == null) return false;
    try {
      final user = await getUserProfile(userId);
      return user?['user_type'] == 'admin' ||
          user?['user_type'] == 'super_admin';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isSuperAdmin(String? userId) async {
    if (userId == null) return false;
    try {
      final user = await getUserProfile(userId);
      return user?['user_type'] == 'super_admin';
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await client.from('users').update({
        'user_type': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  static Future<void> verifyUser(String userId) async {
    try {
      print('🔧 SupabaseConfig: Verifying user $userId');

      // Check current user and admin status
      final currentUser = client.auth.currentUser;
      print('🔧 SupabaseConfig: Current auth user: ${currentUser?.id}');

      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in as admin.');
      }

      // Verify current user is admin
      final currentUserProfile = await client
          .from('users')
          .select('id, user_type, full_name')
          .eq('id', currentUser.id)
          .maybeSingle();
      print('🔧 SupabaseConfig: Current user profile: $currentUserProfile');

      if (currentUserProfile == null) {
        throw Exception('Current user profile not found in database');
      }

      if (currentUserProfile['user_type'] != 'admin') {
        throw Exception(
            'Only admins can verify users. Current user type: ${currentUserProfile['user_type']}');
      }

      // First check if target user exists
      final userCheck = await client
          .from('users')
          .select('id, full_name, email, user_type, is_verified')
          .eq('id', userId)
          .maybeSingle();
      print('🔧 SupabaseConfig: Target user check result: $userCheck');

      if (userCheck == null) {
        throw Exception('Target user not found with ID: $userId');
      }

      print(
          '🔧 SupabaseConfig: Target user current verification status: ${userCheck['is_verified']}');

      // Try using RPC to bypass RLS issues
      String? rpcError;
      try {
        print('🔧 SupabaseConfig: Attempting RPC call...');
        final rpcResponse =
            await client.rpc('update_user_verification', params: {
          'user_id': userId,
          'is_verified': true,
        });
        print('🔧 SupabaseConfig: RPC response: $rpcResponse');

        if (rpcResponse == true) {
          // Also update runner applications if user is a runner
          await _syncRunnerApplicationStatus(userId, 'approved');
          print('✅ SupabaseConfig: User verified successfully via RPC');
          return;
        } else {
          print('⚠️ SupabaseConfig: RPC returned false, trying direct update');
        }
      } catch (e) {
        rpcError = e.toString();
        print('⚠️ SupabaseConfig: RPC failed with error: $rpcError');
        print('🔧 SupabaseConfig: Attempting direct update as fallback...');
      }

      // Fallback to direct update with better error handling
      try {
        final response = await client
            .from('users')
            .update({
              'is_verified': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId)
            .select();

        print('🔧 SupabaseConfig: Direct update response: $response');

        if (response.isEmpty) {
          // Check if user still exists
          final recheck = await client
              .from('users')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

          if (recheck == null) {
            throw Exception('User $userId no longer exists in database');
          } else {
            throw Exception(
                'Update failed - no rows affected for user ID: $userId. This may be due to RLS policies or database constraints.');
          }
        }

        // Also update runner applications if user is a runner
        await _syncRunnerApplicationStatus(userId, 'approved');

        print('✅ SupabaseConfig: User verified successfully via direct update');
      } catch (directUpdateError) {
        print(
            '❌ SupabaseConfig: Direct update also failed: $directUpdateError');
        throw Exception(
            'Both RPC and direct update failed. RPC error: ${rpcError ?? 'Unknown'}. Direct update error: $directUpdateError');
      }
    } catch (e) {
      print('❌ SupabaseConfig: Failed to verify user: $e');
      throw Exception('Failed to verify user: $e');
    }
  }

  static Future<void> unverifyUser(String userId) async {
    try {
      print('🔧 SupabaseConfig: Unverifying user $userId');

      // Check current user and admin status
      final currentUser = client.auth.currentUser;
      print('🔧 SupabaseConfig: Current auth user: ${currentUser?.id}');

      if (currentUser == null) {
        throw Exception('No authenticated user found. Please log in as admin.');
      }

      // Verify current user is admin
      final currentUserProfile = await client
          .from('users')
          .select('id, user_type, full_name')
          .eq('id', currentUser.id)
          .maybeSingle();
      print('🔧 SupabaseConfig: Current user profile: $currentUserProfile');

      if (currentUserProfile == null) {
        throw Exception('Current user profile not found in database');
      }

      if (currentUserProfile['user_type'] != 'admin') {
        throw Exception(
            'Only admins can unverify users. Current user type: ${currentUserProfile['user_type']}');
      }

      // First check if target user exists
      final userCheck = await client
          .from('users')
          .select('id, full_name, email, user_type, is_verified')
          .eq('id', userId)
          .maybeSingle();
      print('🔧 SupabaseConfig: Target user check result: $userCheck');

      if (userCheck == null) {
        throw Exception('Target user not found with ID: $userId');
      }

      print(
          '🔧 SupabaseConfig: Target user current verification status: ${userCheck['is_verified']}');

      // Try using RPC to bypass RLS issues
      String? rpcError;
      try {
        print('🔧 SupabaseConfig: Attempting RPC call...');
        final rpcResponse =
            await client.rpc('update_user_verification', params: {
          'user_id': userId,
          'is_verified': false,
        });
        print('🔧 SupabaseConfig: RPC response: $rpcResponse');

        if (rpcResponse == true) {
          // Also update runner applications if user is a runner
          await _syncRunnerApplicationStatus(userId, 'rejected');
          print('✅ SupabaseConfig: User unverified successfully via RPC');
          return;
        } else {
          print('⚠️ SupabaseConfig: RPC returned false, trying direct update');
        }
      } catch (e) {
        rpcError = e.toString();
        print('⚠️ SupabaseConfig: RPC failed with error: $rpcError');
        print('🔧 SupabaseConfig: Attempting direct update as fallback...');
      }

      // Fallback to direct update with better error handling
      try {
        final response = await client
            .from('users')
            .update({
              'is_verified': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId)
            .select();

        print('🔧 SupabaseConfig: Direct update response: $response');

        if (response.isEmpty) {
          // Check if user still exists
          final recheck = await client
              .from('users')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

          if (recheck == null) {
            throw Exception('User $userId no longer exists in database');
          } else {
            throw Exception(
                'Update failed - no rows affected for user ID: $userId. This may be due to RLS policies or database constraints.');
          }
        }

        // Also update runner applications if user is a runner
        await _syncRunnerApplicationStatus(userId, 'rejected');

        print(
            '✅ SupabaseConfig: User unverified successfully via direct update');
      } catch (directUpdateError) {
        print(
            '❌ SupabaseConfig: Direct update also failed: $directUpdateError');
        throw Exception(
            'Both RPC and direct update failed. RPC error: ${rpcError ?? 'Unknown'}. Direct update error: $directUpdateError');
      }
    } catch (e) {
      print('❌ SupabaseConfig: Failed to unverify user: $e');
      throw Exception('Failed to unverify user: $e');
    }
  }

  // Helper function to sync runner application status when user verification changes
  static Future<void> _syncRunnerApplicationStatus(
      String userId, String status) async {
    try {
      // Check if user has any runner applications
      final applications = await client
          .from('runner_applications')
          .select('id')
          .eq('user_id', userId)
          .eq('verification_status',
              status == 'approved' ? 'pending' : 'approved');

      if (applications.isNotEmpty) {
        // Update all applications for this user
        await client.from('runner_applications').update({
          'verification_status': status,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': client.auth.currentUser?.id,
        }).eq('user_id', userId);

        print(
            '✅ SupabaseConfig: Runner applications synced with status: $status');
      }
    } catch (e) {
      print('⚠️ SupabaseConfig: Failed to sync runner applications: $e');
      // Don't throw error here as this is a secondary operation
    }
  }

  // Calculate service pricing based on user type
  static double calculateServicePrice(
      Map<String, dynamic> service, Map<String, dynamic>? pricingTier,
      {String? userType, double hours = 1.0, double miles = 0.0}) {
    // Use business price for business users, base price for others
    double basePrice = (service['base_price'] as num).toDouble();
    double businessPrice =
        (service['business_price'] as num? ?? basePrice).toDouble();

    // Determine which price to use based on user type
    double priceToUse = (userType == 'business') ? businessPrice : basePrice;

    if (pricingTier != null) {
      double multiplier =
          (pricingTier['price_multiplier'] as num? ?? 1.0).toDouble();
      priceToUse *= multiplier;
    }

    return priceToUse;
  }

  // ==========================================
  // TRANSPORTATION SYSTEM MANAGEMENT
  // ==========================================

  // Vehicle Types Management
  static Future<List<Map<String, dynamic>>> getAllVehicleTypes() async {
    final response = await client.from('vehicle_types').select('''
      *,
      service_subcategory_ids
    ''').order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createVehicleType(
      Map<String, dynamic> vehicleTypeData) async {
    try {
      // Extract service subcategory IDs
      final subcategoryIds =
          vehicleTypeData['service_subcategory_ids'] as List<String>?;

      // Remove subcategory IDs from vehicle data before inserting
      final vehicleData = Map<String, dynamic>.from(vehicleTypeData);
      vehicleData.remove('service_subcategory_ids');

      // Insert vehicle type
      final response = await client
          .from('vehicle_types')
          .insert(vehicleData)
          .select()
          .single();

      // If subcategories were provided, create the relationships
      if (subcategoryIds != null && subcategoryIds.isNotEmpty) {
        await client.rpc('update_vehicle_subcategories', params: {
          'p_vehicle_type_id': response['id'],
          'p_subcategory_ids': subcategoryIds,
        });
      }

      return response;
    } catch (e) {
      print('Error creating vehicle type: $e');
      return null;
    }
  }

  static Future<bool> updateVehicleType(
      String vehicleTypeId, Map<String, dynamic> updateData) async {
    try {
      print(
          'Attempting to update vehicle type $vehicleTypeId with data: $updateData');

      // Extract service subcategory IDs
      final subcategoryIds =
          updateData['service_subcategory_ids'] as List<String>?;

      // Remove subcategory IDs from update data before updating
      final vehicleData = Map<String, dynamic>.from(updateData);
      vehicleData.remove('service_subcategory_ids');

      // Update vehicle type
      final response = await client
          .from('vehicle_types')
          .update(vehicleData)
          .eq('id', vehicleTypeId)
          .select();

      print('Update response: $response');

      // If subcategories were provided, update the relationships
      if (subcategoryIds != null) {
        await client.rpc('update_vehicle_subcategories', params: {
          'p_vehicle_type_id': vehicleTypeId,
          'p_subcategory_ids': subcategoryIds,
        });
      }

      return true;
    } catch (e) {
      print('Error updating vehicle type: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> deleteVehicleType(String vehicleTypeId) async {
    try {
      // Check for all types of dependencies
      final allDependencies =
          await getAllVehicleTypeDependencies(vehicleTypeId);

      final hasServices = allDependencies['services']?.isNotEmpty ?? false;
      final hasPricing = allDependencies['pricing']?.isNotEmpty ?? false;

      if (hasServices || hasPricing) {
        print(
            'Cannot delete vehicle type: ${allDependencies['services']?.length ?? 0} services and ${allDependencies['pricing']?.length ?? 0} pricing tiers depend on it');
        return false;
      }

      await client.from('vehicle_types').delete().eq('id', vehicleTypeId);
      return true;
    } catch (e) {
      print('Error deleting vehicle type: $e');
      return false;
    }
  }

  // New method to get dependent transportation services for a vehicle type
  static Future<List<Map<String, dynamic>>> getVehicleTypeDependencies(
      String vehicleTypeId) async {
    try {
      // transportation_services.vehicle_type_id was removed from the schema.
      // There are no direct service dependencies by vehicle type anymore.
      // Return an empty list to indicate no dependencies.
      return <Map<String, dynamic>>[];
    } catch (e) {
      // Be permissive: treat any error as no dependencies to avoid blocking operations.
      return <Map<String, dynamic>>[];
    }
  }

  // Metod to reassign transportation services from one vehicle type to anotherHHHERE
  static Future<bool> reassignTransportationServices(
      String fromVehicleTypeId, String toVehicleTypeId) async {
    try {
      // transportation_services.vehicle_type_id was removed from the schema.
      // Reassignment is no longer applicable; treat as a no-op success.
      print(
          'Skipping transportation service reassignment: vehicle_type_id column no longer exists.');
      return true; // No action needed
    } catch (e) {
      // Still report success to avoid blocking UI flows relying on this method.
      return true;
    }
  }

  // Enhanced method to get all dependencies for a vehicle type//HERE
  static Future<Map<String, List<Map<String, dynamic>>>>
      getAllVehicleTypeDependencies(String vehicleTypeId) async {
    try {
      final Map<String, List<Map<String, dynamic>>> dependencies = {};

      // transportation_services.vehicle_type_id was removed.
      // There are no direct service dependencies by vehicle type anymore.
      dependencies['services'] = <Map<String, dynamic>>[];

      // Pricing table was removed from the schema; no pricing dependencies.
      dependencies['pricing'] = <Map<String, dynamic>>[];

      return dependencies;
    } catch (e) {
      print('Error checking all vehicle type dependencies: $e');
      return {};
    }
  }

  // Routes Management
  static Future<List<Map<String, dynamic>>> getServiceRoutes(
      String serviceId) async {
    try {
      // Try to get full service data with pricing
      final response = await client.from('transportation_services').select('''
          *,
          route:service_routes(route_name, from_location, to_location)
        ''').eq('id', serviceId).eq('is_active', true).order('name');

      // Pricing support removed: set empty pricing arrays to maintain structure
      for (var service in response) {
        service['service_pricing'] = [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching service routes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createRoute(
      Map<String, dynamic> routeData) async {
    try {
      final response = await client
          .from('service_routes')
          .insert(routeData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating route: $e');
      return null;
    }
  }

  static Future<bool> updateRoute(
      String routeId, Map<String, dynamic> updateData) async {
    try {
      await client.from('service_routes').update(updateData).eq('id', routeId);
      return true;
    } catch (e) {
      print('Error updating route: $e');
      return false;
    }
  }

  static Future<bool> deleteRoute(String routeId) async {
    try {
      await client.from('service_routes').delete().eq('id', routeId);
      return true;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }


  // Route Pricing Management
  static Future<List<Map<String, dynamic>>> getRoutePricing(
      String routeId) async {
    // Pricing table removed; return empty list
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> createRoutePricing(
      Map<String, dynamic> pricingData) async {
    // Pricing table removed; no-op with dummy response
    return <String, dynamic>{};
  }

  static Future<void> updateRoutePricing(
      String pricingId, Map<String, dynamic> updates) async {
    // Pricing table removed; no-op
  }

  static Future<void> deleteRoutePricing(String pricingId) async {
    // Pricing table removed; no-op
  }

  // Transportation Search & Booking (for users)
  static Future<List<Map<String, dynamic>>> searchTransportation({
    String? fromLocation,
    String? toLocation,
    String? serviceType,
  }) async {
    try {
      var query = client.from('transportation_services').select('''
          *,
          route:service_routes(route_name, from_location, to_location),
        ''').eq('is_active', true);

      if (fromLocation != null) {
        query = query.ilike('route.from_location', '%$fromLocation%');
      }
      if (toLocation != null) {
        query = query.ilike('route.to_location', '%$toLocation%');
      }

      final response = await query.order('name');

      // Pricing support removed: set empty pricing arrays to maintain structure
      for (var service in response) {
        service['service_pricing'] = [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching transportation: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableRoutes() async {
    try {
      final response = await client.from('transportation_services').select('''
          *,
          route:service_routes(route_name, from_location, to_location)
        ''').eq('is_active', true).order('name');

      // Pricing support removed: set empty pricing arrays to maintain structure
      for (var service in response) {
        service['service_pricing'] = [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching available routes: $e');
      return [];
    }
  }

  // Transportation Booking
  static Future<Map<String, dynamic>> bookTransportation({
    required String routeId,
    required String vehicleTypeId,
    required String pricingId,
    required bool includePickup,
    String? pickupAddress,
    String? passengerName,
    String? passengerPhone,
    int passengerCount = 1,
  }) async {
    try {
      // This would create an errand with transportation-specific details
      final errandData = {
        'customer_id': currentUser?.id,
        'category': 'transportation',
        'title': 'Shuttle Services',
        'description': 'Transportation service booking',
        'pickup_location': pickupAddress ?? 'To be determined',
        'delivery_location': 'Transportation service',
        'status': 'pending',
        'transportation_details': {
          'route_id': routeId,
          'vehicle_type_id': vehicleTypeId,
          'pricing_id': pricingId,
          'include_pickup': includePickup,
          'passenger_count': passengerCount,
          'passenger_name': passengerName,
          'passenger_phone': passengerPhone,
        },
      };

      final response =
          await client.from('errands').insert(errandData).select().single();
      return response;
    } catch (e) {
      throw Exception('Failed to book transportation: $e');
    }
  }

  // ============= NEW TRANSPORTATION SYSTEM METHODS =============

  // Service Categories Management
  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    final response = await client
        .from('service_categories')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all categories (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllServiceCategories() async {
    final response =
        await client.from('service_categories').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceCategory(
      Map<String, dynamic> categoryData) async {
    try {
      final response = await client
          .from('service_categories')
          .insert(categoryData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service category: $e');
      return null;
    }
  }

  static Future<bool> updateServiceCategory(
      String categoryId, Map<String, dynamic> updateData) async {
    try {
      await client
          .from('service_categories')
          .update(updateData)
          .eq('id', categoryId);
      return true;
    } catch (e) {
      print('Error updating service category: $e');
      return false;
    }
  }

  static Future<bool> deleteServiceCategory(String categoryId) async {
    try {
      await client.from('service_categories').delete().eq('id', categoryId);
      return true;
    } catch (e) {
      print('Error deleting service category: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getServiceSubcategories() async {
    final response = await client
        .from('service_subcategories')
        .select('*')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get transportation-specific subcategories only
  static Future<List<Map<String, dynamic>>>
      getTransportationSubcategories() async {
    final response = await client
        .from('service_subcategories')
        .select('*')
        .eq('is_active', true)
        .inFilter('name', [
      'Bus Services',
      'Shuttle Services',
      'Contract Subscription',
      'Ride Sharing',
      'Airport Transfers',
      'Cargo Transport',
      'Moving Services'
    ]).order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all subcategories (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllServiceSubcategories() async {
    final response =
        await client.from('service_subcategories').select('*').order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceSubcategory(
      Map<String, dynamic> subcategoryData) async {
    try {
      final response = await client
          .from('service_subcategories')
          .insert(subcategoryData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service subcategory: $e');
      return null;
    }
  }

  static Future<bool> updateServiceSubcategory(
      String subcategoryId, Map<String, dynamic> updateData) async {
    try {
      await client
          .from('service_subcategories')
          .update(updateData)
          .eq('id', subcategoryId);
      return true;
    } catch (e) {
      print('Error updating service subcategory: $e');
      return false;
    }
  }

  static Future<bool> deleteServiceSubcategory(String subcategoryId) async {
    try {
      await client
          .from('service_subcategories')
          .delete()
          .eq('id', subcategoryId);
      return true;
    } catch (e) {
      print('Error deleting service subcategory: $e');
      return false;
    }
  }

  // Vehicle Types Management
  static Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final response = await client
        .from('vehicle_types')
        .select()
        .eq('is_active', true)
        .order('capacity');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get vehicle types by subcategory ID
  static Future<List<Map<String, dynamic>>> getVehicleTypesBySubcategory(
      String serviceSubcategoryId) async {
    try {
      final response = await client
          .from('vehicle_types')
          .select()
          .eq('is_active', true)
          .contains('service_subcategory_ids', [serviceSubcategoryId]).order(
              'capacity');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vehicle types by subcategory: $e');
      return [];
    }
  }

  // Towns and Routes Management
  static Future<List<Map<String, dynamic>>> getTowns() async {
    final response =
        await client.from('towns').select().eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all towns (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllTowns() async {
    final response = await client.from('towns').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createTown(
      Map<String, dynamic> townData) async {
    try {
      final response =
          await client.from('towns').insert(townData).select().single();
      return response;
    } catch (e) {
      print('Error creating town: $e');
      return null;
    }
  }

  static Future<bool> updateTown(
      String townId, Map<String, dynamic> updateData) async {
    try {
      await client.from('towns').update(updateData).eq('id', townId);
      return true;
    } catch (e) {
      print('Error updating town: $e');
      return false;
    }
  }

  static Future<bool> deleteTown(String townId) async {
    try {
      await client.from('towns').delete().eq('id', townId);
      return true;
    } catch (e) {
      print('Error deleting town: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getRoutes() async {
    final response = await client
        .from('service_routes')
        .select('*')
        .eq('is_active', true)
        .order('route_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all routes (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final response =
        await client.from('service_routes').select('*').order('route_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Providers Management (using service_providers table)
  static Future<List<Map<String, dynamic>>> getProviders() async {
    final response = await client
        .from('service_providers')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all providers (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllProviders() async {
    final response =
        await client.from('service_providers').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createProvider(
      Map<String, dynamic> providerData) async {
    try {
      final response = await client
          .from('service_providers')
          .insert(providerData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating provider: $e');
      return null;
    }
  }

  static Future<bool> updateProvider(
      String providerId, Map<String, dynamic> updateData) async {
    try {
      await client
          .from('service_providers')
          .update(updateData)
          .eq('id', providerId);
      return true;
    } catch (e) {
      print('Error updating provider: $e');
      return false;
    }
  }

  static Future<bool> deleteProvider(String providerId) async {
    try {
      await client.from('service_providers').delete().eq('id', providerId);
      return true;
    } catch (e) {
      print('Error deleting provider: $e');
      return false;
    }
  }

  // Service Providers Management (Legacy - keeping for backward compatibility)
  static Future<List<Map<String, dynamic>>> getServiceProviders() async {
    final response = await client
        .from('service_providers')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all service providers (including inactive) for admin management
  static Future<List<Map<String, dynamic>>> getAllServiceProviders() async {
    final response =
        await client.from('service_providers').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceProvider(
      Map<String, dynamic> providerData) async {
    try {
      final response = await client
          .from('service_providers')
          .insert(providerData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service provider: $e');
      return null;
    }
  }

  static Future<bool> updateServiceProvider(
      String providerId, Map<String, dynamic> updateData) async {
    try {
      await client
          .from('service_providers')
          .update(updateData)
          .eq('id', providerId);
      return true;
    } catch (e) {
      print('Error updating service provider: $e');
      return false;
    }
  }

  static Future<bool> deleteServiceProvider(String providerId) async {
    try {
      await client.from('service_providers').delete().eq('id', providerId);
      return true;
    } catch (e) {
      print('Error deleting service provider: $e');
      return false;
    }
  }

  // Transportation Services Management
  static Future<List<Map<String, dynamic>>> getTransportationServices(
      [String? subcategoryId]) async {
    var query = client.from('transportation_services').select('''
          *,
          route:service_routes(route_name, from_location, to_location)
        ''').eq('is_active', true);

    final response = await query.order('name');
    List<Map<String, dynamic>> services =
        List<Map<String, dynamic>>.from(response);

    // Pricing support removed: set empty pricing arrays to maintain structure
    for (var service in services) {
      service['pricing'] = [];
    }

    return services;
  }

  static Future<Map<String, dynamic>?> createTransportationService(
      Map<String, dynamic> serviceData) async {
    try {
      // Extract provider information if present
      List<Map<String, dynamic>>? providers = serviceData.remove('providers');

      // Convert provider data to arrays if providers are specified
      if (providers != null && providers.isNotEmpty) {
        List<String> providerIds = [];
        List<double> prices = [];
        List<String> departureTimes = [];
        List<String?> checkInTimes = [];
        List<List<int>> operatingDays = [];
        List<int> advanceBookingHours = [];
        List<int> cancellationHours = [];

        List<String> providerNames = [];

        for (var provider in providers) {
          providerIds.add(provider['provider_id']);
          prices.add(provider['price']?.toDouble() ?? 0.0);
          departureTimes.add(provider['departure_time'] ?? '08:00');
          checkInTimes.add(provider['check_in_time']);

          // Get provider name from the providers list or fetch it
          String providerName = 'Unknown Provider';
          if (provider.containsKey('provider_name')) {
            providerName = provider['provider_name'];
          } else {
            // Try to get provider name from the providers list passed to the function
            try {
              final providerResponse = await client
                  .from('service_providers')
                  .select('name')
                  .eq('id', provider['provider_id'])
                  .single();
              providerName = providerResponse['name'] ?? 'Unknown Provider';
            } catch (e) {
              print(
                  'Could not fetch provider name for ${provider['provider_id']}: $e');
            }
          }
          providerNames.add(providerName);

          // Handle days_of_week - ensure it's always a valid array
          List<String> dayNames = [];
          if (provider['days_of_week'] != null) {
            if (provider['days_of_week'] is List) {
              dayNames = List<String>.from(provider['days_of_week']);
            } else if (provider['days_of_week'] is String) {
              dayNames = [provider['days_of_week']];
            }
          }

          // Convert day names to integers (1=Monday, 7=Sunday)
          List<int> dayIntegers = dayNames.isNotEmpty
              ? dayNames
                  .map((dayName) => _convertDayNameToInt(dayName))
                  .toList()
              : [1]; // Default to Monday if no days specified

          operatingDays.add(dayIntegers);
          advanceBookingHours.add(provider['advance_booking_hours'] ?? 1);
          cancellationHours.add(provider['cancellation_hours'] ?? 2);
        }

        // Ensure all arrays have the same number of providers (outer dimension)
        final int providerCount = providers.length;
        while (providerIds.length < providerCount) {
          providerIds.add(providerIds.isNotEmpty
              ? providerIds.last
              : providerIds.length < providers.length
                  ? providers[providerIds.length]['provider_id'] ?? ''
                  : '');
        }
        while (prices.length < providerCount) {
          prices.add(0.0);
        }
        while (departureTimes.length < providerCount) {
          departureTimes.add('08:00:00');
        }
        while (checkInTimes.length < providerCount) {
          checkInTimes.add(null);
        }
        while (operatingDays.length < providerCount) {
          operatingDays.add(<int>[1]);
        }
        while (advanceBookingHours.length < providerCount) {
          advanceBookingHours.add(1);
        }
        while (cancellationHours.length < providerCount) {
          cancellationHours.add(2);
        }
        while (providerNames.length < providerCount) {
          providerNames.add('Unknown Provider');
        }

        // Postgres multidimensional arrays must be rectangular.
        // Pad inner operatingDays lists to uniform length to avoid 22P02 errors.
        int maxInnerLen = 0;
        for (final days in operatingDays) {
          if (days.length > maxInnerLen) maxInnerLen = days.length;
        }
        if (maxInnerLen == 0) {
          maxInnerLen = 1; // at least 1 element per inner list
        }
        for (final days in operatingDays) {
          while (days.length < maxInnerLen) {
            days.add(0);
          }
        }

        serviceData['provider_ids'] = providerIds;
        serviceData['prices'] = prices;
        serviceData['departure_times'] = departureTimes;
        serviceData['check_in_times'] = checkInTimes;
        serviceData['provider_operating_days'] =
            operatingDays; // This will be converted to JSONB automatically
        serviceData['advance_booking_hours_array'] = advanceBookingHours;
        serviceData['cancellation_hours_array'] = cancellationHours;
        serviceData['provider_names'] = providerNames;
      }

      // Remove old single-provider fields if they exist
      serviceData.remove('provider_id');
      serviceData.remove('price');
      serviceData.remove('departure_time');
      serviceData.remove('check_in_time');
      serviceData.remove('days_of_week');
      serviceData.remove('advance_booking_hours');
      serviceData.remove('cancellation_hours');

      final response = await client
          .from('transportation_services')
          .insert(serviceData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating transportation service: $e');
      return null;
    }
  }

  // Add a provider to an existing service
  static Future<bool> addProviderToService(
      String serviceId, Map<String, dynamic> providerData) async {
    try {
      String normalizeTime(String? t) {
        if (t == null || t.isEmpty) return '00:00:00';
        final trimmed = t.trim();
        if (RegExp(r'^\d{1,2}:\d{2}:\d{2}').hasMatch(trimmed)) return trimmed;
        if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(trimmed)) return '$trimmed:00';
        return '00:00:00';
      }

      // Fallback to array-append update to ensure UI can rebuild from arrays
      final current = await client
          .from('transportation_services')
          .select(
              'provider_ids, prices, departure_times, check_in_times, provider_operating_days, advance_booking_hours_array, cancellation_hours_array, features_array')
          .eq('id', serviceId)
          .single();

      List<String> providerIds = (current['provider_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      List<num> prices =
          (current['prices'] as List?)?.map((e) => (e as num)).toList() ??
              <num>[];
      List<String> departureTimes = (current['departure_times'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      List<String> checkInTimes = (current['check_in_times'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      List<List<int>> operatingDays = (current['provider_operating_days']
                  as List?)
              ?.map<List<int>>((dynamic item) => item is List
                  ? item
                      .map<int>(
                          (d) => d is int ? d : int.tryParse(d.toString()) ?? 1)
                      .toList()
                  : <int>[])
              .toList() ??
          <List<int>>[];
      List<int> advanceHours = (current['advance_booking_hours_array'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[];
      List<int> cancellationHours =
          (current['cancellation_hours_array'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              <int>[];
      List<List<String>> featuresArray = [];
      try {
        // Check if features_array column exists in the response
        if (current.containsKey('features_array')) {
          final rawFeatures = current['features_array'] as List?;
          if (rawFeatures != null && rawFeatures.isNotEmpty) {
            // Handle potentially malformed features array
            for (var item in rawFeatures) {
              if (item is List) {
                featuresArray
                    .add(item.map<String>((f) => f.toString()).toList());
              } else {
                featuresArray.add(<String>[]);
              }
            }
          }
        } else {
          print('Info: features_array column not found in database response');
        }
      } catch (e) {
        print('Warning: Could not parse features_array, using empty array: $e');
        featuresArray = <List<String>>[];
      }

      final String providerId = providerData['provider_id'] as String;
      final num price = (providerData['price'] as num?) ?? 0;
      final String depTime =
          normalizeTime(providerData['departure_time'] as String?);
      final String chkTime =
          normalizeTime(providerData['check_in_time'] as String?);
      final List<int> days =
          (providerData['days_of_week'] as List<String>? ?? <String>[])
              .map<int>((name) => _convertDayNameToInt(name))
              .toList();
      final int adv = (providerData['advance_booking_hours'] as int?) ?? 1;
      final int cancel = (providerData['cancellation_hours'] as int?) ?? 2;
      final List<String> features =
          (providerData['features'] as List<String>?) ?? [];

      // Ensure provider_operating_days remains rectangular by padding inner lists
      int currentMaxInnerLen = 0;
      for (final d in operatingDays) {
        if (d.length > currentMaxInnerLen) currentMaxInnerLen = d.length;
      }
      if (days.length > currentMaxInnerLen) currentMaxInnerLen = days.length;
      if (currentMaxInnerLen == 0) currentMaxInnerLen = 1;
      for (final d in operatingDays) {
        while (d.length < currentMaxInnerLen) {
          d.add(0);
        }
      }
      while (days.length < currentMaxInnerLen) {
        days.add(0);
      }

      providerIds.add(providerId);
      prices.add(price);
      departureTimes.add(depTime);
      checkInTimes.add(chkTime);
      operatingDays.add(days);
      advanceHours.add(adv);
      cancellationHours.add(cancel);
      featuresArray.add(features);

      // Ensure features array has consistent dimensions
      if (featuresArray.isNotEmpty) {
        int maxLength = 0;
        for (var features in featuresArray) {
          if (features.length > maxLength) {
            maxLength = features.length;
          }
        }

        // Normalize all feature arrays to the same length
        for (int i = 0; i < featuresArray.length; i++) {
          while (featuresArray[i].length < maxLength) {
            featuresArray[i].add('');
          }
        }
      }

      // Try to update with features_array, fallback to without if column doesn't exist
      try {
        print('🔄 Adding provider to service with features...');
        print('📊 Features array: $featuresArray');

        // Ensure all arrays are properly formatted
        final updateData = {
          'provider_ids': providerIds,
          'prices': prices.map((p) => p.toDouble()).toList(),
          'departure_times': departureTimes,
          'check_in_times': checkInTimes,
          'provider_operating_days': operatingDays,
          'advance_booking_hours_array': advanceHours,
          'cancellation_hours_array': cancellationHours,
          'features_array': featuresArray,
        };

        print('📤 Sending add provider data: $updateData');

        await client
            .from('transportation_services')
            .update(updateData)
            .eq('id', serviceId);
        print('✅ Provider added successfully with features');
      } catch (e) {
        print(
            'Warning: Could not update features_array, updating without it: $e');
        // Fallback: update without features_array
        final fallbackData = {
          'provider_ids': providerIds,
          'prices': prices.map((p) => p.toDouble()).toList(),
          'departure_times': departureTimes,
          'check_in_times': checkInTimes,
          'provider_operating_days': operatingDays,
          'advance_booking_hours_array': advanceHours,
          'cancellation_hours_array': cancellationHours,
        };

        print('📤 Sending fallback add provider data: $fallbackData');

        await client
            .from('transportation_services')
            .update(fallbackData)
            .eq('id', serviceId);
        print('✅ Provider added successfully without features');
      }
      return true;
    } catch (e) {
      print('Error adding provider to service: $e');
      return false;
    }
  }

  // Remove a provider from a service
  static Future<bool> removeProviderFromService(
      String serviceId, String providerId) async {
    try {
      // Try RPC first
      try {
        await client.rpc('remove_provider_from_service', params: {
          'p_service_id': serviceId,
          'p_provider_id': providerId,
        });
        return true;
      } catch (e) {
        print('RPC failed, using client-side removal: $e');
        // Fallback to client-side removal
        final current = await client
            .from('transportation_services')
            .select(
                'provider_ids, prices, departure_times, check_in_times, provider_operating_days, advance_booking_hours_array, cancellation_hours_array, provider_names')
            .eq('id', serviceId)
            .single();

        List<String> providerIds = (current['provider_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        final int idx = providerIds.indexOf(providerId);
        if (idx < 0) {
          print('Provider not found in service');
          return false;
        }

        List<num> prices =
            (current['prices'] as List?)?.map((e) => (e as num)).toList() ??
                <num>[];
        List<String> departureTimes = (current['departure_times'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        List<String?> checkInTimes = (current['check_in_times'] as List?)
                ?.map((e) => e?.toString())
                .toList() ??
            <String?>[];
        List<dynamic> rawOperatingDays =
            (current['provider_operating_days'] as List?) ?? <dynamic>[];
        List<List<dynamic>> operatingDays = rawOperatingDays
            .map<List<dynamic>>(
                (e) => e is List ? List<dynamic>.from(e) : <dynamic>[])
            .toList();
        List<int> advanceHours =
            (current['advance_booking_hours_array'] as List?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                <int>[];
        List<int> cancellationHours =
            (current['cancellation_hours_array'] as List?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                <int>[];
        List<String> providerNames = (current['provider_names'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        // Remove the provider at the found index
        if (idx < providerIds.length) providerIds.removeAt(idx);
        if (idx < prices.length) prices.removeAt(idx);
        if (idx < departureTimes.length) departureTimes.removeAt(idx);
        if (idx < checkInTimes.length) checkInTimes.removeAt(idx);
        if (idx < operatingDays.length) operatingDays.removeAt(idx);
        if (idx < advanceHours.length) advanceHours.removeAt(idx);
        if (idx < cancellationHours.length) cancellationHours.removeAt(idx);
        if (idx < providerNames.length) providerNames.removeAt(idx);

        // Update the service
        await client.from('transportation_services').update({
          'provider_ids': providerIds,
          'prices': prices,
          'departure_times': departureTimes,
          'check_in_times': checkInTimes,
          'provider_operating_days': operatingDays,
          'advance_booking_hours_array': advanceHours,
          'cancellation_hours_array': cancellationHours,
          'provider_names': providerNames,
        }).eq('id', serviceId);

        return true;
      }
    } catch (e) {
      print('Error removing provider from service: $e');
      return false;
    }
  }

  // Update provider data in a service
  static Future<bool> updateServiceProviderData(String serviceId,
      String providerId, Map<String, dynamic> updateData) async {
    try {
      String normalizeTime(String? t) {
        if (t == null || t.isEmpty) return '00:00:00';
        final trimmed = t.trim();
        if (RegExp(r'^\d{1,2}:\d{2}:\d{2}').hasMatch(trimmed)) return trimmed;
        if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(trimmed)) return '$trimmed:00';
        return '00:00:00';
      }

      final String depTime =
          normalizeTime(updateData['departure_time'] as String?);
      final String? chkTime = updateData['check_in_time'] != null
          ? normalizeTime(updateData['check_in_time'] as String?)
          : null;

      // Prepare operating days
      final List<String>? dayNames = updateData['days_of_week'] != null
          ? List<String>.from(updateData['days_of_week'] as List)
          : null;

      // Use direct client-side update to avoid RPC array dimension issues
      // Try to get data with features_array, fallback to without if column doesn't exist
      Map<String, dynamic> current;
      try {
        current = await client
            .from('transportation_services')
            .select(
                'provider_ids, prices, departure_times, check_in_times, provider_operating_days, advance_booking_hours_array, cancellation_hours_array, features_array')
            .eq('id', serviceId)
            .single();
      } catch (e) {
        print(
            'Warning: Could not select features_array, trying without it: $e');
        current = await client
            .from('transportation_services')
            .select(
                'provider_ids, prices, departure_times, check_in_times, provider_operating_days, advance_booking_hours_array, cancellation_hours_array')
            .eq('id', serviceId)
            .single();
      }

      List<String> providerIds = (current['provider_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      final int idx = providerIds.indexOf(providerId);
      if (idx < 0) throw Exception('Provider not found in service');

      List<num> prices =
          (current['prices'] as List?)?.map((e) => (e as num)).toList() ??
              <num>[];
      List<String> departureTimes = (current['departure_times'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      List<String?> checkInTimes = (current['check_in_times'] as List?)
              ?.map((e) => e?.toString())
              .toList() ??
          <String?>[];
      List<dynamic> rawOperatingDays =
          (current['provider_operating_days'] as List?) ?? <dynamic>[];
      List<List<dynamic>> operatingDays = rawOperatingDays
          .map<List<dynamic>>(
              (e) => e is List ? List<dynamic>.from(e) : <dynamic>[])
          .toList();
      List<int> advanceHours = (current['advance_booking_hours_array'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[];
      List<int> cancellationHours =
          (current['cancellation_hours_array'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              <int>[];
      List<List<String>> featuresArray = [];
      try {
        // Check if features_array column exists in the response
        if (current.containsKey('features_array')) {
          final rawFeatures = current['features_array'] as List?;
          if (rawFeatures != null && rawFeatures.isNotEmpty) {
            // Handle potentially malformed features array
            for (var item in rawFeatures) {
              if (item is List) {
                featuresArray
                    .add(item.map<String>((f) => f.toString()).toList());
              } else {
                featuresArray.add(<String>[]);
              }
            }
          }
        } else {
          print('Info: features_array column not found in database response');
        }
      } catch (e) {
        print('Warning: Could not parse features_array, using empty array: $e');
        featuresArray = <List<String>>[];
      }

      // Ensure arrays lengths
      void ensureLength<T>(List<T> list, int length, T pad) {
        while (list.length <= idx) {
          list.add(pad);
        }
        while (list.length < length) {
          list.add(pad);
        }
      }

      final int targetLen = providerIds.length;
      ensureLength<num>(prices, targetLen, 0);
      ensureLength<String>(departureTimes, targetLen, '00:00:00');
      ensureLength<String?>(checkInTimes, targetLen, null);
      ensureLength<List<dynamic>>(operatingDays, targetLen, <dynamic>[]);
      ensureLength<int>(advanceHours, targetLen, 1);
      ensureLength<int>(cancellationHours, targetLen, 2);
      ensureLength<List<String>>(featuresArray, targetLen, <String>[]);

      // Apply updates
      if (updateData['price'] != null) {
        prices[idx] = (updateData['price'] as num);
      }
      departureTimes[idx] = depTime;
      checkInTimes[idx] = chkTime;

      if (dayNames != null) {
        final bool storeAsInts = operatingDays.isNotEmpty &&
            operatingDays.any((row) => row.isNotEmpty && row.first is int);
        List<dynamic> newDays = storeAsInts
            ? dayNames.map((d) => _convertDayNameToInt(d)).toList()
            : dayNames;
        int maxInner = newDays.length;
        for (final row in operatingDays) {
          if (row.length > maxInner) maxInner = row.length;
        }
        while (newDays.length < maxInner) {
          newDays.add(storeAsInts ? 0 : '');
        }
        for (final row in operatingDays) {
          while (row.length < maxInner) {
            row.add(storeAsInts ? 0 : '');
          }
        }
        if (idx < operatingDays.length) {
          operatingDays[idx] = newDays;
        } else {
          ensureLength<List<dynamic>>(operatingDays, idx + 1, <dynamic>[]);
          operatingDays[idx] = newDays;
        }
      }

      // Apply other updates
      if (updateData['advance_booking_hours'] != null) {
        advanceHours[idx] = (updateData['advance_booking_hours'] as int);
      }
      if (updateData['cancellation_hours'] != null) {
        cancellationHours[idx] = (updateData['cancellation_hours'] as int);
      }
      if (updateData['features'] != null) {
        featuresArray[idx] = List<String>.from(updateData['features'] as List);
      }

      // Ensure features array has consistent dimensions
      if (featuresArray.isNotEmpty) {
        int maxLength = 0;
        for (var features in featuresArray) {
          if (features.length > maxLength) {
            maxLength = features.length;
          }
        }

        // Normalize all feature arrays to the same length
        for (int i = 0; i < featuresArray.length; i++) {
          while (featuresArray[i].length < maxLength) {
            featuresArray[i].add('');
          }
        }
      }

      // Try to update with features_array, fallback to without if column doesn't exist
      try {
        print('🔄 Updating service provider data with features...');
        print('📊 Features array: $featuresArray');

        // Ensure all arrays are properly formatted
        final updateData = {
          'prices': prices.map((p) => p.toDouble()).toList(),
          'departure_times': departureTimes,
          'check_in_times': checkInTimes,
          'provider_operating_days': operatingDays,
          'advance_booking_hours_array': advanceHours,
          'cancellation_hours_array': cancellationHours,
          'features_array': featuresArray,
        };

        print('📤 Sending update data: $updateData');

        await client
            .from('transportation_services')
            .update(updateData)
            .eq('id', serviceId);
        print('✅ Service provider updated successfully with features');
      } catch (e) {
        print(
            'Warning: Could not update features_array, updating without it: $e');
        // Fallback: update without features_array
        final fallbackData = {
          'prices': prices.map((p) => p.toDouble()).toList(),
          'departure_times': departureTimes,
          'check_in_times': checkInTimes,
          'provider_operating_days': operatingDays,
          'advance_booking_hours_array': advanceHours,
          'cancellation_hours_array': cancellationHours,
        };

        print('📤 Sending fallback data: $fallbackData');

        await client
            .from('transportation_services')
            .update(fallbackData)
            .eq('id', serviceId);
        print('✅ Service provider updated successfully without features');
      }

      // Verify the update by reading back the data
      try {
        final verifyResponse = await client
            .from('transportation_services')
            .select('features_array')
            .eq('id', serviceId)
            .single();
        print(
            '🔍 Verification - Current features_array in DB: ${verifyResponse['features_array']}');
      } catch (e) {
        print('⚠️ Could not verify update: $e');
      }

      return true;
    } catch (e) {
      print('Error updating service provider: $e');
      return false;
    }
  }

  // Get all transportation services (including inactive) for admin management
  static Future<List<Map<String, dynamic>>>
      getAllTransportationServices() async {
    try {
      final response = await client.from('transportation_services').select('''
          *,
          route:service_routes(route_name, from_location, to_location)
        ''').order('name');

      List<Map<String, dynamic>> services =
          List<Map<String, dynamic>>.from(response);

      // Convert array data to provider format for each service
      for (var service in services) {
        List<Map<String, dynamic>> providers = [];

        // Get arrays from service
        List<dynamic>? providerIds = service['provider_ids'];
        List<dynamic>? prices = service['prices'];
        List<dynamic>? departureTimes = service['departure_times'];
        List<dynamic>? checkInTimes = service['check_in_times'];
        List<dynamic>? operatingDays = service['provider_operating_days'];
        List<dynamic>? advanceHours = service['advance_booking_hours_array'];
        List<dynamic>? cancellationHours = service['cancellation_hours_array'];
        List<dynamic>? featuresArray = service['features_array'];

        // Debug logging
        print('🔍 Service: ${service['name']}');
        print('🔍 Provider IDs: $providerIds');
        print('🔍 Provider IDs type: ${providerIds.runtimeType}');
        print('🔍 Provider IDs length: ${providerIds?.length ?? 0}');
        print('🔍 Raw service data: ${service.keys.toList()}');
        print('🔍 All service data: $service');

        if (providerIds != null && providerIds.isNotEmpty) {
          // Get provider information for all provider IDs
          final providerResponse = await client
              .from('service_providers')
              .select('id, name, contact_phone, contact_email')
              .inFilter('id', providerIds);

          Map<String, Map<String, dynamic>> providerMap = {};
          for (var provider in providerResponse) {
            providerMap[provider['id']] = provider;
          }

          // Build provider list with details
          for (int i = 0; i < providerIds.length; i++) {
            String providerId = providerIds[i];
            Map<String, dynamic>? providerInfo = providerMap[providerId];

            providers.add({
              'provider_id': providerId,
              'provider': providerInfo,
              'price': prices != null && i < prices.length ? prices[i] : 0,
              'departure_time':
                  departureTimes != null && i < departureTimes.length
                      ? departureTimes[i]
                      : null,
              'check_in_time': checkInTimes != null && i < checkInTimes.length
                  ? checkInTimes[i]
                  : null,
              'days_of_week': operatingDays != null && i < operatingDays.length
                  ? (operatingDays[i] is List
                      ? (operatingDays[i] as List)
                          .where(
                              (d) => d != 0 && d != '0' && d != null && d != '')
                          .map((day) {
                            if (day is int) {
                              return _convertDayIntToName(day);
                            } else if (day is String) {
                              return day; // Already a string
                            }
                            return 'Monday'; // Default
                          })
                          .toSet()
                          .toList()
                      : [])
                  : [],
              'advance_booking_hours':
                  advanceHours != null && i < advanceHours.length
                      ? advanceHours[i]
                      : 1,
              'cancellation_hours':
                  cancellationHours != null && i < cancellationHours.length
                      ? cancellationHours[i]
                      : 2,
              'features': featuresArray != null && i < featuresArray.length
                  ? (featuresArray[i] is List
                      ? List<String>.from(featuresArray[i])
                          .where((feature) => feature.isNotEmpty)
                          .toList()
                      : [])
                  : [],
              'is_active': true,
            });
          }
        }

        service['providers'] = providers;
      }

      return services;
    } catch (e) {
      print('Error getting all transportation services: $e');
      return [];
    }
  }

  // Get transportation services with providers using the array view
  static Future<List<Map<String, dynamic>>>
      getTransportationServicesWithProviders() async {
    try {
      final response = await client
          .from('transportation_services_with_provider_arrays')
          .select('*')
          .order('service_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting transportation services with providers: $e');
      return [];
    }
  }

  // Helper function to convert day names to integers (1=Monday, 7=Sunday)
  static int _convertDayNameToInt(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1; // Default to Monday if unknown
    }
  }

  // Helper function to convert day integers to names
  static String _convertDayIntToName(int dayInt) {
    switch (dayInt) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday'; // Default to Monday if invalid
    }
  }

  static Future<bool> updateTransportationService(
      String serviceId, Map<String, dynamic> updateData) async {
    try {
      await client
          .from('transportation_services')
          .update(updateData)
          .eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating transportation service: $e');
      return false;
    }
  }

  static Future<bool> deleteTransportationService(String serviceId) async {
    try {
      await client.from('transportation_services').delete().eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error deleting transportation service: $e');
      return false;
    }
  }


  // Service Pricing Management
  static Future<List<Map<String, dynamic>>> getServicePricing(
      String serviceId) async {
    // Pricing table removed; return empty list
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>?> createServicePricing(
      Map<String, dynamic> pricingData) async {
    // Pricing table removed; return null to indicate no create
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPricingTiers(
      String serviceId) async {
    final response = await client
        .from('pricing_tiers')
        .select()
        .eq('service_id', serviceId)
        .order('min_distance_km');
    return List<Map<String, dynamic>>.from(response);
  }

  // Transportation Bookings Management
  static Future<List<Map<String, dynamic>>> getUserBookings(
      [String? userId]) async {
    print('🚀 DEBUG: [GET USER BOOKINGS] Starting getUserBookings...');
    
    final user = client.auth.currentUser;
    final targetUserId = userId ?? user?.id;

    print('👤 DEBUG: [GET USER BOOKINGS] Current user: ${user?.id}');
    print('👤 DEBUG: [GET USER BOOKINGS] Target user ID: $targetUserId');

    if (targetUserId == null) {
      print('❌ DEBUG: [GET USER BOOKINGS] No user ID found - returning empty list');
      return [];
    }

    try {
      print('📡 DEBUG: [GET USER BOOKINGS] Executing parallel queries...');
      
      // Execute all queries in parallel for better performance
      final futures = await Future.wait([
        // Get transportation bookings with driver info and vehicle type
        // Note: service join is optional since shuttle bookings might not have service_id
        client
            .from('transportation_bookings')
            .select('''
              *,
              service:transportation_services(
                name
              ),
              driver:users!transportation_bookings_driver_id_fkey(full_name, avatar_url),
              vehicle_type:vehicle_types(
                name,
                description
              )
            ''')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false),

        // Get contract bookings with driver info
        client
            .from('contract_bookings')
            .select('''
              *,
              driver:users!contract_bookings_driver_id_fkey(full_name, avatar_url)
            ''')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false),

        // Get bus service bookings
        client
            .from('bus_service_bookings')
            .select('''
              *,
              service:transportation_services(
                name
              )
            ''')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false),
      ]);

      print('✅ DEBUG: [GET USER BOOKINGS] All queries completed');
      
      final transportationBookings = futures[0] as List;
      final contractBookings = futures[1] as List;
      final busBookings = futures[2] as List;

      print('📊 DEBUG: [GET USER BOOKINGS] Query results:');
      print('   - Transportation bookings: ${transportationBookings.length}');
      print('   - Contract bookings: ${contractBookings.length}');
      print('   - Bus bookings: ${busBookings.length}');

      // Log each transportation booking for debugging
      for (var i = 0; i < transportationBookings.length; i++) {
        final booking = transportationBookings[i];
        print('📋 DEBUG: [GET USER BOOKINGS] Transportation booking #${i + 1}:');
        print('   - ID: ${booking['id']}');
        print('   - Status: ${booking['status']}');
        print('   - Pickup: ${booking['pickup_location']}');
        print('   - Dropoff: ${booking['dropoff_location']}');
        print('   - Vehicle type ID: ${booking['vehicle_type_id']}');
        print('   - Service ID: ${booking['service_id']}');
        print('   - Service name: ${booking['service']?['name']}');
        print('   - Vehicle type: ${booking['vehicle_type']?['name']}');
        print('   - Driver ID: ${booking['driver_id']}');
        print('   - Is immediate: ${booking['is_immediate']}');
        print('   - Created at: ${booking['created_at']}');
      }

      // Combine all bookings efficiently
      List<Map<String, dynamic>> allBookings = [];

      // Add transportation bookings with type identifier
      for (var booking in transportationBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'transportation',
          'title': 'Shuttle Services',
        });
        print('✅ DEBUG: [GET USER BOOKINGS] Added transportation booking: ${booking['id']}');
      }

      // Add contract bookings with type identifier
      for (var booking in contractBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'contract',
          'title': 'Contract Booking',
          'pickup_location': booking['pickup_location'],
          'dropoff_location': booking['dropoff_location'],
        });
        print('✅ DEBUG: [GET USER BOOKINGS] Added contract booking: ${booking['id']}');
      }

      // Add bus service bookings with type identifier
      for (var booking in busBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'bus',
          'title': 'Bus Service',
          'pickup_location': booking['pickup_location'],
          'dropoff_location': booking['dropoff_location'],
        });
        print('✅ DEBUG: [GET USER BOOKINGS] Added bus booking: ${booking['id']}');
      }

      // Sort combined bookings by created_at
      allBookings.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      print('✅ DEBUG: [GET USER BOOKINGS] Total bookings after combining: ${allBookings.length}');
      print('✅ DEBUG: [GET USER BOOKINGS] Returning ${allBookings.length} bookings');

      return allBookings;
    } catch (e, stackTrace) {
      print('❌ DEBUG: [GET USER BOOKINGS] Error fetching user bookings');
      print('❌ DEBUG: [GET USER BOOKINGS] Error type: ${e.runtimeType}');
      print('❌ DEBUG: [GET USER BOOKINGS] Error message: $e');
      print('❌ DEBUG: [GET USER BOOKINGS] Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('foreign key') || e.toString().contains('relation')) {
        print('🚨 DEBUG: [GET USER BOOKINGS] FOREIGN KEY OR RELATION ERROR!');
        print('🚨 DEBUG: [GET USER BOOKINGS] This might be a database relationship issue');
      }
      if (e.toString().contains('null')) {
        print('🚨 DEBUG: [GET USER BOOKINGS] NULL VALUE ERROR!');
      }
      if (e.toString().contains('permission') || e.toString().contains('policy')) {
        print('🚨 DEBUG: [GET USER BOOKINGS] PERMISSION/RLS POLICY ERROR!');
        print('🚨 DEBUG: [GET USER BOOKINGS] Check Row Level Security policies');
      }
      
      return [];
    }
  }

  // Get all transportation bookings made by other users (excluding current user)
  static Future<List<Map<String, dynamic>>> getOtherUsersBookings() async {
    try {
      final user = client.auth.currentUser;
      print('🔍 Current user: ${user?.id}');
      if (user == null) {
        print('❌ No authenticated user found');
        return [];
      }

      print('📡 Querying transportation_bookings table...');

      // Use a more targeted query that should work with RLS policies
      final response = await client.from('transportation_bookings').select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone)
          ''').neq('user_id', user.id).order('created_at', ascending: false);

      print('✅ Raw response length: ${response.length}');

      final bookings = List<Map<String, dynamic>>.from(response);

      // Log each booking for debugging
      for (var booking in bookings) {
        print(
            '📋 Booking ID: ${booking['id']}, Status: ${booking['status']}, Driver: ${booking['driver_id']}, User: ${booking['user']?['full_name']}');
      }

      return bookings;
    } catch (e) {
      print('❌ Error fetching other users bookings: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to fetch other users bookings: $e');
    }
  }

  // Get available transportation bookings for drivers (pending status, no runner assigned)
  static Future<List<Map<String, dynamic>>> getAvailableTransportationBookings(
      {String? vehicleTypeId}) async {
    try {
      print('🚌 Getting available transportation bookings...');
      print('🚗 Filtering by vehicle type: $vehicleTypeId');

      // Query for pending bookings with no driver assigned
      var query = client.from('transportation_bookings').select('''
            *,
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
            vehicle_type:vehicle_types(name, description)
          ''').eq('status', 'pending').filter('driver_id', 'is', null);

      // Note: Vehicle type filtering is done in the frontend using text-based matching
      // This ensures compatibility with the existing runner_applications.vehicle_type (text) field

      final response = await query.order('created_at', ascending: false);

      print('✅ Available transportation bookings: ${response.length}');

      final bookings = List<Map<String, dynamic>>.from(response);

      // Log each available booking
      for (var booking in bookings) {
        print(
            '🎯 Available: ${booking['id']} - ${booking['user']?['full_name']} - ${booking['vehicle_type']?['name'] ?? 'No vehicle required'} - ${booking['pickup_location']} to ${booking['dropoff_location']}');
      }

      return bookings;
    } catch (e) {
      print('❌ Error fetching available transportation bookings: $e');
      throw Exception('Failed to fetch available transportation bookings: $e');
    }
  }

  // Get all available bookings for drivers (transportation + contracts)
  static Future<List<Map<String, dynamic>>> getAvailableAllBookings(
      {String? vehicleTypeId}) async {
    try {
      print(
          '🚌 Getting all available bookings (transportation + contracts)...');
      print('🚗 Filtering by vehicle type: $vehicleTypeId');

      // Get available transportation bookings
      final transportationBookings = await getAvailableTransportationBookings(
          vehicleTypeId: vehicleTypeId);

      // Get available contract bookings
      print('🔍 Querying contract_bookings table...');
      final contractBookings = await client
          .from('contract_bookings')
          .select('''
            *,
            user:users!contract_bookings_user_id_fkey(full_name, email, phone),
            vehicle_type:vehicle_types(name, description)
          ''')
          .eq('status', 'pending')
          .filter('driver_id', 'is', null)
          .order('created_at', ascending: false);

      print(
          '📋 Contract bookings query result: ${contractBookings.length} bookings');
      for (var booking in contractBookings) {
        print(
            '📋 Contract: ${booking['id']} - Status: ${booking['status']} - Driver: ${booking['driver_id']}');
      }

      // Combine both types of bookings
      List<Map<String, dynamic>> allBookings = [];

      // Add transportation bookings with type identifier
      for (var booking in transportationBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'transportation',
          'title': 'Shuttle Services',
        });
      }

      // Add contract bookings with type identifier
      for (var booking in contractBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'contract',
          'title': 'Contract Booking',
        });
      }

      // Sort combined bookings by created_at
      allBookings.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      print(
          '✅ Available all bookings: ${allBookings.length} (${transportationBookings.length} transportation, ${contractBookings.length} contracts)');

      // Debug: Log each booking type
      for (var booking in allBookings) {
        print(
            '📋 Booking: ${booking['id']} - Type: ${booking['booking_type']} - Title: ${booking['title']} - Status: ${booking['status']}');
      }

      return allBookings;
    } catch (e) {
      print('❌ Error fetching available all bookings: $e');
      throw Exception('Failed to fetch available all bookings: $e');
    }
  }

  static Future<Map<String, dynamic>?> createTransportationBooking(
      Map<String, dynamic> bookingData) async {
    try {
      print('🚀 DEBUG: [CREATE TRANSPORTATION BOOKING] Starting booking creation...');
      print('📋 DEBUG: [CREATE TRANSPORTATION BOOKING] Booking data received: $bookingData');
      
      final user = client.auth.currentUser;
      print('👤 DEBUG: [CREATE TRANSPORTATION BOOKING] Current user: ${user?.id}');
      print('👤 DEBUG: [CREATE TRANSPORTATION BOOKING] User email: ${user?.email}');
      
      if (user == null) {
        print('❌ DEBUG: [CREATE TRANSPORTATION BOOKING] User not authenticated');
        throw Exception('User not authenticated');
      }

      // Ensure user_id is set
      bookingData['user_id'] = user.id;
      print('✅ DEBUG: [CREATE TRANSPORTATION BOOKING] User ID set: ${bookingData['user_id']}');
      
      // Log all booking data fields
      print('📝 DEBUG: [CREATE TRANSPORTATION BOOKING] Booking details:');
      print('   - user_id: ${bookingData['user_id']}');
      print('   - vehicle_type_id: ${bookingData['vehicle_type_id']}');
      print('   - pickup_location: ${bookingData['pickup_location']}');
      print('   - dropoff_location: ${bookingData['dropoff_location']}');
      print('   - pickup_lat: ${bookingData['pickup_lat']}');
      print('   - pickup_lng: ${bookingData['pickup_lng']}');
      print('   - dropoff_lat: ${bookingData['dropoff_lat']}');
      print('   - dropoff_lng: ${bookingData['dropoff_lng']}');
      print('   - passenger_count: ${bookingData['passenger_count']}');
      print('   - booking_date: ${bookingData['booking_date']}');
      print('   - booking_time: ${bookingData['booking_time']}');
      print('   - is_immediate: ${bookingData['is_immediate']}');
      print('   - status: ${bookingData['status']}');
      print('   - payment_status: ${bookingData['payment_status']}');
      print('   - estimated_price: ${bookingData['estimated_price']}');
      print('   - final_price: ${bookingData['final_price']}');
      print('   - special_requests: ${bookingData['special_requests']}');

      print('💾 DEBUG: [CREATE TRANSPORTATION BOOKING] Inserting into database...');
      final response = await client
          .from('transportation_bookings')
          .insert(bookingData)
          .select()
          .single();

      print('✅ DEBUG: [CREATE TRANSPORTATION BOOKING] Booking created successfully!');
      print('🆔 DEBUG: [CREATE TRANSPORTATION BOOKING] Booking ID: ${response['id']}');
      print('📊 DEBUG: [CREATE TRANSPORTATION BOOKING] Full response: $response');

      // If this is an immediate booking, notify runners with matching vehicle types
      if (bookingData['is_immediate'] == true) {
        print('🔔 DEBUG: [CREATE TRANSPORTATION BOOKING] This is an immediate booking - notifying runners...');
        try {
          await _notifyRunnersOfNewTransportationBooking(response);
          print('✅ DEBUG: [CREATE TRANSPORTATION BOOKING] Runners notified successfully');
        } catch (notifyError) {
          print('⚠️ DEBUG: [CREATE TRANSPORTATION BOOKING] Error notifying runners: $notifyError');
          // Don't fail the booking if notification fails
        }
      } else {
        print('📅 DEBUG: [CREATE TRANSPORTATION BOOKING] This is a scheduled booking - no immediate notification needed');
      }

      return response;
    } catch (e, stackTrace) {
      print('❌ DEBUG: [CREATE TRANSPORTATION BOOKING] Error creating transportation booking');
      print('❌ DEBUG: [CREATE TRANSPORTATION BOOKING] Error type: ${e.runtimeType}');
      print('❌ DEBUG: [CREATE TRANSPORTATION BOOKING] Error message: $e');
      print('❌ DEBUG: [CREATE TRANSPORTATION BOOKING] Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('constraint')) {
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] CONSTRAINT VIOLATION DETECTED!');
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] This might be a database constraint issue');
      }
      if (e.toString().contains('null')) {
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] NULL VALUE ERROR DETECTED!');
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] A required field might be null');
      }
      if (e.toString().contains('foreign key')) {
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] FOREIGN KEY ERROR DETECTED!');
        print('🚨 DEBUG: [CREATE TRANSPORTATION BOOKING] A referenced ID might not exist');
      }
      
      return null;
    }
  }

  static Future<bool> updateTransportationBooking(
      String bookingId, Map<String, dynamic> updates) async {
    try {
      print('🔄 DEBUG: updateTransportationBooking called');
      print('📋 DEBUG: Booking ID: $bookingId');
      print('📋 DEBUG: Booking ID type: ${bookingId.runtimeType}');
      print('📋 DEBUG: Booking ID length: ${bookingId.length}');
      print('📋 DEBUG: Updates: $updates');

      // Check if this is a cancellation update
      final isCancellation = updates['status'] == 'cancelled';
      print('🚫 DEBUG: Is cancellation: $isCancellation');

      // Check if this is an acceptance update and verify runner
      final isAcceptance =
          updates['status'] == 'accepted' && updates['driver_id'] != null;
      if (isAcceptance) {
        final driverId = updates['driver_id'];
        final canAccept = await canRunnerAcceptErrands(driverId);
        if (!canAccept) {
          throw Exception(
              'Cannot accept transportation booking. You must be verified to accept bookings. Please complete your verification process first.');
        }
      }

      // First, let's check if the booking exists
      print('🔍 DEBUG: Checking if booking exists before update...');
      try {
        final existingBooking = await client
            .from('transportation_bookings')
            .select('id, status, driver_id')
            .eq('id', bookingId)
            .maybeSingle();

        print('🔍 DEBUG: Existing booking: $existingBooking');

        if (existingBooking == null) {
          print('❌ DEBUG: Booking does not exist with ID: $bookingId');
          print(
              '❌ DEBUG: This suggests the booking was deleted/expired or never existed');
          print(
              '❌ DEBUG: The UI may be showing stale data - try refreshing the page');
          return false;
        }

        // Check if the booking is still available for acceptance
        if (existingBooking['status'] != 'pending') {
          print(
              '❌ DEBUG: Booking is not pending - current status: ${existingBooking['status']}');
          print('❌ DEBUG: This booking cannot be accepted');
          return false;
        }

        if (existingBooking['driver_id'] != null) {
          print(
              '❌ DEBUG: Booking already has a driver assigned: ${existingBooking['driver_id']}');
          print('❌ DEBUG: This booking cannot be accepted');
          return false;
        }

        print(
            '✅ DEBUG: Booking exists and is available for acceptance, proceeding with update...');

        // Check runner limits if this is an acceptance (not cancellation)
        if (!isCancellation && updates['driver_id'] != null) {
          print('🚦 DEBUG: Checking runner limits before acceptance...');
          final limits = await checkRunnerLimits(updates['driver_id']);
          print('🚦 DEBUG: Runner limits: $limits');

          if (!limits['can_accept_transportation']) {
            final totalCount = limits['total_active_count'] ?? 0;
            final totalLimit = limits['total_limit'] ?? 2;
            print(
                '❌ DEBUG: Runner has reached limit - cannot accept transportation booking');
            throw Exception(
                'Cannot accept transportation booking. You have reached your limit of $totalLimit active jobs (currently have $totalCount). Please complete existing jobs before accepting new ones.');
          }
        }
      } catch (e) {
        print('❌ DEBUG: Error checking if booking exists: $e');
        // Re-throw limit-related exceptions so they can be handled properly
        if (e.toString().contains('limit') ||
            e.toString().contains('maximum')) {
          rethrow;
        }
        return false;
      }

      if (isCancellation) {
        print('🚫 DEBUG: Processing cancellation...');

        // Get current booking details
        print('📋 DEBUG: Fetching current booking details...');
        final bookingResponse = await client
            .from('transportation_bookings')
            .select(
                'status, user_id, driver_id, service:transportation_services(name)')
            .eq('id', bookingId)
            .single();

        final currentStatus = bookingResponse['status'];
        final userId = bookingResponse['user_id'];
        final driverId = bookingResponse['driver_id'];
        final serviceName =
            bookingResponse['service']?['name'] ?? 'Transportation Service';

        print('📊 DEBUG: Current status: $currentStatus');
        print('👤 DEBUG: User ID: $userId');
        print('🚗 DEBUG: Driver ID: $driverId');
        print('🏢 DEBUG: Service name: $serviceName');

        // Check if cancellation is allowed - only allow cancellation of accepted bookings
        if (currentStatus == 'completed' || currentStatus == 'cancelled') {
          print('❌ DEBUG: Cannot cancel $currentStatus booking');
          throw Exception('Cannot cancel $currentStatus booking');
        }

        if (currentStatus == 'in_progress') {
          print('❌ DEBUG: Cannot cancel booking that is in progress');
          throw Exception('Cannot cancel booking that is in progress');
        }

        // Update the booking
        print('🔄 DEBUG: Updating booking to cancelled...');
        await client
            .from('transportation_bookings')
            .update(updates)
            .eq('id', bookingId);

        // Send cancellation notifications
        final currentUserId = SupabaseConfig.currentUser?.id;
        print('👤 DEBUG: Current user ID: $currentUserId');

        if (currentUserId == userId && driverId != null) {
          // Customer cancelled - notify runner
          print('🔔 DEBUG: Customer cancelled - notifying runner');
          await _notifyRunnerTransportationCancelled(
              driverId, userId, serviceName);
        } else if (currentUserId == driverId) {
          // Runner cancelled - notify customer
          print('🔔 DEBUG: Runner cancelled - notifying customer');
          await _notifyCustomerTransportationCancelled(
              userId, driverId, serviceName);
        }

        print('✅ DEBUG: Cancellation update successful');
        return true;
      } else {
        // For non-cancellation updates, proceed normally
        print('🔄 DEBUG: Processing non-cancellation update...');

        // First, let's check the current booking status
        try {
          print('📋 DEBUG: Checking current booking status...');
          final currentBooking = await client
              .from('transportation_bookings')
              .select('status, driver_id, user_id')
              .eq('id', bookingId)
              .single();

          print('📊 DEBUG: Current booking: $currentBooking');
          print(
              '📊 DEBUG: Current booking status: ${currentBooking['status']}');
          print('🚗 DEBUG: Current driver ID: ${currentBooking['driver_id']}');
          print('👤 DEBUG: Current user ID: ${currentBooking['user_id']}');
          print('🆔 DEBUG: Booking ID: ${currentBooking['id']}');

          // Check if this is an acceptance (setting driver_id from null)
          final isAcceptance = updates['driver_id'] != null &&
              currentBooking['driver_id'] == null &&
              updates['status'] == 'accepted';
          print('✅ DEBUG: Is acceptance: $isAcceptance');

          // Check if the booking exists and is in a valid state for acceptance
          if (currentBooking['status'] != 'pending') {
            print(
                '⚠️ DEBUG: WARNING - Booking is not in pending status, current status: ${currentBooking['status']}');
          }

          if (currentBooking['driver_id'] != null) {
            print(
                '⚠️ DEBUG: WARNING - Booking already has a driver assigned: ${currentBooking['driver_id']}');
          }
        } catch (e) {
          print('❌ DEBUG: Could not fetch current booking: $e');
          print(
              '❌ DEBUG: This might mean the booking does not exist or there is a permission issue');
          // Don't return false here, let the update attempt proceed to see what happens
        }

        print('🔄 DEBUG: Executing update...');
        print(
            '🔄 DEBUG: Update query: UPDATE transportation_bookings SET $updates WHERE id = $bookingId');

        dynamic response;
        try {
          response = await client
              .from('transportation_bookings')
              .update(updates)
              .eq('id', bookingId);
          print('✅ DEBUG: Update query executed without exception');
        } catch (updateError) {
          print('❌ DEBUG: Update query failed with exception: $updateError');
          print('❌ DEBUG: This is likely the root cause of the silent failure');
          rethrow; // Re-throw to be caught by outer catch
        }

        print('📊 DEBUG: Update response: $response');
        print('📊 DEBUG: Response type: ${response.runtimeType}');
        print('📊 DEBUG: Response length: ${response?.length ?? "null"}');

        // Check if the update actually worked by querying the record
        print('🔍 DEBUG: Verifying update by querying the record...');
        print('🔍 DEBUG: Looking for booking ID: $bookingId');
        try {
          // First, let's try to find the record without .single() to see what we get
          final allRecords = await client
              .from('transportation_bookings')
              .select('id, status, driver_id, updated_at')
              .eq('id', bookingId);

          print(
              '🔍 DEBUG: Found ${allRecords.length} records with ID $bookingId');
          print('🔍 DEBUG: Records: $allRecords');

          if (allRecords.isEmpty) {
            print('❌ DEBUG: No records found with ID $bookingId');
            print(
                '❌ DEBUG: This suggests the booking ID is invalid or the record was deleted');
            return false;
          }

          if (allRecords.length > 1) {
            print(
                '❌ DEBUG: Multiple records found with ID $bookingId - this should not happen');
            return false;
          }

          final updatedRecord = allRecords.first;

          print('🔍 DEBUG: Updated record: $updatedRecord');

          // Check if the status was actually updated
          final actualStatus = updatedRecord['status'];
          final actualDriverId = updatedRecord['driver_id'];
          final expectedStatus = updates['status'];
          final expectedDriverId = updates['driver_id'];

          print(
              '🔍 DEBUG: Expected status: $expectedStatus, Actual status: $actualStatus');
          print(
              '🔍 DEBUG: Expected driver_id: $expectedDriverId, Actual driver_id: $actualDriverId');

          if (actualStatus == expectedStatus &&
              actualDriverId == expectedDriverId) {
            print(
                '✅ DEBUG: Update verification successful - database was updated correctly');
            return true;
          } else {
            print(
                '❌ DEBUG: Update verification failed - database was NOT updated correctly');
            print('❌ DEBUG: This suggests a silent database failure');
            return false;
          }
        } catch (e) {
          print('❌ DEBUG: Error verifying update: $e');
          print('❌ DEBUG: This suggests the update may have failed');
          return false;
        }
      }
    } catch (e, stackTrace) {
      print('💥 DEBUG: Exception in updateTransportationBooking');
      print('💥 DEBUG: Error: $e');
      print('💥 DEBUG: Stack trace: $stackTrace');

      // Check if it's a constraint violation
      if (e.toString().contains('violates check constraint')) {
        print('🚨 DEBUG: CONSTRAINT VIOLATION DETECTED!');
        print('🚨 DEBUG: This is likely a status constraint issue');
        print(
            '🚨 DEBUG: Check if "accepted" status is allowed in the constraint');
      }

      // Check if it's an RLS policy violation
      if (e.toString().contains('row-level security')) {
        print('🚨 DEBUG: RLS POLICY VIOLATION DETECTED!');
        print('🚨 DEBUG: This is likely a Row Level Security policy issue');
        print(
            '🚨 DEBUG: Check if the user has permission to update this booking');
      }

      // Re-throw limit-related exceptions so they can be handled properly
      if (e.toString().contains('limit') || e.toString().contains('maximum')) {
        print('🚫 DEBUG: Re-throwing limit exception');
        rethrow;
      }

      return false;
    }
  }

  // Simplified price calculation - uses only vehicle declared price
  static Future<Map<String, dynamic>?> calculateTransportationServicePrice({
    required String serviceId,
    required int passengerCount,
    double? distance, // Parameter kept for compatibility but completely ignored
    bool includePickup = false,
    DateTime? bookingDate,
  }) async {
    try {
      // Get service pricing
      final pricingList = await getServicePricing(serviceId);
      if (pricingList.isEmpty) return null;

      final pricing = pricingList.first;
      double basePrice = (pricing['base_price'] as num).toDouble();
      double totalPrice = basePrice;

      // Apply passenger multiplier for certain vehicle types
      if (passengerCount > 1) {
        totalPrice *= passengerCount;
      }

      // Add pickup fee if requested
      if (includePickup && pricing['pickup_fee'] != null) {
        totalPrice += (pricing['pickup_fee'] as num).toDouble();
      }

      // All distance calculations removed - using only vehicle declared price

      // Apply minimum fare if set
      if (pricing['minimum_fare'] != null) {
        final minFare = (pricing['minimum_fare'] as num).toDouble();
        if (totalPrice < minFare) {
          totalPrice = minFare;
        }
      }

      // Apply maximum fare if set
      if (pricing['maximum_fare'] != null) {
        final maxFare = (pricing['maximum_fare'] as num).toDouble();
        if (totalPrice > maxFare) {
          totalPrice = maxFare;
        }
      }

      // Apply weekend/holiday multipliers if booking date is provided
      if (bookingDate != null) {
        final isWeekend = bookingDate.weekday >= 6;
        if (isWeekend && pricing['weekend_multiplier'] != null) {
          final multiplier = (pricing['weekend_multiplier'] as num).toDouble();
          totalPrice *= multiplier;
        }
      }

      return {
        'base_price': basePrice,
        'total_price': totalPrice,
        'pickup_fee': includePickup ? (pricing['pickup_fee'] ?? 0) : 0,
        'passenger_count': passengerCount,
        'currency': pricing['currency'] ?? 'NAD',
        'pricing_breakdown': {
          'base': basePrice,
          'passengers': passengerCount,
          'pickup': includePickup ? (pricing['pickup_fee'] ?? 0) : 0,
          'distance_km': distance,
        }
      };
    } catch (e) {
      print('Error calculating transportation price: $e');
      return null;
    }
  }

  // Simplified transportation price calculation - uses only vehicle declared price

  //// Simplified version - vehicle declared price is the final price
  static Future<Map<String, dynamic>?> calculateTransportationPrice({
    required String vehicleTypeId,
    required double
        distanceKm, // Parameter kept for compatibility but completely ignored
    required String userType,
  }) async {
    try {
      print(
          'SupabaseConfig: Using vehicle declared price for $vehicleTypeId, user type $userType');

      final response =
          await client.rpc('calculate_transportation_price', params: {
        'p_vehicle_type_id': vehicleTypeId,
        'p_distance_km': distanceKm,
        'p_user_type': userType,
      });

      print('SupabaseConfig: RPC response: $response');
      print('SupabaseConfig: Response type: ${response.runtimeType}');

      if (response == null) {
        print('SupabaseConfig: Response is null');
        return null;
      }

      // Handle the response based on its type
      if (response is List && response.isNotEmpty) {
        print(
            'SupabaseConfig: Response is a list with ${response.length} elements');

        // Get the first element
        final firstElement = response[0];
        print('SupabaseConfig: First element: $firstElement');
        print(
            'SupabaseConfig: First element type: ${firstElement.runtimeType}');

        if (firstElement is Map<String, dynamic>) {
          print('SupabaseConfig: Successfully parsed pricing data');
          return firstElement;
        } else {
          print('SupabaseConfig: First element is not a Map<String, dynamic>');
          return null;
        }
      } else if (response is Map<String, dynamic>) {
        print('SupabaseConfig: Response is a Map');
        return response;
      } else {
        print(
            'SupabaseConfig: Unexpected response format: ${response.runtimeType}');
        return null;
      }
    } catch (e) {
      print('SupabaseConfig: Error calculating transportation price: $e');
      return null;
    }
  }

  // Search services by criteria
  static Future<List<Map<String, dynamic>>> searchTransportationServices({
    String? originTownId,
    String? destinationTownId,
    String? subcategoryId,
    String? vehicleTypeId,
    DateTime? departureDate,
    int? minCapacity,
  }) async {
    var query = client.from('transportation_services').select('''
          *,
          route:service_routes(
            route_name, distance_km, estimated_duration_minutes,
            from_location, to_location
          ),
        ''').eq('is_active', true);

    final response = await query.order('name');
    List<Map<String, dynamic>> services =
        List<Map<String, dynamic>>.from(response);

    // Try to add pricing data if the table exists
    try {
      for (var service in services) {
        final pricingResponse = await client
            .from('service_pricing')
            .select('base_price, pickup_fee, currency')
            .eq('service_id', service['id']);
        service['pricing'] = pricingResponse;
      }
    } catch (e) {
      print('service_pricing table not found, skipping pricing data');
      // Add empty pricing data
      for (var service in services) {
        service['pricing'] = [];
      }
    }

    // Filter by route if origin/destination specified
    if (originTownId != null || destinationTownId != null) {
      services = services.where((service) {
        final route = service['route'];
        if (route == null) return false;

        bool matchOrigin = originTownId == null ||
            (route['from_location'] != null &&
                route['from_location'].toString().contains(originTownId));
        bool matchDestination = destinationTownId == null ||
            (route['to_location'] != null &&
                route['to_location'].toString().contains(destinationTownId));

        return matchOrigin && matchDestination;
      }).toList();
    }

    // Filter by vehicle capacity if specified
    if (minCapacity != null) {
      services = services.where((service) {
        final vehicleType = service['vehicle_type'];
        return vehicleType != null &&
            vehicleType['capacity'] != null &&
            vehicleType['capacity'] >= minCapacity;
      }).toList();
    }

    // Filter by departure date/day of week if specified
    if (departureDate != null) {
      final dayOfWeek = departureDate.weekday; // 1=Monday, 7=Sunday
      services = services.where((service) {
        final schedules = service['schedules'] as List?;
        if (schedules == null || schedules.isEmpty) return false;

        return schedules.any((schedule) {
          final daysOfWeek = schedule['days_of_week'] as List?;
          return daysOfWeek?.contains(dayOfWeek) == true;
        });
      }).toList();
    }

    return services;
  }

  // Service Reviews Management
  static Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId,
      {bool verifiedOnly = true}) async {
    var query = client.from('service_reviews').select('''
          *,
          user:users!service_reviews_user_id_fkey(full_name, avatar_url)
        ''').eq('service_id', serviceId);

    if (verifiedOnly) {
      query = query.eq('is_verified', true);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> createServiceReview(
      Map<String, dynamic> reviewData) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      reviewData['user_id'] = user.id;

      final response = await client
          .from('service_reviews')
          .insert(reviewData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating service review: $e');
      return null;
    }
  }

  // Admin Management Functions
  static Future<bool> updateServiceCategoryStatus(
      String categoryId, bool isActive) async {
    try {
      await client
          .from('service_categories')
          .update({'is_active': isActive}).eq('id', categoryId);
      return true;
    } catch (e) {
      print('Error updating category status: $e');
      return false;
    }
  }

  static Future<bool> updateTransportationServiceStatus(
      String serviceId, bool isActive) async {
    try {
      await client
          .from('transportation_services')
          .update({'is_active': isActive}).eq('id', serviceId);
      return true;
    } catch (e) {
      print('Error updating service status: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBookings(
      {String? status}) async {
    try {
      print('🔄 Loading all bookings (transportation + bus)...');

      // Get transportation bookings
      var transportationQuery =
          client.from('transportation_bookings').select('''
            *,
            user:users!transportation_bookings_user_id_fkey(
              id,
              full_name,
              email,
              phone
            ),
            service:transportation_services(
              id,
              name
            )
          ''');

      if (status != null) {
        transportationQuery = transportationQuery.eq('status', status);
      }

      final transportationResponse =
          await transportationQuery.order('created_at', ascending: false);
      final transportationBookings =
          List<Map<String, dynamic>>.from(transportationResponse);

      // Add booking type identifier
      for (var booking in transportationBookings) {
        booking['booking_type'] = 'transportation';
      }

      // Get bus service bookings
      var busQuery = client.from('bus_service_bookings').select('''
            *,
            user:users!bus_service_bookings_user_id_fkey(
              id,
              full_name,
              email,
              phone
            ),
            service:transportation_services!bus_service_bookings_service_id_fkey(
              id,
              name
            )
          ''');

      if (status != null) {
        busQuery = busQuery.eq('status', status);
      }

      final busResponse = await busQuery.order('created_at', ascending: false);
      final busBookings = List<Map<String, dynamic>>.from(busResponse);

      // Add booking type identifier
      for (var booking in busBookings) {
        booking['booking_type'] = 'bus';
      }

      // Combine both types
      final allBookings = [...transportationBookings, ...busBookings];

      // Sort by created_at descending
      allBookings.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      print(
          '✅ Loaded ${transportationBookings.length} transportation bookings and ${busBookings.length} bus bookings');
      return allBookings;
    } catch (e) {
      print('❌ Error loading all bookings: $e');
      return [];
    }
  }

  // Delete all errands for a user
  static Future<void> deleteAllUserErrands(String userId) async {
    try {
      // Delete errands where user is the customer or runner
      await client
          .from('errands')
          .delete()
          .or('customer_id.eq.$userId,runner_id.eq.$userId');
    } catch (e) {
      throw Exception('Failed to delete user errands: $e');
    }
  }

  // Delete all transportation bookings for a user
  static Future<void> deleteAllUserBookings(String userId) async {
    try {
      await client
          .from('transportation_bookings')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete user bookings: $e');
    }
  }

  // Delete all errands and bookings for a user
  static Future<void> deleteAllUserData(String userId) async {
    try {
      await deleteAllUserErrands(userId);
      await deleteAllUserBookings(userId);
    } catch (e) {
      throw Exception('Failed to delete all user data: $e');
    }
  }

  // Delete a single errand by ID (only if user is the customer)
  static Future<void> deleteErrand(String errandId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Only allow deletion if user is the customer of this errand
      // Runners cannot delete errands as they belong to customers
      await client
          .from('errands')
          .delete()
          .eq('id', errandId)
          .eq('customer_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete errand: $e');
    }
  }

  // Delete a single transportation booking by ID (only if user is the owner)
  static Future<void> deleteTransportationBooking(String bookingId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Only allow deletion if user is the owner of this booking
      await client
          .from('transportation_bookings')
          .delete()
          .eq('id', bookingId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete transportation booking: $e');
    }
  }

  // Start a transportation booking (change status from accepted to in_progress)
  static Future<void> startTransportationBooking(String bookingId) async {
    try {
      print('🔧 startTransportationBooking called with ID: $bookingId');

      final updateData = {
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 Update data: $updateData');

      final result = await client
          .from('transportation_bookings')
          .update(updateData)
          .eq('id', bookingId);

      print('✅ Database update result: $result');
      print(
          '✅ Transportation booking status updated successfully to in_progress');
    } catch (e) {
      print('❌ Database error in startTransportationBooking: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to start transportation booking: $e');
    }
  }

  // Complete a transportation booking (change status from in_progress to completed)
  static Future<void> completeTransportationBooking(String bookingId) async {
    try {
      print('🔧 completeTransportationBooking called with ID: $bookingId');

      final updateData = {
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 Update data: $updateData');

      final result = await client
          .from('transportation_bookings')
          .update(updateData)
          .eq('id', bookingId);

      print('✅ Database update result: $result');
      print(
          '✅ Transportation booking status updated successfully to completed');
    } catch (e) {
      print('❌ Database error in completeTransportationBooking: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to complete transportation booking: $e');
    }
  }

  // Start a contract booking (change status from accepted to in_progress)
  static Future<void> startContractBooking(String bookingId) async {
    try {
      print('🔧 startContractBooking called with ID: $bookingId');

      final updateData = {
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 Update data: $updateData');

      final result = await client
          .from('contract_bookings')
          .update(updateData)
          .eq('id', bookingId);

      print('✅ Database update result: $result');
      print('✅ Contract booking status updated successfully to in_progress');
    } catch (e) {
      print('❌ Database error in startContractBooking: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to start contract booking: $e');
    }
  }

  // Complete a contract booking (change status from in_progress to completed)
  static Future<void> completeContractBooking(String bookingId) async {
    try {
      print('🔧 completeContractBooking called with ID: $bookingId');

      final updateData = {
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📝 Update data: $updateData');

      final result = await client
          .from('contract_bookings')
          .update(updateData)
          .eq('id', bookingId);

      print('✅ Database update result: $result');
      print('✅ Contract booking status updated successfully to completed');
    } catch (e) {
      print('❌ Database error in completeContractBooking: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to complete contract booking: $e');
    }
  }

  // Get transportation bookings assigned to a specific runner
  static Future<List<Map<String, dynamic>>> getRunnerTransportationBookings(
      String runnerId) async {
    try {
      final response = await client.from('transportation_bookings').select('''
          *,
          user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
          service:transportation_services(
            name
          )
        ''').eq('driver_id', runnerId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching runner transportation bookings: $e');
      return [];
    }
  }

  // Get all bookings assigned to a specific runner (transportation + contracts)
  static Future<List<Map<String, dynamic>>> getRunnerAllBookings(
      String runnerId) async {
    try {
      // Get transportation bookings
      final transportationBookings =
          await client.from('transportation_bookings').select('''
          *,
          user:users!transportation_bookings_user_id_fkey(full_name, email, phone),
          service:transportation_services(
            name
          )
        ''').eq('driver_id', runnerId).order('created_at', ascending: false);

      // Get contract bookings
      final contractBookings = await client.from('contract_bookings').select('''
          *,
          user:users!contract_bookings_user_id_fkey(full_name, email, phone)
        ''').eq('driver_id', runnerId).order('created_at', ascending: false);

      // Combine both types of bookings
      List<Map<String, dynamic>> allBookings = [];

      // Add transportation bookings with type identifier
      for (var booking in transportationBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'transportation',
          'title': 'Shuttle Services',
        });
      }

      // Add contract bookings with type identifier
      for (var booking in contractBookings) {
        allBookings.add({
          ...booking,
          'booking_type': 'contract',
          'title': 'Contract Booking',
        });
      }

      // Sort combined bookings by created_at
      allBookings.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      return allBookings;
    } catch (e) {
      print('Error fetching runner all bookings: $e');
      return [];
    }
  }

  // Accept a contract booking (similar to acceptErrand)
  static Future<void> acceptContractBooking(
      String bookingId, String driverId) async {
    try {
      print('🔄 Starting contract booking acceptance process...');
      print('🔄 Booking ID: $bookingId');
      print('🔄 Driver ID: $driverId');

      // Check runner limits first
      print('🚦 DEBUG: [CONTRACT] Checking runner limits before acceptance...');
      final limits = await checkRunnerLimits(driverId);
      print('🚦 DEBUG: [CONTRACT] Runner limits: $limits');

      if (!limits['can_accept_contract']) {
        final totalCount = limits['total_active_count'] ?? 0;
        final totalLimit = limits['total_limit'] ?? 2;
        throw Exception(
            'Cannot accept contract booking. You have reached your limit of $totalLimit active jobs (currently have $totalCount). Please complete existing jobs before accepting new ones.');
      }

      // Get contract booking details first
      print(
          '🔍 DEBUG: [CONTRACT] Checking if contract booking exists with ID: $bookingId');
      final bookingResponse = await client
          .from('contract_bookings')
          .select('user_id, description, status, driver_id')
          .eq('id', bookingId)
          .maybeSingle();

      print('🔍 DEBUG: [CONTRACT] Contract booking response: $bookingResponse');

      if (bookingResponse == null) {
        print(
            '❌ DEBUG: [CONTRACT] Contract booking does not exist with ID: $bookingId');
        throw Exception('Contract booking does not exist with ID: $bookingId');
      }

      print('📋 Current contract booking details: $bookingResponse');

      final customerId = bookingResponse['user_id'];
      final description = bookingResponse['description'];
      final currentStatus = bookingResponse['status'];
      final currentDriverId = bookingResponse['driver_id'];

      // Check if booking is already accepted
      if (currentStatus == 'accepted' && currentDriverId == driverId) {
        print('⚠️ Contract booking already accepted by this driver');
        return;
      }

      // Check if booking is in a valid state for acceptance
      if (currentStatus != 'pending') {
        throw Exception(
            'Cannot accept contract booking with status: $currentStatus');
      }

      print('🔄 Updating contract booking status to accepted...');

      // Update booking status
      final updateResult = await client.from('contract_bookings').update({
        'driver_id': driverId,
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      print('✅ Contract booking acceptance update result: $updateResult');

      // Verify the update was successful
      final verifyResponse = await client
          .from('contract_bookings')
          .select('status, driver_id')
          .eq('id', bookingId)
          .single();

      print('🔍 Verification - Updated contract booking: $verifyResponse');

      // Create chat conversation
      await _createContractBookingChat(
          bookingId, customerId, driverId, description);
    } catch (e) {
      print('❌ Error in acceptContractBooking: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to accept contract booking: $e');
    }
  }

  // Helper method to create chat conversation when contract booking is accepted
  static Future<void> _createContractBookingChat(String bookingId,
      String customerId, String driverId, String description) async {
    try {
      // Create conversation
      final conversationResponse = await client
          .from('chat_conversations')
          .insert({
            'contract_booking_id': bookingId,
            'customer_id': customerId,
            'runner_id': driverId,
            'status': 'active',
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'];

      // Send initial welcome message
      await client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': driverId,
        'message':
            'Hi! I\'ve accepted your contract booking "$description". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      print('✅ Chat conversation created for contract booking: $bookingId');
    } catch (e) {
      print('❌ Error creating chat conversation: $e');
      // Don't throw here as the booking was accepted successfully
    }
  }

  // ============= VEHICLE PRICING MANAGEMENT =============

  // Get vehicle pricing information
  static Future<Map<String, dynamic>?> getVehiclePricing(
      String vehicleTypeId) async {
    try {
      final response = await client
          .from('vehicle_pricing')
          .select('*')
          .eq('vehicle_type_id', vehicleTypeId)
          .eq('is_active', true)
          .single();
      return response;
    } catch (e) {
      print('Error fetching vehicle pricing: $e');
      return null;
    }
  }

  // Create or update vehicle pricing
  static Future<Map<String, dynamic>?> createVehiclePricing(
      Map<String, dynamic> pricingData) async {
    try {
      final response = await client
          .from('vehicle_pricing')
          .upsert(pricingData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating vehicle pricing: $e');
      return null;
    }
  }

  // Update vehicle pricing
  static Future<bool> updateVehiclePricing(
      String pricingId, Map<String, dynamic> updates) async {
    try {
      await client.from('vehicle_pricing').update(updates).eq('id', pricingId);
      return true;
    } catch (e) {
      print('Error updating vehicle pricing: $e');
      return false;
    }
  }

  // Get vehicle pricing tiers
  static Future<List<Map<String, dynamic>>> getVehiclePricingTiers(
      String vehicleTypeId) async {
    try {
      final response = await client
          .from('vehicle_pricing_tiers')
          .select('*')
          .eq('vehicle_type_id', vehicleTypeId)
          .eq('is_active', true)
          .order('min_distance_km');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vehicle pricing tiers: $e');
      return [];
    }
  }

  // Create vehicle pricing tier
  static Future<Map<String, dynamic>?> createVehiclePricingTier(
      Map<String, dynamic> tierData) async {
    try {
      final response = await client
          .from('vehicle_pricing_tiers')
          .insert(tierData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creating vehicle pricing tier: $e');
      return null;
    }
  }

  // Update vehicle pricing tier
  static Future<bool> updateVehiclePricingTier(
      String tierId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('vehicle_pricing_tiers')
          .update(updates)
          .eq('id', tierId);
      return true;
    } catch (e) {
      print('Error updating vehicle pricing tier: $e');
      return false;
    }
  }

  // Delete vehicle pricing tier
  static Future<bool> deleteVehiclePricingTier(String tierId) async {
    try {
      await client.from('vehicle_pricing_tiers').delete().eq('id', tierId);
      return true;
    } catch (e) {
      print('Error deleting vehicle pricing tier: $e');
      return false;
    }
  }

  // Get user type for pricing calculations
  static Future<String> getUserType() async {
    try {
      final user = currentUser;
      if (user != null) {
        final userData = await client
            .from('users')
            .select('user_type')
            .eq('id', user.id)
            .single();
        return userData['user_type'] ?? 'individual';
      }
      return 'individual';
    } catch (e) {
      print('Error getting user type: $e');
      return 'individual';
    }
  }

  // Create transportation booking with pricing
  static Future<Map<String, dynamic>?> createTransportationBookingWithPricing({
    required Map<String, dynamic> bookingData,
    required Map<String, dynamic> pricingData,
  }) async {
    try {
      // Use the database function for atomic creation
      final response = await client
          .rpc('create_transportation_booking_with_pricing', params: {
        'p_booking_data': bookingData,
        'p_pricing_data': pricingData,
      });

      if (response != null) {
        return response;
      }

      return null;
    } catch (e) {
      print('Error creating transportation booking with pricing: $e');
      return null;
    }
  }

  // Get transportation booking pricing
  static Future<Map<String, dynamic>?> getTransportationBookingPricing(
      String bookingId) async {
    try {
      final response = await client
          .from('transportation_booking_pricing')
          .select('*')
          .eq('booking_id', bookingId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching transportation booking pricing: $e');
      return null;
    }
  }

  // Update vehicle type with pricing information
  static Future<bool> updateVehicleTypeWithPricing(
    String vehicleTypeId,
    Map<String, dynamic> vehicleData,
    Map<String, dynamic>? pricingData,
  ) async {
    try {
      // Update vehicle type
      await client
          .from('vehicle_types')
          .update(vehicleData)
          .eq('id', vehicleTypeId);

      // Update or create pricing if provided
      if (pricingData != null) {
        pricingData['vehicle_type_id'] = vehicleTypeId;
        await client.from('vehicle_pricing').upsert(pricingData);
      }

      return true;
    } catch (e) {
      print('Error updating vehicle type with pricing: $e');
      return false;
    }
  }

  // Debug function to check current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfileDebug() async {
    if (currentUser == null) {
      print('❌ No current user found');
      return null;
    }

    try {
      print('🔍 Getting profile for user: ${currentUser!.id}');
      print('🔍 User email: ${currentUser!.email}');
      print('🔍 User metadata: ${currentUser!.userMetadata}');

      final profile = await getUserProfile(currentUser!.id);
      print('🔍 User profile: $profile');

      if (profile != null) {
        print('🔍 User type: ${profile['user_type']}');
        print('🔍 Full name: ${profile['full_name']}');
        print('🔍 Is verified: ${profile['is_verified']}');
      } else {
        print('❌ No profile found for user');
      }

      return profile;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Check runner limits for ALL job types (transportation, contract, errands, immediate jobs)
  static Future<Map<String, dynamic>> checkRunnerLimits(String runnerId) async {
    try {
      print('🚦 DEBUG: Checking runner limits for: $runnerId');

      // Get active transportation bookings (accepted, in_progress) - includes immediate bookings
      print('🚦 DEBUG: Querying active transportation bookings...');
      final activeTransportationBookings = await client
          .from('transportation_bookings')
          .select('id, status, is_immediate')
          .eq('driver_id', runnerId)
          .or('status.eq.accepted,status.eq.in_progress');

      print(
          '🚦 DEBUG: Active transportation bookings: $activeTransportationBookings');

      // Get active contract bookings (accepted, in_progress)
      print('🚦 DEBUG: Querying active contract bookings...');
      final activeContractBookings = await client
          .from('contract_bookings')
          .select('id, status')
          .eq('driver_id', runnerId)
          .or('status.eq.accepted,status.eq.in_progress');

      print('🚦 DEBUG: Active contract bookings: $activeContractBookings');

      // Get active errands (accepted, in_progress) - includes immediate errands
      print('🚦 DEBUG: Querying active errands...');
      final activeErrands = await client
          .from('errands')
          .select('id, status, is_immediate')
          .eq('runner_id', runnerId)
          .or('status.eq.accepted,status.eq.in_progress');

      print('🚦 DEBUG: Active errands: $activeErrands');

      final transportationCount = activeTransportationBookings.length;
      final contractCount = activeContractBookings.length;
      final errandsCount = activeErrands.length;
      final totalActiveCount =
          transportationCount + contractCount + errandsCount;
      final totalLimit = 2; // Maximum 2 active jobs total across all types

      print(
          '🚦 DEBUG: Counts - Transportation: $transportationCount, Contract: $contractCount, Errands: $errandsCount, Total: $totalActiveCount, Limit: $totalLimit');

      final limits = {
        'transportation_count': transportationCount,
        'contract_count': contractCount,
        'errands_count': errandsCount,
        'total_active_count': totalActiveCount,
        'can_accept_transportation': totalActiveCount < totalLimit,
        'can_accept_contract': totalActiveCount < totalLimit,
        'can_accept_errands': totalActiveCount < totalLimit,
        'transportation_limit': 2,
        'contract_limit': 2,
        'errands_limit': 2,
        'total_limit': totalLimit,
      };

      print('🚦 DEBUG: Final runner limits: $limits');
      print(
          '🚦 DEBUG: Can accept transportation: ${limits['can_accept_transportation']}');
      print('🚦 DEBUG: Can accept contract: ${limits['can_accept_contract']}');
      print('🚦 DEBUG: Can accept errands: ${limits['can_accept_errands']}');

      return limits;
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error checking runner limits: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');

      // Return safe defaults that block acceptance on error
      final safeLimits = {
        'transportation_count': 0,
        'contract_count': 0,
        'errands_count': 0,
        'total_active_count': 0,
        'can_accept_transportation': false, // Block on error to be safe
        'can_accept_contract': false, // Block on error to be safe
        'can_accept_errands': false, // Block on error to be safe
        'transportation_limit': 2,
        'contract_limit': 2,
        'errands_limit': 2,
        'total_limit': 2,
      };

      print('🚦 DEBUG: Returning safe limits due to error: $safeLimits');
      return safeLimits;
    }
  }

  // Get runner's active transportation bookings
  static Future<List<Map<String, dynamic>>>
      getRunnerActiveTransportationBookings(String runnerId) async {
    try {
      final response = await client
          .from('transportation_bookings')
          .select('''
            *,
            service:transportation_services(
              name
            ),
            user:users!transportation_bookings_user_id_fkey(full_name, email, phone)
          ''')
          .eq('driver_id', runnerId)
          .or('status.eq.accepted,status.eq.in_progress')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting runner active transportation bookings: $e');
      return [];
    }
  }

  // Cancel transportation booking (runner cancels)
  static Future<bool> cancelTransportationBooking(String bookingId) async {
    try {
      print('🚫 Cancelling transportation booking: $bookingId');

      // Get current booking details first
      final bookingResponse = await client
          .from('transportation_bookings')
          .select(
              'status, user_id, driver_id, service:transportation_services(name)')
          .eq('id', bookingId)
          .single();

      final currentStatus = bookingResponse['status'];
      final userId = bookingResponse['user_id'];
      final driverId = bookingResponse['driver_id'];
      final serviceName =
          bookingResponse['service']?['name'] ?? 'Transportation Service';

      // Check if cancellation is allowed - only allow cancellation of accepted bookings
      if (currentStatus == 'completed' || currentStatus == 'cancelled') {
        throw Exception('Cannot cancel $currentStatus booking');
      }

      if (currentStatus == 'in_progress') {
        throw Exception('Cannot cancel booking that is in progress');
      }

      await client.from('transportation_bookings').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      // Send cancellation notification to customer
      await _notifyCustomerTransportationCancelled(
          userId, driverId, serviceName);

      print('✅ Transportation booking cancelled successfully');
      return true;
    } catch (e) {
      print('❌ Error cancelling transportation booking: $e');
      return false;
    }
  }

  // Bus Service Methods
  static Future<List<Map<String, dynamic>>>
      getBusServicesWithProviders() async {
    try {
      print('🚌 Fetching bus services with all providers...');

      // Test if transportation_services table exists
      try {
        await client.from('transportation_services').select('count').limit(1);
        print('✅ transportation_services table exists');
      } catch (e) {
        print('❌ transportation_services table does not exist: $e');
        print('💡 Please run the transportation system setup scripts first');
        return [];
      }

      // Get all active transportation services with array-based provider data
      final servicesResponse =
          await client.from('transportation_services').select('''
            *,
            route:service_routes(route_name, from_location, to_location)
          ''').eq('is_active', true).order('name');

      print('✅ Found ${servicesResponse.length} transportation services');

      // Process each service to extract provider information from arrays
      List<Map<String, dynamic>> servicesWithProviders = [];
      for (var service in servicesResponse) {
        List<Map<String, dynamic>> serviceProviders = [];

        // Check if service has array-based provider data
        final providerIds = service['provider_ids'] as List<dynamic>?;
        final prices = service['prices'] as List<dynamic>?;
        final departureTimes = service['departure_times'] as List<dynamic>?;
        final checkInTimes = service['check_in_times'] as List<dynamic>?;
        final featuresArray = service['features_array'] as List<dynamic>?;

        if (providerIds != null && providerIds.isNotEmpty) {
          // Get provider details for each provider ID in the array
          for (int i = 0; i < providerIds.length; i++) {
            final providerId = providerIds[i];

            try {
              // Get provider details
              final providerResponse = await client
                  .from('service_providers')
                  .select(
                      'id, name, description, contact_phone, contact_email, rating, total_reviews, is_verified')
                  .eq('id', providerId)
                  .eq('is_active', true)
                  .maybeSingle();

              if (providerResponse != null) {
                Map<String, dynamic> providerWithDetails =
                    Map<String, dynamic>.from(providerResponse);

                // Add service-specific provider data from arrays
                if (prices != null && i < prices.length) {
                  providerWithDetails['service_price'] = prices[i];
                }
                if (departureTimes != null && i < departureTimes.length) {
                  providerWithDetails['service_departure_time'] =
                      departureTimes[i];
                }
                if (checkInTimes != null && i < checkInTimes.length) {
                  providerWithDetails['service_check_in_time'] =
                      checkInTimes[i];
                }
                if (featuresArray != null && i < featuresArray.length) {
                  // Extract features for this provider
                  final providerFeatures = featuresArray[i];
                  if (providerFeatures is List) {
                    providerWithDetails['features'] = providerFeatures
                        .map((f) => f.toString())
                        .where((f) => f.isNotEmpty)
                        .toList();
                  } else {
                    providerWithDetails['features'] = <String>[];
                  }
                } else {
                  providerWithDetails['features'] = <String>[];
                }

                serviceProviders.add(providerWithDetails);
              }
            } catch (e) {
              print('⚠️ Error fetching provider $providerId: $e');
            }
          }
        } else {
          // Fallback: check if service has legacy single provider_id
          final legacyProviderId = service['provider_id'];
          if (legacyProviderId != null) {
            try {
              final providerResponse = await client
                  .from('service_providers')
                  .select(
                      'id, name, description, contact_phone, contact_email, rating, total_reviews, is_verified')
                  .eq('id', legacyProviderId)
                  .eq('is_active', true)
                  .maybeSingle();

              if (providerResponse != null) {
                Map<String, dynamic> providerWithDetails =
                    Map<String, dynamic>.from(providerResponse);

                // Add legacy service data
                providerWithDetails['service_price'] = service['price'];
                providerWithDetails['service_departure_time'] =
                    service['departure_time'];
                providerWithDetails['service_check_in_time'] =
                    service['check_in_time'];

                serviceProviders.add(providerWithDetails);
              }
            } catch (e) {
              print('⚠️ Error fetching legacy provider $legacyProviderId: $e');
            }
          }
        }

        // Add providers to the service
        Map<String, dynamic> serviceWithProviders =
            Map<String, dynamic>.from(service);
        serviceWithProviders['providers'] = serviceProviders;
        servicesWithProviders.add(serviceWithProviders);

        print(
            '📋 Service "${service['name']}" has ${serviceProviders.length} provider(s)');
      }

      return servicesWithProviders;
    } catch (e) {
      print('❌ Error getting bus services with providers: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getBusServices() async {
    try {
      print('🚌 Fetching bus services...');

      // Test if transportation_services table exists
      try {
        await client.from('transportation_services').select('count').limit(1);
        print('✅ transportation_services table exists');
      } catch (e) {
        print('❌ transportation_services table does not exist: $e');
        print('💡 Please run the transportation system setup scripts first');
        return [];
      }

      // Test if service_routes table exists
      try {
        await client.from('service_routes').select('count').limit(1);
        print('✅ service_routes table exists');
      } catch (e) {
        print('❌ service_routes table does not exist: $e');
        print('💡 Please run the transportation system setup scripts first');
        return [];
      }

      // Get all active transportation services (no subcategory filtering)
      final response = await client.from('transportation_services').select('''
            *,
            route:service_routes(route_name, from_location, to_location)
          ''').eq('is_active', true).order('name');

      print('✅ Found ${response.length} transportation services');

      // Debug: Print the first service if any found
      if (response.isNotEmpty) {
        print('🔍 First service: ${response.first}');
      } else {
        print('⚠️ No transportation services found');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting bus services: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createBusServiceBooking(
      Map<String, dynamic> bookingData) async {
    try {
      print('🚌 Creating bus service booking: $bookingData');

      final response = await client
          .from('bus_service_bookings')
          .insert(bookingData)
          .select()
          .single();

      print('✅ Bus service booking created successfully');
      return response;
    } catch (e) {
      print('❌ Error creating bus service booking: $e');
      return null;
    }
  }

  // Contract Booking Methods
  static Future<Map<String, dynamic>?> createContractBooking(
      Map<String, dynamic> contractData) async {
    try {
      print('📋 Creating contract booking: $contractData');

      final response = await client
          .from('contract_bookings')
          .insert(contractData)
          .select()
          .single();

      print('✅ Contract booking created successfully');
      return response;
    } catch (e) {
      print('❌ Error creating contract booking: $e');
      return null;
    }
  }

  // Admin Bus Management Methods
  static Future<List<Map<String, dynamic>>> getBusServiceBookings() async {
    try {
      print('🚌 Getting all bus service bookings for admin');

      final response = await client.from('bus_service_bookings').select('''
            *,
            user:users!bus_service_bookings_user_id_fkey(
              full_name,
              email,
              phone,
              user_type
            ),
            service:transportation_services!bus_service_bookings_service_id_fkey(
              name,
              provider_names
            )
          ''').order('created_at', ascending: false);

      // Transform the data to flatten user information
      final bookings = List<Map<String, dynamic>>.from(response);
      return bookings.map((booking) {
        final user = booking['user'] as Map<String, dynamic>?;
        final service = booking['service'] as Map<String, dynamic>?;

        // Get provider name from service
        String providerName = 'Unknown Provider';
        if (service != null && service['provider_names'] != null) {
          final providerNames = service['provider_names'] as List<dynamic>?;
          if (providerNames != null && providerNames.isNotEmpty) {
            providerName = providerNames.first.toString();
          }
        }

        return {
          ...booking,
          'user_name': user?['full_name'] ?? 'Unknown User',
          'user_email': user?['email'] ?? '',
          'user_phone': user?['phone'] ?? '',
          'user_type': user?['user_type'] ?? 'individual',
          'provider_name': providerName,
          'service_name': service?['name'] ?? 'Unknown Service',
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting bus service bookings: $e');
      return [];
    }
  }

  static Future<bool> updateBusBookingStatus(
      String bookingId, String status) async {
    try {
      print('🔄 Updating bus booking status: $bookingId to $status');

      // Get booking details before updating
      final bookingResponse = await client
          .from('bus_service_bookings')
          .select('user_id, service:transportation_services(name)')
          .eq('id', bookingId)
          .single();

      final userId = bookingResponse['user_id'];
      final serviceName = bookingResponse['service']?['name'] ?? 'Bus Service';

      final response = await client.from('bus_service_bookings').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      print('✅ Bus booking status updated successfully: $response');

      // If admin is accepting the booking, notify the customer
      if (status == 'accepted') {
        final currentUserId = SupabaseConfig.currentUser?.id;
        if (currentUserId != null) {
          await _notifyCustomerBusBookingAcceptedByAdmin(
              userId, currentUserId, serviceName);
        }
      }

      return true;
    } catch (e) {
      print('❌ Error updating bus booking status: $e');
      return false;
    }
  }

  // Get providers for a specific route using provider_names array
  static Future<List<Map<String, dynamic>>> getProvidersForRoute(
      String routeId) async {
    try {
      final response = await client.from('transportation_services').select('''
            id,
            name,
            provider_ids,
            provider_names,
            prices,
            departure_times,
            check_in_times,
            provider_operating_days,
            advance_booking_hours_array,
            cancellation_hours_array
          ''').eq('route_id', routeId).eq('is_active', true);

      List<Map<String, dynamic>> providers = [];

      for (var service in response) {
        List<dynamic>? providerIds = service['provider_ids'];
        List<dynamic>? providerNames = service['provider_names'];
        List<dynamic>? prices = service['prices'];
        List<dynamic>? departureTimes = service['departure_times'];
        List<dynamic>? checkInTimes = service['check_in_times'];
        List<dynamic>? operatingDays = service['provider_operating_days'];
        List<dynamic>? advanceHours = service['advance_booking_hours_array'];
        List<dynamic>? cancellationHours = service['cancellation_hours_array'];

        if (providerIds != null && providerIds.isNotEmpty) {
          for (int i = 0; i < providerIds.length; i++) {
            // Convert operating days from integers to day names
            List<String> dayNames = [];
            if (operatingDays != null &&
                i < operatingDays.length &&
                operatingDays[i] is List) {
              List<int> dayInts = List<int>.from(operatingDays[i]);
              dayNames = dayInts
                  .map((dayInt) => _convertDayIntToName(dayInt))
                  .toList();
            }

            providers.add({
              'provider_id': providerIds[i],
              'provider_name': providerNames != null && i < providerNames.length
                  ? providerNames[i]
                  : 'Unknown Provider',
              'service_id': service['id'],
              'service_name': service['name'],
              'price': prices != null && i < prices.length ? prices[i] : 0.0,
              'departure_time':
                  departureTimes != null && i < departureTimes.length
                      ? departureTimes[i]
                      : '08:00',
              'check_in_time': checkInTimes != null && i < checkInTimes.length
                  ? checkInTimes[i]
                  : null,
              'operating_days': dayNames,
              'advance_booking_hours':
                  advanceHours != null && i < advanceHours.length
                      ? advanceHours[i]
                      : 1,
              'cancellation_hours':
                  cancellationHours != null && i < cancellationHours.length
                      ? cancellationHours[i]
                      : 2,
              'is_active': true,
            });
          }
        }
      }

      // Remove duplicates based on provider_id
      final uniqueProviders = <String, Map<String, dynamic>>{};
      for (var provider in providers) {
        uniqueProviders[provider['provider_id']] = provider;
      }

      return uniqueProviders.values.toList();
    } catch (e) {
      print('Error getting providers for route: $e');
      return [];
    }
  }

  // Get providers for a specific route by route name (alternative method)
  static Future<List<Map<String, dynamic>>> getProvidersForRouteByName(
      String routeName) async {
    try {
      final response = await client.from('transportation_services').select('''
            id,
            name,
            provider_ids,
            provider_names,
            prices,
            departure_times,
            check_in_times,
            provider_operating_days,
            advance_booking_hours_array,
            cancellation_hours_array,
            route:service_routes(id, route_name)
          ''').eq('is_active', true).ilike('route.route_name', '%$routeName%');

      List<Map<String, dynamic>> providers = [];

      for (var service in response) {
        List<dynamic>? providerIds = service['provider_ids'];
        List<dynamic>? providerNames = service['provider_names'];
        List<dynamic>? prices = service['prices'];
        List<dynamic>? departureTimes = service['departure_times'];
        List<dynamic>? checkInTimes = service['check_in_times'];
        List<dynamic>? operatingDays = service['provider_operating_days'];
        List<dynamic>? advanceHours = service['advance_booking_hours_array'];
        List<dynamic>? cancellationHours = service['cancellation_hours_array'];

        if (providerIds != null && providerIds.isNotEmpty) {
          for (int i = 0; i < providerIds.length; i++) {
            // Convert operating days from integers to day names
            List<String> dayNames = [];
            if (operatingDays != null &&
                i < operatingDays.length &&
                operatingDays[i] is List) {
              List<int> dayInts = List<int>.from(operatingDays[i]);
              dayNames = dayInts
                  .map((dayInt) => _convertDayIntToName(dayInt))
                  .toList();
            }

            providers.add({
              'provider_id': providerIds[i],
              'provider_name': providerNames != null && i < providerNames.length
                  ? providerNames[i]
                  : 'Unknown Provider',
              'service_id': service['id'],
              'service_name': service['name'],
              'route_name': service['route']?['route_name'] ?? 'Unknown Route',
              'price': prices != null && i < prices.length ? prices[i] : 0.0,
              'departure_time':
                  departureTimes != null && i < departureTimes.length
                      ? departureTimes[i]
                      : '08:00',
              'check_in_time': checkInTimes != null && i < checkInTimes.length
                  ? checkInTimes[i]
                  : null,
              'operating_days': dayNames,
              'advance_booking_hours':
                  advanceHours != null && i < advanceHours.length
                      ? advanceHours[i]
                      : 1,
              'cancellation_hours':
                  cancellationHours != null && i < cancellationHours.length
                      ? cancellationHours[i]
                      : 2,
            });
          }
        }
      }

      // Remove duplicates based on provider_id
      final uniqueProviders = <String, Map<String, dynamic>>{};
      for (var provider in providers) {
        uniqueProviders[provider['provider_id']] = provider;
      }

      return uniqueProviders.values.toList();
    } catch (e) {
      print('Error getting providers for route by name: $e');
      return [];
    }
  }

  // Get bus services with provider_names for dropdown selection
  static Future<List<Map<String, dynamic>>>
      getBusServicesWithProviderNames() async {
    try {
      print('🚌 Fetching bus services with provider_names...');

      // Test if transportation_services table exists
      try {
        await client.from('transportation_services').select('count').limit(1);
        print('✅ transportation_services table exists');
      } catch (e) {
        print('❌ transportation_services table does not exist: $e');
        print('💡 Please run the transportation system setup scripts first');
        return [];
      }

      // Get all active transportation services with provider_names
      final servicesResponse =
          await client.from('transportation_services').select('''
            id,
            name,
            price,
            departure_time,
            check_in_time,
            days_of_week,
            provider_names,
            route:service_routes(route_name, from_location, to_location)
          ''').eq('is_active', true).order('name');

      print('✅ Found ${servicesResponse.length} transportation services');

      return List<Map<String, dynamic>>.from(servicesResponse);
    } catch (e) {
      print('❌ Error getting bus services with provider_names: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get runner's vehicle type from their application
  static Future<String?> getRunnerVehicleType(String runnerId) async {
    try {
      final response = await client
          .from('runner_applications')
          .select('vehicle_type')
          .eq('user_id', runnerId)
          .eq('verification_status', 'approved')
          .single();

      return response['vehicle_type'] as String?;
    } catch (e) {
      print('Error fetching runner vehicle type: $e');
      return null;
    }
  }

  // Notify runners of new transportation booking
  static Future<void> _notifyRunnersOfNewTransportationBooking(
      Map<String, dynamic> booking) async {
    try {
      print(
          '🔔 Notifying runners of new transportation booking: ${booking['id']}');

      // Get booking details
      final vehicleTypeId = booking['vehicle_type_id'];
      final pickupLocation = booking['pickup_location'];
      final dropoffLocation = booking['dropoff_location'];
      final passengerCount = booking['passenger_count'];

      // Get vehicle type name
      String vehicleTypeName = 'Vehicle';
      if (vehicleTypeId != null) {
        try {
          final vehicleResponse = await client
              .from('vehicle_types')
              .select('name')
              .eq('id', vehicleTypeId)
              .single();
          vehicleTypeName = vehicleResponse['name'] ?? 'Vehicle';
        } catch (e) {
          print('Error fetching vehicle type name: $e');
        }
      }

      // Get all runners with matching vehicle type (case insensitive)
      final runnersResponse = await client
          .from('runner_applications')
          .select('user_id')
          .ilike('vehicle_type', vehicleTypeName) // Case insensitive matching
          .eq('verification_status', 'approved');

      final runners = List<Map<String, dynamic>>.from(runnersResponse);
      print(
          '🎯 Found ${runners.length} runners with vehicle type: $vehicleTypeName');

      // Send notifications to each runner
      for (final runner in runners) {
        final runnerId = runner['user_id'];
        if (runnerId != null) {
          // Create a notification record in the database
          await client.from('notifications').insert({
            'user_id': runnerId,
            'title': 'New Ride Request',
            'message':
                '$vehicleTypeName needed: $pickupLocation to $dropoffLocation ($passengerCount passengers)',
            'type': 'transportation_request',
            'booking_id': booking['id'],
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });

          print('📱 Notification sent to runner: $runnerId');
        }
      }
    } catch (e) {
      print('❌ Error notifying runners: $e');
    }
  }

  // ============= NOTIFICATION MANAGEMENT =============

  // Get user's notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications(
      String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await client.from('notifications').update({
        'is_read': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for a user
  static Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      await client.from('notifications').update({
        'is_read': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get unread notification count for a user
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error fetching unread notification count: $e');
      return 0;
    }
  }

  // Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await client.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Helper method to notify customer that admin accepted their bus booking
  static Future<void> _notifyCustomerBusBookingAcceptedByAdmin(
      String customerId, String adminId, String serviceName) async {
    try {
      print(
          '📱 Notifying customer $customerId that admin $adminId accepted bus booking: $serviceName');

      // Only notify if current user is the customer
      final currentUserId = SupabaseConfig.currentUser?.id;
      if (currentUserId == customerId) {
        await NotificationService.notifyCustomerBusBookingAcceptedByAdmin(
            serviceName);
      }

      // Store notification in database for customer
      await client.from('notifications').insert({
        'user_id': customerId,
        'title': 'Bus Booking Accepted',
        'message': 'Your bus booking has been accepted: $serviceName',
        'type': 'admin_bus_booking_accepted',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error notifying customer about bus booking acceptance: $e');
    }
  }

  // ============================================================================
  // PROVIDER ACCOUNTING METHODS - 33.3% Commission System
  // ============================================================================

  /// Get runner earnings summary with commission breakdown
  /// Returns summary of all runners with their earnings and commission data
  static Future<List<Map<String, dynamic>>> getRunnerEarningsSummary() async {
    try {
      print('💰 Getting runner earnings summary');

      final response = await client
          .from('runner_earnings_summary')
          .select('*')
          .order('total_revenue', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      print('✅ Loaded earnings for ${data.length} runners');
      return data;
    } catch (e) {
      print('❌ Error getting runner earnings summary: $e');
      return [];
    }
  }

  /// Get detailed bookings for a specific runner with commission breakdown
  static Future<List<Map<String, dynamic>>> getRunnerDetailedBookings(
      String runnerId) async {
    try {
      print('📋 Getting detailed bookings for runner: $runnerId');

      final response = await client.rpc('get_runner_detailed_bookings',
          params: {'p_runner_id': runnerId});

      final data = List<Map<String, dynamic>>.from(response);

      print('✅ Loaded ${data.length} bookings for runner');
      return data;
    } catch (e) {
      print('❌ Error getting runner detailed bookings: $e');
      return [];
    }
  }

  /// Get all runners (verified users)
  static Future<List<Map<String, dynamic>>> getAllRunners() async {
    try {
      print('👥 Getting all runners');

      final response = await client
          .from('users')
          .select('''
            id,
            full_name,
            email,
            phone,
            is_verified,
            has_vehicle,
            created_at,
            user_type
          ''')
          .or('user_type.eq.runner,is_verified.eq.true')
          .order('created_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      print('✅ Loaded ${data.length} runners');
      return data;
    } catch (e) {
      print('❌ Error getting all runners: $e');
      return [];
    }
  }

  /// Get company commission totals
  static Future<Map<String, dynamic>> getCompanyCommissionTotals() async {
    try {
      print('💵 Getting company commission totals');

      final summary = await getRunnerEarningsSummary();

      double totalRevenue = 0;
      double totalCommission = 0;
      double totalRunnerEarnings = 0;
      int totalBookings = 0;
      int totalRunners = summary.length;

      for (var runner in summary) {
        totalRevenue += (runner['total_revenue'] as num?)?.toDouble() ?? 0;
        totalCommission +=
            (runner['total_company_commission'] as num?)?.toDouble() ?? 0;
        totalRunnerEarnings +=
            (runner['total_runner_earnings'] as num?)?.toDouble() ?? 0;
        totalBookings += (runner['total_bookings'] as int?) ?? 0;
      }

      return {
        'total_revenue': totalRevenue,
        'total_commission': totalCommission,
        'total_runner_earnings': totalRunnerEarnings,
        'total_bookings': totalBookings,
        'total_runners': totalRunners,
        'commission_rate': 33.33,
        'runner_rate': 66.67,
      };
    } catch (e) {
      print('❌ Error getting company commission totals: $e');
      return {
        'total_revenue': 0.0,
        'total_commission': 0.0,
        'total_runner_earnings': 0.0,
        'total_bookings': 0,
        'total_runners': 0,
        'commission_rate': 33.33,
        'runner_rate': 66.67,
      };
    }
  }

  /// Calculate commission breakdown for an amount
  static Map<String, double> calculateCommission(double amount,
      {double rate = 33.33}) {
    final commission = (amount * (rate / 100));
    final earnings = amount - commission;

    return {
      'total_amount': amount,
      'company_commission': double.parse(commission.toStringAsFixed(2)),
      'runner_earnings': double.parse(earnings.toStringAsFixed(2)),
      'commission_rate': rate,
    };
  }

  // ============================================================================
  // ADMIN MESSAGING TO RUNNERS
  // ============================================================================

  /// Send message from admin to a specific runner
  static Future<String?> sendMessageToRunner({
    required String runnerId,
    required String subject,
    required String message,
    String messageType = 'general',
    String priority = 'normal',
    bool allowReply = true,
  }) async {
    try {
      print('📨 Sending message to runner: $runnerId');

      final response = await client.rpc('send_admin_message_to_runner', params: {
        'p_recipient_id': runnerId,
        'p_subject': subject,
        'p_message': message,
        'p_message_type': messageType,
        'p_priority': priority,
        'p_allow_reply': allowReply,
      });

      print('✅ Message sent successfully. ID: $response');
      return response.toString();
    } catch (e) {
      print('❌ Error sending message to runner: $e');
      rethrow;
    }
  }

  /// Broadcast message to all runners
  static Future<int> broadcastMessageToAllRunners({
    required String subject,
    required String message,
    String messageType = 'announcement',
    String priority = 'normal',
    bool allowReply = true,
  }) async {
    try {
      print('📢 Broadcasting message to all runners');

      final response =
          await client.rpc('broadcast_admin_message_to_all_runners', params: {
        'p_subject': subject,
        'p_message': message,
        'p_message_type': messageType,
        'p_priority': priority,
        'p_allow_reply': allowReply,
      });

      final count = response as int;
      print('✅ Message broadcast to $count runners');
      return count;
    } catch (e) {
      print('❌ Error broadcasting message: $e');
      rethrow;
    }
  }

  /// Get all admin messages (for admin view)
  static Future<List<Map<String, dynamic>>> getAdminMessages() async {
    try {
      print('📨 Fetching admin messages...');
      print('📨 Current user: ${currentUser?.id}');
      
      final response = await client
          .from('admin_messages')
          .select('''
            *,
            sender:users!admin_messages_sender_id_fkey(full_name, email),
            recipient:users!admin_messages_recipient_id_fkey(full_name, email)
          ''')
          .order('created_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);
      print('✅ Got ${data.length} admin messages');
      
      return data;
    } catch (e) {
      print('❌ Error getting admin messages: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  /// Get messages for current runner (only root messages, not replies)
  static Future<List<Map<String, dynamic>>> getRunnerMessages() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      print('📨 Fetching messages for runner: $userId');

      // Query for messages - works with both old and new structure
      final response = await client
          .from('admin_messages')
          .select('''
            *,
            sender:users!admin_messages_sender_id_fkey(full_name, email)
          ''')
          .or('recipient_id.eq.$userId,and(sent_to_all_runners.eq.true,recipient_id.is.null)')
          .order('created_at', ascending: false);

      print('✅ Got ${response.length} messages');

      // Filter out replies if parent_message_id column exists
      final messages = List<Map<String, dynamic>>.from(response);
      final filtered = messages.where((msg) {
        // If parent_message_id exists and is not null, it's a reply - filter it out
        if (msg.containsKey('parent_message_id') && msg['parent_message_id'] != null) {
          return false;
        }
        return true;
      }).toList();

      print('✅ After filtering replies: ${filtered.length} root messages');

      // Remove duplicates for broadcast messages (group by subject + message content)
      final uniqueMessages = <String, Map<String, dynamic>>{};
      for (final msg in filtered) {
        final isBroadcast = msg['sent_to_all_runners'] == true;
        if (isBroadcast) {
          // For broadcasts, use subject+message as key to deduplicate
          final key = '${msg['subject']}_${msg['message']}';
          if (!uniqueMessages.containsKey(key)) {
            uniqueMessages[key] = msg;
          }
        } else {
          // For individual messages, use ID as key
          uniqueMessages[msg['id']] = msg;
        }
      }

      final result = uniqueMessages.values.toList();
      print('✅ After deduplication: ${result.length} unique messages');

      return result;
    } catch (e) {
      print('❌ Error getting runner messages: $e');
      return [];
    }
  }

  /// Get message thread (conversation)
  static Future<List<Map<String, dynamic>>> getMessageThread(String messageId) async {
    try {
      print('📨 Getting message thread for: $messageId');
      
      final response = await client.rpc('get_message_thread', params: {
        'p_message_id': messageId,
      });

      final messages = List<Map<String, dynamic>>.from(response);
      print('✅ Got ${messages.length} messages in thread');
      return messages;
    } catch (e) {
      print('❌ Error getting message thread: $e');
      return [];
    }
  }

  /// Send runner reply to admin message
  static Future<String?> sendRunnerReply({
    required String parentMessageId,
    required String message,
  }) async {
    try {
      print('📨 Sending runner reply to message: $parentMessageId');

      final response = await client.rpc('send_runner_reply_to_admin', params: {
        'p_parent_message_id': parentMessageId,
        'p_message': message,
      });

      print('✅ Reply sent successfully. ID: $response');
      return response.toString();
    } catch (e) {
      print('❌ Error sending runner reply: $e');
      rethrow;
    }
  }

  /// Mark admin message as read
  static Future<void> markAdminMessageAsRead(String messageId) async {
    try {
      await client.rpc('mark_admin_message_as_read',
          params: {'p_message_id': messageId});
      print('✅ Message marked as read');
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  /// Get unread admin messages count for runner
  static Future<int> getUnreadAdminMessagesCount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return 0;

      print('📨 Counting unread messages for runner: $userId');

      final response = await client
          .from('admin_messages')
          .select('*')
          .or('recipient_id.eq.$userId,and(sent_to_all_runners.eq.true,recipient_id.is.null)')
          .eq('is_read', false);

      final messages = response as List;
      print('✅ Got ${messages.length} unread messages (before deduplication)');

      // Filter out replies if parent_message_id column exists
      final filtered = messages.where((msg) {
        if (msg.containsKey('parent_message_id') && msg['parent_message_id'] != null) {
          return false;
        }
        return true;
      }).toList();

      // Deduplicate broadcast messages (same logic as getRunnerMessages)
      final uniqueMessages = <String, dynamic>{};
      for (final msg in filtered) {
        final isBroadcast = msg['sent_to_all_runners'] == true;
        if (isBroadcast) {
          // For broadcasts, use subject+message as key to deduplicate
          final key = '${msg['subject']}_${msg['message']}';
          if (!uniqueMessages.containsKey(key)) {
            uniqueMessages[key] = msg;
          }
        } else {
          // For individual messages, use ID as key
          uniqueMessages[msg['id']] = msg;
        }
      }

      final count = uniqueMessages.length;
      print('✅ Unique unread messages: $count');
      return count;
    } catch (e) {
      print('❌ Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Delete admin message (admin only)
  static Future<void> deleteAdminMessage(String messageId) async {
    try {
      await client.from('admin_messages').delete().eq('id', messageId);
      print('✅ Message deleted');
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SPECIAL ORDERS MANAGEMENT
  // ============================================================================

  /// Get all special orders for admin review
  /// Returns special orders with 'pending_price' or 'price_quoted' status
  static Future<List<Map<String, dynamic>>> getSpecialOrdersForAdmin() async {
    try {
      print('📦 Getting special orders for admin...');
      
      final response = await client
          .from('errands')
          .select('''
            *,
            customer:users!errands_customer_id_fkey(id, full_name, phone, email)
          ''')
          .eq('category', 'special_orders')
          .inFilter('status', ['pending_price', 'price_quoted'])
          .order('created_at', ascending: false);
      
      final orders = List<Map<String, dynamic>>.from(response);
      print('✅ Got ${orders.length} special orders');
      return orders;
    } catch (e) {
      print('❌ Error getting special orders for admin: $e');
      rethrow;
    }
  }

  /// Set price for special order (admin only)
  /// Updates order with price and changes status to 'price_quoted'
  static Future<void> setSpecialOrderPrice(
    String errandId,
    double price,
  ) async {
    try {
      print('💰 Setting price for special order: $errandId = N\$$price');
      
      await client.from('errands').update({
        'price_amount': price,
        'calculated_price': price,
        'status': 'price_quoted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
      
      print('✅ Price set successfully');
      
      // TODO: Send notification to customer about price quote
      
    } catch (e) {
      print('❌ Error setting special order price: $e');
      rethrow;
    }
  }

  /// Customer approves special order price quote
  /// Changes status to 'pending' making it available to runners
  static Future<void> approveSpecialOrderPrice(String errandId) async {
    try {
      print('✅ Customer approving special order: $errandId');
      
      await client.from('errands').update({
        'status': 'pending', // Now available to runners
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
      
      print('✅ Special order approved with status: pending');
    } catch (e) {
      print('❌ Error approving special order: $e');
      rethrow;
    }
  }

  /// Customer rejects special order price quote
  /// Changes status to 'cancelled'
  static Future<void> rejectSpecialOrderPrice(String errandId) async {
    try {
      print('❌ Customer rejecting special order: $errandId');
      
      await client.from('errands').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', errandId);
      
      print('✅ Special order rejected and cancelled');
    } catch (e) {
      print('❌ Error rejecting special order: $e');
      rethrow;
    }
  }
}
