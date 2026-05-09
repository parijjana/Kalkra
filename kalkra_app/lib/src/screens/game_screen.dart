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
import '../widgets/reactive_aura.dart';
import '../widgets/achievement_notification.dart';
import '../widgets/global_drawer.dart';
import '../widgets/countdown_overlay.dart';
import 'main_screen.dart';
import 'results_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with TickerProviderStateMixin {
  Timer? _timer;
  int _secondsLeft = 60;
  int _totalRoundTime = 60;
  String _currentExpression = '';
  final List<int> _usedIndices = [];
  DateTime? _roundStartTime;
  double? _secondsToSubmit;
  
  JeopardyType? _activeJeopardy;
  String? _lockedOperator;
  int _visibleNumberCount = 6;
  int? _dynamicTarget;

  double _proximity = 0.0;
  AuraOperator _lastAuraOp = AuraOperator.none;
  Set<int> _revealedIndices = {};

  late AnimationController _entranceController;
  int _focusedTokenIndex = 0;
  final FocusNode _focusNode = FocusNode();

  bool _isRoundEnding = false;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final round = ref.read(roundProvider);
    _activeJeopardy = round.jeopardyType;
    _lockedOperator = round.lockedOperator;
    
    if (_activeJeopardy == JeopardyType.blindPool) {
      _revealedIndices = {};
    } else {
      _revealedIndices = Set.from(Iterable.generate(6));
    }

    if (round.config.poolType == PoolType.expanding) {
      _visibleNumberCount = 3;
    } else {
      _visibleNumberCount = round.numbers.length;
    }

    if (round.config.targetType == TargetType.countdown) {
      _dynamicTarget = round.targets.first;
    }

    final syncStartTime = ref.read(roundStartTimeProvider);
    if (syncStartTime != null && syncStartTime > DateTime.now().millisecondsSinceEpoch) {
      _showCountdown = true;
    } else {
      _startTimer();
    }

    _roundStartTime = DateTime.now();
    _entranceController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) { _focusNode.requestFocus(); });
  }

  void _startTimer() {
    _timer?.cancel();
    final round = ref.read(roundProvider);
    _secondsLeft = round.config.durationSeconds;
    if (_activeJeopardy == JeopardyType.speedDemon) _secondsLeft ~/= 2;
    _totalRoundTime = _secondsLeft;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) { 
        setState(() {
          _secondsLeft--;
          
          if (round.config.poolType == PoolType.expanding && _visibleNumberCount < 6) {
            final elapsed = _totalRoundTime - _secondsLeft;
            if (elapsed > 0 && elapsed % 5 == 0) {
              _visibleNumberCount++;
              if (_activeJeopardy != JeopardyType.blindPool) _revealedIndices.add(_visibleNumberCount - 1);
            }
          }

          if (round.config.targetType == TargetType.countdown && _dynamicTarget != null && _dynamicTarget! > 100) {
            _dynamicTarget = _dynamicTarget! - 1;
          }
        }); 
      } else { 
        _timer?.cancel(); 
        _onTimeUp(); 
      }
    });
  }

  void _updateProximity() {
    final round = ref.read(roundProvider);
    final expression = _currentExpression.trim();
    if (expression.isEmpty) {
      setState(() => _proximity = 0.0);
      return;
    }

    try {
      final validation = SubmissionValidator().validate(expression, round.numbers, allowNegative: round.config.allowNegative, allowFractions: round.config.allowFractions);
      if (validation.isValid && validation.value != null) {
        final val = validation.value!;
        final target = _dynamicTarget ?? round.target ?? 1;
        final diff = (target - val).abs();
        setState(() {
          _proximity = (1.0 - (diff / target)).clamp(0.0, 1.0);
        });
      } else {
        setState(() => _proximity = 0.0);
      }
    } catch (_) {
      setState(() => _proximity = 0.0);
    }
  }

  AuraOperator _mapOp(String op) {
    switch (op) {
      case '+': return AuraOperator.plus;
      case '-': return AuraOperator.minus;
      case '*': return AuraOperator.times;
      case '/': return AuraOperator.divide;
      default: return AuraOperator.none;
    }
  }

  Future<void> _onTimeUp() async {
    if (_isRoundEnding) return;
    _isRoundEnding = true;
    _timer?.cancel(); 

    final round = ref.read(roundProvider);
    final transport = ref.read(transportProvider);
    final match = ref.read(matchProvider).value;
    final session = ref.read(sessionProvider);
    round.endRound();

    if (transport is LanHostTransport) {
      final target = _dynamicTarget ?? round.target ?? 0;
      final validator = SubmissionValidator();
      
      final myExpression = _currentExpression.trim();
      session.recordSubmission('host', myExpression, 0);

      final playerResults = <String, Map<String, dynamic>>{};
      
      for (final id in session.players.keys) {
        final p = session.players[id]!;
        final expression = p.lastExpression ?? '';
        final validation = validator.validate(expression, round.numbers, allowNegative: round.config.allowNegative, allowFractions: round.config.allowFractions);
        
        num? val;
        num proximity = 1000000;
        
        if (validation.isValid && validation.value != null) {
          val = validation.value;
          proximity = (target - val!).abs();
        }

        playerResults[id] = {
          'name': p.name,
          'expression': expression,
          'value': val,
          'proximity': proximity == 1000000 ? null : proximity,
          'teamId': p.teamId,
        };
      }

      final teamBestPoints = <int, int>{}; 

      for (int tId = 1; tId <= 4; tId++) {
        final teamPlayers = session.players.entries.where((e) => e.value.teamId == tId).map((e) => e.key).toList();
        if (teamPlayers.isEmpty) continue;

        num minProx = 1000000;
        num? bestVal;

        for (final pId in teamPlayers) {
          final res = playerResults[pId]!;
          final prox = res['proximity'] as num?;
          if (prox != null && prox < minProx) {
            minProx = prox;
            bestVal = res['value'];
          }
        }

        if (minProx < 1000000) {
          final scoreKeeper = ScoreKeeper();
          final pts = scoreKeeper.calculateScore(target: target, result: bestVal, jeopardy: round.jeopardyType);
          teamBestPoints[tId] = pts;
          session.awardTeamPoints(tId, pts);
        }
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

      await transport.sendEvent(GameEvent(type: GameEventType.roundResults, payload: {
        'playerResults': playerResults,
        'teamPoints': teamBestPoints.map((k, v) => MapEntry(k.toString(), v)),
        'teamTotalScores': session.teamScores.map((k, v) => MapEntry(k.toString(), v)),
        'bestSolution': round.bestSolution?.toJson(),
        'eloShifts': eloShifts,
        'isMatchOver': isMatchOver
      }));

      if (eloShifts != null && eloShifts.containsKey('host')) { 
        ref.read(careerProvider.notifier).applyEloShift(eloShifts['host']!, 'Arena Rival'); 
      }

      if (mounted) {
        _navigateToResults(
          multiplayerResults: playerResults, 
          teamPoints: teamBestPoints,
          teamTotalScores: session.teamScores,
          eloShifts: eloShifts
        );
      }
    } else if (transport is NullTransport) {
      final expression = _currentExpression.trim();
      final roundData = ref.read(roundProvider);
      final points = roundData.calculatePoints(expression);
      final validation = SubmissionValidator().validate(expression, roundData.numbers, allowNegative: roundData.config.allowNegative, allowFractions: roundData.config.allowFractions);
      
      num proximity = 1000;
      if (validation.isValid && validation.value != null) {
        final val = validation.value!;
        if (roundData.config.isDualTarget) {
          proximity = roundData.targets.map((t) => (t - val).abs()).reduce((a, b) => a < b ? a : b);
        } else {
          proximity = (roundData.target! - val).abs();
        }
      }
      
      if (match != null && match.gameMode == GameMode.endless && points == 0) {
        match.loseLife();
      }

      ref.read(sessionProvider).recordSubmission('solo', expression, points);
      ref.read(careerProvider.notifier).updatePerformance(secondsToSubmit: _secondsToSubmit ?? 60.0, proximityToTarget: proximity.toDouble());
      
      final career = ref.read(careerProvider).value;
      if (career != null) {
        ref.read(achievementProvider).handleEvent(AchievementEvent(
          type: AchievementEventType.roundCompleted,
          data: {
            'roundIndex': match?.currentRound ?? 1,
            'gameMode': match?.gameMode.name ?? 'practice',
            'livesLeft': match?.lives ?? 0,
          },
        ));

        if (match != null && match.isMatchOver) {
          ref.read(achievementProvider).handleEvent(AchievementEvent(
            type: AchievementEventType.matchCompleted,
            data: {
              'totalMatches': career.matchesPlayed + 1,
              'playerCount': 1,
            },
          ));
        }
      }

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
            final navigator = Navigator.of(context);
            Navigator.pop(context);
            final transport = ref.read(transportProvider);
            if (transport is! NullTransport) { await transport.sendEvent(GameEvent(type: GameEventType.playerJoined, payload: {'resigned': true})); }
            if (mounted) { navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false); }
          }, child: const Text('RESIGN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _onNumberTap(int index, int value) {
    if (_usedIndices.contains(index)) return;
    
    if (_activeJeopardy == JeopardyType.blindPool && !_revealedIndices.contains(index)) {
      setState(() => _revealedIndices.add(index));
      return; 
    }

    setState(() {
      if (_currentExpression.isNotEmpty && RegExp(r'\d$').hasMatch(_currentExpression.trim())) { 
        _currentExpression = '${_currentExpression.trim()} '; 
      }
      _currentExpression += '$value'; 
      _usedIndices.add(index);
    });
    _updateProximity();
  }

  void _onOperatorTap(String op) {
    if (op == _lockedOperator) return;
    setState(() { 
      _currentExpression = '${_currentExpression.trim()} $op '; 
      _lastAuraOp = _mapOp(op);
    });
    _updateProximity();
  }

  void _clear() { 
    setState(() { 
      _currentExpression = ''; 
      _usedIndices.clear(); 
      _proximity = 0.0;
      _lastAuraOp = AuraOperator.none;
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
    _updateProximity();
  }

  Future<void> _submit() async {
    if (_currentExpression.isEmpty) return;
    final round = ref.read(roundProvider); final transport = ref.read(transportProvider);
    final expression = _currentExpression.trim(); 
    final secondsToSubmit = DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;
    _secondsToSubmit = secondsToSubmit;

    final validation = SubmissionValidator().validate(expression, round.numbers);
    ref.read(achievementProvider).handleEvent(AchievementEvent(
      type: AchievementEventType.expressionSubmitted,
      data: {
        'isExact': validation.isValid && (validation.value?.toInt() == round.target),
        'seconds': secondsToSubmit,
        'secondsLeft': _secondsLeft,
        'numberCount': validation.usedNumbers.length,
        'ops': validation.operators,
        'value': validation.value,
        'error': validation.error,
        'intermediates': validation.intermediateResults,
        'isTokenOnly': validation.operators.isEmpty && validation.usedNumbers.length == 1,
      },
    ));

    if (transport is NullTransport) { 
      round.submitExpression(expression); 
      if (round.config.allowMultipleSubmissions) {
        _clear();
        if (mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Submission Recorded! Total: ${round.calculateTotalPoints(round.submissions)} pts'),
            duration: const Duration(milliseconds: 500),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        _onTimeUp(); 
      }
    }
    else {
      String myId = transport.myId;
      await transport.sendEvent(GameEvent(type: GameEventType.submissionReceived, payload: {'expression': expression, 'playerId': myId}));
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission sent!'), duration: Duration(seconds: 1))); }
      if (round.config.allowMultipleSubmissions) {
        _clear();
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;
      if (logicalKey == LogicalKeyboardKey.keyH) {
        _onOperatorTap('+');
      } else if (logicalKey == LogicalKeyboardKey.keyJ) {
        _onOperatorTap('-');
      } else if (logicalKey == LogicalKeyboardKey.keyK) {
        _onOperatorTap('*');
      } else if (logicalKey == LogicalKeyboardKey.keyL) {
        _onOperatorTap('/');
      } else if (logicalKey == LogicalKeyboardKey.keyN) {
        _onOperatorTap('(');
      } else if (logicalKey == LogicalKeyboardKey.keyM) {
        _onOperatorTap(')');
      } else if (logicalKey == LogicalKeyboardKey.backspace) {
        _backspace();
      } else if (logicalKey == LogicalKeyboardKey.enter) {
        _submit();
      }
      final round = ref.read(roundProvider);
      if (logicalKey == LogicalKeyboardKey.arrowLeft) { setState(() { _focusedTokenIndex = (_focusedTokenIndex - 1).clamp(0, round.numbers.length - 1); }); }
      else if (logicalKey == LogicalKeyboardKey.arrowRight) { setState(() { _focusedTokenIndex = (_focusedTokenIndex + 1).clamp(0, round.numbers.length - 1); }); }
      else if (logicalKey == LogicalKeyboardKey.space) { _onNumberTap(_focusedTokenIndex, round.numbers[_focusedTokenIndex]); }
    }
  }

  void _navigateToResults({
    Map<String, dynamic>? multiplayerResults, 
    Map<int, int>? teamPoints,
    Map<int, int>? teamTotalScores,
    Map<String, int>? eloShifts
  }) {
    final round = ref.read(roundProvider); final expression = _currentExpression.trim();
    final validation = SubmissionValidator().validate(expression, round.numbers);
    final points = round.calculatePoints(expression);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ResultsScreen(
          playerExpression: expression, 
          playerValue: validation.value, 
          playerPoints: points, 
          multiplayerResults: multiplayerResults, 
          teamPoints: teamPoints,
          teamTotalScores: teamTotalScores,
          eloShifts: eloShifts
        ),
      ));
    }
  }

  @override
  void dispose() { _timer?.cancel(); _entranceController.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(currentScreenIdProvider.notifier).setScreenId('GameScreen'); });
    
    ref.watch(sessionUpdateProvider);
    ref.watch(roundUpdateProvider);

    // Listen for future start times (network sync)
    ref.listen<int?>(roundStartTimeProvider, (prev, next) {
      if (next != null && next > DateTime.now().millisecondsSinceEpoch) {
        setState(() {
          _showCountdown = true;
          _timer?.cancel(); 
 // Stop any current timer
        });
      }
    });

    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == GameEventType.roundEnded) {
          _onTimeUp();
        } else if (event.type == GameEventType.roundStarted || event.type == GameEventType.hostStartedMatch) {
          final List<int> numbers = List<int>.from(event.payload['numbers']); 
          final List<int> targets = event.payload['targets'] != null 
              ? List<int>.from(event.payload['targets']) 
              : [event.payload['target'] as int];
          final jeopardyIndex = event.payload['jeopardy']; final lockedOp = event.payload['lockedOperator'];
          final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null;
          ref.read(roundProvider).startRoundWithData(numbers: numbers, targets: targets, jeopardy: jeopardy, lockedOp: lockedOp);
          setState(() {
            _activeJeopardy = jeopardy; _lockedOperator = lockedOp; 
            
            if (_activeJeopardy == JeopardyType.blindPool) {
              _revealedIndices = {};
            } else {
              _revealedIndices = Set.from(Iterable.generate(numbers.length));
            }

            _secondsLeft = ref.read(roundProvider).config.durationSeconds;
            if (_activeJeopardy == JeopardyType.speedDemon) _secondsLeft ~/= 2;
            
            _currentExpression = ''; _usedIndices.clear(); _roundStartTime = DateTime.now(); _secondsToSubmit = null;
            _focusedTokenIndex = 0; _isRoundEnding = false;
          });
          _entranceController.reset(); _entranceController.forward(); _startTimer();
        }
      });
    });

    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final round = ref.watch(roundProvider); final match = ref.watch(matchProvider).value; final session = ref.watch(sessionProvider);
    
    ref.listen<MatchStatus>(matchStatusProvider, (prev, next) {
      if (next == MatchStatus.results) {
        final lastResults = ref.read(lastResultsProvider);
        if (lastResults != null) {
          final results = Map<String, dynamic>.from(lastResults['playerResults']);
          final Map<int, int>? teamPoints = lastResults['teamPoints'] != null 
              ? Map<String, dynamic>.from(lastResults['teamPoints']).map((k, v) => MapEntry(int.parse(k), v as int)) 
              : null;
          final Map<int, int>? teamTotalScores = lastResults['teamTotalScores'] != null 
              ? Map<String, dynamic>.from(lastResults['teamTotalScores']).map((k, v) => MapEntry(int.parse(k), v as int)) 
              : null;
          final Map<String, int>? eloShifts = lastResults['eloShifts'] != null ? Map<String, int>.from(lastResults['eloShifts']) : null;

          _navigateToResults(
            multiplayerResults: results,
            teamPoints: teamPoints,
            teamTotalScores: teamTotalScores,
            eloShifts: eloShifts,
          );
        }
      }
    });

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
    
    final myScore = session.getPlayerScore(ref.read(transportProvider).myId);

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
              Text('$roundText • SCORE: $myScore', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: colorScheme.onPrimary.withValues(alpha: 0.7))),
              Text('TIME: $_secondsLeft', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ]),
          centerTitle: true, elevation: 0,
          actions: [
            IconButton(onPressed: _onExit, icon: const Icon(Icons.logout_rounded)),
            IconButton(onPressed: _clear, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: VectorBackground(
          child: Stack(
            children: [
              ReactiveAura(
                proximity: _proximity,
                timerProgress: _secondsLeft / _totalRoundTime,
                operator: _lastAuraOp,
                baseColor: colorScheme.primary,
              ),
              ResponsiveLayout(
                mobile: _buildGameCockpit(context, round, match),
                desktop: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: _buildGameCockpit(context, round, match),
                  ),
                ),
              ),
              if (_showCountdown && ref.watch(roundStartTimeProvider) != null)
                CountdownOverlay(
                  targetTimeMillis: ref.watch(roundStartTimeProvider)!,
                  onComplete: () {
                    setState(() => _showCountdown = false);
                    _startTimer();
                  },
                ),
              const AchievementNotification(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCockpit(BuildContext context, RoundManager round, MatchManager? match) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _AnimatedTarget(targets: round.targets, isHighStakes: _activeJeopardy == JeopardyType.doubleOrNothing, isObfuscated: _activeJeopardy == JeopardyType.targetObfuscation, entrance: _entranceController, isDesktop: ResponsiveLayout.isDesktop(context), match: match),
          LayoutBuilder(builder: (context, constraints) {
            final isDesktop = ResponsiveLayout.isDesktop(context);
            return Padding(padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 32), child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _NumbersSection(numbers: round.numbers, usedIndices: _usedIndices, revealedIndices: _revealedIndices, onNumberTap: _onNumberTap, entranceAnimation: _entranceController, focusedIndex: _focusedTokenIndex, isHorizontal: isDesktop),
              const SizedBox(height: 24),
              _ExpressionSection(currentExpression: _currentExpression, onBackspace: _backspace, isLarge: isDesktop),
              const SizedBox(height: 24),
              _ControlsSection(onOperatorTap: _onOperatorTap, onSubmit: _submit, lockedOperator: _lockedOperator, isLarge: isDesktop),
            ]));
          }),
        ],
      ),
    );
  }
}

