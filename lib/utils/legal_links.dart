import 'package:flutter/material.dart';
import 'package:lotto_runners/constants/legal_urls.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openPrivacyPolicy(BuildContext context) async {
  await _openLegalUrl(
    context,
    LegalUrls.privacyPolicyUrl,
    'privacy policy',
  );
}

Future<void> openTermsOfService(BuildContext context) async {
  await _openLegalUrl(
    context,
    LegalUrls.termsOfServiceUrl,
    'terms of service',
  );
}

Future<void> _openLegalUrl(
  BuildContext context,
  String url,
  String label,
) async {
  final uri = Uri.parse(url);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchError(context, url, label);
    }
  } catch (_) {
    if (context.mounted) _showLaunchError(context, url, label);
  }
}

void _showLaunchError(BuildContext context, String url, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Could not open $label. Visit $url'),
    ),
  );
}
