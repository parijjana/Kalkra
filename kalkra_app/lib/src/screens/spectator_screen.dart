import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import '../widgets/vector_background.dart';
import 'results_screen.dart';
import 'main_screen.dart';

class SpectatorScreen extends ConsumerStatefulWidget {
  const SpectatorScreen({super.key});

  @override
  ConsumerState<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends ConsumerState<SpectatorScreen> with TickerProviderStateMixin {
  late Timer _timer;
  int _secondsLeft = 60;
  bool _isRoundEnding = false;

  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _startTimer();
    _entranceController.forward();
    
    final round = ref.read(roundProvider);
    _secondsLeft = round.jeopardyType == JeopardyType.speedDemon ? 30 : 60;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
        _onTimeUp();
      }
    });
  }

  Future<void> _onTimeUp() async {
    if (_isRoundEnding) return;
    _isRoundEnding = true;
    _timer.cancel();

    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final session = ref.read(sessionProvider);
    final match = ref.read(matchProvider).value;

    round.endRound();

    if (transport is LanHostTransport) {
      // WINNER TAKES ALL SCORING LOGIC
      final target = round.target ?? 0;
      final validator = SubmissionValidator();
      
      // 1. Calculate proximity for all players
      final proximities = <String, int>{};
      final values = <String, int>{};
      
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        final expression = p.lastExpression ?? '';
        final validation = validator.validate(expression, round.numbers);
        
        if (validation.isValid && validation.value != null) {
          final val = validation.value!.toInt();
          values[id] = val;
          proximities[id] = (target - val).abs();
        } else {
          proximities[id] = 1000000; // Infinity for invalid/no submission
        }
      }

      // 2. Find minimum proximity
      int minProximity = 1000000;
      for (final prox in proximities.values) {
        if (prox < minProximity) minProximity = prox;
      }

      // 3. Award points ONLY to the closest (standard rules apply)
      final roundResults = <String, Map<String, dynamic>>{};
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        int points = 0;
        
        if (minProximity < 1000000 && proximities[id] == minProximity) {
          // Calculate standard points for this proximity
          final scoreKeeper = ScoreKeeper();
          points = scoreKeeper.calculateScore(
            target: target, 
            result: values[id],
            jeopardy: round.jeopardyType,
          );
        }
        
        session.recordSubmission(id, p.lastExpression ?? '', points);
        roundResults[id] = {
          'name': p.name, 
          'points': points, 
          'expression': p.lastExpression ?? '',
          'value': values[id] ?? 0,
          'proximity': proximities[id] == 1000000 ? null : proximities[id],
        };
      }

      // 4. Calculate ELO shifts if match is over
      Map<String, int>? eloShifts;
      bool isMatchOver = false;
      if (match != null) {
        isMatchOver = match.isMatchOver;
        if (isMatchOver) {
          final playerElos = session.players.map((id, p) => MapEntry(id, p.currentElo));
          String? winnerId; int maxScore = -1;
          for (final entry in session.players.entries) {
            if (entry.value.cumulativeScore > maxScore) { maxScore = entry.value.cumulativeScore; winnerId = entry.key; }
          }
          if (winnerId != null) { eloShifts = EloCalculator.calculateMultiplayerShifts(playerElos: playerElos, winnerId: winnerId); }
        }
      }

      // 5. Broadcast results
      await transport.sendEvent(GameEvent(
        type: GameEventType.roundResults, 
        payload: {
          'results': roundResults, 
          if (eloShifts != null) 'eloShifts': eloShifts, 
          'isMatchOver': isMatchOver
        }
      ));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              playerExpression: '', // Host is spectator
              playerValue: 0,
              playerPoints: 0,
              multiplayerResults: roundResults,
              eloShifts: eloShifts,
            ),
          ),
        );
      }
    }
  }

  void _handleGameEvent(GameEvent event) {
    if (event.type == GameEventType.roundStarted) {
      final List<int> numbers = List<int>.from(event.payload['numbers']);
      final int target = event.payload['target'];
      final jeopardyIndex = event.payload['jeopardy'];
      final lockedOp = event.payload['lockedOperator'];
      final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null;

      ref.read(roundProvider).startRoundWithData(numbers: numbers, target: target, jeopardy: jeopardy, lockedOp: lockedOp);
      
      setState(() {
        _secondsLeft = jeopardy == JeopardyType.speedDemon ? 30 : 60;
        _isRoundEnding = false;
      });
      _entranceController.reset();
      _entranceController.forward();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider);
    final session = ref.watch(sessionProvider);
    final match = ref.watch(matchProvider).value;
    final nextRoundJeopardy = ref.watch(jeopardyOverrideProvider);

    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) => next.whenData(_handleGameEvent));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('COMMAND CENTER • ROUND ${match?.currentRound ?? 1}', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false),
            icon: const Icon(Icons.exit_to_app_rounded),
          ),
        ],
      ),
      body: VectorBackground(
        child: Column(
          children: [
            // 1. Target & Timer Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('TARGET', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)),
                      Text('${round.target}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                  Column(
                    children: [
                      Text('TIME LEFT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10)),
                      Text('$_secondsLeft', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: _secondsLeft < 10 ? Colors.red : colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2. Control Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.amber),
                        const SizedBox(width: 12),
                        Text('HOST OVERRIDE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.primary)),
                        const Spacer(),
                        Switch(
                          value: nextRoundJeopardy, 
                          onChanged: (v) => ref.read(jeopardyOverrideProvider.notifier).setOverride(v),
                          activeThumbColor: colorScheme.primary,
                        ),
                        Text('NEXT ROUND JEOPARDY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3. Player Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: session.players.length,
                  itemBuilder: (context, index) {
                    final id = session.players.keys.elementAt(index);
                    final player = session.players[id]!;
                    final hasSubmitted = player.lastExpression != null;

                    return Container(
                      decoration: BoxDecoration(
                        color: hasSubmitted ? Colors.green.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: hasSubmitted ? Colors.green.withValues(alpha: 0.3) : colorScheme.onSurface.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: hasSubmitted ? Colors.green : colorScheme.primary.withValues(alpha: 0.1),
                            child: hasSubmitted 
                              ? const Icon(Icons.check_rounded, color: Colors.white)
                              : Text(player.name[0].toUpperCase(), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          Text(player.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            hasSubmitted ? 'SUBMITTED' : 'THINKING...', 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: hasSubmitted ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 4. Force End Button (Optional but useful)
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _onTimeUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('FORCE END ROUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _entranceController.dispose();
    super.dispose();
  }
}
