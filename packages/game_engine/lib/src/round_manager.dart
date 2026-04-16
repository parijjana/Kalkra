import 'number_generator.dart';
import 'target_generator.dart';
import 'submission_validator.dart';
import 'solver_engine.dart';
import 'score_keeper.dart';

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
  final List<String> _submissions = [];
  SolveResult? _bestSolution;

  RoundState get state => _state;
  List<int> get numbers => _numbers;
  int? get target => _target;
  List<String> get submissions => _submissions;
  SolveResult? get bestSolution => _bestSolution;

  void startRound({int? seed, Difficulty difficulty = Difficulty.medium}) {
    _numbers = _numGen.generatePool(difficulty: difficulty, seed: seed);
    _target = _targetGen.generateTarget(seed: seed);
    _resetRound();
  }

  void startRoundWithData({required List<int> numbers, required int target}) {
    _numbers = numbers;
    _target = target;
    _resetRound();
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
    // Validation is done at submission time but result is not stored in state
    // to prevent real-time feedback. 
    _submissions.add(expression);
  }

  void endRound() {
    if (_state != RoundState.playing) return;
    _state = RoundState.scoring;

    // Evaluate submissions (This is a simplification, usually you want to evaluate each one for points)
    // Find best overall solution using solver
    if (_numbers.isNotEmpty && _target != null) {
      _bestSolution = _solver.solve(_numbers, _target!);
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
      result: validation.value?.toInt()
    );
  }
}
