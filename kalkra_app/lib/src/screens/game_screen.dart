import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/game_providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/global_drawer.dart';
import 'main_screen.dart';
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
  
  JeopardyType? _activeJeopardy;
  String? _lockedOperator;
  int _revealedDigits = 0;
  Timer? _revealTimer;

  bool _isHistoryVisible = false;

  late AnimationController _entranceController;
  int _focusedTokenIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _startTimer();
    _roundStartTime = DateTime.now();
    _entranceController.forward();
    final round = ref.read(roundProvider);
    if (round.jeopardyType == JeopardyType.hiddenTarget) { _startRevealTimer(); } else { _revealedDigits = 3; }
    _activeJeopardy = round.jeopardyType;
    _lockedOperator = round.lockedOperator;
    WidgetsBinding.instance.addPostFrameCallback((_) { _focusNode.requestFocus(); });
  }

  void _startTimer() {
    final round = ref.read(roundProvider);
    _secondsLeft = round.jeopardyType == JeopardyType.speedDemon ? 30 : 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) { setState(() => _secondsLeft--); } else { _timer.cancel(); _onTimeUp(); }
    });
  }

  void _startRevealTimer() {
    _revealedDigits = 0;
    _revealTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_revealedDigits < 3) { setState(() => _revealedDigits++); } else { _revealTimer?.cancel(); }
    });
  }

  bool _isRoundEnding = false;

  Future<void> _onTimeUp() async {
    if (_isRoundEnding) return;
    _isRoundEnding = true;
    _timer.cancel();
    _revealTimer?.cancel();
    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final match = ref.read(matchProvider).value;
    final session = ref.read(sessionProvider);
    round.endRound();

    if (transport is LanHostTransport) {
      final target = round.target ?? 0;
      final validator = SubmissionValidator();
      
      final myExpression = _currentExpression.trim();
      session.recordSubmission('host', myExpression, 0);

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
          proximities[id] = 1000000;
        }
      }

      int minProximity = 1000000;
      for (final prox in proximities.values) {
        if (prox < minProximity) minProximity = prox;
      }

      final roundResults = <String, Map<String, dynamic>>{};
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        int points = 0;
        
        if (minProximity < 1000000 && proximities[id] == minProximity) {
          final scoreKeeper = ScoreKeeper();
          points = scoreKeeper.calculateScore(target: target, result: values[id], jeopardy: round.jeopardyType);
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
      await transport.sendEvent(GameEvent(type: GameEventType.roundResults, payload: {'results': roundResults, if (eloShifts != null) 'eloShifts': eloShifts, 'isMatchOver': isMatchOver}));
      if (eloShifts != null && eloShifts.containsKey('host')) { ref.read(careerProvider.notifier).applyEloShift(eloShifts['host']!, 'Arena Rival'); }
      if (mounted) _navigateToResults(multiplayerResults: roundResults, eloShifts: eloShifts);
    } else if (transport is NullTransport) {
      final expression = _currentExpression.trim();
      final roundData = ref.read(roundProvider);
      final points = roundData.calculatePoints(expression);
      final validation = SubmissionValidator().validate(expression, roundData.numbers);
      final proximity = (roundData.target! - (validation.value ?? 0)).abs().toInt();
      
      if (match != null && match.gameMode == GameMode.endless && points == 0) {
        match.loseLife();
      }

      ref.read(sessionProvider).recordSubmission('solo', expression, points);
      ref.read(careerProvider.notifier).updatePerformance(secondsToSubmit: _secondsToSubmit ?? 60.0, proximityToTarget: proximity);
      _navigateToResults();
    }
  }

  void _onExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('END MATCH?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to resign and return to the main menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            final transport = ref.read(transportProvider);
            if (transport is! NullTransport) { await transport.sendEvent(GameEvent(type: GameEventType.playerJoined, payload: {'resigned': true})); }
            if (mounted) { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false); }
          }, child: const Text('RESIGN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _onNumberTap(int index, int value) {
    if (_usedIndices.contains(index)) return;
    setState(() {
      if (_currentExpression.isNotEmpty && RegExp(r'\d$').hasMatch(_currentExpression.trim())) { _currentExpression = _currentExpression.trim() + ' '; }
      _currentExpression += '$value'; _usedIndices.add(index);
    });
  }

  void _onOperatorTap(String op) {
    if (op == _lockedOperator) return;
    setState(() { _currentExpression = _currentExpression.trim() + ' $op '; });
  }

  void _clear() { setState(() { _currentExpression = ''; _usedIndices.clear(); }); }

  void _backspace() {
    if (_currentExpression.isEmpty) return;
    setState(() {
      final trimmed = _currentExpression.trim(); if (trimmed.isEmpty) return;
      final parts = trimmed.split(' '); final lastToken = parts.last;
      if (int.tryParse(lastToken) != null && _usedIndices.isNotEmpty) { _usedIndices.removeLast(); }
      if (parts.length > 1) { parts.removeLast(); _currentExpression = parts.join(' '); if (_currentExpression.isNotEmpty && !RegExp(r'\d$').hasMatch(_currentExpression)) { _currentExpression += ' '; } }
      else { _currentExpression = ''; }
    });
  }

  Future<void> _submit() async {
    if (_currentExpression.isEmpty) return;
    final round = ref.read(roundProvider); final transport = ref.read(transportProvider);
    final expression = _currentExpression.trim(); _secondsToSubmit = DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;
    if (transport is NullTransport) { round.submitExpression(expression); _onTimeUp(); }
    else {
      String myId = transport is LanHostTransport ? 'host' : 'me';
      await transport.sendEvent(GameEvent(type: GameEventType.submissionReceived, payload: {'expression': expression, 'playerId': myId}));
      setState(() { _history.insert(0, expression); _clear(); });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission sent!'), duration: Duration(seconds: 1))); }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;
      if (logicalKey == LogicalKeyboardKey.keyH) _onOperatorTap('+');
      else if (logicalKey == LogicalKeyboardKey.keyJ) _onOperatorTap('-');
      else if (logicalKey == LogicalKeyboardKey.keyK) _onOperatorTap('*');
      else if (logicalKey == LogicalKeyboardKey.keyL) _onOperatorTap('/');
      else if (logicalKey == LogicalKeyboardKey.keyN) _onOperatorTap('(');
      else if (logicalKey == LogicalKeyboardKey.keyM) _onOperatorTap(')');
      else if (logicalKey == LogicalKeyboardKey.backspace) _backspace();
      else if (logicalKey == LogicalKeyboardKey.enter) _submit();
      final round = ref.read(roundProvider);
      if (logicalKey == LogicalKeyboardKey.arrowLeft) { setState(() { _focusedTokenIndex = (_focusedTokenIndex - 1).clamp(0, round.numbers.length - 1); }); }
      else if (logicalKey == LogicalKeyboardKey.arrowRight) { setState(() { _focusedTokenIndex = (_focusedTokenIndex + 1).clamp(0, round.numbers.length - 1); }); }
      else if (logicalKey == LogicalKeyboardKey.space) { _onNumberTap(_focusedTokenIndex, round.numbers[_focusedTokenIndex]); }
    }
  }

  void _navigateToResults({Map<String, dynamic>? multiplayerResults, Map<String, int>? eloShifts}) {
    final round = ref.read(roundProvider); final expression = _currentExpression.trim();
    final validation = SubmissionValidator().validate(expression, round.numbers);
    final points = round.calculatePoints(expression);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ResultsScreen(playerExpression: expression, playerValue: validation.value, playerPoints: points, multiplayerResults: multiplayerResults, eloShifts: eloShifts)));
    }
  }

  @override
  void dispose() { _timer.cancel(); _revealTimer?.cancel(); _entranceController.dispose(); _focusNode.dispose(); super.dispose(); }

  void _handleGameEvent(GameEvent event) {
    if (event.type == GameEventType.roundResults) {
      final results = Map<String, dynamic>.from(event.payload['results']);
      final Map<String, int>? eloShifts = event.payload['eloShifts'] != null ? Map<String, int>.from(event.payload['eloShifts']) : null;
      if (eloShifts != null) {
        final transport = ref.read(transportProvider);
        String myKey = transport is LanHostTransport ? 'host' : eloShifts.keys.firstWhere((k) => k.startsWith('client-'), orElse: () => 'me');
        if (eloShifts.containsKey(myKey)) ref.read(careerProvider.notifier).applyEloShift(eloShifts[myKey]!, 'Arena Rival');
      }
      if (mounted) _navigateToResults(multiplayerResults: results, eloShifts: eloShifts);
    } else if (event.type == GameEventType.roundStarted) {
      final List<int> numbers = List<int>.from(event.payload['numbers']); final int target = event.payload['target'];
      final jeopardyIndex = event.payload['jeopardy']; final lockedOp = event.payload['lockedOperator'];
      final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null;
      ref.read(roundProvider).startRoundWithData(numbers: numbers, target: target, jeopardy: jeopardy, lockedOp: lockedOp);
      setState(() {
        _activeJeopardy = jeopardy; _lockedOperator = lockedOp; _secondsLeft = _activeJeopardy == JeopardyType.speedDemon ? 30 : 60;
        _currentExpression = ''; _usedIndices.clear(); _roundStartTime = DateTime.now(); _secondsToSubmit = null;
        if (_activeJeopardy == JeopardyType.hiddenTarget) { _revealedDigits = 0; _startRevealTimer(); } else { _revealedDigits = 3; }
        _focusedTokenIndex = 0; _isRoundEnding = false;
      });
      _entranceController.reset(); _entranceController.forward(); _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(currentScreenIdProvider.notifier).setScreenId('GameScreen'); });
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider); final match = ref.watch(matchProvider).value; final session = ref.watch(sessionProvider);
    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (previous, next) { next.whenData(_handleGameEvent); });
    
    String roundText = 'SOLO';
    if (match != null) {
      if (match.gameMode == GameMode.progressive) {
        roundText = 'PROGRESSIVE • ROUND ${match.currentRound}/10';
      } else if (match.gameMode == GameMode.endless) {
        roundText = 'ENDLESS • ROUND ${match.currentRound}';
      } else {
        roundText = 'ROUND ${match.currentRound}/${match.totalRounds}';
      }
    }
    
    final myScore = session.getPlayerScore(ref.read(transportProvider) is LanHostTransport ? 'host' : 'solo');

    return KeyboardListener(
      focusNode: _focusNode, autofocus: true, onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        drawer: const GlobalDrawer(),
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)]))),
          foregroundColor: colorScheme.onPrimary,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match?.gameMode == GameMode.endless) ...[
                    ...List.generate(3, (i) => Icon(
                      i < (match?.lives ?? 0) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: i < (match?.lives ?? 0) ? Colors.redAccent : Colors.white24,
                    )),
                    const SizedBox(width: 12),
                  ],
                  Text('$roundText • SCORE: $myScore', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white70)),
                ],
              ),
              Text('TIME: $_secondsLeft', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ]),
          centerTitle: true, elevation: 0,
          actions: [IconButton(onPressed: _clear, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: VectorBackground(
          child: Stack(
            children: [
              ResponsiveLayout(
                mobile: _buildGameCockpit(context, round),
                desktop: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: _buildGameCockpit(context, round),
                  ),
                ),
              ),
              _buildSidebarTabs(context),
              _buildHistoryOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCockpit(BuildContext context, RoundManager round) {
    return Column(children: [
        Flexible(flex: 4, child: _AnimatedTarget(target: round.target ?? 0, revealedDigits: _revealedDigits, isHighStakes: _activeJeopardy == JeopardyType.doubleOrNothing, entrance: _entranceController, isDesktop: ResponsiveLayout.isDesktop(context))),
        Expanded(flex: 8, child: LayoutBuilder(builder: (context, constraints) {
          final isDesktop = ResponsiveLayout.isDesktop(context);
          return Padding(padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: constraints.maxHeight * 0.05), child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _NumbersSection(numbers: round.numbers, usedIndices: _usedIndices, onNumberTap: _onNumberTap, entranceAnimation: _entranceController, focusedIndex: _focusedTokenIndex, isHorizontal: isDesktop),
            _ExpressionSection(currentExpression: _currentExpression, onBackspace: _backspace, isLarge: isDesktop),
            _ControlsSection(onOperatorTap: _onOperatorTap, onSubmit: _submit, lockedOperator: _lockedOperator, isLarge: isDesktop),
          ]));
        })),
    ]);
  }

  Widget _buildSidebarTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 140, 
      right: 0, 
      child: _BookTab(
        label: 'HISTORY', 
        icon: Icons.history_rounded, 
        color: colorScheme.primary.withValues(alpha: 0.4), 
        onTap: () => setState(() => _isHistoryVisible = !_isHistoryVisible), 
        isActive: _isHistoryVisible,
        small: true,
      )
    );
  }

  Widget _buildHistoryOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPositioned(duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart, right: _isHistoryVisible ? 0 : -350, top: 0, bottom: 0, child: Container(
        width: 320,
        decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.98), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 60, offset: const Offset(-15, 0))], border: Border(left: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 6))),
        child: Column(children: [
            SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(32, 48, 24, 24), child: Row(children: [Text('HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 16, color: colorScheme.primary)), const Spacer(), IconButton(onPressed: () => setState(() => _isHistoryVisible = false), icon: const Icon(Icons.close_rounded))]))),
            Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: _history.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)), child: Text(_history[i], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 18))))),
        ]),
    ));
  }
}

