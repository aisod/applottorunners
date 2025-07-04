import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Lotto Runners Website Color Palette
class LottoRunnersColors {
  // Primary Blues
  static const Color primaryBlue = Color(0xFF2563eb);
  static const Color primaryBlueDark = Color(0xFF1d4ed8);
  
  // Secondary/Accent Colors
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color accent = Color(0xFF10b981);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFf9fafb);
  static const Color gray100 = Color(0xFFf3f4f6);
  static const Color gray200 = Color(0xFFe5e7eb);
  static const Color gray300 = Color(0xFFd1d5db);
  static const Color gray400 = Color(0xFF9ca3af);
  static const Color gray600 = Color(0xFF4b5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1f2937);
  static const Color gray900 = Color(0xFF111827);
}

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: LottoRunnersColors.primaryBlue,
        primaryContainer: LottoRunnersColors.primaryBlueDark,
        secondary: LottoRunnersColors.primaryYellow,
        secondaryContainer: LottoRunnersColors.primaryYellow,
        tertiary: LottoRunnersColors.accent,
        surface: LottoRunnersColors.gray50,
        surfaceContainerHighest: LottoRunnersColors.gray100,
        error: const Color(0xFFdc2626), // Red that matches website style
        onPrimary: Colors.white,
        onSecondary: LottoRunnersColors.gray900,
        onTertiary: Colors.white,
        onSurface: LottoRunnersColors.gray900,
        onError: Colors.white,
        outline: LottoRunnersColors.gray300,
        outlineVariant: LottoRunnersColors.gray200,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: LottoRunnersColors.gray50,
      cardColor: Colors.white,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray900,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray900,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: LottoRunnersColors.gray900,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray900,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray900,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: LottoRunnersColors.gray900,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray800,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray800,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray700,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray700,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray800,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray700,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray600,
        ),
      ),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: LottoRunnersColors.primaryBlue,
        primaryContainer: LottoRunnersColors.primaryBlueDark,
        secondary: LottoRunnersColors.primaryYellow,
        secondaryContainer: LottoRunnersColors.primaryYellow,
        tertiary: LottoRunnersColors.accent,
        surface: LottoRunnersColors.gray900,
        surfaceContainerHighest: LottoRunnersColors.gray800,
        error: const Color(0xFFef4444), // Lighter red for dark mode
        onPrimary: Colors.white,
        onSecondary: LottoRunnersColors.gray900,
        onTertiary: Colors.white,
        onSurface: LottoRunnersColors.gray100,
        onError: Colors.white,
        outline: LottoRunnersColors.gray600,
        outlineVariant: LottoRunnersColors.gray700,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LottoRunnersColors.gray900,
      cardColor: LottoRunnersColors.gray800,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray100,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray100,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36.0,
          fontWeight: FontWeight.w600,
          color: LottoRunnersColors.gray100,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray100,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray100,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: LottoRunnersColors.gray100,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray200,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray200,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray300,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray300,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray400,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: LottoRunnersColors.gray400,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray200,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray300,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: LottoRunnersColors.gray400,
        ),
      ),
    );
