import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/game_providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';

class SessionRecapScreen extends ConsumerWidget {
  const SessionRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(currentScreenIdProvider.notifier)
          .setScreenId('SessionRecapScreen');
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      appBar: isDesktop
          ? const TopNavBar(activeId: 'SessionRecapScreen')
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
                      'SESSION RECAP',
                      overflow: TextOverflow.ellipsis,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHO IS WINNING THE NIGHT?',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Session Standings
                  _buildSessionLeaderboard(colorScheme, session),

                  const SizedBox(height: 48),
                  Text(
                    'MATCH HISTORY',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Match List
                  if (session.matchHistory.isEmpty)
                    const Center(
                      child: Text(
                        'No matches played yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...session.matchHistory.reversed.map(
                      (match) => _buildMatchCard(colorScheme, match),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionLeaderboard(
    ColorScheme colorScheme,
    SessionManager session,
  ) {
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    final activeTeams =
        [1, 2, 3, 4]
            .where((tId) => session.players.values.any((p) => p.teamId == tId))
            .toList()
          ..sort(
            (a, b) => (session.sessionTeamScores[b] ?? 0).compareTo(
              session.sessionTeamScores[a] ?? 0,
            ),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: activeTeams.map((tId) {
        final score = session.sessionTeamScores[tId] ?? 0;
        final color = teamColors[tId - 1];
        final name = session.teamNames[tId] ?? 'T$tId';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchCard(ColorScheme colorScheme, MatchRecord match) {
    final dateFormat = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.amber,
            size: 32,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.winnerName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'MATCH VICTORY • ${dateFormat.format(match.date)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOP SCORE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${match.teamScores[match.winnerTeamId]}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
