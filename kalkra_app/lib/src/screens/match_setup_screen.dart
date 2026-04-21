import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/vector_background.dart';
import 'game_screen.dart';

import 'package:transport_lan/transport_lan.dart';

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
  GameMode _gameMode = GameMode.practice;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenIdProvider.notifier).setScreenId('MatchSetupScreen');
    });
    return ResponsiveLayout(
      mobile: _buildMobile(context),
      desktop: _buildDesktop(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('ARENA CONFIGURATION'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader('GAME MODE'),
            const SizedBox(height: 16),
            _buildModeSelector(),
            if (_gameMode != GameMode.progressive) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('MATCH DIFFICULTY'),
              const SizedBox(height: 16),
              _buildDifficultyDial(),
            ],
            if (_gameMode == GameMode.practice) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('TOTAL ROUNDS'),
              const SizedBox(height: 16),
              _buildRoundSelector(),
            ],
            const SizedBox(height: 32),
            if (_gameMode != GameMode.progressive) _buildJeopardyToggle(),
            const SizedBox(height: 48),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const TopNavBar(activeId: 'MainScreen'),
      body: VectorBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARENA CONFIGURATION', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  Text('CALIBRATE YOUR CHALLENGE PARAMETERS', style: TextStyle(letterSpacing: 4, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w900, fontSize: 12)),
                  
                  const SizedBox(height: 80),

                  _buildSectionHeader('GAME MODE'),
                  const SizedBox(height: 24),
                  _buildModeSelector(),
                  
                  const SizedBox(height: 60),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_gameMode != GameMode.progressive)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('MATCH DIFFICULTY'),
                              const SizedBox(height: 24),
                              _buildDifficultyDial(),
                              const SizedBox(height: 48),
                              _buildJeopardyToggle(),
                            ],
                          ),
                        ),
                      if (_gameMode != GameMode.progressive) const SizedBox(width: 80),
                      if (_gameMode == GameMode.practice)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('TOTAL ROUNDS'),
                              const SizedBox(height: 24),
                              _buildRoundSelector(),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 100),
                  _buildStartButton(context, isLarge: true),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)));
  }

  Widget _buildModeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final modes = [
      (mode: GameMode.practice, label: 'PRACTICE', icon: Icons.model_training_rounded),
      if (widget.mode == MatchSetupMode.solo)
        (mode: GameMode.endless, label: 'ENDLESS', icon: Icons.loop_rounded),
      (mode: GameMode.progressive, label: 'PROGRESSIVE', icon: Icons.trending_up_rounded),
    ];

    return Row(
      children: modes.map((m) {
        final isSelected = _gameMode == m.mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: m == modes.last ? 0 : 12),
            child: GestureDetector(
              onTap: () => setState(() => _gameMode = m.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))] : [],
                ),
                child: Column(
                  children: [
                    Icon(m.icon, color: isSelected ? Colors.white : colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(m.label, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : colorScheme.onSurface, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyDial() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(48)),
      child: Row(children: Difficulty.values.map((d) {
          final isSelected = _difficulty == d;
          return Expanded(child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: isSelected ? _getDifficultyColor(d) : Colors.transparent, borderRadius: BorderRadius.circular(40), boxShadow: isSelected ? [BoxShadow(color: _getDifficultyColor(d).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))] : []),
                alignment: Alignment.center,
                child: Text(d.name.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
          ));
      }).toList()),
    );
  }

  Widget _buildRoundSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final roundOptions = [3, 5, 10];
    return Row(children: roundOptions.map((r) {
        final isSelected = _rounds == r;
        return Expanded(child: Padding(
            padding: EdgeInsets.only(right: r == 10 ? 0 : 16),
            child: GestureDetector(
              onTap: () => setState(() => _rounds = r),
              child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(32), boxShadow: isSelected ? [BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))] : []), alignment: Alignment.center, child: Column(children: [Text('$r', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : colorScheme.onSurface)), Text('ROUNDS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: isSelected ? Colors.white70 : colorScheme.onSurface.withValues(alpha: 0.4)))]))),
        ));
    }).toList());
  }

  Widget _buildJeopardyToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
      child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorScheme.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.bolt_rounded, color: colorScheme.tertiary)),
          const SizedBox(width: 20),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('JEOPARDY MODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)), Text('Random chaos events each round.', style: TextStyle(fontSize: 12, color: Colors.black54))])),
          Switch(value: _jeopardyEnabled, onChanged: (v) => setState(() => _jeopardyEnabled = v), activeTrackColor: colorScheme.tertiary),
      ]),
    );
  }

  Widget _buildStartButton(BuildContext context, {bool isLarge = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 100 : 80,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15))]),
        child: ElevatedButton(
          onPressed: _startMatch,
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
          child: Text(widget.mode == MatchSetupMode.solo ? 'START PRACTICE' : 'START ARENA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: isLarge ? 24 : 18)),
        ),
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
    final match = MatchManager(
      totalRounds: _gameMode == GameMode.progressive ? 10 : _rounds, 
      jeopardyEnabled: _gameMode == GameMode.progressive ? true : _jeopardyEnabled,
      gameMode: _gameMode,
    );
    ref.read(matchProvider).value = match;
    final round = ref.read(roundProvider);
    round.startRound(difficulty: match.currentDifficulty, jeopardy: match.activeJeopardy, lockedOp: match.lockedOperator);
    
    final session = ref.read(sessionProvider);
    session.resetScores();
    session.resetRoundData();

    if (widget.mode == MatchSetupMode.solo) {
      ref.read(transportProvider.notifier).setTransport(NullTransport());
      session.addPlayer('solo', ref.read(careerProvider).playerName);
      ref.read(roundProvider).startRoundWithData(numbers: round.numbers, target: round.target!, jeopardy: match.activeJeopardy, lockedOp: match.lockedOperator);
    } else if (widget.mode == MatchSetupMode.host) {
      final transport = ref.read(transportProvider);
      await transport.sendEvent(GameEvent(type: GameEventType.roundStarted, payload: {'target': round.target, 'numbers': round.numbers, 'difficulty': match.currentDifficulty.index, 'jeopardy': match.activeJeopardy?.index, 'lockedOperator': match.lockedOperator}));
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const GameScreen()));
    }
  }
}
