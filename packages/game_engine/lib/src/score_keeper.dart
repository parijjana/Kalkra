class ScoreKeeper {
  int calculateScore({required int target, required int? result}) {
    if (result == null) return 0;

    final diff = (target - result).abs();

    if (diff == 0) return 10;
    if (diff <= 5) return 7;
    if (diff <= 10) return 5;
    
    return 0;
  }
}
