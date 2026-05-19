import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/vector_background.dart';
import 'hosted_history_screen.dart';
import 'package:intl/intl.dart';

import '../widgets/global_drawer.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  void _showTooltip(BuildContext context, String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(explanation, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'GOT IT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('StatsScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final careerAsync = ref.watch(careerProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return careerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Vault Error: $err'))),
      data: (career) => Scaffold(
        backgroundColor: colorScheme.surface,
        drawer: const GlobalDrawer(),
        appBar: isDesktop
            ? const TopNavBar(activeId: 'StatsScreen', showMenu: true)
            : AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/app_icon.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'CAREER ANALYTICS',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ),
        body: VectorBackground(
          child: ResponsiveLayout(
            mobile: _buildMobile(context, theme, colorScheme, career),
            desktop: _buildDesktop(context, theme, colorScheme, career, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic career,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRankCard(colorScheme, career, theme),
          const SizedBox(height: 32),
          _buildStatsGrid(context, career),
          const SizedBox(height: 48),
          _buildHistoryHeader(context, colorScheme),
          const SizedBox(height: 16),
          _buildHistoryList(career, colorScheme),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic career,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAREER ANALYTICS',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'QUANTIFY YOUR COGNITIVE SUPREMACY',
                style: TextStyle(
                  letterSpacing: 4,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 80),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildRankCard(
                          colorScheme,
                          career,
                          theme,
                          isDesktop: true,
                        ),
                        const SizedBox(height: 40),
                        _buildStatsGrid(context, career, isDesktop: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildHistoryHeader(context, colorScheme),
                        const SizedBox(height: 24),
                        _buildHistoryList(career, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(
    ColorScheme colorScheme,
    dynamic career,
    ThemeData theme, {
    bool isDesktop = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 60 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 60 : 48),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CURRENT RANK',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: isDesktop ? 14 : 10,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${career.elo} ELO',
            style: theme.textTheme.displayLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontSize: isDesktop ? 80 : 48,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTier(career.elo),
              style: TextStyle(
                color: colorScheme.tertiaryContainer,
                fontWeight: FontWeight.w900,
                fontSize: isDesktop ? 20 : 14,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    dynamic career, {
    bool isDesktop = false,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: isDesktop ? 1.4 : 1.1,
      children: [
        _StatCard(
          title: 'SPEED',
          value: '${career.avgSpeedSeconds.toStringAsFixed(1)}s',
          icon: Icons.bolt_rounded,
          color: Colors.orange,
          onInfo: () => _showTooltip(
            context,
            'SPEED',
            'Average number of seconds from the moment numbers appear to when you hit SUBMIT.',
          ),
        ),
        _StatCard(
          title: 'ACCURACY',
          value: '±${career.avgAccuracy.toStringAsFixed(1)}',
          icon: Icons.track_changes_rounded,
          color: Colors.redAccent,
          onInfo: () => _showTooltip(
            context,
            'ACCURACY',
            'The average difference between your mathematical result and the target number. Lower is better!',
          ),
        ),
        _StatCard(
          title: 'WINS',
          value: '${career.matchesWon}',
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
          onInfo: () => _showTooltip(
            context,
            'WINS',
            'Total number of multiplayer sessions where you finished with the highest cumulative score.',
          ),
        ),
        _StatCard(
          title: 'BEST STREAK',
          value: '${career.bestStreak}',
          icon: Icons.whatshot_rounded,
          color: Colors.deepOrange,
          onInfo: () => _showTooltip(
            context,
            'BEST STREAK',
            'The highest number of consecutive rounds where you achieved an EXACT match to the target.',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          'MATCH LOGS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const HostedHistoryScreen(),
            ),
          ),
          icon: const Icon(Icons.dns_rounded, size: 14),
          label: const Text(
            'HOSTED LOGS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'LAST 50',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colorScheme.primary.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(dynamic career, ColorScheme colorScheme) {
    final history = career.rivals;
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'NO BATTLES RECORDED',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isPositive = item.eloShift > 0;
        final isNeutral = item.eloShift == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (item.wasSolo
                              ? colorScheme.primary
                              : colorScheme.secondary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.wasSolo ? Icons.person_rounded : Icons.groups_rounded,
                  color: item.wasSolo
                      ? colorScheme.primary
                      : colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd • HH:mm').format(item.date),
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? "+" : ""}${item.eloShift}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isNeutral
                          ? Colors.grey
                          : (isPositive ? Colors.green : Colors.redAccent),
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'ELO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTier(int elo) {
    if (elo < 1000) return 'BRONZE TIER';
    if (elo < 1500) return 'SILVER TIER';
    if (elo < 2000) return 'GOLD TIER';
    return 'PLATINUM TIER';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onInfo;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              IconButton(
                onPressed: onInfo,
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  size: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
