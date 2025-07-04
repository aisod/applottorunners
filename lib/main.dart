import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/pages/auth_page.dart';
import 'package:lotto_runners/pages/home_page.dart';
import 'package:lotto_runners/pages/admin/admin_home_page.dart';
import 'package:lotto_runners/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await NotificationService.initialize();
  runApp(const LottoRunnersApp());
}

class LottoRunnersApp extends StatelessWidget {
  const LottoRunnersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotto Runners',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
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

        if (session != null) {
          // Setup real-time notifications when user is authenticated
          NotificationService.setupRealtimeSubscriptions();

          // Check if user is admin
          return FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseConfig.getCurrentUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final profile = profileSnapshot.data;
              if (profile != null && profile['user_type'] == 'admin') {
                return const AdminHomePage();
              } else {
                return const HomePage();
              }
            },
          );
        } else {
          return const AuthPage();
        }
      },
    );
  }
}
