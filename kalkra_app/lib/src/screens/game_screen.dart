import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_engine/game_engine.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/vector_background.dart';
import '../widgets/reactive_aura.dart';
import '../widgets/achievement_notification.dart';
import '../widgets/global_drawer.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/game/game_widgets.dart';
import '../services/sound_service.dart';
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

    _visibleNumberCount = round.config.poolType == PoolType.expanding ? 3 : round.numbers.length;
    if (round.config.targetType == TargetType.countdown) _dynamicTarget = round.targets.first;

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
            if ((_totalRoundTime - _secondsLeft) % 5 == 0) _visibleNumberCount++;
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
    if (expression.isEmpty) { setState(() => _proximity = 0.0); return; }

    try {
      final val = SubmissionValidator().validate(expression, round.numbers, allowNegative: round.config.allowNegative, allowFractions: round.config.allowFractions).value;
      if (val != null) {
        final target = _dynamicTarget ?? round.target ?? 1;
        setState(() => _proximity = (1.0 - ((target - val).abs() / target)).clamp(0.0, 1.0));
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
      await _handleHostResults(round, transport, match, session);
    } else if (transport is NullTransport) {
      await _handleSoloResults(round, match, session);
    }
  }

  Future<void> _handleHostResults(RoundManager round, LanHostTransport transport, MatchManager? match, SessionManager session) async {
    final target = _dynamicTarget ?? round.target ?? 0;
    final validator = SubmissionValidator();
    session.recordSubmission('host', _currentExpression.trim(), 0);

    final playerResults = <String, Map<String, dynamic>>{};
    for (final id in session.players.keys) {
      final p = session.players[id]!;
      final val = validator.validate(p.lastExpression ?? '', round.numbers, allowNegative: round.config.allowNegative, allowFractions: round.config.allowFractions).value;
      playerResults[id] = {'name': p.name, 'expression': p.lastExpression ?? '', 'value': val, 'proximity': val == null ? null : (target - val).abs(), 'teamId': p.teamId};
    }

    final teamBestPoints = <int, int>{};
    for (int tId = 1; tId <= 4; tId++) {
      final teamPlayers = session.players.entries.where((e) => e.value.teamId == tId).map((e) => e.key).toList();
      if (teamPlayers.isEmpty) continue;
      num minProx = 1000000; num? bestVal;
      for (final pId in teamPlayers) {
        final prox = playerResults[pId]!['proximity'] as num?;
        if (prox != null && prox < minProx) { minProx = prox; bestVal = playerResults[pId]!['value']; }
      }
      if (minProx < 1000000) {
        final pts = ScoreKeeper().calculateScore(target: target, result: bestVal, jeopardy: round.jeopardyType);
        teamBestPoints[tId] = pts; session.awardTeamPoints(tId, pts);
      }
    }

    Map<String, int>? eloShifts;
    if (match?.isMatchOver ?? false) {
      final winnerId = session.players.entries.reduce((a, b) => a.value.cumulativeScore > b.value.cumulativeScore ? a : b).key;
      eloShifts = EloCalculator.calculateMultiplayerShifts(playerElos: session.players.map((id, p) => MapEntry(id, p.currentElo)), winnerId: winnerId);
    }

    await transport.sendEvent(GameEvent(type: GameEventType.roundResults, payload: {        
      'playerResults': playerResults, 'teamPoints': teamBestPoints.map((k, v) => MapEntry(k.toString(), v)),
      'teamTotalScores': session.teamScores.map((k, v) => MapEntry(k.toString(), v)),       
      'bestSolution': round.bestSolution?.toJson(), 'eloShifts': eloShifts, 'isMatchOver': match?.isMatchOver ?? false
    }));

    if (eloShifts?.containsKey('host') ?? false) ref.read(careerProvider.notifier).applyEloShift(eloShifts!['host']!, 'Arena Rival');   

    if (mounted) {
      _navigateToResults(multiplayerResults: playerResults, teamPoints: teamBestPoints, teamTotalScores: session.teamScores, eloShifts: eloShifts);
    }
  }

  Future<void> _handleSoloResults(RoundManager round, MatchManager? match, SessionManager session) async {
    final expression = _currentExpression.trim();
    final points = round.calculatePoints(expression);
    final val = SubmissionValidator().validate(expression, round.numbers, allowNegative: round.config.allowNegative, allowFractions: round.config.allowFractions).value;     
    
    if (match?.gameMode == GameMode.endless && points == 0) match?.loseLife();

    session.recordSubmission('solo', expression, points);
    ref.read(careerProvider.notifier).updatePerformance(secondsToSubmit: _secondsToSubmit ?? 60.0, proximityToTarget: val != null ? (round.target! - val).abs().toDouble() : 1000.0);

    final career = ref.read(careerProvider).value;
    if (career != null) {
      ref.read(achievementProvider).handleEvent(AchievementEvent(type: AchievementEventType.roundCompleted, data: {'roundIndex': match?.currentRound ?? 1, 'gameMode': match?.gameMode.name ?? 'practice', 'livesLeft': match?.lives ?? 0}));
      if (match?.isMatchOver ?? false) ref.read(achievementProvider).handleEvent(AchievementEvent(type: AchievementEventType.matchCompleted, data: {'totalMatches': career.matchesPlayed + 1, 'playerCount': 1}));
    }
    _navigateToResults();
  }

  void _onExit() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('END MATCH?', style: TextStyle(fontWeight: FontWeight.w900)),       
        content: const Text('Are you sure you want to resign and return to the main menu?'),  
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          TextButton(onPressed: () async {
            Navigator.pop(dialogContext);
            final transport = ref.read(transportProvider);
            if (transport is! NullTransport) {
              await transport.sendEvent(GameEvent(type: GameEventType.playerJoined, payload: {'resigned': true}));
              transport.disconnect();
              ref.read(transportProvider.notifier).setTransport(NullTransport());
            }
            ref.read(matchProvider).value = null;
            ref.read(matchStatusProvider.notifier).setStatus(MatchStatus.lobby);
            ref.read(isPausedProvider.notifier).setPaused(false);
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
          }, child: const Text('RESIGN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _onNumberTap(int index, int value) {
    if (_usedIndices.contains(index)) return;
    final trimmed = _currentExpression.trim();
    if (trimmed.isNotEmpty && RegExp(r'[\d\)]').hasMatch(trimmed[trimmed.length - 1])) return;
    SoundService().playTap();
    setState(() { _currentExpression = trimmed.isEmpty ? '$value' : '$trimmed $value'; _usedIndices.add(index); });
    _updateProximity();
  }

  void _onOperatorTap(String op) {
    if (op == _lockedOperator) return;
    final trimmed = _currentExpression.trim();
    if (op == '(') { if (trimmed.isNotEmpty && !RegExp(r'[+\-*/(]$').hasMatch(trimmed)) return; }
    else if (op == ')') {
      if (trimmed.isEmpty || !RegExp(r'[\d)]$').hasMatch(trimmed)) return;
      if (')'.allMatches(trimmed).length >= '('.allMatches(trimmed).length) return;
    } else { if (trimmed.isEmpty || !RegExp(r'[\d\)]$').hasMatch(trimmed)) return; }

    SoundService().playTap();
    setState(() {
      _currentExpression = trimmed.isEmpty ? op : '$trimmed $op';
      if (op != '(' && op != ')') _currentExpression += ' ';
      _lastAuraOp = _mapOp(op);
    });
    _updateProximity();
  }

  void _clear() { setState(() { _currentExpression = ''; _usedIndices.clear(); _proximity = 0.0; _lastAuraOp = AuraOperator.none; }); }

  void _backspace() {
    if (_currentExpression.isEmpty) return;
    SoundService().playTap();
    setState(() {
      final trimmed = _currentExpression.trim();
      if (trimmed.isEmpty) return;
      final parts = trimmed.split(' ');
      if (int.tryParse(parts.last) != null && _usedIndices.isNotEmpty) _usedIndices.removeLast();
      if (parts.length > 1) {
        parts.removeLast();
        _currentExpression = parts.join(' ');
        if (_currentExpression.isNotEmpty && !RegExp(r'\d$').hasMatch(_currentExpression)) _currentExpression += ' ';
      } else { _currentExpression = ''; }
    });
    _updateProximity();
  }

  Future<void> _submit() async {
    if (_currentExpression.isEmpty) return;
    final round = ref.read(roundProvider); final transport = ref.read(transportProvider);     
    final expression = _currentExpression.trim();
    _secondsToSubmit = DateTime.now().difference(_roundStartTime!).inMilliseconds / 1000.0;
    final val = SubmissionValidator().validate(expression, round.numbers).value;

    if (val != null) { if (val.toInt() == round.target) SoundService().playSuccess(); else SoundService().playTap(); }
    else { SoundService().playError(); }

    if (transport is NullTransport) {
      round.submitExpression(expression);
      if (round.config.allowMultipleSubmissions) {
        _clear();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Recorded! Total: ${round.calculateTotalPoints(round.submissions)} pts'), duration: const Duration(milliseconds: 500), backgroundColor: Colors.green));
      } else { _onTimeUp(); }
    } else {
      await transport.sendEvent(GameEvent(type: GameEventType.submissionReceived, payload: {'expression': expression, 'playerId': transport.myId}));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission sent!'), duration: Duration(seconds: 1)));
      if (round.config.allowMultipleSubmissions) _clear();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyH) _onOperatorTap('+');
    else if (key == LogicalKeyboardKey.keyJ) _onOperatorTap('-');
    else if (key == LogicalKeyboardKey.keyK) _onOperatorTap('*');
    else if (key == LogicalKeyboardKey.keyL) _onOperatorTap('/');
    else if (key == LogicalKeyboardKey.keyN) _onOperatorTap('(');
    else if (key == LogicalKeyboardKey.keyM) _onOperatorTap(')');
    else if (key == LogicalKeyboardKey.backspace) _backspace();
    else if (key == LogicalKeyboardKey.enter) _submit();
    else if (key == LogicalKeyboardKey.arrowLeft) setState(() => _focusedTokenIndex = (_focusedTokenIndex - 1).clamp(0, ref.read(roundProvider).numbers.length - 1));
    else if (key == LogicalKeyboardKey.arrowRight) setState(() => _focusedTokenIndex = (_focusedTokenIndex + 1).clamp(0, ref.read(roundProvider).numbers.length - 1));
    else if (key == LogicalKeyboardKey.space) _onNumberTap(_focusedTokenIndex, ref.read(roundProvider).numbers[_focusedTokenIndex]);
  }

  void _navigateToResults({Map<String, dynamic>? multiplayerResults, Map<int, int>? teamPoints, Map<int, int>? teamTotalScores, Map<String, int>? eloShifts}) {
    final expression = _currentExpression.trim();      
    final val = SubmissionValidator().validate(expression, ref.read(roundProvider).numbers).value;
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ResultsScreen(
        playerExpression: expression, playerValue: val, playerPoints: ref.read(roundProvider).calculatePoints(expression),
        multiplayerResults: multiplayerResults, teamPoints: teamPoints, teamTotalScores: teamTotalScores, eloShifts: eloShifts
      )));
    }
  }

  @override
  void dispose() { _timer?.cancel(); _entranceController.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    SoundService().updateRef(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(currentScreenIdProvider.notifier).setScreenId('GameScreen'); });
    ref.watch(sessionUpdateProvider);
    ref.watch(roundUpdateProvider);

    ref.listen<int?>(roundStartTimeProvider, (prev, next) {
      if (next != null && next > DateTime.now().millisecondsSinceEpoch) { setState(() { _showCountdown = true; _timer?.cancel(); }); }
    });

    ref.listen<AsyncValue<GameEvent>>(gameEventStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == GameEventType.roundEnded) { _onTimeUp(); }
        else if (event.type == GameEventType.roundStarted || event.type == GameEventType.hostStartedMatch) {
          final List<int> numbers = List<int>.from(event.payload['numbers']);
          final List<int> targets = event.payload['targets'] != null ? List<int>.from(event.payload['targets']) : [event.payload['target'] as int];
          final jeopardyIndex = event.payload['jeopardy']; final lockedOp = event.payload['lockedOperator'];
          final jeopardy = jeopardyIndex != null ? JeopardyType.values[jeopardyIndex] : null; 
          ref.read(roundProvider).startRoundWithData(numbers: numbers, targets: targets, jeopardy: jeopardy, lockedOp: lockedOp);
          setState(() {
            _activeJeopardy = jeopardy; _lockedOperator = lockedOp;
            _secondsLeft = ref.read(roundProvider).config.durationSeconds;
            if (_activeJeopardy == JeopardyType.speedDemon) _secondsLeft ~/= 2;
            _currentExpression = ''; _usedIndices.clear(); _roundStartTime = DateTime.now(); _secondsToSubmit = null;
            _focusedTokenIndex = 0; _isRoundEnding = false;
          });
          SoundService().playStart();
          _entranceController.reset(); _entranceController.forward(); _startTimer();
        }
      });
    });

    final theme = Theme.of(context);
    final round = ref.watch(roundProvider);
    final matchNotifier = ref.watch(matchProvider);
    final session = ref.watch(sessionProvider);

    ref.listen<MatchStatus>(matchStatusProvider, (prev, next) {
      if (next == MatchStatus.results) {
        final lastResults = ref.read(lastResultsProvider);
        if (lastResults != null) {
          final results = Map<String, dynamic>.from(lastResults['playerResults']);
          final Map<int, int>? teamPoints = lastResults['teamPoints'] != null ? Map<String, dynamic>.from(lastResults['teamPoints']).map((k, v) => MapEntry(int.parse(k), v as int)) : null;
          final Map<int, int>? teamTotalScores = lastResults['teamTotalScores'] != null ? Map<String, dynamic>.from(lastResults['teamTotalScores']).map((k, v) => MapEntry(int.parse(k), v as int)) : null;
          final Map<String, int>? eloShifts = lastResults['eloShifts'] != null ? Map<String, int>.from(lastResults['eloShifts']) : null;
          _navigateToResults(multiplayerResults: results, teamPoints: teamPoints, teamTotalScores: teamTotalScores, eloShifts: eloShifts);
        }
      }
    });

    return ValueListenableBuilder<MatchManager?>(
      valueListenable: matchNotifier,
      builder: (context, match, _) {
        String roundText = 'SOLO';
        if (match != null) {
          if (match.gameMode == GameMode.progressive) roundText = 'PROGRESSIVE • ROUND ${match.currentRound}/10';
          else if (match.gameMode == GameMode.endless) roundText = 'ENDLESS • ROUND ${match.currentRound}';
          else roundText = 'ROUND ${match.currentRound}/${match.totalRounds}';
        }
        final myScore = session.getPlayerScore(ref.read(transportProvider).myId);

        return KeyboardListener(
          focusNode: _focusNode, autofocus: true, onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            drawer: const GlobalDrawer(),
            backgroundColor: theme.colorScheme.surface,
            appBar: GameHeader(roundText: roundText, myScore: myScore, secondsLeft: _secondsLeft, onExit: _onExit, onClear: _clear),
            body: VectorBackground(
              child: Stack(
                children: [
                  ReactiveAura(proximity: _proximity, timerProgress: _secondsLeft / _totalRoundTime, operator: _lastAuraOp, baseColor: theme.colorScheme.primary),
                  ResponsiveLayout(
                    mobile: _buildGameCockpit(context, round, match, false),
                    desktop: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: _buildGameCockpit(context, round, match, true))),
                  ),
                  if (_showCountdown && ref.watch(roundStartTimeProvider) != null)
                    CountdownOverlay(targetTimeMillis: ref.watch(roundStartTimeProvider)!, onComplete: () { setState(() => _showCountdown = false); _startTimer(); }),
                  const AchievementNotification(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameCockpit(BuildContext context, RoundManager round, MatchManager? match, bool isDesktop) {   
    return SingleChildScrollView(
      child: Column(
        children: [
          AnimatedTarget(targets: round.targets, isHighStakes: _activeJeopardy == JeopardyType.doubleOrNothing, entrance: _entranceController, isDesktop: isDesktop, match: match),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 32),
            child: Column(
              children: [
                NumbersSection(numbers: round.numbers.take(_visibleNumberCount).toList(), usedIndices: _usedIndices, onNumberTap: _onNumberTap, entranceAnimation: _entranceController, focusedIndex: _focusedTokenIndex, isHorizontal: isDesktop),
                const SizedBox(height: 24),
                ExpressionSection(currentExpression: _currentExpression, onBackspace: _backspace, isLarge: isDesktop),
                const SizedBox(height: 24),
                ControlsSection(onOperatorTap: _onOperatorTap, onSubmit: _submit, lockedOperator: _lockedOperator, isLarge: isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
