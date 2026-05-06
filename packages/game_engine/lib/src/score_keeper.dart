import 'match_manager.dart';

class ScoreKeeper {
  int calculateScore({
    required int target, 
    required int? result, 
    JeopardyType? jeopardy,
    int rewardBump = 0,
  }) {
    if (result == null) return 0;

    final diff = (target - result).abs();

    // Double or Nothing Logic
    if (jeopardy == JeopardyType.doubleOrNothing) {
      return (diff == 0) ? 20 : 0;
    }

    if (diff == 0) return 10 + rewardBump;
    if (diff <= 5) return 7;
    if (diff <= 10) return 5;
    
    return 0;
  }

  int calculateDualTargetScore({
    required List<int> targets,
    required int? result,
    int rewardBump = 0,
  }) {
    if (result == null || targets.isEmpty) return 0;

    // Check for exact matches first
    if (targets.contains(result)) {
      return 10 + rewardBump;
    }

    // Otherwise find the closest target
    int bestScore = 0;
    for (final target in targets) {
      final score = calculateScore(target: target, result: result);
      if (score > bestScore) bestScore = score;
    }

    return bestScore;
  }
}
