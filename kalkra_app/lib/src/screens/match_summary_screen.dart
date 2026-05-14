import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/providers.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import 'staging_screen.dart';

class MatchSummaryScreen extends ConsumerWidget {
  final Map<int, int> teamTotalScores;
  final Map<String, dynamic>? multiplayerResults;

  const MatchSummaryScreen({
    super.key,
    required this.teamTotalScores,
    this.multiplayerResults,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(currentScreenIdProvider.notifier)
          .setScreenId('MatchSummaryScreen');
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final isHost = ref.read(transportProvider) is LanHostTransport;

    final sortedTeams =
        [1, 2, 3, 4]
            .where((tId) => session.players.values.any((p) => p.teamId == tId))
            .toList()
          ..sort(
            (a, b) =>
                (teamTotalScores[b] ?? 0).compareTo(teamTotalScores[a] ?? 0),
          );

    final winnerId = sortedTeams.isNotEmpty ? sortedTeams.first : null;
    final winnerName = winnerId != null
        ? (session.teamNames[winnerId] ?? 'Team $winnerId')
        : 'Unknown';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const GlobalDrawer(),
      body: VectorBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'MATCH COMPLETE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                winnerName.toUpperCase(),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Text(
                'VICTORY',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                  color: Colors.amber,
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 48),

              // Burnup Chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _BurnupChart(
                    teamTotalScores: teamTotalScores,
                    teamNames: session.teamNames,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Final Leaderboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: sortedTeams.map((tId) {
                    final isWinner = tId == winnerId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? Colors.amber.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: isWinner
                            ? Border.all(color: Colors.amber, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${sortedTeams.indexOf(tId) + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              session.teamNames[tId]?.toUpperCase() ??
                                  'TEAM $tId',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '${teamTotalScores[tId]} PTS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: isWinner
                                  ? Colors.amber
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 48),

              // Navigation
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: 300,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isHost) {
                        // 1. Record Outcome locally
                        if (winnerId != null)
                          session.recordMatchOutcome(winnerId);
                        session.resetScores();

                        // 2. Transition State
                        ref
                            .read(matchStatusProvider.notifier)
                            .setStatus(MatchStatus.lobby);
                        ref.read(roundStartTimeProvider.notifier).setTime(null);

                        // 3. Broadcast return to lobby with FULL session history
                        ref
                            .read(transportProvider)
                            .sendEvent(
                              GameEvent(
                                type: GameEventType.matchEnded,
                                payload: {
                                  'matchHistory': session.matchHistory
                                      .map(
                                        (m) => {
                                          'date': m.date.toIso8601String(),
                                          'winnerTeamId': m.winnerTeamId,
                                          'winnerName': m.winnerName,
                                          'teamScores': m.teamScores.map(
                                            (k, v) => MapEntry(k.toString(), v),
                                          ),
                                        },
                                      )
                                      .toList(),
                                  'sessionTeamScores': session.sessionTeamScores
                                      .map((k, v) => MapEntry(k.toString(), v)),
                                },
                              ),
                            );
                      }
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const StagingScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onSurface,
                      foregroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      'RETURN TO LOBBY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurnupChart extends StatelessWidget {
  final Map<int, int> teamTotalScores;
  final Map<int, String> teamNames;

  const _BurnupChart({required this.teamTotalScores, required this.teamNames});

  @override
  Widget build(BuildContext context) {
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];

    int maxScore = 1;
    for (var s in teamTotalScores.values) {
      if (s > maxScore) maxScore = s;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: teamTotalScores.entries.map((entry) {
        final tId = entry.key;
        final score = entry.value;
        final color = teamColors[tId - 1];
        final heightFactor = (score / maxScore).clamp(0.1, 1.0);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 200 * heightFactor,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.3)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    teamNames[tId]?.toUpperCase() ?? 'T$tId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
