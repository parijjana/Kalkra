import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import '../providers/game_providers.dart';
import 'results_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late Timer _timer;
  int _secondsLeft = 60;
  String _currentExpression = '';
  final List<int> _usedIndices = [];
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    // Only start round locally if in Solo mode and not already started
    final transport = ref.read(transportProvider);
    if (transport is NullTransport) {
      _startNewRound();
    }
    _startTimer();
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
      if (match != null && (match.currentRound >= match.totalRounds)) {
        // Calculate Elo shifts
        final playerElos = session.players.map((id, p) => MapEntry(id, p.currentElo));
        // Find match winner (highest cumulative score)
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

      await transport.sendEvent(GameEvent(
        type: GameEventType.roundResults,
        payload: {
          'results': roundResults,
          if (eloShifts != null) 'eloShifts': eloShifts,
          'isMatchOver': match?.isMatchOver ?? false,
        },
      ));

      if (mounted) {
        _navigateToResults(
          multiplayerResults: roundResults, 
          eloShifts: eloShifts,
        );
      }
    } else if (transport is NullTransport) {
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

    if (transport is NullTransport) {
      round.submitExpression(expression);
      round.endRound();
      _navigateToResults();
    } else {
      await transport.sendEvent(GameEvent(
        type: GameEventType.submissionReceived,
        payload: {
          'expression': expression,
          'playerId': 'me',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider);
    final eventAsync = ref.watch(gameEventStreamProvider);

    // Listen for round results in multiplayer
    eventAsync.whenData((event) {
      if (event.type == GameEventType.roundResults) {
        final results = event.payload['results'] as Map<String, dynamic>;
        final Map<String, int>? eloShifts = event.payload['eloShifts'] != null 
            ? Map<String, int>.from(event.payload['eloShifts']) 
            : null;

        // Apply local Elo shift if present
        if (eloShifts != null && eloShifts.containsKey('me')) { // TODO: use real ID
           final shift = eloShifts['me']!;
           final careerNotifier = ref.read(careerProvider);
           // We need to find the winner's name for the rival history
           String winnerName = 'Opponent'; 
           careerNotifier.value.applyEloShift(shift, winnerName);
        }

        if (mounted) {
          _navigateToResults(multiplayerResults: results, eloShifts: eloShifts);
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primaryContainer],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'TIME: $_secondsLeft',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
        _TargetSection(target: round.target ?? 0),
        const SizedBox(height: 24),
        _NumbersSection(
          numbers: round.numbers,
          usedIndices: _usedIndices,
          onNumberTap: _onNumberTap,
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
          width: 250,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_history[i], style: const TextStyle(fontFamily: 'monospace')),
                    leading: const Icon(Icons.history_rounded, size: 16),
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
              ),
              const SizedBox(height: 40),
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
          width: 250,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PRO TIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 24),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F0F3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(48)),
      ),
      child: Column(
        children: [
          Text('TARGET', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2)),
          Text('$target', style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary, fontSize: 100, height: 1)),
        ],
      ),
    );
  }
}

class _NumbersSection extends StatelessWidget {
  final List<int> numbers;
  final List<int> usedIndices;
  final Function(int, int) onNumberTap;

  const _NumbersSection({required this.numbers, required this.usedIndices, required this.onNumberTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(numbers.length, (i) {
          final isUsed = usedIndices.contains(i);
          return _NumberTile(
            value: numbers[i],
            isUsed: isUsed,
            onTap: () => onNumberTap(i, numbers[i]),
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
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isUsed ? colorScheme.surfaceVariant : colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isUsed ? null : [BoxShadow(color: colorScheme.onSurface.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: isUsed ? colorScheme.onSurfaceVariant.withOpacity(0.3) : colorScheme.onTertiaryContainer)),
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
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: colorScheme.onSurface.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 12))],
      ),
      child: Text(
        currentExpression.isEmpty ? 'BUILD EXPRESSION' : currentExpression,
        style: theme.textTheme.headlineMedium?.copyWith(color: currentExpression.isEmpty ? colorScheme.onSurface.withOpacity(0.2) : colorScheme.onSurface, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _OpButton(label: '(', onTap: () => onOperatorTap('('), color: colorScheme.surfaceVariant, textColor: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 16),
              Expanded(child: _OpButton(label: ')', onTap: () => onOperatorTap(')'), color: colorScheme.surfaceVariant, textColor: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: Colors.white),
              child: Text('SUBMIT', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(72, 72),
        backgroundColor: color ?? theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label, style: TextStyle(fontSize: 32, color: textColor ?? Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