class _AnimatedTarget extends StatelessWidget {
  final int target; final int revealedDigits; final bool isHighStakes; final AnimationController entrance; final bool isDesktop;
  const _AnimatedTarget({required this.target, required this.revealedDigits, required this.isHighStakes, required this.entrance, this.isDesktop = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    String targetStr = target.toString().padLeft(3, '0'); String displayedTarget = '';
    for (int i = 0; i < 3; i++) { displayedTarget += i < revealedDigits ? targetStr[i] : '?'; }
    return FadeTransition(opacity: entrance, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: entrance, curve: Curves.easeOutBack)), child: Container(width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: isHighStakes ? Colors.red.withValues(alpha: 0.1) : colorScheme.surfaceContainerLow, borderRadius: BorderRadius.vertical(bottom: Radius.circular(isDesktop ? 80 : 56)), boxShadow: [BoxShadow(color: isHighStakes ? Colors.red.withValues(alpha: 0.2) : colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 50, offset: const Offset(0, 20))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(isHighStakes ? 'DOUBLE OR NOTHING' : 'TARGET', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 10, color: isHighStakes ? Colors.red : colorScheme.onSurface.withValues(alpha: 0.3), fontSize: isDesktop ? 14 : 10)), FittedBox(fit: BoxFit.scaleDown, child: Text(displayedTarget, style: theme.textTheme.displayLarge?.copyWith(color: isHighStakes ? Colors.redAccent : colorScheme.primary, fontSize: isDesktop ? 180 : 110, height: 1, fontWeight: FontWeight.w900)))]))));
  }
}

