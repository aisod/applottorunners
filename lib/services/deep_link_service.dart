import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/navigation_service.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // Flag to track if user came from password reset
  static bool _isPasswordResetFlow = false;

  /// Handle incoming deep links for authentication
  static Future<void> handleDeepLink(String link) async {
    print('🔗 Handling deep link: $link');

    try {
      // Parse the URL to extract the fragment/query parameters
      final uri = Uri.parse(link);

      // Handle email confirmation
      if (link.contains('confirm-email')) {
        await _handleEmailConfirmation(uri);
      }
      // Handle password reset
      else if (link.contains('reset-password')) {
        await _handlePasswordReset(uri);
      } else {
        print('⚠️ Unknown deep link type: $link');
      }
    } catch (e) {
      print('❌ Error handling deep link: $e');
    }
  }

  /// Handle email confirmation deep link
  static Future<void> _handleEmailConfirmation(Uri uri) async {
    print('📧 Handling email confirmation');

    try {
      // Extract the access token from the URL
      final accessToken = uri.fragment.contains('access_token=')
          ? uri.fragment.split('access_token=')[1].split('&')[0]
          : null;

      if (accessToken != null) {
        // Recover the session using the access token from the deep link
        await SupabaseConfig.client.auth.recoverSession(accessToken);

        print('✅ Email confirmation successful');

        // Show success message
        _showSuccessMessage(
            'Email verified successfully! You can now sign in.');
      } else {
        print('❌ Missing tokens in email confirmation link');
        _showErrorMessage('Invalid email confirmation link');
      }
    } catch (e) {
      print('❌ Error confirming email: $e');
      _showErrorMessage('Failed to confirm email. Please try again.');
    }
  }

  /// Handle password reset deep link
  static Future<void> _handlePasswordReset(Uri uri) async {
    print('🔑 Handling password reset');

    try {
      // Extract the access token from the URL
      final accessToken = uri.fragment.contains('access_token=')
          ? uri.fragment.split('access_token=')[1].split('&')[0]
          : null;

      if (accessToken != null) {
        // For web apps, check if another tab is already handling this
        if (kIsWeb) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final lastResetTime = _getLastPasswordResetTime();

          // If another tab handled a password reset within the last 2 seconds, skip this one
          if (lastResetTime != null && (currentTime - lastResetTime) < 2000) {
            print(
                '🔑 Another tab is already handling password reset, skipping...');
            return;
          }

          _setLastPasswordResetTime(currentTime);
        }

        // Set flag to indicate this is a password reset flow
        _setPasswordResetFlow();

        // For web apps, we need to handle this differently to prevent auto-signin in other tabs
        if (kIsWeb) {
          // Store the access token for later use instead of immediately recovering session
          _storePasswordResetToken(accessToken);

          print('✅ Password reset token stored for web app');

          // Navigate to password reset page where user can set new password
          _navigateToPasswordReset();
        } else {
          // For mobile apps, use the normal flow
          await SupabaseConfig.client.auth.recoverSession(accessToken);
          print(
              '✅ Password reset link opened successfully - user is now signed in');
          _navigateToPasswordReset();
        }
      } else {
        print('❌ Missing tokens in password reset link');
        _showErrorMessage('Invalid password reset link');
      }
    } catch (e) {
      print('❌ Error handling password reset: $e');
      _showErrorMessage(
          'Failed to process password reset link. Please try again.');
    }
  }

  /// Navigate to password reset page
  static void _navigateToPasswordReset() {
    print('🔑 Navigating to password reset page');
    NavigationService.navigateToPasswordReset();
  }

  /// Check if user is in password reset flow
  static bool get isPasswordResetFlow {
    if (kIsWeb) {
      // For web, check both memory flag and session storage
      return _isPasswordResetFlow || _getWebPasswordResetFlag();
    }
    return _isPasswordResetFlow;
  }

  /// Clear password reset flow flag
  static void clearPasswordResetFlow() {
    _isPasswordResetFlow = false;
    if (kIsWeb) {
      _clearWebPasswordResetFlag();
    }
  }

  /// Set password reset flow flag (with web support)
  static void _setPasswordResetFlow() {
    _isPasswordResetFlow = true;
    if (kIsWeb) {
      _setWebPasswordResetFlag();
    }
  }

  /// Get password reset flag from web session storage
  static bool _getWebPasswordResetFlag() {
    try {
      // This would need to be implemented with web-specific storage
      // For now, we'll use a simpler approach
      return false;
    } catch (e) {
      print('Error getting web password reset flag: $e');
      return false;
    }
  }

  /// Set password reset flag in web session storage
  static void _setWebPasswordResetFlag() {
    try {
      // This would need to be implemented with web-specific storage
      // For now, we'll use a simpler approach
    } catch (e) {
      print('Error setting web password reset flag: $e');
    }
  }

  /// Clear password reset flag from web session storage
  static void _clearWebPasswordResetFlag() {
    try {
      // This would need to be implemented with web-specific storage
      // For now, we'll use a simpler approach
    } catch (e) {
      print('Error clearing web password reset flag: $e');
    }
  }

  /// Get last password reset time for tab coordination
  static int? _getLastPasswordResetTime() {
    try {
      if (kIsWeb) {
        // For web, we'll use a simple approach with a static variable
        // In a real implementation, you'd use localStorage or sessionStorage
        return _lastPasswordResetTime;
      }
      return null;
    } catch (e) {
      print('Error getting last password reset time: $e');
      return null;
    }
  }

  /// Set last password reset time for tab coordination
  static void _setLastPasswordResetTime(int timestamp) {
    try {
      if (kIsWeb) {
        _lastPasswordResetTime = timestamp;
        // In a real implementation, you'd store this in localStorage
      }
    } catch (e) {
      print('Error setting last password reset time: $e');
    }
  }

  // Static variable to track last password reset time (web only)
  static int? _lastPasswordResetTime;

  // Store password reset token for web apps
  static String? _storedPasswordResetToken;

  /// Store password reset token for web apps
  static void _storePasswordResetToken(String token) {
    _storedPasswordResetToken = token;
  }

  /// Get stored password reset token for web apps
  static String? getStoredPasswordResetToken() {
    return _storedPasswordResetToken;
  }

  /// Clear stored password reset token
  static void clearStoredPasswordResetToken() {
    _storedPasswordResetToken = null;
  }

  /// Show success message using a global navigator
  static void _showSuccessMessage(String message) {
    print('✅ Success: $message');
    NavigationService.showSuccessMessage(message);
  }

  /// Show error message using a global navigator
  static void _showErrorMessage(String message) {
    print('❌ Error: $message');
    NavigationService.showErrorMessage(message);
  }

  /// Initialize deep link handling
  static void initialize() {
    // Listen for incoming links when the app is already running
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      print('🔐 Auth state changed: $event');
      print('📊 Session present: ${session != null}');

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('✅ User signed in successfully');
        // Handle successful authentication
      } else if (event == AuthChangeEvent.signedOut) {
        print('👋 User signed out');
        // Handle sign out
      } else if (event == AuthChangeEvent.passwordRecovery) {
        print('🔑 Password recovery event detected!');
        print('📝 User ID: ${session?.user.id}');
        print('📧 User email: ${session?.user.email}');
        
        // Set the password reset flow flag
        _setPasswordResetFlow();
        
        // Navigate to password reset page when password recovery is triggered
        // This happens when user clicks the password reset link in their email
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToPasswordReset();
        });
      }
    });
  }
}
