import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
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
  TextEditingController? _nameController;

  void _initName(String name) {
    _nameController ??= TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController?.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController?.text.trim() ?? '';
    if (newName.isNotEmpty) {
      ref.read(careerProvider.notifier).setPlayerName(newName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Identity synchronized.')));
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
    final careerAsync = ref.watch(careerProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return careerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Vault Error: $err'))),
      data: (career) {
        _initName(career.playerName);
        return Scaffold(
          backgroundColor: colorScheme.surface,
          drawer: const GlobalDrawer(),
          appBar: isDesktop
              ? const TopNavBar(activeId: 'AccountScreen')
              : AppBar(
                  title: const Text('ACCOUNT & PREFERENCES'),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
          body: VectorBackground(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/app_icon.svg',
                              width: 48,
                              height: 48,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACCOUNT SETTINGS',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.primary,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MANAGE YOUR IDENTITY AND VISUAL PREFERENCES',
                                  style: TextStyle(
                                    letterSpacing: 2,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.3,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

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
      },
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
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'UPDATE IDENTITY',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
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
      crossAxisCount: ResponsiveLayout.isMobile(context) ? 2 : 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: AppThemeType.values
          .map(
            (type) => _ThemeCard(
              type: type,
              isActive: type == currentTheme,
              onTap: () => ref.read(themeProvider.notifier).setTheme(type),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDangerZone(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WIPE LOCAL DATA',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reset ELO, stats, and theme preferences.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _confirmReset(colorScheme),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('PERFORM HARD RESET'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ARE YOU SURE?'),
        content: const Text(
          'All your progress, ELO and achievements will be permanently erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(careerProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text(
              'RESET EVERYTHING',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeType type;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          children: [
            Icon(
              Icons.palette_rounded,
              color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              type.name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
                color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
