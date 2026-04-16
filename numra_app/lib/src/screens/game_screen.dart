import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import 'results_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with TickerProviderStateMixin {
  late Timer _timer;
  int _secondsLeft = 60;
  String _currentExpression = '';
  final List<int> _usedIndices = [];
  final List<String> _history = [];
  DateTime? _roundStartTime;
  double? _secondsToSubmit;

  // Animation Controllers for Polish
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    final transport = ref.read(transportProvider);
    if (transport is NullTransport) {
      _startNewRound();
    }
    _startTimer();
    _roundStartTime = DateTime.now();
    _entranceController.forward();
  }

  void _startNewRound() {
    final settings = ref.read(settingsProvider).value;
    ref.read(roundProvider).startRound(difficulty: settings.difficulty);
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
    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final match = ref.read(matchProvider).value;
    round.endRound();

    if (transport is LanHostTransport) {
      final session = ref.read(sessionProvider);
      
      // Calculate round results
      final roundResults = <String, Map<String, dynamic>>{};
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        roundResults[id] = {
          'name': p.name,
          'points': p.lastPoints ?? 0,
          'expression': p.lastExpression ?? '',
        };
      }

      // Check if match is over
      Map<String, int>? eloShifts;
      bool isMatchOver = false;
      if (match != null) {
        isMatchOver = match.isMatchOver;
        if (isMatchOver) {
          final playerElos = session.players.map((id, p) => MapEntry(id, p.currentElo));
          String? winnerId;
          int maxScore = -1;
          for (final entry in session.players.entries) {
            if (entry.value.cumulativeScore > maxScore) {
              maxScore = entry.value.cumulativeScore;
              winnerId = entry.key;
            }
          }
          
          if (winnerId != null) {
            eloShifts = EloCalculator.calculateMultiplayerShifts(
              playerElos: playerElos,
              winnerId: winnerId,
            );
          }
        }
      }

      await transport.sendEvent(GameEvent(
        type: GameEventType.roundResults,
        payload: {
          'results': roundResults,
          if (eloShifts != null) 'eloShifts': eloShifts,
          'isMatchOver': isMatchOver,
        },
      ));

      if (eloShifts != null && eloShifts.containsKey('host')) {
        final shift = eloShifts['host']!;
        String opponentName = 'Arena';
        ref.read(careerProvider.notifier).applyEloShift(shift, opponentName);
      }

      if (mounted) {
        _navigateToResults(
          multiplayerResults: roundResults, 
          eloShifts: eloShifts,
        );
      }
    } else if (transport is NullTransport) {
      final expression = _currentExpression.trim();
      final roundData = ref.read(roundProvider);
      final points = roundData.calculatePoints(expression);
      final validation = SubmissionValidator().validate(expression, roundData.numbers);
      final proximity = (roundData.target! - (validation.value ?? 0)).abs().toInt();
      
      ref.read(careerProvider.notifier).updatePerformance(
        secondsToSubmit: _secondsToSubmit ?? 60.0,
        proximityToTarget: proximity,
      );

      _navigateToResults();
    }
  }

  void _navigateToResults({Map<String, dynamic>? multiplayerResults, Map<String, int>? eloShifts}) {
    final round = ref.read(roundProvider);
    final expression = _currentExpression.trim();
    final validation = SubmissionValidator().validate(expression, round.numbers);
    final points = round.calculatePoints(expression);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            playerExpression: expression,
            playerValue: validation.value,
            playerPoints: points,
            multiplayerResults: multiplayerResults,
            eloShifts: eloShifts,
          ),
        ),
      );
    }
  }

  void _onNumberTap(int index, int value) {
    if (_usedIndices.contains(index)) return;
    setState(() {
      _currentExpression += '$value';
      _usedIndices.add(index);
    });
  }

  void _onOperatorTap(String op) {
    setState(() {
      _currentExpression += ' $op ';
    });
  }

  void _clear() {
    setState(() {
      _currentExpression = '';
      _usedIndices.clear();
    });
  }

  Future<void> _submit() async {
    if (_currentExpression.isEmpty) return;
    
    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final expression = _currentExpression.trim();

    _secondsToSubmit = DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;

    if (transport is NullTransport) {
      round.submitExpression(expression);
      _onTimeUp();
    } else {
      String myId = transport is LanHostTransport ? 'host' : 'me';
      await transport.sendEvent(GameEvent(
        type: GameEventType.submissionReceived,
        payload: {
          'expression': expression,
          'playerId': myId,
        },
      ));
      setState(() {
        _history.insert(0, expression);
        _clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission sent!'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider);
    final eventAsync = ref.watch(gameEventStreamProvider);

    eventAsync.whenData((event) {
      if (event.type == GameEventType.roundResults) {
        final results = Map<String, dynamic>.from(event.payload['results']);
        final Map<String, int>? eloShifts = event.payload['eloShifts'] != null 
            ? Map<String, int>.from(event.payload['eloShifts']) 
            : null;

        if (eloShifts != null) {
          final transport = ref.read(transportProvider);
          String myKey = 'me';
          if (transport is LanHostTransport) myKey = 'host';
          else {
             myKey = eloShifts.keys.firstWhere((k) => k.startsWith('client-'), orElse: () => 'me');
          }

      if (eloShifts?.containsKey(myKey) ?? false) {
        final shift = eloShifts![myKey]!;
        ref.read(careerProvider.notifier).applyEloShift(shift, 'Arena Rival');
      }
        }

        if (mounted) {
          _navigateToResults(multiplayerResults: results, eloShifts: eloShifts);
        }
      } else if (event.type == GameEventType.roundStarted) {
        final List<int> numbers = List<int>.from(event.payload['numbers']);
        final int target = event.payload['target'];
        ref.read(roundProvider).startRoundWithData(numbers: numbers, target: target);
        
        setState(() {
          _secondsLeft = 60;
          _currentExpression = '';
          _usedIndices.clear();
          _roundStartTime = DateTime.now();
          _secondsToSubmit = null;
        });
        _entranceController.reset();
        _entranceController.forward();
        _startTimer();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
            ),
          ),
        ),
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          'TIME: $_secondsLeft',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout(context, round);
          } else {
            return _buildMobileLayout(context, round);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, RoundManager round) {
    return Column(
      children: [
        FadeTransition(
          opacity: _entranceController,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
                .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack)),
            child: _TargetSection(target: round.target ?? 0),
          ),
        ),
        const SizedBox(height: 32),
        _NumbersSection(
          numbers: round.numbers,
          usedIndices: _usedIndices,
          onNumberTap: _onNumberTap,
          entranceAnimation: _entranceController,
        ),
        const Spacer(),
        _ExpressionSection(currentExpression: _currentExpression),
        const Spacer(),
        _ControlsSection(
          onOperatorTap: _onOperatorTap,
          onSubmit: _submit,
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, RoundManager round) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Left: History
        Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text('HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 12)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _history.length,
                  itemBuilder: (context, i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(_history[i], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.history_rounded, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Center: Main Game
        Expanded(
          child: Column(
            children: [
              _TargetSection(target: round.target ?? 0),
              const Spacer(),
              _NumbersSection(
                numbers: round.numbers,
                usedIndices: _usedIndices,
                onNumberTap: _onNumberTap,
                entranceAnimation: _entranceController,
              ),
              const SizedBox(height: 48),
              _ExpressionSection(currentExpression: _currentExpression),
              const Spacer(),
              _ControlsSection(
                onOperatorTap: _onOperatorTap,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
        // Right: Pro Tips
        Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PRO TIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 12)),
              const SizedBox(height: 32),
              _TipItem(icon: Icons.lightbulb_outline, text: 'Try to reach near 100s first.'),
              _TipItem(icon: Icons.calculate_outlined, text: 'Use large numbers for big jumps.'),
              _TipItem(icon: Icons.timer_outlined, text: 'Speed counts in multiplayer!'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetSection extends StatelessWidget {
  final int target;
  const _TargetSection({required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TARGET', 
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900, 
              letterSpacing: 6,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$target', 
            style: theme.textTheme.displayLarge?.copyWith(
              color: colorScheme.primary, 
              fontSize: 120, 
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumbersSection extends StatelessWidget {
  final List<int> numbers;
  final List<int> usedIndices;
  final Function(int, int) onNumberTap;
  final Animation<double> entranceAnimation;

  const _NumbersSection({
    required this.numbers, 
    required this.usedIndices, 
    required this.onNumberTap,
    required this.entranceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: List.generate(numbers.length, (i) {
          final isUsed = usedIndices.contains(i);
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: entranceAnimation,
              curve: Interval(0.2 + (i * 0.1), 1.0, curve: Curves.elasticOut),
            ),
            child: _NumberTile(
              value: numbers[i],
              isUsed: isUsed,
              onTap: () => onNumberTap(i, numbers[i]),
            ),
          );
        }),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  final int value;
  final bool isUsed;
  final VoidCallback onTap;

  const _NumberTile({required this.value, required this.isUsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isUsed ? colorScheme.surfaceContainerHighest : colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isUsed ? null : [
            BoxShadow(
              color: colorScheme.tertiary.withValues(alpha: 0.2), 
              blurRadius: 15, 
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value', 
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900, 
            color: isUsed 
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.2) 
              : colorScheme.onTertiaryContainer,
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}

class _ExpressionSection extends StatelessWidget {
  final String currentExpression;
  const _ExpressionSection({required this.currentExpression});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08), 
            blurRadius: 50, 
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Text(
        currentExpression.isEmpty ? 'BUILD EXPRESSION' : currentExpression,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: currentExpression.isEmpty ? colorScheme.onSurface.withValues(alpha: 0.15) : colorScheme.onSurface, 
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          fontSize: 24,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final Function(String) onOperatorTap;
  final VoidCallback onSubmit;

  const _ControlsSection({required this.onOperatorTap, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OpButton(label: '+', onTap: () => onOperatorTap('+')),
              _OpButton(label: '-', onTap: () => onOperatorTap('-')),
              _OpButton(label: '×', onTap: () => onOperatorTap('*')),
              _OpButton(label: '÷', onTap: () => onOperatorTap('/')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _OpButton(label: '(', onTap: () => onOperatorTap('('), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 20),
              Expanded(child: _OpButton(label: ')', onTap: () => onOperatorTap(')'), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: Text(
                  'SUBMIT', 
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  const _OpButton({required this.label, required this.onTap, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final btnColor = color ?? colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: btnColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(76, 76),
          backgroundColor: btnColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 36, 
            color: textColor ?? colorScheme.onPrimary, 
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
