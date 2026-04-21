import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import 'game_screen.dart';
import 'host_screen.dart';
import 'join_screen.dart';
import 'account_screen.dart';
import 'match_setup_screen.dart';
import 'stats_screen.dart';
import 'package:transport_interface/transport_interface.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('MainScreen');
    });
    return ResponsiveLayout(
      mobile: _MainScreenMobile(),
      desktop: _MainScreenDesktop(),
    );
  }
}

/// --- MOBILE LAYOUT ---
class _MainScreenMobile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final career = ref.watch(careerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8), colorScheme.primaryContainer],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KALKRA', style: theme.textTheme.displayLarge?.copyWith(color: colorScheme.onPrimary, fontSize: 72, height: 0.9)),
                            const SizedBox(height: 8),
                            Text('MASTER THE NUMBERS', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontWeight: FontWeight.w900, letterSpacing: 3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _EloBadge(career: career),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _SectionHeader(title: 'THE ARENA'),
            const SizedBox(height: 24),
            _ModeCard(
              title: 'SOLO',
              description: ref.watch(isPausedProvider) ? 'RESUME SUSPENDED SESSION' : 'Hone your mental math skills.',
              icon: Icons.person_rounded,
              color: ref.watch(isPausedProvider) ? colorScheme.tertiary : colorScheme.primary,
              onTap: () {
                if (ref.read(isPausedProvider)) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GameScreen()));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MatchSetupScreen(mode: MatchSetupMode.solo)));
                }
              },
            ),
            _ModeCard(
              title: 'MULTIPLAYER',
              description: 'Host or join a local session.',
              icon: Icons.groups_rounded,
              color: colorScheme.secondary,
              onTap: () => _showMultiplayerDialog(context),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'NAVIGATION'),
            const SizedBox(height: 24),
            _ModeCard(
              title: 'ANALYTICS',
              description: 'View your career metrics.',
              icon: Icons.bar_chart_rounded,
              color: colorScheme.tertiary,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StatsScreen())),
            ),
            _ModeCard(
              title: 'ACCOUNT',
              description: 'Preferences and identity.',
              icon: Icons.manage_accounts_rounded,
              color: colorScheme.primary,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AccountScreen())),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

/// --- DESKTOP LAYOUT ---
class _MainScreenDesktop extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final career = ref.watch(careerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const TopNavBar(activeId: 'MainScreen', showMenu: false),
      body: VectorBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desktop Hero
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DASHBOARD', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                          const SizedBox(height: 12),
                          Text('ELEVATE YOUR MIND THROUGH NUMBERS', style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 8, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                      _EloBadge(career: career, isLarge: true),
                    ],
                  ),

                  const SizedBox(height: 100),

                  // Game Mode Grid
                  Row(
                    children: [
                      Expanded(
                        child: _DesktopModeCard(
                          title: 'SOLO',
                          desc: 'Individual missions and endless survival.',
                          icon: Icons.psychology_rounded,
                          color: colorScheme.primary,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MatchSetupScreen(mode: MatchSetupMode.solo))),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _DesktopModeCard(
                          title: 'HOST ARENA',
                          desc: 'Create a local room for friends to join via QR or IP.',
                          icon: Icons.sensors_rounded,
                          color: colorScheme.secondary,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HostScreen())),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _DesktopModeCard(
                          title: 'JOIN BATTLE',
                          desc: 'Find an active host on your LAN and prove your speed.',
                          icon: Icons.bolt_rounded,
                          color: colorScheme.tertiary,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const JoinScreen())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),

                  // Performance Quick View
                  _DesktopStatsPanel(career: career),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopModeCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DesktopModeCard({required this.title, required this.desc, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
            ],
            border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 40),
              Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(desc, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), height: 1.6, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopStatsPanel extends StatelessWidget {
  final dynamic career;
  const _DesktopStatsPanel({required this.career});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(56),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERFORMANCE SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LargeStat(label: 'AVG SPEED', value: '${career.avgSpeedSeconds.toStringAsFixed(1)}s', icon: Icons.bolt_rounded, color: Colors.orange),
              _LargeStat(label: 'ACCURACY', value: '±${career.avgAccuracy.toStringAsFixed(1)}', icon: Icons.track_changes_rounded, color: Colors.redAccent),
              _LargeStat(label: 'BEST STREAK', value: '${career.bestStreak}', icon: Icons.whatshot_rounded, color: Colors.deepOrange),
            ],
          ),
        ],
      ),
    );
  }
}

class _LargeStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _LargeStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 20),
        Text(value, style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, fontSize: 48)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.black26)),
      ],
    );
  }
}

/// --- COMMON WIDGETS ---

class _EloBadge extends StatelessWidget {
  final dynamic career;
  final bool isLarge;
  const _EloBadge({required this.career, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 32 : 20, vertical: isLarge ? 20 : 10),
      decoration: BoxDecoration(
        color: isLarge ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(isLarge ? 32 : 24),
        border: Border.all(color: isLarge ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: Colors.amber, size: isLarge ? 32 : 20),
          SizedBox(width: isLarge ? 16 : 10),
          Text(
            '${career.playerName} • ${career.elo} ELO',
            style: TextStyle(
              color: isLarge ? Theme.of(context).colorScheme.onSurface : Colors.white, 
              fontWeight: FontWeight.w900,
              fontSize: isLarge ? 24 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({required this.title, required this.description, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Material(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(40),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withValues(alpha: 0.15), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showMultiplayerDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(56)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 32),
          const Text('MULTIPLAYER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 4)),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(child: _DialogButton(label: 'HOST', icon: Icons.qr_code_rounded, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HostScreen())); })),
              const SizedBox(width: 24),
              Expanded(child: _DialogButton(label: 'JOIN', icon: Icons.sensors_rounded, onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (context) => const JoinScreen())); })),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DialogButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 40),
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        ],
      ),
    );
  }
}
