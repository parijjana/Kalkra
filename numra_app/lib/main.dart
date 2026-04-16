import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/main_screen.dart';
import 'src/providers/game_providers.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KalkraApp(),
    ),
  );
}

class KalkraApp extends ConsumerWidget {
  const KalkraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Kalkra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeType),
      home: const MainScreen(),
    );
  }
}
