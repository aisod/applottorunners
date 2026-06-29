import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';

/// Consistent loading UI with optional message for accessibility and clarity.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(24),
    this.showLogo = false,
    this.compact = false,
  });

  final String? message;
  final EdgeInsetsGeometry padding;
  final bool showLogo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message;
    final indicatorSize = compact ? 28.0 : 36.0;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'web/icons/logolotto.png',
                  width: compact ? 48 : 72,
                  height: compact ? 48 : 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.directions_run,
                    size: compact ? 48 : 72,
                    color: LottoRunnersColors.primaryBlue,
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
            ],
            Semantics(
              label: 'Loading',
              child: SizedBox(
                width: indicatorSize,
                height: indicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: compact ? 2.5 : 3,
                  color: LottoRunnersColors.primaryBlue,
                ),
              ),
            ),
            if (text != null) ...[
              SizedBox(height: compact ? 12 : 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
