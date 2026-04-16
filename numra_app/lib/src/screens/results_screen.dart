import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

class ResultsScreen extends ConsumerWidget {
  final String playerExpression;
  final num? playerValue;
  final int playerPoints;
  final Map<String, dynamic>? multiplayerResults;
  final Map<String, int>? eloShifts;

  const ResultsScreen({
    super.key,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    this.multiplayerResults,
    this.eloShifts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.read(roundProvider);
    final solverResult = round.bestSolution;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary, const Color(0xFF5E35B1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text(
                'ROUND OVER',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              
              if (multiplayerResults != null)
                _buildLeaderboard(context, multiplayerResults!)
              else
                _buildSoloResults(context, theme, colorScheme),
              
              const SizedBox(height: 32),
              
              // Solver Reveal (Always show)
              _ResultCard(
                title: 'OPTIMAL SOLUTION',
                content: solverResult?.expression ?? 'NO SOLUTION FOUND',
                subtitle: 'Target: ${round.target} • Solver: ${solverResult?.bestValue ?? "?"}',
                color: colorScheme.secondary.withValues(alpha: 0.8),
              ),

              const Spacer(),

              // Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('MAIN MENU', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (multiplayerResults != null && ref.read(transportProvider) is! LanHostTransport) 
                          ? null 
                          : () async {
                            final transport = ref.read(transportProvider);
                            if (transport is LanHostTransport) {
                              final match = ref.read(matchProvider).value;
                              if (match != null && !match.isMatchOver) {
                                match.nextRound();
                                final round = ref.read(roundProvider);
                                round.startRound(difficulty: match.currentDifficulty);
                                ref.read(sessionProvider).resetRoundData();
                                
                                await transport.sendEvent(GameEvent(
                                  type: GameEventType.roundStarted,
                                  payload: {
                                    'target': round.target,
                                    'numbers': round.numbers,
                                    'difficulty': match.currentDifficulty.index,
                                  },
                                ));
                              }
                            }
                            
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const GameScreen()),
                              );
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiaryContainer,
                          foregroundColor: colorScheme.onTertiaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          (multiplayerResults != null && ref.read(transportProvider) is! LanHostTransport) 
                            ? 'WAITING FOR HOST' 
                            : 'NEXT ROUND', 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoloResults(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(color: colorScheme.tertiaryContainer, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$playerPoints', style: theme.textTheme.displayLarge?.copyWith(fontSize: 64, color: colorScheme.onTertiaryContainer, height: 1)),
              Text('POINTS', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onTertiaryContainer.withValues(alpha: 0.5), fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _ResultCard(
          title: 'YOUR EXPRESSION',
          content: playerExpression.isEmpty ? 'NO SUBMISSION' : playerExpression,
          subtitle: playerValue != null ? 'Result: ${playerValue!.toInt()}' : null,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(BuildContext context, Map<String, dynamic> results) {
    // Sort players by points
    final sortedPlayers = results.entries.toList()
      ..sort((a, b) => (b.value['points'] as int).compareTo(a.value['points'] as int));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text('LEADERBOARD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...sortedPlayers.map((entry) {
            final data = entry.value;
            final eloShift = eloShifts?[entry.key];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(data['name'][0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (eloShift != null)
                          Text(
                            '${eloShift > 0 ? "+" : ""}$eloShift ELO',
                            style: TextStyle(
                              color: eloShift >= 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text('${data['points']} PTS', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String content;
  final String? subtitle;
  final Color color;

  const _ResultCard({required this.title, required this.content, this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          Text(title, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(content, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
