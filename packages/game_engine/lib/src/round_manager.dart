import 'number_generator.dart';
import 'target_generator.dart';
import 'submission_validator.dart';
import 'solver_engine.dart';
import 'score_keeper.dart';
import 'match_manager.dart';
import 'round_config.dart';

enum RoundState { idle, playing, scoring, completed }

class RoundManager {
  final NumberGenerator _numGen = NumberGenerator();
  final TargetGenerator _targetGen = TargetGenerator();
  final SubmissionValidator _validator = SubmissionValidator();
  final SolverEngine _solver = SolverEngine();
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

  /// Starts a new round, ensuring it is solvable if a jeopardy event is active.
  void startRound({
    int? seed,
    Difficulty difficulty = Difficulty.medium,
    JeopardyType? jeopardy,
    String? lockedOp,
    RoundConfig config = RoundConfig.classic,
  }) {
    _jeopardyType = jeopardy;
    _lockedOperator = lockedOp;
    _config = config;

    bool isSolvable = false;
    int attempts = 0;
    int maxNesting = (difficulty == Difficulty.easy) ? 1 : 10;

    // Solver-Validated Generation Loop
    while (!isSolvable && attempts < 10) {
      _numbers = _numGen.generatePool(
        difficulty: difficulty, 
        seed: seed != null ? seed + attempts : null,
        poolType: config.poolType,
      );
      
      _targets = _targetGen.generateTargets(
        count: config.isDualTarget ? 2 : 1,
        difficulty: difficulty, 
        seed: seed != null ? seed + attempts : null
      );

      // Special case for single targets that need a specific type (like countdown)
      if (!config.isDualTarget) {
        _targets = [
          _targetGen.generateTarget(
            difficulty: difficulty, 
            seed: seed != null ? seed + attempts : null,
            type: config.targetType,
          )
        ];
      }

      final allowedOps = _getAllowedOperators();
      // Solve for the first target primarily to ensure at least one is solvable
      final result = _solver.solve(_numbers, _targets.first, allowedOperators: allowedOps, maxNesting: maxNesting);

      if (result.foundExact) {
        isSolvable = true;
      }
      attempts++;
    }

    _resetRound();
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
    _resetRound();
  }

  List<String> _getAllowedOperators() {
    final ops = ['+', '-', '*', '/'];
    if (_lockedOperator != null) {
      ops.remove(_lockedOperator);
    }
    return ops;
  }

  void _resetRound() {
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

    if (_numbers.isNotEmpty && _targets.isNotEmpty) {
      final allowedOps = _getAllowedOperators();
      // For now, solve for the first target in results display
      // TODO: Solve for both targets in dual mode
      _bestSolution = _solver.solve(_numbers, _targets.first, allowedOperators: allowedOps);
    }
  }

  void setBestSolution(SolveResult solution) {
    _bestSolution = solution;
  }

  void completeRound() {
    _state = RoundState.completed;
  }

  int calculatePoints(String expression) {
    if (_targets.isEmpty) return 0;
    
    final validation = _validator.validate(
      expression, 
      _numbers, 
      constraints: _config.constraints
    );
    
    if (!validation.isValid) return 0;
    
    if (_config.isDualTarget) {
      return _scoreKeeper.calculateDualTargetScore(
        targets: _targets, 
        result: validation.value?.toInt(),
        rewardBump: _config.rewardBump,
      );
    }

    return _scoreKeeper.calculateScore(
      target: _targets.first, 
      result: validation.value?.toInt(),
      jeopardy: _jeopardyType,
      rewardBump: _config.rewardBump,
    );
  }
}
