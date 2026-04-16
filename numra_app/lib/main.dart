import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/screens/main_screen.dart';

void main() {
  runApp(const ProviderScope(child: KalkraApp()));
}

class KalkraApp extends StatelessWidget {
  const KalkraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Vector Pop Design System Colors
    const primaryColor = Color(0xFF652FE7);
    const primaryContainer = Color(0xFFA98FFF);
    const secondaryColor = Color(0xFF9B3F00);
    const tertiaryColor = Color(0xFF6D5A00);
    const backgroundColor = Color(0xFFF9F5F8);
    const surfaceContainerLow = Color(0xFFF3F0F3);
    const surfaceContainerLowest = Color(0xFFFFFFFF);

    return MaterialApp(
      title: 'Kalkra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          onPrimary: const Color(0xFFF7F0FF),
          primaryContainer: primaryContainer,
          onPrimaryContainer: const Color(0xFF280072),
          secondary: secondaryColor,
          secondaryContainer: const Color(0xFFFFC5AA),
          onSecondaryContainer: const Color(0xFF7B3100),
          tertiary: tertiaryColor,
          tertiaryContainer: const Color(0xFFFDD400),
          surface: backgroundColor,
          onSurface: const Color(0xFF2F2E30),
          brightness: Brightness.light,
        ),
        // Dual Font System
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          displayMedium: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
          ),
          displaySmall: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32), // LG rounding (2rem approx)
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48), // XL rounding (3rem approx)
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
