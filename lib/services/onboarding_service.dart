import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed the first-launch onboarding.
class OnboardingService {
  OnboardingService._();

  static const String _keyComplete = 'onboarding_complete_v1';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyComplete) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyComplete, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyComplete);
  }
}
