import 'number_generator.dart';
import 'target_generator.dart';
import 'submission_validator.dart';
import 'solver_engine.dart';
import 'score_keeper.dart';
import 'match_manager.dart';

enum RoundState { idle, playing, scoring, completed }

class RoundManager {
  final NumberGenerator _numGen = NumberGenerator();
  final TargetGenerator _targetGen = TargetGenerator();
  final SubmissionValidator _validator = SubmissionValidator();
  final SolverEngine _solver = SolverEngine();
  final ScoreKeeper _scoreKeeper = ScoreKeeper();

  RoundState _state = RoundState.idle;
  List<int> _numbers = [];
  int? _target;
  JeopardyType? _jeopardyType;
  String? _lockedOperator;
  final List<String> _submissions = [];
  SolveResult? _bestSolution;

  RoundState get state => _state;
  List<int> get numbers => _numbers;
  int? get target => _target;
  JeopardyType? get jeopardyType => _jeopardyType;
  String? get lockedOperator => _lockedOperator;
  List<String> get submissions => _submissions;
  SolveResult? get bestSolution => _bestSolution;

  /// Starts a new round, ensuring it is solvable if a jeopardy event is active.
  void startRound({
    int? seed,
    Difficulty difficulty = Difficulty.medium,
    JeopardyType? jeopardy,
    String? lockedOp,
  }) {
    _jeopardyType = jeopardy;
    _lockedOperator = lockedOp;

    bool isSolvable = false;
    int attempts = 0;
    int maxNesting = (difficulty == Difficulty.easy) ? 1 : 10;

    // Solver-Validated Generation Loop
    while (!isSolvable && attempts < 10) {
      _numbers = _numGen.generatePool(difficulty: difficulty, seed: seed != null ? seed + attempts : null);
      _target = _targetGen.generateTarget(difficulty: difficulty, seed: seed != null ? seed + attempts : null);

      final allowedOps = _getAllowedOperators();
      final result = _solver.solve(_numbers, _target!, allowedOperators: allowedOps, maxNesting: maxNesting);

      if (result.foundExact) {
        isSolvable = true;
      }
      attempts++;
    }

    _resetRound();
  }
  void startRoundWithData({
    required List<int> numbers, 
    required int target, 
    JeopardyType? jeopardy,
    String? lockedOp,
  }) {
    _numbers = numbers;
    _target = target;
    _jeopardyType = jeopardy;
    _lockedOperator = lockedOp;
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

    if (_numbers.isNotEmpty && _target != null) {
      final allowedOps = _getAllowedOperators();
      _bestSolution = _solver.solve(_numbers, _target!, allowedOperators: allowedOps);
    }
  }

  void completeRound() {
    _state = RoundState.completed;
  }

  int calculatePoints(String expression) {
    if (_target == null) return 0;
    final validation = _validator.validate(expression, _numbers);
    if (!validation.isValid) return 0;
    
    return _scoreKeeper.calculateScore(
      target: _target!, 
      result: validation.value?.toInt(),
      jeopardy: _jeopardyType,
    );
  }
}
