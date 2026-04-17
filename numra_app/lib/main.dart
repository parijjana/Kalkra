import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';
import 'src/screens/main_screen.dart';
import 'src/providers/game_providers.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_provider.dart';

void main() async {
  // 1. Setup Logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  final log = Logger('Kalkra');

  // 2. Setup Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    log.severe('FLUTTER ERROR: ${details.exception}', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  WidgetsFlutterBinding.ensureInitialized();

  // 3. Desktop Native Initialization
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 850),
      minimumSize: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Kalkra',
      titleBarStyle: TitleBarStyle.normal,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Colors.redAccent,
            child: Text(
              'DEBUG ERROR: ${details.exception.toString().split('\n').first}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        };
        return widget!;
      },
    );
  }
}
