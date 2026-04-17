import 'match_manager.dart';

class ScoreKeeper {
  int calculateScore({
    required int target, 
    required int? result, 
    JeopardyType? jeopardy,
  }) {
    if (result == null) return 0;

    final diff = (target - result).abs();

    // Double or Nothing Logic
    if (jeopardy == JeopardyType.doubleOrNothing) {
      return (diff == 0) ? 20 : 0;
    }

    if (diff == 0) return 10;
    if (diff <= 5) return 7;
    if (diff <= 10) return 5;
    
    return 0;
  }
}
