import 'dart:async';
import 'dart:ui';
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
  
  // Jeopardy State
  JeopardyType? _activeJeopardy;
  String? _lockedOperator;
  int _revealedDigits = 0;
  Timer? _revealTimer;

  // Sidebar visibility state
  bool _isHistoryVisible = false;
  bool _isTipsVisible = false;

  // Animation Controllers for Polish
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _startTimer();
    _roundStartTime = DateTime.now();
    _entranceController.forward();

    // Check if we need a reveal timer for Hidden Target
    final round = ref.read(roundProvider);
    if (round.jeopardyType == JeopardyType.hiddenTarget) {
      _startRevealTimer();
    } else {
      _revealedDigits = 3;
    }
    _activeJeopardy = round.jeopardyType;
    _lockedOperator = round.lockedOperator;
  }

  void _startTimer() {
    final round = ref.read(roundProvider);
    _secondsLeft = round.jeopardyType == JeopardyType.speedDemon ? 30 : 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _startRevealTimer() {
    _revealedDigits = 0;
    _revealTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_revealedDigits < 3) {
        setState(() => _revealedDigits++);
      } else {
        _revealTimer?.cancel();
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
      
      final roundResults = <String, Map<String, dynamic>>{};
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        roundResults[id] = {
          'name': p.name,
          'points': p.lastPoints ?? 0,
          'expression': p.lastExpression ?? '',
        };
      }

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
        ref.read(careerProvider.notifier).applyEloShift(shift, 'Arena Rival');
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
    if (op == _lockedOperator) return;
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

  void _backspace() {
    if (_currentExpression.isEmpty) return;

    setState(() {
      final trimmed = _currentExpression.trim();
      if (trimmed.isEmpty) return;

      final parts = trimmed.split(' ');
      final lastToken = parts.last;

      if (int.tryParse(lastToken) != null && _usedIndices.isNotEmpty) {
        _usedIndices.removeLast();
      }

      if (parts.length > 1) {
        parts.removeLast();
        _currentExpression = parts.join(' ');
        if (_currentExpression.isNotEmpty && !RegExp(r'\d$').hasMatch(_currentExpression)) {
          _currentExpression += ' ';
        }
      } else {
        _currentExpression = '';
      }
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
    _revealTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleGameEvent(GameEvent event) {
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

        if (eloShifts.containsKey(myKey)) {
          final shift = eloShifts[myKey]!;
          ref.read(careerProvider.notifier).applyEloShift(shift, 'Arena Rival');
        }
      }

      if (mounted) {
        _navigateToResults(multiplayerResults: results, eloShifts: eloShifts);
      }
    } else if (event.type == GameEventType.roundStarted) {
      final List<int> numbers = List<int>.from(event.payload['numbers']);
      final int target = event.payload['target'];
      final jeopardyIndex = event.payload['jeopardy'];
      final lockedOp = event.payload['lockedOperator'];
      
      final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null;
      ref.read(roundProvider).startRoundWithData(numbers: numbers, target: target, jeopardy: jeopardy, lockedOp: lockedOp);
      
      setState(() {
        _activeJeopardy = jeopardy;
        _lockedOperator = lockedOp;
        _secondsLeft = _activeJeopardy == JeopardyType.speedDemon ? 30 : 60;
        _currentExpression = '';
        _usedIndices.clear();
        _roundStartTime = DateTime.now();
        _secondsToSubmit = null;
        
        if (_activeJeopardy == JeopardyType.hiddenTarget) {
          _revealedDigits = 0;
          _startRevealTimer();
        } else {
          _revealedDigits = 3;
        }
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
    final match = ref.watch(matchProvider).value;
    
    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (previous, next) {
      next.whenData(_handleGameEvent);
    });

    final roundText = match != null 
        ? 'ROUND ${match.currentRound}/${match.totalRounds}'
        : 'SOLO PRACTICE';

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roundText,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white70),
            ),
            Text(
              'TIME: $_secondsLeft',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (_activeJeopardy != null)
              Text(
                'JEOPARDY: ${_activeJeopardy!.name.toUpperCase()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: _clear, icon: const Icon(Icons.refresh_rounded)),
      ),
      body: Stack(
        children: [
          // Main Play Area
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: _buildMainGame(context, round),
            ),
          ),

          // Sidebar Toggles
          _buildSidebarTabs(context),

          // Overlays
          _buildHistoryOverlay(context),
          _buildTipsOverlay(context),
        ],
      ),
    );
  }

  Widget _buildMainGame(BuildContext context, RoundManager round) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _entranceController,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
                .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack)),
            child: _TargetSection(
              target: round.target ?? 0, 
              revealedDigits: _revealedDigits,
              isHighStakes: _activeJeopardy == JeopardyType.doubleOrNothing,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _NumbersSection(
          numbers: round.numbers,
          usedIndices: _usedIndices,
          onNumberTap: _onNumberTap,
          entranceAnimation: _entranceController,
        ),
        const SizedBox(height: 40),
        _ExpressionSection(currentExpression: _currentExpression, onBackspace: _backspace),
        const SizedBox(height: 40),
        _ControlsSection(
          onOperatorTap: _onOperatorTap,
          onSubmit: _submit,
          lockedOperator: _lockedOperator,
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSidebarTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 100,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BookTab(
            label: 'HISTORY',
            icon: Icons.history_rounded,
            color: colorScheme.primary,
            onTap: () => setState(() => _isHistoryVisible = !_isHistoryVisible),
            isActive: _isHistoryVisible,
          ),
          const SizedBox(height: 12),
          _BookTab(
            label: 'PRO TIPS',
            icon: Icons.lightbulb_outline_rounded,
            color: colorScheme.tertiary,
            onTap: () => setState(() => _isTipsVisible = !_isTipsVisible),
            isActive: _isTipsVisible,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      right: _isHistoryVisible ? 0 : -350,
      top: 0,
      bottom: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 60, offset: const Offset(-15, 0)),
          ],
          border: Border(left: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 6)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 48, 24, 24),
                    child: Row(
                      children: [
                        Text('HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16, color: colorScheme.primary)),
                        const Spacer(),
                        IconButton(onPressed: () => setState(() => _isHistoryVisible = false), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _history.length,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(_history[i], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      right: _isTipsVisible ? 0 : -350,
      top: 0,
      bottom: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 60, offset: const Offset(-15, 0)),
          ],
          border: Border(left: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.3), width: 6)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 48, 24, 24),
                    child: Row(
                      children: [
                        Text('PRO TIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16, color: colorScheme.tertiary)),
                        const Spacer(),
                        IconButton(onPressed: () => setState(() => _isTipsVisible = false), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _TipItem(icon: Icons.lightbulb_outline, text: 'Try to reach near 100s first.'),
                      _TipItem(icon: Icons.calculate_outlined, text: 'Use large numbers for big jumps.'),
                      _TipItem(icon: Icons.timer_outlined, text: 'Speed counts in multiplayer!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _BookTab({required this.label, required this.icon, required this.color, required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(-4, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isActive ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  final int target;
  final int revealedDigits;
  final bool isHighStakes;

  const _TargetSection({
    required this.target, 
    required this.revealedDigits,
    required this.isHighStakes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Mask target based on revealedDigits
    String targetStr = target.toString().padLeft(3, '0');
    String displayedTarget = '';
    for (int i = 0; i < 3; i++) {
      if (i < revealedDigits) {
        displayedTarget += targetStr[i];
      } else {
        displayedTarget += '?';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      decoration: BoxDecoration(
        color: isHighStakes ? Colors.red.withValues(alpha: 0.1) : colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(72)),
        boxShadow: [
          BoxShadow(
            color: isHighStakes ? Colors.red.withValues(alpha: 0.2) : colorScheme.onSurface.withValues(alpha: 0.05), 
            blurRadius: 50, 
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isHighStakes ? 'DOUBLE OR NOTHING' : 'TARGET', 
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900, 
              letterSpacing: isHighStakes ? 4 : 10, 
              color: isHighStakes ? Colors.red : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayedTarget, 
            style: theme.textTheme.displayLarge?.copyWith(
              color: isHighStakes ? Colors.redAccent : colorScheme.primary, 
              fontSize: 130, 
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

  const _NumbersSection({required this.numbers, required this.usedIndices, required this.onNumberTap, required this.entranceAnimation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: List.generate(numbers.length, (i) {
          final isUsed = usedIndices.contains(i);
          return ScaleTransition(
            scale: CurvedAnimation(parent: entranceAnimation, curve: Interval(0.2 + (i * 0.1), 1.0, curve: Curves.elasticOut)),
            child: _NumberTile(value: numbers[i], isUsed: isUsed, onTap: () => onNumberTap(i, numbers[i])),
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
        curve: Curves.easeInOut,
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: isUsed ? colorScheme.surfaceContainerHighest : colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isUsed ? Colors.transparent : colorScheme.tertiary.withValues(alpha: 0.3), 
              blurRadius: isUsed ? 0 : 25, 
              offset: isUsed ? Offset.zero : const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value', 
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900, 
            color: isUsed ? colorScheme.onSurfaceVariant.withValues(alpha: 0.2) : colorScheme.onTertiaryContainer,
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}

class _ExpressionSection extends StatelessWidget {
  final String currentExpression;
  final VoidCallback onBackspace;

  const _ExpressionSection({required this.currentExpression, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.1), blurRadius: 60, offset: const Offset(0, 25)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              currentExpression.isEmpty ? 'BUILD EXPRESSION' : currentExpression,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: currentExpression.isEmpty ? colorScheme.onSurface.withValues(alpha: 0.2) : colorScheme.onSurface, 
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (currentExpression.isNotEmpty)
            IconButton(
              onPressed: onBackspace, 
              icon: Icon(Icons.backspace_rounded, color: colorScheme.primary, size: 32),
            ),
        ],
      ),
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final Function(String) onOperatorTap;
  final VoidCallback onSubmit;
  final String? lockedOperator;

  const _ControlsSection({
    required this.onOperatorTap, 
    required this.onSubmit,
    this.lockedOperator,
  });

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
              _OpButton(label: '+', onTap: () => onOperatorTap('+'), isLocked: lockedOperator == '+'),
              _OpButton(label: '-', onTap: () => onOperatorTap('-'), isLocked: lockedOperator == '-'),
              _OpButton(label: '×', onTap: () => onOperatorTap('*'), isLocked: lockedOperator == '*'),
              _OpButton(label: '÷', onTap: () => onOperatorTap('/'), isLocked: lockedOperator == '/'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _OpButton(label: '(', onTap: () => onOperatorTap('('), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 24),
              Expanded(child: _OpButton(label: ')', onTap: () => onOperatorTap(')'), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 88,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.4), blurRadius: 35, offset: const Offset(0, 15)),
                ],
              ),
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                child: Text('SUBMIT', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 8)),
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
  final bool isLocked;

  const _OpButton({required this.label, required this.onTap, this.color, this.textColor, this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final btnColor = isLocked ? colorScheme.surfaceContainerHighest : (color ?? colorScheme.primary);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: isLocked ? [] : [
          BoxShadow(color: btnColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLocked ? null : onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(80, 80),
          backgroundColor: btnColor,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
        ),
        child: isLocked 
          ? const Icon(Icons.lock_rounded, color: Colors.grey)
          : Text(label, style: TextStyle(fontSize: 44, color: textColor ?? colorScheme.onPrimary, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 28, color: colorScheme.primary),
          ),
          const SizedBox(width: 24),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
