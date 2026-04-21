import 'dart:math';
import 'number_generator.dart';

enum JeopardyType {
  speedDemon,      // 50% less time
  operatorLockout, // Disables one random operator (+, -, *, /)
  hiddenTarget,    // Target revealed digit by digit every 10 seconds
  doubleOrNothing  // Exact match gives 20 points, off-by-1 gives 0.
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
  final Random _random;

  MatchManager({
    this.totalRounds = 5, 
    this.jeopardyEnabled = true,
    this.gameMode = GameMode.practice,
    int? seed,
  }) : _random = Random(seed);

  int get currentRound => _currentRound;
  int get lives => _lives;
  Difficulty get currentDifficulty => _currentDifficulty;
  JeopardyType? get activeJeopardy => _activeJeopardy;
  String? get lockedOperator => _lockedOperator;
  
  bool get isMatchOver {
    if (gameMode == GameMode.endless) return _lives <= 0;
    return _currentRound > totalRounds;
  }

  void loseLife() {
    if (gameMode == GameMode.endless) {
      _lives--;
    }
  }

  void nextRound({bool forceJeopardy = false}) {
    _currentRound++;
    if (isMatchOver) return;

    if (gameMode == GameMode.progressive) {
      // 10-round gauntlet: 2 Easy, 3 Med, 3 Hard, 2 Hard+Jeopardy
      if (_currentRound <= 2) {
        _currentDifficulty = Difficulty.easy;
        _activeJeopardy = null;
      } else if (_currentRound <= 5) {
        _currentDifficulty = Difficulty.medium;
        _activeJeopardy = null;
      } else if (_currentRound <= 8) {
        _currentDifficulty = Difficulty.hard;
        _activeJeopardy = null;
      } else {
        _currentDifficulty = Difficulty.hard;
        // Random jeopardy for final rounds
        _activeJeopardy = JeopardyType.values[_random.nextInt(JeopardyType.values.length)];
      }
      _updateLockedOp();
      return;
    }

    final progress = _currentRound / totalRounds;
    if (progress <= 0.34) {
      _currentDifficulty = Difficulty.easy;
    } else if (progress <= 0.67) {
      _currentDifficulty = Difficulty.medium;
    } else {
      _currentDifficulty = Difficulty.hard;
    }

    if (jeopardyEnabled && (_currentRound > 1 || forceJeopardy)) {
      final jeopardyChance = forceJeopardy ? 1.0 : (0.2 + (progress * 0.5)); 
      if (_random.nextDouble() <= jeopardyChance) {
        _activeJeopardy = JeopardyType.values[_random.nextInt(JeopardyType.values.length)];
        _updateLockedOp();
      } else {
        _activeJeopardy = null;
        _lockedOperator = null;
      }
    } else {
      _activeJeopardy = null;
      _lockedOperator = null;
    }
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