class _NumbersSection extends StatelessWidget {
  final List<int> numbers; final List<int> usedIndices; final Function(int, int) onNumberTap; final Animation<double> entranceAnimation; final int focusedIndex; final bool isHorizontal;
  const _NumbersSection({required this.numbers, required this.usedIndices, required this.onNumberTap, required this.entranceAnimation, required this.focusedIndex, this.isHorizontal = false});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Wrap(spacing: isHorizontal ? 32 : 16, runSpacing: 16, alignment: WrapAlignment.center, children: List.generate(numbers.length, (i) {
      final isUsed = usedIndices.contains(i); final isFocused = i == focusedIndex;
      return ScaleTransition(scale: CurvedAnimation(parent: entranceAnimation, curve: Interval(0.2 + (i * 0.1), 1.0, curve: Curves.elasticOut)), child: _NumberTile(value: numbers[i], isUsed: isUsed, isFocused: isFocused, onTap: () => onNumberTap(i, numbers[i]), small: !isHorizontal));
    })));
  }
}

class _NumberTile extends StatelessWidget {
  final int value; final bool isUsed; final bool isFocused; final VoidCallback onTap; final bool small;
  const _NumberTile({required this.value, required this.isUsed, required this.isFocused, required this.onTap, this.small = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme; final size = small ? 72.0 : 88.0;
    return GestureDetector(onTap: isUsed ? null : onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, width: size, height: size, decoration: BoxDecoration(color: isUsed ? colorScheme.surfaceContainerHighest : colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(small ? 24 : 32), border: isFocused ? Border.all(color: colorScheme.primary, width: 4) : null, boxShadow: [BoxShadow(color: isUsed ? Colors.transparent : colorScheme.tertiary.withValues(alpha: 0.3), blurRadius: isUsed ? 0 : 25, offset: isUsed ? Offset.zero : const Offset(0, 10))]), alignment: Alignment.center, child: Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: isUsed ? colorScheme.onSurfaceVariant.withValues(alpha: 0.2) : colorScheme.onTertiaryContainer, fontSize: small ? 24 : 32))));
  }
}

