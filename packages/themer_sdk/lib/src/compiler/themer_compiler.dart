import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/themer_model.dart';

/// Compiler that translates [ThemerModel] into Flutter's native [ThemeData].
class ThemerCompiler {
  static ThemeData compile(ThemerModel model) {
    final colors = model.colors;

    final colorScheme = ColorScheme(
      brightness: _estimateBrightness(colors.background),
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary ?? colors.primary,
      onSecondary: colors.onSecondary ?? colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.onSurface,
      error: colors.error ?? const Color(0xFFB00020),
      onError: colors.onError ?? Colors.white,
    );

    final double roundness = model.effects?.roundness ?? 4.0;
    final double elevation = model.effects?.elevation ?? 0.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: elevation,
        shadowColor: colors.shadow ?? Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundness),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation,
          foregroundColor: colors.onPrimary,
          backgroundColor: colors.primary,
          shadowColor: colors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundness),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colors.onSecondary ?? colors.onPrimary,
          backgroundColor: colors.secondary ?? colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundness),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundness),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.secondary?.withValues(alpha: 0.12) ?? colors.surface,
        labelStyle: TextStyle(color: colors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundness),
          side: BorderSide(color: colors.secondary?.withValues(alpha: 0.2) ?? Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundness),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundness),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        prefixIconColor: colorScheme.onSurface.withValues(alpha: 0.5),
        suffixIconColor: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      // Add typography if present
      textTheme: _compileTextTheme(model.typography, colorScheme.onSurface),
    );
  }

  static Brightness _estimateBrightness(Color color) {
    return ThemeData.estimateBrightnessForColor(color);
  }

  static TextTheme? _compileTextTheme(ThemerTypography? typography, Color textColor) {
    if (typography == null) return null;

    final String family = typography.fontFamily ?? 'Inter';
    TextStyle baseStyle;
    
    try {
      baseStyle = GoogleFonts.getFont(family, color: textColor);
    } catch (e) {
      // Fallback if font name is invalid or not in Google Fonts
      baseStyle = TextStyle(fontFamily: family, color: textColor);
    }

    return TextTheme(
      displayLarge: baseStyle.copyWith(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.0),
      headlineLarge: baseStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      bodyLarge: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.normal, height: 1.6),
      labelSmall: baseStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0),
    );
  }
}
