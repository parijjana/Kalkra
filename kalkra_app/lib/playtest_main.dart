import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/providers/game_providers.dart';
import 'src/screens/playtest_login_screen.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PlaytestApp(),
    ),
  );
}

class PlaytestApp extends ConsumerWidget {
  const PlaytestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force a specific theme for playtesting to ensure visual consistency
    final theme = AppTheme.getTheme(AppThemeType.pastel);

    return MaterialApp(
      title: 'KALKRA PLAYTEST',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const PlaytestLoginScreen(),
      builder: (context, child) {
        // Global overlay or constraints if needed for web
        return SelectionArea(
          child: child!,
        );
      },
    );
  }
}
