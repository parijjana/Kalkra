import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'CHOOSE THEME',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          _ThemeTile(
            title: 'Vector Pop',
            subtitle: 'Vibrant & bold geometric style.',
            type: AppThemeType.vectorPop,
            currentTheme: currentTheme,
          ),
          _ThemeTile(
            title: 'Noir',
            subtitle: 'Dark, stark, and high contrast.',
            type: AppThemeType.noir,
            currentTheme: currentTheme,
          ),
          _ThemeTile(
            title: 'Pastel',
            subtitle: 'Soft, rounded, and friendly.',
            type: AppThemeType.pastel,
            currentTheme: currentTheme,
          ),
          _ThemeTile(
            title: 'Neon',
            subtitle: 'Cyberpunk glow in the dark.',
            type: AppThemeType.neon,
            currentTheme: currentTheme,
          ),
          _ThemeTile(
            title: 'Ivory',
            subtitle: 'Paper-like serif elegance.',
            type: AppThemeType.ivory,
            currentTheme: currentTheme,
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  final String title;
  final String subtitle;
  final AppThemeType type;
  final AppThemeType currentTheme;

  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = type == currentTheme;
    final theme = Theme.of(context);
    final previewTheme = AppTheme.getTheme(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          ref.read(themeProvider.notifier).setTheme(type);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // Mini Theme Preview
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: previewTheme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: previewTheme.colorScheme.outline.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: previewTheme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
