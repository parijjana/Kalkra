import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import '../providers/game_providers.dart';
import '../widgets/vector_background.dart';
import 'game_screen.dart';
import 'match_setup_screen.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  final int totalRounds;
  final bool jeopardyEnabled;
  final GameMode gameMode;
  final Difficulty difficulty;
  final MatchSetupMode setupMode;

  const CalibrationScreen({
    super.key,
    required this.totalRounds,
    required this.jeopardyEnabled,
    required this.gameMode,
    required this.difficulty,
    required this.setupMode,
  });

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  String _statusText = 'INITIALIZING HEURISTICS...';
  final List<String> _quirkyMessages = [
    'SYNTHESIZING TARGETS...',
    'PRUNING TRIVIAL BRACKETS...',
    'CALIBRATING OPERATOR FLUX...',
    'GENERATING UNIQUE PATHWAYS...',
    'SOLVING THE UNSOLVABLE...',
    'OPTIMIZING RECURSIVE SEARCH...',
    'ELIMINATING DIVISION BY ZERO...',
    'STABILIZING ARENA VECTORS...',
    'CHECKING FERMAT\'S LAST THEOREM...',
    'ENTANGLING QUANTUM TOKENS...',
    'SCRUBBING POINTLESS MULTIPLICATIONS...',
    'DEFRAGGLING MATHEMATICAL PATHS...',
    'IGNORING MULTIPLICATION BY ONE...',
    'COLLAPSING REDUNDANT PARENTHESES...',
    'VERIFYING RECURSIVE INTEGRITY...',
  ];
  late Timer _statusTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _statusText = _quirkyMessages[_random.nextInt(_quirkyMessages.length)];
      });
    });

    _startGeneration();
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    final seed = _random.nextInt(1000000);

    // 1. Offload heavy generation to background isolate
    final matchRounds = await compute(MatchManager.generateMatchData, (
      totalRounds: widget.totalRounds,
      jeopardyEnabled: widget.jeopardyEnabled,
      gameMode: widget.gameMode,
      initialDifficulty: widget.difficulty,
      seed: seed,
      startRoundIndex: 0,
    ));

    final match = MatchManager.fromData(
      totalRounds: widget.totalRounds,
      jeopardyEnabled: widget.jeopardyEnabled,
      gameMode: widget.gameMode,
      initialDifficulty: widget.difficulty,
      rounds: matchRounds,
      seed: seed,
    );
    
    ref.read(matchProvider).value = match;
    
    final session = ref.read(sessionProvider);
    session.resetScores();
    session.resetRoundData();

    final roundData = match.currentRoundData;
    if (roundData == null) return;

    if (widget.setupMode == MatchSetupMode.solo) {
      ref.read(transportProvider.notifier).setTransport(NullTransport());
      final career = await ref.read(careerProvider.future);
      session.addPlayer('solo', career.playerName);
      
      ref.read(roundProvider).startRound(data: roundData);
    } else {
      final transport = ref.read(transportProvider);
      ref.read(roundProvider).startRound(data: roundData);
      
      await transport.sendEvent(GameEvent(type: GameEventType.roundStarted, payload: {
        'target': roundData.targets.first, 
        'targets': roundData.targets,
        'numbers': roundData.numbers, 
        'difficulty': widget.difficulty.index, 
        'jeopardy': roundData.jeopardy?.index, 
        'lockedOperator': roundData.lockedOperator,
        'config': roundData.config.title,
      }));
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const GameScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: VectorBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 12,
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 60),
              Text(
                'CALIBRATING ARENA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontSize: 12,
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