class _ExpressionSection extends StatelessWidget {
  final String currentExpression; final VoidCallback onBackspace; final bool isLarge;
  const _ExpressionSection({required this.currentExpression, required this.onBackspace, this.isLarge = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    return Container(width: isLarge ? 900 : double.infinity, padding: EdgeInsets.symmetric(vertical: isLarge ? 48 : 32, horizontal: 24), margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: colorScheme.onSurface.withValues(alpha: 0.1), blurRadius: 60, offset: const Offset(0, 25))]), child: Row(children: [
        Expanded(child: Text(currentExpression.isEmpty ? 'BUILD EXPRESSION' : currentExpression, style: theme.textTheme.headlineMedium?.copyWith(color: currentExpression.isEmpty ? colorScheme.onSurface.withValues(alpha: 0.2) : colorScheme.onSurface, fontWeight: FontWeight.w900, fontFamily: 'monospace', fontSize: isLarge ? 40 : 24), textAlign: TextAlign.center)),
        if (currentExpression.isNotEmpty) IconButton(onPressed: onBackspace, icon: Icon(Icons.backspace_rounded, color: colorScheme.primary, size: isLarge ? 40 : 28)),
    ]));
  }
}

class _ControlsSection extends StatelessWidget {
  final Function(String) onOperatorTap; final VoidCallback onSubmit; final String? lockedOperator; final bool isLarge;
  const _ControlsSection({required this.onOperatorTap, required this.onSubmit, this.lockedOperator, this.isLarge = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final isMobile = theme.platform == TargetPlatform.android || theme.platform == TargetPlatform.iOS;
    
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: isLarge ? 950 : double.infinity), child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 20), child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                _OpButton(label: '+', shortcut: 'H', onTap: () => onOperatorTap('+'), isLocked: lockedOperator == '+', size: isLarge ? 80 : 44),
                _OpButton(label: '-', shortcut: 'J', onTap: () => onOperatorTap('-'), isLocked: lockedOperator == '-', size: isLarge ? 80 : 44),
                _OpButton(label: '×', shortcut: 'K', onTap: () => onOperatorTap('*'), isLocked: lockedOperator == '*', size: isLarge ? 80 : 44),
                _OpButton(label: '÷', shortcut: 'L', onTap: () => onOperatorTap('/'), isLocked: lockedOperator == '/', size: isLarge ? 80 : 44),
                _OpButton(label: '(', shortcut: 'N', onTap: () => onOperatorTap('('), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant, size: isLarge ? 80 : 44),
                _OpButton(label: ')', shortcut: 'M', onTap: () => onOperatorTap(')'), color: colorScheme.surfaceContainerHighest, textColor: colorScheme.onSurfaceVariant, size: isLarge ? 80 : 44),
            ],
        ),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: isLarge ? 80 : 64, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: colorScheme.secondary.withValues(alpha: 0.4), blurRadius: 35, offset: const Offset(0, 15))]), child: ElevatedButton(onPressed: onSubmit, style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))), child: Text('SUBMIT', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 8, fontSize: isLarge ? 24 : 18))))),
    ])));
  }
}

