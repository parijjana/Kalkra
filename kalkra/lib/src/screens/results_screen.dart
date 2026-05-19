import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/providers.dart';
import '../widgets/global_drawer.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';
import 'multi_target_screen.dart';
import 'match_summary_screen.dart';
import 'solo_summary_screen.dart';
import 'main_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String playerExpression;
  final num? playerValue;
  final int playerPoints;
  final Map<String, dynamic>? multiplayerResults;
  final Map<int, int>? teamPoints;
  final Map<int, int>? teamTotalScores;
  final Map<String, int>? eloShifts;

  // Triple Threat specific results
  final Map<int, String>? tripleThreatSolutions;
  final int? tripleThreatGuessed;

  const ResultsScreen({
    super.key,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    this.multiplayerResults,
    this.teamPoints,
    this.teamTotalScores,
    this.eloShifts,
    this.tripleThreatSolutions,
    this.tripleThreatGuessed,
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

    if (widget.playerPoints > 0) {
      SoundService().playSuccess();
    } else if (widget.playerPoints == 0 && widget.playerExpression.isNotEmpty) {
      SoundService().playError();
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
      SoundService().ensureMusicPlaying();
    });

    ref.watch(sessionUpdateProvider);
    ref.listen<MatchStatus>(matchStatusProvider, (prev, next) {
      if (next == MatchStatus.playing) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameScreen()),
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
    final myScore = session.getPlayerScore(transport.myId);

    final bool isTripleThreat = widget.tripleThreatSolutions != null;

    return Scaffold(
      drawer: const GlobalDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(matchProvider).value = null;
              ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.lobby);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
            tooltip: 'Exit Arena',
          ),
          const SizedBox(width: 8),
        ],
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                match != null ? 'ROUND ${match.currentRound}/${match.totalRounds}' : 'SOLO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              Text(
                'TOTAL: $myScore',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
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
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        if (widget.multiplayerResults != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: _buildIndividualBreakdown(context),
                            ),
                          const SizedBox(height: 32),
                        ],
                        if (isTripleThreat) 
                          _TripleThreatRecap(
                            solutions: widget.tripleThreatSolutions!,
                            guessedValue: widget.tripleThreatGuessed,
                            points: widget.playerPoints,
                            expression: widget.playerExpression,
                          )
                        else
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: (isLocked || (!isHost && widget.multiplayerResults != null)) ? null : () async {
              if (isLastRound) {
                _finishMatch(context, ref);
                return;
              }
              final transport = ref.read(transportProvider);
              if (transport is LanHostTransport) {
                _triggerNextRound(ref, transport, match);
              } else if (transport is NullTransport && match != null) {
                match.nextRound();
                final round = ref.read(roundProvider);
                if (match.currentRoundData != null) round.startRound(data: match.currentRoundData!);
              }
              if (mounted) {
                final isMultiTarget = match?.gameMode == GameMode.tripleThreat ||
                                      match?.gameMode == GameMode.doubleDanger;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => isMultiTarget ? MultiTargetScreen() : GameScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 0,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? colorScheme.surfaceContainerHighest : colorScheme.primary),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _finishMatch(BuildContext context, WidgetRef ref) {
    final transport = ref.read(transportProvider);
    if (transport is NullTransport) {
      final session = ref.read(sessionProvider);
      final match = ref.read(matchProvider).value;
      ref.read(careerProvider.notifier).recordSoloMatch(score: session.getPlayerScore('solo'), mode: match?.gameMode.name.toUpperCase() ?? 'SOLO');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SoloSummaryScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MatchSummaryScreen(teamTotalScores: widget.teamTotalScores ?? {}, multiplayerResults: widget.multiplayerResults)));
    }
  }

  Future<void> _triggerNextRound(WidgetRef ref, IGameTransport transport, MatchManager? match) async {
    if (match != null && !match.isMatchOver) {
      match.nextRound();
      final roundData = match.currentRoundData ?? MatchRoundData.mock();
      ref.read(roundProvider).startRound(data: roundData);
      ref.read(sessionProvider).resetRoundData();
      await transport.sendEvent(GameEvent(type: GameEventType.roundStarted, payload: {
        'target': roundData.targets.first, 'targets': roundData.targets, 'numbers': roundData.numbers,
        'difficulty': 1, 'jeopardy': roundData.jeopardy?.index, 'lockedOperator': roundData.lockedOperator,
        'totalRounds': match.totalRounds, 'gameMode': match.gameMode.index, 'currentRound': match.currentRound, 'config': roundData.config.title,
      }));
    }
  }

  Widget _buildTeamLeaderboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(sessionProvider);
    final activeTeams = [1, 2, 3, 4].where((tId) => session.players.values.any((p) => p.teamId == tId)).toList()
      ..sort((a, b) => (widget.teamTotalScores?[b] ?? 0).compareTo(widget.teamTotalScores?[a] ?? 0));

    if (activeTeams.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(32), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05))),
      child: Column(children: [
        Text('TEAM STANDINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10, color: colorScheme.primary.withValues(alpha: 0.5))),
        const SizedBox(height: 24),
        ...activeTeams.map((tId) {
          final color = [Colors.blue, Colors.orange, Colors.purple, Colors.teal][tId - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Row(children: [
              CircleAvatar(backgroundColor: color, radius: 14, child: Text('$tId', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(child: Text('TEAM $tId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${widget.teamTotalScores?[tId] ?? 0} TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: colorScheme.onSurface)),
                if ((widget.teamPoints?[tId] ?? 0) > 0) Text('+${widget.teamPoints?[tId]} ROUND', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildIndividualBreakdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(children: widget.multiplayerResults!.entries.map((entry) {
      final data = entry.value; final teamId = data['teamId'] as int;
      final color = teamId > 0 ? [Colors.blue, Colors.orange, Colors.purple, Colors.teal][teamId - 1] : Colors.grey;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          CircleAvatar(radius: 12, backgroundColor: color.withValues(alpha: 0.1), child: Text(data['name'][0].toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(data['expression'].isEmpty ? 'NO SUBMISSION' : '${data['expression']} = ${data['value']}', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          ])),
          if (data['proximity'] != null) Text('PROX: ${data['proximity']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      );
    }).toList());
  }
}

class _TripleThreatRecap extends StatelessWidget {
  final Map<int, String> solutions;
  final int? guessedValue;
  final int points;
  final String expression;

  const _TripleThreatRecap({
    required this.solutions,
    required this.guessedValue,
    required this.points,
    required this.expression,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ranked = solutions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Text(
          points > 0 ? 'MISSION ACCOMPLISHED' : 'MISSION FAILED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 12,
            color: points > 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '+$points PTS',
          style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: colorScheme.primary),
        ),
        const SizedBox(height: 32),
        const Text(
          'ACHIEVABLE VECTORS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...ranked.map((t) {
          final bool isGuessed = t == guessedValue;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isGuessed ? Colors.green.withValues(alpha: 0.1) : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: isGuessed ? Border.all(color: Colors.green) : null,
            ),
            child: Row(
              children: [
                Text('$t', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    solutions[t] ?? '???',
                    style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _HeroRecap extends StatelessWidget {
  final int target; final String playerExpression; final num playerValue; final int playerPoints; final String solverExpression;
  const _HeroRecap({required this.target, required this.playerExpression, required this.playerValue, required this.playerPoints, required this.solverExpression});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme; final isExact = playerValue == target;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('TARGET NUMBER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
      FittedBox(fit: BoxFit.scaleDown, child: Text('$target', style: theme.textTheme.displayLarge?.copyWith(fontSize: 100, color: colorScheme.primary, height: 1, fontWeight: FontWeight.w900))),
      const SizedBox(height: 24),
      if (isExact) Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20), decoration: const BoxDecoration(color: Colors.green), child: Column(children: [
          const Text('TARGET REACHED!', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          FittedBox(fit: BoxFit.scaleDown, child: Text(playerExpression, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 80, color: Colors.white, letterSpacing: 4))),
      ])) else ...[
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20), decoration: BoxDecoration(color: colorScheme.secondary), child: Column(children: [
            Text('POSSIBLE SOLUTION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: colorScheme.onSecondary.withValues(alpha: 0.5), fontSize: 14)),
            const SizedBox(height: 24),
            FittedBox(fit: BoxFit.scaleDown, child: Text(solverExpression, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 80, color: colorScheme.onSecondary, letterSpacing: 4))),
        ])),
        const SizedBox(height: 32),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
            Text('YOUR SUBMISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(playerExpression.isEmpty ? 'NO SUBMISSION' : playerExpression, style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 32))),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), decoration: BoxDecoration(color: colorScheme.onSurface, borderRadius: BorderRadius.circular(20)), child: Text('RESULT: $playerValue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white))),
        ])),
      ],
      const SizedBox(height: 48),
      FittedBox(fit: BoxFit.scaleDown, child: Column(children: [
          Text('$playerPoints PTS', style: TextStyle(fontSize: 90, fontWeight: FontWeight.w900, color: playerPoints > 0 ? Colors.amber : Colors.grey.withValues(alpha: 0.5), letterSpacing: -2, height: 1)),
          const SizedBox(height: 4),
          Text('EARNED THIS ROUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.3))),
      ])),
    ]);
  }
}
