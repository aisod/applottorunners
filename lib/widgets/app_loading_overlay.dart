import 'package:flutter/material.dart';
import 'package:lotto_runners/widgets/app_loading.dart';

/// Full-screen loading overlay for async actions (submit, delete, etc.).
class AppLoadingOverlay {
  AppLoadingOverlay._();

  static OverlayEntry? _entry;

  static void show(BuildContext context, {String? message}) {
    hide();
    _entry = OverlayEntry(
      builder: (ctx) => Material(
        color: Colors.black45,
        child: AppLoadingIndicator(message: message ?? 'Please wait…'),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
