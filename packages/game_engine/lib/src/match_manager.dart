import 'dart:math';
import 'number_generator.dart';

enum JeopardyType {
  speedDemon,      // 50% less time
  operatorLockout, // Disables one random operator (+, -, *, /)
  hiddenTarget,    // Target revealed digit by digit every 10 seconds
  doubleOrNothing  // Exact match gives 20 points, off-by-1 gives 0.
}

class MatchManager {
  final int totalRounds;
  int _currentRound = 1;
  Difficulty _currentDifficulty = Difficulty.easy;
  JeopardyType? _activeJeopardy;
  final Random _random;

  MatchManager({this.totalRounds = 5, int? seed}) : _random = Random(seed);

  int get currentRound => _currentRound;
  Difficulty get currentDifficulty => _currentDifficulty;
  JeopardyType? get activeJeopardy => _activeJeopardy;
  bool get isMatchOver => _currentRound > totalRounds;

  void nextRound() {
    _currentRound++;
    if (isMatchOver) return;

    // Progression Logic: Scale difficulty based on round percentage
    final progress = _currentRound / totalRounds;
    if (progress <= 0.34) {
      _currentDifficulty = Difficulty.easy;
    } else if (progress <= 0.67) {
      _currentDifficulty = Difficulty.medium;
    } else {
      _currentDifficulty = Difficulty.hard;
    }

    // Jeopardy Logic: Start introducing jeopardy from round 2 onwards
    // Chance increases as the match progresses
    if (_currentRound > 1) {
      final jeopardyChance = 0.2 + (progress * 0.5); // 20% to 70% chance
      if (_random.nextDouble() < jeopardyChance) {
        _activeJeopardy = JeopardyType.values[_random.nextInt(JeopardyType.values.length)];
      } else {
        _activeJeopardy = null;
      }
    } else {
      _activeJeopardy = null;
    }
  }
}
