import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../theme/theme_provider.dart';
import '../widgets/top_nav_bar.dart';

import '../widgets/global_drawer.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final career = ref.read(careerProvider);
    _nameController = TextEditingController(text: career.playerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      ref.read(careerProvider.notifier).setPlayerName(newName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity synchronized.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('AccountScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentTheme = ref.watch(themeProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop ? const TopNavBar(activeId: 'AccountScreen') : AppBar(
        title: const Text('ACCOUNT & PREFERENCES'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: VectorBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACCOUNT SETTINGS', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text('MANAGE YOUR IDENTITY AND VISUAL PREFERENCES', style: TextStyle(letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontWeight: FontWeight.w900, fontSize: 10)),
                    
                    const SizedBox(height: 48),
                    _buildSectionHeader('PLAYER IDENTITY'),
                    const SizedBox(height: 24),
                    _buildIdentityCard(colorScheme),
                    const SizedBox(height: 48),
                    _buildSectionHeader('VISUAL THEME'),
                    const SizedBox(height: 24),
                    _buildThemeGrid(colorScheme, currentTheme),
                    const SizedBox(height: 48),
                    _buildSectionHeader('DANGER ZONE'),
                    const SizedBox(height: 24),
                    _buildDangerZone(colorScheme),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        fontSize: 12,
      ),
    );
  }

  Widget _buildIdentityCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            onSubmitted: (_) => _saveName(),
            decoration: const InputDecoration(
              labelText: 'CALLSIGN',
              hintText: 'Enter your name',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveName,
              child: const Text('UPDATE IDENTITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(ColorScheme colorScheme, AppThemeType currentTheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveLayout.isDesktop(context) ? 3 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: AppThemeType.values.map((type) {
        final isSelected = currentTheme == type;
        return _ThemeCard(
          type: type,
          isSelected: isSelected,
          onTap: () => ref.read(themeProvider.notifier).setTheme(type),
        );
      }).toList(),
    );
  }

  Widget _buildDangerZone(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1), width: 2),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WIPE ALL DATA', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
                SizedBox(height: 4),
                Text('Reset ELO, stats, and theme preferences.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(careerProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Career wiped.')));
            },
            child: const Text('RESET', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({required this.type, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getTheme(type);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.2), blurRadius: 20)] : [],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorDot(color: colorScheme.primary),
                const SizedBox(width: 4),
                _ColorDot(color: colorScheme.secondary),
                const SizedBox(width: 4),
                _ColorDot(color: colorScheme.tertiary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              type.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