class _AnimatedTarget extends StatelessWidget {
  final List<int> targets; final bool isHighStakes; final bool isObfuscated; final AnimationController entrance; final bool isDesktop; final MatchManager? match;
  const _AnimatedTarget({required this.targets, required this.isHighStakes, this.isObfuscated = false, required this.entrance, this.isDesktop = false, this.match});
  
  String _getObfuscatedTarget(int target) {
     if (target < 50) return '???';
     final parts = [target ~/ 2, target - (target ~/ 2)];
     return '${parts[0]} + ${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    final isDual = targets.length > 1;
    return FadeTransition(opacity: entrance, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: entrance, curve: Curves.easeOutBack)), child: Container(width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: isHighStakes ? Colors.red.withValues(alpha: 0.1) : colorScheme.surfaceContainerLow, borderRadius: BorderRadius.vertical(bottom: Radius.circular(isDesktop ? 80 : 56)), boxShadow: [BoxShadow(color: isHighStakes ? Colors.red.withValues(alpha: 0.2) : colorScheme.onSurface.withValues(alpha: 0.05), blurRadius: 50, offset: const Offset(0, 20))]), child: Stack(children: [
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(isHighStakes ? 'DOUBLE OR NOTHING' : (isObfuscated ? 'CALCULATE TARGET' : (isDual ? 'TWO TARGETS' : 'TARGET')), style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 10, color: isHighStakes ? Colors.red : colorScheme.onSurface.withValues(alpha: 0.3), fontSize: isDesktop ? 14 : 10)),
        if (isDual)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(isObfuscated ? _getObfuscatedTarget(targets[0]) : '${targets[0]}', style: theme.textTheme.displayLarge?.copyWith(color: colorScheme.primary, fontSize: isDesktop ? 120 : 80, height: 1, fontWeight: FontWeight.w900))),
                const SizedBox(width: 40),
                FittedBox(fit: BoxFit.scaleDown, child: Text(isObfuscated ? _getObfuscatedTarget(targets[1]) : '${targets[1]}', style: theme.textTheme.displayLarge?.copyWith(color: colorScheme.secondary, fontSize: isDesktop ? 120 : 80, height: 1, fontWeight: FontWeight.w900))),
              ],
            ),
          )
        else
          FittedBox(fit: BoxFit.scaleDown, child: Text(isObfuscated ? _getObfuscatedTarget(targets.first) : '${targets.isNotEmpty ? targets.first : 0}', style: theme.textTheme.displayLarge?.copyWith(color: isHighStakes ? Colors.redAccent : colorScheme.primary, fontSize: isDesktop ? 120 : 110, height: 1, fontWeight: FontWeight.w900)))
      ]),
      if (match?.gameMode == GameMode.endless) Positioned(top: 24, left: 24, child: Row(children: List.generate(3, (i) => Padding(padding: const EdgeInsets.only(right: 8), child: Icon(i < (match?.lives ?? 0) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 28, color: i < (match?.lives ?? 0) ? Colors.redAccent : colorScheme.onSurface.withValues(alpha: 0.1))))))
    ]))));
  }
}

