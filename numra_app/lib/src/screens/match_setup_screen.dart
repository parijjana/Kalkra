import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

enum MatchSetupMode { solo, host }

class MatchSetupScreen extends ConsumerStatefulWidget {
  final MatchSetupMode mode;

  const MatchSetupScreen({super.key, required this.mode});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _rounds = 5;
  bool _jeopardyEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('MATCH SETUP'),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('DIFFICULTY DIAL'),
            const SizedBox(height: 24),
            _buildDifficultyDial(),
            
            const SizedBox(height: 48),
            
            _buildSectionHeader('ROUND COUNT'),
            const SizedBox(height: 24),
            _buildRoundSelector(),

            const SizedBox(height: 48),

            _buildJeopardyToggle(),

            const SizedBox(height: 64),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _startMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  child: Text(
                    widget.mode == MatchSetupMode.solo ? 'START PRACTICE' : 'START ARENA',
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildDifficultyDial() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Row(
        children: Difficulty.values.map((d) {
          final isSelected = _difficulty == d;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected ? _getDifficultyColor(d) : Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: isSelected ? [
                    BoxShadow(color: _getDifficultyColor(d).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  d.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoundSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final roundOptions = [3, 5, 10];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: roundOptions.map((r) {
        final isSelected = _rounds == r;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: r == 10 ? 0 : 16),
            child: GestureDetector(
              onTap: () => setState(() => _rounds = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: isSelected ? [
                    BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      '$r',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'ROUNDS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: isSelected ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJeopardyToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.bolt_rounded, color: colorScheme.tertiary),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JEOPARDY MODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('Random chaos events each round.', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Switch(
            value: _jeopardyEnabled,
            onChanged: (v) => setState(() => _jeopardyEnabled = v),
            activeColor: colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy: return Colors.green;
      case Difficulty.medium: return Colors.orange;
      case Difficulty.hard: return Colors.redAccent;
    }
  }

  Future<void> _startMatch() async {
    final career = ref.read(careerProvider);
    final transport = ref.read(transportProvider);
    
    // Initialize MatchManager
    final match = MatchManager(totalRounds: _rounds, jeopardyEnabled: _jeopardyEnabled);
    ref.read(matchProvider).value = match;
    
    // Start First Round with Solver Validation
    final round = ref.read(roundProvider);
    round.startRound(
      difficulty: _difficulty, 
      jeopardy: match.activeJeopardy,
      lockedOp: match.lockedOperator,
    );
    ref.read(sessionProvider).resetRoundData();

    if (widget.mode == MatchSetupMode.host) {
      // Broadcast to clients
      await transport.sendEvent(GameEvent(
        type: GameEventType.roundStarted,
        payload: {
          'target': round.target,
          'numbers': round.numbers,
          'difficulty': _difficulty.index,
          'jeopardy': match.activeJeopardy?.index,
          'lockedOperator': match.lockedOperator,
        },
      ));
    }

    if (mounted) {
      // Manually ensure local RoundManager state is sync'd
      ref.read(roundProvider).startRoundWithData(
        numbers: round.numbers, 
        target: round.target!,
        jeopardy: match.activeJeopardy,
        lockedOp: match.lockedOperator,
      );
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }
}
