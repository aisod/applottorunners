import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lotto_runners/main.dart' as app;
import 'package:lotto_runners/services/onboarding_service.dart';

/// Play Store screenshot capture (run on Android emulator or device).
///
/// Optional login (for home/orders/profile screens):
///   flutter test integration_test/play_screenshots_test.dart -d <device_id> ^
///     --dart-define=SCREENSHOT_EMAIL=you@example.com ^
///     --dart-define=SCREENSHOT_PASSWORD=yourpassword
const _email = String.fromEnvironment('SCREENSHOT_EMAIL');
const _password = String.fromEnvironment('SCREENSHOT_PASSWORD');

/// pumpAndSettle hangs on maps, loaders, and live timers — use fixed delays.
Future<void> waitForUi(WidgetTester tester, [Duration duration = const Duration(seconds: 3)]) async {
  await tester.pump(duration);
  await tester.pump();
}

Future<void> captureScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await waitForUi(tester, const Duration(seconds: 4));
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

Future<void> skipOnboardingIfShown(WidgetTester tester) async {
  if (find.text('Skip').evaluate().isNotEmpty) {
    await tester.tap(find.text('Skip'));
    await waitForUi(tester, const Duration(seconds: 2));
  }
}

Future<bool> signInIfConfigured(WidgetTester tester) async {
  if (_email.isEmpty || _password.isEmpty) {
    return false;
  }

  if (find.text('Welcome Back').evaluate().isEmpty &&
      find.text('Sign In').evaluate().isNotEmpty) {
    await tester.tap(find.text('Sign In'));
    await waitForUi(tester);
  }

  final fields = find.byType(TextFormField);
  if (fields.evaluate().length < 2) {
    return false;
  }

  await tester.enterText(fields.at(0), _email);
  await tester.enterText(fields.at(1), _password);
  await waitForUi(tester);

  final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
  if (signInButton.evaluate().isEmpty) {
    return false;
  }

  await tester.tap(signInButton);
  await waitForUi(tester, const Duration(seconds: 10));

  return find.text('Dashboard').evaluate().isNotEmpty ||
      find.text('My Orders').evaluate().isNotEmpty;
}

Future<void> tapBottomNav(WidgetTester tester, String label) async {
  final tab = find.text(label);
  if (tab.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tab.last);
  await waitForUi(tester, const Duration(seconds: 3));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture Play Store phone screenshots',
    (tester) async {
      await OnboardingService.reset();

      app.main();
      await waitForUi(tester, const Duration(seconds: 8));

      if (find.text('Welcome to Lotto Runners').evaluate().isNotEmpty) {
        await captureScreenshot(binding, tester, '01-onboarding-welcome');
        if (find.text('Next').evaluate().isNotEmpty) {
          await tester.tap(find.text('Next'));
          await waitForUi(tester, const Duration(seconds: 2));
          await captureScreenshot(binding, tester, '02-onboarding-errands');
        }
        await skipOnboardingIfShown(tester);
        await waitForUi(tester, const Duration(seconds: 2));
      }

      await captureScreenshot(binding, tester, '03-sign-in');

      final signedIn = await signInIfConfigured(tester);
      if (!signedIn) {
        return;
      }

      await captureScreenshot(binding, tester, '04-home-dashboard');
      await tapBottomNav(tester, 'My Orders');
      await captureScreenshot(binding, tester, '05-my-orders');
      await tapBottomNav(tester, 'My History');
      await captureScreenshot(binding, tester, '06-my-history');
      await tapBottomNav(tester, 'Profile');
      await captureScreenshot(binding, tester, '07-profile');
      await tapBottomNav(tester, 'Dashboard');
      await captureScreenshot(binding, tester, '08-home-services');
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
