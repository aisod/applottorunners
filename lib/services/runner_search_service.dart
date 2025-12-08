import 'package:flutter/material.dart';
import 'package:lotto_runners/widgets/looking_for_runner_popup.dart';

/// Service to manage the "Looking for Runner" popup for immediate errand requests
class RunnerSearchService {
  static RunnerSearchService? _instance;
  static RunnerSearchService get instance =>
      _instance ??= RunnerSearchService._();

  RunnerSearchService._();

  OverlayEntry? _currentPopup;

  /// Show the "Looking for Runner" popup
  void showLookingForRunnerPopup({
    required BuildContext context,
    required String errandId,
    required String errandTitle,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    VoidCallback? onRunnerFound,
  }) {
    // Hide any existing popup
    hidePopup();

    // Create overlay entry
    _currentPopup = OverlayEntry(
      builder: (context) => LookingForRunnerPopup(
        errandId: errandId,
        errandTitle: errandTitle,
        onRetry: () {
          hidePopup();
          onRetry?.call();
        },
        onCancel: () {
          hidePopup();
          onCancel?.call();
        },
        onRunnerFound: () {
          hidePopup();
          onRunnerFound?.call();
        },
      ),
    );

    // Insert into overlay
    Overlay.of(context).insert(_currentPopup!);

    print('🔍 Runner search popup shown for errand: $errandId');
  }

  /// Hide the current popup
  void hidePopup() {
    _currentPopup?.remove();
    _currentPopup = null;
    print('🔍 Runner search popup hidden');
  }

  /// Check if popup is currently showing
  bool get isShowing => _currentPopup != null;

  /// Dispose resources
  void dispose() {
    hidePopup();
  }
}
