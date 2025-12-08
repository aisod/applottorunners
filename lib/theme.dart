import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Lotto Runners App Color Palette
class LottoRunnersColors {
  // Primary Blue (Brand)
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue 500
  static const Color primaryBlueDark = Color(0xFF1D4ED8); // Blue 700
  static const Color lightBlue = Color(0xFFE0F2FE); // Blue 50

  // Secondary/Accent Colors - Updated to match the service cards
  static const Color primaryPurple =
      Color(0xFF8B5CF6); // Purple for grocery shopping
  static const Color accent = Color(0xFF10B981); // Green for package delivery
  static const Color orange =
      Color(0xFFF59E0B); // Orange/amber for food delivery
  static const Color teal = Color(0xFF14B8A6); // Teal for document delivery

  // Service-specific colors
  static const Color shuttleBlue = Color(0xFF3B82F6); // Shuttle service blue
  static const Color contractGreen =
      Color(0xFF10B981); // Contract service green
  static const Color busOrange = Color(0xFFF59E0B); // Bus service orange

  // Additional accent colors for better theme variety
  static const Color lightPurple = Color(0xFFA78BFA); // Lighter purple variant
  static const Color darkPurple = Color(0xFF7C3AED); // Darker purple variant

  // Additional colors for admin cards and UI elements
  static const Color green =
      Color(0xFF10B981); // Green for success/positive actions
  static const Color purple =
      Color(0xFF8B5CF6); // Purple for creative/innovative features
  static const Color indigo =
      Color(0xFF6366F1); // Indigo for professional/trust features

  // Gray Scale - Updated for better contrast
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Yellow token for accents
  static const Color primaryYellow = Color(0xFFF59E0B); // Amber 600
}

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      // Add smooth page transitions globally
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: LottoRunnersColors.primaryBlue,
        primaryContainer: LottoRunnersColors.primaryBlueDark,
        secondary: LottoRunnersColors.primaryPurple,
        secondaryContainer: LottoRunnersColors.lightPurple,
        tertiary: LottoRunnersColors.accent,
        surface: LottoRunnersColors.gray50,
        surfaceContainerHighest: LottoRunnersColors.gray100,
        error: Color(0xFFDC2626), // Red that matches website style
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: LottoRunnersColors.gray900,
        onError: Colors.white,
        outline: LottoRunnersColors.gray300,
        outlineVariant: LottoRunnersColors.gray200,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: LottoRunnersColors.gray50,
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: LottoRunnersColors.gray900,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: LottoRunnersColors.primaryYellow),
        actionsIconTheme:
            IconThemeData(color: LottoRunnersColors.primaryYellow),
      ),
      iconTheme: const IconThemeData(color: LottoRunnersColors.primaryYellow),
      listTileTheme:
          const ListTileThemeData(iconColor: LottoRunnersColors.primaryYellow),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LottoRunnersColors.primaryBlue,
          side: const BorderSide(
              color: LottoRunnersColors.primaryBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LottoRunnersColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: LottoRunnersColors.primaryBlue, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: LottoRunnersColors.gray300, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 1.2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        floatingLabelStyle: TextStyle(color: LottoRunnersColors.primaryBlue),
        iconColor: LottoRunnersColors.primaryYellow,
        prefixIconColor: LottoRunnersColors.primaryYellow,
        suffixIconColor: LottoRunnersColors.primaryYellow,
      ),
      chipTheme: const ChipThemeData(
        selectedColor: LottoRunnersColors.primaryBlue,
        secondarySelectedColor: LottoRunnersColors.primaryBlue,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        checkmarkColor: Colors.white,
        disabledColor: LottoRunnersColors.gray200,
        backgroundColor: Colors.white,
        side: BorderSide(color: LottoRunnersColors.gray300),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: StadiumBorder(),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LottoRunnersColors.primaryYellow,
        foregroundColor: LottoRunnersColors.primaryBlue,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: LottoRunnersColors.primaryYellow,
        unselectedItemColor: LottoRunnersColors.gray400,
        selectedIconTheme:
            IconThemeData(color: LottoRunnersColors.primaryYellow),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: LottoRunnersColors.primaryBlue,
        unselectedLabelColor: LottoRunnersColors.gray600,
        indicatorColor: LottoRunnersColors.primaryBlue,
      ),
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
      // Add smooth page transitions globally
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
        primary: LottoRunnersColors.primaryBlue,
        primaryContainer: LottoRunnersColors.primaryBlueDark,
        secondary: LottoRunnersColors.primaryPurple,
        secondaryContainer: LottoRunnersColors.lightPurple,
        tertiary: LottoRunnersColors.accent,
        surface: LottoRunnersColors.gray900,
        surfaceContainerHighest: LottoRunnersColors.gray800,
        error: Color(0xFFEF4444), // Lighter red for dark mode
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: LottoRunnersColors.gray100,
        onError: Colors.white,
        outline: LottoRunnersColors.gray600,
        outlineVariant: LottoRunnersColors.gray700,
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LottoRunnersColors.gray900,
      cardColor: LottoRunnersColors.gray800,
      appBarTheme: const AppBarTheme(
        backgroundColor: LottoRunnersColors.gray800,
        foregroundColor: LottoRunnersColors.gray100,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: LottoRunnersColors.primaryYellow),
        actionsIconTheme:
            IconThemeData(color: LottoRunnersColors.primaryYellow),
      ),
      iconTheme: const IconThemeData(color: LottoRunnersColors.primaryYellow),
      listTileTheme:
          const ListTileThemeData(iconColor: LottoRunnersColors.primaryYellow),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LottoRunnersColors.primaryBlue,
          side: const BorderSide(
              color: LottoRunnersColors.primaryBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LottoRunnersColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: LottoRunnersColors.primaryBlue, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: LottoRunnersColors.gray600, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        floatingLabelStyle: TextStyle(color: LottoRunnersColors.primaryBlue),
        iconColor: LottoRunnersColors.primaryYellow,
        prefixIconColor: LottoRunnersColors.primaryYellow,
        suffixIconColor: LottoRunnersColors.primaryYellow,
      ),
      chipTheme: const ChipThemeData(
        selectedColor: LottoRunnersColors.primaryBlue,
        secondarySelectedColor: LottoRunnersColors.primaryBlue,
        labelStyle: TextStyle(color: Colors.white),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        checkmarkColor: Colors.white,
        disabledColor: LottoRunnersColors.gray700,
        backgroundColor: LottoRunnersColors.gray800,
        side: BorderSide(color: LottoRunnersColors.gray700),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: StadiumBorder(),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LottoRunnersColors.primaryYellow,
        foregroundColor: LottoRunnersColors.primaryBlue,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: LottoRunnersColors.primaryYellow,
        unselectedItemColor: LottoRunnersColors.gray400,
        selectedIconTheme:
            IconThemeData(color: LottoRunnersColors.primaryYellow),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: LottoRunnersColors.primaryBlue,
        unselectedLabelColor: LottoRunnersColors.gray300,
        indicatorColor: LottoRunnersColors.primaryBlue,
      ),
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
