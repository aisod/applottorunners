import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/auth_page.dart';
import 'package:lotto_runners/pages/home_page.dart';
import 'package:lotto_runners/services/notification_service.dart';
// Removed debug floating button wrapper
import 'package:lotto_runners/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lotto_runners/services/scheduled_errand_notification_service.dart';
import 'package:lotto_runners/services/scheduled_transportation_notification_service.dart';
import 'package:lotto_runners/services/scheduled_contract_notification_service.dart';
import 'package:lotto_runners/services/scheduled_bus_notification_service.dart';
import 'package:lotto_runners/services/deep_link_service.dart';
import 'package:lotto_runners/pages/my_orders_page.dart';
import 'package:lotto_runners/pages/password_reset_page.dart';
import 'package:lotto_runners/services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService.initialize();

  // Initialize deep link service
  DeepLinkService.initialize();

  // Handle initial deep link if the app was opened from a link
  await _handleInitialDeepLink();

  runApp(const LottoRunnersApp());
}

/// Handle deep link that opened the app
Future<void> _handleInitialDeepLink() async {
  try {
    // Supabase Flutter automatically handles deep links for mobile apps
    // This ensures the auth state is properly recovered on app start
    print('🔗 Checking for initial deep link...');
    
    // The Supabase SDK will automatically handle password reset links
    // when the app is opened from an email link
  } catch (e) {
    print('❌ Error handling initial deep link: $e');
  }
}

class LottoRunnersApp extends StatelessWidget {
  const LottoRunnersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Lotto Runners',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: NavigationService.navigatorKey,
            home: const AuthWrapper(),
            routes: {
              '/my-orders': (context) => const MyOrdersPage(),
              '/password-reset': (context) => const PasswordResetPage(),
              '/auth': (context) => const AuthPage(),
            },
            // Page transitions are handled by custom routes
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Check if user has a stored password reset token (web only)
        if (kIsWeb &&
            session == null &&
            DeepLinkService.getStoredPasswordResetToken() != null) {
          // User has a password reset token but no session, show password reset page
          return const PasswordResetPage();
        }

        if (session != null) {
          // Setup real-time notifications when user is authenticated
          NotificationService.setupRealtimeSubscriptions();

          // Initialize scheduled errand notifications
          ScheduledErrandNotificationService.instance.initialize();

          // Initialize scheduled transportation notifications
          ScheduledTransportationNotificationService.instance.initialize();

          // Initialize scheduled contract notifications
          ScheduledContractNotificationService.instance.initialize();

          // Initialize scheduled bus notifications
          ScheduledBusNotificationService.instance.initialize();

          // Initialize errand acceptance notification service will be done in HomePage

          // Check if user is admin
          return FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseConfig.getCurrentUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your profile...'),
                      ],
                    ),
                  ),
                );
              }

              if (profileSnapshot.hasError) {
                print('Profile loading error: ${profileSnapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try signing in again',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await SupabaseConfig.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final profile = profileSnapshot.data;
              print('User profile: $profile'); // Debug info
              print('User type: ${profile?['user_type']}'); // Debug info

              if (profile == null) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Profile not found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please sign in again to recreate your profile',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await SupabaseConfig.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Check if user came from password reset flow
              if (DeepLinkService.isPasswordResetFlow) {
                // Clear the flag immediately to prevent other tabs from showing reset page
                DeepLinkService.clearPasswordResetFlow();

                // For web apps, add a small delay to ensure only one tab shows the reset page
                if (kIsWeb) {
                  return FutureBuilder<bool>(
                    future: Future.delayed(
                        const Duration(milliseconds: 200), () => true),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return const PasswordResetPage();
                      }
                      return const Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Preparing password reset...'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const PasswordResetPage();
              }

              // Route based on user type (not needed for conditional logic here)
              return const HomePage();
            },
          );
        } else {
          return const AuthPage();
        }
      },
    );
  }
}
