import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final theme = Theme.of(context);

        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            size: size ?? 24,
            color: foregroundColor ?? theme.colorScheme.onSurface,
          ),
          tooltip: 'Toggle theme',
          onSelected: (ThemeMode mode) {
            themeProvider.setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  const Icon(
                    Icons.light_mode,
                    color: LottoRunnersColors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Light',
                    style: TextStyle(
                      color: themeProvider.themeMode == ThemeMode.light
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: themeProvider.themeMode == ThemeMode.light
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  const Icon(
                    Icons.dark_mode,
                    color: LottoRunnersColors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dark',
                    style: TextStyle(
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: themeProvider.themeMode == ThemeMode.dark
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_suggest,
                    color: LottoRunnersColors.gray600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'System',
                    style: TextStyle(
                      color: themeProvider.themeMode == ThemeMode.system
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: themeProvider.themeMode == ThemeMode.system
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: showLabel
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        size: 20,
                        color: foregroundColor ?? theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        themeProvider.getThemeModeName(),
                        style: TextStyle(
                          color: foregroundColor ?? theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: foregroundColor ?? theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
