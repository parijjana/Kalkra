import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType {
  vectorPop,
  noir,
  pastel,
  neon,
  ivory,
  midnightCyber,
  retroArcade,
}

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.vectorPop:
        return _buildTheme(
          primary: const Color(0xFF652FE7),
          primaryContainer: const Color(0xFF4527A0), // Deeper shadow purple
          secondary: const Color(0xFF9B3F00),
          secondaryContainer: const Color(0xFFFF6D00), // Action orange
          tertiary: const Color(0xFFFFD600), // Electric yellow
          tertiaryContainer: const Color(0xFFFDD400),
          background: const Color(0xFFF9F5F8),
          surface: Colors.white,
          onBackground: const Color(0xFF2F2E30),
          onSurface: const Color(0xFF2F2E30),
          onPrimary: Colors.white,
          isDark: false,
          headlineFont: GoogleFonts.spaceGrotesk,
          bodyFont: GoogleFonts.plusJakartaSansTextTheme,
          borderRadiusCard: 48,
          borderRadiusButton: 32,
        );
      case AppThemeType.noir:
        return _buildTheme(
          primary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF121214), // Midnight well
          secondary: const Color(0xFF999999),
          secondaryContainer: const Color(0xFF333333),
          tertiary: const Color(0xFF666666),
          tertiaryContainer: const Color(0xFF444444),
          background: const Color(0xFF0A0A0A),
          surface: const Color(0xFF1A1A1C), // Sunken texture
          onBackground: const Color(0xFFF5F5F5),
          onSurface: const Color(0xFFF5F5F5),
          onPrimary: Colors.black,
          isDark: true,
          headlineFont: GoogleFonts.dmSans,
          bodyFont: GoogleFonts.ibmPlexSansTextTheme,
          borderRadiusCard: 8,
          borderRadiusButton: 4,
        );
      case AppThemeType.pastel:
        return _buildTheme(
          primary: const Color(0xFFFFB7B2),
          primaryContainer: const Color(0xFFFFD1CC),
          secondary: const Color(0xFFE2F0CB),
          secondaryContainer: const Color(0xFFB5EAD7),
          tertiary: const Color(0xFFFFE4E1), // Misty Rose
          tertiaryContainer: const Color(0xFFC7F0DF),
          background: const Color(0xFFFFF5EE),
          surface: Colors.white,
          onBackground: const Color(0xFF5D5D5D),
          onSurface: const Color(0xFF5D5D5D),
          onPrimary: const Color(0xFF7B3100),
          isDark: false,
          headlineFont: GoogleFonts.nunitoSans,
          bodyFont: GoogleFonts.nunitoSansTextTheme,
          borderRadiusCard: 100,
          borderRadiusButton: 100,
        );
      case AppThemeType.neon:
        return _buildTheme(
          primary: const Color(0xFF39FF14),
          primaryContainer: const Color(0xFF0D4D00), // Deep acid green
          secondary: const Color(0xFFFF00FF),
          secondaryContainer: const Color(0xFF800080),
          tertiary: const Color(0xFF00FFFF),
          tertiaryContainer: const Color(0xFF004D4D),
          background: const Color(0xFF000000),
          surface: const Color(0xFF050505),
          onBackground: Colors.white,
          onSurface: Colors.white,
          onPrimary: Colors.black,
          isDark: true,
          headlineFont: GoogleFonts.spaceGrotesk,
          bodyFont: GoogleFonts.spaceGroteskTextTheme,
          borderRadiusCard: 16,
          borderRadiusButton: 12,
        );
      case AppThemeType.ivory:
        return _buildTheme(
          primary: const Color(0xFF5C4033),
          primaryContainer: const Color(0xFF3E2723), // Dark saddle
          secondary: const Color(0xFF8B4513),
          secondaryContainer: const Color(0xFFCD853F),
          tertiary: const Color(0xFFA0522D),
          tertiaryContainer: const Color(0xFFEEDC82), // Flax yellow
          background: const Color(0xFFFDFBF7),
          surface: const Color(0xFFFAF6E9),
          onBackground: const Color(0xFF3E2723),
          onSurface: const Color(0xFF3E2723),
          onPrimary: Colors.white,
          isDark: false,
          headlineFont: GoogleFonts.newsreader,
          bodyFont: GoogleFonts.literataTextTheme,
          borderRadiusCard: 4,
          borderRadiusButton: 2,
        );
      case AppThemeType.midnightCyber:
        return _buildTheme(
          primary: const Color(0xFF00E5FF),
          primaryContainer: const Color(0xFF00363A),
          secondary: const Color(0xFF7C4DFF),
          secondaryContainer: const Color(0xFF311B92),
          tertiary: const Color(0xFFFFE082),
          tertiaryContainer: const Color(0xFFFFB300),
          background: const Color(0xFF000B0D),
          surface: const Color(0xFF001519),
          onBackground: Colors.white,
          onSurface: Colors.white,
          onPrimary: Colors.black,
          isDark: true,
          headlineFont: GoogleFonts.spaceGrotesk,
          bodyFont: GoogleFonts.interTextTheme,
          borderRadiusCard: 24,
          borderRadiusButton: 16,
        );
      case AppThemeType.retroArcade:
        return _buildTheme(
          primary: const Color(0xFFFF0055),
          primaryContainer: const Color(0xFF4A001A),
          secondary: const Color(0xFF00FF9D),
          secondaryContainer: const Color(0xFF003D24),
          tertiary: const Color(0xFFFFFF00),
          tertiaryContainer: const Color(0xFF3D3D00),
          background: const Color(0xFF050005),
          surface: const Color(0xFF100010),
          onBackground: Colors.white,
          onSurface: Colors.white,
          onPrimary: Colors.white,
          isDark: true,
          headlineFont: GoogleFonts.spaceGrotesk,
          bodyFont: GoogleFonts.ibmPlexSansTextTheme,
          borderRadiusCard: 4,
          borderRadiusButton: 0,
        );
    }
  }

  static ThemeData _buildTheme({
    required Color primary,
    required Color primaryContainer,
    required Color secondary,
    required Color secondaryContainer,
    required Color tertiary,
    required Color tertiaryContainer,
    required Color background,
    required Color surface,
    required Color onBackground,
    required Color onSurface,
    required Color onPrimary,
    required bool isDark,
    required TextStyle Function({Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing}) headlineFont,
    required TextTheme Function([TextTheme? base]) bodyFont,
    required double borderRadiusCard,
    required double borderRadiusButton,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      tertiary: tertiary,
      tertiaryContainer: tertiaryContainer,
      surface: surface,
      onSurface: onSurface,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    final textTheme = bodyFont().apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme.copyWith(
        displayLarge: headlineFont(fontWeight: FontWeight.w900, letterSpacing: -1.5, color: onSurface),
        displayMedium: headlineFont(fontWeight: FontWeight.w900, color: onSurface),
        displaySmall: headlineFont(fontWeight: FontWeight.w800, color: onSurface),
        headlineLarge: headlineFont(fontWeight: FontWeight.w800, color: onSurface),
        headlineMedium: headlineFont(fontWeight: FontWeight.w700, color: onSurface),
        headlineSmall: headlineFont(fontWeight: FontWeight.w700, color: onSurface),
        titleLarge: headlineFont(fontWeight: FontWeight.bold, color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
          side: BorderSide(color: primary, width: 2),
          foregroundColor: primary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: IconThemeData(color: onPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusCard / 2),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}
