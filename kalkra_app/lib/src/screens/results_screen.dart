import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import '../widgets/global_drawer.dart';
import 'game_screen.dart';
import 'match_summary_screen.dart';
import 'solo_summary_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String playerExpression;
  final num? playerValue;
  final int playerPoints;
  final Map<String, dynamic>? multiplayerResults;
  final Map<int, int>? teamPoints;
  final Map<int, int>? teamTotalScores;
  final Map<String, int>? eloShifts;

  const ResultsScreen({
    super.key,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    this.multiplayerResults,
    this.teamPoints,
    this.teamTotalScores,
    this.eloShifts,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool _showIndividual = false;

  @override
  void initState() {
    super.initState();
    final transport = ref.read(transportProvider);
    final isHost = transport is LanHostTransport;
    final isHostPlaying = !ref.read(isHostOnlyProvider);

    if (isHost && isHostPlaying) {
      _lockoutSeconds = 15;
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_lockoutSeconds > 0) {
          setState(() => _lockoutSeconds--);
        } else {
          _lockoutTimer?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('ResultsScreen');
    });

    // Watch session updates
    ref.watch(sessionUpdateProvider);
    ref.listen<MatchStatus>(matchStatusProvider, (prev, next) {
      if (next == MatchStatus.playing) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GameScreen()),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.read(roundProvider);
    final solverResult = round.bestSolution;
    final match = ref.watch(matchProvider).value;
    final session = ref.watch(sessionProvider);
    
    final transport = ref.watch(transportProvider);
    final myId = transport is LanHostTransport ? 'host' : 'me';
    final myScore = session.getPlayerScore(transport is NullTransport ? 'solo' : myId);

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
              // 1. Top Status Row
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
                          'YOUR TOTAL: $myScore',
                          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Main Analytics Area
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        if (widget.multiplayerResults != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: _buildTeamLeaderboard(context),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => setState(() => _showIndividual = !_showIndividual),
                            icon: Icon(_showIndividual ? Icons.expand_less : Icons.expand_more),
                            label: Text(_showIndividual ? 'HIDE INDIVIDUALS' : 'SHOW INDIVIDUALS'),
                          ),
                          if (_showIndividual)
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                               child: _buildIndividualBreakdown(context),
                             ),
                          const SizedBox(height: 32),
                        ],
                        _HeroRecap(
                          target: round.target ?? 0,
                          playerExpression: widget.playerExpression,
                          playerValue: widget.playerValue ?? 0,
                          playerPoints: widget.playerPoints,
                          solverExpression: solverResult?.expression ?? 'N/A',
                        ),
                      ],
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
    final isHost = ref.read(transportProvider) is LanHostTransport;
    final isLocked = _lockoutSeconds > 0;
    
    String buttonText = isLastRound ? 'FINISH MATCH' : 'NEXT ROUND';
    if (isLocked) {
      buttonText = 'WAIT... ${_lockoutSeconds}s';
    } else if (!isHost && widget.multiplayerResults != null) {
      buttonText = 'WAITING FOR HOST';
    }

    return SizedBox(
      width: 350,
      height: 64,
      child: ElevatedButton(
        onPressed: (isLocked || (!isHost && widget.multiplayerResults != null)) 
          ? null 
          : () async {
            if (isLastRound) {
              if (context.mounted) {
                final transport = ref.read(transportProvider);
                if (transport is NullTransport) {
                  final session = ref.read(sessionProvider);
                  final score = session.getPlayerScore('solo');
                  final match = ref.read(matchProvider).value;
                  ref.read(careerProvider.notifier).recordSoloMatch(
                    score: score,
                    mode: match?.gameMode.name.toUpperCase() ?? 'SOLO',
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SoloSummaryScreen()),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MatchSummaryScreen(
                        teamTotalScores: widget.teamTotalScores ?? {},
                        multiplayerResults: widget.multiplayerResults,
                      ),
                    ),
                  );
                }
              }
              return;
            }

            final transport = ref.read(transportProvider);
            if (transport is LanHostTransport) {
               _triggerNextRound(ref, transport, match);
            } else if (transport is NullTransport) {
               if (match != null) {
                  match.nextRound();
                  final round = ref.read(roundProvider);
                  final nextData = match.currentRoundData;
                  if (nextData != null) {
                    round.startRound(data: nextData);
                  }
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
        child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
      ),
    );
  }

  Future<void> _triggerNextRound(WidgetRef ref, IGameTransport transport, MatchManager? match) async {
    if (match != null && !match.isMatchOver) {
      match.nextRound();
      final roundData = match.currentRoundData ?? MatchRoundData.mock();
      
      final round = ref.read(roundProvider);
      round.startRound(data: roundData);
      ref.read(sessionProvider).resetRoundData();
      
      await transport.sendEvent(GameEvent(
        type: GameEventType.roundStarted,
        payload: {
          'target': roundData.targets.first,
          'targets': roundData.targets,
          'numbers': roundData.numbers,
          'difficulty': 1, 
          'jeopardy': roundData.jeopardy?.index,
          'lockedOperator': roundData.lockedOperator,
          'totalRounds': match.totalRounds,
          'gameMode': match.gameMode.index,
          'currentRound': match.currentRound,
          'config': roundData.config.title,
        },
      ));
    }
  }

  Widget _buildTeamLeaderboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(sessionProvider);
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    
    // Only show teams that have at least one player assigned
    final activeTeams = [1, 2, 3, 4].where((tId) => 
      session.players.values.any((p) => p.teamId == tId)
    ).toList();

    final sortedTeams = activeTeams..sort((a, b) {
       final sA = widget.teamTotalScores?[a] ?? 0;
       final sB = widget.teamTotalScores?[b] ?? 0;
       return sB.compareTo(sA);
    });

    if (sortedTeams.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        children: [
          Text('TEAM STANDINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10, color: colorScheme.primary.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          ...sortedTeams.map((tId) {
            final total = widget.teamTotalScores?[tId] ?? 0;
            final roundPts = widget.teamPoints?[tId] ?? 0;
            final color = teamColors[tId - 1];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: color, radius: 14, child: Text('$tId', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(child: Text('TEAM $tId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$total TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: colorScheme.onSurface)),
                      if (roundPts > 0) Text('+$roundPts ROUND', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildIndividualBreakdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final results = widget.multiplayerResults!;
    final teamColors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal];

    return Column(
      children: results.entries.map((entry) {
        final data = entry.value;
        final teamId = data['teamId'] as int;
        final color = teamId > 0 ? teamColors[teamId - 1] : Colors.grey;
        final expr = data['expression'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: color.withValues(alpha: 0.1), child: Text(data['name'][0].toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(expr.isEmpty ? 'NO SUBMISSION' : '$expr = ${data['value']}', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              if (data['proximity'] != null) Text('PROX: ${data['proximity']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeroRecap extends StatelessWidget {
  final int target;
  final String playerExpression;
  final num playerValue;
  final int playerPoints;
  final String solverExpression;

  const _HeroRecap({
    required this.target,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    required this.solverExpression,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExact = playerValue == target;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Target Header
        Text('TARGET NUMBER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$target', style: theme.textTheme.displayLarge?.copyWith(fontSize: 100, color: colorScheme.primary, height: 1, fontWeight: FontWeight.w900)),
        ),
        
        const SizedBox(height: 24),
        
        // 2. Main Solution Card (Dynamic based on outcome)
        if (isExact)
          // Success Highlight: Player's Solution is the Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: const BoxDecoration(color: Colors.green),
            child: Column(
              children: [
                const Text('TARGET REACHED!', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(playerExpression, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 80, color: Colors.white, letterSpacing: 4)),
                ),
              ],
            ),
          )
        else ...[
          // Solver's "Possible Solution" shown as a guide
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(color: colorScheme.secondary),
            child: Column(
              children: [
                Text('POSSIBLE SOLUTION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: colorScheme.onSecondary.withValues(alpha: 0.5), fontSize: 14)),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(solverExpression, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 80, color: colorScheme.onSecondary, letterSpacing: 4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // User Results (only if not exact, to show how close they were)
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
                    color: colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('RESULT: $playerValue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 48),

        // 4. Points Display
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                '$playerPoints PTS',
                style: TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: playerPoints > 0 ? Colors.amber : Colors.grey.withValues(alpha: 0.5), letterSpacing: -2, height: 1),
              ),
              const SizedBox(height: 4),
              Text('EARNED THIS ROUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.3))),
            ],
          ),
        ),
      ],
    );
  }
}
