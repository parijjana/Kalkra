import 'submission_validator.dart';
import 'score_keeper.dart';
import 'match_manager.dart';
import 'round_config.dart';
import 'solver_engine.dart';

enum RoundState { idle, playing, scoring, completed }

class RoundManager {
  final SubmissionValidator _validator = SubmissionValidator();
  final ScoreKeeper _scoreKeeper = ScoreKeeper();

  RoundState _state = RoundState.idle;
  List<int> _numbers = [];
  List<int> _targets = [];
  JeopardyType? _jeopardyType;
  String? _lockedOperator;
  RoundConfig _config = RoundConfig.classic;
  final List<String> _submissions = [];
  SolveResult? _bestSolution;

  RoundState get state => _state;
  List<int> get numbers => _numbers;
  List<int> get targets => _targets;
  int? get target => _targets.isNotEmpty ? _targets.first : null;
  JeopardyType? get jeopardyType => _jeopardyType;
  String? get lockedOperator => _lockedOperator;
  RoundConfig get config => _config;
  List<String> get submissions => _submissions;
  SolveResult? get bestSolution => _bestSolution;

  /// Starts a round using pre-computed data.
  void startRound({required MatchRoundData data}) {
    _numbers = data.numbers;
    _targets = data.targets;
    _jeopardyType = data.jeopardy;
    _lockedOperator = data.lockedOperator;
    _config = data.config;
    _bestSolution = data.bestSolution;
    
    _submissions.clear();
    _state = RoundState.playing;
  }

  void startRoundWithData({
    required List<int> numbers, 
    required List<int> targets, 
    JeopardyType? jeopardy,
    String? lockedOp,
    RoundConfig config = RoundConfig.classic,
  }) {
    _numbers = numbers;
    _targets = targets;
    _jeopardyType = jeopardy;
    _lockedOperator = lockedOp;
    _config = config;
    
    _submissions.clear();
    _bestSolution = null;
    _state = RoundState.playing;
  }

  void submitExpression(String expression) {
    if (_state != RoundState.playing) {
      throw StateError('Cannot submit expression when not in playing state');
    }
    _submissions.add(expression);
  }

  void endRound() {
    if (_state != RoundState.playing) return;
    _state = RoundState.scoring;
  }

  void setBestSolution(SolveResult solution) {
    _bestSolution = solution;
  }

  void completeRound() {
    _state = RoundState.completed;
  }

  /// Calculates points for a list of expressions (handling Permutations deduplication).
  int calculateTotalPoints(List<String> expressions) {
    if (_targets.isEmpty) return 0;
    
    if (!_config.allowMultipleSubmissions) {
      return calculatePoints(expressions.isEmpty ? '' : expressions.last);
    }

    final uniqueSolutions = <String>{};
    int total = 0;

    for (final expr in expressions) {
      final canonical = _validator.getCanonicalForm(expr);
      if (canonical == null || uniqueSolutions.contains(canonical)) continue;

      final pts = calculatePoints(expr);
      if (pts > 0) {
        total += pts;
        uniqueSolutions.add(canonical);
      }
    }

    return total;
  }

  int calculatePoints(String expression) {
    if (_targets.isEmpty) return 0;
    
    final validation = _validator.validate(
      expression, 
      _numbers, 
      constraints: _config.constraints,
      allowNegative: _config.allowNegative,
      allowFractions: _config.allowFractions,
    );
    
    if (!validation.isValid) return 0;
    
    if (_config.isDualTarget) {
      return _scoreKeeper.calculateDualTargetScore(
        targets: _targets, 
        result: validation.value,
        rewardBump: _config.rewardBump,
      );
    }

    return _scoreKeeper.calculateScore(
      target: _targets.first, 
      result: validation.value,
      jeopardy: _jeopardyType,
      rewardBump: _config.rewardBump,
    );
  }
}
