import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import '../providers/providers.dart';
import '../widgets/global_drawer.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';
import 'multi_target_screen.dart';
import 'solo_summary_screen.dart';
import 'main_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String playerExpression;
  final num? playerValue;
  final int playerPoints;

  // Triple Threat specific results
  final Map<int, String>? tripleThreatSolutions;
  final int? tripleThreatGuessed;

  const ResultsScreen({
    super.key,
    required this.playerExpression,
    required this.playerValue,
    required this.playerPoints,
    this.tripleThreatSolutions,
    this.tripleThreatGuessed,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.playerPoints > 0) {
      SoundService().playSuccess();
    } else if (widget.playerPoints == 0 && widget.playerExpression.isNotEmpty) {
      SoundService().playError();
    }
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

    final myScore = session.getPlayerScore('solo');

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
                // top gap so the scroll area's content never abuts the button
                // even when it does scroll — that read as an overlap.
                padding: const EdgeInsets.only(top: 12, bottom: 40),
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

    final String buttonText = isLastRound ? 'FINISH MATCH' : 'NEXT ROUND';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () async {
              if (isLastRound) {
                _finishMatch(context, ref);
                return;
              }
              if (match != null) {
                match.nextRound();
                final round = ref.read(roundProvider);
                if (match.currentRoundData != null) round.startRound(data: match.currentRoundData!);
              }
              if (mounted) {
                final isMultiTarget = match?.gameMode == GameMode.tripleThreat ||
                                      match?.gameMode == GameMode.doubleDanger;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => isMultiTarget ? const MultiTargetScreen() : const GameScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 0,
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
    final session = ref.read(sessionProvider);
    final match = ref.read(matchProvider).value;
    ref.read(careerProvider.notifier).recordSoloMatch(score: session.getPlayerScore('solo'), mode: match?.gameMode.name.toUpperCase() ?? 'SOLO');
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SoloSummaryScreen()));
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

    // This recap's vertical rhythm was fixed-size, totalling ~700dp. On a short
    // viewport it outgrew the parent SingleChildScrollView and got clipped right
    // where the NEXT ROUND button begins, so the button appeared to sit on top of
    // the score: play/phone (800dp) lost the bottom of 'N PTS' and microsoft
    // (720dp) lost the score entirely plus part of the RESULT pill. Scale the
    // gaps and display type down on short viewports so it always fits.
    final tight = MediaQuery.of(context).size.height < 900;
    final gap = tight ? 0.6 : 1.0;
    final bandPad = tight ? 28.0 : 48.0;
    final targetSize = tight ? 72.0 : 100.0;
    final exprSize = tight ? 56.0 : 80.0;
    final ptsSize = tight ? 64.0 : 90.0;

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('TARGET NUMBER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
      FittedBox(fit: BoxFit.scaleDown, child: Text('$target', style: theme.textTheme.displayLarge?.copyWith(fontSize: targetSize, color: colorScheme.primary, height: 1, fontWeight: FontWeight.w900))),
      SizedBox(height: 24 * gap),
      if (isExact) Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: bandPad, horizontal: 20), decoration: const BoxDecoration(color: Colors.green), child: Column(children: [
          const Text('TARGET REACHED!', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white70, fontSize: 14)),
          SizedBox(height: 24 * gap),
          FittedBox(fit: BoxFit.scaleDown, child: Text(playerExpression, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: exprSize, color: Colors.white, letterSpacing: 4))),
      ])) else ...[
        Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: bandPad, horizontal: 20), decoration: BoxDecoration(color: colorScheme.secondary), child: Column(children: [
            Text('POSSIBLE SOLUTION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 8, color: colorScheme.onSecondary.withValues(alpha: 0.5), fontSize: 14)),
            SizedBox(height: 24 * gap),
            FittedBox(fit: BoxFit.scaleDown, child: Text(solverExpression, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: exprSize, color: colorScheme.onSecondary, letterSpacing: 4))),
        ])),
        SizedBox(height: 32 * gap),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
            Text('YOUR SUBMISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10)),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(playerExpression.isEmpty ? 'NO SUBMISSION' : playerExpression, style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 32))),
            SizedBox(height: 20 * gap),
            Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), decoration: BoxDecoration(color: colorScheme.onSurface, borderRadius: BorderRadius.circular(20)), child: Text('RESULT: $playerValue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white))),
        ])),
      ],
      SizedBox(height: 48 * gap),
      FittedBox(fit: BoxFit.scaleDown, child: Column(children: [
          Text('$playerPoints PTS', style: TextStyle(fontSize: ptsSize, fontWeight: FontWeight.w900, color: playerPoints > 0 ? Colors.amber : Colors.grey.withValues(alpha: 0.5), letterSpacing: -2, height: 1)),
          const SizedBox(height: 4),
          Text('EARNED THIS ROUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 6, fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.3))),
      ])),
    ]);
  }
}