class _OpButton extends StatelessWidget {
  final String label; final String? shortcut; final VoidCallback onTap; final Color? color; final Color? textColor; final bool isLocked; final double size;
  const _OpButton({required this.label, this.shortcut, required this.onTap, this.color, this.textColor, this.isLocked = false, this.size = 80});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final btnColor = isLocked ? colorScheme.surfaceContainerHighest : (color ?? colorScheme.primary);
    final isMobile = theme.platform == TargetPlatform.android || theme.platform == TargetPlatform.iOS;

    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: isLocked ? [] : [BoxShadow(color: btnColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]), child: Stack(children: [
          ElevatedButton(onPressed: isLocked ? null : onTap, style: ElevatedButton.styleFrom(minimumSize: Size(size, size), backgroundColor: btnColor, disabledBackgroundColor: colorScheme.surfaceContainerHighest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0), child: isLocked ? const Icon(Icons.lock_rounded, color: Colors.grey) : Text(label, style: TextStyle(fontSize: size * 0.5, color: textColor ?? colorScheme.onPrimary, fontWeight: FontWeight.w900))),
          if (shortcut != null && !isLocked && !isMobile) Positioned(top: 4, right: 6, child: Text(shortcut!, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: (textColor ?? colorScheme.onPrimary).withValues(alpha: 0.5)))),
    ]));
  }
}

class _BookTab extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap; final bool isActive; final bool small;
  const _BookTab({required this.label, required this.icon, required this.color, required this.onTap, required this.isActive, this.small = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20, vertical: small ? 10 : 16), decoration: BoxDecoration(color: isActive ? color : color.withValues(alpha: 0.2), borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(-4, 4))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isActive ? Colors.white : color, size: small ? 20 : 24), const SizedBox(width: 12), if (!small) Text(label, style: TextStyle(color: isActive ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2))])));
  }
}
