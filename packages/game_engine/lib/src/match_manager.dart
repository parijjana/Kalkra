import 'dart:math';
import 'number_generator.dart';
import 'round_config.dart';

enum JeopardyType {
  speedDemon,      // 50% less time
  operatorLockout, // Disables one random operator (+, -, *, /)
  doubleOrNothing, // Exact match gives 20 points, off-by-1 gives 0.
  targetObfuscation, // Target is displayed as an expression
  blindPool,       // Numbers are hidden until tapped
}

enum GameMode { practice, endless, progressive, multiplayer }

class MatchManager {
  final int totalRounds;
  final bool jeopardyEnabled;
  final GameMode gameMode;
  int _currentRound = 1;
  int _lives = 3;
  Difficulty _currentDifficulty = Difficulty.easy;
  JeopardyType? _activeJeopardy;
  String? _lockedOperator; // Specific for operatorLockout
  RoundConfig _currentConfig = RoundConfig.classic;
  final Random _random;

  final List<JeopardyType?> _roundJeopardies = [];

  MatchManager({
    this.totalRounds = 5, 
    this.jeopardyEnabled = true,
    this.gameMode = GameMode.multiplayer,
    int? seed,
  }) : _random = Random(seed) {
    if (jeopardyEnabled) {
      _precalculateJeopardies();
    }
  }

  void syncRound(int roundIndex) {
    _currentRound = roundIndex;
    if (_currentRound <= _roundJeopardies.length) {
      _activeJeopardy = _roundJeopardies[_currentRound - 1];
      _updateLockedOp();
    }
  }

  int get currentRound => _currentRound;
  int get lives => _lives;
  Difficulty get currentDifficulty => _currentDifficulty;
  JeopardyType? get activeJeopardy => _activeJeopardy;
  String? get lockedOperator => _lockedOperator;
  RoundConfig get currentConfig => _currentConfig;
  
  bool get isMatchOver {
    if (gameMode == GameMode.endless) return _lives <= 0;
    return _currentRound > totalRounds;
  }

  void loseLife() {
    if (gameMode == GameMode.endless) {
      _lives--;
    }
  }

  void _precalculateJeopardies() {
    _roundJeopardies.clear();
    // No jeopardy for round 1
    _roundJeopardies.add(null); 
    
    for (int i = 1; i < totalRounds; i++) {
      if (_random.nextDouble() < 0.3) { // 30% chance
        _roundJeopardies.add(JeopardyType.values[_random.nextInt(JeopardyType.values.length)]);
      } else {
        _roundJeopardies.add(null);
      }
    }
  }

  void nextRound({bool forceJeopardy = false}) {
    _currentRound++;
    if (isMatchOver) return;

    if (gameMode == GameMode.progressive) {
      _updateProgressiveRound();
      return;
    }

    // Difficulty scaling
    final progress = _currentRound / totalRounds;
    if (progress <= 0.34) _currentDifficulty = Difficulty.easy;
    else if (progress <= 0.67) _currentDifficulty = Difficulty.medium;
    else _currentDifficulty = Difficulty.hard;
    
    _currentConfig = RoundConfig.classic;

    if (jeopardyEnabled) {
      if (forceJeopardy) {
        _activeJeopardy = JeopardyType.values[_random.nextInt(JeopardyType.values.length)];
      } else if (_currentRound <= _roundJeopardies.length) {
        _activeJeopardy = _roundJeopardies[_currentRound - 1];
      } else {
        _activeJeopardy = null;
      }
      _updateLockedOp();
    } else {
      _activeJeopardy = null;
      _lockedOperator = null;
    }
  }

  void _updateProgressiveRound() {
    // 10-round gauntlet based on Kalkra Progression Framework
    switch (_currentRound) {
      case 1:
      case 2:
        _currentDifficulty = Difficulty.easy;
        _currentConfig = RoundConfig.classic;
        break;
      case 3:
        _currentDifficulty = Difficulty.medium;
        _currentConfig = RoundConfig.gauntlet;
        break;
      case 4:
        _currentDifficulty = Difficulty.medium;
        _currentConfig = RoundConfig.forbiddenNumber;
        // Logic to assign actual forbidden number should happen in RoundManager or here
        break;
      case 5:
        _currentDifficulty = Difficulty.medium;
        _currentConfig = RoundConfig.twoTargets;
        break;
      case 6:
        _currentDifficulty = Difficulty.hard;
        _currentConfig = RoundConfig.expandingPool;
        break;
      case 7:
        _currentDifficulty = Difficulty.hard;
        _currentConfig = RoundConfig.mandatoryNumber;
        break;
      case 8:
        _currentDifficulty = Difficulty.hard;
        _currentConfig = RoundConfig.countdownMode;
        break;
      default:
        _currentDifficulty = Difficulty.hard;
        _currentConfig = RoundConfig.classic;
    }
    _activeJeopardy = null; // Progressive has fixed challenge types
    _lockedOperator = null;
  }

  void _updateLockedOp() {
    if (_activeJeopardy == JeopardyType.operatorLockout) {
      const ops = ['+', '-', '*', '/'];
      _lockedOperator = ops[_random.nextInt(ops.length)];
    } else {
      _lockedOperator = null;
    }
  }
}
