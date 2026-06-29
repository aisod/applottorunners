import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/utils/legal_links.dart';
import 'package:lotto_runners/widgets/app_loading_overlay.dart';

/// Prompts logged-in users who have not yet accepted Terms of Service.
class TermsAcceptanceDialog extends StatefulWidget {
  const TermsAcceptanceDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final profile = await SupabaseConfig.getCurrentUserProfile();
    if (!context.mounted) return;
    if (profile == null) return;
    if (profile['terms_accepted'] == true) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TermsAcceptanceDialog(),
    );
  }

  @override
  State<TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  bool _accepted = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_accepted) return;
    setState(() => _isSubmitting = true);
    AppLoadingOverlay.show(context, message: 'Saving…');
    try {
      final ok = await SupabaseConfig.acceptTermsAndConditions();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save acceptance. Please try again.'),
          ),
        );
      }
    } finally {
      AppLoadingOverlay.hide();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please review and accept our Terms of Service and Privacy Policy to continue using Lotto Runners.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => openTermsOfService(context),
                    child: const Text('Terms of Service'),
                  ),
                  TextButton(
                    onPressed: () => openPrivacyPolicy(context),
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _accepted = v ?? false),
                title: const Text('I have read and agree to the Terms of Service'),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: LottoRunnersColors.primaryBlue,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _accepted && !_isSubmitting ? _submit : null,
            child: const Text('Accept & continue'),
          ),
        ],
      ),
    );
  }
}
