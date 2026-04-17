import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_providers.dart'; // To reuse sharedPreferencesProvider
import 'app_theme.dart';

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<AppThemeType> {
  static const _themeKey = 'kalkra_theme';

  @override
  AppThemeType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    
    if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
      return AppThemeType.values[themeIndex];
    }
    return AppThemeType.vectorPop;
  }

  void setTheme(AppThemeType type) {
    state = type;
    ref.read(sharedPreferencesProvider).setInt(_themeKey, type.index);
  }
}
