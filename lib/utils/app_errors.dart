/// Maps exceptions and API errors to user-friendly messages.
class AppErrors {
  AppErrors._();

  static String message(Object error) {
    final raw = error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('PostgrestException: ', '')
        .trim();

    if (_isOfflineError(raw)) {
      return 'You appear to be offline. Check your internet connection and try again.';
    }
    if (raw.contains('EMAIL_SEND_FAILED')) {
      return 'We could not send the confirmation email. Please try again in a few minutes.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (raw.contains('Email not confirmed') ||
        raw.contains('email_not_confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (raw.contains('User already registered') ||
        raw.contains('already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (raw.contains('WEAK_PASSWORD') ||
        raw.contains('AuthWeakPasswordException') ||
        (raw.contains('weak') && raw.contains('password')) ||
        raw.contains('pwned')) {
      return 'This password is too weak. Use at least 8 characters with letters, numbers, and symbols.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Password must be at least 8 characters long.';
    }
    if (raw.contains('Unable to validate email address') ||
        raw.contains('INVALID_EMAIL') ||
        raw.contains('email_address_invalid')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('rate_limit_exceeded') || raw.contains('RATE_LIMIT')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    if (raw.contains('PAYMENT_REQUIRED')) {
      return 'Payment is required before continuing.';
    }
    if (raw.contains('RLS') ||
        raw.contains('row-level security') ||
        raw.contains('permission denied') ||
        raw.contains('42501')) {
      return 'You do not have permission to perform this action.';
    }
    if (raw.contains('JWT') || raw.contains('session')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (raw.contains('delete-account') || raw.contains('delete account')) {
      return 'Could not delete your account. Please try again or contact support.';
    }

    return raw.isNotEmpty
        ? raw
        : 'Something went wrong. Please try again.';
  }

  static bool _isOfflineError(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('network') ||
        lower.contains('network_error') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('clientexception') ||
        lower.contains('no internet');
  }

  static bool isOfflineError(Object error) => _isOfflineError(error.toString());
}