class _NumbersSection extends StatelessWidget {
  final List<int> numbers; final List<int> usedIndices; final Set<int> revealedIndices; final Function(int, int) onNumberTap; final Animation<double> entranceAnimation; final int focusedIndex; final bool isHorizontal;
  const _NumbersSection({required this.numbers, required this.usedIndices, required this.revealedIndices, required this.onNumberTap, required this.entranceAnimation, required this.focusedIndex, this.isHorizontal = false});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Wrap(spacing: isHorizontal ? 32 : 16, runSpacing: 16, alignment: WrapAlignment.center, children: List.generate(numbers.length, (i) {
      final isUsed = usedIndices.contains(i); final isFocused = i == focusedIndex;
      final isRevealed = revealedIndices.contains(i);
      return ScaleTransition(scale: CurvedAnimation(parent: entranceAnimation, curve: Interval(0.2 + (i * 0.1), 1.0, curve: Curves.elasticOut)), child: _NumberTile(value: numbers[i], isUsed: isUsed, isFocused: isFocused, isRevealed: isRevealed, onTap: () => onNumberTap(i, numbers[i]), small: !isHorizontal));
    })));
  }
}

class _NumberTile extends StatelessWidget {
  final int value; final bool isUsed; final bool isFocused; final bool isRevealed; final VoidCallback onTap; final bool small;
  const _NumberTile({required this.value, required this.isUsed, required this.isFocused, required this.isRevealed, required this.onTap, this.small = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme; final size = small ? 72.0 : 88.0;
    return GestureDetector(onTap: isUsed ? null : onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, width: size, height: size, decoration: BoxDecoration(color: isUsed ? colorScheme.surfaceContainerHighest : (isRevealed ? colorScheme.tertiaryContainer : colorScheme.primaryContainer), borderRadius: BorderRadius.circular(small ? 24 : 32), border: isFocused ? Border.all(color: colorScheme.primary, width: 4) : null, boxShadow: [BoxShadow(color: isUsed ? Colors.transparent : colorScheme.tertiary.withValues(alpha: 0.3), blurRadius: isUsed ? 0 : 25, offset: isUsed ? Offset.zero : const Offset(0, 10))]), alignment: Alignment.center, child: Text(isRevealed ? '$value' : '?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: isUsed ? colorScheme.onSurfaceVariant.withValues(alpha: 0.2) : (isRevealed ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer), fontSize: small ? 24 : 32))));
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
