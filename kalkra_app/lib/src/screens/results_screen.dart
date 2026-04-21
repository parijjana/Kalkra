import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import 'game_screen.dart';
import '../widgets/global_drawer.dart';
import 'main_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('ResultsScreen');
    });
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.read(roundProvider);
    final solverResult = round.bestSolution;
    final match = ref.watch(matchProvider).value;
    final session = ref.watch(sessionProvider);
    final myScore = session.getPlayerScore(ref.read(transportProvider) is LanHostTransport ? 'host' : 'solo');

    return Scaffold(
      drawer: const GlobalDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.05),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Status Row (Fixed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 40, 0),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          match != null ? 'ROUND ${match.currentRound}/${match.totalRounds}' : 'SOLO',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10),
                        ),
                        Text(
                          'TOTAL SCORE: $myScore',
                          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Main Analytics Area (Viewport-Focused)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _HeroRecap(
                      target: round.target ?? 0,
                      playerExpression: playerExpression,
                      playerValue: playerValue?.toInt() ?? 0,
                      playerPoints: playerPoints,
                      solverExpression: solverResult?.expression ?? 'N/A',
                      leaderboard: multiplayerResults != null 
                        ? _buildLeaderboard(context, multiplayerResults!) 
                        : null,
                    ),
                  ),
                ),
              ),

              // 3. Navigation Row
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: _buildNavigationRow(context, colorScheme, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context, ColorScheme colorScheme, WidgetRef ref) {
    final match = ref.read(matchProvider).value;
    final isLastRound = match != null && (match.isMatchOver || (match.gameMode != GameMode.endless && match.currentRound >= match.totalRounds));
    final buttonText = isLastRound ? 'FINISH MATCH' : 'NEXT ROUND';

    return SizedBox(
      width: 350,
      height: 64,
      child: ElevatedButton(
        onPressed: (multiplayerResults != null && ref.read(transportProvider) is! LanHostTransport) 
          ? null 
          : () async {
            if (isLastRound) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
              return;
            }

            final transport = ref.read(transportProvider);
            if (transport is LanHostTransport) {
              if (match != null && !match.isMatchOver) {
                final forceJeopardy = ref.read(jeopardyOverrideProvider);
                match.nextRound(forceJeopardy: forceJeopardy);
                ref.read(jeopardyOverrideProvider.notifier).setOverride(false);

                final round = ref.read(roundProvider);
                round.startRound(
                  difficulty: match.currentDifficulty,
                  jeopardy: match.activeJeopardy,
                  lockedOp: match.lockedOperator,
                );
                ref.read(sessionProvider).resetRoundData();
                
                await transport.sendEvent(GameEvent(
                  type: GameEventType.roundStarted,
                  payload: {
                    'target': round.target,
                    'numbers': round.numbers,
                    'difficulty': match.currentDifficulty.index,
                    'jeopardy': match.activeJeopardy?.index,
                    'lockedOperator': match.lockedOperator,
                  },
                ));
              }
            } else if (transport is NullTransport) {
              if (match != null && !match.isMatchOver) {
                match.nextRound();
                final round = ref.read(roundProvider);
                round.startRound(
                  difficulty: match.currentDifficulty,
                  jeopardy: match.activeJeopardy,
                  lockedOp: match.lockedOperator,
                );
              }
            }
            
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const GameScreen()),
              );
            }
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return colorScheme.surfaceContainerHighest;
            return colorScheme.primary;
          }),
        ),
        child: Text(
          (multiplayerResults != null && ref.read(transportProvider) is! LanHostTransport) 
            ? 'WAITING FOR HOST' 
            : buttonText, 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)
        ),
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, Map<String, dynamic> results) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedEntries = results.entries.toList()
      ..sort((a, b) {
        // Primary sort: Points (Winner takes all)
        final pA = a.value['points'] as int;
        final pB = b.value['points'] as int;
        if (pA != pB) return pB.compareTo(pA);

        // Secondary sort: Proximity (lowest is better)
        final proxA = a.value['proximity'] as int? ?? 1000000;
        final proxB = b.value['proximity'] as int? ?? 1000000;
        return proxA.compareTo(proxB);
      });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ROUND CLASSIFICATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10, color: colorScheme.primary.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          ...sortedEntries.map((entry) {
            final data = entry.value;
            final eloShift = eloShifts?[entry.key];
            final points = data['points'] as int;
            final isWinner = points > 0;
            final expression = data['expression'] as String;
            final value = data['value'] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWinner ? colorScheme.primary.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: isWinner ? Border.all(color: colorScheme.primary.withValues(alpha: 0.2)) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isWinner ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    child: Text(data['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'].toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isWinner ? colorScheme.primary : colorScheme.onSurface)),
                        if (expression.isNotEmpty)
                          Text(
                            '$expression = $value',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          )
                        else
                          const Text('NO SUBMISSION', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$points PTS', style: TextStyle(fontWeight: FontWeight.w900, color: isWinner ? Colors.amber : Colors.grey, fontSize: 16)),
                      if (eloShift != null)
                        Text(
                          '${eloShift >= 0 ? "+" : ""}$eloShift ELO',
                          style: TextStyle(color: eloShift >= 0 ? Colors.green : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeroRecap extends StatelessWidget {
  final int target;
  final String playerExpression;
  final int playerValue;
  final int playerPoints;
  final String solverExpression;
  final Widget? leaderboard;

  const _HeroRecap({
    required this.target,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    required this.solverExpression,
    this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExact = playerValue == target;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leaderboard != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: leaderboard!,
          ),
          const SizedBox(height: 32),
        ],

        // 1. Target Header
        Text('TARGET NUMBER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$target', style: theme.textTheme.displayLarge?.copyWith(fontSize: 100, color: colorScheme.primary, height: 1, fontWeight: FontWeight.w900)),
        ),
        
        const SizedBox(height: 24),
        
        // 2. Strategy Card (Full Width & Massive Font)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            boxShadow: [
              BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            children: [
              Text('OPTIMAL STRATEGY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: colorScheme.onSecondary.withValues(alpha: 0.5), fontSize: 14)),
              const SizedBox(height: 24),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  solverExpression, 
                  style: TextStyle(
                    fontFamily: 'monospace', 
                    fontWeight: FontWeight.w900, 
                    fontSize: 80, 
                    color: colorScheme.onSecondary, 
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),

        // 3. User Results (Compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Text('YOUR SUBMISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(playerExpression.isEmpty ? 'NO SUBMISSION' : playerExpression, style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 32)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: isExact ? Colors.green : colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isExact) BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8)),
                  ],
                ),
                child: Text(
                  'RESULT: $playerValue',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // 4. Points Display (Vibrant & Scaled)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                '$playerPoints PTS',
                style: TextStyle(
                  fontSize: 90, 
                  fontWeight: FontWeight.w900, 
                  color: playerPoints > 0 ? Colors.amber : Colors.grey.withValues(alpha: 0.5),
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EARNED THIS ROUND',
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 6, 
                  fontSize: 10, 
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
