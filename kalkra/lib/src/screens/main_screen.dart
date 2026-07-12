import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/global_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game_screen.dart';
import 'account_screen.dart';
import 'match_setup_screen.dart';
import 'stats_screen.dart';
import '../services/sound_service.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('MainScreen');
      SoundService().ensureMusicPlaying();
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
    final careerAsync = ref.watch(careerProvider);

    return careerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Vault Error: $err'))),
      data: (career) => Scaffold(
        backgroundColor: colorScheme.surface,
        drawer: const GlobalDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      80,
                      24,
                      isNarrow ? 40 : 60,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                          colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(56),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/app_icon.svg',
                              width: isNarrow ? 40 : 48,
                              height: isNarrow ? 40 : 48,
                            ),
                            SizedBox(width: isNarrow ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KALKRA',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontSize: isNarrow ? 36 : 44,
                                          height: 0.9,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MASTER THE NUMBERS',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      fontSize: isNarrow ? 8 : 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _PlayerBadge(career: career),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              _SectionHeader(title: 'THE ARENA'),
              const SizedBox(height: 24),
              _ModeCard(
                title: ref.watch(isPausedProvider)
                    ? 'RESUME'
                    : 'START PLAYING',
                description: ref.watch(isPausedProvider)
                    ? 'RESUME SUSPENDED SESSION'
                    : 'Hone your mental math skills.',
                icon: ref.watch(isPausedProvider)
                    ? Icons.play_arrow_rounded
                    : Icons.calculate_rounded,
                color: ref.watch(isPausedProvider)
                    ? colorScheme.tertiary
                    : colorScheme.primary,
                onTap: () {
                  SoundService().playTap();
                  if (ref.read(isPausedProvider)) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MatchSetupScreen(mode: MatchSetupMode.solo),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              _SectionHeader(title: 'NAVIGATION'),
              const SizedBox(height: 24),
              _ModeCard(
                title: 'ANALYTICS',
                description: 'View your career metrics.',
                icon: Icons.bar_chart_rounded,
                color: colorScheme.tertiary,
                onTap: () {
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StatsScreen(),
                    ),
                  );
                },
              ),
              _ModeCard(
                title: 'ACCOUNT',
                description: 'Preferences and identity.',
                icon: Icons.manage_accounts_rounded,
                color: colorScheme.primary,
                onTap: () {
                  SoundService().playTap();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
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
    final careerAsync = ref.watch(careerProvider);

    return careerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Vault Error: $err'))),
      data: (career) => Scaffold(
        backgroundColor: colorScheme.surface,
        drawer: const GlobalDrawer(),
        appBar: const TopNavBar(activeId: 'MainScreen', showMenu: true),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/app_icon.svg',
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DASHBOARD',
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ELEVATE YOUR MIND THROUGH NUMBERS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    letterSpacing: 8,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _PlayerBadge(career: career, isLarge: true),
                      ],
                    ),

                    const SizedBox(height: 100),

                    // Primary Play CTA
                    _DesktopModeCard(
                      title: 'START PLAYING',
                      desc: 'Individual missions and endless survival. Test your mental math.',
                      icon: Icons.calculate_rounded,
                      color: colorScheme.primary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MatchSetupScreen(
                            mode: MatchSetupMode.solo,
                          ),
                        ),
                      ),
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

  const _DesktopModeCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      desc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.4),
                size: 24,
              ),
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
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE SUMMARY',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LargeStat(
                label: 'AVG SPEED',
                value: '${career.avgSpeedSeconds.toStringAsFixed(1)}s',
                icon: Icons.bolt_rounded,
                color: Colors.orange,
              ),
              _LargeStat(
                label: 'ACCURACY',
                value: '±${career.avgAccuracy.toStringAsFixed(1)}',
                icon: Icons.track_changes_rounded,
                color: Colors.redAccent,
              ),
              _LargeStat(
                label: 'BEST STREAK',
                value: '${career.bestStreak}',
                icon: Icons.whatshot_rounded,
                color: Colors.deepOrange,
              ),
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
  const _LargeStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 20),
        Text(
          value,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 2,
            color: Colors.black26,
          ),
        ),
      ],
    );
  }
}

/// --- COMMON WIDGETS ---

class _PlayerBadge extends StatelessWidget {
  final dynamic career;
  final bool isLarge;
  const _PlayerBadge({required this.career, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 32 : 20,
        vertical: isLarge ? 20 : 10,
      ),
      decoration: BoxDecoration(
        color: isLarge
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(isLarge ? 32 : 24),
        border: Border.all(
          color: isLarge
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.amber,
            size: isLarge ? 32 : 20,
          ),
          SizedBox(width: isLarge ? 16 : 10),
          Flexible(
            child: Text(
              career.playerName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLarge
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isLarge ? 24 : 14,
              ),
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

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
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
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.15),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
